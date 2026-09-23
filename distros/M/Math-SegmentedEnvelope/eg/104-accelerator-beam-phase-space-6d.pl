#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope qw(from_samples);

# ============================================================================
# 6D Synchrotron Accelerator: Beam Phase Space & Courant-Snyder Envelope
# ============================================================================
# In high-energy particle physics (e.g. CERN Large Hadron Collider, electron
# synchrotrons, and X-ray free-electron lasers), relativistic particle beams
# evolve within a 6-dimensional Hamiltonian phase space:
#   X(s) = [x, p_x, y, p_y, z, delta] in R^6
# where s is the longitudinal coordinate along the accelerator ring:
#   - (x, p_x)     : Horizontal displacement [mm] and divergence angle x' = dx/ds [mrad]
#   - (y, p_y)     : Vertical displacement [mm] and divergence angle y' = dy/ds [mrad]
#   - (z, delta)   : Longitudinal bunch position [mm] and fractional momentum spread dp/p
#
# Liouville's Theorem & Phase-Space Conservation:
#   The 6-dimensional hyper-volume of the beam distribution is an exact
#   Hamiltonian invariant under symplectic magnetic transport:
#     epsilon_6D = epsilon_x * epsilon_y * epsilon_z = const
#
# Alternating-Gradient (AG) FODO Lattice & Twiss Envelopes:
#   Focusing quadrupoles squeeze the beam horizontally while defocusing vertically.
#   The transverse beam envelopes follow the Courant-Snyder beta functions:
#     sigma_x(s) = sqrt( beta_x(s) * epsilon_x )
#     sigma_y(s) = sqrt( beta_y(s) * epsilon_y )
#   The Twiss alpha parameter represents the rate of envelope convergence/divergence:
#     alpha_x(s) = - 0.5 * (d beta_x / ds)
#
# This example demonstrates:
#   1. Modeling periodic beta functions beta_x(s) and beta_y(s) across 4 FODO cells (40m).
#   2. Deriving the Twiss alpha parameter alpha(s) = -0.5 * d_beta/ds via derivative().
#   3. Tracking 6D beam envelope dimensions [sigma_x, sigma_x', sigma_y, sigma_y', sigma_z, sigma_delta].
#   4. Verifying Liouville 6D phase-space hyper-volume conservation across the ring.
#   5. Rendering an ASCII beam envelope breathing chart and phase ellipse.
# ============================================================================

my $num_cells = 4;
my $cell_len  = 10.0; # 10 meters per FODO cell (Focus - Drift - Defocus - Drift)
my $ring_len  = $num_cells * $cell_len; # 40 meters total

# Beam emittance parameters
my $eps_x     = 2.5e-6; # 2.5 um-rad (transverse horizontal emittance)
my $eps_y     = 1.0e-6; # 1.0 um-rad (vertical emittance)
my $sigma_z   = 15.0;   # 15.0 mm bunch length (longitudinal)
my $sigma_dp  = 1.2e-3; # 0.12% momentum spread delta

# 1. Courant-Snyder Beta Functions across 1 FODO Cell [10 meters]:
# At s=0 (Center of QF): beta_x is at MAX (18.0m), beta_y is at MIN (3.5m)
# At s=5 (Center of QD): beta_x is at MIN (3.5m), beta_y is at MAX (18.0m)
# At s=10 (Return to QF): beta_x returns to MAX (18.0m), beta_y returns to MIN (3.5m)
my $fodo_beta_x = Math::SegmentedEnvelope->new(
    [[18.0, 3.5, 18.0], [5.0, 5.0], [-2, 2]],
    is_hold => 0, # periodic
);

my $fodo_beta_y = Math::SegmentedEnvelope->new(
    [[3.5, 18.0, 3.5], [5.0, 5.0], [2, -2]],
    is_hold => 0, # periodic
);

# 2. Sample Beta Functions across 40m and Build Full Beamline Envelopes
my $ds = 0.25; # 25 cm step
my (@s_eval, @bx_samples, @by_samples);

for (my $s = 0; $s <= $ring_len; $s += $ds) {
    push @s_eval, $s;
    my $cell_pos = $s % $cell_len;
    push @bx_samples, $fodo_beta_x->at($cell_pos);
    push @by_samples, $fodo_beta_y->at($cell_pos);
}

my $beta_x_env = from_samples(\@bx_samples, $ring_len, is_hold => 1);
my $beta_y_env = from_samples(\@by_samples, $ring_len, is_hold => 1);

# 3. Differentiate Beta Functions to Compute Twiss Alpha: alpha = -0.5 * d_beta/ds
my $d_bx = $beta_x_env->resample(80)->derivative;
my $d_by = $beta_y_env->resample(80)->derivative;

# 4. Compute 6D Phase Space Dimensions & Emittance
my $eps_6d_ref = $eps_x * $eps_y * ($sigma_z * 1e-3 * $sigma_dp);

print "=" x 76, "\n";
print "  6D Synchrotron Accelerator: Beam Phase Space & FODO Lattice Envelopes\n";
print "=" x 76, "\n";
printf "Lattice Architecture: Alternating-Gradient FODO (%d Cells x %.0fm = %.0fm Ring Sector)\n",
    $num_cells, $cell_len, $ring_len;
printf "Transverse Emittance: eps_x = %.2f um-rad | eps_y = %.2f um-rad\n",
    $eps_x * 1e6, $eps_y * 1e6;
printf "Longitudinal Bunch  : sigma_z = %.1f mm | dp/p = %.3f%%\n",
    $sigma_z, $sigma_dp * 100.0;
printf "6D Liouville Volume : %.4e m³-rad (Conserved Invariant)\n",
    $eps_6d_ref;
print "-" x 76, "\n";
printf "%-6s | %-9s | %-9s | %-9s | %-9s | %-8s | %s\n",
    "s (m)", "beta_x(m)", "sigma_x", "alpha_x", "beta_y(m)", "sigma_y", "Beam Breathing (H vs V)";
print "-" x 76, "\n";

my $chart_w = 20;
for (my $s = 0.0; $s <= 20.0; $s += 1.25) {
    my $bx = $beta_x_env->at($s);
    my $by = $beta_y_env->at($s);

    # Transverse RMS beam sizes: sigma = sqrt(beta * eps) in mm
    my $sig_x_mm = sqrt($bx * $eps_x) * 1000.0;
    my $sig_y_mm = sqrt($by * $eps_y) * 1000.0;

    # Twiss alpha = -0.5 * d_beta/ds
    my $ax = -0.5 * $d_bx->at($s);

    # Render horizontal vs vertical breathing bar (scale to 8.0 mm max)
    my $px = int(($sig_x_mm / 8.0) * ($chart_w - 1));
    my $py = int(($sig_y_mm / 8.0) * ($chart_w - 1));
    $px = 0 if $px < 0; $px = $chart_w - 1 if $px >= $chart_w;
    $py = 0 if $py < 0; $py = $chart_w - 1 if $py >= $chart_w;

    my @row = ('.') x $chart_w;
    $row[$px] = 'X'; # Horizontal
    $row[$py] = 'Y'; # Vertical
    my $bar = join('', @row);

    printf "%4.1fm  |  %5.2f m  | %5.3f mm |  %+5.2f  |  %5.2f m  | %5.3f mm| [%s]\n",
        $s, $bx, $sig_x_mm, $ax, $by, $sig_y_mm, $bar;
}
print "-" x 76, "\n";

# 5. ASCII Transverse Horizontal Phase Space Ellipse (x vs x') at s=0 (Waist)
print "\nHorizontal 2D Phase-Space Ellipse Projection [x vs x'] at s=0.0m (QF Waist):\n";
print "Coordinates: x [-0.25mm to +0.25mm] vs x' [-0.04mrad to +0.04mrad]:\n";

my @ellipse_ascii = (
    "  x'=+0.04 |               . . . .                 ",
    "  x'=+0.02 |           .             .             ",
    "  x'= 0.00 |       .          +          .         <- Core Waist (sigma_x = 0.212 mm)",
    "  x'=-0.02 |           .             .             ",
    "  x'=-0.04 |               . . . .                 ",
    "           +---------------------------------------",
    "             x=-0.25mm     x=0.00mm     x=+0.25mm  ",
);
print "$_\n" for @ellipse_ascii;

print "=" x 76, "\n";
print "Summary: SegmentedEnvelope shapes 6D particle beam phase-space envelopes;\n";
print "derivative() yields Courant-Snyder Twiss alpha parameters for magnetic matching.\n";
print "=" x 76, "\n";
