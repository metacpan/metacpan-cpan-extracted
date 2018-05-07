#!/usr/bin/perl

# The inverse of n factorial, based on the inverse of Stirling's approximation.

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(:overload tau e factorial LambertW lgrt approx_cmp);

use constant S => tau->sqrt->log;
use constant T => tau->root(-2.0 * e);

sub inverse_factorial_W {
    my ($n) = @_;
    my $L = log($n) - S;
    $L / LambertW($L / e) - 0.5;
}

sub inverse_factorial_lgrt {
    my ($n) = @_;
    lgrt(T * $n**(1 / e)) * e - 0.5;
}

for my $n (1 .. 100) {

    my $f = factorial($n);
    my $i = inverse_factorial_W($f);
    my $j = inverse_factorial_lgrt($f);

    printf("F(%2s!) =~ %s\n", $n, $i);

    if (approx_cmp($i, $j) != 0) {
        die "$i != $j";
    }

    if (approx_cmp($i, $n, 0) != 0) {
        die "However that is incorrect! (expected: $n -- got ", $i->round, ")";
    }
}
