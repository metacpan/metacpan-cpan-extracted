#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 September 2015
# Website: https://github.com/trizen

# Calculate zeta(2n) using a closed-form formula.
# See: https://en.wikipedia.org/wiki/Riemann_zeta_function

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum qw(:constant);
use constant PI => Math::BigNum->pi;

# An improved version of Sidel's algorithm
#   http://oeis.org/wiki/User:Peter_Luschny/ComputationAndAsymptoticsOfBernoulliNumbers#Seidel

# However, for practical purposes, `Math::BigNum::bernfrac()` is recommended.

sub bernoulli_number {
    my ($n) = @_;

    $n == 0 and return 1;
    $n == 1 and return 0.5;
    $n %  2 and return 0;

    my @D = (0, 1, (0) x ($n / 2));

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            $D[$_] += $D[$_ - 1] for (1 .. $h-1);
        }
        else {
            $w = $h++;
            $D[$w] += $D[$w + 1] while --$w;
        }
    }

    $D[$h - 1] / ((1 << ($n + 1)) - 2) * ($n % 4 == 0 ? -1 : 1);
}

sub zeta_2n {
    my ($n2) = 2 * $_[0];
    ((-1)**($_[0] + 1) * (1 << ($n2 - 1)) * (PI)->fpow($n2) * bernoulli_number($n2)) / $n2->fac;
}

for my $i (1 .. 10) {
    say "zeta(", 2 * $i, ") = ", zeta_2n($i);
}
