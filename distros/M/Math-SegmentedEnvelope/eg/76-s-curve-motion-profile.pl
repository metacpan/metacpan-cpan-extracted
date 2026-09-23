#!/usr/bin/env perl
# S-curve (7-segment jerk-limited) motion profile for robotics and CNC
# Demonstrates envelope integration:
#   Jerk j(t) = a'(t) (derivative of acceleration)
#   Velocity v(t) = ∫ a(t) dt (integral of acceleration)
#   Position s(t) = ∫ v(t) dt (integral of velocity)
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Machine parameters
my $v_max = 200.0;    # mm/s target cruise speed
my $a_max = 1000.0;   # mm/s^2 max acceleration
my $t_jerk = 0.05;    # s time to ramp acceleration (jerk phase)

# Time intervals for 7-segment S-curve:
# 1. Accel ramp-up (0 -> a_max)
# 2. Accel plateau (constant a_max)
# 3. Accel ramp-down (a_max -> 0)
# 4. Cruise at constant v_max
# 5. Decel ramp-up (0 -> -a_max)
# 6. Decel plateau (constant -a_max)
# 7. Decel ramp-down (-a_max -> 0)
my $t_cruise = 0.20;
my $t_accel_plateau = 0.15;

# Define acceleration envelope a(t) in mm/s^2
# S-curve ramps acceleration smoothly using linear or curved transitions
my $accel = env([
    [0, $a_max, $a_max, 0, 0, -$a_max, -$a_max, 0],
    [$t_jerk, $t_accel_plateau, $t_jerk, $t_cruise, $t_jerk, $t_accel_plateau, $t_jerk],
    [1, 1, 1, 1, 1, 1, 1],
], is_hold => 1);

# Compute Velocity v(t) = ∫ a(t) dt
my $velocity = $accel->integrate;

# Compute Position s(t) = ∫ v(t) dt
my $position = $velocity->integrate;

# Compute Jerk j(t) = da/dt
my $jerk = $accel->derivative;

my $total_time = $accel->duration;
my $total_dist = $position->at($total_time);
my $peak_speed = $velocity->max_value;

print "=" x 70, "\n";
print "  7-Segment S-Curve Motion Profile Generator\n";
print "=" x 70, "\n";
printf "Total Move Time: %.3f s | Total Distance: %.2f mm | Peak Speed: %.2f mm/s\n",
    $total_time, $total_dist, $peak_speed;
print "-" x 70, "\n";

# Plot multi-track ASCII telemetry
my $steps = 25;
printf "%-7s | %-12s | %-12s | %-12s | %s\n",
    "Time(s)", "Pos(mm)", "Vel(mm/s)", "Acc(mm/s²)", "Profile Trace";
print "-" x 70, "\n";

my $p_stat = $position->static;
my $v_stat = $velocity->static;
my $a_stat = $accel->static;

for my $i (0 .. $steps) {
    my $t = ($i / $steps) * $total_time;
    my $pos = $p_stat->($t);
    my $vel = $v_stat->($t);
    my $acc = $a_stat->($t);

    # Visual gauge for speed
    my $gauge_w = 20;
    my $bar_len = int(($vel / ($peak_speed || 1)) * $gauge_w);
    $bar_len = 0 if $bar_len < 0;
    $bar_len = $gauge_w if $bar_len > $gauge_w;
    my $gauge = "[" . ("#" x $bar_len) . (" " x ($gauge_w - $bar_len)) . "]";

    printf "%6.3f  | %10.2f   | %10.2f   | %+10.1f   | %s\n",
        $t, $pos, $vel, $acc, $gauge;
}

print "=" x 70, "\n";
print "Integrals & Derivatives check:\n";
printf "  Velocity at start: %.3f mm/s  | at end: %.3f mm/s (expected 0)\n",
    $velocity->at(0), $velocity->at($total_time);
printf "  Total displacement: %.2f mm\n", $position->at($total_time);
print "=" x 70, "\n";
