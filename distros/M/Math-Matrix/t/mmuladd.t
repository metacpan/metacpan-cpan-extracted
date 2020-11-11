#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 10;

{
    my $A = Math::Matrix -> new([[  1,  0,  1 ],
                                 [ -1, -1, -7 ],
                                 [  1, -1, -4 ]]);

    my $x = Math::Matrix -> new([[  2,  17 ],
                                 [ -1,  71 ],
                                 [  0, -13 ]]);

    my $y = Math::Matrix -> new([[  2,  4 ],
                                 [ -1,  3 ],
                                 [  3, -2 ]]);

    my $z = $A -> mmuladd($x, $y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  4,  8 ],
                        [ -2,  6 ],
                        [  6, -4 ]], '$z has the right values');

    # Verify that modifying $z does not modify $A, $x, or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  1,  0,  1 ],
                        [ -1, -1, -7 ],
                        [  1, -1, -4 ]], '$A is unmodified');

    is_deeply([ @$x ], [[  2,  17 ],
                        [ -1,  71 ],
                        [  0, -13 ]], '$x is unmodified');

    is_deeply([ @$y ], [[  2,  4 ],
                        [ -1,  3 ],
                        [  3, -2 ]], '$y is unmodified');
}


{
    my $A = Math::Matrix -> new([[  1,  0,  1 ],
                                 [ -1, -1, -7 ],
                                 [  1, -1, -4 ]]);

    my $x = Math::Matrix -> new([[  2,  17 ],
                                 [ -1,  71 ],
                                 [  0, -13 ]]);

    my $y = Math::Matrix -> new([[  2,  4 ],
                                 [ -1,  3 ],
                                 [  3, -2 ]]);

    my $z = $A -> mmuladd($x, -$y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 0],
                        [0, 0],
                        [0, 0]], '$z has the right values');

    # Verify that modifying $z does not modify $A, $x, or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  1,  0,  1 ],
                        [ -1, -1, -7 ],
                        [  1, -1, -4 ]], '$A is unmodified');

    is_deeply([ @$x ], [[  2,  17 ],
                        [ -1,  71 ],
                        [  0, -13 ]], '$x is unmodified');

    is_deeply([ @$y ], [[  2,  4 ],
                        [ -1,  3 ],
                        [  3, -2 ]], '$y is unmodified');
}
