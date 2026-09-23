#!/usr/bin/env perl
# IPC/JEDEC J-STD-020 Lead-Free Reflow Soldering Thermal Profile
# Demonstrates:
#   1. Complex multi-phase physical process modeling with segmented envelopes
#   2. Using derivative() to calculate instantaneous thermal ramp rates (°C/s)
#   3. Automated manufacturing tolerance verification and ASCII thermal plot
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Thermal phases (Temperature in °C, Duration in seconds):
# 1. Ramp to Soak:  25°C -> 150°C over 70s  (slope ~ 1.78 °C/s)
# 2. Soak/Preheat: 150°C -> 200°C over 90s  (slope ~ 0.55 °C/s)
# 3. Ramp to Peak: 200°C -> 245°C over 40s  (slope ~ 1.12 °C/s)
# 4. Peak Dwell:   245°C -> 245°C over 30s  (peak solder melt)
# 5. Fast Cool:    245°C -> 130°C over 60s  (slope ~ -1.92 °C/s)
# 6. Final Cool:   130°C ->  40°C over 45s  (slope ~ -2.00 °C/s)

my $profile = env([
    [25.0, 150.0, 200.0, 245.0, 245.0, 130.0, 40.0],
    [70.0, 90.0, 40.0, 30.0, 60.0, 45.0],
    [1.1, 0.9, 1.2, 1.0, -1.2, -1.0] # smooth transitions between heating zones
], is_hold => 1);

# Compute instantaneous ramp rate dT/dt (°C/s) using derivative()
my $ramp_rate = $profile->derivative;

my $total_time = $profile->duration;
my $liquidus_temp = 217.0; # Sn-Ag-Cu (SAC305) melting point

print "=" x 74, "\n";
print "  IPC/JEDEC J-STD-020 Lead-Free SMT Reflow Profile Simulation\n";
print "=" x 74, "\n";
printf "Total Oven Time: %.1f s (%.1f min) | Liquidus Threshold: %.1f °C\n",
    $total_time, $total_time / 60.0, $liquidus_temp;
print "-" x 74, "\n";

# Track metrics for JEDEC compliance
my $max_heat_rate = 0.0;
my $max_cool_rate = 0.0;
my $time_above_liquidus = 0.0;
my $soak_time = 0.0;
my $peak_temp = 0.0;

my $dt = 1.0; # 1 second steps
for (my $t = 0; $t <= $total_time; $t += $dt) {
    my $temp = $profile->at($t);
    my $rate = $ramp_rate->at($t);

    $peak_temp = $temp if $temp > $peak_temp;
    $max_heat_rate = $rate if $rate > $max_heat_rate;
    $max_cool_rate = -$rate if -$rate > $max_cool_rate;

    $time_above_liquidus += $dt if $temp >= $liquidus_temp;
    $soak_time += $dt if $temp >= 150.0 && $temp <= 200.0;
}

# ASCII Thermal Profile Curve
my $chart_w = 40;
my $chart_h = 14;
print "Temperature Profile & Ramp Rate Log:\n";
printf "%-7s | %-8s | %-9s | %s\n", "Time", "Temp(°C)", "dT/dt(°C/s)", "Thermal Curve [25°C -> 250°C]";
print "-" x 74, "\n";

my $steps = 22;
for my $i (0 .. $steps) {
    my $t = ($i / $steps) * $total_time;
    my $temp = $profile->at($t);
    my $rate = $ramp_rate->at($t);

    my $pos = int((($temp - 25.0) / (250.0 - 25.0)) * $chart_w);
    $pos = 0 if $pos < 0;
    $pos = $chart_w if $pos > $chart_w;

    my $line = " " x $chart_w;
    substr($line, $pos, 1) = ($temp >= $liquidus_temp) ? "#" : "*";

    # Liquidus marker
    my $liq_pos = int((($liquidus_temp - 25.0) / (250.0 - 25.0)) * $chart_w);
    if ($pos != $liq_pos) {
        substr($line, $liq_pos, 1) = "|";
    }

    printf "%4.0fs   | %6.1f °C | %+6.2f °C/s | [%s]\n",
        $t, $temp, $rate, $line;
}
print "-" x 74, "\n";

# Compliance Audit Report
print "J-STD-020 Compliance Verification Audit:\n";
sub audit_line {
    my ($label, $val, $spec, $pass) = @_;
    printf "  %-32s : %-12s (Spec: %-15s) -> [%s]\n",
        $label, $val, $spec, $pass ? "PASS" : "FAIL";
}

audit_line("Peak Temperature (Tp)", sprintf("%.1f °C", $peak_temp), "240 - 250 °C",
    $peak_temp >= 240 && $peak_temp <= 250);

audit_line("Max Heating Ramp Rate", sprintf("%.2f °C/s", $max_heat_rate), "< 3.0 °C/s",
    $max_heat_rate <= 3.0);

audit_line("Preheat / Soak Duration", sprintf("%.1f s", $soak_time), "60 - 120 s",
    $soak_time >= 60 && $soak_time <= 120);

audit_line("Time Above Liquidus (tL)", sprintf("%.1f s", $time_above_liquidus), "60 - 90 s",
    $time_above_liquidus >= 60 && $time_above_liquidus <= 90);

audit_line("Max Cooling Ramp Rate", sprintf("%.2f °C/s", $max_cool_rate), "< 6.0 °C/s",
    $max_cool_rate <= 6.0);

print "=" x 74, "\n";
