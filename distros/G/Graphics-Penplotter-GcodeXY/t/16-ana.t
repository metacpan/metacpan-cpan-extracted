#!/usr/bin/perl
# t/16-ana.t -- Tests for Graphics::Penplotter::GcodeXY::Anamorphic
#
# All tests run without the real host module.  The math helpers are tested
# as plain subroutines.  The anamorphic() method itself is tested via a
# lightweight MockPlotter that exposes the psegments array directly.

use v5.38.2;
use strict;
use warnings;

use POSIX ();
use Test::More;

# ---------------------------------------------------------------------------
# Pre-register stub modules so 'use Foo' inside the role resolves to our stubs
# ---------------------------------------------------------------------------
BEGIN {
    $INC{'Role/Tiny.pm'} = 'stub';
}

# ---------------------------------------------------------------------------
# Role::Tiny stub (same pattern as 15-3d.t)
# ---------------------------------------------------------------------------
{
    package Role::Tiny;
    sub import {
        my $role = caller;
        no strict 'refs';
        *{"${role}::requires"} = sub { };
        *{"${role}::after"}    = sub { };
        *{"${role}::before"}   = sub { };
    }
    sub apply_role_to_package {
        my ($role, $target) = @_;
        no strict 'refs';
        for my $sym (keys %{"${role}::"}) {
            next if $sym =~ /^(?:import|requires|after|before|BEGIN|END|ISA)$/;
            my $code = *{"${role}::${sym}"}{CODE} or next;
            *{"${target}::${sym}"} = $code
                unless defined &{"${target}::${sym}"};
        }
    }
}

# ---------------------------------------------------------------------------
# Load the role under test
# ---------------------------------------------------------------------------
do './lib/Graphics/Penplotter/GcodeXY/Anamorphic.pm'
    // do '/mnt/user-data/outputs/Anamorphic.pm'
    // die "Cannot find Anamorphic.pm: $!";
die $@ if $@;

# Convenient shorthand for calling the module's plain-function helpers
my $PKG = 'Graphics::Penplotter::GcodeXY::Anamorphic';

# ---------------------------------------------------------------------------
# MockPlotter -- minimal host class
# ---------------------------------------------------------------------------
{
    package MockPlotter;
    my @log;
    sub new           { bless { _moves => [], _lines => [], psegments => [] }, shift }
    sub penup         { push @log, 'PU'             }
    sub pendown       { push @log, 'PD'             }
    sub _genfastmove  { push @log, "GM @_[1,2]"     }
    sub _genslowmove  { my $self = shift; push @{$self->{_lines}}, [@_]; push @log, "SM @_" }
    sub stroke        { push @log, 'STROKE'         }
    sub gsave         { push @log, 'GSAVE'          }
    sub grestore      { push @log, 'GRESTORE'       }
    sub _croak        { die "croak: $_[1]\n"        }
    sub moveto        { my $self = shift; push @{$self->{_moves}}, [@_]; push @log, "MV @_" }
    sub line          { my ($self, @a) = @_; push @{$self->{_lines}}, [@a]; push @log, "LN @a" }
    sub log_clear     { @log = ()     }
    sub log_get       { @log          }
    sub moves         { @{$_[0]->{_moves}} }
    sub lines         { @{$_[0]->{_lines}} }
    sub _addpath      { my ($self,$k,$sx,$sy,$dx,$dy) = @_;
                        push @{$self->{psegments}}, {key=>$k,sx=>$sx,sy=>$sy,dx=>$dx,dy=>$dy} }
    sub _clearsegs    { @{$_[0]->{psegments}} = () }

    Role::Tiny::apply_role_to_package(
        'Graphics::Penplotter::GcodeXY::Anamorphic',
        'MockPlotter'
    );
}

my $PI = 3.14159265358979;

# ==========================================================================
# Helper: call a module private function by name
# ==========================================================================
sub ana { no strict 'refs'; &{"${PKG}::$_[0]"}(@_[1..$#_]) }

# ==========================================================================
# SECTION 1: _ana_ray_cylinder
# ==========================================================================
{
    # 1. Horizontal ray from +x toward origin, cylinder at origin R=1
    # E=(5,0,0) D=(-1,0,0)  hits at x=1 => t=4
    my $t = ana('_ana_ray_cylinder', 5,0,0, -1,0,0, 0,0, 1);
    ok defined $t,                          'ray_cylinder: direct shot returns defined t';
    ok abs($t - 4.0) < 1e-9,               'ray_cylinder: direct shot t=4';

    # 2. Intersection point is on the cylinder surface
    my ($hx, $hy) = (5 + $t*(-1), 0 + $t*0);
    ok abs($hx - 1.0) < 1e-9,              'ray_cylinder: hit point x=1 (on surface)';
    ok abs($hy - 0.0) < 1e-9,              'ray_cylinder: hit point y=0';

    # 3. Ray parallel to cylinder axis => undef
    my $t2 = ana('_ana_ray_cylinder', 5,0,0, 0,0,1, 0,0, 1);
    ok !defined $t2,                        'ray_cylinder: axis-parallel ray returns undef';

    # 4. Ray missing the cylinder entirely (passing above in x-y plane)
    my $t3 = ana('_ana_ray_cylinder', 5,0,0, 0,1,0, 0,0, 1);
    ok !defined $t3,                        'ray_cylinder: miss returns undef';

    # 5. Ray going away from cylinder (both t < 0) => undef
    my $t4 = ana('_ana_ray_cylinder', 5,0,0, 1,0,0, 0,0, 1);
    ok !defined $t4,                        'ray_cylinder: receding ray returns undef';

    # 6. Ray from inside the cylinder exits at t > 0
    my $t5 = ana('_ana_ray_cylinder', 0,0,0, 1,0,0, 0,0, 1);
    ok defined $t5,                         'ray_cylinder: from inside returns defined t';
    ok abs($t5 - 1.0) < 1e-9,              'ray_cylinder: inside exit at t=1';

    # 7. Oblique ray from (5,5,3) toward origin, cylinder at origin R=1
    # Horizontal distance from E=(5,5) to origin = 5*sqrt2; ray dir = (-1,-1,0)/sqrt2
    my $sq2 = sqrt(2);
    my $t6 = ana('_ana_ray_cylinder',
                 5, 5, 0,
                 -1/$sq2, -1/$sq2, 0,
                 0, 0, 1);
    ok defined $t6,                         'ray_cylinder: oblique ray returns defined t';
    # Hit point should be on the cylinder: x^2+y^2=1
    my $hx2 = 5 + $t6*(-1/$sq2);
    my $hy2 = 5 + $t6*(-1/$sq2);
    ok abs(sqrt($hx2**2+$hy2**2) - 1.0) < 1e-6,
                                            'ray_cylinder: oblique hit on surface';

    # 8. t1 is slightly negative but t2 is positive => returns t2
    # E=(0.5, 0, 0), D=(1,0,0): t1 = -(0.5+1)/1=-1.5 (neg), t2=0.5 (pos)
    my $t7 = ana('_ana_ray_cylinder', 0.5,0,0, 1,0,0, 0,0, 1);
    ok defined $t7,                         'ray_cylinder: exits cylinder when inside on axis';
    ok abs($t7 - 0.5) < 1e-9,              'ray_cylinder: exit t=0.5 for inside shot';
}

# ==========================================================================
# SECTION 2: _ana_reflect
# ==========================================================================
{
    # 1. Normal incidence on x+ face: D=(-1,0,0), N=(1,0,0) => reflect=(1,0,0)
    my ($rx, $ry, $rz) = ana('_ana_reflect', -1,0,0, 1,0,0);
    ok abs($rx - 1.0) < 1e-9,              'reflect: normal incidence rx=1';
    ok abs($ry - 0.0) < 1e-9,              'reflect: normal incidence ry=0';
    ok abs($rz - 0.0) < 1e-9,              'reflect: normal incidence rz=0';

    # 2. Tangent ray unchanged: D=(0,1,0), N=(1,0,0) => D.N=0, reflect=(0,1,0)
    my ($rx2,$ry2,$rz2) = ana('_ana_reflect', 0,1,0, 1,0,0);
    ok abs($rx2 - 0.0) < 1e-9,             'reflect: tangent ray unchanged x';
    ok abs($ry2 - 1.0) < 1e-9,             'reflect: tangent ray unchanged y';

    # 3. 45-degree incidence: D=(-1,-1,0)/sqrt2, N=(1,0,0)
    # D.N = -1/sqrt2; reflect = D - 2*(-1/sqrt2)*(1,0,0) = D + (sqrt2,0,0)
    # = (-1/sqrt2 + sqrt2, -1/sqrt2, 0) = (1/sqrt2, -1/sqrt2, 0)
    my $s2 = 1.0/sqrt(2);
    my ($rx3,$ry3,$rz3) = ana('_ana_reflect', -$s2,-$s2,0, 1,0,0);
    ok abs($rx3 - $s2) < 1e-9,             'reflect: 45-degree rx=1/sqrt2';
    ok abs($ry3 - (-$s2)) < 1e-9,          'reflect: 45-degree ry=-1/sqrt2';
    ok abs($rz3 - 0.0) < 1e-9,             'reflect: 45-degree rz=0';

    # 4. Reflected vector has unit length
    my $len = sqrt($rx3**2 + $ry3**2 + $rz3**2);
    ok abs($len - 1.0) < 1e-9,             'reflect: output is unit length';

    # 5. 3-D case: D=(-1,0,-1)/sqrt2 (pointing down and inward), N=(1,0,0)
    # D.N = -1/sqrt2; reflect = (-1/sqrt2+sqrt2, 0, -1/sqrt2) = (1/sqrt2,0,-1/sqrt2)
    my ($rx4,$ry4,$rz4) = ana('_ana_reflect', -$s2,0,-$s2, 1,0,0);
    ok abs($rx4 - $s2) < 1e-9,             'reflect: 3-D case rx=1/sqrt2';
    ok abs($rz4 - (-$s2)) < 1e-9,          'reflect: 3-D case rz=-1/sqrt2 (still going down)';
}

# ==========================================================================
# SECTION 3: _ana_build_config
# ==========================================================================
{
    # Default observer: obs_angle=0, obs_dist=5*R, obs_height=5*R
    my %cfg = ana('_ana_build_config', 0,0, 1);

    ok abs($cfg{ex} - 5.0) < 1e-9,         'build_config: default ex=5';
    ok abs($cfg{ey} - 0.0) < 1e-9,         'build_config: default ey=0';
    ok abs($cfg{ez} - 5.0) < 1e-9,         'build_config: default ez=5';

    # phi_fwd should point from (5,0) toward (0,0): that is angle pi
    ok abs($cfg{phi_fwd} - $PI) < 1e-9,    'build_config: phi_fwd=pi for default obs';

    # ang_rad: 2*asin(1/5)*0.9 ~ 2*0.20136*0.9 ~ 0.36245
    my $expected_ang = 2.0 * atan2(0.2, sqrt(1-0.04)) * 0.90;
    ok abs($cfg{ang_rad} - $expected_ang) < 1e-6,
                                            'build_config: default ang_rad matches formula';

    # beta0 = atan2(H, D) = atan2(5,5) = pi/4
    ok abs($cfg{beta0} - $PI/4) < 1e-9,    'build_config: beta0=pi/4 for H=D';

    # elev_rad = beta0 * 0.8
    ok abs($cfg{elev_rad} - $PI/4 * 0.8) < 1e-9,
                                            'build_config: elev_rad=beta0*0.8';

    # Custom obs_angle=90 (observer from +y direction)
    my %cfg2 = ana('_ana_build_config', 0,0, 1, obs_angle => 90);
    ok abs($cfg2{ex} - 0.0) < 1e-6,        'build_config: obs_angle=90 ex~0';
    ok abs($cfg2{ey} - 5.0) < 1e-6,        'build_config: obs_angle=90 ey=5';
    # phi_fwd from (0,5) toward (0,0) = -pi/2
    ok abs($cfg2{phi_fwd} - (-$PI/2)) < 1e-6,
                                            'build_config: phi_fwd=-pi/2 for obs_angle=90';

    # Custom obs_dist
    my %cfg3 = ana('_ana_build_config', 0,0, 1, obs_dist => 10);
    ok abs($cfg3{ex} - 10.0) < 1e-9,       'build_config: custom obs_dist=10';

    # Non-origin cylinder centre
    my %cfg4 = ana('_ana_build_config', 3,4, 2);
    ok abs($cfg4{ex} - (3 + 10*cos(0))) < 1e-9,
                                            'build_config: shifted cylinder ex=cx+obs_dist';
    ok abs($cfg4{ey} - 4.0) < 1e-9,        'build_config: shifted cylinder ey=cy';

    # Custom angle_range and elev_range in degrees
    my %cfg5 = ana('_ana_build_config', 0,0, 1,
                   angle_range => 20, elev_range => 30);
    ok abs($cfg5{ang_rad}  - 20*$PI/180) < 1e-9, 'build_config: custom angle_range=20 deg';
    ok abs($cfg5{elev_rad} - 30*$PI/180) < 1e-9, 'build_config: custom elev_range=30 deg';

    # Croak when obs_dist <= R
    eval { ana('_ana_build_config', 0,0, 5, obs_dist => 5) };
    like $@, qr/obs_dist/i,                'build_config: croaks when obs_dist==R';

    eval { ana('_ana_build_config', 0,0, 5, obs_dist => 3) };
    like $@, qr/obs_dist/i,                'build_config: croaks when obs_dist<R';

    # Croak for R<=0
    eval { ana('_ana_build_config', 0,0, 0) };
    like $@, qr/radius/i,                  'build_config: croaks for R=0';
}

# ==========================================================================
# SECTION 4: _ana_transform_point
# ==========================================================================
# Use a fixed, analytically verified configuration:
#   cylinder at origin, R=1, observer at (5,0,5), phi_fwd=pi
# Centre of image (s=0, t=0): looking at phi=pi, beta=pi/4
#   Ray from (5,0,5) in dir (-cos45,0,-cos45) = (-s2,0,-s2)
#   Cylinder hit at t=4*sqrt2: M=(1,0,1)
#   Normal at M = (1,0,0)
#   Reflected: (-s2,0,-s2) -> (s2,0,-s2)  [z unchanged for vertical cylinder]
#   Paper hit: t_paper = -1/(-s2) = sqrt2; P=(1+1,0,0) = (2,0)
{
    my %cfg = ana('_ana_build_config', 0,0, 1);

    # Image bounding box 0..100 x 0..100; centre maps to (s=0,t=0)
    my ($px, $py) = ana('_ana_transform_point',
                        50, 50,        # image point at centre
                        0, 0, 100, 100,
                        %cfg);

    ok defined $px,                         'transform: centre of image returns defined px';
    ok defined $py,                         'transform: centre of image returns defined py';
    ok abs($px - 2.0) < 1e-6,              'transform: image centre maps to px=2';
    ok abs($py - 0.0) < 1e-6,              'transform: image centre maps to py=0';

    # Different horizontal positions give symmetric (same px, opposite py) results
    my ($px_l, $py_l) = ana('_ana_transform_point',
                             25, 50, 0,0,100,100, %cfg);   # left quarter
    my ($px_r, $py_r) = ana('_ana_transform_point',
                             75, 50, 0,0,100,100, %cfg);   # right quarter
    ok defined $px_l && defined $px_r,     'transform: off-centre points return values';
    ok abs($py_l + $py_r) < 1e-6,         'transform: left/right image points antisymmetric in y';

    # The centre point (px=2,py=0) is beyond the cylinder surface (R=1), so
    # the reflected ray travelled outward -- verify px > R
    ok $px > 1.0,                          'transform: paper point is beyond cylinder surface';

    # A point at top of image (v=0 => t=-0.5) looks more upward => may still hit
    my ($px_top) = ana('_ana_transform_point',
                       50, 0, 0,0,100,100, %cfg);
    ok defined $px_top,                    'transform: top of image maps to valid point';

    # Degenerate bbox: should return ()
    my @nil = ana('_ana_transform_point', 5,5, 0,0,0,0, %cfg);
    ok !@nil,                              'transform: zero-size bbox returns empty list';

    # Very wide angle (s = 10) should miss the cylinder
    # Build a config with very large ang_rad so s=0.5 points sideways
    my %cfg_wide = ana('_ana_build_config', 0,0, 1, angle_range => 360);
    my @far = ana('_ana_transform_point', 95, 50, 0,0,100,100, %cfg_wide);
    # With 360 degree range and s=0.45 the ray goes nearly sideways -- may or
    # may not hit depending on geometry; just confirm the function doesn't die
    ok 1,                                  'transform: extreme angle handled without error';

    # Reflected ray going upward: cylinder directly above observer?  Hard to
    # trigger naturally, but we at least confirm return-type consistency.
    my @result = ana('_ana_transform_point', 50, 50, 0,0,100,100, %cfg);
    ok scalar(@result) == 0 || scalar(@result) == 2,
                                           'transform: return is always 0 or 2 values';
}

# ==========================================================================
# SECTION 5: _ana_resample_segment
# ==========================================================================
{
    # Trivial: identical points returns the endpoint
    my @r0 = ana('_ana_resample_segment', 5,5, 5,5, 1.0);
    is scalar @r0, 1,                       'resample: zero-length returns 1 point';
    ok abs($r0[0][0] - 5) < 1e-9,          'resample: zero-length point x=5';

    # Segment (0,0)-(10,0) step=3: ceil(10/3)=4 intervals => 4 points
    my @r1 = ana('_ana_resample_segment', 0,0, 10,0, 3);
    is scalar @r1, 4,                       'resample: 10/step=3 gives 4 pts';
    ok abs($r1[-1][0] - 10) < 1e-9,        'resample: last point is endpoint';
    ok abs($r1[0][0] - 2.5) < 1e-9,        'resample: first sample at 10/4=2.5';

    # Step larger than segment => 1 point (just the endpoint)
    my @r2 = ana('_ana_resample_segment', 0,0, 3,4, 100);
    is scalar @r2, 1,                       'resample: step>length gives 1 point';
    ok abs($r2[0][0] - 3) < 1e-9,          'resample: endpoint x=3';
    ok abs($r2[0][1] - 4) < 1e-9,          'resample: endpoint y=4';

    # Diagonal: length=5, step=1 => 5 points, all on the line y=x*(4/3)
    my @r3 = ana('_ana_resample_segment', 0,0, 3,4, 1);
    is scalar @r3, 5,                       'resample: diagonal 5 pts at step=1';
    for my $pt (@r3) {
        # Each point should satisfy y = (4/3)*x (the line from (0,0) to (3,4))
        my $expected_y = ($pt->[0] / 3.0) * 4.0;
        ok abs($pt->[1] - $expected_y) < 1e-9,
                                            'resample: diagonal pt on line';
    }
}

# ==========================================================================
# SECTION 6: anamorphic() integration
# ==========================================================================
{
    # ------------------------------------------------------------------
    # Build a diagonal path from (0,0) to (100,50), giving a well-defined
    # 100x50 bounding box.  Two 'l' segments so resampling is exercised.
    # ------------------------------------------------------------------
    my $g = MockPlotter->new;
    $g->_addpath('m',  0,  0,  0,  0);
    $g->_addpath('l',  0,  0, 50, 25);
    $g->_addpath('l', 50, 25,100, 50);

    $g->log_clear;
    my $ret = $g->anamorphic(0, 0, 1, obs_dist => 10, obs_height => 10, step => 10);
    is $ret, 1,                              'anamorphic: returns 1 on success';

    my @log = $g->log_get;
    ok grep({ $_ eq 'STROKE' } @log),       'anamorphic: calls stroke';

    # After stroke() the mock does not clear psegments (no real newpath),
    # so we can inspect what anamorphic() wrote back before stroke() emptied it.
    # We capture via a stroke override during the call instead -- but that is
    # complex.  Instead we verify structural output via a spy on psegments
    # written inside anamorphic BEFORE stroke() is called, by using a
    # subclassed mock that captures the snapshot.

    # Simpler: since MockPlotter::stroke just logs 'STROKE' and does NOT clear
    # psegments (no newpath call), psegments still holds the transformed path
    # after the method returns.
    my @ns = @{ $g->{psegments} };
    ok @ns >= 1,                             'anamorphic: produces transformed segments';
    ok grep({ $_->{key} eq 'm' } @ns),      'anamorphic: output contains a moveto segment';
    ok grep({ $_->{key} eq 'l' } @ns),      'anamorphic: output contains line segments';

    # All transformed coordinates must be finite numbers
    my $all_finite = 1;
    for my $s (@ns) {
        for my $k (qw(sx sy dx dy)) {
            unless (defined $s->{$k} && $s->{$k} == $s->{$k}) {
                $all_finite = 0; last;
            }
        }
        last unless $all_finite;
    }
    ok $all_finite,                          'anamorphic: all output coords are finite';

    # ------------------------------------------------------------------
    # Croak on R = 0
    # ------------------------------------------------------------------
    $g->_clearsegs;
    $g->_addpath('m', 0,0, 0,0);
    $g->_addpath('l', 0,0, 10,10);
    eval { $g->anamorphic(0, 0, 0) };
    like $@, qr/radius/i,                   'anamorphic: croaks on R=0';

    # ------------------------------------------------------------------
    # Croak on empty segment path
    # ------------------------------------------------------------------
    $g->_clearsegs;
    eval { $g->anamorphic(0, 0, 1) };
    like $@, qr/empty/i,                    'anamorphic: croaks on empty segment path';

    # ------------------------------------------------------------------
    # Croak when path has no drawable (m/l) segments
    # ------------------------------------------------------------------
    $g->_clearsegs;
    $g->_addpath('u', -1,-1,-1,-1);   # pen-up only
    eval { $g->anamorphic(0, 0, 1) };
    like $@, qr/empty/i,                    'anamorphic: croaks when path has no drawable segs';

    # ------------------------------------------------------------------
    # Croak on degenerate (zero-size) bounding box
    # ------------------------------------------------------------------
    $g->_clearsegs;
    $g->_addpath('m', 5,5, 5,5);
    $g->_addpath('l', 5,5, 5,5);   # all points the same -> zero bbox
    eval { $g->anamorphic(0, 0, 1) };
    like $@, qr/zero width/i,               'anamorphic: croaks on zero-size bbox';

    # ------------------------------------------------------------------
    # Two separate polylines each produce at least one moveto.
    # A dummy 'm' at y=50 extends the combined bbox to [0,50] on y so
    # both real polylines sit at t < 0 (upper half) and project cleanly.
    # The dummy moveto has no following 'l' so it is never emitted as a
    # drawable segment (polyline length < 2 is discarded).
    # ------------------------------------------------------------------
    $g = MockPlotter->new;
    $g->_addpath('m',  0, 50,  0, 50);  # bbox anchor only -- no following 'l'
    $g->_addpath('m',  0,  0,  0,  0);  # polyline 1 at y=0  (t = 0/50-0.5 = -0.5)
    $g->_addpath('l',  0,  0, 50,  0);
    $g->_addpath('m',  0, 10,  0, 10);  # polyline 2 at y=10 (t = 10/50-0.5 = -0.3)
    $g->_addpath('l',  0, 10, 50, 10);
    $g->anamorphic(0, 0, 1, obs_dist => 10, obs_height => 10, step => 50);
    my $mv_count = grep { $_->{key} eq 'm' } @{ $g->{psegments} };
    ok $mv_count >= 2,                       'anamorphic: two polylines give >=2 moveto segs';
}
# ==========================================================================
# SECTION 7: Geometric consistency checks
# ==========================================================================
{
    # Symmetry: image point at left (u=25) and right (u=75) of a 100-wide image
    # should give paper points symmetric about the observer axis (y=0 for obs_angle=0)
    my %cfg = ana('_ana_build_config', 0,0, 1);   # observer at (5,0,5)

    my ($px_l, $py_l) = ana('_ana_transform_point',
                             25, 50, 0,0,100,100, %cfg);
    my ($px_r, $py_r) = ana('_ana_transform_point',
                             75, 50, 0,0,100,100, %cfg);

    SKIP: {
        skip 'left/right points did not hit', 2
            unless defined $py_l && defined $py_r;

        # By symmetry py_l should be -py_r (antisymmetric about y=0)
        ok abs($py_l + $py_r) < 1e-6,          'geometry: left/right pts antisymmetric in y';
        # And px_l == px_r by the same symmetry
        ok abs($px_l - $px_r) < 1e-6,          'geometry: left/right pts same x (symmetric)';
    }

    # Centre of image always has py=0 for obs_angle=0 (by symmetry)
    my ($px_c, $py_c) = ana('_ana_transform_point',
                             50, 50, 0,0,100,100, %cfg);
    SKIP: {
        skip 'centre point did not hit', 1 unless defined $py_c;
        ok abs($py_c) < 1e-6,                  'geometry: image centre maps to py=0';
    }

    # Paper point must always be OUTSIDE the cylinder (distance from origin > R)
    for my $u (10, 30, 50, 70, 90) {
        my ($px, $py) = ana('_ana_transform_point',
                            $u, 50, 0,0,100,100, %cfg);
        next unless defined $px;
        my $dist = sqrt($px**2 + $py**2);
        ok $dist > 1.0 - 1e-9,                 "geometry: u=$u paper pt outside cylinder";
    }
}

done_testing;
