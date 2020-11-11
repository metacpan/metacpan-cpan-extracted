#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('floor() on a non-empty matrix');

{
    my $x = Math::Matrix -> new([[ -2.75, -2.50, -2.25, -2.00 ],
                                 [ -1.75, -1.50, -1.25, -1.00 ],
                                 [ -0.75, -0.50, -0.25, -0.00 ],
                                 [  0.75,  0.50,  0.25,  0.00 ],
                                 [  1.75,  1.50,  1.25,  1.00 ],
                                 [  2.75,  2.50,  2.25,  2.00 ]]);
    my $y = $x -> floor();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -3, -3, -3, -2 ],
                        [ -2, -2, -2, -1 ],
                        [ -1, -1, -1,  0 ],
                        [  0,  0,  0,  0 ],
                        [  1,  1,  1,  1 ],
                        [  2,  2,  2,  2 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2.75, -2.50, -2.25, -2.00 ],
                        [ -1.75, -1.50, -1.25, -1.00 ],
                        [ -0.75, -0.50, -0.25, -0.00 ],
                        [  0.75,  0.50,  0.25,  0.00 ],
                        [  1.75,  1.50,  1.25,  1.00 ],
                        [  2.75,  2.50,  2.25,  2.00 ]], '$x is unmodified');
}

note('floor() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> floor();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
