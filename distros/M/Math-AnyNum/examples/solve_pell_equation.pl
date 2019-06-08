#!/usr/bin/perl

# Find the smallest solution in positive integers to Pell's equation: x^2 - d*y^2 = 1, where `d` is known.

# See also:
#   https://rosettacode.org/wiki/Pell%27s_equation
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(is_square isqrt idiv);

sub solve_pell {
    my ($n) = @_;

    return () if is_square($n);

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;
    my $r = 2 * $x;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    for (; ;) {

        $y = $r * $z - $y;
        $z = idiv(($n - $y * $y), $z);
        $r = idiv(($x + $y), $z);

        my $A = $e2 + $x * $f2;
        my $B = $f2;

        if ($A**2 - $n * $B**2 == 1) {
            return ($A, $B);
        }

        ($e1, $e2) = ($e2, $r * $e2 + $e1);
        ($f1, $f2) = ($f2, $r * $f2 + $f1);
    }
}

foreach my $n (61, 109, 181, 277) {
    my ($x, $y) = solve_pell($n);
    printf("x^2 - %3d*y^2 = 1 for x = %-21s and y = %s\n", $n, $x, $y);
}

__END__
x^2 -  61*y^2 = 1 for x = 1766319049            and y = 226153980
x^2 - 109*y^2 = 1 for x = 158070671986249       and y = 15140424455100
x^2 - 181*y^2 = 1 for x = 2469645423824185801   and y = 183567298683461940
x^2 - 277*y^2 = 1 for x = 159150073798980475849 and y = 9562401173878027020
