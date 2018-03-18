#!/usr/bin/perl -T

use 5.010001;
use strict;
use warnings;

use Test::Exception;
use Test::More tests => 2;

use HTML::Tidy5;

my $tidy = HTML::Tidy5->new;
isa_ok( $tidy, 'HTML::Tidy5' );

my $expected_pattern = 'Usage: parse($filename,$str [, $str...])';
throws_ok {
    $tidy->parse('fake-filename.txt');
} qr/\Q$expected_pattern\E/,
'parse() dies when not given a string or array of strings to parse';
