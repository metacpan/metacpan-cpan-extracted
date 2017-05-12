use strict;
use warnings;

use Math::Prime::FastSieve;

my $sieve = Math::Prime::FastSieve->new(100);

my $range_aref = $sieve->ranged_primes(25,75);

print "Prime numbers between 25 and 75 inclusive:\n";
print "$_\n" for @{$range_aref};

print "Count: ", scalar( @{$range_aref} ), "\n";
