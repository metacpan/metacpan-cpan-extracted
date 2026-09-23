#!/usr/bin/env perl
# Catmull-Rom spline envelopes
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline);

# Simple arc through 3 points
my $arc = spline([0, 0.5, 1.0], [0, 1, 0]);
printf "Arc: %d segments, duration %.2f\n", $arc->segments, $arc->duration;
printf "  Control: at(0)=%.2f at(0.5)=%.2f at(1)=%.2f\n",
    $arc->at(0), $arc->at(0.5), $arc->at(1);
printf "  Mid-span: at(0.25)=%.4f at(0.75)=%.4f\n",
    $arc->at(0.25), $arc->at(0.75);

# Complex shape with 6 control points
print "\nComplex spline:\n";
my @times  = (0, 0.15, 0.3, 0.5, 0.8, 1.0);
my @values = (0, 0.9,  0.2, 0.7, 0.4, 0);
my $complex = spline(\@times, \@values, resolution => 12);

printf "  %d segments, duration %.2f\n", $complex->segments, $complex->duration;
for my $i (0 .. $#times) {
    my $got = $complex->at($times[$i]);
    printf "  t=%.2f: target=%.1f got=%.4f %s\n",
        $times[$i], $values[$i], $got,
        abs($got - $values[$i]) < 0.001 ? 'OK' : 'MISS';
}

# Tension parameter: 0=smooth (Catmull-Rom), 1=linear (straight lines)
print "\nTension comparison at t=0.25:\n";
for my $tension (0, 0.25, 0.5, 0.75, 1.0) {
    my $s = spline([0, 0.5, 1.0], [0, 1, 0], tension => $tension);
    printf "  tension=%.2f: at(0.25)=%.4f\n", $tension, $s->at(0.25);
}

# High-resolution for smooth curves
my $hires = spline([0, 0.3, 0.7, 1.0], [0, 1, 0.5, 0],
                   resolution => 32);
printf "\nHi-res: %d segments\n", $hires->segments;

# Spline with morpher
my $morphed = spline([0, 0.5, 1.0], [0, 1, 0],
                     morpher_formula => 'smoothstep');
printf "Morphed: is_morph=%d at(0.25)=%.4f\n",
    $morphed->is_morph, $morphed->at(0.25);

# ASCII plot of the complex spline
print "\n";
my $width = 60;
my $height = 12;
my @vals = $complex->table($width);
my ($min, $max) = ($vals[0], $vals[0]);
for (@vals) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
my $range = $max - $min || 1;

for my $y (reverse 0 .. $height - 1) {
    my $level = $min + $y / ($height - 1) * $range;
    printf "%5.2f |", $level;
    for my $x (0 .. $width - 1) {
        my $vy = int(($vals[$x] - $min) / $range * ($height - 1) + 0.5);
        print $vy == $y ? '*' : ' ';
    }
    print "\n";
}
printf "      +%s\n", '-' x $width;
