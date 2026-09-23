#!/usr/bin/env perl
# LiFePO4 Battery Cell Modeling, State-of-Charge (SoC) & Differential Voltage (DVA)
# Demonstrates:
#   1. Highly non-linear Open-Circuit Voltage (OCV) curve modeling with segmented envelopes
#   2. Fast inverse lookup (measured voltage -> estimated State of Charge %)
#   3. Differential Voltage Analysis (dV/dSoC) via derivative() to detect electrochemical phase changes
#   4. Battery Management System (BMS) cell balancing and state estimation
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env spline);

# LiFePO4 3.2V 100Ah prismatic cell OCV characteristics:
#   0% SoC   : 2.50V (fully depleted cutoff)
#   5% SoC   : 3.00V (steep knee recovery)
#  10% SoC   : 3.18V (pre-plateau transition)
#  20% SoC   : 3.25V (flat plateau start)
#  50% SoC   : 3.29V (mid-plateau phase transition)
#  80% SoC   : 3.33V (plateau end)
#  90% SoC   : 3.36V (steep charge knee)
#  95% SoC   : 3.42V (saturation)
# 100% SoC   : 3.65V (fully charged cutoff)

# Time parameter t = SoC fraction [0.0 to 1.0] (duration = 1.0)
my @soc_pts = (0.00, 0.05, 0.10, 0.20, 0.50, 0.80, 0.90, 0.95, 1.00);
my @ocv_pts = (2.50, 3.00, 3.18, 3.25, 3.29, 3.33, 3.36, 3.42, 3.65);

# Build smooth continuous OCV curve using Catmull-Rom spline
my $ocv_curve = spline(\@soc_pts, \@ocv_pts, resolution => 16, tension => 0.05);

# Differential Voltage Analysis: dV / d(SoC)
# Battery researchers use peaks in dV/dQ (derivative of OCV) to track
# lithium staging in graphite (LiC12 -> LiC6) and detect battery aging!
my $dva_curve = $ocv_curve->derivative;

print "=" x 74, "\n";
print "  LiFePO4 Battery Management System (BMS) & Differential Voltage Analysis\n";
print "=" x 74, "\n";
printf "Cell Chemistry: LiFePO4 | Nominal Voltage: 3.2V | Operating: 2.50V - 3.65V\n";
print "-" x 74, "\n";

# Inverse lookup: given measured voltage, solve for SoC %
sub estimate_soc {
    my ($v_target) = @_;
    return 0.0 if $v_target <= 2.50;
    return 100.0 if $v_target >= 3.65;

    # Binary search over monotonic envelope
    my $lo = 0.0;
    my $hi = 1.0;
    for (1 .. 25) {
        my $mid = ($lo + $hi) * 0.5;
        my $v = $ocv_curve->at($mid);
        if ($v < $v_target) {
            $lo = $mid;
        } else {
            $hi = $mid;
        }
    }
    return ($lo + $hi) * 50.0; # as percentage [0, 100%]
}

# Print OCV and DVA curve table
print "OCV vs SoC & Differential Voltage (dV/dSoC):\n";
printf "%-8s | %-10s | %-12s | %s\n",
    "SoC (%)", "OCV (V)", "dV/dSoC (V)", "Discharge Plateau Graph [2.5V -> 3.65V]";
print "-" x 74, "\n";

my $chart_w = 30;
for (my $s = 0; $s <= 100; $s += 5) {
    my $t = $s / 100.0;
    my $v = $ocv_curve->at($t);
    my $dva = $dva_curve->at($t);

    my $bar = int((($v - 2.50) / (3.65 - 2.50)) * ($chart_w - 1));
    $bar = 0 if $bar < 0; $bar = $chart_w - 1 if $bar >= $chart_w;
    my $line = " " x $chart_w;
    substr($line, $bar, 1) = "*";

    printf "%4.0f %%   | %6.3f V   | %6.3f V/unit | [%s]\n",
        $s, $v, $dva, $line;
}
print "-" x 74, "\n";

# Simulate BMS Telemetry across battery pack cells
print "BMS Multi-Cell Pack Telemetry (Voltage -> State of Charge):\n";
printf "%-10s | %-12s | %-12s | %s\n",
    "Cell ID", "Voltage (V)", "Est. SoC (%)", "Charge Level Bar";
print "-" x 74, "\n";

my @test_voltages = (2.65, 3.12, 3.26, 3.28, 3.31, 3.34, 3.45, 3.62);
my $cell_num = 1;
for my $v_meas (@test_voltages) {
    my $est = estimate_soc($v_meas);
    my $bar_len = int(($est / 100.0) * 20);
    my $meter = "[" . ("#" x $bar_len) . (" " x (20 - $bar_len)) . "]";

    printf "Cell #%02d   |   %5.3f V    |    %5.1f %%     | %s\n",
        $cell_num++, $v_meas, $est, $meter;
}

print "=" x 74, "\n";
print "Notice: Between 20% and 80% SoC, voltage changes by only ~0.08V!\n";
print "SegmentedEnvelope accurately interpolates the ultra-flat plateau\n";
print "while preserving steep knees for high-precision BMS state estimation.\n";
print "=" x 74, "\n";
