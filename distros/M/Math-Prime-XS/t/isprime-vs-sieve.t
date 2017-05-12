#!/usr/bin/perl

# run is_prime() against sieve_primes()
#

use strict;
use warnings;

use Math::Prime::XS 'is_prime', 'sieve_primes';
use Test::More tests => 1;

my $limit = 10_000;
my @sieve_primes = sieve_primes($limit);

my $count = 0;
my $bad = 0;
my $upto = 0;
my $last_prime;
while (my $prime = shift @sieve_primes) {

  while ($upto < $prime) {
    $count++;
    if (is_prime($upto)) {
      diag "oops, is_prime($upto) true but sieve_primes() doesn't give $upto";
      $bad++ < 10 or die "too many errors";
    }
    $upto++;
  }

  $count++;
  unless (is_prime($prime)) {
    diag "oops, is_prime($prime) false but sieve_primes() returned $prime as a prime";
    $bad++ < 10 or die;
  }
  $upto++;
  $last_prime = $prime;
}

while ($upto < $limit) {
  $count++;
  if (is_prime($upto)) {
    diag "oops, is_prime($upto) true but sieve_primes() doesn't give $upto";
    $bad++ < 10 or die "too many errors";
  }
  $upto++;
}


diag "tested 0 to $count, with last prime $last_prime";

is ($bad, 0, 'bad count');
exit 0;
