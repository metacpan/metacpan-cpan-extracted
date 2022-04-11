#!/usr/bin/perl -T

BEGIN
{
    $ENV{LC_ALL} = 'C';

    # See: https://github.com/shlomif/html-tidy5/issues/6
    $ENV{LANG} = 'en_US.UTF-8';
};


use 5.010001;
use strict;
use warnings;

use Test::Exception;
use Test::More tests => 2;

use HTML::T5;

my $tidy = HTML::T5->new;
isa_ok( $tidy, 'HTML::T5' );

my $expected_pattern = 'Usage: parse($filename,$str [, $str...])';
throws_ok {
    $tidy->parse('fake-filename.txt');
} qr/\Q$expected_pattern\E/,
'parse() dies when not given a string or array of strings to parse';
