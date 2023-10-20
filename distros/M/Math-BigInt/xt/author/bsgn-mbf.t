# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigFloat;

my ($x, $y);

note("Testing Math::BigFloat->bsgn() without downgrading and upgrading");

note("bsgn() as a class method");

$x = Math::BigFloat -> bsgn("-2");
subtest '$x = Math::BigFloat -> bsgn("-2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bsgn() as an instance method");

$x = Math::BigFloat -> new("-2"); $y = $x -> bsgn();
subtest '$x = Math::BigFloat -> new("-2"); $y = $x -> bsgn();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("Testing Math::BigFloat->bsgn() with downgrading and upgrading");

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

# The cases below will downgrade, since the sign can be represented as a
# Math::BigInt object.

note("bsgn() as a class method");

$x = Math::BigFloat -> bsgn("-2.5");
subtest '$x = Math::BigFloat -> bsgn("-2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bsgn() as an instance method");

$x = Math::BigFloat -> new("-2.5"); $y = $x -> bsgn();
subtest '$x = Math::BigFloat -> new("-2.5"); $y = $x -> bsgn();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    cmp_ok($x, "==", -2.5, '$x == -2.5');
    cmp_ok($y, "==", -1, '$x == -1');
};
