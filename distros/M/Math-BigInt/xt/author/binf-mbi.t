# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigInt;

my $x;

note("binf() as a class method");

$x = Math::BigInt -> binf();
subtest '$x = Math::BigInt -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == inf');
};

$x = Math::BigInt -> binf("+");

subtest '$x = Math::BigInt -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == inf');
};

$x = Math::BigInt -> binf("-");
subtest '$x = Math::BigInt -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "-inf", '$x == inf');
};

note("binf() as an instane method");

$x = Math::BigInt -> new("2") -> binf();
subtest '$x = Math::BigInt -> new("2") -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == -inf');
};

$x = Math::BigInt -> new("2") -> binf("+");
subtest '$x = Math::BigInt -> new("2") -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == inf');
};

$x = Math::BigInt -> new("2") -> binf("-");
subtest '$x = Math::BigInt -> new("2") -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "-inf", '$x == -inf');
};

note("binf() as a function");

$x = Math::BigInt::binf();
subtest '$x = Math::BigInt -> binf()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == inf');
};

$x = Math::BigInt::binf("+");
subtest '$x = Math::BigInt -> binf("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "inf", '$x == inf');
};

$x = Math::BigInt::binf("-");
subtest '$x = Math::BigInt -> binf("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    is($x, "-inf", '$x == -inf');
};
