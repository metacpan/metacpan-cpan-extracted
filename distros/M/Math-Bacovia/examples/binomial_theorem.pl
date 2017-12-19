#!/usr/bin/perl

use utf8;
use 5.014;

use lib qw(../lib);
use Math::Bacovia qw(:all);

#
## The binomial coefficient: (n, k)
#
sub g {
    my ($n, $k) = @_;
    $k == 0 ? Number(1) : ($n - $k + 1) * g($n, $k - 1) / $k;
}

#
## Binomial summation for (a + b)^n
#
sub binomial_sum {
    my ($a, $b, $n) = @_;
    my $sum = Sum();
    foreach my $k (0 .. $n) {
        $sum += g($n, $k) * $a**($n - $k) * $b**$k;
    }
    return $sum;
}

#
## Example for (1 + 1/10)^10
#

my $a = Number(1);
my $b = Fraction(1, 10);
my $n = Number(10);

my $e = binomial_sum($a, $b, $n);

say $e->pretty;
say $e->numeric;
