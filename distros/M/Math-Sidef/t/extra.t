#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 16;

use Math::Sidef qw(:all);

is(pow(Gauss(3,4), 10), Gauss(-9653287, Number("1476984")));
is(pow(Fraction(3,4), 10), Fraction(ipow(3, 10), ipow(4, 10)));
is(pow(Quadratic(3,4,2), 10), Quadratic(Number("1181882441"), Number("835704696"), 2));
is(pow(Quaternion(3,4,2,5), 10), Quaternion("222969024", "-239345280", "-119672640", "-299181600"));
is(pow(Poly([3,4,5]), 2), Polynomial(0 => 25, 1 => 40, 2 => 46, 3 => 24, 4 => 9));

is(pow(Mod(42, 97), 10), Mod(8, 97));
is(powmod(Quadratic(3, 4, 100), 10, 97), Quadratic(72, 72, 100));
is(cyclotomic_polynomial(10), Polynomial(0 => 1, 1 => -1, 2 => 1, 3 => -1, 4 => 1));

is(add(Gauss(3,4), Gauss(9,10)), Gauss(3+9, 4+10));
is(Gauss(3,4)->add(Gauss(9,10)), Gauss(3+9, 4+10));

is(Poly(1), Poly(1 => 1));
is(Poly(1), Poly([1, 0]));
is(Poly(2), Poly([1, 0, 0]));

is(mul(Poly([9,0,2]), Poly([3,1])), Polynomial(0 => 2, 1 => 6, 2 => 9, 3 => 27));

#is(Gauss(3,4) + Gauss(9,10), Gauss(3+9, 4+10));    # TODO
#is(binomial(Poly(1), 3), Polynomial(1 => div(1,3), 2 => div(-1,2), 3 => div(1,6)));

my $x = Polynomial(1 => div(1,6), 2 => div(1,2), 3 => div(1,3));

is_deeply(
    [map { Math::Sidef::eval($x, $_) } 0..10],
    [0, 1, 5, 14, 30, 55, 91, 140, 204, 285, 385]
);

my $y = Polynomial(1 => Fraction(1,6), 2 => Fraction(1,2), 3 => Fraction(1,3));

is_deeply(
    [map { round(Math::Sidef::eval($y, $_)) } 0..10],
    [0, 1, 5, 14, 30, 55, 91, 140, 204, 285, 385]
);
