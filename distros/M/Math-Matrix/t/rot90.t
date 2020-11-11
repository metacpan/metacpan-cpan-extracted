#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 24;

note('rot90()');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[3, 6],
                        [2, 5],
                        [1, 4]], '$y has the right values');

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

note('rot90(0)');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90(0);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 2, 3],
                        [4, 5, 6]], '$y has the right values');

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

note('rot90(1)');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[3, 6],
                        [2, 5],
                        [1, 4]], '$y has the right values');

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

note('rot90(2)');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[6, 5, 4],
                        [3, 2, 1]], '$y has the right values');

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

note('rot90(3)');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90(3);

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

note('rot90() with empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> rot90();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('rot90([[1]])');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90([[1]]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[3, 6],
                        [2, 5],
                        [1, 4]], '$y has the right values');

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

note('rot90(Math::Matrix -> new([[1]]))');

{
    my $x = Math::Matrix -> new([[1, 2, 3],
                                 [4, 5, 6]]);
    my $y = $x -> rot90(Math::Matrix -> new([[1]]));

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[3, 6],
                        [2, 5],
                        [1, 4]], '$y has the right values');

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
