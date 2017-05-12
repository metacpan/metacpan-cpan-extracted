#!/usr/bin/perl

# Produces a graph of random numbers from an Erlang distribution.

# Usage:  erlang.pl [ORDER [COUNT]]
#         ORDER defaults to 3
#         COUNT defaults to 1 million

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(erlang);

MAIN:
{
    my $order = (@ARGV)     ? $ARGV[0] : 3;
    my $count = (@ARGV > 1) ? $ARGV[1] : 1000000;

    my %erlang;

    # Get random numbers and put them in bins
    print("Generating $count Erlang random numbers.  Please wait...");
    for (1 .. $count) {
        my $x = int(erlang($order, 40/($order+2)));

        # Make sure the tail doesn't overflow
        if ($x > 80) {
            $x = 80;
        }

        $erlang{$x}++;
    }

    # Find the max bin size for scaling the output
    my $max = 0;
    while (my $key = each(%erlang)) {
        if ($max < $erlang{$key}) {
            $max = $erlang{$key};
        }
    }

    # Output the graph
    print("\n");
    for my $key (sort { $a <=> $b } (keys(%erlang))) {
        my $len = int(79.0 * $erlang{$key}/$max);
        print(':', '*' x $len, "\n");
    }
}

exit(0);

# EOF
