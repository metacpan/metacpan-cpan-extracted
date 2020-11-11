#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note("mmul() with two matrices");

{
    my $x = Math::Matrix -> new([[ 1, 2, 3 ],
                                 [ 4, 5, 6 ]]);
    my $y = Math::Matrix -> new([[ 7, 10, 13, 16 ],
                                 [ 8, 11, 14, 17 ],
                                 [ 9, 12, 15, 18 ]]);
    my $z = $x -> mmul($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  50,  68,  86, 104 ],
                        [ 122, 167, 212, 257 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 1, 2, 3 ],
                        [ 4, 5, 6 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 7, 10, 13, 16 ],
                        [ 8, 11, 14, 17 ],
                        [ 9, 12, 15, 18 ]], '$y is unmodified');
}

note("mmul() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> mmul($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');
}
