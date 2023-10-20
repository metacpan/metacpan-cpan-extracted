# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigFloat;

my ($x, $y);

note("Testing Math::BigInt->babs() without downgrading and upgrading");

note("babs() as a class method");

$x = Math::BigInt -> babs("-2");
subtest '$x = Math::BigInt -> babs("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as an instance method");

$x = Math::BigInt -> new("-2"); $y = $x -> babs();
subtest '$x = Math::BigInt -> new("-2"); $y = $x -> babs();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as a function");

$x = Math::BigInt::babs("-2");
subtest '$x = Math::BigInt::babs("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("Testing Math::BigInt->babs() with downgrading and upgrading");

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

note("babs() as a class method");

$x = Math::BigInt -> babs("-2");
subtest '$x = Math::BigInt -> babs("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as an instance method");

$x = Math::BigInt -> new("-2"); $y = $x -> babs();
subtest '$x = Math::BigInt -> new("-2"); $y = $x -> babs();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("babs() as a function");

$x = Math::BigInt::babs("-2");
subtest '$x = Math::BigInt::babs("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};
