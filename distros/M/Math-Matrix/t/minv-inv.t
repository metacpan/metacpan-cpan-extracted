#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('minv()');

{
    my $x = Math::Matrix -> new([[ -1, -2,  4,  2,  0 ],
                                 [  3, -2,  1,  4, -1 ],
                                 [  2, -2,  0, -2, -3 ],
                                 [  1,  2, -4,  2,  2 ],
                                 [  4,  0,  0,  2, -3 ]]);

    my $y = $x -> minv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -2.6875,       2,    -1.5, -2.1875,  -0.625 ],
                        [  -0.375,       0,    -0.5,  -0.375,    0.25 ],
                        [  -1.375,       1,      -1,  -1.375,   -0.25 ],
                        [ 1.53125,      -1,    0.75, 1.28125,  0.4375 ],
                        [ -2.5625,       2,    -1.5, -2.0625,  -0.875 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -1, -2,  4,  2,  0 ],
                        [  3, -2,  1,  4, -1 ],
                        [  2, -2,  0, -2, -3 ],
                        [  1,  2, -4,  2,  2 ],
                        [  4,  0,  0,  2, -3 ]], '$x is unmodified');
}

note('inv()');

{
    my $x = Math::Matrix -> new([[ -1, -2,  4,  2,  0 ],
                                 [  3, -2,  1,  4, -1 ],
                                 [  2, -2,  0, -2, -3 ],
                                 [  1,  2, -4,  2,  2 ],
                                 [  4,  0,  0,  2, -3 ]]);

    my $y = $x -> inv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -2.6875,       2,    -1.5, -2.1875,  -0.625 ],
                        [  -0.375,       0,    -0.5,  -0.375,    0.25 ],
                        [  -1.375,       1,      -1,  -1.375,   -0.25 ],
                        [ 1.53125,      -1,    0.75, 1.28125,  0.4375 ],
                        [ -2.5625,       2,    -1.5, -2.0625,  -0.875 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -1, -2,  4,  2,  0 ],
                        [  3, -2,  1,  4, -1 ],
                        [  2, -2,  0, -2, -3 ],
                        [  1,  2, -4,  2,  2 ],
                        [  4,  0,  0,  2, -3 ]], '$x is unmodified');
}
