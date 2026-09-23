#!/usr/bin/env perl
# Biomedical Electrocardiogram (ECG / EKG) Heartbeat Synthesizer
# Demonstrates:
#   1. High-precision physiological waveform synthesis (P-Q-R-S-T cardiac cycle)
#   2. Dynamic heart rate (BPM) pacing and stretch/duration transforms
#   3. Pathology simulation: Normal Sinus Rhythm vs ST-Elevation Myocardial Infarction (STEMI)
#   4. Multi-beat continuous looping via table() and ASCII strip-chart monitor
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Generate a single ECG cardiac cycle (P-Q-R-S-T) at a given Heart Rate (BPM)
sub generate_ecg_beat {
    my (%opts) = @_;
    my $bpm = $opts{bpm} // 75; # beats per minute
    my $st_elev = $opts{st_elev} // 0.0; # ST elevation in mV (pathology)

    my $beat_period = 60.0 / $bpm; # total duration of one beat in seconds

    # Standard cardiac interval proportions (at 75 BPM, period = 0.8s):
    #   P-wave:      0.09s (smooth atrium pulse to +0.2 mV)
    #   PR-segment:  0.07s (isoelectric delay)
    #   Q-deflection:0.03s (sharp septal dip to -0.15 mV)
    #   R-peak:      0.04s (ventricular spike to +1.2 mV)
    #   S-trough:    0.04s (ventricular dip to -0.35 mV)
    #   ST-segment:  0.10s (plateau, normally 0.0 mV, elevated in ischemia/infarction)
    #   T-wave:      0.18s (ventricular repolarization to +0.3 mV)
    #   TP-baseline: remainder of cycle to next beat
    my $t_p  = 0.09;
    my $t_pr = 0.07;
    my $t_q  = 0.03;
    my $t_r  = 0.04;
    my $t_s  = 0.04;
    my $t_st = 0.10;
    my $t_t  = 0.18;
    my $active_time = $t_p + $t_pr + $t_q + $t_r + $t_s + $t_st + $t_t; # 0.55s
    my $t_tp = $beat_period - $active_time;
    $t_tp = 0.05 if $t_tp < 0.05;

    # Voltages at key landmarks (mV):
    my @levels = (
        0.0,            # start baseline
        0.20, 0.0,      # P-wave peak and return
        0.0,            # PR segment
        -0.15,          # Q-trough
        1.20,           # R-peak spike
        -0.35,          # S-trough
        $st_elev,       # ST segment start
        $st_elev,       # ST segment end
        0.30 + $st_elev,# T-wave peak
        0.0,            # T-wave return
        0.0             # TP rest baseline
    );

    my @durs = (
        $t_p * 0.5, $t_p * 0.5,
        $t_pr,
        $t_q,
        $t_r * 0.5, $t_r * 0.5,
        $t_s,
        $t_st,
        $t_t * 0.5, $t_t * 0.5,
        $t_tp
    );

    # Curvature exponents:
    # 2.0 for rounded P and T waves, 1.0 for sharp spikes Q-R-S
    my @curves = (
        2.0, -2.0,   # P-wave rounded dome
        1.0,        # PR flat
        1.0,        # Q sharp dip
        1.0, 1.0,   # R steep spike
        1.0,        # S recovery
        1.0,        # ST segment
        2.0, -2.0,   # T-wave dome
        1.0         # TP rest baseline
    );

    return env([\@levels, \@durs, \@curves], is_hold => 0);
}

print "=" x 74, "\n";
print "  Biomedical Electrocardiogram (ECG / EKG) Synthesizer\n";
print "=" x 74, "\n";

# 1. Normal Sinus Rhythm (NSR) at 72 BPM
my $ecg_normal = generate_ecg_beat(bpm => 72, st_elev => 0.0);

# 2. Acute Myocardial Infarction (STEMI with +0.4 mV ST segment elevation)
my $ecg_stemi = generate_ecg_beat(bpm => 85, st_elev => 0.40);

printf "Patient 1: Normal Sinus Rhythm (72 BPM) | Beat Duration: %.3fs\n", $ecg_normal->duration;
printf "Patient 2: Acute STEMI Infarction (85 BPM, +0.40mV ST elevation)\n";
print "-" x 74, "\n";

# Strip-chart printer subroutine
sub print_ecg_chart {
    my ($title, $ecg, $beats, $width) = @_;
    $width //= 65;

    print "Telemetry Strip: $title\n";
    printf "%-8s | %s | %s\n", "Time", "-0.40 mV       0.00 mV       +0.60 mV       +1.20 mV", "ECG Waveform";
    print "-" x 74, "\n";

    # Render multi-beat continuous strip chart using table(samples, loop_count)
    my $samples = 40;
    my @vals = $ecg->table($samples, $beats);
    my $chart_w = 40;
    my $total_dur = $ecg->duration * $beats;

    for my $i (0 .. $#vals) {
        my $t = ($i / scalar(@vals)) * $total_dur;
        my $mv = $vals[$i];

        # Map [-0.4 mV, +1.3 mV] to chart width
        my $pos = int((($mv - (-0.4)) / (1.3 - (-0.4))) * ($chart_w - 1));
        $pos = 0 if $pos < 0; $pos = $chart_w - 1 if $pos >= $chart_w;

        my $line = " " x $chart_w;
        # Isoelectric baseline marker
        my $zero_pos = int(((0.0 - (-0.4)) / (1.3 - (-0.4))) * ($chart_w - 1));
        substr($line, $zero_pos, 1) = ":";

        # Cardiac wave marker
        my $marker = ($mv > 0.8) ? "^" : ($mv < -0.1 ? "v" : "*");
        substr($line, $pos, 1) = $marker;

        # Landmark annotation
        my $note = "";
        if ($mv > 1.0) { $note = "<- R-Peak (Ventricular)" }
        elsif ($mv < -0.2) { $note = "<- S-Wave" }

        printf "%5.2fs   | [%s] %+5.2f mV %s\n", $t, $line, $mv, $note;
    }
    print "\n";
}

# Print Normal Sinus Rhythm Strip
print_ecg_chart("Normal Sinus Rhythm (Lead II, 2 Beats)", $ecg_normal, 2);

# Print STEMI Strip
print_ecg_chart("Acute STEMI Heart Attack (Marked ST Elevation)", $ecg_stemi, 2);

print "=" x 74, "\n";
print "Notice: Modifying a single level parameter in SegmentedEnvelope\n";
print "instantaneously shifts the ST-segment to accurately simulate heart pathology.\n";
print "=" x 74, "\n";
