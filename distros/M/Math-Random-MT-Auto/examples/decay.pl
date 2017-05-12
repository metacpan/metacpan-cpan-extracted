#!/usr/bin/perl

# Produces a decay curve using exponential random numbers.
# Uses a mean of 15, and computes 80 'bins' of data.

# Usage:  decay.pl [COUNT]
#         COUNT defaults to 1 million

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(exponential);

MAIN:
{
    my $count = (@ARGV) ? $ARGV[0] : 1000000;

    my %decay;

    # Get random numbers and put them in bins
    print("Generating $count exponential random numbers.  Please wait...");
    for (1 .. $count) {
        my $x = int(exponential(15));

        # Make sure the tail doesn't overflow
        if ($x > 80) {
            $x = 80;
        }

        $decay{$x}++;
    }

    # Find the max bin size for scaling the output
    my $max = 0;
    while (my $key = each(%decay)) {
        if ($max < $decay{$key}) {
            $max = $decay{$key};
        }
    }

    # Output the graph
    print("\n");
    for my $key (sort { $a <=> $b } (keys(%decay))) {
        my $len = int(79.0 * $decay{$key}/$max);
        print(':', '*' x $len, "\n");
    }
}

exit(0);

# EOF
