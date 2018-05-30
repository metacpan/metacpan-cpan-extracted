#!/usr/bin/perl

# Calculate zeta(2n) using a closed-form formula.

# See also:
#   https://en.wikipedia.org/wiki/Riemann_zeta_function

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use experimental qw(signatures);
use Math::AnyNum qw(tau bernoulli factorial);

sub zeta_2n($n) {
    (-1)**($n + 1) * bernoulli(2 * $n) / factorial(2 * $n) * tau**(2 * $n) / 2;
}

for my $i (1 .. 30) {
    say "zeta(", 2 * $i, ") = ", zeta_2n($i);
}
