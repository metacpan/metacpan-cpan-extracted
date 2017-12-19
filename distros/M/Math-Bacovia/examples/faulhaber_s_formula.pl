#!/usr/bin/perl

# The formula for calculating the sum of consecutive
# numbers raised to a given power, such as:
#    1^p + 2^p + 3^p + ... + n^p
# where p is a positive integer.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::Bacovia qw(:all);
use Math::AnyNum qw(binomial bernfrac);

# The Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula {
    my ($p, $n) = @_;

    my $sum = Sum();
    for my $j (0 .. $p) {
        $sum += Number(binomial($p + 1, $j)) * Number(bernfrac($j)) * $n**($p + 1 - $j);
    }

    Fraction($sum, ($p + 1));
}

# Alternate expression using Bernoulli polynomials
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula#Alternate_expressions
sub bernoulli_polynomials {
    my ($n, $x) = @_;

    my $sum = Sum();
    for my $k (0 .. $n) {
        $sum += Number(binomial($n, $k)) * Number(bernfrac($n - $k)) * $x**$k;
    }

    $sum;
}

sub faulhaber_s_formula_2 {
    my ($p, $n) = @_;
    1 + Fraction((bernoulli_polynomials($p + 1, $n) - bernoulli_polynomials($p + 1, 1)), ($p + 1));
}

foreach my $i (0 .. 10) {
    say "F($i) = ", faulhaber_s_formula($i, Symbol('n'))->simple->pretty;
    say "F($i) = ", faulhaber_s_formula_2($i, Symbol('n'))->simple->pretty;
}
