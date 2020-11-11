#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 102;

use Math::Trig qw< Inf >;

################################################################

note('vecnorm() on a 2-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 41 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(2) on a 2-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 41 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(2, 1) on a 2-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 41 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(2, 2) on a 2-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 41 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(1) on a 2-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7, 49 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(1, 1) on a 2-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(1, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7, 49 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(1, 2) on a 2-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 12 ],
                        [ 44 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(Inf) on a 2-by-2 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(Inf);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4, 40 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(Inf, 1) on a 2-by-2 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(Inf, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4, 40 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

note('vecnorm(Inf, 2) on a 2-by-2 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[  3, -9 ],
                                 [ -4, 40 ]]);
    my $y = $x -> vecnorm(Inf, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  9 ],
                        [ 40 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  3, -9 ],
                        [ -4, 40 ]], '$x is unmodified');
}

################################################################

note('vecnorm() on a 2-by-1 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(2) on a 2-by-1 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(2, 1) on a 2-by-1 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(2, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(2, 2) on a 2-by-1 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(2, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3 ], [ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(1) on a 2-by-1 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(1, 1) on a 2-by-1 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(1, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(1, 2) on a 2-by-1 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3 ], [ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(Inf) on a 2-by-1 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(Inf);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(Inf, 1) on a 2-by-1 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(Inf, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

note('vecnorm(Inf, 2) on a 2-by-1 matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> vecnorm(Inf, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3 ],
                        [ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ]], '$x is unmodified');
}

################################################################

note('vecnorm() on a 1-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(2) on a 1-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(2, 1) on a 1-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(2, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3, 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(2, 2) on a 1-by-2 matrix (2-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(2, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(1) on a 1-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(1, 1) on a 1-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(1, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3, 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(1, 2) on a 1-by-2 matrix (1-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 7 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(Inf) on a 1-by-2 matrix (Inf-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(Inf);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(Inf, 1) on a 1-by-2 matrix (Inf-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(Inf, 1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 3, 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

note('vecnorm(Inf, 2) on a 1-by-2 matrix (Inf-norm)');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> vecnorm(Inf, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 4 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, 4 ]], '$x is unmodified');
}

################################################################

note('vecnorm() on an empty matrix (2-norm)');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> vecnorm();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('vecnorm(1) on an empty matrix (1-norm)');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> vecnorm(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('vecnorm(2) on an empty matrix (2-norm)');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> vecnorm(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('vecnorm(Inf) on an empty matrix (Infinity-norm)');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> vecnorm(Inf);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
