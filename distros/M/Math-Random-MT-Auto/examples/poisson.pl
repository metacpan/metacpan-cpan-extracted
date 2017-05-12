#!/usr/bin/perl

# Produces a graph of random numbers from a Poisson distribution.

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(poisson);

MAIN:
{
    if (! @ARGV) {
        print("Usage:  poisson.pl MEAN [COUNT]]\n");
        print("\tCOUNT defaults to 1 million\n");

    }
    my $mean  = $ARGV[0];
    my $count = (@ARGV > 1) ? $ARGV[1] : 1000000;

    my %poisson;

    # Get random numbers and put them in bins
    print("Generating $count Poisson random numbers.  Please wait...");
    for (1 .. $count) {
        my $x = poisson($mean);

        # Make sure the tail doesn't overflow
        if ($x > 80) {
            $x = 80;
        }

        $poisson{$x}++;
    }

    # Find the max bin size for scaling the output
    my $max = 0;
    while (my $key = each(%poisson)) {
        if ($max < $poisson{$key}) {
            $max = $poisson{$key};
        }
    }

    # Output the graph
    print("\n");
    for my $key (sort { $a <=> $b } (keys(%poisson))) {
        my $len = int(79.0 * $poisson{$key}/$max);
        print(':', '*' x $len, "\n");
    }
}

exit(0);

# EOF
