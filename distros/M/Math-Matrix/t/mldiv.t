#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

note('mldiv() when "denominator" is an M-by-N matrix with M = N');

{
    my $A = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);

    my $y = Math::Matrix -> new([[  -38,   15, -103 ],
                                 [   62,  -72,  -10 ],
                                 [  -66,   99,   33 ],
                                 [   84,  -68,   42 ],
                                 [  -61,   71,   32 ]]);

    my $x = $y -> mldiv($A);

    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');

    is_deeply([ @$x ], [[  4, -2, -9 ],
                        [ -3, -2, -1 ],
                        [  4, -5,  7 ],
                        [ -7,  2, -9 ],
                        [  1, -8, -8 ]], '$x has the right values');

    # Verify that modifying $x does not modify $A or $y.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $x -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$A is unmodified');

    is_deeply([ @$y ], [[  -38,   15, -103 ],
                        [   62,  -72,  -10 ],
                        [  -66,   99,   33 ],
                        [   84,  -68,   42 ],
                        [  -61,   71,   32 ]], '$y is unmodified');
}

note('mldiv() when "denominator" is an M-by-N matrix with M > N');

{
    my $A = Math::Matrix -> new([[  7, -9,  5,  4 ],
                                 [  8,  1,  0,  3 ],
                                 [  4,  0,  7, -7 ],
                                 [ -5,  2,  9,  4 ],
                                 [ -2,  5,  5,  4 ]]);

    my $y = Math::Matrix -> new([[   0,  37,  37 ],
                                 [  99, -66,  23 ],
                                 [ -59,  11, -17 ],
                                 [ -24,  18,  33 ],
                                 [  40, -35,  28 ]]);

    my $x = $y -> mldiv($A);

    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');

    # Avoid tiny errors. If an element is very close to an integer, round it to
    # that integer, otherwise use the original value.

    $x = $x -> sapply(sub {
                          my $r = sprintf('%.0f', $_[0]);
                          abs($r - $_[0]) < 1e-12 ? $r : $_[0];
                      });

    is_deeply([ @$x ], [[  8, -6,  1 ],
                        [  8, -9,  0 ],
                        [ -4,  2,  2 ],
                        [  9, -3,  5 ]], '$x has the right values');

    # Verify that modifying $x does not modify $A or $y.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $x -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  7, -9,  5,  4 ],
                        [  8,  1,  0,  3 ],
                        [  4,  0,  7, -7 ],
                        [ -5,  2,  9,  4 ],
                        [ -2,  5,  5,  4 ]], '$A is unmodified');

    is_deeply([ @$y ], [[   0,  37,  37 ],
                        [  99, -66,  23 ],
                        [ -59,  11, -17 ],
                        [ -24,  18,  33 ],
                        [  40, -35,  28 ]], '$y is unmodified');
}

note('mldiv() when "denominator" is an M-by-N matrix with M < N');

{
    my $A = Math::Matrix -> new([[  2, -2, -1, -2,  4 ],
                                 [ -2,  0,  0,  1,  0 ],
                                 [  0, -3,  0,  1, -2 ],
                                 [ -2, -3,  1,  1, -2 ]]);

    my $y = Math::Matrix -> new([[   5,  18,   6 ],
                                 [   3,   5,  -5 ],
                                 [ -23,   0,  -7 ],
                                 [ -14,   6, -15 ]]);

    my $x = $y -> mldiv($A);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');

    # Avoid negative zero in the output.

    $x = $x -> sapply(sub { $_[0] == 0 ? abs($_[0]) : $_[0] });

    is_deeply([ @$x ], [[       0,       0,       0,       0 ],
                        [  -0.125,       0,  -0.125,  -0.125 ],
                        [       0,       0,      -1,       1 ],
                        [       0,       1,       0,       0 ],
                        [  0.1875,     0.5, -0.3125,  0.1875 ]],
              '$x has the right values');

    # Verify that modifying $x does not modify $A or $y.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $x -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  2, -2, -1, -2,  4 ],
                        [ -2,  0,  0,  1,  0 ],
                        [  0, -3,  0,  1, -2 ],
                        [ -2, -3,  1,  1, -2 ]], '$A is unmodified');

    is_deeply([ @$y ], [[   5,  18,   6 ],
                        [   3,   5,  -5 ],
                        [ -23,   0,  -7 ],
                        [ -14,   6, -15 ]], '$y is unmodified');
}
