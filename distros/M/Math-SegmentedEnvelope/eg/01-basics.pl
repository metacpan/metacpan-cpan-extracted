#!/usr/bin/env perl
# Basic envelope creation, evaluation, and inspection
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Create an envelope from explicit definition:
#   levels:    [0, 1, 0.6, 0]    (4 values = 3 segments + 1)
#   durations: [0.1, 0.3, 0.6]   (3 segment durations)
#   curves:    [2, -2, -3]       (positive=ease-in, negative=ease-out)
my $e = env(
    [[0, 1, 0.6, 0], [0.1, 0.3, 0.6], [2, -2, -3]],
);

printf "Segments: %d\n", $e->segments;
printf "Duration: %.2f\n", $e->duration;

# Evaluate at specific times
for my $t (0, 0.05, 0.1, 0.2, 0.5, 0.8, 1.0) {
    printf "  at(%.2f) = %.4f\n", $t, $e->at($t);
}

# Inspect the definition
my $def = $e->def;
printf "\nLevels:    %s\n", join(', ', map { sprintf '%.2f', $_ } @{$def->[0]});
printf "Durations: %s\n", join(', ', map { sprintf '%.2f', $_ } @{$def->[1]});
printf "Curves:    %s\n", join(', ', map { sprintf '%.2f', $_ } @{$def->[2]});

# Random envelope (different each run, respects srand)
srand(42);
my $r = env();
printf "\nRandom: %d segments, duration %.4f\n", $r->segments, $r->duration;
