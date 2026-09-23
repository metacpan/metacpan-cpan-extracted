#!/usr/bin/env perl
# Asynchronous Granular Synthesis & Cloud Texture Generator
# Demonstrates multi-dimensional segmented envelopes controlling grain streams:
# - Grain emission density envelope (events per second)
# - Grain duration envelope (micro-events 15ms -> macro-textures 120ms)
# - Pitch center & harmonic dispersion envelope
# - Stereo spatial panning trajectory envelope
# - Grain windowing envelope (Hann / cosine shape)
#
# Generates a stereo ambient soundscape and writes a 16-bit 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;
my $dur = 4.0; # seconds
my $total_samples = int($dur * $sample_rate);

my @left_buf  = (0.0) x $total_samples;
my @right_buf = (0.0) x $total_samples;

# 1. Grain density envelope (grains per second: 20 -> 180 -> 40)
my $density_env = env(
    [[20, 180, 220, 40], [1.2, 1.8, 1.0], [2, 1, -2]],
    is_hold => 1,
);
my $density_s = $density_env->static;

# 2. Grain duration envelope (seconds: 0.03s -> 0.12s -> 0.04s)
my $duration_env = env(
    [[0.03, 0.09, 0.12, 0.04], [1.5, 1.5, 1.0], [1, -2, 1]],
    is_hold => 1,
);
my $duration_s = $duration_env->static;

# 3. Central pitch envelope (MIDI pitch: 48 (C3) -> 60 (C4) -> 72 (C5) -> 67 (G4))
my $pitch_env = spline(
    [0.0, 1.0, 2.2, 3.2, 4.0],
    [130.81, 220.00, 329.63, 392.00, 261.63], # C3 -> A3 -> E4 -> G4 -> C4
    resolution => 16,
    is_hold => 1,
);
my $pitch_s = $pitch_env->static;

# 4. Pitch dispersion envelope (semitones spread: tight 0.5 -> wide 12.0 -> tight 1.0)
my $spread_env = env(
    [[0.5, 7.0, 14.0, 2.0], [1.0, 1.8, 1.2], [1, 2, -1]],
    is_hold => 1,
);
my $spread_s = $spread_env->static;

# 5. Stereo pan envelope (-1.0 left to +1.0 right)
my $pan_env = env(
    [[-0.6, 0.8, -0.7, 0.5, 0.0], [0.9, 1.1, 1.0, 1.0], [1, 1, 1, 1]],
    is_hold => 1,
);
my $pan_s = $pan_env->static;

print "Synthesizing Asynchronous Granular Soundscape...\n";

my $current_time = 0.0;
my $grain_count = 0;

while ($current_time < $dur) {
    my $density = $density_s->($current_time);
    $density = 5.0 if $density < 5.0;

    my $grain_dur = $duration_s->($current_time);
    my $base_freq = $pitch_s->($current_time);
    my $spread_semi = $spread_s->($current_time);
    my $pan = $pan_s->($current_time); # [-1 .. +1]

    # Random pitch deviation within spread
    my $semitone_offset = (rand(2.0) - 1.0) * $spread_semi;
    my $freq = $base_freq * (2.0 ** ($semitone_offset / 12.0));

    # Stereo gains (constant power pan)
    my $pan_angle = ($pan + 1.0) * 0.25 * $pi; # [0 .. pi/2]
    my $left_gain  = cos($pan_angle);
    my $right_gain = sin($pan_angle);

    # Generate grain samples
    my $grain_samples = int($grain_dur * $sample_rate);
    $grain_samples = 16 if $grain_samples < 16;

    # Grain window envelope (Hann bell curve via perc or cosine)
    my $win_env = env([[0, 1, 0], [0.5, 0.5], [2, -2]]);
    my $win_s = $win_env->static;

    my $start_sample = int($current_time * $sample_rate);
    my $phase_inc = 2.0 * $pi * $freq / $sample_rate;
    my $phase = rand(2.0 * $pi); # random initial phase

    for my $i (0 .. $grain_samples - 1) {
        my $target = $start_sample + $i;
        last if $target >= $total_samples;

        my $t_rel = $i / $grain_samples;
        my $window = $win_s->($t_rel);
        my $sample = sin($phase) * $window * 0.12;

        $left_buf[$target]  += $sample * $left_gain;
        $right_buf[$target] += $sample * $right_gain;

        $phase += $phase_inc;
        $phase -= 2.0 * $pi if $phase > 2.0 * $pi;
    }

    $grain_count++;
    # Poisson-distributed inter-grain interval
    my $mean_interval = 1.0 / $density;
    my $dt = -log(rand() || 0.0001) * $mean_interval;
    $current_time += $dt;
}

# Normalize stereo buffer
my $peak = 0.0001;
for my $i (0 .. $total_samples - 1) {
    my $al = abs($left_buf[$i]);
    my $ar = abs($right_buf[$i]);
    $peak = $al if $al > $peak;
    $peak = $ar if $ar > $peak;
}
my $gain = 0.88 / $peak;

my $wav_file = 'granular_cloud.wav';
open my $out, '>:raw', $wav_file or die "Cannot open $wav_file: $!\n";

my $num_channels = 2; # Stereo
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

for my $i (0 .. $total_samples - 1) {
    my $l = int($left_buf[$i] * $gain * 32767.0);
    my $r = int($right_buf[$i] * $gain * 32767.0);
    $l =  32767 if $l >  32767; $l = -32768 if $l < -32768;
    $r =  32767 if $r >  32767; $r = -32768 if $r < -32768;
    print $out pack('s<s<', $l, $r);
}
close $out;

printf "Synthesized %d grains -> %s (%.2fs, stereo 44.1kHz)\n",
    $grain_count, $wav_file, $dur;

# ASCII Timeline of Grain Density
print "\nGrain Density Profile (grains/sec):\n";
my $cols = 60;
my @d_samples = map { $density_s->($_ / $cols * $dur) } 0 .. $cols - 1;
my $max_d = 250;
for my $r (reverse 1 .. 6) {
    my $val = ($r / 6) * $max_d;
    printf "%3d |", int($val);
    for my $c (0 .. $cols - 1) {
        print ($d_samples[$c] >= $val ? '*' : ' ');
    }
    print "\n";
}
print "    +" . ("-" x $cols) . "\n";
print "     0.0s" . (" " x ($cols - 8)) . sprintf("%.1fs\n", $dur);
