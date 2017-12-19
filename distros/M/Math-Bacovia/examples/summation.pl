#!/usr/bin/perl

# Sum() + Fraction() example.

use utf8;
use 5.014;

use lib qw(../lib);
use ntheory qw(factorial);
use Math::Bacovia qw(:all);

my $sum = Sum();
foreach my $n (0 .. 3) {
    $sum += Fraction(1, factorial($n));
    say $sum;
}

say '';
say "Pretty        : ", $sum->pretty;
say "Simple+Pretty : ", $sum->simple->pretty;
say "Numeric       : ", $sum->numeric;
