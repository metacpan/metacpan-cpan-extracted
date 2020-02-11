#!perl

use strict;                     # Import test functions
use warnings;

use Test::More tests => 35;

my @f;
BEGIN { @f = qw< sum kahansum neumaiersum kleinsum pairwisesum >; }

use Math::Summation @f;

# Basic tests.

for (my $n = 0 ; $n <= 5 ; ++$n) {
    for my $f (@f) {
        my @x = 1 .. $n;
        my $expected = 0.5 * ($n * ($n + 1));
        my $test = "$f(" . join(", ", @x) . ")";
        my $got = eval $test;
        cmp_ok($got, '==', $expected, "$test = $expected");
    }
}

# Some tests where the output differs.

my @x = (1, 1e100, 1, -1e100);
my @expected = (0, 0, 2, 2, 0);
for (my $i = 0 ; $i <= $#f ; ++$i) {
    my $f = $f[$i];
    my $expected = $expected[$i];
    my $test = "$f(" . join(", ", @x) . ")";
    my $got = eval $test;
    cmp_ok($got, '==', $expected, "$test = $expected");
}
