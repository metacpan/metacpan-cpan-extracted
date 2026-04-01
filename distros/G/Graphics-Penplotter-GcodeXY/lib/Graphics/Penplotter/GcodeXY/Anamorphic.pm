package Graphics::Penplotter::GcodeXY::Anamorphic v0.9.4;

# Role::Tiny role adding anamorphic cylindrical mirror projection to GcodeXY.
#
# An anamorphic image is a distorted drawing that appears correct only when
# viewed in a curved mirror.  The caller first populates the GcodeXY segment
# path using any available drawing primitives, then calls anamorphic() to
# replace that path in-place with a distorted version such that a reflective
# cylindrical mirror placed at the given position will show the observer the
# original image.
#
# Physical model
# --------------
# The cylinder stands upright (axis parallel to z) with its base on the paper
# (z = 0).  The observer is at world position
#
#     E = ( cx + D*cos(alpha), cy + D*sin(alpha), H )
#
# where D = obs_dist, H = obs_height, and alpha = obs_angle (in radians).
#
# For every pixel of the source image at normalised coordinates (s, t):
#   1. Compute the 3-D viewing direction from E corresponding to (s, t).
#   2. Find where that ray first hits the cylinder surface (mirror point M).
#   3. Reflect the incident direction off the cylinder's outward normal at M.
#   4. Follow the reflected ray until it hits z = 0 (the paper).
#   5. The paper hit point is where the distorted drawing must be made.
#
# Coordinate conventions
# ----------------------
# SVG coordinates: u increases to the right, v increases downward (standard
# SVG).  The image is laid out such that:
#   * Horizontal centre of image (s = 0) aligns with the observer looking
#     directly at the cylinder.
#   * Image left  (s < 0) is the observer's right  side of the mirror.
#   * Image right (s > 0) is the observer's left   side of the mirror.
#   * Image top   (t < 0) is the upper part of the mirror.
#   * Image bottom(t > 0) is the lower part (closer to the paper).

use v5.38.2;
use strict;
use warnings;
use Role::Tiny;
use Carp       qw( croak );
use List::Util qw( min max );
use POSIX      qw( ceil );

# ---------------------------------------------------------------------------
# The consuming class must provide these primitive hooks
# ---------------------------------------------------------------------------
requires qw(
    _croak
    stroke
);

# ---------------------------------------------------------------------------
# Module-private constants
# ---------------------------------------------------------------------------

my $PI  = 3.14159265358979323846;
my $D2R = $PI / 180.0;

# ===========================================================================
# PURE MATH HELPERS
# All functions below are plain subs (not methods) so that test code can call
# them without a host object.  They are all prefixed _ana_ for namespacing.
# ===========================================================================

# ---------------------------------------------------------------------------
# _ana_ray_cylinder
#
# Find the smallest positive parameter t at which the ray
#
#     P(t) = ( ex + t*dx, ey + t*dy, ez + t*dz )
#
# intersects the infinite vertical cylinder of radius R whose axis passes
# through ( cx, cy ).  Only the horizontal components (dx, dy) are used for
# the cylinder test; the ray also advances along z but the cylinder is
# infinite in that direction.
#
# Returns t on success, undef if the ray is parallel to the axis or misses
# the cylinder, or if both intersections are behind the ray origin.
# ---------------------------------------------------------------------------
sub _ana_ray_cylinder {
    my ($ex, $ey, $ez, $dx, $dy, $dz, $cx, $cy, $R) = @_;

    my $qx = $ex - $cx;
    my $qy = $ey - $cy;
    my $A  = $dx*$dx + $dy*$dy;
    return undef if $A < 1e-14;       # ray runs parallel to cylinder axis

    my $B    = 2.0 * ($qx*$dx + $qy*$dy);
    my $C    = $qx*$qx + $qy*$qy - $R*$R;
    my $disc = $B*$B - 4.0*$A*$C;
    return undef if $disc < 0;        # ray misses cylinder entirely

    my $sq = sqrt($disc);
    my $t1 = (-$B - $sq) / (2.0 * $A);
    my $t2 = (-$B + $sq) / (2.0 * $A);

    return $t1 if $t1 > 1e-9;        # prefer the nearer (entry) intersection
    return $t2 if $t2 > 1e-9;
    return undef;                     # both intersections are behind the origin
}

# ---------------------------------------------------------------------------
# _ana_reflect
#
# Reflect the (already unit-length) incident direction vector D = (dx,dy,dz)
# off the surface whose outward unit normal is N = (nx,ny,nz).
#
# Formula: D_ref = D - 2 * (D.N) * N
#
# Returns (rx, ry, rz).  The reflected vector has the same magnitude as D.
# ---------------------------------------------------------------------------
sub _ana_reflect {
    my ($dx, $dy, $dz, $nx, $ny, $nz) = @_;
    my $dot2 = 2.0 * ($dx*$nx + $dy*$ny + $dz*$nz);
    return ($dx - $dot2*$nx,
            $dy - $dot2*$ny,
            $dz - $dot2*$nz);
}

# ---------------------------------------------------------------------------
# _ana_build_config
#
# Compute the observer and image-mapping configuration hash from the cylinder
# parameters ($cx, $cy, $R) and optional user overrides (%opts).
#
# Returned hash keys:
#   ex, ey, ez   - observer world position
#   phi_fwd      - azimuth of the direction FROM observer TOWARD cylinder
#   ang_rad      - total horizontal angular range of the image (radians)
#   beta0        - centre elevation (radians below horizontal)
#   elev_rad     - total vertical angular range (radians)
#   cx, cy, R    - cylinder parameters (passed through)
# ---------------------------------------------------------------------------
sub _ana_build_config {
    my ($cx, $cy, $R, %opts) = @_;
    croak 'cylinder radius R must be > 0' if $R <= 0;

    my $obs_dist   = $opts{obs_dist}   // (5.0 * $R);
    my $obs_height = $opts{obs_height} // (5.0 * $R);
    my $obs_angle  = ($opts{obs_angle} // 0.0) * $D2R;

    croak 'obs_dist must be > R (observer must be outside the cylinder)'
        if $obs_dist <= $R;

    # Observer world position
    my $ex = $cx + $obs_dist * cos($obs_angle);
    my $ey = $cy + $obs_dist * sin($obs_angle);
    my $ez = $obs_height;

    # Forward azimuth: direction from observer E toward cylinder centre
    my $phi_fwd = atan2($cy - $ey, $cx - $ex);

    # Maximum azimuthal half-angle that can hit the cylinder.
    # sin(half_max) = R / obs_dist  =>  half_max = asin(R / obs_dist).
    # Implemented via atan2 to avoid a POSIX::asin dependency.
    my $ratio    = min($R / $obs_dist, 1.0);
    my $half_max = atan2($ratio, sqrt(1.0 - $ratio*$ratio));

    my $ang_rad;
    if (defined $opts{angle_range}) {
        $ang_rad = $opts{angle_range} * $D2R;
    }
    else {
        $ang_rad = 2.0 * $half_max * 0.90;  # 90 % of the full visible cone
    }

    # Centre elevation: the angle below horizontal that looks at the base of
    # the cylinder (z = 0) from the observer's position.
    my $beta0 = atan2($obs_height, $obs_dist);

    my $elev_rad;
    if (defined $opts{elev_range}) {
        $elev_rad = $opts{elev_range} * $D2R;
    }
    else {
        $elev_rad = $beta0 * 0.80;           # 80 % of the base elevation
    }

    return (
        ex       => $ex,
        ey       => $ey,
        ez       => $ez,
        phi_fwd  => $phi_fwd,
        ang_rad  => $ang_rad,
        beta0    => $beta0,
        elev_rad => $elev_rad,
        cx       => $cx,
        cy       => $cy,
        R        => $R,
    );
}

# ---------------------------------------------------------------------------
# _ana_transform_point
#
# Map one image point (u, v) within the image bounding box
# ($u0, $v0) -- ($u1, $v1) to paper coordinates (px, py), using the
# prebuilt configuration hash %cfg (from _ana_build_config).
#
# SVG coordinate convention: u increases right, v increases downward.
#
# Returns (px, py) on success, or an empty list () if the viewing ray misses
# the cylinder, or if the reflected ray travels upward (away from the paper).
# ---------------------------------------------------------------------------
sub _ana_transform_point {
    my ($u, $v, $u0, $v0, $u1, $v1, %cfg) = @_;

    my $iw = $u1 - $u0;
    my $ih = $v1 - $v0;
    return () if $iw < 1e-12 || $ih < 1e-12;

    # Normalise to [-0.5, +0.5]: s = horizontal (right +), t = vertical (down +)
    my $s = ($u - $u0) / $iw - 0.5;
    my $t = ($v - $v0) / $ih - 0.5;

    # Map to viewing angles from the observer.
    # phi: azimuth of the viewing ray. Right side of image (s > 0) means the
    # observer looks more counterclockwise (toward their left).
    my $phi  = $cfg{phi_fwd} + $s * $cfg{ang_rad};

    # beta: elevation angle below horizontal.  Image bottom (t > 0 in SVG)
    # maps to looking further downward.
    my $beta = $cfg{beta0} + $t * $cfg{elev_rad};

    # Unit viewing direction from observer toward the mirror
    my $cos_b = cos($beta);
    my $dx    = $cos_b * cos($phi);
    my $dy    = $cos_b * sin($phi);
    my $dz    = -sin($beta);              # negative z = downward toward paper

    # Intersect the viewing ray with the cylinder surface
    my $t_cyl = _ana_ray_cylinder(
        $cfg{ex}, $cfg{ey}, $cfg{ez},
        $dx, $dy, $dz,
        $cfg{cx}, $cfg{cy}, $cfg{R},
    );
    return () unless defined $t_cyl;

    # Mirror surface point M
    my $mx = $cfg{ex} + $t_cyl * $dx;
    my $my = $cfg{ey} + $t_cyl * $dy;
    my $mz = $cfg{ez} + $t_cyl * $dz;

    # The cylinder hit must be at or above the paper (z >= 0)
    return () if $mz < -1e-9;

    # Outward unit normal at M (horizontal, pointing away from cylinder axis)
    my $nx = ($mx - $cfg{cx}) / $cfg{R};
    my $ny = ($my - $cfg{cy}) / $cfg{R};

    # Reflect the incident ray off the cylinder surface (nz = 0 for a vertical
    # cylinder, so the z component of the reflected ray is unchanged)
    my ($rx, $ry, $rz) = _ana_reflect($dx, $dy, $dz, $nx, $ny, 0.0);

    # The reflected ray must travel downward (rz < 0) to reach the paper
    return () if $rz >= -1e-9;

    # Intersect the reflected ray with the paper plane (z = 0)
    my $t_paper = -$mz / $rz;
    return () if $t_paper < 0;

    my $px = $mx + $t_paper * $rx;
    my $py = $my + $t_paper * $ry;
    return ($px, $py);
}

# ---------------------------------------------------------------------------
# _ana_resample_segment
#
# Given endpoints (x0,y0) and (x1,y1) in image space, return a list of
# [ x, y ] sample-point arrayrefs spaced at most $step apart.  The start
# point is NOT included (the caller holds it); the end point IS included.
# ---------------------------------------------------------------------------
sub _ana_resample_segment {
    my ($x0, $y0, $x1, $y1, $step) = @_;
    my $ddx  = $x1 - $x0;
    my $ddy  = $y1 - $y0;
    my $dist = sqrt($ddx*$ddx + $ddy*$ddy);
    if ($dist < 1e-12) { return ([$x1, $y1]) }
    my $n = ceil($dist / $step);
    $n = 1 if $n < 1;
    my @pts;
    for my $i (1 .. $n) {
        my $f = $i / $n;
        push @pts, [$x0 + $f*$ddx, $y0 + $f*$ddy];
    }
    return @pts;
}

# ===========================================================================
# PUBLIC ENTRY POINT
# ===========================================================================



# ---------------------------------------------------------------------------
# anamorphic
#
# Transform the current segment path through the cylindrical mirror model.
#
# Usage:
#     $g->anamorphic( $cx, $cy, $R, %opts );
#
# $cx, $cy  Centre of the cylindrical mirror in drawing coordinates.
# $R        Radius of the cylindrical mirror in the same units.
# %opts     Optional parameters (see POD / _ana_build_config).
#
# The method reads the existing psegments, uses their bounding box as the
# image extent, projects every sample point through the mirror model, writes
# the transformed segments back into psegments, then calls stroke() to flush.
# ---------------------------------------------------------------------------
sub anamorphic {
    my ($self, $cx, $cy, $R, %opts) = @_;

    $self->_croak('anamorphic: cylinder radius R must be > 0') unless $R > 0;

    my $step = delete $opts{step} // 1.0;

    # ------------------------------------------------------------------
    # Collect all drawable segment endpoints and compute the image bbox.
    # ------------------------------------------------------------------
    my @segs = @{ $self->{psegments} };

    my (@xs, @ys);
    for my $s (@segs) {
        my $k = $s->{key} // '';
        next unless $k eq 'm' || $k eq 'l';
        push @xs, $s->{sx}, $s->{dx};
        push @ys, $s->{sy}, $s->{dy};
    }
    $self->_croak('anamorphic: segment path is empty') unless @xs;

    my ($u0, $v0) = (min(@xs), min(@ys));
    my ($u1, $v1) = (max(@xs), max(@ys));

    $self->_croak('anamorphic: segment path has zero width or height')
        if $u1 - $u0 < 1e-12 || $v1 - $v0 < 1e-12;

    # ------------------------------------------------------------------
    # Build observer / image-mapping configuration.
    # ------------------------------------------------------------------
    my %cfg = _ana_build_config($cx, $cy, $R, %opts);

    # ------------------------------------------------------------------
    # Extract polylines from the segment path.
    # Each 'm' entry starts a new polyline; 'l' entries continue it,
    # resampled at most $step apart so the non-linear transform stays
    # accurate along longer segments.
    # ------------------------------------------------------------------
    my @polylines;
    my @cur;
    for my $s (@segs) {
        my $k = $s->{key} // '';
        if ($k eq 'm') {
            push @polylines, [@cur] if @cur > 1;
            @cur = ([$s->{dx}, $s->{dy}]);
        }
        elsif ($k eq 'l') {
            push @cur,
                _ana_resample_segment($s->{sx}, $s->{sy},
                                      $s->{dx}, $s->{dy}, $step);
        }
        # penup / pendown / comment entries are ignored
    }
    push @polylines, [@cur] if @cur > 1;

    $self->_croak('anamorphic: segment path contains no drawable segments')
        unless @polylines;

    # ------------------------------------------------------------------
    # Replace the segment path with the transformed version, then flush.
    # ------------------------------------------------------------------
    @{ $self->{psegments} } = ();

    for my $poly (@polylines) {
        my $pen_is_down = 0;
        my ($prev_px, $prev_py);

        for my $pt (@$poly) {
            my ($px, $py) = _ana_transform_point(
                $pt->[0], $pt->[1],
                $u0, $v0, $u1, $v1,
                %cfg,
            );
            unless (defined $px) {
                $pen_is_down = 0;    # ray missed; lift pen before next valid point
                next;
            }
            if (!$pen_is_down) {
                # Insert an explicit PU / move / PD triple and mark it preserved
                push @{ $self->{psegments} },
                    { key => 'u', sx => -1, sy => -1, dx => -1, dy => -1 };
                push @{ $self->{psegments} },
                    { key => 'm', sx => $px, sy => $py, dx => $px, dy => $py, preserve => 1 };
                push @{ $self->{psegments} },
                    { key => 'd', sx => -1, sy => -1, dx => -1, dy => -1 };
                $pen_is_down = 1;
            }
            else {
                push @{ $self->{psegments} },
                    { key => 'l', sx => $prev_px, sy => $prev_py,
                                  dx => $px,       dy => $py };
            }
            ($prev_px, $prev_py) = ($px, $py);
        }
    }

    $self->stroke();
    return 1;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Anamorphic - cylindrical mirror anamorphic
projection for GcodeXY

=head1 SYNOPSIS

    use Graphics::Penplotter::GcodeXY;

    my $g = Graphics::Penplotter::GcodeXY->new(
        papersize => 'A4',
        units     => 'mm',
        outfile   => 'plot.gcode',
    );

    # Build any path -- lines, arcs, imported SVG, etc.
    $g->importsvg('face.svg');           # or $g->line(...), etc.

    # Distort the current segment path for a cylindrical mirror at (100,100)
    # with radius 20 mm.  The path is replaced in-place and flushed.
    $g->anamorphic(
        100, 100,            # cylinder centre (mm)
        20,                  # cylinder radius (mm)
        obs_dist   => 120,   # observer distance from axis (mm)
        obs_height => 120,   # observer height above paper (mm)
        obs_angle  => 0,     # observer azimuth (degrees, default 0 = from +x)
    );

    $g->output();

=head1 DESCRIPTION

A L<Role::Tiny> role that adds the C<anamorphic> method to
L<Graphics::Penplotter::GcodeXY>.

An I<anamorphic image> is a distorted drawing which, when viewed from a
specific vantage point via a curved mirror, appears undistorted.  This role
implements the cylindrical convex mirror variant.

The caller first populates the GcodeXY segment path using any drawing
primitives (C<line>, C<arc>, C<importsvg>, etc.).  The C<anamorphic> method
then reads the existing path, uses its bounding box as the image space,
projects every sample point through the cylindrical mirror model, writes the
transformed path back into the segment buffer, and calls C<stroke> to flush
it to the output stream.

=head2 Physical model

The cylinder stands vertically (axis along z) with its base on the paper
(z = 0).  The observer is at world position

    E = ( cx + D*cos(alpha), cy + D*sin(alpha), H )

where I<D> = C<obs_dist>, I<H> = C<obs_height>, and I<alpha> = C<obs_angle>
converted to radians.

For every sample point of the source path the algorithm:

=over 4

=item 1.

Computes the 3-D viewing direction from E corresponding to the point's
normalised position within the image bounding box.

=item 2.

Finds where that ray first intersects the cylinder surface (the I<mirror
point> M).

=item 3.

Reflects the incident direction off the cylinder's outward normal at M using
the law of reflection.

=item 4.

Follows the reflected ray until it hits the paper plane (z = 0).

=item 5.

Records the resulting paper coordinate as a segment in the new path.

=back

=head2 Image coordinate convention

The bounding box of the incoming segment path is treated as the image canvas:

=over 4

=item *

Horizontally, the left edge (min x) maps to the observer's right side of the
mirror and the right edge (max x) maps to the observer's left side.  (A
convex mirror reverses left and right.)

=item *

Vertically, the top edge (min y) maps to the upper part of the mirror and the
bottom edge (max y) maps to the part closest to the paper.

=back

=head1 METHODS

=head2 anamorphic($cx, $cy, $R [, %opts])

Replace the current segment path with its anamorphic distortion for a
cylindrical mirror of radius C<$R> centred at C<($cx, $cy)>, then flush via
C<stroke>.

The bounding box of the existing path is used as the image extent.  Segments
whose sample points cannot be projected (ray misses the cylinder, or the
reflected ray travels away from the paper) are silently dropped; path
continuity is restored automatically before the next valid point.

Recognised options:

=over 4

=item C<obs_dist> (default 5 * R)

Horizontal distance from the observer to the cylinder axis, in drawing units.
Must be greater than C<$R>.

=item C<obs_height> (default 5 * R)

Height of the observer's eye above the paper, in drawing units.

=item C<obs_angle> (default 0)

Azimuthal direction from which the observer views the mirror, in degrees.
0 means the observer stands to the right of the cylinder (+x); 90 means
from the top (+y), etc.

=item C<angle_range> (default: 90% of the visible horizontal cone)

Total horizontal angular range of the image in degrees.  Reducing this crops
the image toward the centre of the mirror.

=item C<elev_range> (default: 80% of the base elevation angle)

Total vertical angular range of the image in degrees.

=item C<step> (default 1.0)

Maximum distance (in drawing units) between consecutive sample points along
a segment.  Smaller values give smoother distorted curves at the cost of more
output moves.

=back

=head2 Internal helpers (callable from tests)

The following subroutines are plain functions (not methods) and can be called
as C<Graphics::Penplotter::GcodeXY::Anamorphic::_ana_foo(...)>:

=over 4

=item C<_ana_ray_cylinder($ex,$ey,$ez, $dx,$dy,$dz, $cx,$cy,$R)>

Find the smallest positive t where the ray E + t*D intersects the vertical
cylinder of radius R centred at (cx, cy).  Returns t or undef.

=item C<_ana_reflect($dx,$dy,$dz, $nx,$ny,$nz)>

Reflect unit vector D off the surface with outward unit normal N.
Returns (rx, ry, rz).

=item C<_ana_build_config($cx, $cy, $R, %opts)>

Build and return the configuration hash used by C<_ana_transform_point>.

=item C<_ana_transform_point($u,$v, $u0,$v0,$u1,$v1, %cfg)>

Map one image-space point to paper coordinates.  Returns (px, py) or ().

=item C<_ana_resample_segment($x0,$y0, $x1,$y1, $step)>

Subdivide the segment from (x0,y0) to (x1,y1) into intervals of at most
$step.  Returns a list of [x,y] arrayrefs; start point NOT included, end
point IS included.

=back

=head1 SEE ALSO

L<Graphics::Penplotter::GcodeXY>

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
