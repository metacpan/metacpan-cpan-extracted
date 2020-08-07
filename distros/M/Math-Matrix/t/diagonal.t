#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 20;

my $dp = [[ 1,  0,  0,  0],
          [ 0,  4,  0,  0],
          [ 0,  0,  4,  0],
          [ 0,  0,  0,  8]];

my $dr = [[ 1,  1,  0,  0],
          [ 1,  4,  1,  0],
          [ 0,  1,  4,  1],
          [ 0,  0,  1,  8]];

my $ds = [[ 1,  9,  0,  0],
          [ 9,  4, 12,  0],
          [ 0, 12,  4, 15],
          [ 0,  0, 15,  8]];

my $dt = [[ 1,  9,  0,  0 ],
          [ 4,  4, 12,  0 ],
          [ 0,  3,  4, 15 ],
          [ 0,  0,  2,  8 ]];

my $du = [[ 1,  1,  0,  0 ],
          [ 1,  4,  1,  0 ],
          [ 0,  1,  4,  1 ],
          [ 0,  0,  1,  8 ]];

###############################################################################

note("test diagonal()");

my $p = Math::Matrix->diagonal(1, 4, 4, 8);

is(ref($p), 'Math::Matrix', '$p is a Math::Matrix');
is_deeply([ @$p ], $dp, '$p has the right values');

my $q = Math::Matrix->diagonal([1, 4, 4, 8]);

is(ref($q), 'Math::Matrix', '$q is a Math::Matrix');
is_deeply([ @$q ], $dp, '$q has the right values');

###############################################################################

note("test tridiagonal()");

my $r = Math::Matrix->tridiagonal([1, 4, 4, 8]);

is(ref($r), 'Math::Matrix', '$r is a Math::Matrix');
is_deeply([ @$r ], $dr, '$r has the right values');

my $s = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15]);

is(ref($s), 'Math::Matrix', '$s is a Math::Matrix');
is_deeply([ @$s ], $ds, '$s has the right values');

my $t = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15], [4, 3, 2]);

is(ref($t), 'Math::Matrix', '$t is a Math::Matrix');
is_deeply([ @$t ], $dt, '$t has the right values');

my $u = Math::Matrix->tridiagonal([1, 4, 4, 8], [1, 1, 1], [1, 1, 1]);

is(ref($u), 'Math::Matrix', '$u is a Math::Matrix');
is_deeply([ @$u ], $du, '$u has the right values');

###############################################################################

note("test diagonal_vector()");

my $v = $r->diagonal_vector();
is(ref($v), 'ARRAY', '$v is an ARRAY');
is_deeply([ @$v ], [1, 4, 4, 8], '$v has the right values');

###############################################################################

note("test tridiagonal_vector()");

my ($v_main, $v_upper, $v_lower) = $t->tridiagonal_vector();

is(ref($v_main), 'ARRAY', '$v_main is an ARRAY');
is_deeply([ @$v_main ], [1, 4, 4, 8], '$v_main has the right values');

is(ref($v_upper), 'ARRAY', '$v_upper is an ARRAY');
is_deeply([ @$v_upper ], [9, 12, 15], '$v_upper has the right values');

is(ref($v_lower), 'ARRAY', '$v_lower is an ARRAY');
is_deeply([ @$v_lower ], [4, 3, 2], '$v_lower has the right values');
