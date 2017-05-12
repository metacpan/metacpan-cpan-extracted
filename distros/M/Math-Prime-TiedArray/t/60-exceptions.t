#!perl -T

use Test::More;
use Math::Prime::TiedArray;

eval "use Test::Exception";
plan skip_all => "Test::Exception required for testing exceptions" if $@;
plan tests => 2;

tie my @a, "Math::Prime::TiedArray", extend_ceiling => 10, precompute => 5;
throws_ok(sub {$a[10]}, qr/Cannot extend beyond 10!/, "Exception generated when breaking ceiling");

tie @a, "Math::Prime::TiedArray", extend_ceiling => 100, precompute => 5;
lives_ok(sub {$a[10]}, "Can extend below the ceiling");

