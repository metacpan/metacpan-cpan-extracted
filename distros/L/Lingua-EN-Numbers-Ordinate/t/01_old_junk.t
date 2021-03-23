#! perl

# Time-stamp: "2004-12-29 18:48:49 AST"

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Lingua::EN::Numbers::Ordinate qw/ ordinate th ordsuf /;

my @TESTS = (
    [3,     '3',    'rd'],
    [-3,    '-3',   'rd'],
    [11,    '11',   'th'],
    [12,    '12',   'th'],
    [13,    '13',   'th'],
    [33,    '33',   'rd'],
    [-513,  '-513', 'th'],
    [1,     '1',    'st'],
    [2,     '2',    'nd'],
    [4,     '4',    'th'],
    [5,     '5',    'th'],
    [0,     '0',    'th'],
    ['',    '0',    'th'],
    [undef, '0',    'th'],
    [22,    '22',   'nd'],
    ['n',   'n',    'th'],
);

my $ordinal;

plan tests => 3 * @TESTS;

foreach my $test (@TESTS) {
    my ($value, $expected_pre_suf, $expected_ord_suf) = @$test;
    my $expected_ordinal = $expected_pre_suf . $expected_ord_suf;

    $ordinal = ordinate($value);
    is($ordinal, $expected_ordinal, 'ordinate('.(defined($value) ? $value : 'undef').')');

    $ordinal = th($value);
    is($ordinal, $expected_ordinal, 'th('.(defined($value) ? $value : 'undef').')');

    my $ord_suf = ordsuf($value);
    is($ord_suf, $expected_ord_suf, "ordsuf(".(defined($value) ? $value : 'undef').") should be $expected_ord_suf");
}
