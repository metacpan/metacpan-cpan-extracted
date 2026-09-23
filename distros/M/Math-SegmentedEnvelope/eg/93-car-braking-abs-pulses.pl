#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# ============================================================================
# Automotive Anti-lock Braking System (ABS): Wheel Slip & Distance Optimization
# ============================================================================
# In automotive chassis dynamics, braking performance depends on the tire-road
# friction coefficient mu(s), which varies nonlinearly with wheel slip ratio:
#   s = (v_vehicle - omega * R_wheel) / v_vehicle   in [0, 1.0]
#
# - At s = 0 (free rolling), friction is zero.
# - At s = 0.15 .. 0.20, friction reaches peak grip (mu_peak ~ 0.85 on dry asphalt).
# - At s = 1.0 (locked wheel skid), friction drops to kinetic sliding (mu_slide ~ 0.60),
#   causing 30% longer stopping distances, flat-spotted tires, and complete loss
#   of steering control.
#
# An ABS controller modulates hydraulic brake caliper pressure at 10-15 Hz
# (Apply -> Hold -> Release) to keep tire slip oscillating strictly around the
# peak grip zone (s ~ 0.15 - 0.20).
#
# This example demonstrates:
#   1. Modeling the nonlinear tire-road mu(s) friction curve using SegmentedEnvelope.
#   2. Simulating emergency braking from 100 km/h (27.78 m/s):
#      - Locked Wheel (No ABS): s = 1.0, mu = 0.60
#      - ABS Controlled: High-frequency pressure modulation maintaining mu ~ 0.82
#   3. Integrating deceleration via integrate() to compute velocity decay v(t)
#      and total stopping distance x(t) = \int v(t) dt.
#   4. Displaying an ASCII deceleration profile and stopping distance comparison.
# ============================================================================

my $g = 9.80665;          # Gravity (m/s^2)
my $v0_kmh = 100.0;       # Initial speed: 100 km/h
my $v0 = $v0_kmh / 3.6;   # Initial speed: 27.78 m/s

# 1. Pacejka-style Tire Friction Curve mu(s) vs Wheel Slip s in [0, 1]
# Peak grip mu = 0.85 at s = 0.18; drops to mu = 0.60 at s = 1.0
my $tire_mu_env = Math::SegmentedEnvelope->new(
    [[0.0, 0.85, 0.60], [0.18, 0.82], [-2, 2]],
    is_hold => 1,
);

# 2. Simulate Emergency Stop Scenarios
my $dt = 0.01; # 10 ms time step
my $max_time = 6.0; # seconds

# A) Locked Wheel (No ABS): s quickly locks to 1.0 (after 0.15s driver reaction)
my @t_no_abs;
my @a_no_abs;
my $t_lock = 0.15;

for (my $t = 0; $t <= $max_time; $t += $dt) {
    push @t_no_abs, $t;
    my $slip = ($t < $t_lock) ? ($t / $t_lock) : 1.0;
    my $mu = $tire_mu_env->at($slip);
    push @a_no_abs, $mu * $g;
}

my $decel_no_abs = from_samples(\@a_no_abs, $max_time, is_hold => 1);

# B) ABS Controlled: ABS modulates pressure at 12 Hz, holding slip in [0.13, 0.22]
my @t_abs;
my @a_abs;
my $abs_freq = 12.0; # 12 Hz modulation cycle
my $two_pi = 8.0 * atan2(1, 1);

for (my $t = 0; $t <= $max_time; $t += $dt) {
    push @t_abs, $t;
    my $slip;
    if ($t < $t_lock) {
        $slip = ($t / $t_lock) * 0.18;
    } else {
        # Modulate slip sinusoidally around peak grip 0.175 +/- 0.035
        my $cycle_phase = ($t - $t_lock) * $abs_freq * $two_pi;
        $slip = 0.175 + 0.035 * sin($cycle_phase);
    }
    my $mu = $tire_mu_env->at($slip);
    push @a_abs, $mu * $g;
}

my $decel_abs = from_samples(\@a_abs, $max_time, is_hold => 1);

# 3. Integrate Deceleration to Obtain Velocity v(t) = v0 - \int a dt
# We integrate deceleration to get delta_v(t)
my $dv_no_abs = $decel_no_abs->integrate;
my $dv_abs    = $decel_abs->integrate;

# Compute velocity and distance stopping points
my $stop_t_no_abs = $max_time;
my $stop_t_abs    = $max_time;

my @v_no_abs_samples;
my @v_abs_samples;

for (my $t = 0; $t <= $max_time; $t += $dt) {
    my $v1 = $v0 - $dv_no_abs->at($t);
    my $v2 = $v0 - $dv_abs->at($t);

    if ($v1 <= 0 && $stop_t_no_abs == $max_time) {
        $stop_t_no_abs = $t;
    }
    if ($v2 <= 0 && $stop_t_abs == $max_time) {
        $stop_t_abs = $t;
    }

    $v1 = 0 if $v1 < 0;
    $v2 = 0 if $v2 < 0;

    push @v_no_abs_samples, $v1;
    push @v_abs_samples,    $v2;
}

# Envelopes of forward velocity v(t)
my $vel_no_abs = from_samples(\@v_no_abs_samples, $max_time, is_hold => 1);
my $vel_abs    = from_samples(\@v_abs_samples,    $max_time, is_hold => 1);

# Integrate velocity v(t) to get total stopping distance x(t) = \int v dt
my $dist_no_abs_env = $vel_no_abs->integrate;
my $dist_abs_env    = $vel_abs->integrate;

my $dist_no_abs = $dist_no_abs_env->at($stop_t_no_abs);
my $dist_abs    = $dist_abs_env->at($stop_t_abs);
my $dist_saved  = $dist_no_abs - $dist_abs;
my $pct_saved   = ($dist_saved / $dist_no_abs) * 100;

print "=" x 76, "\n";
print "  Automotive ABS Dynamics: Tire Slip Control & Stopping Distance\n";
print "=" x 76, "\n";
printf "Initial Vehicle Speed: %.1f km/h (%.2f m/s) | Road Surface: Dry Asphalt\n",
    $v0_kmh, $v0;
printf "Peak Friction Coeff mu_peak: %.2f (s=18%%) | Sliding Coeff mu_slide: %.2f (s=100%%)\n",
    $tire_mu_env->at(0.18), $tire_mu_env->at(1.0);
print "-" x 76, "\n";
printf "Locked Wheel (No ABS) : Stop Time = %4.2fs | Stopping Distance = %5.1f m\n",
    $stop_t_no_abs, $dist_no_abs;
printf "ABS Modulated (12 Hz) : Stop Time = %4.2fs | Stopping Distance = %5.1f m\n",
    $stop_t_abs, $dist_abs;
printf "ABS Safety Advantage  : Distance Saved = %5.1f m (%.1f%% reduction!)\n",
    $dist_saved, $pct_saved;
print "-" x 76, "\n";

# 4. Deceleration & Velocity Transient Table
print "\nTransient Deceleration & Speed Decay Comparison:\n";
print "Time   | No-ABS Acc | ABS Acc    | No-ABS Speed | ABS Speed  | Speed Decay Bar\n";
print "       |   (m/s^2)  |  (m/s^2)   |    (km/h)    |   (km/h)   | [0 to 100 km/h]\n";
print "-" x 76, "\n";

my $bar_width = 25;
for (my $t = 0.0; $t <= 5.0; $t += 0.25) {
    my $a1 = ($t <= $stop_t_no_abs) ? $decel_no_abs->at($t) : 0.0;
    my $a2 = ($t <= $stop_t_abs)    ? $decel_abs->at($t)    : 0.0;

    my $spd1 = ($vel_no_abs->at($t) * 3.6);
    my $spd2 = ($vel_abs->at($t) * 3.6);

    my @row = (' ') x $bar_width;
    my $p1 = int(($spd1 / $v0_kmh) * ($bar_width - 1));
    my $p2 = int(($spd2 / $v0_kmh) * ($bar_width - 1));
    $p1 = 0 if $p1 < 0; $p1 = $bar_width - 1 if $p1 >= $bar_width;
    $p2 = 0 if $p2 < 0; $p2 = $bar_width - 1 if $p2 >= $bar_width;

    $row[$p1] = 'N'; # No-ABS
    $row[$p2] = 'A'; # ABS

    my $graph = join('', @row);
    printf "%4.2fs  | %6.2f m/s² | %6.2f m/s² | %6.1f km/h  | %6.1f km/h | [%s]\n",
        $t, $a1, $a2, $spd1, $spd2, $graph;
}
print "=" x 76, "\n";

# 5. ABS High-Speed Caliper Pressure Modulation Zoom (t = 0.50s to 0.70s)
print "\nABS 12 Hz Caliper Hydraulic Pressure Modulation Trace (Zoom: 0.50s - 0.70s):\n";
print "Cycle: [Apply -> Hold -> Dump -> Hold -> Apply]\n";
for (my $t = 0.50; $t <= 0.70; $t += 0.015) {
    my $a = $decel_abs->at($t);
    my $p_bar = int(($a - 5.5) / (8.5 - 5.5) * 30);
    $p_bar = 0 if $p_bar < 0;
    $p_bar = 30 if $p_bar > 30;
    my $bar = ('=' x $p_bar) . '>';
    printf "t=%5.3fs | a=%5.2f m/s² | %-32s |\n", $t, $a, $bar;
}
print "=" x 76, "\n";
print "Summary: integrate() double-integrates tire deceleration a(t) to speed v(t)\n";
print "and position x(t), proving the vital stopping distance savings of ABS.\n";
print "=" x 76, "\n";
