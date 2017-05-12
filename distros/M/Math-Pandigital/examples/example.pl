#!/usr/bin/env perl

use strict;
use warnings;

use Math::Pandigital;

# Find the first 350 pandigital numbers (no repeated digits, zerofull)
# using brute force (note, permutation would be quicker for this).

my $p = Math::Pandigital->new( unique => 1 );

my $count = 0;
my $n = 1023456789;
while ( $count < 350 ) {
  if( $p->is_pandigital($n) ) {
    $count++;
    print "$count: $n is pandigital.\n";
  }
  $n++;
}
