#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

note('rot270()');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot270();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[4, 1],
                        [5, 2],
                        [6, 3]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3],
                        [4, 5, 6]], '$x is unmodified');
}

note('rot270() with empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> rot270();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
