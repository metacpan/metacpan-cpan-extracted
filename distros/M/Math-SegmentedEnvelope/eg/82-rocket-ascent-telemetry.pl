#!/usr/bin/env perl
# Orbital Rocket Ascent & Staging Trajectory Simulation
# Demonstrates:
#   1. Modeling multi-stage variable rocket thrust T(t) and mass depletion m(t)
#   2. Successive integration: Acceleration a(t) -> Velocity v(t) -> Altitude h(t)
#   3. Dynamic pressure calculation (Max-Q aerodynamic stress detection)
#   4. Staging event sequencing and telemetry flight director dashboard
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Launch Vehicle Specs (similar to Falcon 9 class):
# Liftoff Mass: 540,000 kg (Stage 1: 430t prop + 25t dry, Stage 2: 105t prop + 4t dry + 5t payload)
# Stage 1 Burn: T+0 to T+150s (Thrust: 7.6 MN liftoff, throttled to 5.5 MN at Max-Q, MECO at T+150s)
# Staging / Coast: T+150 to T+154s
# Stage 2 Burn: T+154 to T+390s (Thrust: 980 kN vacuum engine until SECO)

# Total mission profile: 400 seconds
# 1. Thrust Envelope T(t) in kiloNewtons (kN)
my $thrust_kn = env([
    # Stages:
    # 0s: Liftoff 7600 kN
    # 50s: Start Max-Q throttle bucket (down to 5500 kN)
    # 75s: Throttle back up to 7600 kN
    # 140s: G-limiter throttle down to 5000 kN
    # 150s: MECO (0 kN)
    # 154s: Stage 2 ignition 980 kN
    # 390s: SECO (0 kN)
    # 400s: Orbit coast
    [0.0, 7600.0, 7600.0, 5500.0, 7600.0, 5000.0, 0.0, 0.0, 980.0, 980.0, 0.0, 0.0],
    [2.0, 48.0,   15.0,   15.0,   60.0,   10.0,  4.0, 2.0,   234.0, 2.0,  8.0],
    [1.0, 1.0,    -1.5,   1.5,    1.0,    -1.0,  1.0, 1.0,   1.0,   1.0,  1.0]
], is_hold => 1);

# 2. Total Vehicle Mass Envelope m(t) in metric tons (1000 kg)
# Drops as fuel burns, with sharp drop when Stage 1 booster separates at T+152s (-25 tons dry mass)
my $mass_tons = env([
    [540.0, 530.0, 360.0, 310.0, 150.0, 140.0, 115.0, 114.0, 12.0, 9.0, 9.0],
    [2.0,   48.0,  20.0,  10.0,  65.0,   5.0,   2.0,   2.0,   234.0, 2.0],
    [1.0,   1.0,   1.0,   1.0,   1.0,    1.0,   1.0,   1.0,   1.0,   1.0]
], is_hold => 1);

# Build acceleration profile a(t) in m/s^2:
#   a(t) = [Thrust(N) / Mass(kg)] - g_eff (where g_eff ~ 9.81 * (R / (R + h))^2)
my $steps = 200;
my $total_time = 395.0; # seconds
my $dt = $total_time / $steps;

my @t_axis;
my @acc_vals;
my $g0 = 9.81;

for my $i (0 .. $steps) {
    my $t = $i * $dt;
    push @t_axis, $t;

    my $f_newtons = $thrust_kn->at($t) * 1000.0;
    my $m_kg = $mass_tons->at($t) * 1000.0;

    my $a_thrust = ($m_kg > 0) ? ($f_newtons / $m_kg) : 0.0;
    # Effective gravity loss diminishes with altitude and pitch-over angle
    # Pitch angle reorients vertical thrust into horizontal orbital velocity
    my $pitch_fraction = ($t < 150) ? (1.0 - ($t / 150.0) * 0.65) : 0.15;
    my $a_net = $a_thrust - ($g0 * $pitch_fraction);
    $a_net = 0.0 if $a_net < 0 && $t < 2.0;

    push @acc_vals, $a_net;
}

# Create acceleration envelope
my @durs = ($dt) x $steps;
my @curves = (1.0) x $steps;
my $accel = env([\@acc_vals, \@durs, \@curves], is_hold => 1);

# Velocity v(t) = ∫ a(t) dt (m/s)
my $velocity = $accel->integrate;

# Altitude h(t) = ∫ (v_vertical) dt (meters)
# Vertical velocity component drops as vehicle pitches into horizontal orbit
my @v_vert;
for my $i (0 .. $steps) {
    my $t = $i * $dt;
    my $v = $velocity->at($t);
    my $pitch = ($t < 160) ? (cos(($t / 160.0) * (3.14159 / 2.2))) : 0.05;
    push @v_vert, $v * $pitch;
}
my $vert_vel_env = env([\@v_vert, \@durs, \@curves], is_hold => 1);
my $altitude = $vert_vel_env->integrate;

print "=" x 74, "\n";
print "  Multistage Orbital Rocket Trajectory & Max-Q Aerodynamic Telemetry\n";
print "=" x 74, "\n";

# Atmospheric dynamic pressure Q = 1/2 * rho * v^2
# rho(h) = rho_0 * exp(-h / H_scale), H_scale = 8500m
my $rho_0 = 1.225; # kg/m^3
my $h_scale = 8500.0;

my $max_q_val = 0.0;
my $max_q_time = 0.0;
for my $i (0 .. $steps) {
    my $t = $i * $dt;
    my $h = $altitude->at($t);
    my $v = $velocity->at($t);
    my $rho = $rho_0 * exp(-$h / $h_scale);
    my $q = 0.5 * $rho * $v * $v / 1000.0; # in kPa
    if ($q > $max_q_val) {
        $max_q_val = $q;
        $max_q_time = $t;
    }
}

printf "Liftoff Mass: %.0f tons | Target Orbit: LEO (~200 km) | Final Velocity: %.1f km/s\n",
    $mass_tons->at(0), $velocity->at($total_time) / 1000.0;
printf "Max-Q Detected at T+%4.1f s | Peak Aerodynamic Pressure: %.1f kPa\n",
    $max_q_time, $max_q_val;
print "-" x 74, "\n";

# Mission Milestones & Telemetry Log
printf "%-6s | %-10s | %-10s | %-9s | %-8s | %s\n",
    "Time", "Altitude", "Velocity", "Accel", "Dyn Q", "Event / Phase";
print "-" x 74, "\n";

my @log_times = (0, 30, 60, 90, 130, 150, 155, 200, 260, 320, 380, 390);
for my $t (@log_times) {
    my $h = $altitude->at($t);
    my $v = $velocity->at($t);
    my $a = $accel->at($t);
    my $rho = $rho_0 * exp(-$h / $h_scale);
    my $q = 0.5 * $rho * $v * $v / 1000.0;

    my $event = "";
    if ($t == 0)   { $event = "LIFTOFF" }
    elsif ($t == 60)  { $event = "MAX-Q (Throttled)" }
    elsif ($t == 130) { $event = "G-Limiter Throttle" }
    elsif ($t == 150) { $event = "MECO (Main Engine Cutoff)" }
    elsif ($t == 155) { $event = "STAGE 2 IGNITION" }
    elsif ($t == 390) { $event = "SECO (Orbital Insertion)" }

    printf "T+%03.0fs | %7.1f km | %6.1f m/s | %+5.1f m/s² | %4.1f kPa | %s\n",
        $t, $h / 1000.0, $v, $a, $q, $event;
}

print "-" x 74, "\n";
print "Altitude Ascent Visual Profile (0 to 200 km):\n";
my $chart_w = 40;
for my $t (0, 40, 80, 120, 160, 200, 250, 300, 350, 390) {
    my $h_km = $altitude->at($t) / 1000.0;
    my $bar = int(($h_km / 200.0) * $chart_w);
    $bar = 0 if $bar < 0; $bar = $chart_w if $bar > $chart_w;
    printf "  T+%03.0fs [%6.1f km] |%s%s|\n",
        $t, $h_km, "#" x $bar, " " x ($chart_w - $bar);
}
print "=" x 74, "\n";
