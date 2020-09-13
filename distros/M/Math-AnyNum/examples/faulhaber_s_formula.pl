#!/usr/bin/perl

# The formula for calculating the sum of consecutive
# numbers raised to a given power, such as:
#    1^p + 2^p + 3^p + ... + n^p
# where p is a positive integer.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula

use 5.020;
use strict;
use warnings;

use lib qw(../lib);
use experimental qw(signatures);
use Math::AnyNum qw(:overload binomial factorial faulhaber_sum);

# This function returns the n-th Bernoulli number
# See: https://en.wikipedia.org/wiki/Bernoulli_number
sub bernoulli_number ($n) {

    return -1/2 if ($n     == 1);
    return    0 if ($n % 2 == 1);

    my @B = (1);

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {
            $B[$i] //= 0;
            $B[$i] -= $B[$k] / factorial($i - $k + 1);
        }
    }

    return $B[-1] * factorial($#B);
}

# The Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula ($n, $p) {

    my $sum = 0;

    for my $k (0 .. $p) {
        $sum += (-1)**$k * binomial($p + 1, $k) * bernoulli_number($k) * $n**($p - $k + 1);
    }

    return $sum / ($p + 1);
}

# Alternate expression using Bernoulli polynomials
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula#Alternate_expressions
sub bernoulli_polynomials ($n, $x) {

    my $sum = 0;
    for my $k (0 .. $n) {
        $sum += binomial($n, $k) * bernoulli_number($n - $k) * $x**$k;
    }

    return $sum;
}

sub faulhaber_s_formula_2 ($n, $p) {
    (bernoulli_polynomials($p + 1, $n + 1) - bernoulli_number($p + 1)) / ($p + 1);
}

foreach my $m (1 .. 15) {

    my $n = int(rand(100));

    my $t1 = faulhaber_s_formula($n, $m);
    my $t2 = faulhaber_s_formula_2($n, $m);
    my $t3 = faulhaber_sum($n, $m);

    say "Sum_{k=1..$n} k^$m = $t1";

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);
}

__END__
Sum_{k=1..79} k^1 = 3160
Sum_{k=1..41} k^2 = 23821
Sum_{k=1..90} k^3 = 16769025
Sum_{k=1..52} k^4 = 79743482
Sum_{k=1..55} k^5 = 4868894800
Sum_{k=1..20} k^6 = 216455810
Sum_{k=1..87} k^7 = 429380261081904
Sum_{k=1..38} k^8 = 20607480744851
Sum_{k=1..45} k^9 = 3796008746347665
Sum_{k=1..91} k^10 = 341980696482343462726
