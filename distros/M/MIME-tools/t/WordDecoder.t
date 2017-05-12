#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 22;

use MIME::QuotedPrint qw(decode_qp);
use MIME::WordDecoder;

use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $mwd = (new MIME::WordDecoder::ISO_8859 1);
{
    local($/) = '';
    open WORDS, "<testin/words.txt" or die "open: $!";
    while (<WORDS>) {
	s{\A\s+|\s+\Z}{}g;    # trim

	my ($isgood, $expect, $enc) = split /\n/, $_, 3;

	# Create the expected data
	$expect = eval $expect;

	my $dec = $mwd->decode($enc);
	if( $isgood eq 'GOOD' ) {
		ok( ! $@, 'No exceptions');
		is( $dec, $expect, "$enc produced correct output");
	} else {
		ok( $@, 'Got an exception as expected');
	}

    }
    close WORDS;
}

my $wd = supported MIME::WordDecoder 'UTF-8';
my $perl_string = $wd->decode('To: =?ISO-8859-1?Q?J=F8rn?= <keld>');
is($perl_string, "To: J\x{00f8}rn <keld>", 'Got back expected UTF-8 string');
is(utf8::is_utf8($perl_string), 1, 'Converted string has UTF-8 flag on');

$perl_string = mime_to_perl_string('To: =?ISO-8859-1?Q?J=F8rn?= <keld>');
is($perl_string, "To: J\x{00f8}rn <keld>", 'Got back expected UTF-8 string');
is(utf8::is_utf8($perl_string), 1, 'Converted string has UTF-8 flag on');
