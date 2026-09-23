#!/usr/bin/env perl
# Audio Dynamics Compressor & Soft-Knee Transfer Curve
# Demonstrates:
#   1. Using spline() to model a smooth analog-style "soft knee" dB transfer function
#   2. Asymmetric attack/release envelope ballistics for peak/RMS level detection
#   3. Real-time gain reduction curve calculation and ASCII waveform metering
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env spline);

# Compressor settings:
# Threshold: -20 dB, Knee width: 10 dB (-25 dB to -15 dB)
# Ratio: 4:1 above knee
my $thresh = -20.0;
my $knee_w = 10.0;
my $ratio  = 4.0;

# Build continuous dB transfer curve from -60 dB to 0 dB
# Segments:
#   1. Linear 1:1 below knee: [-60 dB, -25 dB] -> [-60 dB, -25 dB]
#   2. Soft knee transition:   [-25 dB, -15 dB] -> [-25 dB, -22.5 dB] (smooth transition)
#   3. Compressed above knee:  [-15 dB, 0 dB]   -> [-22.5 dB, -18.75 dB] (ratio 4:1)
my $knee_start_in  = $thresh - $knee_w / 2.0;  # -25 dB
my $knee_end_in    = $thresh + $knee_w / 2.0;  # -15 dB

my $knee_start_out = $knee_start_in;            # -25 dB (1:1)
# Output at knee end: threshold + half knee reduced by ratio
my $knee_end_out   = $thresh + ($knee_w / 2.0) / $ratio; # -18.75 dB
my $peak_out       = $knee_end_out + (0.0 - $knee_end_in) / $ratio; # -15 dB peak

# Input dB mapped to duration: In = t - 60, so t = In + 60 in [0, 60]
my $dur1 = $knee_start_in - (-60.0); # 35 dB
my $dur2 = $knee_end_in - $knee_start_in; # 10 dB
my $dur3 = 0.0 - $knee_end_in; # 15 dB

my $transfer = env([
    [-60.0, $knee_start_out, $knee_end_out, $peak_out],
    [$dur1, $dur2, $dur3],
    [1.0, -1.8, 1.0], # -1.8 curve provides smooth gradual knee tapering
], is_hold => 1);

sub db_to_transfer_t { $_[0] + 60.0 }
sub transfer_at_db   { $transfer->at(db_to_transfer_t($_[0])) }

# Ballistics: attack and release time constants
my $attack_ms  = 5.0;   # fast attack for transient capture
my $release_ms = 80.0;  # smooth release recovery

print "=" x 72, "\n";
print "  Studio Dynamics Compressor: Soft-Knee Transfer & Envelope Follower\n";
print "=" x 72, "\n";
printf "Threshold: %.1f dB | Knee Width: %.1f dB | Ratio: %.1f:1\n",
    $thresh, $knee_w, $ratio;
print "-" x 72, "\n";

# Print transfer curve calibration table
print "Soft-Knee Transfer Curve:\n";
printf "%-10s  %-10s  %-12s  %s\n", "In (dB)", "Out (dB)", "Gain Reduc", "Transfer Line";
for (my $db = -40; $db <= 0; $db += 5) {
    my $out = transfer_at_db($db);
    my $gr = $out - $db; # negative dB is attenuation
    my $gauge_w = 20;
    my $bar = int((($out + 40) / 40.0) * $gauge_w);
    $bar = 0 if $bar < 0;
    $bar = $gauge_w if $bar > $gauge_w;
    printf "%+6.1f dB   %+6.1f dB   %+6.2f dB    |%s*\n",
        $db, $out, $gr, " " x $bar;
}
print "-" x 72, "\n";

# Simulate audio signal with transient bursts (drum hit + sustained pad)
my $sr = 1000; # 1 kHz simulation rate (1 ms per step)
my $sim_dur = 0.35; # 350 ms
my $samples = int($sim_dur * $sr);

# Signal: low pad (-24 dB) with two loud percussion hits (0 dB and -6 dB)
my $env_signal = env([
    [-24, -24, 0, -12, -24, -24, -6, -18, -24],
    [0.05, 0.01, 0.03, 0.04, 0.05, 0.01, 0.04, 0.05],
    [1, 1, -2, -2, 1, 1, -2, -2]
], is_hold => 1);

print "Processing Transient Burst Signal:\n";
printf "%-7s | %-9s | %-9s | %-8s | %s\n",
    "Time", "Input", "Detector", "Gain Red", "Meter (Input -> Output)";
print "-" x 72, "\n";

my $det_level = -60.0;
my $dt = 1.0 / $sr;
my $att_coeff = exp(-$dt / ($attack_ms / 1000.0));
my $rel_coeff = exp(-$dt / ($release_ms / 1000.0));

for my $i (0 .. 25) {
    my $t = ($i / 25) * $sim_dur;
    my $in_db = $env_signal->at($t);

    # Envelope follower ballistics
    if ($in_db > $det_level) {
        $det_level = $in_db + ($det_level - $in_db) * $att_coeff;
    } else {
        $det_level = $in_db + ($det_level - $in_db) * $rel_coeff;
    }

    # Evaluate transfer function
    my $target_out = transfer_at_db($det_level);
    my $gr_db = $target_out - $det_level; # <= 0 dB
    $gr_db = 0.0 if $gr_db > 0.0;

    my $out_db = $in_db + $gr_db;

    my $in_bar  = int((($in_db + 30) / 30) * 12);
    my $out_bar = int((($out_db + 30) / 30) * 12);
    $in_bar = 0 if $in_bar < 0; $in_bar = 12 if $in_bar > 12;
    $out_bar = 0 if $out_bar < 0; $out_bar = 12 if $out_bar > 12;

    printf "%4.0f ms | %+6.1f dB | %+6.1f dB | %+5.1f dB | In: [%-12s] Out: [%-12s]\n",
        $t * 1000, $in_db, $det_level, $gr_db,
        "#" x $in_bar, "=" x $out_bar;
}
print "=" x 72, "\n";
