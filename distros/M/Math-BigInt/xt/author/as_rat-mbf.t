# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("as_rat() as a class method");

$x = Math::BigFloat -> as_rat("Inf");
subtest '$x = Math::BigFloat -> as_rat("Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", "Inf", '$x == Inf');
};

$x = Math::BigFloat -> as_rat("-Inf");
subtest '$x = Math::BigFloat -> as_rat("-Inf");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", "-Inf", '$x == -Inf');
};

$x = Math::BigFloat -> as_rat("NaN");
subtest '$x = Math::BigFloat -> as_rat("NaN");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    is($x, "NaN", '$x is NaN');
};

$x = Math::BigFloat -> as_rat("2");
subtest '$x = Math::BigFloat -> as_rat("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", 2, '$x == 2');
};

$x = Math::BigFloat -> as_rat("2.5");
subtest '$x = Math::BigFloat -> as_rat("2.5");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigRat', '$x is a Math::BigRat');
    cmp_ok($x, "==", 2.5, '$x == 2.5');
};

note("as_rat() as an instance method");

$x = Math::BigFloat -> new("Inf"); $y = $x -> as_rat();
subtest '$x = Math::BigFloat -> new("Inf"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", "Inf", '$y == Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("-Inf"); $y = $x -> as_rat();
subtest '$x = Math::BigFloat -> new("-Inf"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", "-Inf", '$y == -Inf');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("NaN"); $y = $x -> as_rat();
subtest '$x = Math::BigFloat -> new("NaN"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    is($y, "NaN", '$y is NaN');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("2"); $y = $x -> as_rat();
subtest '$x = Math::BigFloat -> new("2"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

$x = Math::BigFloat -> new("2.5"); $y = $x -> as_rat();
subtest '$x = Math::BigFloat -> new("2.5"); $y = $x -> as_rat();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigRat', '$y is a Math::BigRat');
    cmp_ok($y, "==", 2.5, '$y == 2.5');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

note("as_rat() returns a Math::BigRat regardless of upgrading/downgrading");

require Math::BigRat;
Math::BigInt -> upgrade("Math::BigFloat");
Math::BigRat -> downgrade("Math::BigInt");
Math::BigRat -> upgrade("Math::BigFloat");

$x = Math::BigFloat -> new("3");
$y = $x -> as_rat();

subtest '$x = Math::BigFloat -> new("3"); $y = $x -> as_rat();' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_rat("3");

subtest '$y = Math::BigFloat -> as_rat("3");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_rat("3.5");

subtest 'Math::BigFloat -> as_rat("3.5");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigRat', 'class of $y');
    cmp_ok($y -> numify(), "==", 3.5, 'value of $y');
};

note("as_rat() preserves all instance variables");

Math::BigInt -> upgrade(undef);
Math::BigRat -> downgrade(undef);
Math::BigRat -> upgrade(undef);

$x = Math::BigFloat -> new("3");

$x -> accuracy(2);
$y = $x -> as_rat();

subtest '$x = Math::BigFloat -> new("3"); $x -> accuracy(2); $y = $x -> as_rat()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), 2, 'accuracy of $x');
      is($x -> precision(), undef, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

$x -> precision(2);
$y = $x -> as_rat();

subtest '$x = Math::BigFloat -> new("3"); $x -> precision(2); $y = $x -> as_rat()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), undef, 'accuracy of $x');
      is($x -> precision(), 2, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

done_testing();
