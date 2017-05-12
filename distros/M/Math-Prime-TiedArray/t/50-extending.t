#!perl -T

use Test::More tests => 8;
use Math::Prime::TiedArray;

tie my @a, "Math::Prime::TiedArray";

my %tests = (
  9 => 29,
  49 => 229,
  99 => 541,
  199 => 1223,
  499 => 3571,
  999 => 7919,
  1999 => 17389,
  4999 => 48611,
);

foreach (sort {$a<=>$b} keys %tests) {
  is($a[$_], $tests{$_}, "${_}th prime is $tests{$_}");
}
