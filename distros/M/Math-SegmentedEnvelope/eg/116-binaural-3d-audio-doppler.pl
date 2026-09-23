#!/usr/bin/env perl
# Binaural 3D Spatial Audio & Acoustic Doppler Flyby Simulator
# Demonstrates segmented envelopes for 3D trajectory and psychoacoustics:
# - X(t), Y(t), Z(t) spatial position trajectory envelopes
# - Distance inverse-square attenuation envelope
# - Interaural Time Difference (ITD) fractional delay lines
# - Interaural Level Difference (ILD) & head shadow acoustic filtering
# - Dynamic Doppler pitch shift envelope (c / (c - v_radial))
#
# Simulates a sound source flying close past the listener's head into stereo 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;
my $speed_of_sound = 343.0; # m/s
my $head_radius = 0.0875;   # ~17.5 cm head width (ear spacing)

my $dur = 4.0; # seconds
my $total_samples = int($dur * $sample_rate);

# Listener is at origin (0, 0, 0) facing +Y (forward), +X is right ear, -X is left ear.
my $left_ear_x  = -$head_radius;
my $right_ear_x =  $head_radius;

# 1. 3D Flyby Trajectory Envelopes
# Source swoops in from far left-behind (-18m, -12m), passes close right (+1.2m, +0.5m), zooms away (+20m, +15m)
my $traj_x = spline(
    [0.0, 1.2, 2.0, 2.8, 4.0],
    [-20.0, -8.0, 1.2, 9.0, 22.0],
    resolution => 16, is_hold => 1
);
my $traj_y = spline(
    [0.0, 1.2, 2.0, 2.8, 4.0],
    [-15.0, -4.0, 0.4, 5.0, 16.0],
    resolution => 16, is_hold => 1
);
my $traj_z = spline(
    [0.0, 1.5, 2.0, 3.0, 4.0],
    [3.0, 1.5, 0.2, 1.8, 4.0], # vertical height
    resolution => 16, is_hold => 1
);

my $sx = $traj_x->static;
my $sy = $traj_y->static;
my $sz = $traj_z->static;

# Source base frequency (propeller / turbine drone tone at 280 Hz + harmonics)
my $base_f0 = 280.0;

print "Synthesizing Binaural 3D Audio with Doppler Flyby...\n";

my @left_out  = (0.0) x $total_samples;
my @right_out = (0.0) x $total_samples;

# Maximum delay line buffer for distance propagation (max distance ~30m -> ~4000 samples)
my $max_delay_samples = int((35.0 / $speed_of_sound) * $sample_rate) + 64;
my @delay_line = (0.0) x $max_delay_samples;
my $write_ptr = 0;

my $source_phase = 0.0;

# Single-pole lowpass filter states for head shadow ILD
my $l_lp_state = 0.0;
my $r_lp_state = 0.0;

for my $n (0 .. $total_samples - 1) {
    my $t = $n / $sample_rate;

    # Current 3D position
    my $px = $sx->($t);
    my $py = $sy->($t);
    my $pz = $sz->($t);

    # Distance to left and right ears
    my $dist_l = sqrt(($px - $left_ear_x)**2  + $py**2 + $pz**2);
    my $dist_r = sqrt(($px - $right_ear_x)**2 + $py**2 + $pz**2);
    my $dist_center = sqrt($px**2 + $py**2 + $pz**2);

    # Generate source audio (engine hum: fundamental + 2nd & 3rd harmonics)
    my $src_sample = 0.60 * sin($source_phase)
                   + 0.25 * sin(2.0 * $source_phase)
                   + 0.15 * sin(3.0 * $source_phase);

    $source_phase += 2.0 * $pi * $base_f0 / $sample_rate;
    $source_phase -= 2.0 * $pi if $source_phase >= 2.0 * $pi;

    # Store in history delay line
    $delay_line[$write_ptr] = $src_sample;

    # Propagation delays in samples (ITD)
    my $delay_l = ($dist_l / $speed_of_sound) * $sample_rate;
    my $delay_r = ($dist_r / $speed_of_sound) * $sample_rate;

    # Hermite/linear fractional delay line interpolation
    my $sample_l = read_fractional_delay(\@delay_line, $write_ptr, $delay_l, $max_delay_samples);
    my $sample_r = read_fractional_delay(\@delay_line, $write_ptr, $delay_r, $max_delay_samples);

    # Inverse-distance amplitude attenuation (1 / (1 + d))
    my $gain_l = 1.0 / (1.0 + 0.6 * $dist_l);
    my $gain_r = 1.0 / (1.0 + 0.6 * $dist_r);

    # Head shadow ILD effect:
    # Sound from right ear shadows the left ear (muffles highs on left)
    # Cosine of azimuth angle with respect to each ear
    my $azim_l = ($px - $left_ear_x) / ($dist_l + 0.001);   # positive = sound is to the right
    my $azim_r = ($px - $right_ear_x) / ($dist_r + 0.001);

    # Cutoff frequencies dynamically driven by head shadow
    my $alpha_l = 0.5 + 0.45 * (1.0 - $azim_l * 0.5); # lower when source is on opposite side
    my $alpha_r = 0.5 + 0.45 * (1.0 + $azim_r * 0.5);
    $alpha_l = 0.15 if $alpha_l < 0.15; $alpha_l = 0.95 if $alpha_l > 0.95;
    $alpha_r = 0.15 if $alpha_r < 0.15; $alpha_r = 0.95 if $alpha_r > 0.95;

    $l_lp_state += $alpha_l * ($sample_l * $gain_l - $l_lp_state);
    $r_lp_state += $alpha_r * ($sample_r * $gain_r - $r_lp_state);

    $left_out[$n]  = $l_lp_state;
    $right_out[$n] = $r_lp_state;

    $write_ptr = ($write_ptr + 1) % $max_delay_samples;
}

sub read_fractional_delay {
    my ($buf, $head, $delay, $size) = @_;
    my $read_pos = $head - $delay;
    while ($read_pos < 0) { $read_pos += $size; }
    my $i0 = int($read_pos);
    my $frac = $read_pos - $i0;
    my $i1 = ($i0 + 1) % $size;
    return $buf->[$i0] * (1.0 - $frac) + $buf->[$i1] * $frac;
}

# Normalize stereo file
my $max_amp = 0.0001;
for my $i (0 .. $total_samples - 1) {
    my $al = abs($left_out[$i]); my $ar = abs($right_out[$i]);
    $max_amp = $al if $al > $max_amp;
    $max_amp = $ar if $ar > $max_amp;
}
my $gain = 0.88 / $max_amp;

my $wav_file = 'binaural_flight.wav';
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
    my $l = int($left_out[$i] * $gain * 32767.0);
    my $r = int($right_out[$i] * $gain * 32767.0);
    $l = 32767 if $l > 32767; $l = -32768 if $l < -32768;
    $r = 32767 if $r > 32767; $r = -32768 if $r < -32768;
    print $out pack('s<s<', $l, $r);
}
close $out;

printf "Wrote %s (%.2fs 3D binaural stereo audio)\n", $wav_file, $dur;

# ASCII 2D Top-Down Flight Path Projection (X vs Y)
print "\n2D Top-Down Spatial Flight Trajectory (X = Left/Right, Y = Behind/Front):\n";
my $gw = 55;
my $gh = 15;
my @grid;
for my $y (0 .. $gh - 1) { $grid[$y] = [(' ') x $gw]; }

# Mark listener at center
my $lx = int($gw / 2);
my $ly = int($gh / 2);
$grid[$ly][$lx] = '@'; # Listener head
$grid[$ly][$lx - 1] = '(';
$grid[$ly][$lx + 1] = ')';

my $steps = 80;
for my $s (0 .. $steps) {
    my $t = ($s / $steps) * $dur;
    my $px = $sx->($t);
    my $py = $sy->($t);

    # Map [-25 .. +25] -> [0 .. $gw-1], [-18 .. +18] -> [0 .. $gh-1]
    my $gx = int(($px + 25.0) / 50.0 * ($gw - 1) + 0.5);
    my $gy = int(($py + 18.0) / 36.0 * ($gh - 1) + 0.5);

    if ($gx >= 0 && $gx < $gw && $gy >= 0 && $gy < $gh) {
        my $char = ($s == 0) ? 'S' : ($s == $steps ? 'E' : '.');
        $grid[$gy][$gx] = $char unless $grid[$gy][$gx] =~ /[()@]/;
    }
}

for my $y (reverse 0 .. $gh - 1) {
    printf "%+3dm |", int(($y / ($gh - 1) * 36.0) - 18.0);
    print join('', @{$grid[$y]}), "|\n";
}
print "      +" . ("-" x $gw) . "+\n";
print "       -25m                     0m(Listener)             +25m\n";
