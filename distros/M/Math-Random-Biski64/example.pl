#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Math::Random::Biski64;

my $rng  = Math::Random::Biski64->new();

# --- Shuffle an array (Fisher-Yates) ---
my @deck = qw(
    2H 3H 4H 5H 6H 7H 8H 9H TH JH QH KH AH
    2D 3D 4D 5D 6D 7D 8D 9D TD JD QD KD AD
    2C 3C 4C 5C 6C 7C 8C 9C TC JC QC KC AC
    2S 3S 4S 5S 6S 7S 8S 9S TS JS QS KS AS
);

my @shuffled = $rng->shuffle_array(@deck);
printf "Shuffled deck (top 5): %s\n", join ', ', @shuffled[0..4];
print "\n";

# --- Roll dice ---
printf "Dice rolls: ";
my @rolls = map { $rng->rand_integer(1, 6) } 1 .. 20;
print join(", ", @rolls) . "\n";
print "\n";

# --- Generate normally-distributed numbers (Box-Muller) ---
my @samples;
for (1 .. 5) {
    push(@samples, $rng->next_double());
}
printf("Doubles: %s\n", join ', ', @samples);
