#!/usr/bin/env perl
# Vector Laser Light Show & Oscilloscope XY Beam Art Simulator
# Demonstrates segmented envelopes for high-speed beam scanning:
# - Galvanometer XY scanner trajectory envelopes with corner deceleration dwell
# - Laser shutter blanking envelope (rapid on/off during beam transitions)
# - Scanner mechanical inertia / damping simulation
# - Phosphor glow intensity persistence model
#
# Generates an animated multi-path vector laser graphic and exports both ASCII and SVG.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $total_time = 4.0; # 4 seconds of laser animation
my $sample_rate = 2000; # 2000 points per second scanner rate (standard ILDA 30k sub-rate)
my $total_points = int($total_time * $sample_rate);

# Define a geometric vector motif (morphing cyberpunk star/polygon)
# Keyframes for X and Y coordinate waypoints across one cycle
my @key_x = ( 0.0,  0.5,  0.2,  0.8,  0.0, -0.8, -0.2, -0.5,  0.0);
my @key_y = (-0.8, -0.2,  0.5,  0.2,  0.8,  0.2,  0.5, -0.2, -0.8);
my $pts = scalar @key_x;
my @times = map { ($_ / ($pts - 1)) * 1.0 } 0 .. $pts - 1;

# 1. Base geometric path splines (repeating every 1.0s via is_hold => 0)
my $base_x_env = spline(\@times, \@key_x, resolution => 16, is_hold => 0);
my $base_y_env = spline(\@times, \@key_y, resolution => 16, is_hold => 0);

# 2. Scanner rotation & scale morphing envelopes over the 4-second performance
my $rotation_env = env(
    [[0.0, 3.14159, 6.28318, 12.566], [1.0, 1.5, 1.5], [1, 2, 1]],
    is_hold => 1,
);
my $scale_env = env(
    [[0.4, 1.1, 0.6, 1.0], [1.2, 1.3, 1.5], [2, -2, 1]],
    is_hold => 1,
);

# 3. Laser blanking envelope: switches beam on during figures, blank off during jump
my $blanking_env = env(
    [[1.0, 1.0, 0.0, 0.0, 1.0], [0.85, 0.03, 0.09, 0.03], [1, 1, 1, 1]],
    is_hold => 0, # wraps cyclically
);

# 4. Scanner corner dwell envelope: slows down at sharp corners to avoid galvanometer distortion
my $dwell_env = env(
    [[1.0, 0.3, 1.0, 0.3, 1.0], [0.25, 0.25, 0.25, 0.25], [-2, 2, -2, 2]],
    is_hold => 0,
);

my $sx = $base_x_env->static;
my $sy = $base_y_env->static;
my $s_rot = $rotation_env->static;
my $s_scl = $scale_env->static;
my $s_blk = $blanking_env->static;
my $s_dwl = $dwell_env->static;

print "Simulating Vector Laser Galvanometer Scan Paths...\n";

# Simulate galvanometer response with 2nd-order spring-mass-damper physics
# mx'' + cx' + kx = F
my $galvo_x = 0.0; my $galvo_vx = 0.0;
my $galvo_y = 0.0; my $galvo_vy = 0.0;
my $spring_k = 1800.0; # galvo stiffness
my $damping_c = 65.0;  # critically damped mechanical mirrors

my $dt = 1.0 / $sample_rate;
my @recorded_points;

for my $n (0 .. $total_points - 1) {
    my $t = $n * $dt;

    # Evaluate geometry
    my $bx = $sx->($t);
    my $by = $sy->($t);
    my $theta = $s_rot->($t);
    my $scale = $s_scl->($t);
    my $blank = $s_blk->($t);
    my $dwell = $s_dwl->($t);

    # Apply 2D rotation & scale to target coordinates
    my $target_x = ($bx * cos($theta) - $by * sin($theta)) * $scale;
    my $target_y = ($bx * sin($theta) + $by * cos($theta)) * $scale;

    # Galvanometer mirror physics integration
    my $fx = ($target_x - $galvo_x) * $spring_k * $dwell - $galvo_vx * $damping_c;
    my $fy = ($target_y - $galvo_y) * $spring_k * $dwell - $galvo_vy * $damping_c;

    $galvo_vx += $fx * $dt;
    $galvo_x  += $galvo_vx * $dt;
    $galvo_vy += $fy * $dt;
    $galvo_y  += $galvo_vy * $dt;

    push @recorded_points, {
        x => $galvo_x,
        y => $galvo_y,
        beam => $blank > 0.5 ? 1 : 0,
        t => $t,
    } if $n % 4 == 0; # downsample for export
}

# Export SVG Vector Graphic
my $svg_file = 'laser_pattern.svg';
open my $sf, '>', $svg_file or die "Cannot open $svg_file: $!\n";
my $dim = 600;
my $center = $dim / 2;
my $view_scale = 220;

print $sf qq{<svg xmlns="http://www.w3.org/2000/svg" width="$dim" height="$dim" style="background:#05070a">\n};
print $sf qq{  <defs>\n};
print $sf qq{    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">\n};
print $sf qq{      <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur"/>\n};
print $sf qq{      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>\n};
print $sf qq{    </filter>\n};
print $sf qq{  </defs>\n};

# Draw laser trace path segments
my $path_d = '';
my $in_stroke = 0;

for my $p (@recorded_points) {
    my $px = sprintf("%.1f", $center + $p->{x} * $view_scale);
    my $py = sprintf("%.1f", $center - $p->{y} * $view_scale);

    if ($p->{beam}) {
        if (!$in_stroke) {
            $path_d .= "M $px,$py ";
            $in_stroke = 1;
        } else {
            $path_d .= "L $px,$py ";
        }
    } else {
        $in_stroke = 0;
    }
}

print $sf qq{  <path d="$path_d" fill="none" stroke="#00ffcc" stroke-width="1.8" filter="url(#glow)" opacity="0.85"/>\n};
print $sf qq{  <circle cx="$center" cy="$center" r="2" fill="#ffffff" opacity="0.5"/>\n};
print $sf qq{</svg>\n};
close $sf;

printf "Wrote %s (%d beam points simulated)\n", $svg_file, scalar(@recorded_points);

# Render ASCII phosphor display of vector points
print "\nLaser Oscilloscope Vector Display Preview:\n";
my $gw = 55;
my $gh = 23;
my @grid;
for my $y (0 .. $gh - 1) { $grid[$y] = [(' ') x $gw]; }

# Intensity accumulation buffer
my @acc = map { [(0) x $gw] } 0 .. $gh - 1;

for my $p (@recorded_points) {
    next unless $p->{beam};
    my $gx = int(($p->{x} + 1.2) / 2.4 * ($gw - 1) + 0.5);
    my $gy = int((- $p->{y} + 1.2) / 2.4 * ($gh - 1) + 0.5);

    if ($gx >= 0 && $gx < $gw && $gy >= 0 && $gy < $gh) {
        $acc[$gy][$gx]++;
    }
}

for my $y (0 .. $gh - 1) {
    for my $x (0 .. $gw - 1) {
        my $count = $acc[$y][$x];
        my $char = ' ';
        $char = '.' if $count >= 1;
        $char = '*' if $count >= 3;
        $char = 'o' if $count >= 6;
        $char = '#' if $count >= 10;
        $grid[$y][$x] = $char;
    }
}

for my $y (0 .. $gh - 1) {
    print "  |" . join('', @{$grid[$y]}) . "|\n";
}
print "  +" . ("-" x $gw) . "+\n";
