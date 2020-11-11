#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

{
    my $x = Math::Matrix -> new([[0, 1, 2]]);
    my $y = $x -> to_permmat();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0, 0],[0, 1, 0],[0, 0, 1]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1, 2]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([[0, 2, 1]]);
    my $y = $x -> to_permmat();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0, 0],[0, 0, 1],[0, 1, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 2, 1]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([[2, 1, 0]]);
    my $y = $x -> to_permmat();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 0, 1],[0, 1, 0],[1, 0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[2, 1, 0]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> to_permmat();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [],
              '$y has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
}
