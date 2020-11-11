#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

note('mrdiv() when "denominator" is a M-by-N matrix with M = N');

{
    my $A = Math::Matrix -> new([[  2,  0, -6,  4, -4 ],
                                 [  2, -8, -6, -2,  0 ],
                                 [ -7,  4, -3,  8, -1 ],
                                 [  2, -2,  6, -4,  5 ],
                                 [  2,  8, -6,  2, -6 ]]);

    my $y = Math::Matrix -> new([[  -38,   62,  -66,   84,  -61 ],
                                 [   15,  -72,   99,  -68,   71 ],
                                 [ -103,  -10,   33,   42,   32 ]]);

    my $x = $y -> mrdiv($A);

    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[  4, -3,  4, -7,  1 ],
                        [ -2, -2, -5,  2, -8 ],
                        [ -9, -1,  7, -9, -8 ]], '$x has the right values');

    # Verify that modifying $x does not modify $A or $y.

    my ($nrowx, $ncolx) = $x -> size();
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $x -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$A ], [[  2,  0, -6,  4, -4 ],
                        [  2, -8, -6, -2,  0 ],
                        [ -7,  4, -3,  8, -1 ],
                        [  2, -2,  6, -4,  5 ],
                        [  2,  8, -6,  2, -6 ]], '$A is unmodified');

    is_deeply([ @$y ], [[  -38,   62,  -66,   84,  -61 ],
                        [   15,  -72,   99,  -68,   71 ],
                        [ -103,  -10,   33,   42,   32 ]], '$y is unmodified');
}
