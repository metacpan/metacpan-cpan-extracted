#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 9;

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> as_array();

    is(ref($y), 'ARRAY', '$y is ARRAY');
    is_deeply([ @$y ], [[1, 2, 3],
                        [4, 5, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    for my $i (0 .. 1) {
        for my $j (0 .. 2) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3],
                        [4, 5, 6]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([[1, 2, 3]]);
    my $y = $x -> as_array();

    is(ref($y), 'ARRAY', '$y is ARRAY');
    is_deeply([ @$y ], [[1, 2, 3]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    for my $i (0) {
        for my $j (0 .. 2) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> as_array();

    is(ref($y), 'ARRAY', '$y is an ARRAY');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
