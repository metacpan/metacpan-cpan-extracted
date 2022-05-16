# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigInt;

my $x;

note("bone() as a class method");

$x = Math::BigInt -> bone();
subtest '$x = Math::BigInt -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt -> bone("+");

subtest '$x = Math::BigInt -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt -> bone("-");
subtest '$x = Math::BigInt -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bone() as an instane method");

$x = Math::BigInt -> new("2") -> bone();
subtest '$x = Math::BigInt -> new("2") -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt -> new("2") -> bone("+");
subtest '$x = Math::BigInt -> new("2") -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt -> new("2") -> bone("-");
subtest '$x = Math::BigInt -> new("2") -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};

note("bone() as a function");

$x = Math::BigInt::bone();
subtest '$x = Math::BigInt -> bone()' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt::bone("+");
subtest '$x = Math::BigInt -> bone("+")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 1, '$x == 1');
};

$x = Math::BigInt::bone("-");
subtest '$x = Math::BigInt -> bone("-")' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", -1, '$x == -1');
};
