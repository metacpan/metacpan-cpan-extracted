#!/usr/bin/env perl
# Hydraulic Pipeline Water Hammer & Cushioned Valve Closure Optimization
# Demonstrates:
#   1. Fluid pipeline Joukowsky pressure surge modeling: ΔP = -ρ·L·(dv/dt)
#   2. Using derivative() to calculate instantaneous flow deceleration
#   3. Comparing abrupt linear valve shutoff vs 2-stage cushioned closure
#   4. Multi-trace ASCII pipeline pressure surge comparison
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Pipeline Physical Specifications:
# Pipe Length L = 600m, Sonic Wave Velocity c = 1200 m/s
# Water density rho = 1000 kg/m³, Base working pressure P0 = 4.0 bar (400 kPa)
# Initial flow velocity v0 = 2.5 m/s
my $pipe_len  = 600.0;   # meters
my $wave_spd  = 1200.0;  # m/s
my $rho       = 1000.0;  # kg/m^3
my $p_base_bar= 4.0;     # bar
my $v0        = 2.5;     # m/s

# Critical pipeline reflection time: Tr = 2*L / c = 1.0 second
my $t_reflect = 2.0 * $pipe_len / $wave_spd; # 1.0s

# Closure Profile 1: Fast Linear Closure over 1.2 seconds (near critical time)
# Valve opening fraction A(t) from 1.0 (100% open) to 0.0 (closed)
my $valve_fast = env([
    [1.0, 0.0],
    [1.2],
    [1.0] # linear shutoff
], is_hold => 1);

# Closure Profile 2: Cushioned Two-Stage Closure over 3.5 seconds
#   Phase 1: Rapid closure from 100% to 15% open over 1.5s (bulk flow reduction)
#   Phase 2: Slow cushioned seat arrival from 15% to 0% over 2.0s (cushions final shock)
my $valve_cushioned = env([
    [1.0, 0.15, 0.0],
    [1.5, 2.0],
    [1.2, -1.8] # smooth curved transition into cushioned seating
], is_hold => 1);

# Flow velocity is proportional to valve opening: v(t) = v0 * A(t)
# Velocity envelopes in m/s:
my $vel_fast      = $valve_fast->scale($v0);
my $vel_cushioned = $valve_cushioned->scale($v0);

# Compute deceleration dv/dt using derivative()
my $acc_fast      = $vel_fast->derivative;
my $acc_cushioned = $vel_cushioned->derivative;

# Compute Water Hammer Surge Pressure:
#   ΔP(t) = -rho * L * (dv/dt) in Pascals
#   Total Pressure P(t) = P_base + ΔP / 100,000 (bar)
sub calc_pressure_bar {
    my ($acc_env, $t) = @_;
    my $dv_dt = $acc_env->at($t); # negative during closure
    my $delta_p_pa = -$rho * $pipe_len * $dv_dt;
    $delta_p_pa = 0.0 if $delta_p_pa < 0.0; # only positive compression surges
    return $p_base_bar + ($delta_p_pa / 100000.0);
}

print "=" x 74, "\n";
print "  Pipeline Hydraulic Water Hammer: Valve Deceleration & Surge Mitigation\n";
print "=" x 74, "\n";
printf "Pipe Length: %.0fm | Wave Speed: %.0fm/s | Reflection Period (2L/c): %.2fs\n",
    $pipe_len, $wave_spd, $t_reflect;
printf "Initial Flow: %.2fm/s | Static Pressure: %.1f bar | Fluid: Water (1000 kg/m³)\n",
    $v0, $p_base_bar;
print "-" x 74, "\n";

# Scan peak pressures across 4 seconds
my $sim_dur = 4.0;
my $peak_p_fast = 0.0;
my $peak_p_cush = 0.0;

for (my $t = 0; $t <= $sim_dur; $t += 0.05) {
    my $pf = calc_pressure_bar($acc_fast, $t);
    my $pc = calc_pressure_bar($acc_cushioned, $t);
    $peak_p_fast = $pf if $pf > $peak_p_fast;
    $peak_p_cush = $pc if $pc > $peak_p_cush;
}

printf "Unmitigated Fast Closure Peak Pressure : %5.1f bar (Burst Risk: HIGH!)\n", $peak_p_fast;
printf "Cushioned S-Curve Closure Peak Pressure: %5.1f bar (Safe Pipeline Operation)\n", $peak_p_cush;
printf "Surge Pressure Reduction              : %5.1f %%\n",
    (1.0 - ($peak_p_cush - $p_base_bar) / ($peak_p_fast - $p_base_bar)) * 100.0;
print "-" x 74, "\n";

# ASCII Pressure Surge Waveform Comparison
print "Pipeline Transient Pressure P(t) Comparison [0 to 4.0s]:\n";
printf "%-6s | %-10s | %-10s | %s\n",
    "Time", "Fast (bar)", "Cush (bar)", "Surge Bar [4 bar Base -> 20 bar Peak]";
print "-" x 74, "\n";

my $chart_w = 34;
for (my $t = 0.0; $t <= $sim_dur; $t += 0.2) {
    my $pf = calc_pressure_bar($acc_fast, $t);
    my $pc = calc_pressure_bar($acc_cushioned, $t);

    # Map [4.0 bar, 20.0 bar] to chart
    my $pos_f = int((($pf - 4.0) / 16.0) * ($chart_w - 1));
    my $pos_c = int((($pc - 4.0) / 16.0) * ($chart_w - 1));
    $pos_f = 0 if $pos_f < 0; $pos_f = $chart_w - 1 if $pos_f >= $chart_w;
    $pos_c = 0 if $pos_c < 0; $pos_c = $chart_w - 1 if $pos_c >= $chart_w;

    my $line = " " x $chart_w;
    substr($line, 0, 1) = "|"; # base 4 bar
    substr($line, $pos_c, 1) = "C"; # cushioned
    substr($line, $pos_f, 1) = "F"; # fast

    my $note = "";
    if (abs($pf - $peak_p_fast) < 0.1 && $t < 1.3) {
        $note = "<- Fast Valve Shock Peak!";
    }

    printf "%4.1fs  | %5.1f bar  | %5.1f bar  | [%s] %s\n",
        $t, $pf, $pc, $line, $note;
}

print "=" x 74, "\n";
print "Summary: Using derivative() on valve position envelopes allows pipeline\n";
print "engineers to shape valve actuators and eliminate destructive water hammer.\n";
print "=" x 74, "\n";
