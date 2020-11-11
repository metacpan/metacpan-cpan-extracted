#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 36;

note('flip() on a 2-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4],
                                 [5, 6, 7, 8]]);
    my $y = $x -> flip();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[5, 6, 7, 8],
                        [1, 2, 3, 4]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4],
                        [5, 6, 7, 8]], '$x is unmodified');
}

note('flip(1) on a 2-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4],
                                 [5, 6, 7, 8]]);
    my $y = $x -> flip(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[5, 6, 7, 8],
                        [1, 2, 3, 4]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4],
                        [5, 6, 7, 8]], '$x is unmodified');
}

note('flip(2) on a 2-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4],
                                 [5, 6, 7, 8]]);
    my $y = $x -> flip(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[4, 3, 2, 1],
                        [8, 7, 6, 5]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4],
                        [5, 6, 7, 8]], '$x is unmodified');
}

################################################################

note('flip() on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[1],
                                 [5]]);
    my $y = $x -> flip();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[5],
                        [1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [5]], '$x is unmodified');
}

note('flip(1) on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[1],
                                 [5]]);
    my $y = $x -> flip(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[5],
                        [1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [5]], '$x is unmodified');
}

note('flip(2) on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[1],
                                 [5]]);
    my $y = $x -> flip(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1],
                        [5]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [5]], '$x is unmodified');
}

################################################################

note('flip() on a 1-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4]]);
    my $y = $x -> flip();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[4, 3, 2, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4]], '$x is unmodified');
}

note('flip(1) on a 1-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4]]);
    my $y = $x -> flip(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 2, 3, 4]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4]], '$x is unmodified');
}

note('flip(2) on a 1-by-4 matrix');

{
    my $x = Math::Matrix -> new([[1, 2, 3, 4]]);
    my $y = $x -> flip(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[4, 3, 2, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2, 3, 4]], '$x is unmodified');
}

################################################################

note('flip() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> flip();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('flip(1) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> flip(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('flip(2) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> flip(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
