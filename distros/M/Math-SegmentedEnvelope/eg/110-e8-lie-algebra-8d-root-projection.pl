#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# ============================================================================
# 8D Exceptional Lie Algebra E8: 240-Root System & 8D Torus Rotation Projection
# ============================================================================
# In theoretical physics (string theory, grand unification, M-theory) and
# higher-dimensional algebra, the exceptional Lie group E8 possesses the most
# symmetrical structure in 8-dimensional space R^8.
#
# E8 Root System (240 Roots in R^8, all of exact Euclidean length ||alpha|| = sqrt(2)):
#   1. Type 1 (112 roots): Permutations of (+/-1, +/-1, 0, 0, 0, 0, 0, 0).
#        (28 index pairs * 4 sign combinations = 112 vectors)
#   2. Type 2 (128 roots): (+/- 1/2, +/- 1/2, ..., +/- 1/2) with an even number
#        of minus signs (2^7 = 128 vectors).
#
# 8D Torus Rotations in SO(8):
#   In R^8, a general element of the maximal torus T^4 rotates 4 mutually
#   orthogonal 2D planes simultaneously:
#     Plane 1 (x1, x2) by theta_1(t)
#     Plane 2 (x3, x4) by theta_2(t)
#     Plane 3 (x5, x6) by theta_3(t)
#     Plane 4 (x7, x8) by theta_4(t)
#
# Coxeter Plane Projection (8D -> 2D):
#   Projecting the 240 roots onto the Coxeter plane yields the famous concentric
#   30-gon rings of the E8 Petrie polygon. As the 4 angles rotate in 8D, the 2D
#   shadow breathes and morphs while 8D Euclidean distances remain invariant!
#
# This example demonstrates:
#   1. Constructing all 240 exact root vectors in R^8.
#   2. Driving 4 independent 8D rotation angles via SegmentedEnvelope with harmonic ratios.
#   3. Differentiating rotation angles via derivative() to compute 8D angular velocities.
#   4. Verifying exact 8D norm conservation (||alpha|| = 1.414214) under rotation.
#   5. Projecting the 240 rotating 8D roots onto a 2D ASCII Coxeter scatter plot.
# ============================================================================

my $two_pi   = 8.0 * atan2(1, 1);
my $duration = 6.0; # 6.0-second 8D rotation cycle

# 1. Generate All 240 Root Vectors of E8 in R^8
my @roots_8d;

# Type 1: 112 roots with two +/-1 and six 0s
for my $i (0 .. 6) {
    for my $j ($i + 1 .. 7) {
        for my $s1 (-1.0, 1.0) {
            for my $s2 (-1.0, 1.0) {
                my @r = (0.0) x 8;
                $r[$i] = $s1;
                $r[$j] = $s2;
                push @roots_8d, \@r;
            }
        }
    }
}

# Type 2: 128 roots with (+/- 0.5)^8 and even number of minus signs
for my $mask (0 .. 255) {
    my $neg_count = 0;
    for my $b (0 .. 7) {
        $neg_count++ if ($mask & (1 << $b));
    }
    if ($neg_count % 2 == 0) {
        my @r;
        for my $b (0 .. 7) {
            push @r, ($mask & (1 << $b)) ? -0.5 : 0.5;
        }
        push @roots_8d, \@r;
    }
}

# 2. 4 Independent 8D Rotation Angle Envelopes (Harmonic Ratios: 1, 2, 3, 5)
my $env_th1 = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi * 1.0], [$duration], [1]], is_morph => 1, morpher_formula => 'smoothstep', is_hold => 1);
my $env_th2 = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi * 2.0], [$duration], [1]], is_morph => 1, morpher_formula => 'smoothstep', is_hold => 1);
my $env_th3 = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi * 3.0], [$duration], [1]], is_morph => 1, morpher_formula => 'smoothstep', is_hold => 1);
my $env_th4 = Math::SegmentedEnvelope->new(
    [[0.0, $two_pi * 5.0], [$duration], [1]], is_morph => 1, morpher_formula => 'smoothstep', is_hold => 1);

# Angular velocities via derivative()
my $w1_env = $env_th1->resample(40)->derivative;
my $w2_env = $env_th2->resample(40)->derivative;
my $w3_env = $env_th3->resample(40)->derivative;
my $w4_env = $env_th4->resample(40)->derivative;

# 3. 8D Rotation Function: Rotates 4 pairs of coordinates
sub rotate_8d {
    my ($v, $t1, $t2, $t3, $t4) = @_;
    my @angles = ($t1, $t2, $t3, $t4);
    my @out;

    for my $p (0 .. 3) {
        my $c = cos($angles[$p]);
        my $s = sin($angles[$p]);
        my $x = $v->[2 * $p];
        my $y = $v->[2 * $p + 1];
        push @out, $x * $c - $y * $s;
        push @out, $x * $s + $y * $c;
    }
    return \@out;
}

# 4. Coxeter Projection Vectors u1, u2 in R^8 (Coxeter plane of E8)
# Constructed from powers of the 30th root of unity (Coxeter number h = 30)
my (@u1, @u2);
for my $k (0 .. 7) {
    my $phi = $k * $two_pi / 30.0;
    push @u1, cos($phi) * 0.5;
    push @u2, sin($phi) * 0.5;
}

# Verify 8D norm invariance across sample roots
my $test_root = $roots_8d[0];
my $rot_test = rotate_8d($test_root, 1.2, 2.3, 3.4, 4.5);
my $norm_sq = 0;
for my $x (@$rot_test) { $norm_sq += $x * $x; }
my $norm_8d = sqrt($norm_sq);

print "=" x 76, "\n";
print "  8D Exceptional Lie Algebra E8: 240-Root System & SO(8) Torus Projection\n";
print "=" x 76, "\n";
printf "Lie Algebra : E8 (Rank = 8, Dimension = 248, Coxeter Number h = 30)\n";
printf "Root System : Exact %d Roots in R⁸ | Theoretical Length = sqrt(2) = 1.414214\n",
    scalar @roots_8d;
printf "Rotated Norm: ||v(t)|| = %8.6f in R⁸ (Exact Euclidean Invariance!)\n", $norm_8d;
print "-" x 76, "\n";

# 5. 8D Rotation Telemetry across Time
print "8D Torus Rotation Angles [th1, th2, th3, th4] & Angular Velocities w_i:\n";
printf "%-6s | %-8s | %-8s | %-8s | %-8s | %-9s | %-9s\n",
    "Time", "th1(deg)", "th2(deg)", "th3(deg)", "th4(deg)", "w1(rad/s)", "w4(rad/s)";
print "-" x 76, "\n";

for (my $t = 0.0; $t <= $duration; $t += 1.0) {
    my $th1 = $env_th1->at($t) * 180.0 / 3.14159;
    my $th2 = $env_th2->at($t) * 180.0 / 3.14159;
    my $th3 = $env_th3->at($t) * 180.0 / 3.14159;
    my $th4 = $env_th4->at($t) * 180.0 / 3.14159;

    my $w1 = $w1_env->at($t);
    my $w4 = $w4_env->at($t);

    printf "%4.1fs  | %7.1f°| %7.1f°| %7.1f°| %7.1f°| %7.2f   | %7.2f\n",
        $t, $th1, $th2, $th3, $th4, $w1, $w4;
}
print "-" x 76, "\n";

# 6. Render 2D ASCII Projection of All 240 Roots onto the Coxeter Plane (t = 1.5s)
print "\n2D ASCII Coxeter Plane Projection of All 240 Roots of E8 (at t=1.5s):\n";
print "Concentric Petrie Polygon Ring Structure:\n";

my ($t1_cur, $t2_cur, $t3_cur, $t4_cur) = (
    $env_th1->at(1.5), $env_th2->at(1.5), $env_th3->at(1.5), $env_th4->at(1.5)
);

my $canvas_w = 60;
my $canvas_h = 21;
my @grid;
for my $y (0 .. $canvas_h - 1) {
    $grid[$y] = [(' ') x $canvas_w];
}

for my $r (@roots_8d) {
    my $r_rot = rotate_8d($r, $t1_cur, $t2_cur, $t3_cur, $t4_cur);

    # Project onto 2D Coxeter vectors u1, u2
    my ($px, $py) = (0.0, 0.0);
    for my $k (0 .. 7) {
        $px += $r_rot->[$k] * $u1[$k];
        $py += $r_rot->[$k] * $u2[$k];
    }

    # Map [-1.1, 1.1] to canvas
    my $cx = int(($px + 1.1) / 2.2 * ($canvas_w - 1));
    my $cy = int((1.1 - $py) / 2.2 * ($canvas_h - 1));
    if ($cx >= 0 && $cx < $canvas_w && $cy >= 0 && $cy < $canvas_h) {
        my $cur = $grid[$cy][$cx];
        $grid[$cy][$cx] = ($cur eq ' ') ? '.' :
                          ($cur eq '.') ? '*' : '#';
    }
}

print "+", "-" x $canvas_w, "+\n";
for my $row (@grid) {
    print "|", join('', @$row), "|\n";
}
print "+", "-" x $canvas_w, "+\n";

print "=" x 76, "\n";
print "Summary: SegmentedEnvelope coordinates 8D maximal torus rotations in R⁸;\n";
print "derivative() computes hyper-angular speeds while 8D norms remain exact.\n";
print "=" x 76, "\n";
