#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

require Math::Trig;
my $inf = Math::Trig::Inf();
my $nan = $inf - $inf;

note('testing find()');

{
    my $x = Math::Matrix -> new([[   -1,    0,    1],
                                 [-$inf, $nan, $inf]]);
    my ($I, $J) = $x -> find();
    my $K = $x -> find();

    is_deeply([ @$I ], [0, 1, 1, 0, 1], '$I has the right values');
    is_deeply([ @$J ], [0, 0, 1, 2, 2], '$J has the right values');
    is_deeply([ @$K ], [0, 1, 3, 4, 5], '$K has the right values');
}

{
    my $x = Math::Matrix -> new([]);
    my ($I, $J) = $x -> find();
    my $K = $x -> find();

    is_deeply([ @$I ], [], '$I has the right values');
    is_deeply([ @$J ], [], '$J has the right values');
    is_deeply([ @$K ], [], '$K has the right values');
}

note('testing is_finite()');

{
    my $x = Math::Matrix -> new([[   -1,    0,    1],
                                 [-$inf, $nan, $inf]]);
    my $B = $x -> is_finite();

    is_deeply([ @$B ], [[1, 1, 1],
                        [0, 0, 0]], '$B has the right values');
}

{
    my $x = Math::Matrix -> new([]);
    my $B = $x -> is_finite();

    is_deeply([ @$B ], [], '$B has the right values');
}

note('testing is_inf()');

{
    my $x = Math::Matrix -> new([[   -1,    0,    1],
                                 [-$inf, $nan, $inf]]);
    my $B = $x -> is_inf();

    is_deeply([ @$B ], [[0, 0, 0],
                        [1, 0, 1]], '$B has the right values');
}

{
    my $x = Math::Matrix -> new([]);
    my $B = $x -> is_inf();

    is_deeply([ @$B ], [], '$B has the right values');
}

note('testing is_nan()');

{
    my $x = Math::Matrix -> new([[   -1,    0,    1],
                                 [-$inf, $nan, $inf]]);
    my $B = $x -> is_nan();

    is_deeply([ @$B ], [[0, 0, 0],
                        [0, 1, 0]], '$B has the right values');
}

{
    my $x = Math::Matrix -> new([]);
    my $B = $x -> is_nan();

    is_deeply([ @$B ], [], '$B has the right values');
}
