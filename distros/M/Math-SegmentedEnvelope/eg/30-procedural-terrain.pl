#!/usr/bin/env perl
# Procedural terrain: spline envelope as 1D heightmap cross-section
use strict;
use warnings;
use Math::SegmentedEnvelope qw(spline env);

srand(42);

# Generate random terrain control points
my $width = 80;
my $height = 20;
my $num_points = 8;

my @times  = map { $_ / ($num_points - 1) } 0 .. $num_points - 1;
my @values;
push @values, 0.3;  # start at sea level
for my $i (1 .. $num_points - 2) {
    push @values, 0.2 + rand(0.7);  # random heights
}
push @values, 0.2;  # end at sea level

# Smooth terrain via Catmull-Rom spline
my $terrain = spline(\@times, \@values, resolution => 16);
printf "Terrain: %d segments, duration=%.2f\n", $terrain->segments, $terrain->duration;

# Quantized version (voxel/minecraft style)
my $voxel = $terrain->quantize(8);

# Eroded version (smoothed + lowered)
my $eroded = $terrain->normalize(0.1, 0.7);

# Render three versions side by side
my @versions = (
    ['Smooth terrain', $terrain],
    ['Voxel (quantize 8)', $voxel],
    ['Eroded (normalized)', $eroded],
);

for my $pair (@versions) {
    my ($label, $e) = @$pair;
    printf "\n%s:\n", $label;

    my @vals = $e->table($width);
    my $sea_level = 0.3;

    for my $y (reverse 0 .. $height - 1) {
        my $level = $y / ($height - 1);
        for my $x (0 .. $width - 1) {
            my $h = $vals[$x];
            if ($level <= $h && $level > $h - 1/$height) {
                print $level > 0.7 ? '^' : '#';  # peak vs rock
            } elsif ($level <= $h) {
                if ($level <= $sea_level) {
                    print ':';  # underground
                } else {
                    print '.';  # earth
                }
            } elsif ($level <= $sea_level) {
                print '~';  # water
            } else {
                print ' ';
            }
        }
        print "\n";
    }
}

# Terrain statistics
printf "\nTerrain stats:\n";
printf "  Height range: %.2f - %.2f\n", $terrain->min_value, $terrain->max_value;
printf "  Sea level:    0.30\n";
my $above_sea = grep { $_ > 0.3 } $terrain->table(1000);
printf "  Land mass:    %.1f%%\n", $above_sea / 10;
