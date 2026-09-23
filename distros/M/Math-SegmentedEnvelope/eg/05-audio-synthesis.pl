#!/usr/bin/env perl
# Audio synthesis: amplitude envelope applied to a sine oscillator
# Outputs raw 16-bit signed PCM to stdout (pipe to aplay/sox/ffmpeg)
#
# Usage:
#   perl eg/05-audio-synthesis.pl | aplay -f S16_LE -r 44100 -c 1
#   perl eg/05-audio-synthesis.pl > note.raw
#   sox -t raw -r 44100 -b 16 -e signed -c 1 note.raw note.wav
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc);

my $sr   = 44100;  # sample rate
my $freq = 440;    # A4

# Amplitude envelope
my $amp = adsr(0.01, 0.08, 0.6, 0.4,
    peak => 0.8,
    morpher_formula => 'smoothstep',
);

# Pitch envelope: slight pitch bend down during attack
my $pitch = Math::SegmentedEnvelope->new(
    [[1.02, 1.0, 1.0], [0.05, $amp->duration - 0.05], [2, 1]],
    is_hold => 1,
);

my $dur    = $amp->duration;
my $frames = int($dur * $sr);

# Use static evaluators for tight loop
my $amp_s   = $amp->static;
my $pitch_s = $pitch->static;

binmode STDOUT;
my $phase = 0;
my $pi2   = 2 * 3.14159265358979323846;

for my $i (0 .. $frames - 1) {
    my $t   = $i / $sr;
    my $a   = $amp_s->($t);
    my $f   = $freq * $pitch_s->($t);
    my $val = sin($phase) * $a;

    # 16-bit signed PCM
    my $sample = int($val * 32767);
    $sample =  32767 if $sample >  32767;
    $sample = -32768 if $sample < -32768;
    print pack('v', $sample & 0xFFFF);

    $phase += $pi2 * $f / $sr;
    $phase -= $pi2 if $phase >= $pi2;
}

warn sprintf "Wrote %d frames (%.2fs) at %d Hz\n", $frames, $dur, $sr;
