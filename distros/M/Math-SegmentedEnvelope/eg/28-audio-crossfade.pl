#!/usr/bin/env perl
# Audio crossfade: blend between two tones using an envelope
# Outputs raw 16-bit signed PCM
#
# Usage:
#   perl eg/28-audio-crossfade.pl | aplay -f S16_LE -r 44100 -c 1
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr);

my $sr  = 44100;
my $dur = 3.0;
my $pi2 = 2 * 3.14159265358979323846;

# Crossfade envelope: A -> B over the duration
# Uses back_out for a "snap" transition feel
my $xfade = env([[0, 1], [$dur], [1]],
    is_hold => 1,
    morpher_formula => 'smoothstep',
);

# Tone A: low saw at 110 Hz with its own amp envelope
my $amp_a = adsr(0.05, 0.2, 0.8, 0.5, morpher_formula => 'cubic_out');

# Tone B: high sine at 440 Hz with its own amp envelope
my $amp_b = adsr(0.3, 0.1, 0.9, 0.8, morpher_formula => 'smoothstep');

my $xf_s   = $xfade->static;
my $amp_a_s = $amp_a->static;
my $amp_b_s = $amp_b->static;

my $frames = int($dur * $sr);
my $phase_a = 0;
my $phase_b = 0;
my $freq_a = 110;
my $freq_b = 440;

binmode STDOUT;
for my $i (0 .. $frames - 1) {
    my $t = $i / $sr;

    # Crossfade mix: 0 = all A, 1 = all B
    my $mix = $xf_s->($t);

    # Tone A: sawtooth
    my $a = (2.0 * ($phase_a / $pi2) - 1.0) * $amp_a_s->($t);

    # Tone B: sine
    my $b = sin($phase_b) * $amp_b_s->($t);

    # Crossfade
    my $out = $a * (1 - $mix) + $b * $mix;

    # Soft clip
    $out = $out > 1.0 ? 1.0 : ($out < -1.0 ? -1.0 : $out);

    my $sample = int($out * 0.7 * 32767);
    print pack('v', $sample & 0xFFFF);

    $phase_a += $pi2 * $freq_a / $sr;
    $phase_a -= $pi2 if $phase_a >= $pi2;
    $phase_b += $pi2 * $freq_b / $sr;
    $phase_b -= $pi2 if $phase_b >= $pi2;
}

warn sprintf "Crossfade: %.1fs, %d Hz -> %d Hz, %d frames\n",
    $dur, $freq_a, $freq_b, $frames;
