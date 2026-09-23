#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline from_samples);

# ============================================================================
# 4D Spacecraft Reentry Trajectory: Aerothermodynamic Flight Corridor
# ============================================================================
# In atmospheric entry engineering (e.g. Apollo, Space Shuttle, Orion, SpaceX
# Dragon), a spacecraft returning from orbit must navigate a narrow 4D flight
# corridor: 3D spatial position [X(t), Y(t), Altitude Z(t)] over time t.
#
# The 4th dimension represents the extreme thermal and aeromechanical environment:
#   1. Stagnation-point convective heat flux:
#        q_dot(t) = k * sqrt(rho(Z) / R_nose) * v(t)^3   [kW / m^2]
#      (Sutton-Graves relation for hypersonic atmospheric entry)
#   2. Dynamic pressure and aerodynamic deceleration:
#        q_inf(t) = 0.5 * rho(Z) * v(t)^2   [kPa]
#        a_decel(t) = -dv/dt   [G-load]
#
# Flight Corridor Constraints:
#   - Overshoot Boundary (Too shallow): Spacecraft skips off upper atmosphere
#     back into deep space; orbital decay lifetime exceeds oxygen reserves.
#   - Undershoot Boundary (Too steep): Aerodynamic G-load exceeds crew limit
#     (>10 G) or heat flux exceeds thermal protection tile melting point (>1500 kW/m^2).
#
# This example demonstrates:
#   1. Constructing a 3D reentry trajectory [X, Y, Altitude Z] via spline().
#   2. Deriving 3D velocity components and speed v(t) = ||v|| via derivative().
#   3. Evaluating atmospheric density rho(z) and Sutton-Graves heat flux q_dot(t).
#   4. Integrating cumulative thermal heat load Q_total = \int q_dot dt via
#      integrate() to size ceramic ablation heatshield thickness.
#   5. Visualizing the 4D entry corridor with an ASCII altitude vs speed chart.
# ============================================================================

my $duration = 800.0; # Total entry duration: 800 seconds (13.3 minutes)

# 1. 3D Spatial Trajectory Waypoints:
# Downrange X (km), Cross-range Y (km), Altitude Z (km) from Entry Interface (EI: 120km)
# down to drogue parachute deployment (15km).
my @t_wps = (  0.0, 150.0, 320.0, 480.0, 620.0, 720.0, 800.0);
my @x_wps = (  0.0, 1150.0, 2400.0, 3400.0, 4100.0, 4500.0, 4525.0); # km downrange
my @y_wps = (  0.0,   35.0,   85.0,  110.0,   90.0,   45.0,   15.0); # km cross-range
my @z_wps = (120.0,   85.0,   68.0,   52.0,   36.0,   22.0,   15.0); # km altitude

my $spline_x = spline(\@t_wps, \@x_wps, segments => 64, is_hold => 1);
my $spline_y = spline(\@t_wps, \@y_wps, segments => 64, is_hold => 1);
my $spline_z = spline(\@t_wps, \@z_wps, segments => 64, is_hold => 1);

# 2. Differentiate 3D Coordinates to Calculate Velocity Components (km/s -> m/s)
my $vx_env = $spline_x->derivative;
my $vy_env = $spline_y->derivative;
my $vz_env = $spline_z->derivative;

# Physical parameters for Earth atmosphere and spacecraft
my $rho_0     = 1.225;     # Sea-level atmospheric density (kg/m^3)
my $h_scale   = 7.5;       # Atmospheric scale height (km)
my $r_nose    = 1.5;       # Spacecraft nose radius (meters)
my $k_sutton  = 1.74e-4;   # Sutton-Graves constant (W*s^3 / (m^3.5 * kg^0.5))
my $g0        = 9.80665;   # Standard gravity (m/s^2)

my $dt = 5.0; # 5-second sampling
my (@t_eval, @v_speed, @heat_flux, @g_loads, @dyn_pressure);

for (my $t = 0; $t <= $duration; $t += $dt) {
    push @t_eval, $t;

    # Velocity components in m/s (coordinates are in km, so * 1000)
    my $vx = $vx_env->at($t) * 1000.0;
    my $vy = $vy_env->at($t) * 1000.0;
    my $vz = $vz_env->at($t) * 1000.0;
    my $v = sqrt($vx * $vx + $vy * $vy + $vz * $vz);
    push @v_speed, $v;

    # Altitude in km
    my $alt_km = $spline_z->at($t);
    $alt_km = 0.1 if $alt_km < 0.1;

    # Exponential barometric atmospheric density: rho(z) = rho0 * exp(-z / H)
    my $rho = $rho_0 * exp(-$alt_km / $h_scale);

    # Hypersonic convective stagnation heat flux (kW/m^2)
    # q_dot = k * sqrt(rho / R_nose) * v^3 / 1000
    my $q_dot = ($k_sutton * sqrt($rho / $r_nose) * ($v ** 3)) / 1000.0; # kW/m^2
    push @heat_flux, $q_dot;

    # Dynamic pressure q_inf = 0.5 * rho * v^2 / 1000 (kPa)
    my $q_inf = (0.5 * $rho * ($v ** 2)) / 1000.0;
    push @dyn_pressure, $q_inf;
}

my $v_env    = from_samples(\@v_speed,   $duration, is_hold => 1);
my $flux_env = from_samples(\@heat_flux, $duration, is_hold => 1);
my $qinf_env = from_samples(\@dyn_pressure, $duration, is_hold => 1);

# Compute deceleration G-load: a = -dv/dt / g0
my $dv_env = $v_env->derivative;
for (my $i = 0; $i < @t_eval; $i++) {
    my $t = $t_eval[$i];
    my $decel = -$dv_env->at($t);
    my $g_load = ($decel > 0) ? ($decel / $g0) : 0.0;
    push @g_loads, $g_load;
}
my $g_env = from_samples(\@g_loads, $duration, is_hold => 1);

# 3. Integrate Heat Flux to Calculate Total Thermal Heat Load (MJ/m^2)
# Q_total = \int q_dot(t) dt
my $q_integral_env = $flux_env->integrate; # Area under kW/m^2 curve in (kW * s / m^2 = kJ / m^2)
my $total_heat_kj = $q_integral_env->at($duration);
my $total_heat_mj = $total_heat_kj / 1000.0;

# Find peaks
my $peak_flux = 0; my $peak_flux_t = 0;
my $peak_g    = 0; my $peak_g_t    = 0;
my $peak_qinf = 0; my $peak_qinf_t = 0;

for (my $t = 0; $t <= $duration; $t += 1.0) {
    my $q = $flux_env->at($t);
    if ($q > $peak_flux) { $peak_flux = $q; $peak_flux_t = $t; }

    my $g = $g_env->at($t);
    if ($g > $peak_g) { $peak_g = $g; $peak_g_t = $t; }

    my $qp = $qinf_env->at($t);
    if ($qp > $peak_qinf) { $peak_qinf = $qp; $peak_qinf_t = $t; }
}

# Thermal protection sizing: LI-900 silica tile ablation requirement
# Tile density ~ 144 kg/m^3, heat capacity cp ~ 1250 J/(kg*K), allowable delta T = 1200 K
my $tile_thickness_mm = ($total_heat_mj * 1e6) / (144.0 * 1250.0 * 1200.0) * 1000.0;

print "=" x 76, "\n";
print "  4D Spacecraft Atmospheric Reentry: Thermal Protection & Corridor Analysis\n";
print "=" x 76, "\n";
printf "Entry Interface: Alt = 120.0 km | Initial Speed = %5.0f m/s (Mach %.1f)\n",
    $v_env->at(0), $v_env->at(0) / 300.0;
printf "Landing Drogue  : Alt = %5.1f km | Terminal Speed= %5.0f m/s | Time = %4.0fs\n",
    $spline_z->at($duration), $v_env->at($duration), $duration;
print "-" x 76, "\n";
printf "Peak Convective Heat Flux: %6.1f kW/m²  at t=%4.0fs (Alt: %4.1f km, v: %4.0f m/s)\n",
    $peak_flux, $peak_flux_t, $spline_z->at($peak_flux_t), $v_env->at($peak_flux_t);
printf "Peak Aerodynamic Decel   : %6.2f G        at t=%4.0fs (Crew Limit: 10.0 G Safe)\n",
    $peak_g, $peak_g_t;
printf "Peak Dynamic Pressure    : %6.1f kPa      at t=%4.0fs (Max-Q)\n",
    $peak_qinf, $peak_qinf_t;
printf "Cumulative Heat Energy Q : %6.1f MJ/m²    (Integrated via integrate())\n",
    $total_heat_mj;
printf "Ablative Shield Sizing   : %6.1f mm       (Required High-Temp Tile Thickness)\n",
    $tile_thickness_mm;
print "-" x 76, "\n";

# 4. ASCII 4D Trajectory Telemetry Table
print "\n4D Reentry Telemetry: [X, Y, Z, Heat Flux q(t)] Along Flight Corridor:\n";
print "Time   | Alt Z (km) | Downrange | Speed (m/s) | Decel (G) | Heat Flux  | Corridor Heat Bar\n";
print "-" x 76, "\n";

my $bar_width = 20;
for (my $t = 0; $t <= $duration; $t += 40.0) {
    my $alt   = $spline_z->at($t);
    my $x_km  = $spline_x->at($t);
    my $v     = $v_env->at($t);
    my $g     = $g_env->at($t);
    my $flux  = $flux_env->at($t);

    my $b_len = int(($flux / $peak_flux) * ($bar_width - 1));
    $b_len = 0 if $b_len < 0; $b_len = $bar_width - 1 if $b_len >= $bar_width;
    my $bar = ('#' x ($b_len + 1)) . ('.' x ($bar_width - 1 - $b_len));

    printf "%4.0fs  |  %5.1f km  | %5.0f km  |  %5.0f m/s  |  %4.1f G   | %5.0f kW/m²| [%s]\n",
        $t, $alt, $x_km, $v, $g, $flux, $bar;
}
print "=" x 76, "\n";
print "Summary: spline() shapes 3D orbital descent paths; derivative() computes\n";
print "entry velocity/G-forces, and integrate() sizes heatshield thermal mass.\n";
print "=" x 76, "\n";
