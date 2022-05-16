# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw< refaddr >;

use Math::BigInt;

my ($x, $y);

note("as_float() as a class method");

$x = Math::BigInt -> as_float("2");
subtest '$x = Math::BigInt -> as_float("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("as_float() as an instance method");

$x = Math::BigInt -> new("2"); $y = $x -> as_float();
subtest '$x = Math::BigInt -> new("2"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};
