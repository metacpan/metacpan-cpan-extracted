#!/usr/bin/env perl
# Radar Signal Processing: FMCW Chirp Pulse Compression & Matched Filter
# Demonstrates:
#   1. Linear Frequency Modulated (LFM) chirp instantaneous frequency envelope f(t)
#   2. Instantaneous phase integration: phi(t) = 2π ∫ f(t) dt via integrate()
#   3. Amplitude window tapering (Tukey window envelope) to suppress range sidelobes
#   4. Matched filter cross-correlation & ASCII radar target range resolution plot
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Radar Pulse Parameters (scaled for discrete simulation):
# Pulse Width T = 1.0 ms (normalized to 1.0)
# Sweep Bandwidth B = 20.0 Hz (normalized sweep rate)
# Carrier Start Frequency f0 = 5.0 Hz, End Frequency f1 = 25.0 Hz
my $t_pulse = 1.0;
my $f_start = 5.0;
my $f_stop  = 25.0;
my $bw = $f_stop - $f_start; # 20 Hz
my $pcr = $bw * $t_pulse;    # Pulse Compression Ratio = B * T = 20

# 1. Frequency Envelope f(t) from f_start to f_stop
my $freq_env = env([
    [$f_start, $f_stop],
    [$t_pulse],
    [1.0] # linear frequency sweep
], is_hold => 1);

# 2. Phase Envelope phi(t) = 2π * ∫ f(t) dt
# Integrating frequency yields quadratic phase phi(t) = 2π * (f0*t + 0.5*(B/T)*t^2)
my $integral_f = $freq_env->integrate;

# 3. Amplitude Tapering Envelope (Tukey / Raised Cosine window)
# Tapers 10% on each side to eliminate spectral leakage and reduce range sidelobes
my $t_taper = 0.10;
my $window_env = env([
    [0.0, 1.0, 1.0, 0.0],
    [$t_taper, $t_pulse - 2.0 * $t_taper, $t_taper],
    [1.0, 1.0, 1.0]
], is_hold => 1, is_morph => 1, morpher_formula => 'sine');

# Synthesize discrete radar chirp signal at 200 Hz sampling rate
my $sr = 200;
my $n_pts = int($t_pulse * $sr);
my $dt = 1.0 / $sr;
my $pi = 3.141592653589793;

my @chirp_samples;
for my $i (0 .. $n_pts - 1) {
    my $t = $i * $dt;
    my $phi = 2.0 * $pi * $integral_f->at($t);
    my $amp = $window_env->at($t);
    my $s = $amp * cos($phi);
    push @chirp_samples, $s;
}

# 4. Matched Filter (Correlation of received chirp with reference template)
# Simulates receiving an echo from a target delayed at lag tau = 0
my $corr_len = $n_pts;
my @matched_output;

for my $lag (-int($corr_len / 2) .. int($corr_len / 2)) {
    my $sum = 0.0;
    for my $i (0 .. $corr_len - 1) {
        my $j = $i + $lag;
        if ($j >= 0 && $j < $corr_len) {
            $sum += $chirp_samples[$i] * $chirp_samples[$j];
        }
    }
    # Normalize peak correlation to 1.0
    push @matched_output, [$lag * $dt, $sum / ($corr_len * 0.4)];
}

print "=" x 74, "\n";
print "  Radar Signal Processing: FMCW Chirp Pulse & Matched Filter Compression\n";
print "=" x 74, "\n";
printf "Pulse Width: %.1fs | Sweep Bandwidth: %.0f Hz | Compression Ratio (B*T): %.0f\n",
    $t_pulse, $bw, $pcr;
print "-" x 74, "\n";

# Display Uncompressed Transmit Chirp Waveform
print "Transmitted LFM Chirp Waveform (Low frequency -> High frequency):\n";
printf "%-6s | %-8s | %s\n", "Time", "Freq(Hz)", "Oscillating Chirp Waveform [-1.0 to +1.0]";
print "-" x 74, "\n";

my $chart_w = 34;
for (my $i = 0; $i < $n_pts; $i += 7) {
    my $t = $i * $dt;
    my $f = $freq_env->at($t);
    my $s = $chirp_samples[$i];

    my $pos = int((($s - (-1.0)) / 2.0) * ($chart_w - 1));
    $pos = 0 if $pos < 0; $pos = $chart_w - 1 if $pos >= $chart_w;
    my $line = " " x $chart_w;
    substr($line, int($chart_w / 2), 1) = ":";
    substr($line, $pos, 1) = "*";

    printf "%4.2fs | %4.1f Hz | [%s]\n", $t, $f, $line;
}
print "-" x 74, "\n";

# Display Compressed Matched Filter Target Peak
print "Matched Filter Output: Compressed Target Range Resolution Spike:\n";
printf "%-9s | %-12s | %s\n", "Time Lag", "Correlation", "Range Peak (Narrow Sinc Spike)";
print "-" x 74, "\n";

my $lag_idx = 0;
for my $pair (@matched_output) {
    my ($lag_t, $val) = @$pair;
    $lag_idx++;
    next unless $lag_idx % 4 == 0; # clean spacing across the range response

    my $val_clamped = $val;
    $val_clamped = 0.0 if $val_clamped < 0.0;
    $val_clamped = 1.0 if $val_clamped > 1.0;

    my $bar = int($val_clamped * $chart_w);
    $bar = 0 if $bar < 0; $bar = $chart_w if $bar > $chart_w;

    my $marker = "";
    if (abs($lag_t) < 0.01) {
        $marker = "<-- TARGET DETECTED (Range Bin 0)";
    }

    printf "%+5.2fs   | %6.3f     | [%s%s] %s\n",
        $lag_t, $val, "#" x $bar, " " x ($chart_w - $bar), $marker;
}

print "=" x 74, "\n";
print "Summary: Integrating the frequency envelope with SegmentedEnvelope\n";
print "directly computes exact instantaneous phase for radar and sonar matched filtering.\n";
print "=" x 74, "\n";
