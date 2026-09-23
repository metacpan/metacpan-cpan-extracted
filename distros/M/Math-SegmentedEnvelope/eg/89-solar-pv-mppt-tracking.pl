#!/usr/bin/env perl
# Solar Photovoltaic (PV) I-V / P-V Curves & Maximum Power Point Tracking (MPPT)
# Demonstrates:
#   1. Modeling non-linear semiconductor solar cell I-V diode characteristics
#   2. Generating the Power curve P(V) = V · I(V) via envelope transformation
#   3. Using derivative() (dP/dV = 0) for incremental conductance MPPT tracking
#   4. Partial shading bypass-diode curve & ASCII MPPT power peak visualizer
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Commercial 400W Monocrystalline PV Module specs (STC: 1000 W/m², 25°C):
#   Open-Circuit Voltage (Voc)  : 48.0 V
#   Short-Circuit Current (Isc) : 10.5 A
#   MPP Voltage (Vmpp)          : 40.0 V
#   MPP Current (Impp)          :  9.6 A -> Pmax = 384 Watts

# 1. Unshaded I-V Curve (Current I in Amperes as a function of Voltage V in [0, 48] Volts)
#   0V to 36V: nearly flat current (10.5A -> 10.1A)
#   36V to 42V: exponential diode knee (10.1A -> 8.5A)
#   42V to 48V: rapid plunge to 0A at Voc
my $iv_unshaded = env([
    [10.5, 10.1, 8.5, 0.0],
    [36.0,  6.0, 6.0],
    [1.0,  -2.5, 2.0]
], is_hold => 1);

# 2. Partially Shaded I-V Curve (Bypass diodes conduct, creating double knee!)
#   Half module in shade (5.2A current limit) + unshaded half (10.5A)
my $iv_shaded = env([
    [10.5, 10.0, 5.5, 5.2, 5.0, 0.0],
    [18.0,  3.0, 3.0, 15.0, 9.0],
    [1.0,  -2.0, 2.0, 1.0,  2.5]
], is_hold => 1);

# Generate continuous Power Envelopes P(V) = V * I(V)
sub make_power_envelope {
    my ($iv_env) = @_;
    my $steps = 96;
    my $voc = $iv_env->duration; # 48V
    my $dv = $voc / $steps;

    my @p_vals;
    for my $i (0 .. $steps) {
        my $v = $i * $dv;
        my $i_curr = $iv_env->at($v);
        my $p = $v * $i_curr;
        push @p_vals, $p;
    }
    my @durs = ($dv) x $steps;
    my @curves = (1.0) x $steps;
    return env([\@p_vals, \@durs, \@curves], is_hold => 1);
}

my $p_unshaded = make_power_envelope($iv_unshaded);
my $p_shaded   = make_power_envelope($iv_shaded);

# Differentiate Power: dP/dV
# At the Maximum Power Point (MPP), dP/dV = 0!
my $dp_unshaded = $p_unshaded->derivative;
my $dp_shaded   = $p_shaded->derivative;

print "=" x 74, "\n";
print "  Solar Photovoltaic (PV) I-V / P-V Modeling & MPPT Derivative Tracking\n";
print "=" x 74, "\n";
printf "PV Panel: 400W Monocrystalline | Voc: 48.0V | Isc: 10.5A | Vmpp: ~40V\n";
print "-" x 74, "\n";

# Solve for MPP using derivative dP/dV zero-crossing
sub find_mpp {
    my ($p_env, $dp_env) = @_;
    my $mpp_v = 0.0;
    my $mpp_p = 0.0;
    for (my $v = 1.0; $v <= 47.0; $v += 0.2) {
        my $p = $p_env->at($v);
        if ($p > $mpp_p) {
            $mpp_p = $p;
            $mpp_v = $v;
        }
    }
    return ($mpp_v, $mpp_p, $dp_env->at($mpp_v));
}

my ($mpp_v1, $mpp_p1, $slope1) = find_mpp($p_unshaded, $dp_unshaded);
my ($mpp_v2, $mpp_p2, $slope2) = find_mpp($p_shaded, $dp_shaded);

printf "Unshaded Condition: Optimal MPP = %4.1f V | Peak Power = %5.1f W (dP/dV = %+5.2f)\n",
    $mpp_v1, $mpp_p1, $slope1;
printf "Partially Shaded  : Global  MPP = %4.1f V | Peak Power = %5.1f W (dP/dV = %+5.2f)\n",
    $mpp_v2, $mpp_p2, $slope2;
print "-" x 74, "\n";

# ASCII P-V (Power vs Voltage) Curve Comparison
print "Power vs Voltage P(V) Sweep [0V to 48V]:\n";
printf "%-6s | %-8s | %-8s | %s\n",
    "Volt", "P_unshade", "P_shaded", "Power Curve Graph [0W -> 400W]";
print "-" x 74, "\n";

my $chart_w = 32;
for (my $v = 0; $v <= 48.1; $v += 3.0) {
    my $p1 = $p_unshaded->at($v);
    my $p2 = $p_shaded->at($v);

    my $bar1 = int(($p1 / 400.0) * ($chart_w - 1));
    my $bar2 = int(($p2 / 400.0) * ($chart_w - 1));
    $bar1 = 0 if $bar1 < 0; $bar1 = $chart_w - 1 if $bar1 >= $chart_w;
    $bar2 = 0 if $bar2 < 0; $bar2 = $chart_w - 1 if $bar2 >= $chart_w;

    my $line = " " x $chart_w;
    substr($line, $bar2, 1) = ":"; # shaded
    substr($line, $bar1, 1) = "*"; # unshaded

    my $marker = "";
    if (abs($v - $mpp_v1) < 1.6) { $marker = "<- MPP Unshaded" }
    elsif (abs($v - $mpp_v2) < 1.6) { $marker = "<- MPP Shaded" }

    printf "%4.1f V | %5.1f W  | %5.1f W  | [%s] %s\n",
        $v, $p1, $p2, $line, $marker;
}

print "-" x 74, "\n";
print "Incremental Conductance MPPT Inverter State:\n";
printf "  At V = 30.0V : dP/dV = %+5.2f W/V -> Action: INCREASE Voltage (Perturb +)\n",
    $dp_unshaded->at(30.0);
printf "  At V = 40.0V : dP/dV = %+5.2f W/V -> Action: LOCKED at Maximum Power Point (MPP)\n",
    $dp_unshaded->at(40.0);
printf "  At V = 45.0V : dP/dV = %+5.2f W/V -> Action: DECREASE Voltage (Perturb -)\n",
    $dp_unshaded->at(45.0);
print "=" x 74, "\n";
