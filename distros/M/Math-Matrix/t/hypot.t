#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 36;

################################################################

note('hypot() on a 2-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3,  5 ],
                                 [ 4, 12 ]]);
    my $y = $x -> hypot();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 13 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3,  5 ],
                        [ 4, 12 ]], '$x is unmodified');
}

note('hypot(1) on a 2-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3,  5 ],
                                 [ 4, 12 ]]);
    my $y = $x -> hypot(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 5, 13 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3,  5 ],
                        [ 4, 12 ]], '$x is unmodified');
}

note('hypot(2) on a 2-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3,  4 ],
                                 [ 5, 12 ]]);
    my $y = $x -> hypot(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  5 ],
                        [ 13 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3,  4 ],
                        [ 5, 12 ]], '$x is unmodified');
}

################################################################

note('hypot() on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> hypot();

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

note('hypot(1) on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> hypot(1);

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

note('hypot(2) on a 2-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ]]);
    my $y = $x -> hypot(2);

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

note('hypot() on a 1-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> hypot();

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

note('hypot(1) on a 1-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> hypot(1);

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

note('hypot(2) on a 1-by-2 matrix');

{
    my $x = Math::Matrix -> new([[ 3, 4 ]]);
    my $y = $x -> hypot(2);

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

################################################################

note('hypot() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> hypot();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('hypot(1) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> hypot(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('hypot(2) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> hypot(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
