# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("babs() as a class method");

$x = Math::BigFloat -> babs("-2");
subtest '$x = Math::BigFloat -> babs("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as an instance method");

$x = Math::BigFloat -> new("-2"); $y = $x -> babs();
subtest '$x = Math::BigFloat -> new("-2"); $y = $x -> babs();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as a function");

SKIP: {
    skip "Math::BigFloat::babs() is a method, not a function", 1;

    $x = Math::BigFloat::babs("-2");
    subtest '$x = Math::BigFloat::babs("-2");' => sub {
        plan tests => 2;
        is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
        cmp_ok($x, "==", 2, '$x == 2');
    };
}
