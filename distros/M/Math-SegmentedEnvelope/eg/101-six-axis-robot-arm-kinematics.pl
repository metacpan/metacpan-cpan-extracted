#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 6-Axis Industrial Robotic Arm: 6D Joint Space Kinematics & Singularity Avoidance
# ============================================================================
# An articulated 6-DOF industrial robot (e.g. KUKA, ABB, Fanuc, Universal Robots)
# operates in a 6-dimensional joint space:
#   q(t) = [q1(t), q2(t), q3(t), q4(t), q5(t), q6(t)] in R^6
# corresponding to:
#   q1: Base / Waist rotation (yaw)
#   q2: Shoulder pitch
#   q3: Elbow pitch
#   q4: Wrist 1 pitch
#   q5: Wrist 2 yaw
#   q6: Wrist 3 roll
#
# Robotic Dynamics & Kinematic Constraints:
#   1. Joint Velocity:
#        q_dot_i(t) = d q_i / dt   [rad / s or deg / s]
#      (Strict mechanical gearbox limit: |q_dot_i| <= 180 deg/s)
#   2. Joint Acceleration:
#        q_ddot_i(t) = d^2 q_i / dt^2   [deg / s^2]
#      (Motor torque limit: |q_ddot_i| <= 360 deg/s^2)
#   3. Yoshikawa Kinematic Manipulability Index:
#        w(q) = sqrt( det( J(q) * J(q)^T ) ) ~ |sin(q3)| * |sin(q5)|
#      (When q5 -> 0, the robot enters a Wrist Singularity: wrist roll and
#       wrist pitch axes align, requiring infinite joint velocity to track!)
#
# This example demonstrates:
#   1. Synthesizing coordinated 6D joint trajectories q1..q6 for a high-speed
#      industrial pick-and-place / laser welding maneuver.
#   2. Computing 6D joint velocities via derivative() to verify gearbox speed limits.
#   3. Computing 6D joint accelerations via secondary derivative() to verify torque.
#   4. Tracking the 6D Yoshikawa manipulability metric to ensure singularity avoidance.
#   5. Generating an ASCII 6-joint telemetry report and speed limit margin chart.
# ============================================================================

my $duration = 4.0; # 4.0 second cycle time
my $rad2deg  = 45.0 / atan2(1, 1);
my $deg2rad  = atan2(1, 1) / 45.0;

# 1. 6D Joint Waypoints (degrees) across 5 Keyframe Poses:
# Poses: [Home/Ready -> Reach Down Pick -> Lift & S-Curve Swing -> Place -> Retract]
my @t_wps = (  0.0,   1.0,   2.2,   3.2,   4.0);

# Joint 1: Base Yaw [-45° -> +60° swing]
my @q1_wps = (  0.0, -35.0,  20.0,  60.0,  45.0);
# Joint 2: Shoulder Pitch [-30° reach -> +15° lift -> -20° place]
my @q2_wps = (-20.0, -45.0,  10.0, -30.0, -15.0);
# Joint 3: Elbow Pitch [80° -> 110° tuck -> 65° reach]
my @q3_wps = ( 75.0, 105.0,  55.0,  90.0,  70.0);
# Joint 4: Wrist 1 Pitch [-45° -> -60° tool level]
my @q4_wps = (-35.0, -60.0, -25.0, -50.0, -40.0);
# Joint 5: Wrist 2 Yaw [Maintain safe clearance from 0° singularity!]
my @q5_wps = ( 45.0,  30.0,  50.0,  35.0,  45.0);
# Joint 6: Wrist 3 Tool Roll [0° -> 90° orientation alignment]
my @q6_wps = (  0.0,  25.0,  65.0,  90.0,  90.0);

# Build smooth C2-continuous splines for all 6 joints
my $env_q1 = spline(\@t_wps, \@q1_wps, segments => 48, is_hold => 1);
my $env_q2 = spline(\@t_wps, \@q2_wps, segments => 48, is_hold => 1);
my $env_q3 = spline(\@t_wps, \@q3_wps, segments => 48, is_hold => 1);
my $env_q4 = spline(\@t_wps, \@q4_wps, segments => 48, is_hold => 1);
my $env_q5 = spline(\@t_wps, \@q5_wps, segments => 48, is_hold => 1);
my $env_q6 = spline(\@t_wps, \@q6_wps, segments => 48, is_hold => 1);

my @q_envs = ($env_q1, $env_q2, $env_q3, $env_q4, $env_q5, $env_q6);

# 2. Differentiate to Calculate 6D Joint Velocities q_dot (deg/s)
my @v_envs;
for my $e (@q_envs) {
    push @v_envs, $e->resample(40)->derivative;
}

# 3. Differentiate to Calculate 6D Joint Accelerations q_ddot (deg/s^2)
my @a_envs;
for my $e (@v_envs) {
    push @a_envs, $e->resample(40)->derivative;
}

# 4. Evaluate Physical Limits & Manipulability
my $dt = 0.05;
my @peak_v = (0) x 6;
my @peak_a = (0) x 6;
my $min_manip = 999;
my $min_manip_t = 0;

for (my $t = 0; $t <= $duration; $t += $dt) {
    for my $i (0 .. 5) {
        my $v = abs($v_envs[$i]->at($t));
        my $a = abs($a_envs[$i]->at($t));
        $peak_v[$i] = $v if $v > $peak_v[$i];
        $peak_a[$i] = $a if $a > $peak_a[$i];
    }

    # Yoshikawa Manipulability Measure w = |sin(q3)| * |sin(q5)|
    my $q3_rad = $q_envs[2]->at($t) * $deg2rad;
    my $q5_rad = $q_envs[4]->at($t) * $deg2rad;
    my $w = abs(sin($q3_rad) * sin($q5_rad));
    if ($w < $min_manip) {
        $min_manip = $w;
        $min_manip_t = $t;
    }
}

print "=" x 76, "\n";
print "  6-Axis Industrial Robot: 6D Joint Kinematics & Singularity Telemetry\n";
print "=" x 76, "\n";
print "Robot Architecture: 6-DOF Articulated Arm (Waist, Shoulder, Elbow, 3-Axis Wrist)\n";
print "Gearbox Limits    : Max Speed = 180.0 deg/s | Max Accel = 360.0 deg/s²\n";
print "Maneuver Horizon  : 4.00s High-Speed Pick & Place Seam Trajectory\n";
print "-" x 76, "\n";
printf "%-8s | %-16s | %-12s | %-12s | %s\n",
    "Joint", "Function", "Peak Speed", "Peak Accel", "Compliance Status";
print "-" x 76, "\n";

my @joint_names = (
    "q1: Base Yaw", "q2: Shoulder Pitch", "q3: Elbow Pitch",
    "q4: Wrist 1 Pitch", "q5: Wrist 2 Yaw", "q6: Wrist 3 Roll"
);

for my $i (0 .. 5) {
    my $status = ($peak_v[$i] <= 180.0 && $peak_a[$i] <= 360.0)
               ? "OK (Compliant)" : "LIMIT EXCEEDED!";
    printf "Joint %d  | %-16s | %5.1f deg/s  | %5.1f deg/s² | %s\n",
        $i + 1, $joint_names[$i], $peak_v[$i], $peak_a[$i], $status;
}
print "-" x 76, "\n";
printf "Yoshikawa Manipulability Minimum: %5.3f at t=%4.2fs (Safe Margin > 0.150)\n",
    $min_manip, $min_manip_t;
print "-" x 76, "\n";

# 5. 6D Joint Trajectory Telemetry Across Time
print "\n6D Joint Angle States q(t) [Degrees] & Singularity Index w(t):\n";
print "Time   |   q1   |   q2   |   q3   |   q4   |   q5   |   q6   | Manipulability Bar\n";
print "-" x 76, "\n";

my $bar_w = 16;
for (my $t = 0.0; $t <= $duration; $t += 0.25) {
    my @angles = map { $q_envs[$_]->at($t) } (0 .. 5);

    my $q3_rad = $angles[2] * $deg2rad;
    my $q5_rad = $angles[4] * $deg2rad;
    my $w = abs(sin($q3_rad) * sin($q5_rad));

    my $pos = int(($w / 1.0) * ($bar_w - 1));
    $pos = 0 if $pos < 0; $pos = $bar_w - 1 if $pos >= $bar_w;
    my $bar = ('*' x ($pos + 1)) . ('.' x ($bar_w - 1 - $pos));

    printf "%4.2fs  | %+5.1f° | %+5.1f° | %+5.1f° | %+5.1f° | %+5.1f° | %+5.1f° | [%s] w=%4.2f\n",
        $t, $angles[0], $angles[1], $angles[2], $angles[3], $angles[4], $angles[5],
        $bar, $w;
}

print "=" x 76, "\n";
print "Summary: spline() coordinates 6D joint trajectories in R⁶; derivative()\n";
print "evaluates joint velocities and accelerations to ensure safe robotic motion.\n";
print "=" x 76, "\n";
