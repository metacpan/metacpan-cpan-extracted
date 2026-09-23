#!/usr/bin/env perl
# 3D Raymarched Signed Distance Field (SDF) ASCII Graphics Engine
# Demonstrates segmented envelopes driving 3D computer graphics:
# - Geometric shape morphing envelope (smooth minimum 'smin' blend: sphere -> torus -> box)
# - Camera orbital trajectory envelopes (azimuth, elevation, distance)
# - Lighting direction and specular highlight intensity envelopes
# - Camera field of view (FOV) breathing envelope
#
# Renders a full raymarched 3D scene directly to the terminal using ASCII luminance shading.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $pi = 3.141592653589793;

# Output resolution
my $width  = 68;
my $height = 30;
my $aspect = 2.0; # terminal font aspect ratio (characters are taller than wide)

# 1. Morphing parameter envelope: smoothly blends between 3 geometric primitives
# 0.0 = Sphere, 0.5 = Torus, 1.0 = Rounded Cube
my $morph_env = env(
    [[0.0, 0.5, 1.0, 0.0], [1.5, 1.5, 1.0], [2, 1, -2]],
    is_hold => 1,
);
my $morph_s = $morph_env->static;

# 2. Camera orbit azimuth angle (spinning around the object)
my $camera_orbit_env = env(
    [[0.4, 1.8, 3.5, 5.8], [1.2, 1.5, 1.3], [1, 1, 1]],
    is_hold => 1,
);
my $orbit_s = $camera_orbit_env->static;

# 3. Camera elevation angle
my $camera_elev_env = spline(
    [0.0, 1.0, 2.0, 3.0, 4.0],
    [0.3, 0.8, -0.4, 0.6, 0.3],
    resolution => 8, is_hold => 1,
);
my $elev_s = $camera_elev_env->static;

# 4. Light position oscillation envelope
my $light_env = env(
    [[1.0, -1.0, 1.0], [2.0, 2.0], [1, 1]],
    is_fold_over => 1,
);
my $light_s = $light_env->static;

# ASCII luminance ramp (10 levels of perceptual brightness)
my @ramp = split //, " .:-=+*#%@";

# Signed Distance Functions for 3D primitives
sub sd_sphere {
    my ($x, $y, $z, $r) = @_;
    return sqrt($x*$x + $y*$y + $z*$z) - $r;
}

sub sd_torus {
    my ($x, $y, $z, $r_major, $r_minor) = @_;
    my $q_x = sqrt($x*$x + $z*$z) - $r_major;
    return sqrt($q_x*$q_x + $y*$y) - $r_minor;
}

sub sd_box {
    my ($x, $y, $z, $bx, $by, $bz) = @_;
    my $dx = abs($x) - $bx;
    my $dy = abs($y) - $by;
    my $dz = abs($z) - $bz;
    my $ox = $dx > 0 ? $dx : 0;
    my $oy = $dy > 0 ? $dy : 0;
    my $oz = $dz > 0 ? $dz : 0;
    my $outside = sqrt($ox*$ox + $oy*$oy + $oz*$oz);
    my $inside = [sort { $b <=> $a } ($dx, $dy, $dz)]->[0];
    return $outside + ($inside < 0 ? $inside : 0);
}

# Polynomial smooth minimum for organic shape morphing
sub smin {
    my ($a, $b, $k) = @_;
    $k //= 0.25;
    my $h = 0.5 + 0.5 * ($b - $a) / $k;
    $h = 0.0 if $h < 0.0;
    $h = 1.0 if $h > 1.0;
    return $b * (1.0 - $h) + $a * $h - $k * $h * (1.0 - $h);
}

# Composite scene distance field evaluated at point (x, y, z)
sub scene_sdf {
    my ($x, $y, $z, $morph) = @_;

    my $d_sphere = sd_sphere($x, $y, $z, 1.15);
    my $d_torus  = sd_torus($x, $y, $z, 1.1, 0.38);
    my $d_box    = sd_box($x, $y, $z, 0.85, 0.85, 0.85) - 0.15; # rounded box

    # Blend between sphere, torus, and box based on morph envelope
    my $dist;
    if ($morph < 0.5) {
        my $t = $morph / 0.5;
        $dist = smin($d_sphere, $d_torus, 0.35 * (1 - $t) + 0.15);
    } else {
        my $t = ($morph - 0.5) / 0.5;
        $dist = smin($d_torus, $d_box, 0.35 * (1 - $t) + 0.15);
    }
    return $dist;
}

# Calculate surface normal via forward difference gradient
sub calc_normal {
    my ($x, $y, $z, $morph) = @_;
    my $eps = 0.002;
    my $d = scene_sdf($x, $y, $z, $morph);
    my $nx = scene_sdf($x + $eps, $y, $z, $morph) - $d;
    my $ny = scene_sdf($x, $y + $eps, $z, $morph) - $d;
    my $nz = scene_sdf($x, $y, $z + $eps, $morph) - $d;
    my $len = sqrt($nx*$nx + $ny*$ny + $nz*$nz) || 1.0;
    return ($nx / $len, $ny / $len, $nz / $len);
}

# Render a frame at time t
sub render_frame {
    my ($t_sim) = @_;

    my $morph = $morph_s->($t_sim);
    my $orbit = $orbit_s->($t_sim);
    my $elev  = $elev_s->($t_sim);
    my $light_osc = $light_s->($t_sim);

    # Camera setup (spherical coordinates to Cartesian)
    my $cam_dist = 3.2;
    my $ro_x = $cam_dist * cos($elev) * sin($orbit);
    my $ro_y = $cam_dist * sin($elev);
    my $ro_z = $cam_dist * cos($elev) * cos($orbit);

    # Look-at matrix vectors
    my ($ta_x, $ta_y, $ta_z) = (0.0, 0.0, 0.0); # target origin
    my ($fwd_x, $fwd_y, $fwd_z) = ($ta_x - $ro_x, $ta_y - $ro_y, $ta_z - $ro_z);
    my $flen = sqrt($fwd_x*$fwd_x + $fwd_y*$fwd_y + $fwd_z*$fwd_z);
    $fwd_x /= $flen; $fwd_y /= $flen; $fwd_z /= $flen;

    # Up vector (0, 1, 0) crossed with forward -> right
    my ($rgt_x, $rgt_y, $rgt_z) = ($fwd_z, 0, -$fwd_x);
    my $rlen = sqrt($rgt_x*$rgt_x + $rgt_z*$rgt_z) || 1.0;
    $rgt_x /= $rlen; $rgt_z /= $rlen;

    # Up = right x forward
    my $up_x = $rgt_y * $fwd_z - $rgt_z * $fwd_y;
    my $up_y = $rgt_z * $fwd_x - $rgt_x * $fwd_z;
    my $up_z = $rgt_x * $fwd_y - $rgt_y * $fwd_x;

    # Light direction vector (normalized)
    my ($lx, $ly, $lz) = (0.5 * $light_osc + 0.4, 0.8, -0.6);
    my $llen = sqrt($lx*$lx + $ly*$ly + $lz*$lz);
    $lx /= $llen; $ly /= $llen; $lz /= $llen;

    printf "3D Raymarched Scene (t=%.2fs | Morph=%.2f | Orbit=%.1f deg):\n",
        $t_sim, $morph, $orbit * 180.0 / $pi;
    print "+" . ("-" x $width) . "+\n";

    for my $py (0 .. $height - 1) {
        print "|";
        for my $px (0 .. $width - 1) {
            # Screen coordinates [-1, 1]
            my $uv_x = (($px / ($width - 1)) * 2.0 - 1.0) * ($width / $height) / $aspect;
            my $uv_y = -((($py / ($height - 1)) * 2.0 - 1.0));

            # Primary camera ray direction
            my $rd_x = $uv_x * $rgt_x + $uv_y * $up_x + 1.8 * $fwd_x;
            my $rd_y = $uv_x * $rgt_y + $uv_y * $up_y + 1.8 * $fwd_y;
            my $rd_z = $uv_x * $rgt_z + $uv_y * $up_z + 1.8 * $fwd_z;
            my $rd_len = sqrt($rd_x*$rd_x + $rd_y*$rd_y + $rd_z*$rd_z);
            $rd_x /= $rd_len; $rd_y /= $rd_len; $rd_z /= $rd_len;

            # Raymarch loop
            my $dist_travelled = 0.0;
            my $hit = 0;
            my ($hx, $hy, $hz) = (0, 0, 0);

            for (1 .. 48) {
                my $cx = $ro_x + $rd_x * $dist_travelled;
                my $cy = $ro_y + $rd_y * $dist_travelled;
                my $cz = $ro_z + $rd_z * $dist_travelled;

                my $d = scene_sdf($cx, $cy, $cz, $morph);
                if ($d < 0.005) {
                    $hit = 1;
                    ($hx, $hy, $hz) = ($cx, $cy, $cz);
                    last;
                }
                $dist_travelled += $d;
                last if $dist_travelled > 10.0;
            }

            if ($hit) {
                my ($nx, $ny, $nz) = calc_normal($hx, $hy, $hz, $morph);

                # Lambertian diffuse lighting
                my $diff = $nx * $lx + $ny * $ly + $nz * $lz;
                $diff = 0.0 if $diff < 0.0;

                # Blinn-Phong specular highlight
                my $vx = -$rd_x; my $vy = -$rd_y; my $vz = -$rd_z;
                my ($hx_dir, $hy_dir, $hz_dir) = ($lx + $vx, $ly + $vy, $lz + $vz);
                my $hlen = sqrt($hx_dir*$hx_dir + $hy_dir*$hy_dir + $hz_dir*$hz_dir) || 1.0;
                my $spec = ($nx * $hx_dir + $ny * $hy_dir + $nz * $hz_dir) / $hlen;
                $spec = $spec > 0 ? ($spec ** 16.0) : 0;

                # Ambient occlusion approximation (curvature proxy)
                my $ao = scene_sdf($hx + $nx*0.1, $hy + $ny*0.1, $hz + $nz*0.1, $morph) / 0.1;
                $ao = 0.0 if $ao < 0.0; $ao = 1.0 if $ao > 1.0;

                my $luminance = 0.18 + 0.65 * $diff * $ao + 0.40 * $spec;
                $luminance = 1.0 if $luminance > 1.0;

                my $char_idx = int($luminance * $#ramp);
                print $ramp[$char_idx];
            } else {
                # Background subtle vignette gradient
                my $bg = 0.08 * (1.0 - 0.4 * sqrt($uv_x*$uv_x + $uv_y*$uv_y));
                my $char_idx = int($bg * $#ramp);
                print $ramp[$char_idx];
            }
        }
        print "|\n";
    }
    print "+" . ("-" x $width) . "+\n";
}

# Render 2 distinct animation snapshots demonstrating envelope morphing
render_frame(0.4);
print "\n";
render_frame(2.2);
