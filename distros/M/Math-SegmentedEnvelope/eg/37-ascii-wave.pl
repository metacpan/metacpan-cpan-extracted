#!/usr/bin/env perl
# ASCII wave animation: envelope shapes rippling across the terminal
# Shows how is_fold_over creates standing waves and how morphers shape them
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc);
use Time::HiRes qw(time sleep);

$| = 1;

my $width  = 78;
my $height = 18;
my $fps    = 15;

# Wave envelope: single arch that will be wrapped/folded
my $wave = env(
    [[0, 1, 0], [0.5, 0.5], [2, -2]],
    is_morph => 1,
    morpher_formula => 'smoothstep',
    is_fold_over => 1,
);

# Decay envelope for amplitude
my $decay = perc(0.01, 4.0, peak => 1.0);

my $wave_s = $wave->static;
my $decay_s = $decay->static;
my $wave_dur = $wave->duration;

my @morphers = qw(linear smoothstep bounce_out elastic_out cubic_inout);
my $morpher_idx = 0;

print "\e[2J";  # clear screen

my $t0 = time();
for (my $frame = 0; $frame < $fps * 6; $frame++) {
    my $t = $frame / $fps;

    # Switch morpher every 1.5 seconds
    if ($frame > 0 && $frame % ($fps * 1.5) == 0) {
        $morpher_idx = ($morpher_idx + 1) % @morphers;
        $wave->morpher_formula($morphers[$morpher_idx]);
        $wave_s = $wave->static;
    }

    my $amp = $decay_s->($t);

    # Build frame buffer
    my @grid;
    for my $y (0 .. $height - 1) { $grid[$y] = [(' ') x $width] }

    # Draw wave: each column is a time-shifted envelope sample
    for my $x (0 .. $width - 1) {
        # Phase shifts create the traveling wave effect
        my $phase = ($x / $width) * 3 + $t * 2;
        my $val = $wave_s->($phase * $wave_dur) * $amp;

        my $y = int((1 - $val) * 0.5 * ($height - 1) + $height * 0.25);
        $y = 0 if $y < 0;
        $y = $height - 1 if $y >= $height;

        # Draw with intensity based on amplitude
        my $ch = $val > 0.8 ? '#' : $val > 0.5 ? '*' : $val > 0.2 ? '~' : '.';
        $grid[$y][$x] = $ch;

        # Reflection for standing wave effect
        my $ry = $height - 1 - $y;
        $grid[$ry][$x] = '.' if $grid[$ry][$x] eq ' ' && $val > 0.3;
    }

    # Render
    print "\e[H";  # cursor home
    printf " morpher: %-14s  t=%.1f  amp=%.2f\n\n", $morphers[$morpher_idx], $t, $amp;
    for my $row (@grid) {
        print ' ', join('', @$row), "\n";
    }

    # Frame timing
    my $target = $t0 + ($frame + 1) / $fps;
    my $wait = $target - time();
    sleep($wait) if $wait > 0;
}

print "\e[", $height + 4, "H\n";
