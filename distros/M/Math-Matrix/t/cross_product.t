#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

my $x = Math::Matrix -> new([[1, 3, 2],
                             [5, 4, 2]]);

my $y = $x -> cross_product();
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[ -2, 8, -11 ]], '$y has the right values');

my $z = Math::Matrix -> new([[1, 3, 2, 4],
                             [5, 4, 2, 7],
                             [0, 4, 1, 2]]);

my $w = $z -> cross_product();
is(ref($w), 'Math::Matrix', '$w is a Math::Matrix');
is_deeply([ @$w ], [[-15, -3, -30, 21]], '$w has the right values');

__END__

# I believe the following should also work. Fixme!

my $a = Math::Matrix -> new([[1, 3, 2]]);
my $b = $a -> cross_product([[5, 4, 2]]);
is(ref($b), 'Math::Matrix', '$b is a Math::Matrix');
is_deeply([ @$b ], [[ -2, 8, -11 ]], '$b has the right values');

my $c = Math::Matrix -> new([[1, 3, 2]]);
my $d = Math::Matrix -> new([[5, 4, 2]]);
my $e = $c -> cross_product($d);
is(ref($e), 'Math::Matrix', '$e is a Math::Matrix');
is_deeply([ @$e ], [[ -2, 8, -11 ]], '$e has the right values');
