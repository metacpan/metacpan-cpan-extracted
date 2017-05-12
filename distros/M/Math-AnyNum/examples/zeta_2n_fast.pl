#!/usr/bin/perl

# Calculate zeta(2n) using a closed-form formula.

# See also:
#   https://en.wikipedia.org/wiki/Riemann_zeta_function

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(:overload pi bernfrac factorial);

sub zeta_2n {
    my ($n2) = 2 * $_[0];
    ((-1)**($_[0] + 1) * 2**($n2 - 1) * pi**$n2 * bernfrac($n2)) / factorial($n2);
}

for my $i (1 .. 30) {
    say "zeta(", 2 * $i, ") = ", zeta_2n($i);
}
