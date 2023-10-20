# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigFloat;

my ($x, $y);

note("Testing Math::BigInt->bsgn() without downgrading and upgrading");

note("bsgn() as a class method");

$x = Math::BigInt -> bsgn("-2");
subtest '$x = Math::BigInt -> bsgn("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bsgn() as an instance method");

$x = Math::BigInt -> new("-2"); $y = $x -> bsgn();
subtest '$x = Math::BigInt -> new("-2"); $y = $x -> bsgn();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("Testing Math::BigInt->bsgn() with downgrading and upgrading");

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

note("bsgn() as a class method");

$x = Math::BigInt -> bsgn("-2");
subtest '$x = Math::BigInt -> bsgn("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bsgn() as an instance method");

$x = Math::BigInt -> new("-2"); $y = $x -> bsgn();
subtest '$x = Math::BigInt -> new("-2"); $y = $x -> bsgn();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", -1, '$x == -1');
};
