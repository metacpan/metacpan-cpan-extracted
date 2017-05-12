#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Spec;

use MIME::Tools;
use MIME::Decoder;

#------------------------------------------------------------
# BEGIN
#------------------------------------------------------------

# Is gzip available?  Quick and dirty test:
my $has_gzip;
foreach (split $^O eq "MSWin32" ? ';' : ':', $ENV{PATH}) {
    last if ($has_gzip = -x "$_/gzip");
}
if ($has_gzip) {
   require MIME::Decoder::Gzip64;
   install MIME::Decoder::Gzip64 'x-gzip64';
}

# Get list of encodings we think we provide:
my @encodings = ('base64',
		 'quoted-printable',
		 '7bit',
		 '8bit',
		 'binary',
		 ($has_gzip ? 'x-gzip64' : ()),
		 'x-uuencode',
		 'binhex');

plan( tests => scalar @encodings);

# Report what tests we may be skipping:
diag($has_gzip
	? "Using gzip: $has_gzip"
	: "No gzip: skipping x-gzip64 test");

# Test each encoding in turn:
my ($e, $eno) = (undef, 0);
foreach $e (@encodings) {
    ++$eno;
    my $warning;
    local $SIG{__WARN__} = sub {
	$warning = $@;
    };
    my $decoder = MIME::Decoder->new($e);
    unless(defined($decoder)) {
	my $msg = "Encoding/decoding of $e not supported -- skipping test";
	if( $warning =~ /^Can't locate ([^\s]+)/ ) {
		$msg .= " (Can't locate $1)";
	}
	pass($msg);
	next;
    }

    my $infile  = File::Spec->catfile('.', 'testin', 'fun.txt');
    my $encfile = File::Spec->catfile('.', 'testout', "fun.en$eno");
    my $decfile = File::Spec->catfile('.', 'testout', "fun.de$eno");

    # Encode:
    open IN, "<$infile" or die "open $infile: $!";
    open OUT, ">$encfile" or die "open $encfile: $!";
    binmode IN; binmode OUT;
    $decoder->encode(\*IN, \*OUT) or next;
    close OUT;
    close IN;

    # Decode:
    open IN, "<$encfile" or die "open $encfile: $!";
    open OUT, ">$decfile" or die "open $decfile: $!";
    binmode IN; binmode OUT;
    $decoder->decode(\*IN, \*OUT) or next;
    close OUT;
    close IN;

    # Can we compare?
    if ($e =~ /^(binhex|base64|quoted-printable|binary|x-gzip64|x-uuencode)$/i) {
	is(-s $infile, -s $decfile, "Encoding/decoding of $e: size of $infile == size of $decfile");
    }
    else {
	pass("Encoding/decoding of $e: size not comparable, marking pass anyway");
    }
}
