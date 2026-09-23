#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 5-Axis CNC Flank Milling: 5D Tool Pose, Kinematic Singularities & Feedrate
# ============================================================================
# In high-performance aerospace manufacturing (jet engine blisks, titanium
# turbine blades, impellers), 5-axis CNC machining centers drive a 5-dimensional
# tool pose vector:
#   T(t) = [X(t), Y(t), Z(t), B(t), C(t)] in R^5
# where:
#   - X, Y, Z : Tool Center Point (TCP) coordinates in 3D part space [mm]
#   - B       : Rotary table tilt angle (nutation) [degrees]
#   - C       : Rotary table swivel angle (precession) [degrees]
#
# Flank Milling (Swarf Cutting):
#   Instead of slow point-by-point ball nose rastering, the entire cylindrical
#   side flank of the cutter is swept tangentially along the ruled 3D blade
#   surface, increasing machining productivity by up to 800%!
#
# Kinematic Singularity Problem:
#   When the B-axis tilts near zero (B -> 0°, tool aligns with machine spindle),
#   the C-axis suffers a gimbal-lock kinematic singularity:
#     C_dot(t) ~ (1 / sin(B)) * d(tool_vector) / dt
#   Even minor orientation changes demand extreme C-axis angular velocities!
#   The CNC controller must dynamically throttle linear feedrate v_f(t) to
#   prevent rotary servo tripping and gouging.
#
# This example demonstrates:
#   1. Modeling a 5D flank milling toolpath [X, Y, Z, B, C] over a turbine blade.
#   2. Deriving linear TCP velocity v_f(t) and rotary speeds B_dot, C_dot via derivative().
#   3. Detecting rotary velocity spikes near the B ~ 0° singularity zone.
#   4. Calculating instantaneous Material Removal Rate MRR(t) = a_p * a_e * v_f(t).
#   5. Integrating total removed metal chip volume via integrate().
#   6. Rendering an ASCII 5D tool pose table and feedrate throttling chart.
# ============================================================================

my $duration = 10.0; # 10-second continuous flank pass across blade
my $ap       = 18.0; # Axial depth of cut: 18.0 mm (flank engaged length)
my $ae       = 1.50; # Radial width of cut (stepover): 1.50 mm

# 1. 5D Flank Milling Waypoints [X, Y, Z, B, C]
# Traverses from blade root leading edge to blade tip trailing edge
my @t_wps = (  0.0,   2.5,   5.0,   7.5,  10.0);
my @x_wps = (  0.0,  30.0,  70.0, 110.0, 140.0); # mm chordwise travel
my @y_wps = (  0.0,  15.0,  35.0,  50.0,  60.0); # mm camber curvature
my @z_wps = (  0.0,  10.0,  30.0,  60.0,  90.0); # mm blade height span
my @b_wps = ( 25.0,  14.0,   4.5,  18.0,  28.0); # B-axis tilt (approaches 4.5° near t=5.0s!)
my @c_wps = ( 10.0,  35.0,  85.0, 125.0, 150.0); # C-axis swivel (steep sweep at crest)

my $spline_x = spline(\@t_wps, \@x_wps, segments => 64, is_hold => 1);
my $spline_y = spline(\@t_wps, \@y_wps, segments => 64, is_hold => 1);
my $spline_z = spline(\@t_wps, \@z_wps, segments => 64, is_hold => 1);
my $spline_b = spline(\@t_wps, \@b_wps, segments => 64, is_hold => 1);
my $spline_c = spline(\@t_wps, \@c_wps, segments => 64, is_hold => 1);

# 2. Differentiate 5D Trajectories to Obtain Feedrates & Rotary Velocities
my $vx_env = $spline_x->derivative;
my $vy_env = $spline_y->derivative;
my $vz_env = $spline_z->derivative;
my $vb_env = $spline_b->derivative;
my $vc_env = $spline_c->derivative;

my $dt = 0.1;
my (@t_eval, @v_tcp_mmpm, @b_rot_dps, @c_rot_dps, @mrr_samples);

for (my $t = 0; $t <= $duration; $t += $dt) {
    push @t_eval, $t;

    my $vx = $vx_env->at($t); # mm/s
    my $vy = $vy_env->at($t);
    my $vz = $vz_env->at($t);
    my $v_tcp_mm_s = sqrt($vx*$vx + $vy*$vy + $vz*$vz);
    my $v_tcp_mm_min = $v_tcp_mm_s * 60.0; # to mm/min
    push @v_tcp_mmpm, $v_tcp_mm_min;

    my $vb = abs($vb_env->at($t)); # deg/s
    my $vc = abs($vc_env->at($t)); # deg/s
    push @b_rot_dps, $vb;
    push @c_rot_dps, $vc;

    # Material Removal Rate MRR (cm^3 / min) = ap * ae * v_f / 1000
    my $mrr = ($ap * $ae * $v_tcp_mm_min) / 1000.0;
    push @mrr_samples, $mrr;
}

my $v_env   = from_samples(\@v_tcp_mmpm, $duration, is_hold => 1);
my $vb_rot  = from_samples(\@b_rot_dps,  $duration, is_hold => 1);
my $vc_rot  = from_samples(\@c_rot_dps,  $duration, is_hold => 1);
my $mrr_env = from_samples(\@mrr_samples, $duration, is_hold => 1);

# Integrate MRR over time (convert min to seconds) to get total metal removed (cm^3)
my $mrr_integral = $mrr_env->integrate;
my $total_chips_cm3 = ($mrr_integral->at($duration) / 60.0);

# Find peak velocities
my $peak_vc = 0; my $peak_vc_t = 0;
my $min_b   = 99; my $min_b_t   = 0;
for (my $t = 0; $t <= $duration; $t += 0.05) {
    my $c_speed = $vc_rot->at($t);
    if ($c_speed > $peak_vc) { $peak_vc = $c_speed; $peak_vc_t = $t; }
    my $b_ang = $spline_b->at($t);
    if ($b_ang < $min_b) { $min_b = $b_ang; $min_b_t = $t; }
}

print "=" x 76, "\n";
print "  5-Axis CNC Flank Milling: 5D Tool Pose & Rotary Singularity Analysis\n";
print "=" x 76, "\n";
printf "Workpiece Geometry: Inconel 718 Aerodynamic Turbine Blade (140mm x 90mm)\n";
printf "Cut Parameters    : Flank Depth ap = %.1f mm | Width ae = %.2f mm\n", $ap, $ae;
printf "Rotary Limits     : Max Rotary Speed = 35.0 deg/s | Target Feed = 1200 mm/min\n";
print "-" x 76, "\n";
printf "Min Tilt Angle B  : %5.1f deg   at t=%4.1fs (Near-Singularity Zone: B < 5.0°)\n",
    $min_b, $min_b_t;
printf "Peak C-Axis Speed : %5.1f deg/s at t=%4.1fs (Precession Acceleration Spike)\n",
    $peak_vc, $peak_vc_t;
printf "Total Chip Volume : %5.1f cm³   (Integrated via integrate())\n",
    $total_chips_cm3;
print "-" x 76, "\n";

# 3. 5D Telemetry Table Across Blade Pass
print "5D Tool Pose States [X, Y, Z, B, C] & Material Removal Rate (MRR):\n";
printf "%-6s | %-6s | %-6s | %-6s | %-6s | %-6s | %-9s | %-10s | %s\n",
    "Time", "X(mm)", "Y(mm)", "Z(mm)", "B(°)", "C(°)", "Feed(mpm)", "C-Rot(°/s)", "Status";
print "-" x 76, "\n";

for (my $t = 0.0; $t <= $duration; $t += 0.8) {
    my $x  = $spline_x->at($t);
    my $y  = $spline_y->at($t);
    my $z  = $spline_z->at($t);
    my $b  = $spline_b->at($t);
    my $c  = $spline_c->at($t);
    my $vf = $v_env->at($t);
    my $vc = $vc_rot->at($t);

    my $flag = ($b < 5.5)   ? "SINGULARITY!" :
               ($vc > 25.0) ? "C-SPEED HIGH" : "NORMAL CUT";

    printf "%4.1fs  | %5.1f | %5.1f | %5.1f | %4.1f° | %5.1f°| %5.0f mm/m | %5.1f °/s  | %s\n",
        $t, $x, $y, $z, $b, $c, $vf, $vc, $flag;
}
print "-" x 76, "\n";

# 4. ASCII Flank Toolpath Profile
print "\nFlank Cutting Toolpath: [Leading Edge -> Aerofoil Crest -> Trailing Edge]:\n";
print "Coordinates:\n";
my @toolpath_ascii = (
    "  Z=90mm |                                            * [Trailing Edge Tip]",
    "  Z=60mm |                                   * * *    ",
    "  Z=30mm |                      * * * [B=4.5° Singularity: Rapid C Swivel!]",
    "  Z=10mm |             * * *                  ",
    "   Z=0mm | * * * [Root Leading Edge]          ",
    "         +-------------------------------------------------------------",
    "           X=0mm            X=50mm            X=100mm         X=140mm  ",
);
print "$_\n" for @toolpath_ascii;

print "=" x 76, "\n";
print "Summary: spline() generates smooth 5D toolpaths in R⁵; derivative()\n";
print "identifies rotary axis speed spikes to prevent machine servo tripping.\n";
print "=" x 76, "\n";
