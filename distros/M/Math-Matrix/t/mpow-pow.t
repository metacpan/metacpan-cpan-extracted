#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 41;

note("mpow() with two matrices");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[ 0 ]]);
    my $z = $x -> mpow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 0 ],
                        [ 0, 1 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 0 ]], '$y is unmodified');
}

note("mpow() with matrix and scalar");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[ 1 ]]);
    my $z = $x -> mpow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0, -2 ],
                        [ 1,  4 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 1 ]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[5]]);
    my $z = $x -> mpow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ -96, -328 ],
                        [ 164,  560 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[5]], '$y is unmodified');
}

note("mpow() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([[5]]);
    my $z = $x -> mpow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [[5]], '$y is unmodified');
}

note("pow() with two matrices");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[ 0 ]]);
    my $z = $x -> pow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 0 ],
                        [ 0, 1 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 0 ]], '$y is unmodified');
}

note("pow() with matrix and scalar");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[ 1 ]]);
    my $z = $x -> pow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0, -2 ],
                        [ 1,  4 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 1 ]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[5]]);
    my $z = $x -> pow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ -96, -328 ],
                        [ 164,  560 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[5]], '$y is unmodified');
}

note("pow() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([[5]]);
    my $z = $x -> pow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [[5]], '$y is unmodified');
}

note("overloading");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $z = $x ** 3;

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ -8, -28 ],
                        [ 14,  48 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x.

    my ($nrowy, $ncoly) = $z -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([[ 4 ]]);
    my $z = 3 ** $x;

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 81 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x.

    my ($nrowy, $ncoly) = $z -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 4 ]], '$x is unmodified');
}

{
    my $x = Math::Matrix -> new([]);
    my $z = $x ** 3;

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
}
