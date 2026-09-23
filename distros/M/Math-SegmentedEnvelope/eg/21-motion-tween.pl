#!/usr/bin/env perl
# Motion tweening: animate an object along a path with easing
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env spline);

# Path: spline through waypoints
my $path_x = spline([0, 0.3, 0.7, 1.0], [5,  60, 20, 70], resolution => 12);
my $path_y = spline([0, 0.3, 0.7, 1.0], [2,  5,  18, 2],  resolution => 12);

# Timing curve: controls speed along the path
# bounce_out gives a playful arrival at each waypoint
my $timing = env([[0, 1], [1], [1]],
    morpher_formula => 'bounce_out');

# Size: scale pulse at waypoints
my $scale = spline([0, 0.28, 0.32, 0.68, 0.72, 1.0],
                   [1,  1,   1.3,   1,   1.3,  1.0],
                   resolution => 4);

# Rotation: spin with elastic settle
my $rotation = env([[0, 360], [1], [1]],
    morpher_formula => 'elastic_out');

my $ts = $timing->static;
my $xs = $path_x->static;
my $ys = $path_y->static;
my $ss = $scale->static;
my $rs = $rotation->static;

my $fps = 20;
my $dur = 2.0;  # animation duration
my $frames = int($dur * $fps);

printf "Motion tween: %.1fs at %d fps\n\n", $dur, $fps;
printf "%-5s  %5s  %5s  %5s  %5s\n", 'time', 'x', 'y', 'scale', 'rot';
printf "%-5s  %5s  %5s  %5s  %5s\n", '----', '---', '---', '-----', '---';

for my $f (0 .. $frames) {
    my $t_linear = $f / $frames;

    # Apply timing curve: remaps linear time to eased time
    my $t_eased = $ts->($t_linear * $timing->duration);

    # Sample path at eased time
    my $x   = $xs->($t_eased * $path_x->duration);
    my $y   = $ys->($t_eased * $path_y->duration);
    my $s   = $ss->($t_linear * $scale->duration);
    my $rot = $rs->($t_linear * $rotation->duration);

    printf "%4.2f  %5.1f  %5.1f  %5.2f  %5.0f", $t_linear, $x, $y, $s, $rot;

    # ASCII viewport
    my $ix = int($x + 0.5);
    $ix = 0 if $ix < 0;
    $ix = 75 if $ix > 75;
    my $marker = $s > 1.15 ? 'O' : 'o';
    print '  ' . (' ' x $ix) . $marker;
    print "\n";
}

# Compare different timing curves on the same path
print "\nTiming curve comparison (x position at t=0.5):\n";
for my $easing (qw(linear quad_out cubic_out back_out elastic_out bounce_out)) {
    my $te = env([[0, 1], [1], [1]], morpher_formula => $easing);
    my $t_mid = $te->at(0.5);
    my $x_mid = $xs->($t_mid * $path_x->duration);
    printf "  %-14s  t_eased=%.3f  x=%.1f\n", $easing, $t_mid, $x_mid;
}
