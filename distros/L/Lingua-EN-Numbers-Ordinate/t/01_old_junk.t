#! perl

# Time-stamp: "2004-12-29 18:48:49 AST"

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Lingua::EN::Numbers::Ordinate qw/ ordinate th /;

my @TESTS = (
    [3,     '3rd'],
    [-3,    '-3rd'],
    [13,    '13th'],
    [33,    '33rd'],
    [-513,  '-513th'],
    [1,     '1st'],
    [2,     '2nd'],
    [4,     '4th'],
    [5,     '5th'],
    [0,     '0th'],
    ['',    '0th'],
    [undef, '0th'],
    [22,    '22nd'],
);

my $ordinal;

plan tests => 2 * @TESTS;

foreach my $test (@TESTS) {
    my ($value, $expected_ordinal) = @$test;

    $ordinal = ordinate($value);
    is($ordinal, $expected_ordinal, 'ordinate('.(defined($value) ? $value : 'undef').')');

    $ordinal = th($value);
    is($ordinal, $expected_ordinal, 'th('.(defined($value) ? $value : 'undef').')');

}
