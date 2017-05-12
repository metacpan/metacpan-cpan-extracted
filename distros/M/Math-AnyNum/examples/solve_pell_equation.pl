#!/usr/bin/perl

# Find a minimum solution to a Pell equation: x^2 - d*y^2 = 1, where `d` is known.

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

sub continued_frac {
    my ($i, $c) = @_;
    $i < 0 ? 0 : ($c->[$i] + continued_frac($i - 1, $c))->inv;
}

sub solve_pell {
    my ($d) = @_;

    my ($k, @c) = sqrt_convergents($d);

    my @period = @c;
    for (my $i = 0 ; ; ++$i) {
        if ($i > $#c) { push @c, @period; $i = 2 * $i - 1 }

        my $x = continued_frac($i, [$k, @c])->denominator;
        my $p = 4 * $d * ($x * $x - 1);

        if (is_square($p)) {
            return ($x, isqrt($p) / (2 * $d));
        }
    }
}

foreach my $d (1 .. 25) {
    is_square($d) && next;
    my ($x, $y) = solve_pell($d);
    printf("x^2 - %2dy^2 = 1       minimum solution: x=%4s and y=%4s\n", $d, $x, $y);
}
