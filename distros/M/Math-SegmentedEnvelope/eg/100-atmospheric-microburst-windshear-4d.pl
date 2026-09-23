#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 4D Atmospheric Microburst: Wind Shear Hazard & F-Factor Energy Analysis
# ============================================================================
# Low-altitude convective microbursts are among the most lethal aviation hazards
# (e.g. Delta 191 at DFW). A thunderstorm downdraft column plummets toward
# the ground and spreads outward in a high-velocity radial vortex ring.
#
# An airliner on an ILS final approach (3-degree glideslope) penetrates a
# 4D spatiotemporal wind vector field: W(X, Y, Z, t) = [u_wind(t), v_wind(t), w_wind(t)].
#
# Canonical 3-Phase Microburst Encounter:
#   Phase 1 (Outflow Entry): Strong headwind (+15 m/s / +30 kts). Airspeed increases;
#            aircraft pitches up / balloons above glideslope. Pilot retards thrust.
#   Phase 2 (Core Penetration): Severe downdraft (w_wind ~ -12 m/s / -2400 fpm).
#            Sink rate spikes; aircraft begins plummeting.
#   Phase 3 (Outflow Exit): Rapid transition to severe tailwind (-20 m/s / -40 kts).
#            Airspeed drops catastrophically by >35 kts; aircraft enters high-sink
#            stall condition short of the runway.
#
# NASA / FAA F-Factor Wind Shear Hazard Metric:
#   F(t) = - (1 / g) * (d u_wind / dt) + ( |w_wind(t)| / V_TAS )
#   - First term: inertial loss of airspeed due to tailwind shear.
#   - Second term: downdraft downdraft angle robbing climb gradient.
#   - FAA Threshold: F >= 0.13 triggers mandatory reactive windshear warning (TOGA escape).
#
# This example demonstrates:
#   1. Modeling 3D aircraft nominal approach path [X, Y, Z] via spline().
#   2. Constructing the 4D microburst wind field [u_wind, w_wind] across the flight path.
#   3. Differentiating horizontal wind via derivative() to compute shear acceleration du/dt.
#   4. Evaluating instantaneous F-factor and aircraft energy loss.
#   5. Integrating sink rate via integrate() to compute glideslope altitude deviation.
#   6. Rendering an ASCII vertical flight path profile with cockpit warning flags.
# ============================================================================

my $duration = 30.0; # 30-second approach window through microburst core
my $g0       = 9.80665; # Gravity (m/s^2)
my $v_nom    = 70.0;    # Nominal approach true airspeed: 70 m/s (~136 knots)

# 1. 3D Aircraft Approach Path (3-Degree Glideslope down to Runway Threshold)
# Distance to threshold X (2100m to 0m), Runway Centerline Y (0m), Altitude Z (110m to 0m)
my @t_wps = (   0.0,   10.0,   20.0,   30.0);
my @x_wps = (2100.0, 1400.0,  700.0,    0.0); # meters
my @y_wps = (   0.0,    0.0,    0.0,    0.0); # on centerline
my @z_wps = ( 110.0,   73.3,   36.7,    0.0); # 3-degree nominal slope (-3.67 m/s sink)

my $spline_x = spline(\@t_wps, \@x_wps, segments => 32, is_hold => 1);
my $spline_z = spline(\@t_wps, \@z_wps, segments => 32, is_hold => 1);

# 2. 4D Microburst Wind Field Components along Flight Path
# Horizontal wind u_wind(t): +15 m/s (headwind) -> 0 -> -18 m/s (severe tailwind)
# Transition across core (t = 8s to 24s)
my $env_u_wind = Math::SegmentedEnvelope->new(
    [[0.0, 15.0, 12.0, -18.0, -10.0], [8.0, 4.0, 12.0, 6.0], [1, 1, 1, 1]],
    is_hold => 1,
);

# Vertical wind w_wind(t): 0 m/s -> downburst -7.5 m/s at core (t = 12s to 18s) -> 0
my $env_w_wind = Math::SegmentedEnvelope->new(
    [[0.0, -1.5, -7.5, -2.0, 0.0], [8.0, 5.0, 7.0, 10.0], [1, -1, 1, 1]],
    is_hold => 1,
);

# 3. Differentiate Horizontal Wind to Obtain Wind Shear Acceleration (du/dt)
my $du_env = $env_u_wind->resample(40)->derivative;

# 4. Compute F-Factor, Airspeed, and Altitude Deviation
my $dt = 0.2;
my (@t_eval, @f_factors, @tas_eval, @alt_deviations);
my $peak_f = 0; my $peak_f_t = 0;
my $max_shear = 0;

for (my $t = 0; $t <= $duration; $t += $dt) {
    push @t_eval, $t;

    my $u = $env_u_wind->at($t);
    my $w = $env_w_wind->at($t);
    my $du = $du_env->at($t); # wind acceleration

    # Aircraft indicated airspeed with lagged engine response
    my $tas = $v_nom + $u * 0.8;
    push @tas_eval, $tas;

    # NASA/FAA F-factor: F = -(du/dt)/g + |w|/tas
    # (du/dt < 0 when transitioning to tailwind, so -(du/dt) is positive hazard)
    my $shear_term = -$du / $g0;
    my $down_term  = abs($w) / $tas;
    my $f = $shear_term + $down_term;
    $f = 0.0 if $f < 0.0;
    push @f_factors, $f;

    if ($f > $peak_f) {
        $peak_f = $f;
        $peak_f_t = $t;
    }
    my $abs_du = abs($du);
    $max_shear = $abs_du if $abs_du > $max_shear;
}

my $f_env   = from_samples(\@f_factors, $duration, is_hold => 1);
my $tas_env = from_samples(\@tas_eval,  $duration, is_hold => 1);

# Compute glideslope altitude deviation: integrate vertical downdraft sink
my $w_integral = $env_w_wind->integrate;

print "=" x 76, "\n";
print "  4D Atmospheric Microburst: Wind Shear Hazard & NASA F-Factor Telemetry\n";
print "=" x 76, "\n";
printf "Aircraft: Transport Category Jet | Nominal Airspeed: %.0f m/s (%.0f kts)\n",
    $v_nom, $v_nom * 1.94384;
printf "Microburst Core: Peak Downdraft = %4.1f m/s (%.0f fpm) | Max Tailwind = %4.1f m/s\n",
    7.5, 7.5 * 196.85, 18.0;
print "-" x 76, "\n";
printf "Peak F-Factor Hazard Index : %5.3f at t=%4.1fs (FAA Warning Alert Level: >= 0.130)\n",
    $peak_f, $peak_f_t;
printf "Peak Horizontal Wind Shear : %5.2f m/s² (%.1f kts/s)\n",
    $max_shear, $max_shear * 1.94384;
printf "Maximum Glideslope Altitude Sink Loss: %5.1f meters (Ground Proximity Warning)\n",
    abs($w_integral->at($duration));
print "-" x 76, "\n";

# 5. Telemetry Table Across Microburst Passage
print "\nSpatiotemporal Approach Telemetry & Cockpit Hazard Warnings:\n";
print "Time   | Nom Alt | True Alt | Airspeed | Horiz Wind | Downdraft  | F-Factor | Annunciator\n";
print "-" x 76, "\n";

for (my $t = 0.0; $t <= $duration; $t += 2.0) {
    my $nom_z = $spline_z->at($t);
    my $z_drop = abs($w_integral->at($t));
    my $act_z = $nom_z - $z_drop;
    $act_z = 0.0 if $act_z < 0.0;

    my $tas  = $tas_env->at($t) * 1.94384; # to knots
    my $u_w  = $env_u_wind->at($t) * 1.94384;
    my $w_w  = $env_w_wind->at($t) * 196.85; # to feet/min
    my $f    = $f_env->at($t);

    my $alert = ($f >= 0.130) ? "[WINDSHEAR! TOGA]" :
                ($f >= 0.080) ? "[CAUTION SHEAR ]" :
                                "[NORMAL APPROACH]";

    printf "%4.1fs  | %5.1fm  |  %5.1fm | %4.0f kts | %+5.0f kts  | %+5.0f fpm |  %5.3f   | %s\n",
        $t, $nom_z, $act_z, $tas, $u_w, $w_w, $f, $alert;
}
print "-" x 76, "\n";

# 6. ASCII Approach Profile Cross-Section
print "\nGlideslope Cross-Section: [Nominal 3° Slope vs Microburst Sink Path]:\n";
print "Altitude [0 to 120m]:\n";

my @cross_section = (
    "  Z=110m | *                                  <- Initial Entry (+31 kts headwind)",
    "  Z=90m  |   \\*                               ",
    "  Z=70m  |     \\   *                          <- Ballooning above glideslope",
    "  Z=50m  |       \\   .                        ",
    "  Z=30m  |         \\   . * *                  <- Core Downdraft: -2460 fpm sink!",
    "  Z=10m  |           \\       * *              <- Outflow Exit: F=0.20 [STALL HAZARD]",
    "  Z=0m   | -----------+-----------*----+----  <- Near Ground Impact Short of Runway!",
    "          Threshold   X=700m    X=1400m X=2100m",
);
print "$_\n" for @cross_section;

print "=" x 76, "\n";
print "Summary: SegmentedEnvelope constructs 4D atmospheric wind vector fields;\n";
print "derivative() evaluates wind shear rate, and integrate() calculates energy loss.\n";
print "=" x 76, "\n";
