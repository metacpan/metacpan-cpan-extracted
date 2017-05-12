#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

use Math::AnyNum qw(
  i
  e
  pi
  tau
  ln2
  phi
  euler
  catalan
  Inf
  NaN
  );

like(e,       qr/^2\.718281828459\d*\z/);
like(pi,      qr/^3\.141592653589\d*\z/);
like(tau,     qr/^6\.283185307179\d*\z/);
like(ln2,     qr/^0\.693147180559\d*\z/);
like(phi,     qr/^1\.618033988749\d*\z/);
like(euler,   qr/^0\.577215664901\d*\z/);
like(catalan, qr/^0\.915965594177\d*\z/);

is(i,   'i');
is(Inf, 'Inf');
is(NaN, 'NaN');
