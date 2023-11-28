# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("as_float() as a class method");

$x = Math::BigFloat -> as_float("Inf");
subtest '$x = Math::BigFloat -> as_float("Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", "Inf", '$x == Inf');
};

$x = Math::BigFloat -> as_float("-Inf");
subtest '$x = Math::BigFloat -> as_float("-Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", "-Inf", '$x == -Inf');
};

$x = Math::BigFloat -> as_float("NaN");
subtest '$x = Math::BigFloat -> as_float("NaN");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is($x, "NaN", '$x is NaN');
};

$x = Math::BigFloat -> as_float("2");
subtest '$x = Math::BigFloat -> new("2"); $x -> as_float();' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2, '$x == 2');
};

$x = Math::BigFloat -> as_float("2.5");
subtest '$x = Math::BigFloat -> as_float("2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("as_float() as an instance method");

$x = Math::BigFloat -> new("Inf"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("Inf"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", "Inf", '$y == Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("-Inf"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("-Inf"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", "-Inf", '$y == -Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("NaN"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("NaN"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    is($y, "NaN", '$y is NaN');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("2"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("2"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("2.5"); $y = $x -> as_float();
subtest '$x = Math::BigFloat -> new("2.5"); $y = $x -> as_float();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigFloat', '$y is a Math::BigFloat');
    cmp_ok($y, "==", 2.5, '$y == 2.5');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

note("as_float() returns a Math::BigFloat regardless of upgrading/downgrading");

require Math::BigInt;
Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");
Math::BigFloat -> upgrade("Math::BigRat");

$x = Math::BigFloat -> new("3");
$y = $x -> as_float();

subtest '$x = Math::BigFloat -> new("3"); $y = $x -> as_float();' => sub {
    plan tests => 3;
    is(ref($x), 'Math::BigInt', 'class of $x');
    is(ref($y), 'Math::BigFloat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_float("3");

subtest '$y = Math::BigFloat -> as_float("3");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigFloat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_float("3.5");

subtest '$y = Math::BigFloat -> as_float("3.5");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigFloat', 'class of $y');
    cmp_ok(eval("$y"), "==", 3.5, 'value of $y');
};

note("as_float() preserves all instance variables");

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);
Math::BigFloat -> upgrade(undef);

$x = Math::BigFloat -> new("3");

$x -> accuracy(2);
$y = $x -> as_float();

subtest '$x = Math::BigFloat -> new("3"); $x -> accuracy(2); $y = $x -> as_float()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), 2, 'accuracy of $x');
      is($x -> precision(), undef, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

$x -> precision(2);
$y = $x -> as_float();

subtest '$x = Math::BigFloat -> new("3"); $x -> precision(2); $y = $x -> as_float()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), undef, 'accuracy of $x');
      is($x -> precision(), 2, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

done_testing();
