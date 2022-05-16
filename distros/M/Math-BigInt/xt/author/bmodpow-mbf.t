# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("bmodpow() as a class method");

$x = Math::BigFloat -> bmodpow("5", "7", "11");
subtest '$x = Math::BigFloat -> bmodpow("5, "7", "11");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 3, '$x == 3');
};

note("bmodpow() as an instance method");

$x = Math::BigFloat -> new("5"); $y = $x -> bmodpow("7", "11");
subtest '$x = Math::BigFloat -> new("5"); $y = $x -> bmodpow("7", "11");' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is(refaddr($x), refaddr($y), '$x and $y are the same object');
    cmp_ok($x, "==", 3, '$x == 3');
};

# Test when the same object appears more than once.

$x = Math::BigFloat -> new("5"); $y = $x -> bmodpow("7", $x);
subtest '$x = Math::BigFloat->new("5"); $y = $x -> bmodpow("5", $x);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');     # (5**7) % 5 = 0
};

$x = Math::BigFloat -> new("5"); $y = $x -> bmodpow($x, "7");
subtest '$x = Math::BigFloat->new("5"); $y = $x -> bmodpow($x, "7");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 3, '$x == 3');     # (5**5) % 7 = 3
};

$x = Math::BigFloat -> new("5"); $y = $x -> bmodpow($x, $x);
subtest '$x = Math::BigFloat->new("5"); $y = $x -> bmodpow($x, $x);' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 0, '$x == 0');     # (5**5) % 5 = 0
};
