# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw< refaddr >;

use Math::BigRat;

my ($x, $y);

note("as_number() as a class method");

$x = Math::BigRat -> as_number("2");
subtest '$x = Math::BigRat -> as_number("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("as_number() as an instance method");

$x = Math::BigRat -> new("2"); $y = $x -> as_number();
subtest '$x = Math::BigRat -> new("2"); $y = $x -> as_number();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};
