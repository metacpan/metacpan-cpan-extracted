# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

use Math::BigFloat;

my $x;

note("bnan() as a class method");

$x = Math::BigFloat -> bnan();
subtest '$x = Math::BigFloat -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "NaN", '$x == NaN');
};

note("bnan() as an instane method");

$x = Math::BigFloat -> new("2") -> bnan();
subtest '$x = Math::BigFloat -> new("2") -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "NaN", '$x == NaN');
};

note("bnan() as a function");

$x = Math::BigFloat::bnan();
subtest '$x = Math::BigFloat -> bnan()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "NaN", '$x == NaN');
};
