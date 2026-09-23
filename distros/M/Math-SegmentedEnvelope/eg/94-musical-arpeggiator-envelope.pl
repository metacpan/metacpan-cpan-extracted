#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc spline);

# ============================================================================
# Modular Synthesizer: 16-Step Arpeggiator & Dynamic Timbre Modulation
# ============================================================================
# In electronic music production and analog modular synthesis (Eurorack, Moog,
# Roland), an arpeggiator transforms held chords into animated melodic patterns.
#
# Synthesizer voice architecture:
#   1. Pitch Control Voltage (1V/Octave):
#      - Continuous melodic trajectory generated via spline() interpolation.
#      - Discrete pitch snapping via quantize(24) to lock to 24 chromatic
#        semitones (2 octaves) or smooth portamento.
#   2. Dynamic Low-Pass Filter (VCF Cutoff):
#      - Per-note snappy filter envelope created with perc(attack, decay).
#      - Blended with a 2-bar macro cutoff sweep LFO using blend().
#   3. Amplitude Envelope (VCA Gain):
#      - ADSR dynamics per step with velocity accents on downbeats and syncopation.
#
# This example demonstrates:
#   - quantize(): Snapping continuous pitch voltage to discrete musical semitones.
#   - spline(): Creating smooth, musical pitch slides and glide contours.
#   - adsr() & perc(): Crafting snappy percussive envelopes for filter and amp.
#   - blend(): Morphing between localized note envelopes and macro filter sweeps.
#   - Generating an ASCII tracker / piano roll display across 16 steps.
# ============================================================================

# Musical tempo: 120 BPM => 1 beat (quarter note) = 0.500s
# 16th note step = 0.125s (125 ms). Total 16 steps = 2.000s
my $step_dur  = 0.125;
my $num_steps = 16;
my $total_dur = $num_steps * $step_dur;

# Note names for chromatic semitone offsets from C3 (MIDI 48 = 130.81 Hz)
my @chromatic_names = (
    'C3', 'C#3', 'D3', 'Eb3', 'E3', 'F3', 'F#3', 'G3', 'Ab3', 'A3', 'Bb3', 'B3',
    'C4', 'C#4', 'D4', 'Eb4', 'E4', 'F4', 'F#4', 'G4', 'Ab4', 'A4', 'Bb4', 'B4', 'C5'
);
my $base_freq = 130.8128; # C3 frequency

# 1. Generate Melodic Contour in C Minor / Dorian:
# Anchor points: [t, semitone / 24.0] normalized to [0, 1] range for quantize(24)
# Notes: C3(0), Eb3(3), G3(7), Bb3(10), C4(12), Eb4(15), D4(14), C4(12),
#        G3(7), Bb3(10), C4(12), Eb4(15), G4(19), Eb4(15), D4(14), C3(0)
my @melody_semitones = (0, 3, 7, 10, 12, 15, 14, 12, 7, 10, 12, 15, 19, 15, 14, 0);

# Build anchor points for spline interpolation
my (@times, @values);
for my $i (0 .. $num_steps - 1) {
    my $t = ($i + 0.5) * $step_dur;
    my $norm_semi = $melody_semitones[$i] / 24.0; # 2 octaves = 24 semitones
    push @times,  $t;
    push @values, $norm_semi;
}

# Continuous pitch spline envelope
my $pitch_glide = spline(\@times, \@values, segments => 64, is_hold => 1);

# Quantized pitch envelope: snaps levels to 24 discrete chromatic semitones!
my $pitch_quant = $pitch_glide->quantize(24);

# 2. VCF Cutoff Filter Envelope:
# Create a macro filter sweep envelope across the 2-second pattern (500 Hz to 4500 Hz)
my $vcf_macro = Math::SegmentedEnvelope->new(
    [[500, 4500, 1200], [1.2, 0.8], [2, -2]],
    is_hold => 1,
);

# Per-note pluck envelope (fast 10ms attack, 80ms decay)
my $vcf_pluck = perc(0.010, 0.080, peak => 1.0, is_hold => 1);

# 3. Output ASCII Arpeggiator & Tracker Table
print "=" x 76, "\n";
print "  Modular Synth Arpeggiator: Pitch Quantization & VCF/VCA Modulation\n";
print "=" x 76, "\n";
print "Tempo: 120 BPM | Step: 16th note (125ms) | Scale: C Minor / Dorian\n";
print "Pitch Range: C3 (130.8 Hz) to G4 (392.0 Hz) | 24 Chromatic Quantization Grid\n";
print "-" x 76, "\n";
printf "%-4s | %-6s | %-7s | %-5s | %-8s | %-8s | %s\n",
    "Step", "Time", "Glide", "Quant", "Freq(Hz)", "VCF Cut", "Piano Roll [C3 . . . . . . . . C4 . . . G4]";
print "-" x 76, "\n";

my $roll_width = 25;

for my $i (0 .. $num_steps - 1) {
    my $t = $i * $step_dur + 0.02; # sample shortly after note onset

    my $glide_norm = $pitch_glide->at($t);
    my $quant_norm = $pitch_quant->at($t);

    my $glide_semi = $glide_norm * 24.0;
    my $quant_semi = int($quant_norm * 24.0 + 0.5);
    $quant_semi = 0  if $quant_semi < 0;
    $quant_semi = 24 if $quant_semi > 24;

    my $note_name = $chromatic_names[$quant_semi] // "C3";
    my $freq = $base_freq * (2.0 ** ($quant_semi / 12.0));

    # VCF Cutoff combines macro sweep with note pluck
    my $macro_hz = $vcf_macro->at($t);
    my $dt_step = $t - $i * $step_dur;
    my $pluck_mod = $vcf_pluck->at($dt_step);
    my $cutoff_hz = $macro_hz + 1500 * $pluck_mod;

    # Accent on beats 1, 5, 9, 13 and syncopated 11
    my $accent = ($i % 4 == 0 || $i == 10) ? "*" : " ";

    # Render piano roll column
    my @roll = ('.') x $roll_width;
    my $pos = int(($quant_semi / 24.0) * ($roll_width - 1));
    $pos = 0 if $pos < 0; $pos = $roll_width - 1 if $pos >= $roll_width;
    $roll[$pos] = '#';

    my $roll_str = join('', @roll);
    printf "%2d%s  | %5.3fs | %5.2fst | %-5s | %7.1fHz | %6.0fHz | [%s]\n",
        $i + 1, $accent, $t, $glide_semi, $note_name, $freq, $cutoff_hz, $roll_str;
}
print "-" x 76, "\n";

# 4. Compare Smooth Portamento Glide vs Quantized Note Stepping
print "\nGlissando Pitch Transition (Step 4 -> Step 5: Bb3 10st -> C4 12st):\n";
print "Time   | Smooth Glide | Quantized Note | Pitch Bend Visualization\n";
print "-" x 76, "\n";

for (my $t = 0.375; $t <= 0.625; $t += 0.025) {
    my $g_semi = $pitch_glide->at($t) * 24.0;
    my $q_semi = int($pitch_quant->at($t) * 24.0 + 0.5);

    my $g_bar = int(($g_semi - 8.0) / (14.0 - 8.0) * 24);
    $g_bar = 0 if $g_bar < 0; $g_bar = 24 if $g_bar > 24;

    my @row = (' ') x 25;
    $row[$g_bar] = 'G'; # Glide
    my $q_bar = int(($q_semi - 8.0) / (14.0 - 8.0) * 24);
    $q_bar = 0 if $q_bar < 0; $q_bar = 24 if $q_bar > 24;
    $row[$q_bar] = 'Q'; # Quantized

    my $graph = join('', @row);
    printf "%5.3fs |   %5.2f st   |    %2d st (%s)   | [%s]\n",
        $t, $g_semi, $q_semi, $chromatic_names[$q_semi] // 'C', $graph;
}
print "-" x 76, "\n";

# 5. Envelope Morphing via blend(): Pluck -> Pad Timbre
print "\nDynamic Timbral Morphing via blend() (0.125s Step Envelope):\n";
print "Morph Ratio | Attack Level | Sustain Level | Decay Level | Envelope Character\n";
print "-" x 76, "\n";

my $env_pluck = perc(0.005, 0.120, peak => 1.0, is_hold => 1);
my $env_pad   = adsr(0.040, 0.020, 0.80, 0.065, sustain_time => 0.05, peak => 1.0, is_hold => 1);

for my $mix (0.0, 0.25, 0.50, 0.75, 1.0) {
    my $blended = $env_pluck->blend($env_pad, $mix);
    my $atk = $blended->at(0.005);
    my $mid = $blended->at(0.060);
    my $dec = $blended->at(0.120);

    my $desc = ($mix == 0.0) ? "100% Percussive Pluck" :
               ($mix == 0.5) ? "50/50 Hybrid Pluck-Pad" :
               ($mix == 1.0) ? "100% Warm Sustained Pad" :
               sprintf("%.0f%% Morph Mix", $mix * 100);

    printf "Mix %4.2f    |    %5.3f     |     %5.3f     |    %5.3f    | %s\n",
        $mix, $atk, $mid, $dec, $desc;
}
print "=" x 76, "\n";
print "Summary: quantize() enables sample-and-hold pitch snapping while spline()\n";
print "and perc()/adsr()/blend() generate organic portamento and synth voice modulation.\n";
print "=" x 76, "\n";
