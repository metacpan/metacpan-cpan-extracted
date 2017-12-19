#!/usr/bin/perl

# Closed-form for zeta(2n).

use utf8;
use 5.014;

use lib qw(../lib);
use Math::AnyNum qw(bernfrac factorial);
use Math::Bacovia qw(tau Number Fraction);

sub zeta_2n {
    my ($n)  = @_;
    my $bern = Number(bernfrac(2 * $n));
    my $fac  = Number(factorial(2 * $n));
    (-1)**($n + 1) * $bern * tau**(2 * $n) / ($fac * 2);
}

foreach my $n (1 .. 5) {
    say zeta_2n($n)->simple(full => 1)->pretty;
}
