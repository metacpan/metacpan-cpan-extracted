#!/usr/bin/env perl
# IoT & Drone Telemetry Filtering, Smoothing & Rate-of-Climb Estimation
# Demonstrates:
#   1. from_samples() to ingest discrete noisy barometric/GPS altimeter data
#   2. smooth() multi-pass moving average to suppress sensor jitter
#   3. resample() to reconstruct continuous smooth flight trajectory
#   4. derivative() to estimate vertical climb rate (m/s) from altitude readings
#   5. quantize() to model fixed-resolution digital barometric sensor ADC bins
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# Synthetic true flight profile (meters):
# Start at ground (0m), climb to cruise altitude (120m), level off, then descend to 40m
my $num_samples = 41;
my $flight_time = 40.0; # 40 seconds flight

# Seed PRNG for reproducible sensor noise
srand(42);

# Generate noisy sensor readings: true altitude + barometric noise
my @noisy_samples;
for my $i (0 .. $num_samples - 1) {
    my $t = ($i / ($num_samples - 1)) * $flight_time;

    # Ground truth profile
    my $true_alt;
    if ($t < 15.0) {
        # Climb phase
        my $p = $t / 15.0;
        $true_alt = 120.0 * ($p * $p * (3.0 - 2.0 * $p)); # smoothstep climb
    } elsif ($t < 28.0) {
        # Cruise altitude
        $true_alt = 120.0;
    } else {
        # Descent phase
        my $p = ($t - 28.0) / 12.0;
        $true_alt = 120.0 - 80.0 * ($p * $p * (3.0 - 2.0 * $p));
    }

    # Add realistic sensor noise (+/- 6 meters jitter)
    my $noise = (rand() - 0.5) * 12.0;
    push @noisy_samples, sprintf("%.2f", $true_alt + $noise) + 0;
}

# 1. Ingest noisy discrete telemetry via from_samples()
my $raw_env = from_samples(\@noisy_samples, $flight_time);

# 2. Smooth signal using 3-pass moving average to suppress sensor jitter
my $smoothed_env = $raw_env->smooth(3);

# 3. Resample to continuous 64 segments
my $clean_trajectory = $smoothed_env->resample(64);

# 4. Compute instantaneous vertical climb rate (m/s) via derivative()
my $raw_climb_rate   = $raw_env->derivative;
my $clean_climb_rate = $clean_trajectory->derivative;

# 5. Model a 16-level quantized digital telemetry stream
my $quantized_env = $clean_trajectory->quantize(16);

print "=" x 74, "\n";
print "  Barometric Sensor Telemetry: Noise Filtering & Rate-of-Climb\n";
print "=" x 74, "\n";
printf "Flight Time: %.1fs | Telemetry Samples: %d | Smoothing: 3 passes\n",
    $flight_time, scalar(@noisy_samples);
print "-" x 74, "\n";

# Side-by-side ASCII comparison
my $plot_w = 26;
print "Telemetry Processing Comparison:\n";
printf "%-5s | %-10s | %-10s | %-10s | %s\n",
    "Time", "Raw Alt", "Smooth Alt", "Climb Rate",
    "Raw [.] vs Filtered [*] Elevation";
print "-" x 74, "\n";

my $steps = 20;
for my $i (0 .. $steps) {
    my $t = ($i / $steps) * $flight_time;

    my $raw_alt   = $raw_env->at($t);
    my $clean_alt = $clean_trajectory->at($t);
    my $vz        = $clean_climb_rate->at($t);

    my $pos_raw   = int(($raw_alt / 130.0) * ($plot_w - 1));
    my $pos_clean = int(($clean_alt / 130.0) * ($plot_w - 1));
    $pos_raw = 0 if $pos_raw < 0; $pos_raw = $plot_w - 1 if $pos_raw >= $plot_w;
    $pos_clean = 0 if $pos_clean < 0; $pos_clean = $plot_w - 1 if $pos_clean >= $plot_w;

    my $trace = " " x $plot_w;
    substr($trace, $pos_raw, 1) = '.';
    substr($trace, $pos_clean, 1) = '*';

    printf "%4.1fs | %6.1f m   | %6.1f m   | %+5.1f m/s  | |%s|\n",
        $t, $raw_alt, $clean_alt, $vz, $trace;
}

print "-" x 74, "\n";
print "Signal Quality & Filtering Statistics:\n";
# Compute Root Mean Square (RMS) jitter between raw and smoothed
my $sum_sq_err = 0;
my $n_eval = 100;
for my $i (0 .. $n_eval) {
    my $t = ($i / $n_eval) * $flight_time;
    my $diff = $raw_env->at($t) - $clean_trajectory->at($t);
    $sum_sq_err += $diff * $diff;
}
my $rmse = sqrt($sum_sq_err / ($n_eval + 1));

printf "  Sensor Noise Jitter RMSE      : %.2f meters\n", $rmse;
printf "  Peak Climb Rate               : %+5.2f m/s\n", $clean_climb_rate->max_value;
printf "  Peak Descent Rate             : %+5.2f m/s\n", $clean_climb_rate->min_value;
printf "  Raw Derivative Noise Jitter   : Max %+5.2f m/s vs Filtered %+5.2f m/s\n",
    $raw_climb_rate->max_value, $clean_climb_rate->max_value;
print "=" x 74, "\n";
