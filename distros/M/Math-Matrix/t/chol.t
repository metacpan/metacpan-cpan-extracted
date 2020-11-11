#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('chol() on 3-by-3 matrix');

{
    my $x = Math::Matrix -> new([[25, 15, -5],
                                 [15, 18,  0],
                                 [-5,  0, 11]]);
    my $y = $x -> chol();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[5, 0, 0],[3, 3, 0],[-1, 1, 3]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[25, 15, -5],
                        [15, 18,  0],
                        [-5,  0, 11]], '$x is unmodified');
}

note('chol() on 4-by-4 matrix');

{
    my $x = Math::Matrix -> new([[ 1, -2,  3, -2],
                                 [-2, 13,  3, 16],
                                 [ 3,  3, 19,  4],
                                 [-2, 16,  4, 25]]);
    my $y = $x -> chol();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  0,  0,  0 ],
                        [ -2,  3,  0,  0 ],
                        [  3,  3,  1,  0 ],
                        [ -2,  4, -2,  1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 1, -2,  3, -2],
                        [-2, 13,  3, 16],
                        [ 3,  3, 19,  4],
                        [-2, 16,  4, 25]], '$x is unmodified');
}
