#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 6D Astrodynamics: Keplerian Orbital Elements, J2 Perturbations & Station-Keeping
# ============================================================================
# In celestial mechanics and space mission design, a satellite's complete state
# in 6-dimensional phase space is defined by the 6 classical Keplerian elements:
#   1. a(t)    : Semi-major axis (orbit size, orbital energy) [km]
#   2. e(t)    : Eccentricity (orbit shape, circular e=0 vs elliptical)
#   3. i(t)    : Orbital inclination relative to equator [degrees]
#   4. RAAN(t) : Right Ascension of Ascending Node Omega (nodal orientation) [deg]
#   5. omega(t): Argument of Periapsis (orientation of ellipse in plane) [deg]
#   6. nu(t)   : True Anomaly (instantaneous angular position along orbit) [deg]
#
# Geopotential Perturbations (Earth Oblateness J2 = 1.08263e-3):
#   - Secular Nodal Precession:
#       dOmega / dt = - (3/2) * J2 * (R_E / p)^2 * n * cos(i)
#     (For Sun-Synchronous Orbits at i ~ 98.2°, dOmega/dt = +0.9856 deg/day,
#      matching Earth's orbital rate around the Sun to maintain constant solar lighting!)
#   - Apsidal Precession:
#       d_omega / dt = (3/4) * J2 * (R_E / p)^2 * n * (5*cos(i)^2 - 1)
#   - Thermospheric Drag Decay:
#       da / dt < 0 (orbital altitude loss over time)
#
# Station-Keeping Thruster Burn:
#   Autonomous orbit raising maneuver to restore semi-major axis:
#     Delta_v = 0.5 * v_orb * (Delta_a / a)   [m / s]
#
# This example demonstrates:
#   1. Propagating the 6D orbital state vector [a, e, i, Omega, omega, nu] over 30 days.
#   2. Modeling secular J2 nodal regression and atmospheric altitude decay.
#   3. Synthesizing a station-keeping re-boost maneuver using SegmentedEnvelope.
#   4. Integrating thruster acceleration via integrate() to compute total Delta-V.
#   5. Rendering an ASCII 6D orbital telemetry table and nodal precession tracker.
# ============================================================================

my $days_total = 30.0; # 30-day mission observation window
my $pi         = 4.0 * atan2(1, 1);
my $deg2rad    = $pi / 180.0;
my $rad2deg    = 180.0 / $pi;

# Earth physical constants
my $mu_earth   = 398600.4418; # km^3 / s^2 (Standard gravitational parameter)
my $r_earth    = 6378.137;   # km (Earth equatorial radius)
my $j2         = 1.08262668e-3;

# 1. Initial Orbit: Sun-Synchronous Earth Observation Satellite (e.g. Sentinel-2)
# Altitude h = 786 km => a = 7164 km, e = 0.001 (near circular), i = 98.5°
my $a0 = 7164.0; # km
my $e0 = 0.0012;
my $i0 = 98.50;  # degrees (retrograde Sun-sync)
my $omega_node0 = 45.0; # RAAN degrees
my $arg_per0    = 90.0; # Frozen orbit argument of perigee
my $nu0         = 0.0;  # True anomaly

# Unperturbed mean motion n (rad/s) and orbital period T (minutes)
my $n0 = sqrt($mu_earth / ($a0 ** 3));
my $period_min = (2.0 * $pi / $n0) / 60.0; # ~100.5 minutes per orbit

# J2 Secular Drift Rates (rad/s -> deg/day)
my $p0 = $a0 * (1.0 - $e0 * $e0);
my $factor = 1.5 * $j2 * (($r_earth / $p0) ** 2) * $n0;
my $raan_rate_deg_day = (-$factor * cos($i0 * $deg2rad)) * $rad2deg * 86400.0; # ~ +0.986 deg/day
my $apsidal_rate_deg_day = (0.5 * $factor * (5.0 * (cos($i0 * $deg2rad) ** 2) - 1.0)) * $rad2deg * 86400.0;

# Atmospheric drag altitude decay: -50 meters/day (-0.05 km/day)
my $decay_rate_km_day = 0.050;

# 2. Station-Keeping Re-Boost at Day 20: Restores 1.0 km altitude loss
# Modeled via SegmentedEnvelope for semi-major axis a(t)
my $env_a = Math::SegmentedEnvelope->new(
    [[$a0, $a0 - 20.0 * $decay_rate_km_day, $a0, $a0 - 10.0 * $decay_rate_km_day],
     [20.0, 0.5, 9.5],
     [1, 2, 1]],
    is_hold => 1,
);

# Thruster acceleration profile during re-boost burn (Day 20.0 to 20.5: 12-hour duty cycle)
# Thrust acceleration = 0.0012 m/s^2
my $env_thrust_acc = Math::SegmentedEnvelope->new(
    [[0.0, 0.0, 1.25e-3, 1.25e-3, 0.0, 0.0],
     [19.98, 0.02, 0.50, 0.02, 9.48],
     [1, 2, 1, -2, 1]],
    is_hold => 1,
);

# 3. Propagate 6D Keplerian Elements over 30 Days
my $dt_days = 0.5;
my (@t_days, @elem_a, @elem_e, @elem_i, @elem_raan, @elem_argp, @elem_nu);

for (my $t = 0.0; $t <= $days_total; $t += $dt_days) {
    push @t_days, $t;

    # 1. Semi-major axis a(t)
    my $a = $env_a->at($t);
    push @elem_a, $a;

    # 2. Eccentricity e(t): subtle drag circularization
    my $e = $e0 - 0.000005 * $t;
    push @elem_e, $e;

    # 3. Inclination i(t): minor solar-lunar gravitational wobble (+/- 0.02°)
    my $inc = $i0 + 0.02 * sin($t / 30.0 * 2.0 * $pi);
    push @elem_i, $inc;

    # 4. RAAN Omega(t): J2 Sun-synchronous nodal precession (+0.9856 deg/day)
    my $raan = ($omega_node0 + $raan_rate_deg_day * $t) % 360.0;
    push @elem_raan, $raan;

    # 5. Argument of perigee omega(t)
    my $argp = ($arg_per0 + $apsidal_rate_deg_day * $t) % 360.0;
    push @elem_argp, $argp;

    # 6. True anomaly nu(t) (modulo 360°)
    my $orbits = ($t * 86400.0) / (2.0 * $pi / $n0);
    my $nu = ($orbits * 360.0) % 360.0;
    push @elem_nu, $nu;
}

# Integrate thruster acceleration to compute cumulative Delta-V (m/s)
# Convert time from days to seconds for SI integration
my $dv_integral = $env_thrust_acc->integrate;
# Total Delta-V = area under acc curve * 86400 s/day
my $total_delta_v = $dv_integral->at($days_total) * 86400.0;

print "=" x 76, "\n";
print "  6D Astrodynamics: Keplerian Orbital Elements & Secular J2 Precession\n";
print "=" x 76, "\n";
printf "Mission Profile : Sun-Synchronous Earth Observation (Alt = %4.0f km, Period = %5.1f min)\n",
    $a0 - $r_earth, $period_min;
printf "J2 Nodal Drift  : %+5.4f deg/day (Required Solar Match = +0.9856 deg/day)\n",
    $raan_rate_deg_day;
printf "Apsidal Drift   : %+5.4f deg/day (Perigee Rotation)\n",
    $apsidal_rate_deg_day;
printf "Station-Keeping : Day 20.0 Autonomous Re-boost (Delta-V = %4.2f m/s)\n",
    $total_delta_v;
print "-" x 76, "\n";

# 4. 6D Orbital State Telemetry Table
print "6D Orbital State Vector [a, e, i, RAAN, arg_p, nu] across 30-Day Mission:\n";
printf "%-6s | %-9s | %-8s | %-7s | %-7s | %-7s | %-6s | %s\n",
    "Time", "a (km)", "e", "i (°)", "RAAN(°)", "argp(°)", "nu(°)", "RAAN Precession Bar";
print "-" x 76, "\n";

my $bar_w = 16;
for (my $t = 0.0; $t <= $days_total; $t += 2.5) {
    my $idx = int($t / $dt_days);
    my $a    = $elem_a[$idx];
    my $e    = $elem_e[$idx];
    my $inc  = $elem_i[$idx];
    my $raan = $elem_raan[$idx];
    my $argp = $elem_argp[$idx];
    my $nu   = $elem_nu[$idx];

    # Bar tracking RAAN precession [45° to 75°]
    my $pos = int(($raan - 45.0) / (75.0 - 45.0) * ($bar_w - 1));
    $pos = 0 if $pos < 0; $pos = $bar_w - 1 if $pos >= $bar_w;
    my $bar = ('.' x $pos) . 'O' . ('.' x ($bar_w - 1 - $pos));

    my $flag = ($t == 20.0) ? " [RE-BOOST BURN]" : "";

    printf "Day %4.1f| %7.2fkm | %6.4f | %5.2f° | %5.1f° | %5.1f° | %4.0f° | [%s]%s\n",
        $t, $a, $e, $inc, $raan, $argp, $nu, $bar, $flag;
}
print "=" x 76, "\n";
print "Summary: SegmentedEnvelope coordinates 6D Keplerian state evolution in R⁶;\n";
print "integrate() tallies station-keeping Delta-V fuel budget under J2 dynamics.\n";
print "=" x 76, "\n";
