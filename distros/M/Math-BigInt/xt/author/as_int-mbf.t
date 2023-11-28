# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Scalar::Util qw< refaddr >;

use Math::BigFloat;

my ($x, $y);

note("as_int() as a class method");

$x = Math::BigFloat -> as_int("2");
subtest '$x = Math::BigFloat -> as_int("2");' => sub {
    plan tests => 2;
    is(ref($x), 'Math::BigInt', '$x is a Math::BigInt');
    cmp_ok($x, "==", 2, '$x == 2');
};

note("as_int() as an instance method");

$x = Math::BigFloat -> new("2"); $y = $x -> as_int();
subtest '$x = Math::BigFloat -> new("2"); $y = $x -> as_int();' => sub {
    plan tests => 4;
    is(ref($x), 'Math::BigFloat', '$x is a Math::BigFloat');
    is(ref($y), 'Math::BigInt', '$y is a Math::BigInt');
    cmp_ok($y, "==", 2, '$y == 2');
    isnt(refaddr($x), refaddr($y), '$x and $y are different objects');
};

note("as_int() returns a Math::BigInt regardless of upgrading/downgrading");

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");
Math::BigFloat -> upgrade("Math::BigRat");

$x = Math::BigFloat -> new("3");
$y = $x -> as_int();

subtest '$x = Math::BigFloat -> new("3"); $y = $x -> as_int();' => sub {
    plan tests => 3;
    is(ref($x), 'Math::BigInt', 'class of $y');
    is(ref($y), 'Math::BigInt', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_int("3");

subtest '$y = Math::BigFloat -> as_int("3");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigInt', 'class of $y');
    cmp_ok($y -> numify(), "==", 3, 'value of $y');
};

$y = Math::BigFloat -> as_int("3.5");

subtest '$y = Math::BigFloat -> as_int("3.5");' => sub {
    plan tests => 2;
    is(ref($y), 'Math::BigInt', 'class of $y');
    is($y, "3", 'value of $y');
};

note("as_int() preserves all instance variables");

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);
Math::BigFloat -> upgrade(undef);

$x = Math::BigFloat -> new("3");

$x -> accuracy(2);
$y = $x -> as_int();

subtest '$x = Math::BigFloat -> new("3"); $x -> accuracy(2); $y = $x -> as_int()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), 2, 'accuracy of $x');
      is($x -> precision(), undef, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

$x -> precision(2);
$y = $x -> as_int();

subtest '$x = Math::BigFloat -> new("3"); $x -> precision(2); $y = $x -> as_int()'
  => sub {
      plan tests => 4;
      is($x -> accuracy(), undef, 'accuracy of $x');
      is($x -> precision(), 2, 'precision of $x');
      is($y -> accuracy(), $x -> accuracy(), 'accuracy of $y');
      is($y -> precision(), $x -> precision(), 'precision of $y');
  };

done_testing();
