#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 36;

note('triu() on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 3, 5],
                        [0, 4, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu(-1) on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu(-1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 3, 5],
                        [2, 4, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu(0) on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu(0);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 3, 5],
                        [0, 4, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu(1) on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 3, 5],
                        [0, 0, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu(2) on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 0, 5],
                        [0, 0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu(3) on 2-by-3 matrix');

{
    my $x = Math::Matrix -> new([[1, 3, 5],
                                 [2, 4, 6]]);
    my $y = $x -> triu(3);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 0, 0],
                        [0, 0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5],
                        [2, 4, 6]], '$x is unmodified');
}

note('triu() on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 4],
                        [0, 5],
                        [0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}

note('triu(-2) on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu(-2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 4],
                        [2, 5],
                        [3, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}

note('triu(-1) on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu(-1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 4],
                        [2, 5],
                        [0, 6]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}

note('triu(0) on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu(0);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 4],
                        [0, 5],
                        [0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}

note('triu(1) on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 4],
                        [0, 0],
                        [0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}

note('triu(2) on 3-by-2 matrix');

{
    my $x = Math::Matrix -> new([[1, 4],
                                 [2, 5],
                                 [3, 6]]);
    my $y = $x -> triu(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[0, 0],
                        [0, 0],
                        [0, 0]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 4],
                        [2, 5],
                        [3, 6]], '$x is unmodified');
}
