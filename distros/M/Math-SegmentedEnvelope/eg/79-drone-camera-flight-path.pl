#!/usr/bin/env perl
# Cinematic 3D Drone Trajectory & Synchronized Camera Gimbal Path
# Demonstrates:
#   1. Multi-axis synchronized spatial interpolation using Catmull-Rom spline()
#   2. Eased camera gimbal orientation (Yaw/Pitch) and focal length zoom
#   3. Using derivative() for 3D flight velocity and G-force load telemetry
#   4. Multi-view ASCII flight path telemetry (Top-Down & Side Elevation)
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env spline);

# Flight duration in seconds
my $duration = 20.0;

# Waypoints: Time (s) -> Spatial Position (meters: X, Y, Altitude Z)
# 1. Start: Hover at establishing height (0, 0, 15m)
# 2. Fly-in: Glide forward and descend toward subject (20m, 10m, 5m)
# 3. Orbit: Arc around subject (30m, 25m, 4m)
# 4. Low sweep: Reveal shot behind subject (10m, 35m, 3m)
# 5. Hero climb: Ascend and pull back ( -5m, 45m, 25m)
my @t_wps = (0.0,  5.0, 10.0, 15.0, 20.0);
my @x_wps = (0.0, 20.0, 30.0, 10.0, -5.0);
my @y_wps = (0.0, 10.0, 25.0, 35.0, 45.0);
my @z_wps = (15.0, 5.0,  4.0,  3.0, 25.0);

# Build 3D spatial splines (smooth curvature through waypoints)
my $spline_x = spline(\@t_wps, \@x_wps, resolution => 16, tension => 0.0);
my $spline_y = spline(\@t_wps, \@y_wps, resolution => 16, tension => 0.0);
my $spline_z = spline(\@t_wps, \@z_wps, resolution => 16, tension => 0.0);

# Camera Gimbal: Pitch (tilt degrees down), Yaw (pan degrees), FOV (zoom degrees)
# Eased transitions using segmented envelopes
my $gimbal_pitch = env([
    [-15.0, -35.0, -45.0, -10.0, -50.0],
    [5.0, 5.0, 5.0, 5.0],
    [2.0, 1.0, -2.0, 2.0]
], is_hold => 1, is_morph => 1, morpher_formula => 'smoothstep');

my $camera_fov = env([
    [75.0, 50.0, 35.0, 60.0, 85.0], # Wide -> Close-up zoom -> Wide hero reveal
    [5.0, 5.0, 5.0, 5.0],
    [1.0, 1.5, 1.0, 2.0]
], is_hold => 1);

# Calculate 3D velocity components vx(t), vy(t), vz(t) via derivative()
my $dx = $spline_x->derivative;
my $dy = $spline_y->derivative;
my $dz = $spline_z->derivative;

print "=" x 75, "\n";
print "  Cinematic Drone Trajectory & 6-DOF Gimbal Path Planner\n";
print "=" x 75, "\n";
printf "Flight Duration: %.1fs | Trajectory: %d Segments per Axis\n",
    $duration, $spline_x->segments;
print "-" x 75, "\n";

# ASCII Top-Down Grid (X from -10 to +35, Y from 0 to 50)
my $grid_w = 40;
my $grid_h = 12;
my @top_grid;
for my $r (0 .. $grid_h - 1) {
    $top_grid[$r] = [('.') x $grid_w];
}

# Plot trajectory points
my $fps = 10;
my $total_frames = int($duration * $fps);
my $max_speed = 0.0;

for my $f (0 .. $total_frames) {
    my $t = ($f / $total_frames) * $duration;
    my $x = $spline_x->at($t);
    my $y = $spline_y->at($t);
    my $z = $spline_z->at($t);

    my $vx = $dx->at($t);
    my $vy = $dy->at($t);
    my $vz = $dz->at($t);
    my $speed = sqrt($vx * $vx + $vy * $vy + $vz * $vz);
    $max_speed = $speed if $speed > $max_speed;

    # Map X [-10, 35] and Y [0, 50] to top grid
    my $gx = int((($x - (-10.0)) / 45.0) * ($grid_w - 1));
    my $gy = int(($y / 50.0) * ($grid_h - 1));
    if ($gx >= 0 && $gx < $grid_w && $gy >= 0 && $gy < $grid_h) {
        $top_grid[$grid_h - 1 - $gy][$gx] = ($f == 0) ? 'S' : ($f == $total_frames ? 'E' : '*');
    }
}

print "Top-Down Flight Path Map (S = Start, E = End, * = Path):\n";
for my $r (0 .. $grid_h - 1) {
    printf "  Y=%4.1fm |%s|\n",
        (1.0 - $r / ($grid_h - 1)) * 50.0,
        join('', @{$top_grid[$r]});
}
print "          +" . ("-" x $grid_w) . "+\n";
print "          X=-10m" . (" " x ($grid_w - 14)) . "+35m\n";
print "-" x 75, "\n";

# Frame Telemetry Table
print "Keyframe Director Log:\n";
printf "%-5s | %-16s | %-9s | %-12s | %-8s\n",
    "Time", "Position (X,Y,Z)", "Speed", "Gimbal Tilt", "Lens FOV";
print "-" x 75, "\n";

for my $i (0 .. 10) {
    my $t = ($i / 10) * $duration;
    my $x = $spline_x->at($t);
    my $y = $spline_y->at($t);
    my $z = $spline_z->at($t);

    my $vx = $dx->at($t);
    my $vy = $dy->at($t);
    my $vz = $dz->at($t);
    my $speed = sqrt($vx * $vx + $vy * $vy + $vz * $vz);

    my $pitch = $gimbal_pitch->at($t);
    my $fov   = $camera_fov->at($t);

    printf "%4.1fs | (%4.1f, %4.1f, %4.1fm) | %4.1f m/s | %+5.1f° tilt | %4.1f°\n",
        $t, $x, $y, $z, $speed, $pitch, $fov;
}

print "=" x 75, "\n";
printf "Peak Flight Speed: %.2f m/s (%.1f km/h)\n",
    $max_speed, $max_speed * 3.6;
print "=" x 75, "\n";
