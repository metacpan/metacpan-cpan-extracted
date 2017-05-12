#!/usr/bin/perl

# The inverse of n factorial, based on the inverse of Stirling's approximation.

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum qw(:constant factorial tau e);

use constant S => tau->sqrt->ln;
use constant T => tau->root(-2 * e);

sub inv_fac_W {
    my ($n) = @_;
    my $L = log($n) - S;
    $L / ($L / e)->lambert_w - 1/2;
}

sub inv_fac_lgrt {
    my ($n) = @_;
    (T * $n**(1 / e))->lgrt * e - 1/2;
}

for (my $n = 1 ; $n <= 1000 ; $n += 100->irand(1)) {
    my $f = factorial($n);
    my $i = inv_fac_W($f);
    my $j = inv_fac_lgrt($f);

    printf("F(%2s!) =~ %s\n", $n, $i);

    if ($i->round(-20) != $j->round(-20)) {
        die "$i != $j";
    }

    if ($i->round(0) != $n) {
        die "However that is incorrect! (expected: $n)";
    }
}
