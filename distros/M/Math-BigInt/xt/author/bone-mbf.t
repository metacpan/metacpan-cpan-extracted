# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigFloat;

my $x;

note("bone() as a class method");

$x = Math::BigFloat -> bone();
subtest '$x = Math::BigFloat -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat -> bone("+");
subtest '$x = Math::BigFloat -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat -> bone("-");
subtest '$x = Math::BigFloat -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", -1, '$x == 0');
};

note("bone() as an instane method");

$x = Math::BigFloat -> new("2") -> bone();
subtest '$x = Math::BigFloat -> new("2") -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat -> new("2") -> bone("+");
subtest '$x = Math::BigFloat -> new("2") -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat -> new("2") -> bone("-");
subtest '$x = Math::BigFloat -> new("2") -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", -1, '$x == 0');
};

note("bone() as a function");

$x = Math::BigFloat::bone();
subtest '$x = Math::BigFloat -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat::bone("+");
subtest '$x = Math::BigFloat -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 1, '$x == 0');
};

$x = Math::BigFloat::bone("-");
subtest '$x = Math::BigFloat -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", -1, '$x == 0');
};
