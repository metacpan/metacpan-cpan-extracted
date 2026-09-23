#!/usr/bin/env perl
# Fractal envelope: recursively apply shape at multiple scales
# Creates self-similar patterns useful for natural-looking modulation
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc spline);

my $width  = 72;
my $height = 14;

# Base shape: a simple arch
my $base = env([[0, 1, 0], [0.5, 0.5], [2, -2]],
    is_morph => 1, morpher_formula => 'smoothstep');

# Recursive fractal: at each level, replace each segment's shape
# with a scaled copy of the base
sub fractal {
    my ($shape, $depth, $base_shape, $res) = @_;
    return $shape if $depth <= 0;

    # Sample current shape at high resolution
    my $n = $res * $shape->segments;
    my @vals = $shape->table($n);
    my $dur = $shape->duration;

    # Modulate each sample by the base shape at a higher frequency
    my $base_s = $base_shape->static;
    my $base_dur = $base_shape->duration;
    my $freq = $shape->segments * (2 ** $depth);

    my @modulated;
    for my $i (0 .. $#vals) {
        my $t = $i / $#vals;
        # Base shape phase cycles $freq times across the envelope
        my $phase = fmod($t * $freq, 1.0) * $base_dur;
        my $mod = $base_s->($phase);
        # Blend: original * (1 - depth_factor) + modulated * depth_factor
        my $factor = 0.3;
        push @modulated, $vals[$i] * (1 - $factor) + $vals[$i] * $mod * $factor;
    }

    my $result = Math::SegmentedEnvelope->from_samples(\@modulated, $dur);
    return fractal($result, $depth - 1, $base_shape, $res);
}

sub fmod { $_[0] - int($_[0] / $_[1]) * $_[1] }

# Generate fractal at increasing depths
for my $depth (0 .. 4) {
    my $f = fractal($base, $depth, $base, 8);
    printf "\nDepth %d (%d segments):\n", $depth, $f->segments;
    plot($f, $width, $height);
}

# Different base shapes produce different fractals
print "\n--- Fractal from spline base ---\n";
my $spline_base = spline([0, 0.3, 0.7, 1.0], [0, 1, 0.3, 0]);
my $spline_fractal = fractal($spline_base, 3, $spline_base, 8);
printf "Spline fractal (%d segments):\n", $spline_fractal->segments;
plot($spline_fractal, $width, $height);

# Analysis: derivative shows self-similar rate of change
print "\n--- Derivative of depth-3 fractal ---\n";
my $f3 = fractal($base, 3, $base, 8);
my $d = $f3->resample(64)->derivative;
printf "Rate of change (%d segments):\n", $d->segments;
plot($d->normalize, $width, $height);

# Integration: cumulative area under fractal
print "\n--- Integral of depth-3 fractal ---\n";
my $integ = $f3->resample(64)->integrate->normalize;
printf "Cumulative area (%d segments):\n", $integ->segments;
plot($integ, $width, $height);

sub plot {
    my ($e, $w, $h) = @_;
    my @vals = $e->table($w);
    my ($min, $max) = ($vals[0], $vals[0]);
    for (@vals) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
    my $range = $max - $min || 1;

    my @grid;
    for my $y (0 .. $h - 1) { $grid[$y] = [(' ') x $w] }
    for my $x (0 .. $w - 1) {
        my $y = int(($vals[$x] - $min) / $range * ($h - 1) + 0.5);
        $y = 0 if $y < 0; $y = $h - 1 if $y >= $h;
        $grid[$h - 1 - $y][$x] = '*';
    }
    for my $row (@grid) {
        print '  ', join('', @$row), "\n";
    }
}
