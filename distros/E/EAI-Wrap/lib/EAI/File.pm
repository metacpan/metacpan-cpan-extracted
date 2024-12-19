package EAI::File 1.917;

use strict; use feature 'unicode_strings'; use warnings; no warnings 'uninitialized';
use Exporter qw(import); use Text::CSV(); use Data::XLSX::Parser(); use Spreadsheet::ParseExcel(); use Spreadsheet::WriteExcel(); use Excel::Writer::XLSX(); use XML::LibXML(); use XML::LibXML::Debugging();
use Carp qw(confess longmess); use Data::Dumper qw(Dumper); use Log::Log4perl qw(get_logger); use Time::localtime; use Scalar::Util qw(looks_like_number); use EAI::DateUtil; use EAI::Common;

our @EXPORT = qw(readText readExcel readXML writeText writeExcel);

# get common read procedure parameters from $File config, used in readText, readExcel and readXML
sub getcommon ($) {
	my ($File) = @_;
	my $lineProcessing = $File->{lineCode};
	my $fieldProcessing = $File->{fieldCode};
	my $firstLineProc = $File->{firstLineProc};
	my $thousandsep = "\\".$File->{format_thousandsep}; # add backslash to quote thousandsep for regexp (in case it is a ".")
	my $decimalsep = "\\".$File->{format_decimalsep}; # add backslash to quote decimalsep for regexp (in case it is a ".")
	my $skip = $File->{format_skip} if $File->{format_skip};
	my $sep = $File->{format_sep} if $File->{format_sep};
	$sep = $File->{format_defaultsep} if !$sep; # use default if not given
	# for fixed format and non existing separator, header and targetheader strings are parsed/split using tab as separator
	my @header = split(($sep =~ /^fix/ or !$sep ? "\t" : $sep), $File->{format_header}) if $File->{format_header};
	my @targetheader = split(($sep =~ /^fix/ or !$sep ? "\t" : $sep), $File->{format_targetheader}) if $File->{format_targetheader};
	$Data::Dumper::Terse = 1;
	get_logger()->debug("\$skip:$skip\n\$sep:".Data::Dumper::qquote($sep)."\n\@header:@header\n\@targetheader:@targetheader\n\$lineProcessing:$lineProcessing\n\$fieldProcessing:$fieldProcessing\n\$firstLineProc:$firstLineProc\n\$thousandsep:$thousandsep\n\$decimalsep:$decimalsep");
	$Data::Dumper::Terse = 0;
	return ($lineProcessing,$fieldProcessing,$firstLineProc,$thousandsep,$decimalsep,$sep,$skip,\@header,\@targetheader);
}

# read text files
sub readText ($$$;$$) {
	my ($File,$data,$filenames,$redoSubDir,$countPercent) = @_;
	my $logger = get_logger();
	my @filenames = @{$filenames} if $filenames;
	if (!@filenames) {
		$logger->error("no filenames passed".longmess());
		return 0;
	}
	# read format configuration
	my ($lineProcessing,$fieldProcessing,$firstLineProc,$thousandsep,$decimalsep,$sep,$skip,$header,$targetheader) = getcommon($File);
	my @header = @$header; my @targetheader = @$targetheader;
	my ($poslen, $isFixLen); 
	if ($sep =~ /^fix/) {
		# positions/length definitions from poslen definition: e.g. "format_poslen => [[0,3],[3,3]]"
		$poslen = $File->{format_poslen};
		if (!$poslen) {
			$logger->error("no format_poslen array given for parsing fix length format".longmess());
			return 0;
		}
		$isFixLen = 1;
	} else {
		if (!$sep) {
			$logger->error("no separator set in ".Dumper($File).longmess());
			return 0;
		}
		if ($File->{format_quotedcsv} and ref($sep) eq "Regexp") {
			$logger->error("no regex separator allowed with format_quotedcsv".longmess());
			return 0;
		}
		$logger->warn("string separator assumed to be a regular expression for splitting textfile without format_quotedcsv, this may produce unexpected results".longmess()) if (!$File->{format_quotedcsv} and !$File->{format_autoheader} and !(ref($sep) eq "Regexp"));
	}
	my $autoheader = $File->{format_autoheader} if $File->{format_autoheader};
	@targetheader = @header if !@targetheader; # if no specific targetheader defined use header instead
	# read all files with same format
	for my $filename (@filenames) {
		my $lines = 0; my $buffer;
		open my($fh), '<:raw', $redoSubDir.$filename;
		while( sysread $fh, $buffer, 4096 ) {
			$lines += ($buffer =~ s!$/!!g);
		}
		close $fh;
		$logger->debug("reading $redoSubDir$filename");
		open (FILE, "<".$File->{format_encoding}, $redoSubDir.$filename) or do { #
			if (! -e $redoSubDir.$filename) {
				$logger->error("no file $redoSubDir$filename to process...".longmess()) unless ($File->{optional});
				$logger->warn("no file $redoSubDir$filename found... ".longmess());
			} else {
				$logger->error("file open error: $!".longmess());
			}
			return 0;
		};
		my $sv = Text::CSV->new ({
			binary    => 1,
			auto_diag => 1,
			sep_char  => $sep,
			eol => ($File->{format_eol} ? $File->{format_eol} : $/),
		});
		# local context for special line record separator
		{
			my $newRecSep;
			if ($File->{format_allowLinefeedInData}) {
				# enable binmode and set line record separator to CRLF, so line feeds in values don't create artificial new lines/records
				binmode(FILE, ":raw".$File->{format_encoding}); # raw so not to swallow CRLF
				$newRecSep = "\015\012";
				$logger->debug("binmode");
			}
			# change record separator (standard CRLF), if needed
			local $/ = $newRecSep if $newRecSep;
			my @layers = PerlIO::get_layers(FILE);
			$logger->info("reading file $redoSubDir$filename, layers: @layers");
			if ($firstLineProc) {
				$_ = <FILE>;
				eval $firstLineProc;
				$logger->error("eval firstLineProc: ".$firstLineProc.$@.longmess()) if ($@);
				$logger->debug("evaled: ".$firstLineProc);
				$lines--;
			}
			if ($skip) {
				$skip-- if $firstLineProc; # if consumed already by firstLineProc skip one row less
				$logger->debug("skipping ".($skip =~ /^\d+$/ ? " $skip lines" : "until line contains $skip (inclusive)"));
				# skip first $skip rows in file (e.g. report header) if $skip is an integer, if $skip is non-integer, skip until the text $skip appears (inclusive)
				if ($skip =~ /^\d+$/) {
					for (1 .. $skip) {$_ = <FILE>};
					$lines-=$skip;
				} else {
					while (<FILE>) {
						$lines--;
						last if /$skip/;
					}
				}
			}
			# assumption: header exists in file and format_header should be derived from there
			if ($autoheader) {
				$sep = "," if !$sep;
				$_ = <FILE>; chomp;
				@header = split $sep;
				@targetheader = @header;
				$logger->debug("autoheader set, sep: [".$sep."], headings: @header");
			}
			# iterate through all rows of file
			my $lineno = 0;
			my (@line,@previousline);
LINE:
			while (<FILE>) {
				chomp;
				# in case lineProcessing or addtlProcessing needs access to whole row -> $rawline
				my $rawline = $_;
				# skip empty rows
				next LINE if $_ eq "";
				@previousline = @line;
				if ($isFixLen) {
					@line = undef;
					for (my $i=0;$i < scalar @header; $i++) {
						$line[$i] = substr ($_, $poslen->[$i][0],$poslen->[$i][1]-$poslen->[$i][0]);
					}
				} else {
					if ($File->{format_quotedcsv}) {
						if ($sv->parse($_)) {
							@line = $sv->fields();
						} else {
							$logger->error("couldn't parse quoted csv row: ".$sv->error_diag().longmess());
						}
					} else {
						@line = split $sep;
					}
				}
				$lineno++;
				print "EAI::File::readText read $lineno of $lines\r" if ($countPercent and ($lineno % (int($lines * ($countPercent / 100)) == 0 ? 1 : int($lines * ($countPercent / 100))) == 0)) or $countPercent >= 100;
				next LINE if $line[0] eq "" and !$lineProcessing;
				readRow($data,\@line,\@header,\@targetheader,$rawline,$lineProcessing,$fieldProcessing,$thousandsep,$decimalsep,$lineno);
			}
		}
		close FILE;
	}
	if (!$data or !@{$data}) {
		if ($File->{emptyOK}) {
			$logger->warn("no data retrieved from file(s): @filenames, will be ignored because \$File{emptyOK}".longmess());
		} else {
			$logger->error("no data retrieved from file(s): @filenames".longmess());
		}
		return 0;
	}
	if ($logger->is_trace) {
		$logger->trace("amount of rows:".scalar(@{$data})) if $data;
		$Data::Dumper::Deepcopy = 1;
		$logger->trace(Dumper($data));
		$Data::Dumper::Deepcopy = 0;
	}
	return 1;
}

# global variables for excel parsing
my $startRowHeader; # header row for check (if format_header is defined), needed globally to avoid accidental date formatting
my %dateColumn; # lookup for columns with date values (key: excel column, numeric, starting with 1, value: 1 (boolean))
my %headerColumn; # lookup for header (key: excel column, numeric, starting with 1, actual column of header field, value: 1 (boolean))
my $worksheet; # worksheet to be read, old format (numeric, starting with 1)
my %dataRows; # intermediate storage for row values
my $maxRow; # bottom most row
my $stoppedOnEmptyValue; 
my $stopOnEmptyValueColumn;

# event handler for readExcel (xls format)
sub cell_handler {
	my $workbook    = $_[0];
	# for the Spreadsheet::ParseExcel index, rows and columns are 0 based, generally row semantics is 1 based
	my $sheet_index = $_[1]+1;
	my $row         = $_[2]+1;
	my $col         = $_[3]+1;
	my $cell        = $_[4];
	my $logger = get_logger();
	return unless $sheet_index eq $worksheet; # only parse desired worksheet
	if ($headerColumn{$col}) {
		if (($stopOnEmptyValueColumn eq $col && !$cell) || $stoppedOnEmptyValue) {
			$logger->warn("empty cell in row $row / column $col and stopOnEmptyValueColumn is set to $col, skipping from here now".longmess()) if !$stoppedOnEmptyValue; # pass warning only once
			$stoppedOnEmptyValue = 1;
		} else {
			$logger->trace("Row $row, Column $col:\n".Dumper($cell)) if $logger->is_trace;
			if ($dateColumn{$col} and $row != $startRowHeader) {
				# with date values need value(), otherwise (unformatted) a julian date (decimal representing date and time) is returned
				# parse from US date format into YYYYMMDD, time parts are still ignored!
				if ($cell) {
					my ($m,$d,$y) = ($cell->value() =~ /(\d+?)\/(\d+?)\/(\d{4})/);
					$dataRows{$row}{$col} = sprintf("%04d%02d%02d",$y,$m,$d);
				}
			} else {
				# non date values are fetched unformatted
				$dataRows{$row}{$col} = $cell->unformatted() if $cell;
			}
			$maxRow = $row if $maxRow < $row;
			#$logger->info(Dumper($cell));
			#my $stopHere = <STDIN>; # for step debugging, uncomment these 2 lines
		}
	}
}

my $countPercentExcel;
# event handler for readExcel (xlsx format)
sub row_handlerXLSX {
	my $rowDetails = $_[1];
	my $logger = get_logger();
	# for the Data::XLSX::Parser index, rows and columns are 1 based
	for my $cellDetail (@$rowDetails) {
		my $row = $cellDetail->{"row"};
		my $col = $cellDetail->{"c"};
		my $value = $cellDetail->{"v"};
		if ($headerColumn{$col}) {
			if (($stopOnEmptyValueColumn eq $col && !$value) || $stoppedOnEmptyValue) {
				$logger->warn("empty cell in row $row / column $col and stopOnEmptyValueColumn is set to $col, skipping from here now".longmess()) if !$stoppedOnEmptyValue; # pass warning only once
				$stoppedOnEmptyValue = 1;
			} else {
				$logger->trace("Row $row, Column $col:\n".Dumper($cellDetail)) if $logger->is_trace;
				if ($dateColumn{$col} and $row != $startRowHeader) {
					# date fields are converted from epoch format !
					$dataRows{$row}{$col} = convertEpochToYYYYMMDD($value);
				} else {
					# non date values taken directly
					$dataRows{$row}{$col} = $value;
				}
				$maxRow = $row if $maxRow < $row;
			}
		}
		print "EAI::File::readExcel read $row rows\r" if $countPercentExcel and ($row % 50 == 0);
	}
}

# read Excel file (format depends on setting)
sub readExcel ($$$;$$) {
	my ($File,$data,$filenames,$redoSubDir,$countPercent) = @_;
	$countPercentExcel = $countPercent if $countPercent;
	my $logger = get_logger();
	$stopOnEmptyValueColumn = $File->{format_stopOnEmptyValueColumn};
	$stoppedOnEmptyValue = 0; # reset
	my @filenames = @{$filenames} if $filenames;
	if (!@filenames) {
		$logger->error("no filenames passed".longmess());
		return 0;
	}
	# reset module global variables
	undef %dateColumn;
	undef %headerColumn;
	# read format configuration
	my ($lineProcessing,$fieldProcessing,$firstLineProc,$thousandsep,$decimalsep,$sep,$skip,$header,$targetheader) = getcommon($File);
	my @header = @$header; my @targetheader = @$targetheader;
	if (!@targetheader) {
		$logger->error("no targetheader defined".longmess()); # targetheader has to be given, excel source header (@header) optional
		return 0;
	}
	$logger->debug("skip: $skip,headerskip: ". $File->{format_headerskip}.", header: @header \ntargetheader: @targetheader\ndateColumns: ".($File->{format_dateColumns} ? @{$File->{format_dateColumns}} : "")."\nheaderColumns: ".($File->{format_headerColumns} ? @{$File->{format_headerColumns}} : ""));
	# prepare dateColumn definition if needed/given
	if ($File->{format_dateColumns} and ref($File->{format_dateColumns}) eq "ARRAY") {
		for my $col (@{$File->{format_dateColumns}}) {
			$dateColumn{$col} = 1;
		}
	}
	# prepare headerColumn definition
	if ($File->{format_headerColumns} and ref($File->{format_headerColumns}) eq "ARRAY") {
		if (@{$File->{format_headerColumns}} != @header or @{$File->{format_headerColumns}} != @targetheader) {
			$logger->error("format_headerColumns has different length than format_header or format_targetheader definitions".longmess());
			return 0;
		}
		for my $col (@{$File->{format_headerColumns}}) {
			$headerColumn{$col} = 1;
		}
	} else {
		if (@header and @header != @targetheader) {
			$logger->error("format_header has different length than format_targetheader definition".longmess());
			return 0;
		}
		$logger->debug("no format_headerColumns given, assuming simple list starting with column 1, having \@header length columns and a header row") if @header;
		$logger->debug("no format_headerColumns and no header definition given, assuming simple list starting with column 1, having \@targetheader length columns and no header row") if !@header;
		for (my $i = 0; $i < @targetheader; $i++) {
			$headerColumn{$i+1} = 1;
		}
	}
	$logger->debug("headerColumn:".Dumper(\%headerColumn).",dateColumn:".Dumper(\%dateColumn));
	@header = @targetheader if !@header; # in the end only target header is important
	# read all files with same format
	for my $filename (@filenames) {
		my $startRow = 1; # starting data row
		$startRowHeader = 1; # starting header row for check (if format_header is defined)
		if ($skip =~ /^\d+$/) {
			$logger->debug("skipping ".$skip." rows for data begin"); 
			$startRow += $skip; # skip additional rows for data begin, row semantics is 1 based
		}
		if ($File->{format_headerskip}) {
			$logger->debug("skipping ".$File->{format_headerskip}." rows for header row (1)"); 
			$startRowHeader += $File->{format_headerskip}; # skip additional rows for header row, row semantics is 1 based
		}
		if (!$skip and $File->{format_header}) {
			$logger->debug("setting data begin to \$startRowHeader ($startRowHeader) + 1 as format_header given and no format_skip found"); 
			$startRow = $startRowHeader + 1; # set to header following row if format_skip not defined and format_header given
		}
		# reset module global variables
		%dataRows = ();
		$maxRow = 1;
		# check excel file existence
		if (! -e $redoSubDir.$filename) {
			$logger->error("no excel file ($filename) to process: $!") unless ($File->{optional});
			$logger->warn("no file $redoSubDir$filename found".longmess()); 
			return 0;
		}
		# read in excel file/sheet completely, both formats utilize read handlers (row_handlerXLSX or cell_handler)
		my $parser;
		if ($File->{format_xlformat} =~ /^xlsx$/i) {
			$logger->debug("open xlsx file $redoSubDir$filename ... ");
			$parser = Data::XLSX::Parser->new;
			$parser->open($redoSubDir.$filename);
			$parser->add_row_event_handler(\&row_handlerXLSX);
			if ($File->{format_worksheet}) {
				$worksheet = $parser->workbook->sheet_id($File->{format_worksheet});
				if (!$worksheet) {
					$logger->error("no xlsx worksheet found named ".$File->{format_worksheet}.", maybe try {format_worksheetID} (numerically ordered place)".longmess());
					return 0;
				}
			} elsif ($File->{format_worksheetID}) {
				$worksheet = $File->{format_worksheetID};
			} else {
				$logger->error("neither worksheetname nor worksheetID (numerically ordered place) given for xlsx workbook".longmess());
				return 0;
			}
			$logger->debug("starting parser for xlsx sheet name: ".$File->{format_worksheet}.", id:".$worksheet);
			eval { $parser->sheet_by_id($worksheet); };
			if ($@) {
				$logger->error("Error parsing xlsx sheet: ".$@.longmess());
				return 0;
			}
		} elsif ($File->{format_xlformat} =~ /^xls$/i) {
			$logger->warn("worksheets can't be found by name for the old xls format, please pass numerically ordered place in {format_worksheetID}".longmess()) if ($File->{format_worksheet});
			$worksheet = $File->{format_worksheetID} if $File->{format_worksheetID};
			$logger->debug("starting parser for xls file $redoSubDir$filename ... ");
			$parser = Spreadsheet::ParseExcel->new(
				CellHandler => \&cell_handler,
				NotSetCell  => 1
			);
			my $workbook = $parser->parse($redoSubDir.$filename);
			if (!defined $workbook) {
				$logger->error("excel xls parsing error: ".$parser->error().longmess());
				return 0;
			}
		} else {
			$logger->error("unrecognised excel format passed in \$File->{format_xlformat}:".$File->{format_xlformat}.longmess());
			return 0;
		}
		# check header row if format_header given
		if ($File->{format_header}) {
			$logger->info("checking header info in row $startRowHeader");
			if ($File->{format_headerColumns}) {
				my $i = 0;
				for (@{$File->{format_headerColumns}}) {
					$logger->error("expected header '".$header[$i]."' not in column ".$_.", instead got:".$dataRows{$startRowHeader}{$_}.longmess()) if $header[$i] ne $dataRows{$startRowHeader}{$_};
					$i++;
				}
			} else {
				for (my $i = 0; $i < @header; $i++) {
					$logger->error("expected header '".$header[$i]."' not in column ".($i+1).", instead got:".$dataRows{$startRowHeader}{$i+1}.longmess()) if $header[$i] ne $dataRows{$startRowHeader}{$i+1};
				}
			}
		}
		# now iterate data rows
		my (@line,@previousline);
		$logger->debug("(data) start row: $startRow, (data) end row: $maxRow");
LINE:
		# $maxRow is being set when reading in the sheet
		my $lines = $maxRow - $startRow;
		for my $lineno ($startRow .. $maxRow) {
			@previousline = @line;
			@line = undef;
			# get @line from stored values
			if ($File->{format_headerColumns}) {
				my $i = 0;
				for (@{$File->{format_headerColumns}}) {
					$line[$i] = $dataRows{$lineno}{$_};
					$i++;
				}
			} else {
				for (my $i = 0; $i < @header; $i++) {
					$line[$i] = $dataRows{$lineno}{$i+1};
				}
			}
			readRow($data,\@line,\@header,\@targetheader,undef,$lineProcessing,$fieldProcessing,$thousandsep,$decimalsep,$lineno);
			print "EAI::File::readExcel parsed $lineno of $lines\r" if $countPercent and ($lineno % (int($lines * ($countPercent / 100)) == 0 ? 1 : int($lines * ($countPercent / 100))) == 0);
		}
		close FILE;
		if (scalar(@{$data}) == 0 and !$File->{emptyOK}) {
			$logger->error("Empty file: $filename, no data returned !!".longmess());
			return 0;
		}
	}
	$logger->trace("amount of rows: ".scalar(@{$data})) if $logger->is_trace;
	$logger->trace(Dumper($data)) if $logger->is_trace;
	return 1;
}

# read XML file
sub readXML ($$$;$) {
	my ($File,$data,$filenames,$redoSubDir) = @_;
	my $logger = get_logger();
	my @filenames = @{$filenames} if $filenames;
	if (!@filenames) {
		$logger->error("no filenames passed".longmess());
		return 0;
	}
	# read format configuration
	my ($lineProcessing,$fieldProcessing,$firstLineProc,$thousandsep,$decimalsep,$sep,$skip,$header,$targetheader) = getcommon($File);
	my @header = @$header; my @targetheader = @$targetheader;
	if (!@header) {
		$logger->error("no header defined".longmess()); # targetheader has to be given, excel source header (@header) optional
		return 0;
	}
	$Data::Dumper::Terse = 1;
	$logger->debug("sep:".Data::Dumper::qquote($sep).",header:@header\ntargetheader:@targetheader");
	$Data::Dumper::Terse = 0;
	@targetheader = @header if !@targetheader; # if no specific targetheader defined use header instead
	# read all files with same format
	for my $filename (@filenames) {
		if (! -e $redoSubDir.$filename) {
			$logger->error("no XML file ($redoSubDir$filename) found to process".longmess()) unless ($File->{optional});
			$logger->warn("file $redoSubDir$filename not found".longmess());
			return 0;
		}
		my $xmldata = XML::LibXML->load_xml(location => $redoSubDir.$filename, no_blanks => 1);
		my $xpc = XML::LibXML::XPathContext->new($xmldata);
		if (ref($File->{format_namespaces}) eq 'HASH') {
			$xpc->registerNs($_, $File->{format_namespaces}{$_}) for keys (%{$File->{format_namespaces}});
		}
		$logger->error("no format_xpathRecordLevel passed".longmess()) unless ($File->{format_xpathRecordLevel});
		$logger->error("no format_fieldXpath hash passed".longmess()) unless ($File->{format_fieldXpath} && ref($File->{format_fieldXpath}) eq 'HASH');
		$logger->trace("format_xpathRecordLevel: ".$File->{format_xpathRecordLevel}) if $logger->is_trace;
		$logger->trace("format_fieldXpath: ".Dumper($File->{format_fieldXpath})) if $logger->is_trace;
		my @records = $xpc->findnodes($File->{format_xpathRecordLevel});
		$logger->warn("no records found".longmess()) if @records == 0;
		$logger->trace("total document content: ".$xpc->getContextNode->toClarkML()) if $logger->is_trace;
		# iterate through all rows of file
		my $lineno = 0;
		foreach my $record (@records) {
			my @line;
			# get @line from stored values
			if (ref($record) eq "XML::LibXML::Element") {
				$logger->trace("node content: ".$record->toClarkML()) if $logger->is_trace;
				my @headerColumns = keys (%{$File->{format_fieldXpath}});
				for (my $i = 0; $i < @headerColumns; $i++) {
					$logger->trace("field:".$header[$i].",\$File->{format_fieldXpath}{".$header[$i]."}:".$File->{format_fieldXpath}{$header[$i]}) if $logger->is_trace;
					if ($File->{format_fieldXpath}{$header[$i]} =~ /^\//) {
						# absolute paths -> leave context node and find in the root doc (no context node argument)
						$logger->trace("absolute fieldXpath:".$File->{format_fieldXpath}{$header[$i]}) if $logger->is_trace;
						$line[$i] = $xpc->findvalue($File->{format_fieldXpath}{$header[$i]});
					} else {
						# relative paths -> context node is current record node
						$logger->trace("relative fieldXpath:".$File->{format_fieldXpath}{$header[$i]}) if $logger->is_trace;
						$line[$i] = $xpc->findvalue($File->{format_fieldXpath}{$header[$i]}, $record);
					}
				}
			}
			$lineno++;
			readRow($data,\@line,\@header,\@targetheader,$xpc,$lineProcessing,$fieldProcessing,$thousandsep,$decimalsep,$lineno);
		}
		if (!$data and !$File->{emptyOK}) {
			$logger->error("empty file: $filename, no data returned".longmess());
			return 0;
		}
	}
	return 1;
}

# to be able to access these variables in fieldCode and/or lineCode anonymous subs, they have to be package global. Access in anon sub is then done with %EAI::File::line, @EAI::File::header or $EAI::File::i (this column loop var is only meaningful in fieldCode)
our (%line,%templine,$i,@line,@header,@targetheader,$skipLineAssignment,$lineno,$rawline);

# read row into final line hash (including special "hook" code)
sub readRow ($$$$$$$$$$) {
	my ($data,$line,$header,$targetheader,$lineProcessing,$fieldProcessing,$thousandsep,$decimalsep);
	($data,$line,$header,$targetheader,$rawline,$lineProcessing,$fieldProcessing,$thousandsep,$decimalsep,$lineno) = @_;
	@line = @$line;
	@header = @$header;
	@targetheader = @$targetheader;
	my $logger = get_logger();
	$skipLineAssignment = 0; # can be set in fieldCode, to avoid further assignment to data.
	%line=(); %templine=();

	$logger->trace("line:@{$line},header:@{$header},targetheader:@{$targetheader},rawline:$rawline,lineProcessing:$lineProcessing,thousandsep:$thousandsep,decimalsep:$decimalsep,lineno:$lineno") if $logger->is_trace;
	# iterate through fields of current row
	for ($i = 0; $i < @line; $i++) {
		# first trim leading and trailing spaces
		$line[$i] =~ s/^ *//;
		$line[$i] =~ s/ *$//;
		# remove thousand separators for numerals based on configured thousand/decimal separator and change decimal separator to \d+\.?\d*
		$line[$i] =~ s/$thousandsep//g if $line[$i] =~ /^-?\d{1,3}($thousandsep\d{3})+($decimalsep\d*)?$/;
		if ($decimalsep ne "\\.") {
			$line[$i] =~ s/$decimalsep/\./ if $line[$i] =~ /^-?\d+$decimalsep\d+$/ or $line[$i] =~ /^-*\d*$decimalsep?\d+E*[-+]*\d*$/;
		}
		
		# only process as targetheader, if they are not the same as the original header (allows special access to original header via $templine/$previoustempline)
		if ($header[$i] ne $targetheader[$i]) {
			# prevent autovivification of hash entries, if $i is potentially > @header or > @targetheader
			$line{$targetheader[$i]} = $line[$i] if $targetheader[$i];
			$templine{$header[$i]} = $line[$i] if $header[$i];
		} else {
			$line{$header[$i]} = $line[$i] if $header[$i];
		}
		# field specific processing set, augments processing for a single specific field specified by targetheader...
		if ($fieldProcessing->{$targetheader[$i]}) {
			$logger->trace('specific fieldProcessing: $targetheader['.$i.']:'.$targetheader[$i].',$line{'.$targetheader[$i].']:'.$line{$targetheader[$i]}.',fieldProcessing{',$targetheader[$i],'}:'.$fieldProcessing->{$targetheader[$i]}) if $logger->is_trace;
			if (ref($fieldProcessing->{$targetheader[$i]}) eq "CODE") {
				eval {$fieldProcessing->{$targetheader[$i]}->()};
			} else {
				eval $fieldProcessing->{$targetheader[$i]};
			}
			$logger->error("eval of ".(ref($fieldProcessing->{$targetheader[$i]}) eq "CODE" ? "defined sub" : "'".$fieldProcessing->{$targetheader[$i]}."'")." returned error:$@".longmess()) if ($@);
		} elsif ($fieldProcessing->{""}) { # special case: if empty key is defined with processing code, do for all fields
			$logger->trace('general fieldProcessing: $targetheader['.$i.']:'.$targetheader[$i].',$line{'.$targetheader[$i].']:'.$line{$targetheader[$i]}.',fieldProcessing{',$targetheader[$i],'}:'.$fieldProcessing->{$targetheader[$i]}) if $logger->is_trace;
			if (ref($fieldProcessing->{""}) eq "CODE") {
				eval {$fieldProcessing->{""}->()};
			} else {
				eval $fieldProcessing->{""};
			}
			$logger->error("eval of ".(ref($fieldProcessing->{""}) eq "CODE" ? "defined sub" : "'".$fieldProcessing->{""}."'")." returned error:$@".longmess()) if ($@);
		}
	}
	# additional row processing defined
	if ($lineProcessing) {
		if (ref($lineProcessing) eq "CODE") {
			eval {$lineProcessing->()};
		} else {
			eval $lineProcessing;
		}
		$logger->error("eval of ".(ref($lineProcessing) eq "CODE" ? "defined sub" : "'".$lineProcessing."'")." returned error:$@".longmess()) if ($@);
	}
	$logger->trace("\$skipLineAssignment: $skipLineAssignment, \%line:\n".Dumper(\%line)) if $logger->is_trace;
	# add reference to created line (don't do push @{$data}, \%line here as then subsequent lines will overwrite all before!)
	push @{$data}, {%line} if keys %line > 0 and !$skipLineAssignment;
}

our $value;
# write text file
sub writeText ($$;$) {
	my ($File,$data,$countPercent) = @_;
	my $logger = get_logger();
	my $filename = $File->{filename};
	my $writemode = ($File->{append} ? ">>" : ">");
	$logger->debug("sepHead: ".Data::Dumper::qquote($File->{format_sepHead}).", sep: ".Data::Dumper::qquote($File->{format_sep}));
	if (ref($data) ne 'ARRAY') {
		$logger->error("passed data in \$data is not a ref to array (you have to initialize it as an array):".Dumper($data).longmess());
		return 0;
	}
	# in case we need to print out csv/quoted values
	my $sv;
	if ($File->{format_quotedcsv}) {
		$sv = Text::CSV->new ({
			binary    => 1,
			auto_diag => 1,
			sep_char  => $File->{format_sep},
			eol => ($File->{format_eol} ? $File->{format_eol} : $/),
		});
	}
	my @columnnames; my @paddings;
	if (ref($File->{columns}) eq 'HASH') {
		@columnnames = map {$File->{columns}{$_}} sort keys %{$File->{columns}};
	} elsif (ref($File->{columns}) eq 'ARRAY') {
		@columnnames = @{$File->{columns}};
	} else {
		$logger->error("no field information given (columns should be ref to array or ref to hash, you have to initialize it as that)".longmess());
		return 0;
	}
	if (ref($File->{format_padding}) eq 'ARRAY') {
		@paddings = @{$File->{format_padding}};
	} elsif (ref($File->{format_padding}) eq 'HASH') {
		@paddings = map {$File->{format_padding}{$_}} sort keys %{$File->{format_padding}};
	} else {
		if ($File->{format_fix}) {
			$logger->error("no padding information given for fixed length format (padding => ref to array or hash)".longmess());
			return 0;
		}
	}
	$logger->debug("fields: @columnnames");
	$logger->debug("paddings: @paddings");
	my $headerRow;
	my $col = 0; # iterate through @paddings in parallel.
	my $firstcol = 1;
	for my $colname (@columnnames) {
		if (!$File->{columnskip}{$colname}) {
			if ($File->{format_quotedcsv}) {
				push @$headerRow, $colname;
			} else {
				# first column has no separator before. if there is a special separator for heading, then use it, else the standard one
				$headerRow = $headerRow.($firstcol ? "" : ($File->{format_sepHead} ? $File->{format_sepHead} : $File->{format_sep})).$colname if (!$File->{format_fix});
				$headerRow = $headerRow.sprintf("%-*s%s", $paddings[$col],$colname) if ($File->{format_fix});
				$firstcol = 0;
			}
		}
		$col++;
	}
	# open file for writing
	$logger->info("writing to $filename ($writemode)");
	open (FHOUT, $writemode.$File->{format_encoding},$filename) or do {
		$logger->error("couldn't open $filename for writing (writemode $writemode): $!".longmess());
		return 0;
	};
	# write header
	print FHOUT $File->{format_beforeHeader} if $File->{format_beforeHeader};
	unless ($File->{format_suppressHeader}) {
		if ($File->{format_quotedcsv}) {
			if (!$sv->print(\*FHOUT, $headerRow)) {
				$logger->error("error writing quoted csv header row: ".$sv->error_diag().longmess());
				return 0;
			}
		} else {
			print FHOUT $headerRow."\n";
		}
	}
	# write data
	$logger->trace("passed data:\n".Dumper($data)) if $logger->is_trace;
	my $lines = scalar(@{$data});
	for (my $i=0; $i<$lines; $i++) {
		# data row
		my $row = $data->[$i];
		my $lineRow;
		# chain all data in a row
		my $col = 0; $firstcol = 1;
		for my $colname (@columnnames) {
			if (!$File->{columnskip}{$colname}) {
				if (ref($row) ne "HASH") {
					$logger->error("row passed in (\$data) is no ref to hash! should be \$VAR1 = {'key' => 'value', ...}:\n".Dumper($row).longmess());
					return 0;
				}
				$value = $row->{$colname};
				$logger->trace("\$value for \$colname $colname: $value") if $logger->is_trace;
				if ($File->{addtlProcessingTrigger} && $File->{addtlProcessing}) {
					my $doAddtlProcessing = eval $File->{addtlProcessingTrigger};
					if ($@) {
						$logger->error("error in eval addtlProcessingTrigger: ".$File->{addtlProcessingTrigger}.":".$@.longmess());
						return 0;
					}
					if ($doAddtlProcessing) {
						if (ref( $File->{addtlProcessing}) eq "CODE") {
							eval {$File->{addtlProcessing}->()};
						} else {
							eval $File->{addtlProcessing};
						}
						if ($@) {
							$logger->error("error in eval addtlProcessing: ".$File->{addtlProcessing}.":".$@.longmess());
							return 0;
						}
						$logger->trace("\$value after addtlProcessing: $value") if $logger->is_trace;
					}
				}
				if ($File->{format_quotedcsv}) {
					push @$lineRow, $value;
				} else {
					# last column ($columnnames[@columnnames-1]) should not have a separator afterwards
					$lineRow = $lineRow.($firstcol ? "" : $File->{format_sep}).sprintf("%s", $value) if (!$File->{format_fix});
					# additional padding for fixed length format
					$lineRow = $lineRow.sprintf("%-*s%s", $paddings[$col],$value) if ($File->{format_fix});
					$firstcol = 0;
				}
			}
			$col++;
		}
		if ($File->{format_quotedcsv}) {
			if (!$sv->print(\*FHOUT, $lineRow)) {
				$logger->error("error writing quoted csv row: ".$sv->error_diag().longmess());
				return 0;
			}
			$logger->trace("row: @$lineRow") if $logger->is_trace;
		} else {
			print FHOUT $lineRow."\n";
			$logger->trace("row: ".$lineRow) if $logger->is_trace;
		}
		print "EAI::File::writeText written $i of $lines\r" if $countPercent and ($i % (int($lines * ($countPercent / 100)) == 0 ? 1 : int($lines * ($countPercent / 100))) == 0);
	}
	close FHOUT;
	return 1;
}

# write Excel file
sub writeExcel ($$;$) {
	my ($File,$data,$countPercent) = @_;
	my $logger = get_logger();
	
	if (ref($data) ne 'ARRAY') {
		$logger->error("passed data in \$data is not a ref to array:".Dumper($data).longmess());
		return 0;
	}
	my @columnnames;
	if (ref($File->{columns}) eq 'HASH') {
		@columnnames = map {$File->{columns}{$_}} sort keys %{$File->{columns}};
	} elsif (ref($File->{columns}) eq 'ARRAY') {
		@columnnames = @{$File->{columns}}; 
	} else {
		$logger->error("no field information given (columns should be ref to array or ref to hash, you have to initialize it as that)".longmess());
		return 0;
	}
	my ($workbook,$worksheet);
	if ($File->{format_xlformat} =~ /^xls$/i) {
		$logger->debug("writing to xls format file ".$File->{filename});
		$workbook = Spreadsheet::WriteExcel->new($File->{filename}) or do {
			$logger->error("xls file creation error: $!".longmess());
			return 0;
		};
	} elsif ($File->{format_xlformat} =~ /^xlsx$/i) {
		$logger->debug("writing to xlsx format file ".$File->{filename});
		$workbook = Excel::Writer::XLSX->new($File->{filename}) or do {
			$logger->error("xlsx file creation error: $!".longmess());
			return 0;
		};
	} else {
		$logger->error("unrecognised excel format passed in \$File->{format_xlformat}:".$File->{format_xlformat}." (allowed: xls and xlsx)".longmess());
		return 0;
	}
	# Add a worksheet
	$worksheet = $workbook->add_worksheet();
	$logger->debug("fields: @columnnames");
	my @headerRow;
	for my $colname (@columnnames) {
		if (!$File->{columnskip}{$colname}) {
			push @headerRow, $colname;
		}
	}
	# write header
	unless ($File->{format_suppressHeader}) {
		for my $col (0 .. @headerRow) {
			$worksheet->write(0,$col,$headerRow[$col]);
		}
	}
	# write data
	$logger->trace("passed data:\n".Dumper($data)) if $logger->is_trace;
	my $lines = scalar(@{$data});
	for (my $i=0; $i<$lines; $i++) {
		# data row
		my $row = $data->[$i];
		my @lineRow;
		# chain all data in a row
		for my $colname (@columnnames) {
			if (!$File->{columnskip}{$colname}) {
				$logger->error("row passed in (\$data) is no ref to hash! should be \$VAR1 = {'key' => 'value', ...}:\n".Dumper($row).longmess()) if (ref($row) ne "HASH");
				my $value = $row->{$colname};
				$logger->trace("\$value for \$colname $colname: $value") if $logger->is_trace;
				if ($File->{addtlProcessingTrigger} && $File->{addtlProcessing}) {
					eval $File->{addtlProcessingTrigger} if (eval $File->{addtlProcessingTrigger});
					$logger->error("error in eval addtlProcessing: ".$File->{addtlProcessingTrigger}.":".$@.longmess()) if ($@);
				}
				push @lineRow, $value;
			}
		}
		for my $col (0 .. @lineRow) {
			$worksheet->write($i+1,$col,$lineRow[$col]);
		}
		print "EAI::File::writeExcel written $i of $lines\r" if $countPercent and ($i % (int($lines * ($countPercent / 100)) == 0 ? 1 : int($lines * ($countPercent / 100))) == 0);
		$logger->trace("row: @lineRow") if $logger->is_trace();
	}
	$workbook->close();
	return 1;
}
1;
__END__

=head1 NAME

EAI::File - read/parse Files from the filesystem or write to the filesystem

=head1 SYNOPSIS

 readText ($File, $data, $filenames, $redoSubDir, $countPercent)
 readExcel ($File, $data, $filenames, $redoSubDir)
 readXML ($File, $data, $filenames, $redoSubDir)
 writeText ($File, $data)
 writeExcel ($File, $data)

=head1 DESCRIPTION

EAI::File contains all file parsing API-calls. This is for reading plain text data (also as quoted csv), reading excel data (old 2003 and new 2007+ format), reading xml data, writing plain text data and excel files.

=head2 API

=over

=item readText ($$$;$$)

reads the defined text file with specified parameters into array of hashes (DB ready structure)

 $File      .. hash ref for File specific configuration
 $data      .. hash ref for returned data (hashkey "data" -> above mentioned array of hashes)
 $filenames .. array of file names, if explicit (given in case of mget and unpacked zip archives).
 $redoSubDir .. (optional) redo subdirectory, where file can be taken alternatively to homedir.
 $countPercent .. (optional) percentage of progress where indicator should be output (e.g. 10 for all 10% of progress). set to 0 to disable progress indicator

returns 0 on error, 1 if OK

=item readExcel ($$$;$$)

reads the defined excel file with specified parameters into array of hashes (DB ready structure)

 $File      .. hash ref for File specific configuration
 $data      .. hash ref for returned data (hashkey "data" -> above mentioned array of hashes)
 $filenames .. array of file names, if explicit (given in case of mget and unpacked zip archives).
 $redoSubDir .. (optional) redo subdirectory, where file can be taken alternatively to homedir.
 $countPercent .. (optional) percentage of progress where indicator should be output (e.g. 10 for all 10% of progress). set to 0 to disable progress indicator

returns 0 on error, 1 if OK

=item readXML ($$$;$)

reads the defined XML file with specified parameters into array of hashes (DB ready structure)

 $File      .. hash ref for File specific configuration
 $data      .. hash ref for returned data (hashkey "data" -> above mentioned array of hashes)
 $filenames .. array of filenamea, if explicit (given in case of mget and unpacked zip archives).
 $redoSubDir .. (optional) redo subdirectory, where file can be taken alternatively to homedir.

returns 0 on error, 1 if OK

For all read<*> functions custom "hooks" can be defined with L<fieldCode|/fieldCode> and L<lineCode|/lineCode> to modify and enhance the standard mapping defined in format_header. To access the final line data the hash %EAI::File::line can be used (specific fields with $EAI::File::line{<target header column>}). if a field is being replaced using a different name from targetheader, the data with the original header name is placed in %EAI::File::templine. You can also access data from the previous line with %EAI::File::previousline and the previous temp line with %EAI::File::previoustempline.

=item writeText ($$;$)

writes a text file using specified parameters from array of hashes (DB structure) 

 $File      .. hash ref for File specific configuration
 $data      .. hash ref for returned data (hashkey "data" -> above mentioned array of hashes)
 $countPercent .. (optional) percentage of progress where indicator should be output (e.g. 10 for all 10% of progress). set to 0 to disable progress indicator

returns 0 on error, 1 if OK

=item writeExcel ($$;$)

writes an excel file using specified parameters from array of hashes (DB structure) 

 $File      .. hash ref for File specific configuration
 $data      .. hash ref for returned data (hashkey "data" -> above mentioned array of hashes)
 $countPercent .. (optional) percentage of progress where indicator should be output (e.g. 10 for all 10% of progress). set to 0 to disable progress indicator

returns 0 on error, 1 if OK

=back

=head1 COPYRIGHT

Copyright (c) 2024 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut