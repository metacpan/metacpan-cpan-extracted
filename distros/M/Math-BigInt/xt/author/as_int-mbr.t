# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw< refaddr >;

use Math::BigRat;

my ($x, $y);

note("as_int() as a class method");

$x = Math::BigRat -> as_int("2");
subtest '$x = Math::BigRat -> as_int("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("as_int() as an instance method");

$x = Math::BigRat -> new("2"); $y = $x -> as_int();
subtest '$x = Math::BigRat -> new("2"); $y = $x -> as_int();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

note("as_int() returns a Math::BigInt regardless of upgrading/downgrading");

Math::BigInt -> upgrade("Math::BigRat");
Math::BigRat -> downgrade("Math::BigInt");
Math::BigRat -> upgrade("Math::BigRat");

$x = Math::BigRat -> new("3");
$y = $x -> as_int();

subtest '$x = Math::BigRat -> new("3"); $y = $x -> as_int();' => sub {
    plan tests => 3;
    is(ref($x), 'Math::BigInt', 'class of $y');
    is(ref($y), 'Math::BigInt', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigRat -> as_int("3");

subtest '$y = Math::BigRat -> as_int("3");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigInt', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigRat -> as_int("3.5");

subtest '$y = Math::BigRat -> as_int("3.5");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigInt', 'class of $y');
    is($y, "3", 'value of $y');
};
