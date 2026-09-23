#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# ============================================================================
# 6-DOF Stewart Platform: Parallel Kinematics & Actuator Stroke Envelopes
# ============================================================================
# A Stewart-Gough platform (hexapod) is a 6-DOF parallel robotic mechanism
# widely used in flight simulators, earthquake shake tables, surgical robotics,
# and satellite antenna pointing.
#
# Mechanics & Kinematics:
#   - Fixed Base Platform: 6 anchor joints B_1 .. B_6 located on a base circle.
#   - Moving Top Platform: 6 anchor joints P_1 .. P_6 located on a top circle.
#   - 6 Linear Actuator Legs connecting B_i to P_i.
#   - 6-DOF Pose Command over time t:
#       Position    : [X(t), Y(t), Z(t)]           (Surge, Sway, Heave)
#       Orientation : [Roll phi(t), Pitch theta(t), Yaw psi(t)]
#
# Inverse Kinematics Problem (4D Spatiotemporal Solution):
#   For each leg i (1..6):
#     Top joint in world coordinates:
#       P_world_i(t) = R(phi, theta, psi) * p_local_i + T(X, Y, Z)
#     Leg displacement vector:
#       L_vec_i(t) = P_world_i(t) - B_i
#     Leg cylinder length:
#       L_i(t) = || L_vec_i(t) ||
#
# Hydraulic / Servo Constraints:
#   - Cylinder stroke limits: L_min = 1.15m <= L_i(t) <= L_max = 1.65m
#   - Max piston extension velocity: |dL_i / dt| <= 0.45 m/s (pump flow limit)
#
# This example demonstrates:
#   1. Synthesizing coordinated 6-DOF flight maneuver envelopes (Takeoff -> Pitch Up -> Banked Turn).
#   2. Solving inverse kinematics for all 6 actuator leg lengths across time.
#   3. Deriving actuator piston velocities dL_i/dt via derivative() to verify servo limits.
#   4. Generating an ASCII 6-actuator stroke headroom and velocity telemetry chart.
# ============================================================================

my $pi = 4.0 * atan2(1, 1);
my $deg2rad = $pi / 180.0;
my $duration = 6.0; # 6-second motion simulation maneuver

# 1. Base and Platform Geometry (radii in meters, joint pair angle offsets)
my $r_base = 1.00; # Base circle radius (m)
my $r_plat = 0.70; # Top platform circle radius (m)
my $z_nom  = 1.10; # Nominal neutral heave height (m)

# Joint angular positions around base and top circles (3 pairs of 2 joints)
# Base pairs at 60°, 180°, 300° with +/- 10° offset
my @base_angles = (50, 70, 170, 190, 290, 310);
# Top platform pairs at 0°, 120°, 240° with +/- 15° offset
my @plat_angles = (345, 15, 105, 135, 225, 255);

my @base_joints;
for my $deg (@base_angles) {
    my $rad = $deg * $deg2rad;
    push @base_joints, [$r_base * cos($rad), $r_base * sin($rad), 0.0];
}

my @plat_joints_local;
for my $deg (@plat_angles) {
    my $rad = $deg * $deg2rad;
    push @plat_joints_local, [$r_plat * cos($rad), $r_plat * sin($rad), 0.0];
}

# 2. 6-DOF Flight Simulator Motion Profile (Takeoff -> Initial Climb -> Left Turn)
# Surge X (longitudinal): acceleration surge [0 -> 0.15m]
my $env_x = Math::SegmentedEnvelope->new(
    [[0.0, 0.15, 0.10, 0.0], [2.0, 2.5, 1.5], [2, 1, -2]], is_hold => 1);

# Sway Y (lateral): centrifugal displacement during turn [0 -> -0.12m]
my $env_y = Math::SegmentedEnvelope->new(
    [[0.0, 0.0, -0.12, -0.05], [2.5, 2.0, 1.5], [1, 2, -2]], is_hold => 1);

# Heave Z: vertical takeoff bump then sustained climb [1.10m -> 1.22m]
my $env_z = Math::SegmentedEnvelope->new(
    [[$z_nom, $z_nom - 0.04, $z_nom + 0.12, $z_nom + 0.08], [1.5, 2.5, 2.0], [-2, 2, -1]], is_hold => 1);

# Roll phi (degrees): level -> bank left (-12 deg) -> recover (-4 deg)
my $env_roll = Math::SegmentedEnvelope->new(
    [[0.0, 0.0, -12.0, -4.0], [2.5, 2.0, 1.5], [1, 2, -2]], is_hold => 1);

# Pitch theta (degrees): level -> rotate nose up (+16 deg) -> cruise climb (+8 deg)
my $env_pitch = Math::SegmentedEnvelope->new(
    [[0.0, 16.0, 12.0, 8.0], [2.0, 2.5, 1.5], [2, -2, -1]], is_hold => 1);

# Yaw psi (degrees): heading turn [0 -> -8 deg]
my $env_yaw = Math::SegmentedEnvelope->new(
    [[0.0, 0.0, -8.0, -8.0], [3.0, 2.0, 1.0], [1, 2, 1]], is_hold => 1);

# 3. Inverse Kinematics Evaluation across Time
my $dt = 0.05;
my @t_eval;
my @leg_lengths = ([], [], [], [], [], []);

for (my $t = 0; $t <= $duration; $t += $dt) {
    push @t_eval, $t;

    my $tx = $env_x->at($t);
    my $ty = $env_y->at($t);
    my $tz = $env_z->at($t);

    my $phi   = $env_roll->at($t) * $deg2rad;
    my $theta = $env_pitch->at($t) * $deg2rad;
    my $psi   = $env_yaw->at($t) * $deg2rad;

    # 3D Euler Rotation Matrix R = Rz(psi) * Ry(theta) * Rx(phi)
    my ($cp, $sp) = (cos($phi),   sin($phi));
    my ($ct, $st) = (cos($theta), sin($theta));
    my ($cs, $ss) = (cos($psi),   sin($psi));

    my $r11 = $cs * $ct;
    my $r12 = $cs * $st * $sp - $ss * $cp;
    my $r13 = $cs * $st * $cp + $ss * $sp;

    my $r21 = $ss * $ct;
    my $r22 = $ss * $st * $sp + $cs * $cp;
    my $r23 = $ss * $st * $cp - $cs * $sp;

    my $r31 = -$st;
    my $r32 = $ct * $sp;
    my $r33 = $ct * $cp;

    # Compute each leg length L_i = || R * p_i + T - B_i ||
    for my $i (0 .. 5) {
        my ($px, $py, $pz) = @{$plat_joints_local[$i]};
        my ($bx, $by, $bz) = @{$base_joints[$i]};

        my $wx = $r11 * $px + $r12 * $py + $r13 * $pz + $tx;
        my $wy = $r21 * $px + $r22 * $py + $r23 * $pz + $ty;
        my $wz = $r31 * $px + $r32 * $py + $r33 * $pz + $tz;

        my $lx = $wx - $bx;
        my $ly = $wy - $by;
        my $lz = $wz - $bz;
        my $len = sqrt($lx*$lx + $ly*$ly + $lz*$lz);

        push @{$leg_lengths[$i]}, $len;
    }
}

# Build continuous envelopes and derivatives for each leg
my (@leg_envs, @leg_vel_envs);
my @max_speeds = (0) x 6;
my @min_lengths = (99) x 6;
my @max_lengths = (0) x 6;

for my $i (0 .. 5) {
    my $len_env = from_samples($leg_lengths[$i], $duration, is_hold => 1);
    my $vel_env = $len_env->resample(40)->derivative;
    push @leg_envs, $len_env;
    push @leg_vel_envs, $vel_env;

    for my $l (@{$leg_lengths[$i]}) {
        $min_lengths[$i] = $l if $l < $min_lengths[$i];
        $max_lengths[$i] = $l if $l > $max_lengths[$i];
    }
    for (my $t = 0; $t <= $duration; $t += $dt) {
        my $v = abs($vel_env->at($t));
        $max_speeds[$i] = $v if $v > $max_speeds[$i];
    }
}

# 4. Display Stewart Platform Performance Report
print "=" x 76, "\n";
print "  6-DOF Stewart Platform: Inverse Kinematics & Actuator Stroke Envelopes\n";
print "=" x 76, "\n";
printf "Geometry: Base Radius = %.2fm | Top Platform Radius = %.2fm | Neutral Height = %.2fm\n",
    $r_base, $r_plat, $z_nom;
printf "Maneuver: Takeoff Rotation (Pitch +16°) -> Climb -> Banked Turn (Roll -12°)\n";
printf "Cylinder Limits: Stroke [1.15m .. 1.70m] (550mm travel) | Max Velocity = 0.45 m/s\n";
print "-" x 76, "\n";
printf "%-6s | %-12s | %-12s | %-12s | %-12s | %s\n",
    "Leg", "Min Stroke", "Max Stroke", "Total Travel", "Peak Speed", "Hydraulic Status";
print "-" x 76, "\n";

for my $i (0 .. 5) {
    my $travel = ($max_lengths[$i] - $min_lengths[$i]) * 1000.0; # mm
    my $status = ($max_speeds[$i] <= 0.45 && $min_lengths[$i] >= 1.15 && $max_lengths[$i] <= 1.70)
               ? "OK (Safe Margin)" : "LIMIT EXCEEDED!";
    printf "Leg %d  |   %5.3f m   |   %5.3f m   |   %5.1f mm   |  %5.3f m/s  | %s\n",
        $i + 1, $min_lengths[$i], $max_lengths[$i], $travel, $max_speeds[$i], $status;
}
print "-" x 76, "\n";

# 5. ASCII Actuator Stroke Extension Bar Chart over Time
print "\nActuator Stroke Trajectories L_i(t) [1.20m to 1.60m]:\n";
print "Time   | Leg 1  | Leg 2  | Leg 3  | Leg 4  | Leg 5  | Leg 6  | Leg 1 Stroke Bar\n";
print "-" x 76, "\n";

my $bar_w = 20;
for (my $t = 0.0; $t <= $duration; $t += 0.4) {
    my @lens = map { $leg_envs[$_]->at($t) } (0 .. 5);

    # Bar for Leg 1 stroke [1.20m .. 1.55m]
    my $pos = int(($lens[0] - 1.20) / (1.55 - 1.20) * ($bar_w - 1));
    $pos = 0 if $pos < 0; $pos = $bar_w - 1 if $pos >= $bar_w;
    my @bar = (' ') x $bar_w;
    $bar[$pos] = '|';
    my $bar_str = join('', @bar);

    printf "%4.2fs  | %5.3fm | %5.3fm | %5.3fm | %5.3fm | %5.3fm | %5.3fm | [%s]\n",
        $t, $lens[0], $lens[1], $lens[2], $lens[3], $lens[4], $lens[5], $bar_str;
}
print "=" x 76, "\n";
print "Summary: SegmentedEnvelope coordinates 6-DOF flight trajectory commands;\n";
print "inverse kinematics determines 6D leg extensions and derivative() verifies flow rates.\n";
print "=" x 76, "\n";
