#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 3;

my $tol = 1e-10;

my $x = Math::Matrix -> new([3, 4]) -> normalize();
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
cmp_ok(abs($x -> [0][0] - 0.6), '<', $tol,
       "\$x->[0][0] has the right value within $tol");
cmp_ok(abs($x -> [0][1] - 0.8), '<=', $tol,
       "\$x->[0][1] has the right value within $tol");
