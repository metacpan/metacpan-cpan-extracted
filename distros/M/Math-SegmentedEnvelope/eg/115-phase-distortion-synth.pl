#!/usr/bin/env perl
# Casio CZ Phase Distortion (PD) Synthesizer
# Demonstrates segmented envelopes for non-linear phase lookup:
# - Piecewise phase-warping transfer function envelope
# - Resonant filter simulation via windowed phase multiplier
# - Multi-stage DCA (Digital Controlled Amp) and DCW (Digital Controlled Wave) envelopes
#
# Generates an authentic 80s electro funk bassline groove and writes 16-bit 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;

# 16-step bassline pattern (note, gate_duration, octave, accent)
my @bassline = (
    { note => 'D2', freq => 73.42, dur => 0.20, acc => 1.0 },
    { note => 'D2', freq => 73.42, dur => 0.12, acc => 0.7 },
    { note => 'F2', freq => 87.31, dur => 0.18, acc => 0.8 },
    { note => 'D2', freq => 73.42, dur => 0.12, acc => 0.6 },
    { note => 'G2', freq => 98.00, dur => 0.22, acc => 1.0 },
    { note => 'Ab2',freq => 103.83,dur => 0.10, acc => 0.5 },
    { note => 'A2', freq => 110.00,dur => 0.24, acc => 0.9 },
    { note => 'D2', freq => 73.42, dur => 0.14, acc => 0.7 },
    { note => 'C3', freq => 130.81,dur => 0.22, acc => 1.0 },
    { note => 'A2', freq => 110.00,dur => 0.14, acc => 0.7 },
    { note => 'G2', freq => 98.00, dur => 0.18, acc => 0.8 },
    { note => 'F2', freq => 87.31, dur => 0.16, acc => 0.7 },
    { note => 'D2', freq => 73.42, dur => 0.28, acc => 1.0 },
    { note => 'C2', freq => 65.41, dur => 0.12, acc => 0.6 },
    { note => 'C#2',freq => 69.30, dur => 0.12, acc => 0.6 },
    { note => 'D2', freq => 73.42, dur => 0.35, acc => 1.0 },
);

my $step_time = 0.20; # 16th note at ~75 BPM
my $total_dur = scalar(@bassline) * $step_time + 0.5;
my $total_samples = int($total_dur * $sample_rate);

# DCW (Filter sweep brightness envelope)
# High brightness snappy attack with exponential decay down to warm sustain
my $dcw_env = adsr(0.015, 0.09, 0.25, 0.08,
    peak => 1.0, attack_curve => 2, decay_curve => -3, release_curve => -2);
my $dcw_s = $dcw_env->static;

# DCA (Amplitude envelope)
my $dca_env = adsr(0.005, 0.12, 0.65, 0.06,
    peak => 1.0, attack_curve => 1, decay_curve => -2, release_curve => -3);
my $dca_s = $dca_env->static;

# Phase transfer function: converts linear phase phi in [0, 1] into distorted phase
# When DCW mod is 0 -> pure cosine wave; when DCW mod is 1.0 -> sharp sawtooth/resonant waveform
sub cz_phase_distortion {
    my ($linear_phi, $dcw_amount) = @_;
    # Normal CZ saw-to-cosine distortion formula:
    # Divides cycle into inflection point controlled by DCW
    # At dcw=0, inflection is at 0.5 (pure symmetric sine/cosine)
    # At dcw=1, inflection is pushed to 0.05 (steep attack, long slope)
    my $inflection = 0.5 - 0.45 * $dcw_amount;
    my $warped_phi;
    if ($linear_phi < $inflection) {
        $warped_phi = 0.5 * ($linear_phi / $inflection);
    } else {
        $warped_phi = 0.5 + 0.5 * (($linear_phi - $inflection) / (1.0 - $inflection));
    }
    return $warped_phi;
}

print "Synthesizing Casio CZ Phase Distortion Funk Bassline...\n";

my @mix_buffer = (0.0) x $total_samples;

for my $step_idx (0 .. $#bassline) {
    my $step = $bassline[$step_idx];
    my $f0 = $step->{freq};
    my $accent = $step->{acc};
    my $gate_time = $step->{dur};

    my $start_sample = int($step_idx * $step_time * $sample_rate);
    my $note_samples = int($gate_time * $sample_rate);

    my $phase = 0.0;
    my $phase_inc = $f0 / $sample_rate;

    for my $n (0 .. $note_samples - 1) {
        my $t_rel = $n / $sample_rate;

        # Evaluate DCW filter sweep and DCA amp
        my $dcw_val = $dcw_s->($t_rel) * $accent;
        my $dca_val = $dca_s->($t_rel) * $accent;

        # Linear ramp phase in [0, 1)
        my $linear_phi = $phase - int($phase);

        # Warped phase
        my $distorted_phi = cz_phase_distortion($linear_phi, $dcw_val);

        # CZ waveform generation: cosine of warped phase + resonant ring modulator
        # Resonant carrier (saw phase * window envelope)
        my $base_wave = -cos(2.0 * $pi * $distorted_phi);
        my $res_harm = 4.0 + 8.0 * $dcw_val;
        my $res_window = 1.0 - $linear_phi; # amplitude window
        my $resonance = sin(2.0 * $pi * $linear_phi * $res_harm) * $res_window;

        my $synth_sample = (0.65 * $base_wave + 0.35 * $resonance) * $dca_val;

        my $target = $start_sample + $n;
        last if $target >= $total_samples;
        $mix_buffer[$target] += $synth_sample * 0.40;

        $phase += $phase_inc;
        $phase -= int($phase) if $phase >= 1.0;
    }
}

# Normalize and write WAV
my $max_val = 0.0001;
for my $s (@mix_buffer) {
    my $a = abs($s);
    $max_val = $a if $a > $max_val;
}
my $gain = 0.88 / $max_val;

my $wav_file = 'phase_distortion_bass.wav';
open my $out, '>:raw', $wav_file or die "Cannot open $wav_file: $!\n";
my $num_channels = 1;
my $bits_per_sample = 16;
my $byte_rate = $sample_rate * $num_channels * ($bits_per_sample / 8);
my $block_align = $num_channels * ($bits_per_sample / 8);
my $data_chunk_size = $total_samples * $block_align;
my $riff_size = 36 + $data_chunk_size;

print $out "RIFF" . pack('V', $riff_size) . "WAVE";
print $out "fmt " . pack('V', 16) . pack('v', 1) . pack('v', $num_channels);
print $out pack('V', $sample_rate) . pack('V', $byte_rate);
print $out pack('v', $block_align) . pack('v', $bits_per_sample);
print $out "data" . pack('V', $data_chunk_size);

for my $s (@mix_buffer) {
    my $v = int($s * $gain * 32767.0);
    $v = 32767 if $v > 32767; $v = -32768 if $v < -32768;
    print $out pack('s<', $v);
}
close $out;

printf "Wrote %s (%.2fs Phase Distortion bassline)\n", $wav_file, $total_dur;

# ASCII Visualization of CZ Phase Transfer Curves (dcw=0 vs dcw=0.8)
print "\nCasio CZ Phase Distortion Transfer Curves (Linear Phase -> Warped Phase):\n";
print "  Warped | DCW = 0.0 (Clean Sine)             | DCW = 0.85 (High Resonance)\n";
print "  -------+------------------------------------+------------------------------------\n";
my $rows = 8;
my $cols = 32;
for my $r (reverse 0 .. $rows) {
    my $y_target = $r / $rows;
    printf "   %3.2f  | ", $y_target;
    # Clean sine plot
    for my $c (0 .. $cols - 1) {
        my $x = $c / ($cols - 1);
        my $y = cz_phase_distortion($x, 0.0);
        print (abs($y - $y_target) < 0.5 / $rows ? '*' : ' ');
    }
    print " | ";
    # High resonance plot
    for my $c (0 .. $cols - 1) {
        my $x = $c / ($cols - 1);
        my $y = cz_phase_distortion($x, 0.85);
        print (abs($y - $y_target) < 0.5 / $rows ? '#' : ' ');
    }
    print "\n";
}
print "  -------+------------------------------------+------------------------------------\n";
print "  Linear | 0.0                  1.0 (Phase)   | 0.0                  1.0 (Phase)\n";
