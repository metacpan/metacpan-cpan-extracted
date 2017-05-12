#!/usr/bin/perl

# Produces a graph of random numbers from a binomial distribution.

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(binomial);

MAIN:
{
    if (! @ARGV) {
        print("Usage:  binomial.pl PROB TRIALS [COUNT]]\n");
        print("\tPROB must be between 0.0 and 1.0 (inclusive)\n");
        print("\tTRIALS must be >= 0\n");
        print("\tCOUNT defaults to 1 million\n");

    }
    my $prob   = $ARGV[0];
    my $trials = $ARGV[1];
    my $count  = (@ARGV > 2) ? $ARGV[2] : 1000000;

    my %binomial;

    # Get random numbers and put them in bins
    print("Generating $count binomial random numbers.  Please wait...");
    for (1 .. $count) {
        my $x = binomial($prob, $trials);
        $binomial{$x}++;
    }

    # Find the max bin size for scaling the output
    my $max = 0;
    while (my $key = each(%binomial)) {
        if ($max < $binomial{$key}) {
            $max = $binomial{$key};
        }
    }

    # Output the graph
    print("\n");
    for my $key (sort { $a <=> $b } (keys(%binomial))) {
        my $len = int(79.0 * $binomial{$key}/$max);
        print(':', '*' x $len, "\n");
    }
}

exit(0);

# EOF
