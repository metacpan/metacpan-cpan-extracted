#!/usr/bin/env perl
# Standard envelope constructors for audio synthesis
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr asr perc concat);

# ADSR - classic synth envelope
#   attack=10ms, decay=100ms, sustain=70% of peak, release=300ms
my $note = adsr(0.01, 0.1, 0.7, 0.3);
printf "ADSR: %d segments, %.2fs\n", $note->segments, $note->duration;
printf "  peak:    %.2f (at t=%.2f)\n", $note->at(0.01), 0.01;
printf "  sustain: %.2f (at t=%.2f)\n", $note->at(0.3), 0.3;

# Percussive - fast attack, exponential decay
my $kick = perc(0.001, 0.2);
printf "\nPerc: %d segments, %.3fs\n", $kick->segments, $kick->duration;

# ASR - attack, sustain hold, release (no decay phase)
my $pad = asr(0.5, 2.0, 1.0, peak => 0.8);
printf "\nASR: %d segments, %.2fs, peak=%.2f\n",
    $pad->segments, $pad->duration, $pad->at(0.5);

# Chain envelopes together
my $pattern = concat($kick, $kick, $kick, $kick);
printf "\nPattern: %d segments, %.3fs (4x kick)\n",
    $pattern->segments, $pattern->duration;

# ADSR with custom curves and morpher
my $rich = adsr(0.05, 0.1, 0.6, 0.5,
    peak => 1.0,
    attack_curve => 3,       # strong ease-in
    decay_curve => -4,       # steep ease-out
    release_curve => -2,
    morpher_formula => 'smootherstep',
);
printf "\nRich ADSR: morpher=%s, jit=%s\n",
    $rich->morpher_formula // 'default', $rich->morpher_jit_backend;
