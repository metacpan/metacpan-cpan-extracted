#!/usr/bin/env perl
# Polysynth: 4-voice chord with shared envelopes, per-voice detune
# Outputs raw 16-bit signed PCM
#
# Usage:
#   perl eg/33-polysynth.pl | aplay -f S16_LE -r 44100 -c 1
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr env);

my $sr  = 44100;
my $pi2 = 2 * 3.14159265358979323846;

# Shared envelopes
my $amp  = adsr(0.02, 0.15, 0.6, 0.8, peak => 0.25,
    morpher_formula => 'smoothstep');
my $filt = adsr(0.005, 0.3, 0.3, 0.5, peak => 1.0,
    morpher_formula => 'cubic_out');

# Compile once, use for all voices
my $amp_s  = $amp->static;
my $filt_s = $filt->static;

# Chord: C major 7 (C4, E4, G4, B4) with per-voice detune
my @voices = (
    { freq => 261.63, detune =>  0.998, phase => 0 },
    { freq => 329.63, detune =>  1.003, phase => 0 },
    { freq => 392.00, detune =>  0.997, phase => 0 },
    { freq => 493.88, detune =>  1.002, phase => 0 },
);

my $dur    = $amp->duration;
my $frames = int($dur * $sr);

# Per-voice filter state
my @lp = (0) x @voices;

binmode STDOUT;
for my $i (0 .. $frames - 1) {
    my $t = $i / $sr;
    my $a = $amp_s->($t);
    my $f = $filt_s->($t);
    my $coeff = 0.02 + $f * 0.95;

    my $mix = 0;
    for my $vi (0 .. $#voices) {
        my $v = $voices[$vi];
        # Sawtooth with detune
        my $saw = 2.0 * ($v->{phase} / $pi2) - 1.0;
        # One-pole lowpass
        $lp[$vi] += $coeff * ($saw - $lp[$vi]);
        $mix += $lp[$vi] * $a;
        # Advance phase
        $v->{phase} += $pi2 * $v->{freq} * $v->{detune} / $sr;
        $v->{phase} -= $pi2 if $v->{phase} >= $pi2;
    }

    # Soft clip
    $mix = $mix > 1 ? 1 : ($mix < -1 ? -1 : $mix);
    my $s = int($mix * 32767);
    print pack('v', $s & 0xFFFF);
}

warn sprintf "Polysynth: %d voices, %.2fs, %d frames\n",
    scalar @voices, $dur, $frames;
