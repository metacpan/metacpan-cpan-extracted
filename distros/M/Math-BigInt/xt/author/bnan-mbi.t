# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

use Math::BigInt;

my $x;

note("bnan() as a class method");

$x = Math::BigInt -> bnan();
subtest '$x = Math::BigInt -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "NaN", '$x == NaN');
};

note("bnan() as an instane method");

$x = Math::BigInt -> new("2") -> bnan();
subtest '$x = Math::BigInt -> new("2") -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "NaN", '$x == NaN');
};

note("bnan() as a function");

$x = Math::BigInt::bnan();
subtest '$x = Math::BigInt -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "NaN", '$x == NaN');
};
