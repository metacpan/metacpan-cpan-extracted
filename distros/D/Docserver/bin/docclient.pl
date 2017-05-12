#!/usr/bin/perl -w

$^W = 1;
use strict;

use Getopt::Long;
use Docclient;
my $win_to_il2;
eval ' use Cz::Cstocs; $win_to_il2 = new Cz::Cstocs qw( 1250 il2 ); ';

use Text::Tabs;
my $tabstop = 8;	# implicit tab skip
my $WIDTH = 72;

my %options;

my $stdin = 0;
if (defined $ARGV[$#ARGV] and $ARGV[$#ARGV] eq '-')
	{ pop @ARGV; $stdin = 1; }

Getopt::Long::GetOptions( \%options,
	qw( raw help debug version server=s host=s port=s
		out_format=s in_format=s out_file=s
		server_version )
			) or exit;

if (not defined $options{'in_format'} and not defined $options{'out_format'}) {
	@options{'in_format', 'out_format'} = ($0 =~ m!([^/\\]+)2([^/\\]+)$!);
}
$options{'in_format'} = 'doc' unless defined $options{'in_format'};
$options{'out_format'} = 'txt' unless defined $options{'out_format'};

if ($stdin or not @ARGV) { push @ARGV, '-' }

sub print_version {
	print "This is docclient version $Docclient::VERSION.\n";
}

if (defined $options{'help'}) {
	print_version();
	print <<"EOF";
usage: docclient [ options ] [ files ]
    where options is some of
	--host=host
	--server=host		name or address of your docserver
				(default $Docclient::Config::Config{'server'})
	--port=number		port number on your docserver
				(default $Docclient::Config::Config{'port'})
	--in_format=format	input format (default $options{'in_format'})
	--out_format=format	output format (default $options{'out_format'})
	--raw			do not clean the output in any way
	--version		client version info
	--server_version	server version info
	--help			this help
    Available in/out format names depend on your server configuration
    but the input generaly is doc, txt, rtf or html for text
    documents, xls for Excel documents and csv for semicolon separated
    values; the output possibilities are txt, txt1, html, doc95, ps
    and ps1 for Word conversions and cvs, txt, xls, html for Excel.
EOF
	exit;
}
if (defined $options{'version'}) {
	print_version();
	exit;
}
if (defined $options{'debug'}) {
	$Docclient::DEBUG = 1;
}

print STDERR "Debug set to $Docclient::DEBUG\n" if $Docclient::DEBUG;

if (defined $options{'out_file'}) {
	open OUTFILE, ">$options{'out_file'}"
		or die "Error writing $options{'out'}: $!\n"; 
	binmode OUTFILE; 
	*STDOUT = \*OUTFILE;
}

my $obj = new Docclient( %options )
	or die "Connection to remote host failed: $Docclient::errstr";

print STDERR "Got the Docclient object.\n" if $Docclient::DEBUG;

if (defined $options{'server_version'}) {
	my $server_version = $obj->server_version;
	print "This is docserver version $server_version.\n";
	exit;
}

for my $file (@ARGV) {
	local *FILE;
	my $size;
	if ($file eq '-') {
		*FILE = \*STDIN;
	} else {
		open FILE, $file or die "Error reading $file: $!\n";
		$size = -s $file;
	}
	binmode FILE;
	$obj->put_file(*FILE, $file, $size);
	close FILE;

	$obj->convert($obj->{'in_format'}, $obj->{'out_format'}) or
		die "Error converting the data: ", $obj->errstr;

	if (defined $obj->{'raw'}
		or not $obj->{'out_format'} =~ /^txt1?$|^html$|^csv$/) {
		binmode STDOUT;
		$obj->get_to_file(*STDOUT);
	} else {
		if ($obj->{'out_format'} =~ /^txt1?$/) {
			# get all to scalar value, clean, print
			&clean_and_print_txt_data($obj->get_to_scalar());
		} else {
			print &clean_charset($obj->get_to_scalar());
		}
	}
	$obj->finished;
}

sub clean_charset {
	if (defined $win_to_il2) {
		return &$win_to_il2($_[0]);
	}
	$_[0];
}

sub clean_and_print_txt_data {
	my $text = shift;

	# cancel spaces and LF at the end of lines
	$text =~ s/[ \t]*\r?\n/\n/g;

	# we do not want more than the subsequent empty lines
	$text =~ s/\n{3}\n+/\n\n\n/g;

	$text = &clean_charset($text);

	my $line;
	while ($text ne '' and $text =~ /(.*)\n/g) {
		my $line = $1;

		# expand tabulators
		$line = expand $line;

		# now try to fit the line into $WIDTH
		while ($line ne '') {
			my $length = length $line;
			if ($length <= $WIDTH) {
				print $line; last;
			}

			# we try to compress spaces
			my @spaces = map { length $_ } $line =~ /(\s{2,})/g;
			my $sum = 0;
			for (@spaces) { $sum += $_; }
			my $shorting = $sum - scalar @spaces;

			if ($length - $shorting <= $WIDTH) {
				my $expand = 1 - ($length - $WIDTH) / $shorting;
				$line =~ s/(\s{2,})/ ' ' x ($expand * shift @spaces) /ge;
				print $line; last;	
			}

			my $start;
			$start = substr $line, 0, $WIDTH + 1;
			$start =~ s/(\b\w)?\s+\S+$//;
			print $start, "\n";
			$line = substr $line, length $start;
			$line =~ s/^\s+//;
		}
		print "\n";
	}
}

1;

__END__

=head1 NAME

docclient - client for remote conversions of MS format documents

=head1 SYNOPSIS

	docclient.pl msword.doc > out.txt
	docclient.pl --out_format=html msword.doc > out.html

=head1 AUTHOR

(c) 1998--2002 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

Jan Pazdziora did the original client/server implementation and the
basic Win32::OLE stuff.

Michal Brandejs provided the code to clean up the output txt on the
client side.

Pavel Smerk added the code for other conversions (xls, HTML, ps, cvs).

=cut

