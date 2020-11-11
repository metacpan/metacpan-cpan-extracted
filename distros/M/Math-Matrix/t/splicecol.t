#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 52;

note('$y = $x -> splicecol();');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $y = $x -> splicecol();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('($y, $z) = $x -> splicecol();');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my ($y, $z) = $x -> splicecol();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$z has the right values');

    # Verify that modifying $z does not modify $x.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('$y = $x -> splicecol(1);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $y = $x -> splicecol(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1],
                        [2]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('($y, $z) = $x -> splicecol(1);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my ($y, $z) = $x -> splicecol(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1],
                        [2]], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[3, 5, 7],
                        [4, 6, 8]], '$z has the right values');

    # Verify that modifying $y and $z does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('$y = $x -> splicecol(1, 2);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $y = $x -> splicecol(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 7],
                        [2, 8]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('($y, $z) = $x -> splicecol(1, 2);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my ($y, $z) = $x -> splicecol(1, 2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 7],
                        [2, 8]], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[3, 5],
                        [4, 6]], '$z has the right values');

                                # Verify that modifying $y and $z does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
}

note('$y = $x -> splicecol(1, 2, $a, $b);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $a = Math::Matrix -> new([[11, 13, 15],
                                 [12, 14, 16]]);
    my $b = Math::Matrix -> new([[17],
                                 [18]]);
    my $y = $x -> splicecol(1, 2, $a, $b);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 11, 13, 15, 17, 7],
                        [2, 12, 14, 16, 18, 8]], '$y has the right values');

    # Verify that modifying $y does not modify $x, $a, or $b.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
    is_deeply([ @$a ], [[11, 13, 15],
                        [12, 14, 16]], '$a is unmodified');
    is_deeply([ @$b ], [[17],
                        [18]], '$b is unmodified');
}

note('($y, $z) = $x -> splicecol(1, 2, $a, $b);');

{
    my $x = Math::Matrix -> new([[1, 3, 5, 7],
                                 [2, 4, 6, 8]]);
    my $a = Math::Matrix -> new([[11, 13, 15],
                                 [12, 14, 16]]);
    my $b = Math::Matrix -> new([[17],
                                 [18]]);
    my ($y, $z) = $x -> splicecol(1, 2, $a, $b);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1, 11, 13, 15, 17, 7],
                        [2, 12, 14, 16, 18, 8]], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[3, 5],
                        [4, 6]], '$z has the right values');

    # Verify that modifying $y and $z does not modify $x, $a, or $b.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 3, 5, 7],
                        [2, 4, 6, 8]], '$x is unmodified');
    is_deeply([ @$a ], [[11, 13, 15],
                        [12, 14, 16]], '$a is unmodified');
    is_deeply([ @$b ], [[17],
                        [18]], '$b is unmodified');
}

note('$y = $x -> splicecol(1);');

{
    my $x = Math::Matrix -> new([[1],
                                 [2]]);
    my $y = $x -> splicecol(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1],
                        [2]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [2]], '$x is unmodified');
}

note('($y, $z) = $x -> splicecol(1);');

{
    my $x = Math::Matrix -> new([[1],
                                 [2]]);
    my ($y, $z) = $x -> splicecol(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[1],
                        [2]], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [2]], '$x is unmodified');
}

note('$y = $x -> splicecol(0);');

{
    my $x = Math::Matrix -> new([[1],
                                 [2]]);
    my $y = $x -> splicecol(0);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is_deeply([ @$x ], [[1],
                        [2]], '$x is unmodified');
}

note('($y, $z) = $x -> splicecol(0);');

{
    my $x = Math::Matrix -> new([[1],
                                 [2]]);
    my ($y, $z) = $x -> splicecol(0);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1], [2]], '$z has the right values');

    # Verify that modifying $z does not modify $x.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1],
                        [2]], '$x is unmodified');
}
