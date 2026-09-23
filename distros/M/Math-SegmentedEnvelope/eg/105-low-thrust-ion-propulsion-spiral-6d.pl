#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 6D Deep Space Trajectory: Low-Thrust Ion Propulsion Continuous Spiral
# ============================================================================
# Deep space probes (e.g. NASA Dawn, ESA SMART-1, BepiColombo) utilize continuous
# low-thrust electric/ion propulsion (gridded Xenon ion thrusters or Hall thrusters)
# rather than impulsive chemical burns.
#
# The spacecraft executes hundreds of continuous spiral revolutions as its 6D
# orbital state evolves:
#   S(t) = [r(t), theta(t), z(t), v_r(t), v_theta(t), v_z(t)] in R^6
#
# Electric Propulsion Dynamics:
#   - Thrust: T = 180 mN (0.180 N) continuous micro-thrust.
#   - Specific Impulse: Isp = 3200 s (Exhaust velocity c = Isp * g0 = 31,381 m/s).
#   - Mass Depletion: dm/dt = - T / (Isp * g0) = -5.736e-6 kg/s (-0.495 kg/day).
#   - Thrust Acceleration (increases as propellant is consumed):
#       a_thrust(t) = T / m(t)   [m / s^2]
#   - Orbital Velocity:
#       v_theta(t) ~ sqrt( mu_Earth / r(t) )
#     (As the spacecraft spirals outward, orbital velocity paradoxical drops
#      while total mechanical orbital energy increases!)
#   - Radial Climb Rate:
#       v_r(t) = dr / dt = 2 * a_thrust(t) * sqrt( r(t)^3 / mu_Earth )
#
# This example demonstrates:
#   1. Modeling a 180-day LEO-to-GEO spiral trajectory in 6D state space.
#   2. Deriving radial velocity v_r(t) = dr/dt via derivative().
#   3. Integrating continuous acceleration a(t) via integrate() to compute
#      cumulative mission Delta-V and verifying against the Tsiolkovsky equation.
#   4. Tracking 6D state coordinates [r, theta, z, v_r, v_theta, v_z].
#   5. Rendering an ASCII multi-ring orbital spiral map.
# ============================================================================

my $mission_days = 180.0; # 180-day continuous transfer
my $pi           = 4.0 * atan2(1, 1);
my $mu_earth     = 398600.4418; # km^3 / s^2
my $g0           = 9.80665;     # m/s^2

# Spacecraft Propulsion Parameters
my $m0       = 1200.0; # Initial wet mass (kg)
my $thrust_n = 0.220;  # 220 mN (0.220 N)
my $isp      = 3300.0; # 3300 seconds specific impulse
my $c_ex     = $isp * $g0; # 32,362 m/s exhaust velocity
my $mdot_day = ($thrust_n / $c_ex) * 86400.0; # ~0.587 kg/day

# 1. 6D Trajectory Waypoints across 180-day spiral
# r: 7000 km (LEO: 622km alt) -> 42164 km (Geostationary Orbit GEO)
my @t_wps = (  0.0,  45.0,  90.0, 135.0, 180.0);
my @r_wps = ( 7000.0, 11500.0, 18500.0, 28500.0, 42164.0); # km radius
my @z_wps = (    0.0,   350.0,  1200.0,  2100.0,     0.0); # km out-of-plane inclination damping

my $spline_r = spline(\@t_wps, \@r_wps, segments => 64, is_hold => 1);
my $spline_z = spline(\@t_wps, \@z_wps, segments => 64, is_hold => 1);

# 2. Differentiate Radius to Calculate Radial Velocity v_r(t) = dr/dt (km/s)
# Convert days to seconds: 1 day = 86400 seconds
my $dr_dt_days = $spline_r->derivative;

# 3. Mass and Thrust Acceleration Envelopes
my (@t_eval, @acc_samples, @mass_samples);
my $dt_days = 1.0;

for (my $t = 0; $t <= $mission_days; $t += $dt_days) {
    push @t_eval, $t;

    my $m = $m0 - $mdot_day * $t;
    push @mass_samples, $m;

    # Acceleration in m/s^2: a = T / m
    my $a = $thrust_n / $m;
    push @acc_samples, $a;
}

my $mass_env = from_samples(\@mass_samples, $mission_days, is_hold => 1);
my $acc_env  = from_samples(\@acc_samples,  $mission_days, is_hold => 1);

# 4. Integrate Acceleration to Obtain Cumulative Mission Delta-V (m/s)
my $acc_integral = $acc_env->integrate;
# Convert days to seconds: total Delta-V = integral * 86400
my $total_delta_v = $acc_integral->at($mission_days) * 86400.0;

# Theoretical Tsiolkovsky Delta-V: c * ln(m0 / mf)
my $mf = $m0 - $mdot_day * $mission_days;
my $tsiolkovsky_dv = $c_ex * log($m0 / $mf);
my $xenon_burned = $m0 - $mf;

print "=" x 76, "\n";
print "  6D Deep Space Trajectory: Continuous Low-Thrust Ion Propulsion Spiral\n";
print "=" x 76, "\n";
printf "Mission Profile : LEO (r=7,000 km) to GEO (r=42,164 km) Orbit Raising\n";
printf "Ion Engine      : Thrust = %.0f mN | Isp = %.0f s | Exhaust Speed = %5.0f m/s\n",
    $thrust_n * 1000.0, $isp, $c_ex;
printf "Propellant Mass : Initial = %5.1f kg | Xenon Fuel Burned = %5.1f kg (Final = %5.1f kg)\n",
    $m0, $xenon_burned, $mf;
print "-" x 76, "\n";
printf "Cumulative Delta-V (Integrated via integrate()): %6.1f m/s\n", $total_delta_v;
printf "Tsiolkovsky Analytical Delta-V Benchmark       : %6.1f m/s (Error: %.2f%%)\n",
    $tsiolkovsky_dv, abs($total_delta_v - $tsiolkovsky_dv) / $tsiolkovsky_dv * 100.0;
print "-" x 76, "\n";

# 5. 6D State Telemetry Table [r, theta, z, v_r, v_theta, v_z]
print "6D Spatiotemporal State Vector Across 180-Day Spiral Transfer:\n";
printf "%-7s | %-10s | %-7s | %-8s | %-9s | %-9s | %s\n",
    "Time", "Radius r", "Mass(kg)", "Acc(mm/s²)", "v_r(m/s)", "v_orb(km/s)", "Spiral Expansion Bar";
print "-" x 76, "\n";

my $bar_w = 18;
for (my $t = 0.0; $t <= $mission_days; $t += 15.0) {
    my $r = $spline_r->at($t);
    my $m = $mass_env->at($t);
    my $a = $acc_env->at($t) * 1000.0; # to mm/s^2

    # Radial climb rate v_r = dr/dt (km/day -> m/s)
    my $vr_m_s = ($dr_dt_days->at($t) * 1000.0) / 86400.0;

    # Tangential orbital speed v_theta = sqrt(mu / r) in km/s
    my $v_orb = sqrt($mu_earth / $r);

    # Bar tracking orbital radius [7000 km to 42164 km]
    my $pos = int(($r - 7000.0) / (42164.0 - 7000.0) * ($bar_w - 1));
    $pos = 0 if $pos < 0; $pos = $bar_w - 1 if $pos >= $bar_w;
    my $bar = ('=' x ($pos + 1)) . ('.' x ($bar_w - 1 - $pos));

    printf "Day %4.0f| %8.1fkm | %6.1f | %6.3f   | %6.2f m/s| %6.3f km/s| [%s]\n",
        $t, $r, $m, $a, $vr_m_s, $v_orb, $bar;
}
print "-" x 76, "\n";

# 6. ASCII Spiral Polar Projection
print "\n2D Polar Projection of Multi-Revolution Outward Spiral [LEO -> GEO]:\n";
print "Scale: Center Earth (+) to Outer Ring GEO (r = 42,164 km):\n";

my @spiral_ascii = (
    "           . . . . - - - - - - - - . . . .           <- GEO (r = 42,164 km)",
    "       . '           . - - - .           ' .         ",
    "     /           / '           ' \\           \\       ",
    "    /          /       . - .       \\          \\      ",
    "   |          |      /   *   \\      |          |     <- Intermediate Spiral Rings",
    "   |          |     |  (LEO)  |     |          |     ",
    "   |          |      \\   +   /      |          |     <- Earth Center (+)",
    "    \\          \\       ' - '       /          /      ",
    "     \\           \\ .           . /           /       ",
    "       . '           ' - - - '           ' .         ",
    "           . . . . - - - - - - - - . . . .           ",
);
print "$_\n" for @spiral_ascii;

print "=" x 76, "\n";
print "Summary: spline() models continuous 6D orbital spirals in R⁶; derivative()\n";
print "yields instantaneous climb rates, and integrate() verifies mission Delta-V.\n";
print "=" x 76, "\n";
