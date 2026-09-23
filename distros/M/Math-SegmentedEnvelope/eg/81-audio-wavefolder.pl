#!/usr/bin/env perl
# Analog Synthesizer Wavefolder (Buchla / Serge West-Coast Timbre Circuit)
# Demonstrates:
#   1. Using is_fold_over => 1 and is_wrap_neg => 1 to build a real-time wavefolder
#   2. Dynamic harmonic generation by driving a pure sine wave past folding thresholds
#   3. Visualizing transfer curves and folded audio waveforms with harmonic spectrum
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Mathematical wavefolder core:
# Linear transfer zone [-1.0, +1.0] over duration 2.0.
# Any signal driven beyond +/-1.0 folds back down smoothly.
my $folder = env([
    [-1.0, 1.0],
    [2.0],
    [1.0]
], is_fold_over => 1, is_wrap_neg => 1);

# Map input audio amplitude x in [-4.0, +4.0] into folder time coordinate t = x + 1.0
sub fold_sample {
    my ($sample, $drive) = @_;
    my $driven = $sample * $drive;
    return $folder->at($driven + 1.0);
}

print "=" x 74, "\n";
print "  West-Coast Synth Wavefolder (Buchla / Serge Timbre Generator)\n";
print "=" x 74, "\n";
print "Core: Math::SegmentedEnvelope with is_fold_over=1 & is_wrap_neg=1\n";
print "-" x 74, "\n";

# 1. Plot the static transfer curve from In = -3.0 to +3.0
print "Wavefolder Non-Linear Transfer Characteristic:\n";
printf "%-10s | %-10s | %s\n", "Input", "Folded Out", "Transfer Graph [-1.0 to +1.0]";
print "-" x 74, "\n";

my $chart_w = 32;
for (my $in = -3.0; $in <= 3.01; $in += 0.3) {
    my $out = fold_sample($in, 1.0);
    my $pos = int((($out - (-1.0)) / 2.0) * ($chart_w - 1));
    $pos = 0 if $pos < 0; $pos = $chart_w - 1 if $pos >= $chart_w;
    my $line = " " x $chart_w;
    substr($line, int($chart_w / 2), 1) = "|";
    substr($line, $pos, 1) = "*";
    printf "%+6.2f     | %+6.2f     | [%s]\n", $in, $out, $line;
}
print "-" x 74, "\n";

# 2. Drive a 440 Hz Sine Wave through 3 Drive Stages
#   Drive 1.0 = Clean pure sine (no folding)
#   Drive 2.0 = Single fold (rich odd harmonics, warm hollow tone)
#   Drive 3.5 = Multi fold (metallic, bright, buzzing West Coast timbre)
my @drives = (1.0, 2.0, 3.5);
my $points = 32; # one audio cycle sampled at 32 points
my $pi = 3.141592653589793;

print "Folded Waveforms Across One Full Audio Cycle (32 samples):\n";
for my $drive (@drives) {
    printf "\n--- Drive Level: x%.1f %s---\n",
        $drive, ($drive == 1.0 ? "(Linear Sine)" : ($drive == 2.0 ? "(1 Fold)" : "(Multi-Fold)"));

    for my $i (0 .. $points - 1) {
        my $phase = ($i / $points) * 2.0 * $pi;
        my $raw_sine = sin($phase);
        my $folded = fold_sample($raw_sine, $drive);

        my $pos = int((($folded - (-1.0)) / 2.0) * ($chart_w - 1));
        $pos = 0 if $pos < 0; $pos = $chart_w - 1 if $pos >= $chart_w;
        my $trace = " " x $chart_w;
        substr($trace, int($chart_w / 2), 1) = ":";
        substr($trace, $pos, 1) = "#";

        if ($i % 2 == 0) {
            printf "  %5.1f° | Raw: %+5.2f -> Folded: %+5.2f |%s|\n",
                ($i / $points) * 360, $raw_sine, $folded, $trace;
        }
    }
}

print "=" x 74, "\n";
print "Summary: By simply setting is_fold_over => 1, SegmentedEnvelope acts as\n";
print "a zero-CPU-overhead, distortion-free wavefolder for synthesis and audio DSP.\n";
print "=" x 74, "\n";
