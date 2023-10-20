# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigFloat;

my ($x, $y);

note("Testing Math::BigFloat->babs() without downgrading and upgrading");

note("babs() as a class method");

$x = Math::BigFloat -> babs("-2.5");
subtest '$x = Math::BigFloat -> babs("-2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("babs() as an instance method");

$x = Math::BigFloat -> new("-2.5"); $y = $x -> babs();
subtest '$x = Math::BigFloat -> new("-2.5"); $y = $x -> babs();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("babs() as a function");

SKIP: {
    skip "Math::BigFloat::babs() is a method, not a function", 1;

    $x = Math::BigFloat::babs("-2.5");
    subtest '$x = Math::BigFloat::babs("-2.5");' => sub {
        plan tests => 2;
        is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
        cmp_ok($x, "==", 2.5, '$x == 2.5');
    };
}

note("Testing Math::BigFloat->babs() with downgrading and upgrading");

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

note("babs() as a class method");

$x = Math::BigFloat -> babs("-2.5");
subtest '$x = Math::BigFloat -> babs("-2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("babs() as an instance method");

$x = Math::BigFloat -> new("-2.5"); $y = $x -> babs();
subtest '$x = Math::BigFloat -> new("-2.5"); $y = $x -> babs();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("babs() as a function");

SKIP: {
    skip "Math::BigFloat::babs() is a method, not a function", 1;

    $x = Math::BigFloat::babs("-2.5");
    subtest '$x = Math::BigFloat::babs("-2.5");' => sub {
        plan tests => 2;
        is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
        cmp_ok($x, "==", 2.5, '$x == 2.5');
    };
}
