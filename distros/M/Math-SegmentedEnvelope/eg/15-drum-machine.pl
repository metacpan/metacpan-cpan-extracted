#!/usr/bin/env perl
# Simple drum pattern generator: kick + snare + hihat as raw PCM
#
# Usage:
#   perl eg/15-drum-machine.pl | aplay -f S16_LE -r 44100 -c 1
#   perl eg/15-drum-machine.pl | sox -t raw -r 44100 -b 16 -e signed -c 1 - out.wav
use strict;
use warnings;
use Math::SegmentedEnvelope qw(perc adsr env);

my $sr  = 44100;
my $bpm = 120;
my $beat = 60 / $bpm;
my $bars = 2;
my $total = $beat * 4 * $bars;
my $frames = int($total * $sr);
my $pi2 = 2 * 3.14159265358979323846;

# Kick: low sine with pitch drop + short amp envelope
my $kick_amp   = perc(0.005, 0.15, peak => 0.9);
my $kick_pitch = env([[150, 55], [0.05], [-4]], is_hold => 1);

# Snare: noise burst + mid-freq body
my $snare_amp  = perc(0.002, 0.12, peak => 0.6);

# Hihat: very short noise burst
my $hat_amp = perc(0.001, 0.04, peak => 0.3);
my $hat_open = perc(0.001, 0.15, peak => 0.25);

# Pattern: x = kick, o = snare, . = closed hat, O = open hat
#          |x..x|o...|x..x|o.O.|
my @pattern = (
    # beat subdivisions (16th notes)
    [qw(K . H .)],  [qw(. . H .)],  [qw(S . H .)],  [qw(. . H .)],
    [qw(K . H .)],  [qw(. . H .)],  [qw(S . H O)],  [qw(. . . .)],
);

# Pre-render each hit into a buffer
sub render_hit {
    my ($amp_env, $freq_fn, $dur) = @_;
    my $n = int($dur * $sr);
    my $s = $amp_env->static;
    my @buf;
    my $phase = 0;
    for my $i (0 .. $n - 1) {
        my $t = $i / $sr;
        my $a = $s->($t);
        my $f = ref $freq_fn ? $freq_fn->($t) : $freq_fn;
        push @buf, sin($phase) * $a;
        $phase += $pi2 * $f / $sr;
    }
    return \@buf;
}

sub render_noise {
    my ($amp_env, $dur) = @_;
    my $n = int($dur * $sr);
    my $s = $amp_env->static;
    my @buf;
    for my $i (0 .. $n - 1) {
        my $t = $i / $sr;
        push @buf, (rand() * 2 - 1) * $s->($t);
    }
    return \@buf;
}

my $kp = $kick_pitch->static;
my $kick_buf  = render_hit($kick_amp, sub { $kp->($_[0]) }, 0.2);
my $snare_buf = render_noise($snare_amp, 0.15);
my $hat_buf   = render_noise($hat_amp, 0.05);
my $hato_buf  = render_noise($hat_open, 0.2);

# Mix pattern into output buffer
my @out = (0) x $frames;
my $step = $beat / 4;  # 16th note

for my $bar (0 .. $bars - 1) {
    for my $beat_idx (0 .. 3) {
        my $hits = $pattern[$bar * 4 + $beat_idx];
        for my $sub (0 .. 3) {
            my $hit = $hits->[$sub];
            my $pos = int(($bar * 4 + $beat_idx + $sub * 0.25) * $beat * $sr);
            my $buf;
            $buf = $kick_buf  if $hit eq 'K';
            $buf = $snare_buf if $hit eq 'S';
            $buf = $hat_buf   if $hit eq 'H';
            $buf = $hato_buf  if $hit eq 'O';
            next unless $buf;
            for my $j (0 .. $#$buf) {
                $out[$pos + $j] += $buf->[$j] if $pos + $j < $frames;
            }
        }
    }
}

# Output as 16-bit PCM
binmode STDOUT;
for my $v (@out) {
    $v =  1.0 if $v >  1.0;
    $v = -1.0 if $v < -1.0;
    print pack('v', int($v * 32767) & 0xFFFF);
}

warn sprintf "Wrote %d frames (%.2fs) at %d Hz, %d BPM\n",
    $frames, $total, $sr, $bpm;
