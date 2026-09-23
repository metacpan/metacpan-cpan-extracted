#!/usr/bin/env perl
# Modular synth patch: oscillator -> filter envelope -> amp envelope -> output
# Demonstrates envelope-as-control-voltage for parameter modulation
#
# Outputs raw 16-bit PCM:
#   perl eg/20-modular-synth.pl | aplay -f S16_LE -r 44100 -c 1
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr env perc);

my $sr  = 44100;
my $pi2 = 2 * 3.14159265358979323846;

# Amplitude envelope
my $amp_env = adsr(0.01, 0.15, 0.6, 0.5, peak => 0.7,
    morpher_formula => 'smoothstep');

# Filter cutoff envelope (controls brightness): opens then closes
my $filt_env = adsr(0.005, 0.3, 0.3, 0.4, peak => 1.0,
    attack_curve => 3, decay_curve => -3,
    morpher_formula => 'cubic_out');

# Vibrato LFO: slow sine, ~5 Hz
my $vibrato = env(
    [[0, 1, 0, -1, 0], [0.05, 0.05, 0.05, 0.05], [2, -2, 2, -2]],
    is_morph => 1, is_fold_over => 1,
);

# Vibrato depth envelope: none at start, increases over time
my $vib_depth = env([[0, 0, 0.008], [0.3, 0.7], [1, 2]], is_hold => 1);

my $dur    = $amp_env->duration;
my $frames = int($dur * $sr);
my $freq   = 220;  # A3

my $amp_s  = $amp_env->static;
my $filt_s = $filt_env->static;
my $vib_s  = $vibrato->static;
my $vdep_s = $vib_depth->static;

# Simple one-pole lowpass filter state
my $lp_state = 0;

binmode STDOUT;
my $phase = 0;

for my $i (0 .. $frames - 1) {
    my $t = $i / $sr;

    # Control voltages
    my $amp  = $amp_s->($t);
    my $filt = $filt_s->($t);          # 0..1 -> filter cutoff
    my $vib  = $vib_s->($t);           # -1..1 vibrato
    my $vdep = $vdep_s->($t);          # vibrato depth (semitones)

    # Apply vibrato to frequency
    my $f = $freq * (1 + $vib * $vdep);

    # Sawtooth oscillator (harmonically rich)
    my $saw = 2.0 * ($phase / $pi2) - 1.0;

    # One-pole lowpass: cutoff from filter envelope
    # Map 0..1 to coefficient 0.01..0.99
    my $coeff = 0.01 + $filt * 0.98;
    $lp_state = $lp_state + $coeff * ($saw - $lp_state);

    # Apply amplitude envelope
    my $out = $lp_state * $amp;

    # Soft clip
    $out = tanh($out * 1.5) / tanh(1.5);

    my $sample = int($out * 32767);
    $sample =  32767 if $sample >  32767;
    $sample = -32768 if $sample < -32768;
    print pack('v', $sample & 0xFFFF);

    $phase += $pi2 * $f / $sr;
    $phase -= $pi2 if $phase >= $pi2;
}

warn sprintf "Modular patch: %.2fs, %d Hz, %d frames\n", $dur, $freq, $frames;

sub tanh { my $x = $_[0]; my $e = exp(2*$x); return ($e-1)/($e+1); }
