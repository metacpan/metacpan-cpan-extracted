# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("as_float() as a class method");

$x = Math::BigFloat -> as_float("2");
subtest '$x = Math::BigFloat -> new("2"); $x -> as_float();' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2, '$x == 2');
};

$x = Math::BigFloat -> as_float("2.5");
subtest '$x = Math::BigFloat -> as_float("2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("as_float() as an instance method");

$x = Math::BigFloat -> new("2"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("2"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("2.5"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("2.5"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", 2.5, '$y == 2.5');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};
