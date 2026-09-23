#!/usr/bin/env perl
# Shepard-Risset Glissando (The Infinite Pitch Ascending Illusion)
# Demonstrates periodic wrapping envelopes in psychoacoustics:
# - Linear pitch ramp envelope that sweeps octaves continuously
# - Bell/raised-cosine spectral envelope weighting partial amplitudes
# - Dynamic glissando acceleration / deceleration curve
#
# Generates a 6-second seamlessly looping infinite glissando into 16-bit 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;
my $dur = 6.0; # seconds for one complete cycle
my $total_samples = int($dur * $sample_rate);

# Number of octave partials spanning human auditory range (approx 20 Hz to 20 kHz)
my $num_octaves = 10;
my $base_freq = 20.0; # lowest partial base (Hz)

# 1. Pitch sweep envelope: rises exactly 1 octave (ratio 1.0 -> 2.0) across the period
# Without hold, wrapping seamlessly creates a continuous endless sweep
my $pitch_ramp_env = env(
    [[0.0, 1.0], [$dur], [1.0]],
    is_hold => 0, # wraps modulo duration!
);
my $pitch_s = $pitch_ramp_env->static;

# 2. Spectral weighting envelope: bell-shaped Gaussian/raised-cosine curve
# Peak amplitude in mid-range (~1 kHz, octave index 5-6), zero at bounds (octave 0 and 10)
my $spectral_bell_env = env(
    [[0.0, 0.05, 0.45, 1.0, 1.0, 0.45, 0.05, 0.0],
     [1.5, 1.5, 1.5, 1.0, 1.5, 1.5, 1.5],
     [2, 2, 1, 1, -1, -2, -2]],
    is_hold => 1,
);
my $bell_s = $spectral_bell_env->static;

print "Synthesizing Shepard-Risset Infinite Pitch Glissando...\n";

my @out_buffer = (0.0) x $total_samples;
my @phases = (0.0) x $num_octaves;

for my $n (0 .. $total_samples - 1) {
    my $t = $n / $sample_rate;
    my $ramp = $pitch_s->($t); # [0.0 .. 1.0]

    my $sample_sum = 0.0;

    for my $k (0 .. $num_octaves - 1) {
        # Current fractional octave position of partial k
        # When ramp moves 0 -> 1, each octave smoothly transitions into the next
        my $octave_pos = $k + $ramp; # range [0 .. 11]

        # Instantaneous frequency: f = f0 * 2^(octave_pos)
        my $freq = $base_freq * (2.0 ** $octave_pos);

        # Spectral envelope weight at this octave position
        # Normalized to bell envelope duration (0 to 10)
        my $amp = 0.0;
        if ($octave_pos >= 0.0 && $octave_pos <= $num_octaves) {
            my $norm_pos = ($octave_pos / $num_octaves) * $spectral_bell_env->duration;
            $amp = $bell_s->($norm_pos);
        }

        # Accumulate phase
        $phases[$k] += 2.0 * $pi * $freq / $sample_rate;
        $phases[$k] -= 2.0 * $pi if $phases[$k] >= 2.0 * $pi;

        # Sine synthesis
        $sample_sum += sin($phases[$k]) * $amp;
    }

    $out_buffer[$n] = $sample_sum * 0.15;
}

# Normalize and write WAV
my $max_val = 0.0001;
for my $s (@out_buffer) {
    my $a = abs($s);
    $max_val = $a if $a > $max_val;
}
my $gain = 0.90 / $max_val;

my $wav_file = 'shepard_glissando.wav';
open my $out, '>:raw', $wav_file or die "Cannot open $wav_file: $!\n";
my $num_channels = 1;
my $bits_per_sample = 16;
my $byte_rate = $sample_rate * $num_channels * ($bits_per_sample / 8);
my $block_align = $num_channels * ($bits_per_sample / 8);
my $data_chunk_size = $total_samples * $block_align;
my $riff_size = 36 + $data_chunk_size;

print $out "RIFF" . pack('V', $riff_size) . "WAVE";
print $out "fmt " . pack('V', 16) . pack('v', 1) . pack('v', $num_channels);
print $out pack('V', $sample_rate) . pack('V', $byte_rate);
print $out pack('v', $block_align) . pack('v', $bits_per_sample);
print $out "data" . pack('V', $data_chunk_size);

for my $s (@out_buffer) {
    my $v = int($s * $gain * 32767.0);
    $v = 32767 if $v > 32767; $v = -32768 if $v < -32768;
    print $out pack('s<', $v);
}
close $out;

printf "Wrote %s (%.2fs endless ascending Shepard tone)\n", $wav_file, $dur;

# ASCII Visualization: Partial Tracks Across One Illusion Cycle
print "\nShepard-Risset Auditory Illusion Partial Trajectories:\n";
print " Octave | Center Freq | Pitch Ramp Progress (0s -> 6s)\n";
print "--------+-------------+-------------------------------------------------\n";
my $cols = 48;
for my $k (reverse 0 .. $num_octaves - 1) {
    my $f_nom = $base_freq * (2.0 ** $k);
    printf "  #%02d   | %6.1f Hz  | ", $k, $f_nom;
    for my $c (0 .. $cols - 1) {
        my $t = ($c / $cols) * $dur;
        my $ramp = $pitch_s->($t);
        my $oct_pos = $k + $ramp;
        my $amp = 0.0;
        if ($oct_pos >= 0.0 && $oct_pos <= $num_octaves) {
            my $norm_pos = ($oct_pos / $num_octaves) * $spectral_bell_env->duration;
            $amp = $bell_s->($norm_pos);
        }
        my $ch = ' ';
        $ch = '.' if $amp > 0.10;
        $ch = '-' if $amp > 0.35;
        $ch = '+' if $amp > 0.65;
        $ch = '#' if $amp > 0.85;
        print $ch;
    }
    print "\n";
}
print "--------+-------------+-------------------------------------------------\n";
