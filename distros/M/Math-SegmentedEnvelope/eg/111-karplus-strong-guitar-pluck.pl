#!/usr/bin/env perl
# Karplus-Strong physical modeling guitar synthesizer
# Demonstrates segmented envelopes for acoustic string dynamics:
# - Excitation burst brightness and duration envelope
# - Pick position comb filter attenuation envelope
# - Frequency-dependent string decay damping envelope
# - Body resonance impulse response envelope
#
# Synthesizes an acoustic 6-string guitar arpeggio and writes a 16-bit 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;

# Guitar chord notes (Em9: E2, B2, E3, G3, D4, F#4)
my @notes = (
    { name => 'E2',  freq => 82.41,  start => 0.00, dur => 2.4, pick => 0.15 },
    { name => 'B2',  freq => 123.47, start => 0.25, dur => 2.2, pick => 0.20 },
    { name => 'E3',  freq => 164.81, start => 0.50, dur => 2.0, pick => 0.22 },
    { name => 'G3',  freq => 196.00, start => 0.75, dur => 1.8, pick => 0.25 },
    { name => 'D4',  freq => 293.66, start => 1.00, dur => 1.6, pick => 0.28 },
    { name => 'F#4', freq => 369.99, start => 1.25, dur => 1.5, pick => 0.30 },
);

my $total_dur = 3.2;
my $total_samples = int($total_dur * $sample_rate);
my @mix_buffer = (0.0) x $total_samples;

# Master acoustic guitar body resonance envelope (wood warmth)
my $body_env = env(
    [[1.0, 1.2, 0.9, 1.0], [0.1, 0.5, 2.0], [1, -2, 1]],
    is_hold => 1,
);
my $body_static = $body_env->static;

print "Synthesizing Karplus-Strong acoustic guitar arpeggio...\n";

for my $note (@notes) {
    my $f0 = $note->{freq};
    my $start_idx = int($note->{start} * $sample_rate);
    my $note_samples = int($note->{dur} * $sample_rate);
    my $delay_len = int($sample_rate / $f0 + 0.5);
    $delay_len = 2 if $delay_len < 2;

    # Pluck excitation brightness envelope: hard initial attack decaying quickly
    my $pluck_env = perc(0.002, 0.02, peak => 1.0, decay_curve => -4);
    my $pluck_s = $pluck_env->static;

    # Pick position comb filtering (suppresses harmonics at multiples of 1/pick_pos)
    my $pick_pos = $note->{pick}; # fraction of string length [0.1 .. 0.5]
    my $comb_delay = int($delay_len * $pick_pos + 0.5);
    $comb_delay = 1 if $comb_delay < 1;

    # Dynamic damping envelope: higher damping at beginning, settles to natural sustain
    my $damping_env = env(
        [[0.485, 0.496, 0.492], [0.08, $note->{dur} - 0.08], [2, 1]],
        is_hold => 1,
    );
    my $damp_s = $damping_env->static;

    # Circular delay line initialized with noise excitation
    my @delay_line;
    for my $i (0 .. $delay_len - 1) {
        my $t = $i / $sample_rate;
        my $amp = $pluck_s->($t);
        my $noise = (rand(2.0) - 1.0) * $amp;
        push @delay_line, $noise;
    }

    # Apply pick comb filter: excitation(n) - excitation(n - comb_delay)
    my @excitation = @delay_line;
    for my $i (0 .. $delay_len - 1) {
        my $prev_i = ($i - $comb_delay + $delay_len) % $delay_len;
        $delay_line[$i] = 0.5 * ($excitation[$i] - 0.7 * $excitation[$prev_i]);
    }

    # Low-pass filter loop (string vibration simulation)
    my $ptr = 0;
    my $prev_sample = 0.0;

    for my $n (0 .. $note_samples - 1) {
        my $t = $n / $sample_rate;
        my $damp = $damp_s->($t);

        my $current = $delay_line[$ptr];
        # Two-point moving average lowpass filter with damping factor
        my $filtered = damp_sample($current, $prev_sample, $damp);
        $prev_sample = $current;
        $delay_line[$ptr] = $filtered;
        $ptr = ($ptr + 1) % $delay_len;

        my $target = $start_idx + $n;
        last if $target >= $total_samples;

        # Body resonance modulation
        my $body_mod = $body_static->($t);
        $mix_buffer[$target] += $current * $body_mod * 0.45;
    }
}

sub damp_sample {
    my ($cur, $prev, $damp) = @_;
    return ($cur + $prev) * $damp;
}

# Normalize and render to 16-bit PCM WAV
my $max_amp = 0.0001;
for my $s (@mix_buffer) {
    my $abs = abs($s);
    $max_amp = $abs if $abs > $max_amp;
}
my $gain = 0.85 / $max_amp;

my $wav_file = 'guitar_strum.wav';
open my $out, '>:raw', $wav_file or die "Cannot open $wav_file: $!\n";

my $num_channels = 1;
my $bits_per_sample = 16;
my $byte_rate = $sample_rate * $num_channels * ($bits_per_sample / 8);
my $block_align = $num_channels * ($bits_per_sample / 8);
my $data_chunk_size = $total_samples * $block_align;
my $riff_size = 36 + $data_chunk_size;

# Write RIFF/WAVE header
print $out "RIFF" . pack('V', $riff_size) . "WAVE";
print $out "fmt " . pack('V', 16) . pack('v', 1) . pack('v', $num_channels);
print $out pack('V', $sample_rate) . pack('V', $byte_rate);
print $out pack('v', $block_align) . pack('v', $bits_per_sample);
print $out "data" . pack('V', $data_chunk_size);

# Write 16-bit PCM samples
for my $s (@mix_buffer) {
    my $norm = $s * $gain;
    $norm = 1.0 if $norm > 1.0;
    $norm = -1.0 if $norm < -1.0;
    my $sample_16 = int($norm * 32767.0);
    print $out pack('s<', $sample_16);
}
close $out;

printf "Wrote %s (%.2f sec, 44.1 kHz, 16-bit mono)\n", $wav_file, $total_dur;

# ASCII preview of audio waveform amplitude envelope
print "\nWaveform Energy Envelope:\n";
my $cols = 64;
my $rows = 8;
my $samples_per_col = int($total_samples / $cols);
my @peaks;
for my $c (0 .. $cols - 1) {
    my $col_max = 0.0;
    my $offset = $c * $samples_per_col;
    for my $i (0 .. $samples_per_col - 1) {
        my $val = abs($mix_buffer[$offset + $i] * $gain);
        $col_max = $val if $val > $col_max;
    }
    push @peaks, $col_max;
}

for my $r (reverse 1 .. $rows) {
    my $thresh = $r / $rows;
    printf "%4.1f |", $thresh;
    for my $c (0 .. $cols - 1) {
        print ($peaks[$c] >= $thresh ? '#' : ($peaks[$c] >= $thresh - 0.5/$rows ? ':' : ' '));
    }
    print "\n";
}
print "     +" . ("-" x $cols) . "\n";
print "      0.0s" . (" " x ($cols - 10)) . sprintf("%.1fs\n", $total_dur);
