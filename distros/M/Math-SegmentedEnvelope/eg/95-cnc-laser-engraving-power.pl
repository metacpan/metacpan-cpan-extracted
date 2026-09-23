#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# ============================================================================
# CNC Laser Cutting / 3D Printing: Dynamic Corner Power Compensation
# ============================================================================
# In high-speed CNC laser cutting and additive manufacturing (3D printing),
# gantry axis motors have finite acceleration limits. When executing sharp
# corners (e.g. 90-degree turns), the toolhead must decelerate substantially
# at the corner apex and re-accelerate along the new vector.
#
# Thermal Physics Problem:
#   Energy Density (heat fluence per millimeter):
#       E(t) = Power(t) / Velocity(t)   [Joules / mm]
#
# If laser power remains fixed at nominal (e.g. 100 W) while toolhead speed
# drops from 100 mm/s to 15 mm/s at the corner, energy density spikes by >600%!
# This causes severe corner burning, melting, charring, wide kerf gouging,
# and ruined part dimensions.
#
# Solution (Dynamic Power Compensation):
#   The CNC controller modulates laser PWM power proportionally to instantaneous
#   tangential toolpath velocity:
#       P_comp(t) = P_nom * (v(t) / v_max)
#   This maintains perfectly uniform energy delivery E(t) = constant across
#   both straightaways and tight corners.
#
# This example demonstrates:
#   1. Modeling 2D toolhead motion X(t) and Y(t) around a 90-degree corner.
#   2. Differentiating position envelopes using derivative() to obtain
#      axis velocity components vx(t) and vy(t).
#   3. Computing tangential path velocity v(t) = sqrt(vx^2 + vy^2).
#   4. Comparing uncompensated vs compensated laser power and energy fluence.
#   5. Integrating heat energy over the corner window via integrate().
#   6. Rendering an ASCII corner burn intensity map and transient profile.
# ============================================================================

my $p_nom = 100.0;     # Nominal laser power: 100 Watts
my $v_nom = 100.0;     # Nominal straightaway speed: 100 mm/s
my $e_target = 1.0;    # Nominal energy fluence: 1.00 J/mm

my $total_t = 2.0;     # Total trajectory duration (seconds)
my $corner_t = 1.0;    # Corner apex occurs at t = 1.0s

# 1. Multi-axis Position Envelopes around a 90° Corner:
# Toolpath moves from (0, 50) mm to (50, 50) mm (0 <= t <= 1.0s)
# then turns 90° downward to (50, 0) mm (1.0 <= t <= 2.0s).
# Ease curves (-2 deceleration, +2 acceleration) model gantry kinematics.
my $px = Math::SegmentedEnvelope->new(
    [[0.0, 50.0, 50.0], [1.0, 1.0], [-2, 1]],
    is_hold => 1,
);

my $py = Math::SegmentedEnvelope->new(
    [[50.0, 50.0, 0.0], [1.0, 1.0], [1, 2]],
    is_hold => 1,
);

# 2. Differentiate Position to Obtain Axis Velocities
my $vx_env = $px->resample(64)->derivative;
my $vy_env = $py->resample(64)->derivative;

# 3. Sample Tangential Velocity, Power, and Energy Density
my $dt = 0.02;
my (@t_samples, @v_samples, @p_uncomp_samples, @p_comp_samples);
my (@e_uncomp_samples, @e_comp_samples);

for (my $t = 0; $t <= $total_t; $t += $dt) {
    push @t_samples, $t;

    my $vx = $vx_env->at($t);
    my $vy = $vy_env->at($t);
    my $v = sqrt($vx * $vx + $vy * $vy);

    # Prevent division by zero at standstill
    my $v_safe = ($v < 2.0) ? 2.0 : $v;

    # Uncompensated: 100W constant laser power
    my $p_uncomp = $p_nom;
    my $e_uncomp = $p_uncomp / $v_safe;

    # Compensated: Power throttled proportionally to speed
    my $v_ratio = $v / $v_nom;
    $v_ratio = 1.0 if $v_ratio > 1.0;
    my $p_comp = $p_nom * $v_ratio;
    my $e_comp = ($v > 2.0) ? ($p_comp / $v) : $e_target;

    push @v_samples,        $v;
    push @p_uncomp_samples, $p_uncomp;
    push @p_comp_samples,   $p_comp;
    push @e_uncomp_samples, $e_uncomp;
    push @e_comp_samples,   $e_comp;
}

my $v_env        = from_samples(\@v_samples,        $total_t, is_hold => 1);
my $p_comp_env   = from_samples(\@p_comp_samples,   $total_t, is_hold => 1);
my $e_uncomp_env = from_samples(\@e_uncomp_samples, $total_t, is_hold => 1);
my $e_comp_env   = from_samples(\@e_comp_samples,   $total_t, is_hold => 1);

# Integrate energy delivery over time to get total Joules deposited
my $joules_uncomp = ($p_nom * $total_t); # constant 100W * 2s = 200 J
my $energy_comp_integral = $p_comp_env->integrate;
my $joules_comp = $energy_comp_integral->at($total_t);

# Find peak energy spike at corner
my $max_e_uncomp = 0;
my $max_e_comp   = 0;
my $min_v        = 999;
for my $e (@e_uncomp_samples) { $max_e_uncomp = $e if $e > $max_e_uncomp; }
for my $e (@e_comp_samples)   { $max_e_comp   = $e if $e > $max_e_comp; }
for my $v (@v_samples)        { $min_v        = $v if $v < $min_v; }

print "=" x 76, "\n";
print "  CNC Laser Machining: Dynamic Corner Power & Fluence Compensation\n";
print "=" x 76, "\n";
printf "Nominal Laser Power: %.0f W | Target Cut Speed: %.0f mm/s | Nominal Fluence: %.2f J/mm\n",
    $p_nom, $v_nom, $e_target;
printf "Corner Turn Angle  : 90 degrees | Minimum Apex Velocity: %5.1f mm/s\n", $min_v;
print "-" x 76, "\n";
printf "Uncompensated Laser: Peak Energy Spike = %5.2f J/mm (+%3.0f%% OVERHEATING!)\n",
    $max_e_uncomp, (($max_e_uncomp - $e_target) / $e_target * 100);
printf "Compensated Laser  : Peak Energy Fluence = %5.2f J/mm (Uniform Cut Kerf)\n",
    $max_e_comp;
printf "Total Heat Injected: Uncomp = %5.1f J | Comp = %5.1f J (%.1f%% energy saved)\n",
    $joules_uncomp, $joules_comp, (($joules_uncomp - $joules_comp) / $joules_uncomp * 100);
print "-" x 76, "\n";

# 4. Transient Corner Deceleration & Power Throttle Table
print "\nTransient Corner Passing Profile (Zoom: t = 0.60s to 1.40s):\n";
print "Time   | Velocity | Uncomp Pwr | Comp Pwr | Uncomp Fluence | Comp Fluence | Heat Spike Bar\n";
print "-" x 76, "\n";

for (my $t = 0.60; $t <= 1.40; $t += 0.08) {
    my $v  = $v_env->at($t);
    my $pu = $p_nom;
    my $pc = $p_comp_env->at($t);
    my $eu = $e_uncomp_env->at($t);
    my $ec = $e_comp_env->at($t);

    # Render bar for uncompensated fluence [1.0 to 10.0 J/mm]
    my $bar_len = int(($eu - 1.0) / (10.0 - 1.0) * 16);
    $bar_len = 0 if $bar_len < 0;
    $bar_len = 16 if $bar_len > 16;
    my $bar = ('*' x $bar_len) . ($bar_len > 8 ? " [BURN!]" : "");

    printf "%4.2fs  | %5.1fmm/s|   %3.0f W   |  %5.1f W |   %5.2f J/mm   |   %5.2f J/mm | %-16s\n",
        $t, $v, $pu, $pc, $eu, $ec, $bar;
}
print "-" x 76, "\n";

# 5. 2D ASCII Toolpath Heat Map around 90° Corner
print "\n2D Toolpath Heat Deposition Around Corner (50mm x 50mm Zone):\n";
print "Coordinates: [0,50] ---> [50,50] (Corner) | Key: [.] Nominal Cut  [*] Burned Zone\n";
print "                          |\n";
print "                          v [50,0]\n";
print "-" x 76, "\n";

my @map = (
    "    Y=50mm | . . . . . . . . . . . . . . . * * * [Corner: Extreme Charring/Melt!]",
    "    Y=40mm |                               *      ",
    "    Y=30mm |                               *      ",
    "    Y=20mm |                               .      ",
    "    Y=10mm |                               .      ",
    "     Y=0mm |                               . [Exit]",
    "           +--------------------------------------",
    "             X=0mm                       X=50mm   ",
);
print "$_\n" for @map;

print "=" x 76, "\n";
print "Summary: derivative() determines instantaneous multi-axis path speed v(t),\n";
print "allowing feed-forward laser power scaling to eliminate corner burning.\n";
print "=" x 76, "\n";
