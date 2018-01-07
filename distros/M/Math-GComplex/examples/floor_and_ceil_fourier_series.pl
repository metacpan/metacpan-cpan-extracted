#!/usr/bin/perl

# Floor and ceil functions, implemented using closed-form Fourier series.

# See also:
#   https://en.wikipedia.org/wiki/Floor_and_ceiling_functions#Continuity_and_series_expansions

use 5.022;
use warnings;

use experimental qw(signatures);
use Math::GComplex qw(:overload);

sub tau() : prototype() {
    log(-1) * -2*i;
}

sub floor ($x) {
    $x + (i * (log(1 - exp(tau * i * $x)) - log(exp(-tau * i * $x) * (-1 + exp(tau * i * $x))))) / tau - 1/2;
}

sub ceil ($x) {
    $x + (i * (log(1 - exp(tau * i * $x)) - log(exp(-tau * i * $x) * (-1 + exp(tau * i * $x))))) / tau + 1/2;
}

say floor(8.95);    #=> 8
say ceil(8.95);     #=> 9

say floor(18.3);    #=> 18
say ceil(18.3);     #=> 19
