#!/usr/bin/env perl
# Data sonification: pipe any numbers into sound
# Reads values from stdin (one per line), converts to envelope, plays as audio
#
# Usage:
#   seq 0 0.01 1 | perl -e 'print sin($_*6.28)*100+200, "\n" for map $_/100, 0..100' | \
#       perl eg/38-data-sonification.pl | aplay -f S16_LE -r 44100 -c 1
#
#   # Or generate test data inline:
#   perl eg/38-data-sonification.pl --demo | aplay -f S16_LE -r 44100 -c 1
use strict;
use warnings;
use Math::SegmentedEnvelope;

my $sr  = 44100;
my $dur = 2.0;
my $pi2 = 2 * 3.14159265358979323846;

my @values;

if (@ARGV && $ARGV[0] eq '--demo') {
    # Generate demo data: a chirp
    @values = map { sin($_ * $_ * 0.001) * 0.5 + 0.5 } 0 .. 99;
    warn "Demo mode: 100 samples (chirp pattern)\n";
} else {
    # Read from stdin
    while (<STDIN>) {
        chomp;
        next unless /^[\d.\-+eE]+$/;
        push @values, $_ + 0;
        last if @values > 10000;
    }
    die "Need at least 2 values on stdin (one per line)\n" unless @values >= 2;
    warn sprintf "Read %d values, range [%.2f, %.2f]\n",
        scalar @values, (sort { $a <=> $b } @values)[0], (sort { $a <=> $b } @values)[-1];
}

# Create envelope from samples
my $data_env = Math::SegmentedEnvelope->from_samples(\@values, $dur);

# Normalize to [0, 1] for pitch mapping
my $pitch_env = $data_env->normalize(0, 1);

# Smooth for less harsh transitions
my $smooth_env = $pitch_env->smooth(2);

# Amplitude envelope: fade in/out
my $amp = Math::SegmentedEnvelope->new(
    [[0, 1, 1, 0], [0.05, $dur - 0.15, 0.1], [2, 1, -2]],
    is_hold => 1,
);

my $pitch_s = $smooth_env->static;
my $amp_s   = $amp->static;

# Map envelope [0,1] to frequency range [200, 800] Hz
my $freq_lo = 200;
my $freq_hi = 800;

my $frames = int($dur * $sr);
my $phase = 0;

binmode STDOUT;
for my $i (0 .. $frames - 1) {
    my $t = $i / $sr;
    my $p = $pitch_s->($t);
    my $a = $amp_s->($t);
    my $freq = $freq_lo + $p * ($freq_hi - $freq_lo);

    my $val = sin($phase) * $a * 0.8;

    my $sample = int($val * 32767);
    $sample =  32767 if $sample >  32767;
    $sample = -32768 if $sample < -32768;
    print pack('v', $sample & 0xFFFF);

    $phase += $pi2 * $freq / $sr;
    $phase -= $pi2 if $phase >= $pi2;
}

warn sprintf "Sonified %d values -> %.1fs audio at %d Hz\n",
    scalar @values, $dur, $sr;
