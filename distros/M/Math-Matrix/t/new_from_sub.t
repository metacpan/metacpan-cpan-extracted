#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 6;

my ($x, $sub);

################################################################

$sub = sub { $_[0] == $_[1] ? 1 : 0 };
$x = Math::Matrix -> new_from_sub($sub, 4);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 1, 0],
                    [0, 0, 0, 1]], '$x has the right values');

################################################################

$x = Math::Matrix -> new_from_sub(sub { 2**$_[1] }, 1, 11);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 ]],
          '$x has the right values');

################################################################

$sub = sub {
    my ($i, $j) = @_;
    my $d = $j - $i;
    return $d == -1 ? 5
         : $d ==  0 ? 6
         : $d ==  1 ? 7
         : 0;
};
$x = Math::Matrix -> new_from_sub($sub, 5);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[6, 7, 0, 0, 0],
                    [5, 6, 7, 0, 0],
                    [0, 5, 6, 7, 0],
                    [0, 0, 5, 6, 7],
                    [0, 0, 0, 5, 6]], '$x has the right values');
