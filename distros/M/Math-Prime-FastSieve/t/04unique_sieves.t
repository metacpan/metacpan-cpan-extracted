## no critic(RCS,VERSION,explicit,Module,ProhibitMagicNumbers)
use strict;
use warnings;

use Test::More;

use Math::Prime::FastSieve qw( primes );

# A test in Inline::CPP v0.33_009 looked like one object instance might be
# binding to another object instance's data.  This test is to verify that's
# not happening here.

note('Testing that multiple sieve objects bind properly.');

# Build a list of sieve sizes and number of primes in a given sieve.
my %quantities;
foreach my $sieve_size ( 0, 2, 3, 5, 7, 11, 13, 17, 19, 23 ) {
    $quantities{$sieve_size} = scalar @{ primes($sieve_size) };
}

# Instantiate a bunch of sieve objects.
my %sieves =
  map { ( $quantities{$_}, new_ok( 'Math::Prime::FastSieve::Sieve', [$_] ) ) }
  keys %quantities;

# Verify that the accessor $obj->count_sieve() is binding to the correct
# object.
foreach my $quantity ( sort { $a <=> $b } keys %sieves ) {
    is( $sieves{$quantity}->count_sieve(),
        $quantity, "Sieve object holding [$quantity] primes correctly bound." );
}

done_testing();
