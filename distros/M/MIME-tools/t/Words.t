#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 20;

use MIME::QuotedPrint qw(decode_qp);
use MIME::Words qw( :all );

{
    local($/) = '';
    open WORDS, "<testin/words.txt" or die "open: $!";
    while (<WORDS>) {
	s{\A\s+|\s+\Z}{}g;    # trim

	my ($isgood, $expect, $enc) = split /\n/, $_, 3;

	# Create the expected data
	$expect = eval $expect;

	my $dec = decode_mimewords($enc);
	if( $isgood eq 'GOOD' ) {
		ok( ! $@, 'No exceptions');
		is( $dec, $expect, "$enc produced correct output");
	} else {
		ok( $@, 'Got an exception as expected');
	}
    }
    close WORDS;
}

# Test case for ticket 5462
{
	my $source  = 'h� h�';
	my $encoded = encode_mimewords($source, ('Encode' => 'Q', 'Charset' => 'iso-8859-1'));
	my $decoded = decode_mimewords($encoded);
	is( $decoded, $source, 'encode/decode of string with spaces matches original');
}

# Second test case for ticket 5462
{
	my $source = 'это специальныйсабжект для теста системы тикетов';
	my $encoded = encode_mimewords($source, ('Encode' => 'Q', 'Charset' => 'utf8'));
	my $decoded = decode_mimewords($encoded);
	is( $decoded, $source, 'encode/decode of string with spaces matches original');
}

# vim: set encoding=utf8 fileencoding=utf8:
