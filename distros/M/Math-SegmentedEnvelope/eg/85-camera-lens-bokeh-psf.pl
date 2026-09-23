#!/usr/bin/env perl
# Camera Lens Aperture Apodization, Bokeh Rendering & Radial Transmission PSF
# Demonstrates:
#   1. Optical Point Spread Function (PSF) & aperture transmittance modeling
#   2. Radial light flux integration (T-Stop calculation via ∫ 2π·r·T(r) dr)
#   3. Comparing Standard (harsh ring), Apodized (Smooth Trans Focus), and Catadioptric (Donut) Bokeh
#   4. 2D ASCII out-of-focus blur disc cross-section rendering
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Radial distance r from optical center (r = 0.0) to aperture edge (r = 1.0)
# 1. Standard Lens (clear pupil with spherical aberration edge bright ring):
#    Center T=0.9, gentle drop, sharp rim brightening (soap-bubble ring) to 1.0, abrupt cutoff
my $std_lens = env([
    [0.90, 0.85, 1.00, 0.00],
    [0.70, 0.28, 0.02],
    [1.0,  2.5,  1.0]
], is_hold => 1);

# 2. Apodized Lens (Sony STF / Smooth Trans Focus with radial gradient filter):
#    Center T=1.0, smoothly falls to 0.0 at edge with no hard ring (creamy cinematic blur)
my $stf_lens = env([
    [1.00, 0.85, 0.20, 0.00],
    [0.30, 0.40, 0.30],
    [-2.0, -1.5, -2.0]
], is_hold => 1, is_morph => 1, morpher_formula => 'smootherstep');

# 3. Catadioptric Mirror Telephoto Lens (central obstruction from secondary mirror):
#    Center r < 0.35 blocked (T=0), clear ring 0.35 to 1.0 (T=1.0) -> donut bokeh
my $mirror_lens = env([
    [0.00, 0.00, 1.00, 1.00, 0.00],
    [0.32, 0.03, 0.63, 0.02],
    [1.0,  1.0,  1.0,  1.0]
], is_hold => 1);

# Compute total light transmission (photometric T-stop efficiency)
# Flux = ∫_0^1 2π·r·T(r) dr
sub compute_light_flux {
    my ($lens_env) = @_;
    my $steps = 100;
    my $dr = 1.0 / $steps;
    my $flux = 0.0;
    for my $i (0 .. $steps - 1) {
        my $r = ($i + 0.5) * $dr;
        my $t = $lens_env->at($r);
        $flux += 2.0 * 3.14159265 * $r * $t * $dr;
    }
    # Normalize against ideal clear aperture (Flux_ideal = π * 1^2 = π)
    return $flux / 3.14159265;
}

print "=" x 74, "\n";
print "  Camera Lens Bokeh Point Spread Function & Radial Apodization\n";
print "=" x 74, "\n";
printf "Standard Lens T-Efficiency : %5.1f %% (Sharp aperture with rim aberration)\n",
    compute_light_flux($std_lens) * 100;
printf "Apodized STF T-Efficiency  : %5.1f %% (Smooth Trans Focus apodization)\n",
    compute_light_flux($stf_lens) * 100;
printf "Mirror Telephoto Efficiency: %5.1f %% (Donut central obstruction)\n",
    compute_light_flux($mirror_lens) * 100;
print "-" x 74, "\n";

# Subroutine to render 2D circular Bokeh Blur Disc in ASCII
sub render_bokeh_disc {
    my ($title, $lens_env) = @_;
    print "Bokeh Disc (Point Spread Function): $title\n";

    my $grid_r = 10; # radius in characters
    my $aspect = 2.0; # terminal character aspect ratio compensation

    # Shading ramp for light intensity:
    my @shades = (' ', '.', ':', '-', '=', '+', '*', '#', '@');

    for my $y (-$grid_r .. $grid_r) {
        my $line = "  ";
        for my $x (-int($grid_r * $aspect) .. int($grid_r * $aspect)) {
            my $norm_x = $x / ($grid_r * $aspect);
            my $norm_y = $y / $grid_r;
            my $r = sqrt($norm_x * $norm_x + $norm_y * $norm_y);

            if ($r > 1.05) {
                $line .= " ";
            } else {
                my $trans = $lens_env->at($r);
                $trans = 0.0 if $trans < 0; $trans = 1.0 if $trans > 1.0;
                my $shade_idx = int($trans * $#shades);
                $line .= $shades[$shade_idx];
            }
        }
        print "$line\n";
    }
    print "\n";
}

# 1. Render Standard Lens Bokeh
render_bokeh_disc("Standard Fast Prime (Harsh Outer Bright Ring)", $std_lens);

# 2. Render Apodized STF Bokeh
render_bokeh_disc("Apodized Smooth Trans Focus (Gaussian Creamy Edge)", $stf_lens);

# 3. Render Catadioptric Mirror Bokeh
render_bokeh_disc("Catadioptric Reflex Lens (Classic Donut Highlight)", $mirror_lens);

print "=" x 74, "\n";
print "Summary: Radial transmittance profiling using SegmentedEnvelope enables\n";
print "computational photography engines to simulate realistic lens bokeh in 2D.\n";
print "=" x 74, "\n";
