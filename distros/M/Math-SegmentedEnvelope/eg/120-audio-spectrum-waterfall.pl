#!/usr/bin/env perl
# Audio Reactive Spectrum Waterfall (ANSI Color Spectrogram)
# Demonstrates segmented envelopes in audio spectral analysis & visualization:
# - Multi-timbral audio test signal (chirp sweeps, vibrato, and resonant pulses)
# - Short-Time Fourier Transform (STFT) analysis filterbank
# - Dynamic range thresholding & AGC (Automatic Gain Control) envelope
# - ANSI 256-color spectral heat-palette mapping envelope
#
# Computes and displays a real-time color spectrogram waterfall in the terminal.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 16000; # 16 kHz for fast spectral analysis
my $dur = 2.5;           # seconds
my $total_samples = int($dur * $sample_rate);
my $pi = 3.141592653589793;

# 1. Test signal frequency trajectory envelope (complex frequency sweep / chirp)
my $freq_env = spline(
    [0.0, 0.5, 1.0, 1.6, 2.2, 2.5],
    [300.0, 1800.0, 650.0, 2400.0, 450.0, 3200.0],
    resolution => 16, is_hold => 1
);
my $sf = $freq_env->static;

# 2. Vibrato depth envelope
my $vib_depth_env = env(
    [[0.0, 0.05, 0.25, 0.0], [0.8, 1.0, 0.7], [1, 2, -1]],
    is_hold => 1
);
my $svib = $vib_depth_env->static;

# 3. Dynamic AGC & Contrast Threshold envelope
my $contrast_env = env(
    [[0.15, 0.35, 0.20, 0.40], [0.8, 1.0, 0.7], [1, 1, 1]],
    is_hold => 1
);
my $s_cont = $contrast_env->static;

# Synthesize audio signal: swept sine + 2nd harmonic + filtered noise transient bursts
my @audio = (0.0) x $total_samples;
my $phase1 = 0.0;
my $phase2 = 0.0;

for my $n (0 .. $total_samples - 1) {
    my $t = $n / $sample_rate;
    my $base_f = $sf->($t);
    my $v_depth = $svib->($t);

    # Add vibrato LFO (6 Hz)
    my $inst_f = $base_f * (1.0 + $v_depth * sin(2.0 * $pi * 6.0 * $t));

    $audio[$n] = 0.70 * sin($phase1) + 0.30 * sin($phase2);

    $phase1 += 2.0 * $pi * $inst_f / $sample_rate;
    $phase2 += 2.0 * $pi * (2.0 * $inst_f) / $sample_rate;

    $phase1 -= 2.0 * $pi if $phase1 >= 2.0 * $pi;
    $phase2 -= 2.0 * $pi if $phase2 >= 2.0 * $pi;
}

# STFT Spectrogram Analysis
# FFT parameters
my $fft_size = 256;
my $hop_size = 128; # 50% overlap
my $num_bins = int($fft_size / 2); # 128 frequency bins (0 Hz to 8000 Hz)
my $freq_per_bin = ($sample_rate / 2.0) / $num_bins;

# Precompute Hann window
my @window;
for my $i (0 .. $fft_size - 1) {
    push @window, 0.5 * (1.0 - cos(2.0 * $pi * $i / ($fft_size - 1)));
}

# Real-valued Discrete Fourier Transform for 128 bins (optimized for spectrogram display)
sub compute_spectrum_slice {
    my ($signal_ref, $start_idx) = @_;
    my @magnitudes;

    for my $k (0 .. $num_bins - 1) {
        my $real = 0.0;
        my $imag = 0.0;
        my $omega = 2.0 * $pi * $k / $fft_size;

        for my $n (0 .. $fft_size - 1) {
            my $sample = $signal_ref->[$start_idx + $n] * $window[$n];
            $real += $sample * cos($omega * $n);
            $imag -= $sample * sin($omega * $n);
        }
        my $mag = sqrt($real*$real + $imag*$imag) / ($fft_size / 2.0);
        push @magnitudes, $mag;
    }
    return \@magnitudes;
}

print "Computing Audio Reactive Spectrogram Waterfall...\n";

# Analyze time frames
my @frames;
my $pos = 0;
while ($pos + $fft_size <= $total_samples) {
    push @frames, compute_spectrum_slice(\@audio, $pos);
    $pos += $hop_size;
}

my $num_frames = scalar @frames;

# ANSI 256-color heat palette: Black -> Blue -> Cyan -> Green -> Yellow -> Red -> White
# Color codes: 16 (black), 17, 18, 19, 21, 27, 33, 39, 45, 51, 85, 118, 190, 226, 220, 208, 196, 231
my @heat_palette = (
    16, 17, 18, 19, 20, 21, 27, 33, 39, 45,
    51, 85, 118, 154, 190, 226, 220, 214, 208, 202, 196, 231
);
my $num_colors = scalar @heat_palette;

# Display frequency bands (grouped into 28 rows from 0 to 4000 Hz)
my $display_rows = 24;
my $display_cols = 64;

# Downsample frames across display columns
my $step = int($num_frames / $display_cols);
$step = 1 if $step < 1;

print "\nAudio Spectrum Waterfall (Frequency vs Time):\n";
print " Freq (Hz) | Time Progress: 0.0s ----------------------------> 2.5s\n";
print "-----------+----------------------------------------------------------------\n";

for my $r (reverse 0 .. $display_rows - 1) {
    my $bin_start = int(($r / $display_rows) * ($num_bins * 0.55)); # focus on 0..4400 Hz
    my $bin_end   = int((($r + 1) / $display_rows) * ($num_bins * 0.55));
    $bin_end = $bin_start + 1 if $bin_end <= $bin_start;
    my $center_hz = ($bin_start + $bin_end) * 0.5 * $freq_per_bin;

    printf "  %4d Hz  | ", int($center_hz);

    for my $c (0 .. $display_cols - 1) {
        my $f_idx = $c * $step;
        $f_idx = $num_frames - 1 if $f_idx >= $num_frames;

        my $slice = $frames[$f_idx];
        # Max magnitude in band
        my $max_mag = 0.0;
        for my $b ($bin_start .. $bin_end - 1) {
            my $val = $slice->[$b] || 0.0;
            $max_mag = $val if $val > $max_mag;
        }

        # Dynamic range mapping (dB scale) with envelope thresholding
        my $t_sim = ($c / $display_cols) * $dur;
        my $thresh = $s_cont->($t_sim);

        my $norm_intensity;
        if ($max_mag < $thresh * 0.05) {
            $norm_intensity = 0.0;
        } else {
            # Logarithmic perceptual dB scaling
            my $db = 20.0 * log($max_mag + 0.0001) / log(10.0); # range [-80 .. 0]
            $norm_intensity = ($db + 45.0) / 45.0;
            $norm_intensity = 0.0 if $norm_intensity < 0.0;
            $norm_intensity = 1.0 if $norm_intensity > 1.0;
        }

        my $color_idx = int($norm_intensity * ($num_colors - 1));
        my $color_code = $heat_palette[$color_idx];

        my $char = ' ';
        $char = '.' if $norm_intensity > 0.15;
        $char = ':' if $norm_intensity > 0.40;
        $char = '*' if $norm_intensity > 0.65;
        $char = '#' if $norm_intensity > 0.85;

        # ANSI 256 foreground color
        print "\e[38;5;${color_code}m${char}\e[0m";
    }
    print "\n";
}

print "-----------+----------------------------------------------------------------\n";
print "           | Low Intensity: [ . ]  ->  Medium: [ : ]  ->  Peak Energy: [ # ]\n";
