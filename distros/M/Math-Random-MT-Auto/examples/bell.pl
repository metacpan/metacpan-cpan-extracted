#!/usr/bin/perl

# Produces a bell curve using Gaussian random numbers.
# Uses a standard deviation of 10 and a mean of 0.5 so that the '0' bin
#   contains the randoms from 0 to 1 and so on.
# Plots +/- 4 standard deviations.

# Usage:  bell.pl [COUNT]
#         COUNT defaults to 1 million

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(gaussian);

MAIN:
{
    my $count = (@ARGV) ? $ARGV[0] : 1000000;

    my %bell;

    # Get random numbers and put them in bins
    print("Generating $count Gaussian random numbers.  Please wait...");
    for (1 .. $count) {
        my $x = gaussian(10, 0.5);

        # Handle 'rounding' using int()
        if ($x < 0) {
            $x = int($x-1);
        } else {
            $x = int($x);
        }

        # Make sure the tails don't overflow
        if ($x > 40) {
            $x = 40;
        } elsif ($x < -40) {
            $x = -40;
        }

        $bell{$x}++;
    }

    # Find the max bin size for scaling the output
    my $max = 0;
    while (my $key = each(%bell)) {
        if ($max < $bell{$key}) {
            $max = $bell{$key};
        }
    }

    # Output the graph
    print("\n");
    for my $key (sort { $a <=> $b } (keys(%bell))) {
        my $len = int(79.0 * $bell{$key}/$max);
        print(':', '*' x $len, "\n");
    }
}

exit(0);

# EOF
