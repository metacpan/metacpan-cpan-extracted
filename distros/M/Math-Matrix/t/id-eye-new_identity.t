#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 42;

###############################################################################

{
    my ($x, $y, $nrowx, $ncolx, $nrowy, $ncoly);

    note("id(0) as class method");

    $x = Math::Matrix -> id(0);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [], '$x has the right values');

    note("id(1) as class method");

    $x = Math::Matrix -> id(1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1]], '$x has the right values');

    note("id(2) as class method");

    $x = Math::Matrix -> id(2);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0],
                        [0, 1]], '$x has the right values');

    note("id(3) as class method");

    $x = Math::Matrix -> id(3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x has the right values');

    note("id(2) as instance method");

    $y = $x -> id(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0],
                        [0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');

    note("id() as instance method");

    $y = $x -> id();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');
}

###############################################################################

{
    my ($x, $y, $nrowx, $ncolx, $nrowy, $ncoly);

    note("eye(0) as class method");

    $x = Math::Matrix -> eye(0);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [], '$x has the right values');

    note("eye(1) as class method");

    $x = Math::Matrix -> eye(1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1]], '$x has the right values');

    note("eye(2) as class method");

    $x = Math::Matrix -> eye(2);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0],
                        [0, 1]], '$x has the right values');

    note("eye(3) as class method");

    $x = Math::Matrix -> eye(3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x has the right values');

    note("eye(2) as instance method");

    $y = $x -> eye(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0],
                        [0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');

    note("eye() as instance method");

    $y = $x -> eye();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');
}

###############################################################################

{
    my ($x, $y, $nrowx, $ncolx, $nrowy, $ncoly);

    note("new_identity(0) as class method");

    $x = Math::Matrix -> new_identity(0);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [], '$x has the right values');

    note("new_identity(1) as class method");

    $x = Math::Matrix -> new_identity(1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1]], '$x has the right values');

    note("new_identity(2) as class method");

    $x = Math::Matrix -> new_identity(2);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0],
                        [0, 1]], '$x has the right values');

    note("new_identity(3) as class method");

    $x = Math::Matrix -> new_identity(3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x has the right values');

    note("new_identity(2) as instance method");

    $y = $x -> new_identity(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0],
                        [0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');

    note("new_identity() as instance method");

    $y = $x -> new_identity();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$x is unmodified');
}
