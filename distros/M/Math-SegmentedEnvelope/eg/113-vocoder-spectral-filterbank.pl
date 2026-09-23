#!/usr/bin/env perl
# 16-Band Channel Vocoder (Analysis & Resynthesis Filterbank)
# Demonstrates segmented envelopes for spectral processing:
# - Analysis filter envelope followers (dynamic attack/release ballistics)
# - Carrier harmonic richness envelope (sawtooth harmonics + sibilant noise)
# - Formant warping envelope (dynamic band frequency shift for robotic/alien voice)
# - Master vocoded speech-synth amplitude envelope
#
# Generates a robotic talking synthesizer phrase and writes 16-bit 44.1kHz WAV.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $sample_rate = 44100;
my $pi = 3.141592653589793;
my $dur = 3.0;
my $total_samples = int($dur * $sample_rate);

# 16 standard vocoder center frequencies (logarithmically spaced 200 Hz to 6400 Hz)
my @band_freqs = map { 200 * (2.0 ** ($_ * 5.0 / 15.0)) } 0 .. 15;
my $num_bands = scalar @band_freqs;

# 1. Modulator speech phoneme envelopes (simulating "A - E - I - O - U" formant shifts)
# Formants: each vowel activates distinct frequency bands over time
my @vowel_profiles = (
    # [F1 band, F2 band, F3 band]
    [2, 7, 11],  # /a/ (Ah)
    [3, 10, 13], # /e/ (Eh)
    [1, 12, 14], # /i/ (Ee)
    [2, 5, 10],  # /o/ (Oh)
    [1, 4, 9],   # /u/ (Oo)
);

# Envelope for speech rhythm articulation (5 syllables)
my $speech_amp_env = env(
    [[0, 1, 0.2, 1, 0.2, 1, 0.2, 1, 0.2, 1, 0],
     [0.1, 0.45, 0.1, 0.45, 0.1, 0.45, 0.1, 0.45, 0.1, 0.45],
     [2, -2, 2, -2, 2, -2, 2, -2, 2, -2]],
    is_hold => 1,
);
my $speech_s = $speech_amp_env->static;

# 2. Formant shift envelope: pitch / gender warping over time
my $formant_shift_env = spline(
    [0.0, 0.8, 1.5, 2.3, 3.0],
    [0.0, 1.5, -1.0, 2.0, 0.0], # band shift offsets
    resolution => 8,
    is_hold => 1,
);
my $formant_s = $formant_shift_env->static;

# 3. Carrier synthesizer pitch envelope (bass note glide C2 -> G2 -> C3)
my $carrier_pitch_env = spline(
    [0.0, 0.6, 1.2, 1.8, 2.4, 3.0],
    [65.41, 65.41, 98.00, 98.00, 130.81, 65.41],
    resolution => 8,
    is_hold => 1,
);
my $pitch_s = $carrier_pitch_env->static;

# 4. Carrier noise envelope (adds unvoiced noise for consonant intelligibility)
my $noise_env = env(
    [[0.05, 0.35, 0.05, 0.35, 0.05, 0.35, 0.05, 0.05],
     [0.5, 0.1, 0.6, 0.1, 0.7, 0.1, 0.9],
     [1, 1, 1, 1, 1, 1, 1]],
    is_hold => 1,
);
my $noise_s = $noise_env->static;

# Precompute 2nd-order resonant bandpass filter coefficients (biquads) for synthesis
my @bp_filters;
for my $fc (@band_freqs) {
    my $q = 8.0; # resonance
    my $w0 = 2.0 * $pi * $fc / $sample_rate;
    my $alpha = sin($w0) / (2.0 * $q);
    my $b0 =  $alpha;
    my $b1 =  0.0;
    my $b2 = -$alpha;
    my $a0 =  1.0 + $alpha;
    my $a1 = -2.0 * cos($w0);
    my $a2 =  1.0 - $alpha;

    push @bp_filters, {
        b0 => $b0 / $a0, b1 => $b1 / $a0, b2 => $b2 / $a0,
        a1 => $a1 / $a0, a2 => $a2 / $a0,
        x1 => 0.0, x2 => 0.0, y1 => 0.0, y2 => 0.0,
    };
}

print "Synthesizing 16-Band Spectral Vocoder...\n";

my @out_buffer = (0.0) x $total_samples;
my $carrier_phase = 0.0;
my @spectral_history; # for ASCII visualization

# Process in blocks of 128 samples
my $block_size = 128;
my $num_blocks = int($total_samples / $block_size);

for my $blk (0 .. $num_blocks - 1) {
    my $t_block = ($blk * $block_size) / $sample_rate;
    my $speech_gain = $speech_s->($t_block);
    my $f_shift = $formant_s->($t_block);
    my $c_freq = $pitch_s->($t_block);
    my $noise_mix = $noise_s->($t_block);

    # Modulator band energies: simulate active vowels over 5 time regions
    my $vowel_idx = int(($t_block / $dur) * 5.0);
    $vowel_idx = 4 if $vowel_idx > 4;
    my $active_formants = $vowel_profiles[$vowel_idx];

    # Compute target energy per band
    my @band_energies = (0.02) x $num_bands;
    for my $f_band (@$active_formants) {
        my $shifted_band = int($f_band + $f_shift + 0.5);
        $shifted_band = 0 if $shifted_band < 0;
        $shifted_band = 15 if $shifted_band > 15;
        $band_energies[$shifted_band] = 1.0;
        # Spread to neighboring bands
        $band_energies[$shifted_band - 1] += 0.4 if $shifted_band > 0;
        $band_energies[$shifted_band + 1] += 0.4 if $shifted_band < 15;
    }

    # Store for visualization every 10 blocks
    if ($blk % 12 == 0) {
        push @spectral_history, [ map { $_ * $speech_gain } @band_energies ];
    }

    # Generate carrier audio block: rich sawtooth wave + white noise
    for my $n (0 .. $block_size - 1) {
        my $sample_idx = $blk * $block_size + $n;
        last if $sample_idx >= $total_samples;

        # Sawtooth wave carrier
        my $saw = 2.0 * ($carrier_phase / (2.0 * $pi)) - 1.0;
        # White noise
        my $noise = rand(2.0) - 1.0;
        my $carrier = (1.0 - $noise_mix) * $saw + $noise_mix * $noise;

        $carrier_phase += 2.0 * $pi * $c_freq / $sample_rate;
        $carrier_phase -= 2.0 * $pi if $carrier_phase >= 2.0 * $pi;

        # Filter carrier through all 16 synthesis bands weighted by modulator energy
        my $vocoded_sample = 0.0;
        for my $b (0 .. $num_bands - 1) {
            my $flt = $bp_filters[$b];
            my $in = $carrier;
            my $out = $flt->{b0} * $in
                    + $flt->{b1} * $flt->{x1}
                    + $flt->{b2} * $flt->{x2}
                    - $flt->{a1} * $flt->{y1}
                    - $flt->{a2} * $flt->{y2};

            $flt->{x2} = $flt->{x1};
            $flt->{x1} = $in;
            $flt->{y2} = $flt->{y1};
            $flt->{y1} = $out;

            $vocoded_sample += $out * $band_energies[$b];
        }

        $out_buffer[$sample_idx] = $vocoded_sample * $speech_gain * 0.25;
    }
}

# Normalize and write WAV
my $max_val = 0.0001;
for my $s (@out_buffer) {
    my $a = abs($s);
    $max_val = $a if $a > $max_val;
}
my $gain = 0.85 / $max_val;

my $wav_file = 'vocoder_output.wav';
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

for my $s (@out_buffer) {
    my $v = int($s * $gain * 32767.0);
    $v = 32767 if $v > 32767; $v = -32768 if $v < -32768;
    print $out pack('s<', $v);
}
close $out;

printf "Wrote %s (%.2fs vocoded speech, 16 bands)\n", $wav_file, $dur;

# ASCII 16-Band Spectral Energy Waterfall
print "\n16-Band Vocoder Spectral Activity Matrix:\n";
print " Band | Freq (Hz) | Spectral Activity Timeline (0.0s -> 3.0s)\n";
print "------+-----------+-----------------------------------------------\n";
for my $b (reverse 0 .. $num_bands - 1) {
    printf "  #%02d |  %5.0f Hz | ", $b + 1, $band_freqs[$b];
    for my $frame (@spectral_history) {
        my $e = $frame->[$b];
        my $ch = ' ';
        $ch = '.' if $e > 0.15;
        $ch = '-' if $e > 0.35;
        $ch = '+' if $e > 0.60;
        $ch = '#' if $e > 0.85;
        print $ch;
    }
    print "\n";
}
print "------+-----------+-----------------------------------------------\n";
