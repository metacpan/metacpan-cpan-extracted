#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::BigInt;
use Math::Revhash;

plan tests => 36;

for my $length (1..9) {
   my (undef, $len, $A, $B, $C) = Math::Revhash::_argsparse(1, $length);
   ok($len == $length, "length check");
   ok($C == 10 ** $length, "C check");
   ok($B == Math::BigInt->bmodinv($A, $C), "B check");
   if (
      $A > 0 and (
         $A =~ /^[12357]$/ or do {
            my $_A = Math::BigInt->new($A);
            $_A->bgcd(30)->is_one && $_A->bgcd(
               Math::BigInt->new("1000000016531")
            )->is_one;
         }
      )
   ) {
      # Need more tests for primality
      ok(1, "A could be a prime");
   } else {
      # A is definitely not a prime
      ok(0, "A is definitely not a prime");
   }
}
