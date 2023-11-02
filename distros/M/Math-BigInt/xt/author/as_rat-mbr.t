# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 13;
use Scalar::Util qw< refaddr >;

use Math::BigRat;

my ($x, $y);

note("as_rat() as a class method");

$x = Math::BigRat -> as_rat("Inf");
subtest '$x = Math::BigRat -> as_rat("Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", "Inf", '$x == Inf');
};

$x = Math::BigRat -> as_rat("-Inf");
subtest '$x = Math::BigRat -> as_rat("-Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", "-Inf", '$x == -Inf');
};

$x = Math::BigRat -> as_rat("NaN");
subtest '$x = Math::BigRat -> as_rat("NaN");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is($x, "NaN", '$x is NaN');
};

$x = Math::BigRat -> as_rat("2");
subtest '$x = Math::BigRat -> as_rat("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", 2, '$x == 2');
};

$x = Math::BigRat -> as_rat("2.5");
subtest '$x = Math::BigRat -> as_rat("2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("as_rat() as an instance method");

$x = Math::BigRat -> new("Inf"); $y = $x -> as_rat();
subtest '$x = Math::BigRat -> new("Inf"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", "Inf", '$y == Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigRat -> new("-Inf"); $y = $x -> as_rat();
subtest '$x = Math::BigRat -> new("-Inf"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", "-Inf", '$y == -Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigRat -> new("NaN"); $y = $x -> as_rat();
subtest '$x = Math::BigRat -> new("NaN"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    is($y, "NaN", '$y is NaN');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigRat -> new("2"); $y = $x -> as_rat();
subtest '$x = Math::BigRat -> new("2"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigRat -> new("2.5"); $y = $x -> as_rat();
subtest '$x = Math::BigRat -> new("2.5"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", 2.5, '$y == 2.5');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

note("as_rat() returns a Math::BigRat regardless of upgrading/downgrading");

require Math::BigInt;
Math::BigInt -> upgrade("Math::BigRat");
Math::BigRat -> downgrade("Math::BigInt");
Math::BigRat -> upgrade("Math::BigFloat");

$x = Math::BigRat -> new("3");
$y = $x -> as_rat();

subtest '$x = Math::BigRat -> new("3"); $y = $x -> as_rat();' => sub {
    plan tests => 3;
    is(ref($x), 'Math::BigInt', 'class of $x');
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3, 'value of $y');
};

$y = Math::BigRat -> as_rat("3");

subtest '$y = Math::BigRat -> as_rat("3");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3, 'value of $y');
};

$y = Math::BigRat -> as_rat("3.5");

subtest '$y = Math::BigRat -> as_rat("3.5");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3.5, 'value of $y');
};
