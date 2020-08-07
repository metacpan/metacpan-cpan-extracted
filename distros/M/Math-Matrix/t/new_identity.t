#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 12;

###############################################################################

note("test new_identity()");

{
    my $x = Math::Matrix -> new_identity(1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[ 1 ]], '$x has the right values');

    my $y = Math::Matrix -> new_identity(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1, 0 ],
                        [ 0, 1 ]], '$y has the right values');

    my $z = Math::Matrix -> new_identity(3);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 0, 0 ],
                        [ 0, 1, 0 ],
                        [ 0, 0, 1 ]], '$z has the right values');
}

###############################################################################

note("test eye()");

{
    my $x = Math::Matrix -> eye(1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    is_deeply([ @$x ], [[ 1 ]], '$x has the right values');

    my $y = Math::Matrix -> eye(2);
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1, 0 ],
                        [ 0, 1 ]], '$y has the right values');

    my $z = Math::Matrix -> eye(3);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 0, 0 ],
                        [ 0, 1, 0 ],
                        [ 0, 0, 1 ]], '$z has the right values');
}
