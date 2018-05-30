#!/usr/bin/perl

# Approximate nth-roots using Halley's method.

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(:overload float approx_cmp);

sub derivatives {
    my ($x, $m, $k) = @_;

    my $fx   = $x**$m - $k;
    my $dfx  = ($m * $x**($m - 1));
    my $ddfx = (($m - 1) * $m) * $x**($m - 2);

    return ($fx, $dfx, $ddfx);
}

sub halleys_method {
    my ($x0, $m0, $k0) = @_;

    my $x = $x0;
    my $m = float($m0);
    my $k = float($k0);

    my @fx = derivatives($x, $m, $k);
    my $r = $fx[0] / ($fx[1] - ($fx[0] * $fx[2]) / (2 * $fx[1]));

    until (approx_cmp($fx[0], 0) == 0) {
        $r = ($fx[0] / ($fx[1] - (($fx[0] * $fx[2]) / (2 * $fx[1]))));
        $x -= $r;
        @fx = derivatives($x, $m, $k);
    }

    return $x;
}

# Real roots
say halleys_method(1, 2,  2);
say halleys_method(1, 3,  125);
say halleys_method(1, 7,  42**7);
say halleys_method(1, 42, 987**42);

# Complex roots
say halleys_method(sqrt(-1), 2,      -1);
say halleys_method(sqrt(-1), 2,      -2);
say halleys_method(sqrt(-1), -3,     -4);
say halleys_method(sqrt(-1), -3 * i, -4);
say halleys_method(sqrt(-1), -3,     -4 * i);
say halleys_method(sqrt(-1), -3 * i, -4 * i);
