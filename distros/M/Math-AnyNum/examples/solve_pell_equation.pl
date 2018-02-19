#!/usr/bin/perl

# Find the smallest solution in positive integers to the Pell equation: x^2 - d*y^2 = ±1, where `d` is known.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(is_square isqrt);

sub sqrt_convergents {
    my ($n) = @_;

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;

    my @convergents = ($x);

    do {
        $y = int(($x + $y) / $z) * $z - $y;
        $z = int(($n - $y * $y) / $z);
        push @convergents, int(($x + $y) / $z);
    } until (($y == $x) && ($z == 1));

    return @convergents;
}

sub cfrac_denominator {
    my (@cfrac) = @_;

    my ($f1, $f2) = (0, 1);

    foreach my $n (@cfrac) {
        ($f1, $f2) = ($f2, $n * $f2 + $f1);
    }

    return $f1;
}

sub solve_pell {
    my ($d) = @_;

    return if is_square($d);

    my ($k, @period) = sqrt_convergents($d);

    my @solutions;

    my $x = cfrac_denominator($k, @period);
    my $p1 = 4 * $d * ($x * $x + 1);

    if (is_square($p1)) {
        push @solutions, [$x, isqrt($p1) / (2 * $d)];
        $x = cfrac_denominator($k, @period, @period);
    }

    my $p2 = 4 * $d * ($x * $x - 1);
    push @solutions, [$x, isqrt($p2) / (2 * $d)];

    return @solutions;
}

foreach my $d (1 .. 30) {

    my @solutions = solve_pell($d);

    foreach my $solution (@solutions) {
        my ($x, $y) = @$solution;
        printf("x^2 - %2dy^2 = %2d    minimum solution: x=%5s and y=%5s\n", $d, $x**2 - $d * $y**2, $x, $y);
    }
}
