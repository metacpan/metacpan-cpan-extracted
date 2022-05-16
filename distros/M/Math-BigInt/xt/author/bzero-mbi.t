# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

use Math::BigInt;

my $x;

note("bzero() as a class method");

$x = Math::BigInt -> bzero();
subtest '$x = Math::BigInt -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 0, '$x == 0');
};

note("bzero() as an instance method");

$x = Math::BigInt -> new("2") -> bzero();
subtest '$x = Math::BigInt -> new("2") -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 0, '$x == 0');
};

note("bzero() as a function");

$x = Math::BigInt::bzero();
subtest '$x = Math::BigInt -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 0, '$x == 0');
};
