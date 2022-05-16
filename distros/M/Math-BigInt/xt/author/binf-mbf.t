# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigFloat;

my $x;

note("binf() as a class method");

$x = Math::BigFloat -> binf();
subtest '$x = Math::BigFloat -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == inf');
};

$x = Math::BigFloat -> binf("+");

subtest '$x = Math::BigFloat -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == inf');
};

$x = Math::BigFloat -> binf("-");
subtest '$x = Math::BigFloat -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "-inf", '$x == inf');
};

note("binf() as an instane method");

$x = Math::BigFloat -> new("2") -> binf();
subtest '$x = Math::BigFloat -> new("2") -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == -inf');
};

$x = Math::BigFloat -> new("2") -> binf("+");
subtest '$x = Math::BigFloat -> new("2") -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == inf');
};

$x = Math::BigFloat -> new("2") -> binf("-");
subtest '$x = Math::BigFloat -> new("2") -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "-inf", '$x == -inf');
};

note("binf() as a function");

$x = Math::BigFloat::binf();
subtest '$x = Math::BigFloat -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == inf');
};

$x = Math::BigFloat::binf("+");
subtest '$x = Math::BigFloat -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "inf", '$x == inf');
};

$x = Math::BigFloat::binf("-");
subtest '$x = Math::BigFloat -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "-inf", '$x == -inf');
};
