# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

use Math::BigFloat;

my $x;

note("bzero() as a class method");

$x = Math::BigFloat -> bzero();
subtest '$x = Math::BigFloat -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');
};

note("bzero() as an instance method");

$x = Math::BigFloat -> new("2") -> bzero();
subtest '$x = Math::BigFloat -> new("2") -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');
};

note("bzero() as a function");

$x = Math::BigFloat::bzero();
subtest '$x = Math::BigFloat -> bzero()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');
};
