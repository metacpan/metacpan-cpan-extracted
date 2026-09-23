#!/usr/bin/env perl
# Acoustic Speech Synthesis: Formant Filter Trajectories & Vowel Morphing
# Demonstrates:
#   1. Human vocal tract formant frequency modeling (F1, F2 acoustic resonances)
#   2. Diphthong vowel morphing (/a/ -> /i/ -> /o/) via eased trajectory envelopes
#   3. Multi-band parametric filter frequency response spectrum calculation
#   4. Terminal ASCII vocal tract acoustic resonance plot
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Vowel Formant Frequencies (Hz) for male vocal tract:
#   /a/ ("father"): F1 = 750 Hz,  F2 = 1200 Hz
#   /i/ ("see")   : F1 = 250 Hz,  F2 = 2300 Hz
#   /o/ ("boat")  : F1 = 500 Hz,  F2 =  900 Hz

# Transition sequence: /a/ (0.0s) -> /i/ (0.6s) -> /o/ (1.2s)
my $dur_vowel = 0.6; # seconds per vowel transition

my $formant_f1 = env([
    [750.0, 250.0, 500.0],
    [$dur_vowel, $dur_vowel],
    [1.0, 1.0]
], is_hold => 1, is_morph => 1, morpher_formula => 'smoothstep');

my $formant_f2 = env([
    [1200.0, 2300.0, 900.0],
    [$dur_vowel, $dur_vowel],
    [1.0, 1.0]
], is_hold => 1, is_morph => 1, morpher_formula => 'smoothstep');

# Pitch fundamental frequency F0 (with natural vocal vibrato / pitch scoop)
my $pitch_f0 = env([
    [110.0, 130.0, 125.0],
    [$dur_vowel, $dur_vowel],
    [2.0, -2.0]
], is_hold => 1);

# Bandwidths of the formants (Q factor / sharpness)
my $bw1 = 80.0;  # Hz bandwidth of F1
my $bw2 = 110.0; # Hz bandwidth of F2

# Compute resonance filter response at frequency f (Hz) given formant peaks
sub vocal_filter_gain {
    my ($f, $f1, $f2) = @_;
    # Second-order resonator response model:
    my $r1 = exp(-0.5 * (($f - $f1) / $bw1) ** 2);
    my $r2 = exp(-0.5 * (($f - $f2) / $bw2) ** 2) * 0.75; # F2 is slightly lower amplitude
    # Overall vocal tract gain (0.0 to 1.0)
    my $gain = $r1 + $r2;
    $gain = 1.0 if $gain > 1.0;
    return $gain;
}

print "=" x 74, "\n";
print "  Acoustic Speech Synthesis: Formant Tracking & Vowel Morphing\n";
print "=" x 74, "\n";
printf "Vowel Sequence: /a/ (0.0s) -> /i/ (0.6s) -> /o/ (1.2s)\n";
print "-" x 74, "\n";

# 1. Print Formant Trajectory Log
print "Dynamic Formant Trajectory Telemetry:\n";
printf "%-6s | %-6s | %-9s | %-9s | %s\n",
    "Time", "Vowel", "F1 (Hz)", "F2 (Hz)", "Resonant Peak Locations [200Hz - 2500Hz]";
print "-" x 74, "\n";

my $chart_w = 32;
for (my $t = 0.0; $t <= 1.21; $t += 0.15) {
    my $f1 = $formant_f1->at($t);
    my $f2 = $formant_f2->at($t);

    my $label = ($t < 0.3) ? "/a/ (ah)" : ($t < 0.9 ? "/i/ (ee)" : "/o/ (oh)");

    my $pos1 = int((($f1 - 200.0) / 2300.0) * ($chart_w - 1));
    my $pos2 = int((($f2 - 200.0) / 2300.0) * ($chart_w - 1));
    $pos1 = 0 if $pos1 < 0; $pos1 = $chart_w - 1 if $pos1 >= $chart_w;
    $pos2 = 0 if $pos2 < 0; $pos2 = $chart_w - 1 if $pos2 >= $chart_w;

    my $line = " " x $chart_w;
    substr($line, $pos1, 1) = "1";
    substr($line, $pos2, 1) = "2";

    printf "%4.2fs | %-7s | %5.0f Hz | %5.0f Hz | [%s]\n",
        $t, $label, $f1, $f2, $line;
}
print "-" x 74, "\n";

# 2. Spectral Cross-Sections across the 3 Vowel Centers
my @snapshots = (
    ["Vowel /a/ ('father') at T=0.0s", 0.0],
    ["Vowel /i/ ('see')    at T=0.6s", 0.6],
    ["Vowel /o/ ('boat')   at T=1.2s", 1.2],
);

my @shades = (' ', '.', ':', '-', '=', '+', '*', '#');

for my $snap (@snapshots) {
    my ($title, $t) = @$snap;
    my $f1 = $formant_f1->at($t);
    my $f2 = $formant_f2->at($t);

    print "$title (F1 = " . int($f1) . " Hz, F2 = " . int($f2) . " Hz):\n";
    printf "  Freq (Hz) | %s | Gain dB\n", " " x 18 . "Acoustic Frequency Response" . " " x 18;

    # Scan from 200 Hz to 2600 Hz in 100 Hz steps
    for (my $f = 200; $f <= 2600; $f += 150) {
        my $gain = vocal_filter_gain($f, $f1, $f2);
        my $bar_len = int($gain * 40);
        my $db = ($gain > 0.01) ? 20.0 * (log($gain) / log(10)) : -40.0;
        printf "   %4d Hz  | %-40s | %+5.1f dB\n",
            $f, "=" x $bar_len, $db;
    }
    print "\n";
}

print "=" x 74, "\n";
print "Summary: SegmentedEnvelope provides smooth, artifact-free trajectories for\n";
print "audio filter parameters, preventing clicks and zippering in speech synthesis.\n";
print "=" x 74, "\n";
