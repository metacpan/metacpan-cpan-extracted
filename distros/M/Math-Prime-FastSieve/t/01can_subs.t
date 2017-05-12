## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;
use Test::More;
use Math::Prime::FastSieve;

# Test exported "non-OO" sub.
can_ok( 'Math::Prime::FastSieve', 'primes' );

# Test OO subs.
my @object_methods = qw/
  new             primes          ranged_primes
  isprime         nearest_le      nearest_ge
  count_sieve     count_le        nth_prime
  is_prime
  /;

can_ok( 'Math::Prime::FastSieve::Sieve', @object_methods );

done_testing();
