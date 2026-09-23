#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope;

# ============================================================================
# 4D Differential Geometry: Tesseract (Hypercube) Dual-Plane Rotation & Projection
# ============================================================================
# In 4-dimensional Euclidean space R^4, a regular tesseract (4-cube) consists of:
#   - 16 vertices: V = (+/- 1, +/- 1, +/- 1, +/- 1)
#   - 32 edges connecting vertices that differ by a Hamming distance of 1
#   - 24 square 2D faces
#   - 8 cubic 3D cells (bounding hyper-facets)
#
# Unlike 3D rotation which occurs around an axis vector, 4D rotation occurs
# in 2D planes, leaving the completely orthogonal 2D plane invariant.
# In general, 4D rotations can be double rotations: rotating in the XW plane
# and YZ plane simultaneously!
#
# Perspective Projection from 4D to 2D:
#   1. 4D -> 3D Perspective Projection (4D camera distance D4 = 2.8):
#        X3 = x / (D4 - w),  Y3 = y / (D4 - w),  Z3 = z / (D4 - w)
#      Notice: When w > 0, the cubic cell appears enlarged (outer bounding cube).
#              When w < 0, the cubic cell appears shrunk (inner centered cube).
#              As w rotates through 4-space, the inner and outer cubes invert!
#   2. 3D -> 2D Screen Projection (3D camera distance D3 = 3.5):
#        u = X3 / (D3 - Z3),  v = Y3 / (D3 - Z3)
#
# This example demonstrates:
#   1. Driving 4D rotational angles theta_xw(t) and theta_yz(t) using
#      SegmentedEnvelope with smoothstep easing.
#   2. Differentiating 4D angular trajectories via derivative() to compute
#      hyper-rotational velocity (rad/s) and Coriolis acceleration.
#   3. Tracking 3D projected edge distortion and hyper-cell inversion across time.
#   4. Rendering an ASCII wireframe projection of the 4D tesseract.
# ============================================================================

my $two_pi = 8.0 * atan2(1, 1);
my $duration = 4.0; # seconds for one full 4D rotation cycle

# 1. 4D Rotational Angle Envelopes
# theta_xw rotates full 360° (2*pi) in XW plane
my $env_theta_xw = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi], [$duration], [1]],
    is_morph        => 1,
    morpher_formula => 'smoothstep',
    is_hold         => 1,
);

# theta_yz rotates 180° (pi) in YZ plane
my $env_theta_yz = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi * 0.5], [$duration], [1]],
    is_morph        => 1,
    morpher_formula => 'smoothstep',
    is_hold         => 1,
);

# Resample before derivative for accurate angular velocity omega(t)
my $omega_xw_env = $env_theta_xw->resample(40)->derivative;
my $omega_yz_env = $env_theta_yz->resample(40)->derivative;

# 2. Build Tesseract Geometry in R^4
# 16 vertices: V_i = (+/- 1, +/- 1, +/- 1, +/- 1)
my @vertices_4d;
for my $i (0 .. 15) {
    my $x = ($i & 1) ? 1.0 : -1.0;
    my $y = ($i & 2) ? 1.0 : -1.0;
    my $z = ($i & 4) ? 1.0 : -1.0;
    my $w = ($i & 8) ? 1.0 : -1.0;
    push @vertices_4d, [$x, $y, $z, $w];
}

# 32 edges: connect vertices differing in exactly one bit
my @edges;
for my $i (0 .. 15) {
    for my $b (0 .. 3) {
        my $j = $i ^ (1 << $b);
        if ($i < $j) {
            push @edges, [$i, $j];
        }
    }
}

# 3. 4D Rotation and Double Projection Function
sub project_tesseract {
    my ($theta_xw, $theta_yz) = @_;

    my $cos_xw = cos($theta_xw); my $sin_xw = sin($theta_xw);
    my $cos_yz = cos($theta_yz); my $sin_yz = sin($theta_yz);

    my $d4 = 2.6; # 4D perspective distance
    my $d3 = 3.2; # 3D perspective distance

    my @pts_3d;
    my @pts_2d;

    for my $v (@vertices_4d) {
        my ($x, $y, $z, $w) = @$v;

        # Rotate in XW plane
        my $rx = $x * $cos_xw - $w * $sin_xw;
        my $rw = $x * $sin_xw + $w * $cos_xw;

        # Rotate in YZ plane
        my $ry = $y * $cos_yz - $z * $sin_yz;
        my $rz = $y * $sin_yz + $z * $cos_yz;

        # 4D -> 3D Perspective Projection
        my $scale4 = 1.0 / ($d4 - $rw);
        my $x3 = $rx * $scale4;
        my $y3 = $ry * $scale4;
        my $z3 = $rz * $scale4;

        push @pts_3d, [$x3, $y3, $z3, $rw];

        # 3D -> 2D Perspective Projection
        my $scale3 = 1.0 / ($d3 - $z3);
        my $x2 = $x3 * $scale3;
        my $y2 = $y3 * $scale3;

        push @pts_2d, [$x2, $y2, $rw];
    }

    return (\@pts_3d, \@pts_2d);
}

# 4. Analyze Projected Edge Distortion & Hyper-Cell Scale
print "=" x 76, "\n";
print "  4D Differential Geometry: Tesseract Dual-Plane Rotation & Projection\n";
print "=" x 76, "\n";
printf "Tesseract Topology: 16 Vertices, 32 Edges, 8 Cubic Hyper-Cells in R⁴\n";
printf "Rotation Planes   : XW Plane (Primary Inversion) + YZ Plane (Spatial Tilt)\n";
printf "Cycle Duration    : %.1fs (Smoothstep Eased Angular Velocity)\n", $duration;
print "-" x 76, "\n";
printf "%-6s | %-10s | %-10s | %-10s | %-12s | %s\n",
    "Time", "Theta XW", "Omega XW", "Theta YZ", "Min/Max Edge", "4D Hyper-Inversion State";
print "-" x 76, "\n";

for (my $t = 0.0; $t <= $duration; $t += 0.5) {
    my $th_xw = $env_theta_xw->at($t);
    my $th_yz = $env_theta_yz->at($t);
    my $om_xw = $omega_xw_env->at($t);

    my ($pts_3d, $pts_2d) = project_tesseract($th_xw, $th_yz);

    # Calculate min and max 3D edge lengths to measure perspective distortion
    my $min_len = 999;
    my $max_len = 0;
    for my $e (@edges) {
        my $p1 = $pts_3d->[$e->[0]];
        my $p2 = $pts_3d->[$e->[1]];
        my $dx = $p1->[0] - $p2->[0];
        my $dy = $p1->[1] - $p2->[1];
        my $dz = $p1->[2] - $p2->[2];
        my $len = sqrt($dx*$dx + $dy*$dy + $dz*$dz);
        $min_len = $len if $len < $min_len;
        $max_len = $len if $len > $max_len;
    }

    my $state = ($t == 0.0)      ? "Initial Bounding Alignment" :
                ($t == 1.0)      ? "XW Inversion in Progress"   :
                ($t == 2.0)      ? "Full 4D Hyper-Inversion (Inside-Out!)" :
                ($t == 3.0)      ? "Returning to Outer Sphere"  :
                                   "Harmonic Dual Rotation";

    printf "%4.2fs  | %5.1f deg  | %5.2f rad/s| %5.1f deg  |  %4.2f / %4.2f  | %s\n",
        $t,
        $th_xw * 180.0 / 3.14159,
        $om_xw,
        $th_yz * 180.0 / 3.14159,
        $min_len, $max_len,
        $state;
}
print "-" x 76, "\n";

# 5. Render 2D ASCII Wireframe Projection at Peak Inversion (t = 2.0s)
print "\n2D ASCII Wireframe Projection of 4D Tesseract at t = 2.0s (Dual Rotation):\n";
print "Symbols: [#] Foreground Vertices (w > 0)  [o] Background Vertices (w <= 0)\n";
print "Edges  : Projected lines connecting 4D neighboring vertices\n";
print "-" x 76, "\n";

my ($mid_3d, $mid_2d) = project_tesseract($env_theta_xw->at(2.0), $env_theta_yz->at(2.0));

my $canvas_w = 64;
my $canvas_h = 21;
my @canvas;
for my $y (0 .. $canvas_h - 1) {
    $canvas[$y] = [(' ') x $canvas_w];
}

# Helper to plot line via Bresenham algorithm
sub draw_line {
    my ($x0, $y0, $x1, $y1, $ch) = @_;
    my $dx = abs($x1 - $x0);
    my $dy = abs($y1 - $y0);
    my $sx = ($x0 < $x1) ? 1 : -1;
    my $sy = ($y0 < $y1) ? 1 : -1;
    my $err = $dx - $dy;

    while (1) {
        if ($x0 >= 0 && $x0 < $canvas_w && $y0 >= 0 && $y0 < $canvas_h) {
            $canvas[$y0][$x0] = $ch if $canvas[$y0][$x0] eq ' ';
        }
        last if $x0 == $x1 && $y0 == $y1;
        my $e2 = 2 * $err;
        if ($e2 > -$dy) { $err -= $dy; $x0 += $sx; }
        if ($e2 <  $dx) { $err += $dx; $y0 += $sy; }
    }
}

# Map 2D coordinates [-0.35, 0.35] to canvas [0..canvas_w-1, 0..canvas_h-1]
my @screen_pts;
for my $p (@$mid_2d) {
    my ($x2, $y2, $w) = @$p;
    my $cx = int(($x2 + 0.38) / 0.76 * ($canvas_w - 1));
    my $cy = int((0.38 - $y2) / 0.76 * ($canvas_h - 1));
    $cx = 0 if $cx < 0; $cx = $canvas_w - 1 if $cx >= $canvas_w;
    $cy = 0 if $cy < 0; $cy = $canvas_h - 1 if $cy >= $canvas_h;
    push @screen_pts, [$cx, $cy, $w];
}

# Draw 32 edges
for my $e (@edges) {
    my $p1 = $screen_pts[$e->[0]];
    my $p2 = $screen_pts[$e->[1]];
    # Connect with '-' or '.'
    my $edge_ch = ($p1->[2] > 0 || $p2->[2] > 0) ? '.' : ':';
    draw_line($p1->[0], $p1->[1], $p2->[0], $p2->[1], $edge_ch);
}

# Draw vertices
for my $sp (@screen_pts) {
    my ($x, $y, $w) = @$sp;
    $canvas[$y][$x] = ($w > 0) ? '#' : 'o';
}

# Print canvas with border
print "+", "-" x $canvas_w, "+\n";
for my $row (@canvas) {
    print "|", join('', @$row), "|\n";
}
print "+", "-" x $canvas_w, "+\n";

print "=" x 76, "\n";
print "Summary: SegmentedEnvelope coordinates smooth 4D dual-plane rotations;\n";
print "derivative() yields hyper-angular velocity while projection maps R⁴ to R².\n";
print "=" x 76, "\n";
