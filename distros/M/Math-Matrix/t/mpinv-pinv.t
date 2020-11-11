#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('mpinv()');

{
    my $x = Math::Matrix -> new([[ -2, -1, -3 ],
                                 [ -2, -1, -3 ],
                                 [ -2, -2, -2 ],
                                 [  2,  2,  3 ],
                                 [  2,  0,  1 ]]);

    my $y = $x -> mpinv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[   0.125,   0.125,   -0.25,  -0.125,   0.625 ],
                        [    0.25,    0.25,    -0.5,    0.25,   -0.25 ],
                        [ -0.3125, -0.3125,   0.375,  0.0625, -0.3125 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2, -1, -3 ],
                        [ -2, -1, -3 ],
                        [ -2, -2, -2 ],
                        [  2,  2,  3 ],
                        [  2,  0,  1 ]], '$A is unmodified');
}

note('pinv()');

{
    my $x = Math::Matrix -> new([[ -2, -1, -3 ],
                                 [ -2, -1, -3 ],
                                 [ -2, -2, -2 ],
                                 [  2,  2,  3 ],
                                 [  2,  0,  1 ]]);

    my $y = $x -> pinv();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[   0.125,   0.125,   -0.25,  -0.125,   0.625 ],
                        [    0.25,    0.25,    -0.5,    0.25,   -0.25 ],
                        [ -0.3125, -0.3125,   0.375,  0.0625, -0.3125 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2, -1, -3 ],
                        [ -2, -1, -3 ],
                        [ -2, -2, -2 ],
                        [  2,  2,  3 ],
                        [  2,  0,  1 ]], '$A is unmodified');
}
