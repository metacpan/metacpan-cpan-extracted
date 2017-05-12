
package Docserver;
use strict;
use Docserver::Config;
use IO::File;
use Fcntl;

BEGIN {
	local $^W = 0;
eval <<'EOF';
	use Win32;
	use Win32::API;
	use Win32::OLE qw(in);
	use Win32::OLE::Const 'Microsoft Office';
	use Win32::OLE::Const 'Microsoft Word';
	use Win32::OLE::Const 'Microsoft Excel';
EOF
}

$Docserver::VERSION = '1.12';

# Placeholder for global error string
use vars qw( $errstr );

# Values for output formats
my %docoutform = (
		'txt' =>	'Text with Layout',
		# 'txt1' =>	wdFormatTextLineBreaks,
		'txt1' =>	wdFormatText,
		'rtf' =>	wdFormatRTF,
		'doc' =>	wdFormatDocument,
		'doc6' =>	'MSWord6Exp',
		'doc95' =>	'MSWord6Exp',
		'html' =>	wdFormatHTML,
		'ps' =>		$Docserver::Config::Config{'ps'},
		'ps1' =>	$Docserver::Config::Config{'ps1'},
		); 
my %xlsoutform = (
		'txt' =>	xlTextPrinter,
		'csv' =>	xlCSV,
		'xls' =>	xlNormal,
		'xls5' =>	xlExcel5,
		'xls95' =>	xlExcel5,
		'html' =>	xlHtml,
		'ps' =>		defined $Docserver::Config::Config{'excel.ps'}
				? $Docserver::Config::Config{'excel.ps'}
				: $Docserver::Config::Config{'ps'},
		'ps1' =>	defined $Docserver::Config::Config{'excel.ps1'}
				? $Docserver::Config::Config{'excel.ps1'}
				: $Docserver::Config::Config{'ps1'},
		);

my $SHEET_SEP = "\n##### List è. %s #####\n\n";
my $CSV_SHEET_SEP = "##### Sheet %s #####\n";

# Pro logovani pouzijeme metody Docserver::Srv (zdedene od Net::Daemon pres
# RPC::PlServer). Abychom ale mohli pristoupit k objektu Docserver::Srv, 
# musel byt upraven RPC/PlServer.pm, kde v metody NewHandle bylo
#     my $object = $self->CallMethod($handle, $method, @args);
# zmeneno na
#     my $object = $self->CallMethod($handle, $method, @args, $self);
# - pak se v konstruktoru new tento argument stane hodnotou 'parent_server'
sub Debug {
	my $self = shift;
	if (defined $self->{'parent_server'}) {
		$self->{'parent_server'}->Debug(@_);
	} else {
		warn scalar localtime, " ddebug, ", (sprintf shift, @_), "\n";
	}
}

# Create Docserver object, create temporary directory and create
# and open input (temporary storage) file in binmode.
sub new {
	my $class = shift;
	my $self;
	eval {
		$self = bless {
			'verbose' => 5,
			'parent_server' => shift,
			}, $class;

		my ($dir, $filename)
			= ($Docserver::Config::Config{'tmp_dir'}, 'file.in');
		if (not -d $dir) {
			$self->Debug("Directory `$dir' doesn't exist, will try to create it");
			mkdir $dir, 0666
				or die "Error creating dir `$dir': $!\n";
			die "Directory `$dir' was not created properly\n" if not -d $dir;
		}
		$dir .= '\\'.time.'.'.$$;
		mkdir $dir, 0666 or die "Error creating tmp dir `$dir': $!\n";
		$self->{'dir'} = $dir;

		$self->{'infile'} = $dir.'\\'.$filename;
		$self->Debug("Temporary file is `$self->{'infile'}'");
		($self->{'outfile'} = $self->{'infile'}) =~ s/in$/out/;

		$self->{'fh'} = new IO::File ">$self->{'infile'}"
			or die "Couldn't create file `$self->{'infile'}': $@\n";
		binmode $self->{'fh'};
	};
	if ($@) {
		$errstr = $@;
		return;
	}
	return $self;
}

# Returns error string, either for class or for object.
sub errstr {
	my $ref = shift;
	if (defined $ref and ref $ref) { return $ref->{'errstr'}; }
	return $errstr;
}

# Chooses smaller chunk size -- compares server configuration with
# value that came from client.
sub preferred_chunk_size {
	my ($self, $size) = @_;
	$size = $Docserver::Config::Config{'ChunkSize'}
		if not defined $size or $size > $Docserver::Config::Config{'ChunkSize'};
	$self->Debug("Choosing chunk size `$size'") if $self->{'verbose'};
	$self->{'ChunkSize'} = $size;
	return $size;
}

# Sets the input file length in the object.
sub input_file_length {
	my ($self, $size) = @_;
	if (defined $size) {
		$self->{'input_file_length'} = shift;
		$self->Debug("Setting input file size to `$size'") if $self->{'verbose'};
	}
	$size;
}

# Puts next chunk of data into the input file.
sub put {
	my $self = shift;
	print { $self->{'fh'} } shift;
	1;
}

# Runs the conversion from infile, from in_format to out_format.
sub convert {
	my ($self, $in_format, $out_format) = @_;
	delete $self->{'errstr'};
	$self->Debug("Called convert (`$in_format', `$out_format')")
		if $self->{'verbose'};

	eval {
		if (defined $self->{'fh'}) {
			# Close the input filehandle, no more data coming.
			$self->{'fh'}->close();
			delete $self->{'fh'};
		}
		if ($in_format =~ /doc|rtf|html|txt/) {
			# Run Word conversion.
			if (not defined $docoutform{$out_format}) {
				die "Unsupported output format `$out_format' for Word conversion\n";
			}
			$self->doc_convert($in_format, $out_format);
		}
		elsif ($in_format eq 'xls' or $in_format eq 'csv') {
			# Run Excel conversion.
			if (not defined $xlsoutform{$out_format}) {
				die "Unsupported output format `$out_format' for Excel conversion\n";
			}
			$self->xls_convert($in_format, $out_format);
		}
		else {
			die "Unsupported input format `$in_format'\n";
		}
	};
	if ($@) {
		$self->{'errstr'} = $@;
		$self->Debug("Conversion failed: $@");
	}
	return 1 if not defined $self->{'errstr'};
	return;
}

# Does the whole conversion from Word doc.
sub doc_convert {
	my ($self, $in_format, $out_format) = @_;

	# We will start new Word. It is better than doing
	# GetActiveObject because if the interactive user already has
	# some Word open, he won't see any documents flashing through
	# his screen, and vice versa, he shouldn't be able to spoil
	# our conversion. Starting new Word would be necessary if we
	# wanted the user to be able to kill potential dialog windows.

	my $word = Win32::OLE->new('Word.Application', 'Quit')
		or die Win32::OLE->LastError;

	# Convertors for Text with Layout and to Word95 are optional
	# part of Word installation and as such they don't have any
	# constant wdFormat. They get some integer upon installation
	# and we need to get them this way.

	if (not $out_format =~ /^ps\d*$/
		and not $docoutform{$out_format} =~ /^\d+$/) {
		for my $conv (in $word->FileConverters) {
			$docoutform{$out_format} = $conv->SaveFormat
				if $conv->ClassName eq $docoutform{$out_format};
		}
		if (not $docoutform{$out_format} =~ /^\d+$/) {
			die "Couldn't find converter for format `$docoutform{$out_format}'\n";
		}
		$self->Debug("Found output converter number `$docoutform{$out_format}'");
	}

	# Open method doesn't handle templates (unlike Excel), which cannot be
	# saved as anything else than templates. So it is better to open
	# document based on template -- it works even if we fill it other
	# files than templates. The format is recognized automagically.

	my $doc = $word->Documents->Add({
		'Template' => $self->{'infile'},
		}) or die Win32::OLE->LastError;

	if ($out_format =~ /^ps\d*$/) {
		# Print to file. We have to run it on background
		# so that we don't get some dialog that would allow
		# interactive user to cancel the print.

		my $origback = $word->Options->{PrintBackground};
		my $origprinter = $word->ActivePrinter;

		$word->Options->{PrintBackground} = 1;
		my $printer = $docoutform{$out_format};
		$self->Debug("Setting ActivePrinter to `$printer'");
		$word->{ActivePrinter} = $printer;
		if ($word->{ActivePrinter} ne $printer) {
			$self->Debug("ActivePrinter set to `$word->{ActivePrinter}'");
			die "Setting ActivePrinter to `$printer' failed -- printer not found\n";
		}

		$doc->Activate;
		$word->PrintOut({
			'Range' => wdPrintAllDocument,
			'PrintToFile' => 1, 
			'OutputFileName' => $self->{'outfile'},
			'Copies' => 1
			});
		for (my $i = 0; $i < 60; $i++) {
			sleep 2;
			last unless $word->{BackgroundPrintingStatus};
		}
		$word->Options->{PrintBackground} = $origback;
		$word->{ActivePrinter} = $origprinter;
	} else {
		# The Text with Layout has problems with pictures,
		# probably whenever the picture is in header or footer
		# (it issues error message that saving cannot be
		# finished because access rights are wrong), and
		# sometimes even in normal text when it produces
		# garbage.
		#
		# Because it seems to ignore shapes wich text fields
		# and probably of all types, we'll delete all shapes.
		# We have to delete shapes from header and footer
		# separately ($doc->Shapes won't return them),
		# according to the manual we can take Shapes property
		# from any HeaderFooter object and the returned
		# collection will contain all shapes from all headers
		# and footers.

		if ($out_format eq 'txt') {
			for my $shape (in $doc->Shapes) {
				$shape->Delete;
			}
			for my $shape (in $doc->Sections(1)->Headers(wdHeaderFooterPrimary)->Shapes) {
				$shape->Delete;
			}
		}

		# The normal text convertor (txt1) puts header under
		# the normal text.

		# If the original document
		# containg page numbers in headers or footers, the
		# Text with Layout puts to the beginning of the output
		# (and the normal text converter to the end of the
		# output) some number, usually number of the first
		# page, but the following pages are not numbered.
		# That's why we'll remove all page numbers,
		# unfortunately there doesn't seem to be any better
		# way than walking through all combinations of header
		# and footer and constants WdHeaderFooterIndex.

		if ($out_format =~ /^txt1?$/) {
			for my $section (in $doc->Sections) {
				for my $pagenumber (
					in $section->Footers(wdHeaderFooterPrimary)->PageNumbers,
					in $section->Headers(wdHeaderFooterPrimary)->PageNumbers,
					in $section->Footers(wdHeaderFooterEvenPages)->PageNumbers,
					in $section->Headers(wdHeaderFooterEvenPages)->PageNumbers,
					in $section->Footers(wdHeaderFooterFirstPage)->PageNumbers,
					in $section->Headers(wdHeaderFooterFirstPage)->PageNumbers
					) {
					$pagenumber->Delete;
				}
			}
		}

		$doc->SaveAs({
			'FileName' => $self->{'outfile'},
			'FileFormat' => $docoutform{$out_format}
			});
	}
	$doc->Close({
		'SaveChanges' => wdDoNotSaveChanges,
		});
}
		
sub xls_convert
	{
	my ($self, $in_format, $out_format) = @_;

	my $excel = Win32::OLE->new('Excel.Application', 'Quit')
		or die Win32::OLE->LastError;

	my $wrk = $excel->Workbooks->Open({
		'FileName' => $self->{'infile'},
		($in_format eq 'csv' ? ('Format' => 4) : ()),
		}) or die Win32::OLE->LastError;

	# We'll set nice name of the sheet if the input comes from CSV
	# to have reasonable name for output to PS or XLS.
	$wrk->Sheets(1)->{'Name'} = 'Sheet1' if $in_format eq 'csv';

	if ($out_format =~ /^(xls(95)?|txt)$/) {
		$wrk->SaveAs({
			'FileName' => $self->{'outfile'},
			'FileFormat' => $xlsoutform{$out_format}
			});

	} elsif ($out_format =~ /^ps\d?$/) {
		# It seems like Excel cannot do background printing
		# like Word can. Fortunately the dialog box is not
		# active so it cannot be hit by accident.
		$excel->{ActivePrinter} = $xlsoutform{$out_format};
		$wrk->Activate;
		$wrk->PrintOut({
			'PrintToFile' => 1, 
			'PrToFileName' => $self->{'outfile'},
			});

	} elsif ($out_format eq 'csv') {
		open FILEOUT, "> $self->{'outfile'}" or die "Error writing $self->{'outfile'}: $!";
		binmode FILEOUT;
		for my $i (1 .. $wrk->Sheets->Count) {
			$wrk->Sheets($i)->SaveAs({
				'FileName' => "$self->{'outfile'}$i",
				'FileFormat' => $xlsoutform{$out_format},
			});
			printf FILEOUT $CSV_SHEET_SEP, $i if $i > 1;
			open IN, "$self->{'outfile'}$i";
			binmode IN;
			while (<IN>) {
				print FILEOUT;
			}
			close IN;
		}
		close FILEOUT;
	
	} elsif ($out_format eq 'html') {
		for my $sheet (in $wrk->Sheets) {
			$wrk->PublishObjects->Add({
				'SourceType' => xlSourceSheet,
				'Filename' => $self->{'outfile'},
				'Sheet' => $sheet->Name,
				'HtmlType' => xlHtmlStatic,
				})->Publish({
					'Create' => 0,
					});
		}	
	}

	$wrk->Close({
		'SaveChanges' => 0
		});
	opendir DIR, $self->{'dir'};
	map unlink("$self->{'dir'}/$_") || warn("$_ $!\n"), grep /out\d+$/, readdir DIR;
	closedir DIR;
}


sub result_length {
	my $self = shift;
	return -s $self->{'outfile'};
}

# Returns next piece of output file.
sub get {
	my ($self, $len) = @_;
	my $fh = $self->{'outfh'};
	if (not defined $fh) {
		$fh = $self->{'outfh'} = new IO::File($self->{'outfile'});
		binmode $fh;
	}
	my $buffer;
	read $fh, $buffer, $len;
	$buffer;
}

sub finished {
	my $self = shift;
	close delete $self->{'fh'} if defined $self->{'fh'};
	close delete $self->{'outfh'} if defined $self->{'outfh'};
	unlink delete $self->{'infile'} if defined $self->{'infile'};
	unlink delete $self->{'outfile'} if defined $self->{'outfile'};
	rmdir delete $self->{'dir'} if defined $self->{'dir'};
}

sub DESTROY {
	shift->finished;
}

sub server_version {
	return $Docserver::VERSION;
}

1;

=head1 NAME

Docserver.pm - server module for remote MS format conversions

=head1 AUTHOR

(c) 1998--2002 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic.

Pavel Smerk added support for more formats and also did the error
and Windows handling.

=cut

