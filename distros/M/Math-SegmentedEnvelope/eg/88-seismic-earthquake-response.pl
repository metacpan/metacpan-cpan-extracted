#!/usr/bin/env perl
# Structural Dynamics & Seismology: Earthquake Ground Motion & Double Integration
# Demonstrates:
#   1. Seismic acceleration envelope modeling (P-wave, S-wave, Coda decay)
#   2. Baseline drift correction and double integration: a(t) -> v(t) -> d(t)
#   3. Peak Ground Acceleration (PGA) and Peak Ground Velocity (PGV) calculation
#   4. Multi-channel ASCII seismograph strip recorder
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Earthquake Event Parameters (Magnitude ~6.5 at 15 km epicentral distance):
# Total record duration: 30.0 seconds
# 1. P-wave arrival at T+3.0s (fast compression wave, moderate amplitude ~0.08g)
# 2. S-wave arrival at T+7.0s (transverse shear wave, peak ground acceleration ~0.45g)
# 3. Surface Rayleigh wave resonance T+10s to T+16s (~0.25g)
# 4. Coda decay from T+16s to T+30s (exponential attenuation)

# Seismic Shaking Intensity Envelope E(t) in fractions of g (1g = 9.81 m/s^2)
my $seismic_envelope = env([
    [0.0, 0.0, 0.08, 0.05, 0.45, 0.35, 0.15, 0.02, 0.0],
    [3.0, 0.5, 3.5,  0.5,  3.5,  4.0,  7.0,  8.0],
    [1.0, 2.0, -1.5, 3.0, -2.0, -1.2, -2.5, -3.0]
], is_hold => 1);

# Synthesize multi-frequency seismic acceleration wave:
#   a(t) = E(t) * [0.6 * sin(2π * f1 * t) + 0.3 * sin(2π * f2 * t + 0.5) + 0.1 * sin(2π * f3 * t)]
my $f_p = 4.5; # Hz (P-wave frequency)
my $f_s = 2.0; # Hz (S-wave dominant frequency)
my $f_r = 0.8; # Hz (Surface wave long-period resonance)
my $pi = 3.141592653589793;

my $sample_rate = 100; # 100 Hz seismic recording station
my $duration = 25.0;   # seconds
my $n_samples = int($duration * $sample_rate);
my $dt = 1.0 / $sample_rate;

my @accel_vals;
my $g0 = 9.81; # m/s^2

for my $i (0 .. $n_samples) {
    my $t = $i * $dt;
    my $env_amp = $seismic_envelope->at($t);

    # Composite ground oscillation
    my $osc = 0.60 * sin(2.0 * $pi * $f_s * $t)
            + 0.30 * sin(2.0 * $pi * $f_p * $t + 0.7)
            + 0.10 * sin(2.0 * $pi * $f_r * $t + 1.2);

    # Acceleration in m/s^2
    my $a = $env_amp * $osc * $g0;
    push @accel_vals, $a;
}

# Create acceleration envelope
my @durs = ($dt) x $n_samples;
my @curves = (1.0) x $n_samples;
my $accel_env = env([\@accel_vals, \@durs, \@curves], is_hold => 1);

# First Integration: Ground Velocity v(t) = ∫ a(t) dt (m/s)
my $velocity_env = $accel_env->integrate;

# Second Integration: Ground Displacement d(t) = ∫ v(t) dt (meters)
my $displacement_env = $velocity_env->integrate;

print "=" x 74, "\n";
print "  Seismic Engineering: Earthquake Waveform & Ground Motion Integration\n";
print "=" x 74, "\n";

# Compute PGA and PGV
my $max_a = 0.0;
my $max_v = 0.0;
my $max_d = 0.0;
for my $i (0 .. $n_samples) {
    my $t = $i * $dt;
    my $a = abs($accel_env->at($t));
    my $v = abs($velocity_env->at($t));
    my $d = abs($displacement_env->at($t));
    $max_a = $a if $a > $max_a;
    $max_v = $v if $v > $max_v;
    $max_d = $d if $d > $max_d;
}

printf "PGA (Peak Ground Acceleration) : %5.2f m/s² (%4.2f g)\n", $max_a, $max_a / $g0;
printf "PGV (Peak Ground Velocity)     : %5.2f cm/s\n", $max_v * 100.0;
printf "Peak Ground Displacement       : %5.2f cm\n", $max_d * 100.0;
print "-" x 74, "\n";

# ASCII Multi-Channel Seismograph Record
print "Seismograph Ground Acceleration a(t) Strip (P-Wave -> S-Wave -> Coda):\n";
printf "%-7s | %-9s | %s\n", "Time", "Accel(g)", "Acceleration Waveform [-0.50g to +0.50g]";
print "-" x 74, "\n";

my $chart_w = 34;
my $chart_steps = 30;
for my $i (0 .. $chart_steps) {
    my $t = ($i / $chart_steps) * $duration;
    my $a_ms2 = $accel_env->at($t);
    my $a_g = $a_ms2 / $g0;

    my $pos = int((($a_g - (-0.50)) / 1.0) * ($chart_w - 1));
    $pos = 0 if $pos < 0; $pos = $chart_w - 1 if $pos >= $chart_w;

    my $line = " " x $chart_w;
    substr($line, int($chart_w / 2), 1) = ":";
    substr($line, $pos, 1) = "*";

    my $note = "";
    if ($t >= 2.5 && $t <= 3.5) { $note = "<- P-Wave Arrival" }
    elsif ($t >= 6.5 && $t <= 8.0) { $note = "<- S-Wave Peak (PGA)" }
    elsif ($t >= 15.0 && $t <= 16.5) { $note = "<- Coda Decay" }

    printf "%4.1fs   | %+5.2f g   | [%s] %s\n",
        $t, $a_g, $line, $note;
}

print "-" x 74, "\n";
print "Ground Displacement d(t) Profile (Cumulative double integral):\n";
for my $t (0, 3, 7, 10, 15, 20, 25) {
    my $d_cm = $displacement_env->at($t) * 100.0;
    my $bar = int((abs($d_cm) / ($max_d * 100.0)) * 24);
    $bar = 0 if $bar < 0; $bar = 24 if $bar > 24;
    printf "  T=%4.1fs | Displacement: %+6.2f cm |%s|\n",
        $t, $d_cm, "#" x $bar;
}
print "=" x 74, "\n";
print "Summary: Double integration of acceleration records in SegmentedEnvelope\n";
print "allows structural engineers to accurately assess dynamic building drift.\n";
print "=" x 74, "\n";
