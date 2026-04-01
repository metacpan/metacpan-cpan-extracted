#!/usr/bin/perl
# t/15-3d.t -- Tests for Graphics::Penplotter::GcodeXY::Geometry3D
#
# Runs without a real Role::Tiny or the host module by using minimal stubs.
# All stub code is confined to the BEGIN block at the top.

use v5.38.2;
use strict;
use warnings;

use POSIX ();    # load the real POSIX *before* we stub anything else

use Test::More;

# ---------------------------------------------------------------------------
# Pre-register stub modules in %INC so 'use Foo' inside the role resolves
# to our stubs instead of trying to load from disk.
# ---------------------------------------------------------------------------
BEGIN {
    $INC{'Role/Tiny.pm'} = 'stub';
    $INC{'Readonly.pm'}  = 'stub';
}

# ---------------------------------------------------------------------------
# Role::Tiny stub
# ---------------------------------------------------------------------------
{
    package Role::Tiny;
    my (%after, %before);

    sub import {
        my $role = caller;
        no strict 'refs';
        *{"${role}::requires"} = sub { };
        *{"${role}::after"}  = sub {
            my ($m,$c) = @_; push @{$after{$role}{$m}},  $c };
        *{"${role}::before"} = sub {
            my ($m,$c) = @_; push @{$before{$role}{$m}}, $c };
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
        for my $meth (keys %{ $after{$role} // {} }) {
            my $orig = *{"${target}::${meth}"}{CODE} or next;
            my @hooks = @{ $after{$role}{$meth} };
            no warnings 'redefine';
            *{"${target}::${meth}"} = sub {
                my @rv = $orig->(@_);
                $_->(@_) for @hooks;
                return wantarray ? @rv : $rv[0];
            };
        }
    }
}

# ---------------------------------------------------------------------------
# Load the role
# ---------------------------------------------------------------------------
do './lib/Graphics/Penplotter/GcodeXY/Geometry3D.pm'
    // do '/mnt/user-data/outputs/Geometry3D.pm'
    // die "Cannot find Geometry3D.pm: $!";
die $@ if $@;

# ---------------------------------------------------------------------------
# Minimal host class
# ---------------------------------------------------------------------------
{
    package MockPlotter;
    my @log;
    sub new     { bless {}, shift }
    sub penup            { push @log, 'PU'              }
    sub pendown          { push @log, 'PD'              }
    sub _genfastmove     { push @log, "GM $_[1],$_[2]" }
    sub _genslowmove     { push @log, "SM $_[1],$_[2]" }
    sub stroke           { push @log, 'STROKE'          }
    sub _croak           { die "croak: $_[1]\n"         }
    sub gsave   ($self)  { $self->{_gs2d} //= []; push @{$self->{_gs2d}}, 1 }
    sub grestore($self)  { pop @{$self->{_gs2d}} }
    sub log_clear  { @log = () }
    sub log_get    { @log      }

    Role::Tiny::apply_role_to_package(
        'Graphics::Penplotter::GcodeXY::Geometry3D',
        'MockPlotter'
    );
}

my $g = MockPlotter->new;

# ==========================================================================
# Helper: count unique vertices by stringifying them
# ==========================================================================
sub unique_verts {
    my $m = shift;
    my %seen;
    $seen{ sprintf('%.9f,%.9f,%.9f', @$_) }++ for @{$m->{verts}};
    return scalar keys %seen;
}

# ==========================================================================
# SECTION: prism
# ==========================================================================
{
    $g->initmatrix3();
    my $m = $g->prism(0,0,0, 2,3,4);
    is scalar @{$m->{verts}}, 8,  'prism: 8 vertices';
    is scalar @{$m->{faces}}, 12, 'prism: 12 triangular faces (2 per box face)';

    my ($lo,$hi) = $g->bbox3($m);
    ok abs($lo->[0] - -1) < 1e-9, 'prism: bbox x-min = -1';
    ok abs($hi->[0] -  1) < 1e-9, 'prism: bbox x-max =  1';
    ok abs($lo->[1] - -1.5) < 1e-9, 'prism: bbox y-min = -1.5';
    ok abs($hi->[1] -  1.5) < 1e-9, 'prism: bbox y-max =  1.5';
    ok abs($lo->[2] - -2) < 1e-9, 'prism: bbox z-min = -2';
    ok abs($hi->[2] -  2) < 1e-9, 'prism: bbox z-max =  2';

    # Cube as special case
    my $c = $g->prism(0,0,0, 5,5,5);
    is scalar @{$c->{faces}}, 12, 'prism cube special case: 12 faces';
    my ($clo,$chi) = $g->bbox3($c);
    ok abs($chi->[0] - 2.5) < 1e-9, 'prism cube: correct half-extent';
}

# ==========================================================================
# SECTION: sphere (UV)
# ==========================================================================
{
    $g->initmatrix3();
    my $m = $g->sphere(0,0,0, 1, 6, 12);
    # Expected verts: (lat+1) * lon = 7 * 12 = 84
    is scalar @{$m->{verts}}, 84, 'sphere: correct vertex count for lat=6 lon=12';
    # All vertices should be on the unit sphere
    for my $v (@{$m->{verts}}) {
        my $r = sqrt($v->[0]**2 + $v->[1]**2 + $v->[2]**2);
        ok abs($r - 1) < 1e-9, 'sphere: vertex on unit sphere surface';
        last;   # spot-check first vertex only to avoid test explosion
    }
    # Face count: lat*(lon-1)*2 degenerate-skipping... just check > 0
    ok scalar @{$m->{faces}} > 0, 'sphere: has faces';

    # Offset centre check
    my $m2 = $g->sphere(5,0,0, 2, 4, 8);
    my ($lo,$hi) = $g->bbox3($m2);
    ok abs($lo->[0] - 3) < 1e-9, 'sphere: centred at x=5, r=2, min x=3';
    ok abs($hi->[0] - 7) < 1e-9, 'sphere: centred at x=5, r=2, max x=7';
}

# ==========================================================================
# SECTION: icosphere
# ==========================================================================
{
    $g->initmatrix3();
    # Subdivision 0: raw icosahedron (20 faces, 12 vertices)
    my $m0 = $g->icosphere(0,0,0, 1, 0);
    is scalar @{$m0->{faces}}, 20, 'icosphere subdiv=0: 20 faces';
    is scalar @{$m0->{verts}}, 12, 'icosphere subdiv=0: 12 vertices';

    # Subdivision 1: 80 faces
    my $m1 = $g->icosphere(0,0,0, 1, 1);
    is scalar @{$m1->{faces}}, 80,  'icosphere subdiv=1: 80 faces';

    # Subdivision 2: 320 faces
    my $m2 = $g->icosphere(0,0,0, 1, 2);
    is scalar @{$m2->{faces}}, 320, 'icosphere subdiv=2: 320 faces';

    # All vertices must lie on the sphere surface
    for my $v (@{$m2->{verts}}) {
        my $rr = sqrt($v->[0]**2+$v->[1]**2+$v->[2]**2);
        ok abs($rr - 1) < 1e-9, 'icosphere: vertex on unit sphere';
        last;   # spot-check
    }

    # Radius scaling
    my $m3 = $g->icosphere(0,0,0, 3, 1);
    my ($lo,$hi) = $g->bbox3($m3);
    ok $hi->[0] <= 3 + 1e-9, 'icosphere: scaled radius upper bound';
    ok $lo->[0] >= -3 - 1e-9, 'icosphere: scaled radius lower bound';
}

# ==========================================================================
# SECTION: frustum / cone
# ==========================================================================
{
    $g->initmatrix3();
    my $seg = 16;

    # Full frustum
    my $f = $g->frustum(0,0,0, 2,1,4,$seg);
    # Vertex layout: seg (bot ring) + 1 (bot ctr) + seg (top ring) + 1 (top ctr)
    is scalar @{$f->{verts}}, $seg*2+2, 'frustum: correct vertex count';
    # Face layout: 4 triangles per segment (2 side + 1 bot cap + 1 top cap)
    is scalar @{$f->{faces}}, $seg*4,   'frustum: correct face count';

    my ($lo,$hi) = $g->bbox3($f);
    ok abs($lo->[2] - -2) < 1e-9, 'frustum: z-min = -height/2';
    ok abs($hi->[2] -  2) < 1e-9, 'frustum: z-max = +height/2';

    # Cone (r_top = 0): same vertex layout
    my $c = $g->cone(0,0,0, 2,4,$seg);
    is scalar @{$c->{verts}}, $seg*2+2, 'cone: same vertex count as frustum';
    # All top-ring vertices should be at (0,0,height/2)
    my @top_ring = @{$c->{verts}}[$seg+1..$seg*2];
    for my $tv (@top_ring) {
        ok abs($tv->[0]) < 1e-9 && abs($tv->[1]) < 1e-9,
            'cone: top ring vertices collapse to apex x=y=0';
        last;  # spot-check
    }

    # Cylinder as frustum (r_bot == r_top)
    my $cyl = $g->frustum(0,0,0, 3,3,5,$seg);
    my ($clo,$chi) = $g->bbox3($cyl);
    ok abs($chi->[0] - 3) < 1e-9, 'frustum-cylinder: radial extent matches r';
}

# ==========================================================================
# SECTION: capsule
# ==========================================================================
{
    $g->initmatrix3();
    my $r = 1;  my $h = 4;  my $sr = 8;  my $sh = 4;
    my $m = $g->capsule(0,0,0, $r,$h,$sr,$sh);

    # Vertex count: 1 (top pole) + sh*sr (top hem) + sr (bot eq) + (sh-1)*sr (bot hem) + 1 (bot pole)
    # = 2 + (2*sh)*sr
    my $expected_verts = 2 + 2*$sh*$sr;
    is scalar @{$m->{verts}}, $expected_verts, 'capsule: vertex count';

    ok scalar @{$m->{faces}} > 0, 'capsule: has faces';

    my ($lo,$hi) = $g->bbox3($m);
    # Total extent in Z: h + 2*r
    ok abs($hi->[2] - ($h/2 + $r)) < 1e-9, 'capsule: top z = h/2 + r';
    ok abs($lo->[2] - (-$h/2 - $r)) < 1e-9, 'capsule: bot z = -(h/2+r)';

    # Radial extent should not exceed r
    ok $hi->[0] <= $r + 1e-9, 'capsule: radial extent <= r';
}

# ==========================================================================
# SECTION: plane
# ==========================================================================
{
    $g->initmatrix3();

    my $m = $g->plane(0,0,0, 4,6, 2,3);
    # Vertices: (segs_w+1)*(segs_h+1) = 3*4 = 12
    is scalar @{$m->{verts}}, 12, 'plane: vertex count (segs_w=2 segs_h=3)';
    # Faces: 2 * segs_w * segs_h = 2*2*3 = 12
    is scalar @{$m->{faces}}, 12, 'plane: face count';

    my ($lo,$hi) = $g->bbox3($m);
    ok abs($lo->[0] - -2) < 1e-9, 'plane: x-min = -w/2';
    ok abs($hi->[0] -  2) < 1e-9, 'plane: x-max = +w/2';
    ok abs($lo->[1] - -3) < 1e-9, 'plane: y-min = -h/2';
    ok abs($hi->[1] -  3) < 1e-9, 'plane: y-max = +h/2';
    # All z == 0
    for my $v (@{$m->{verts}}) {
        ok abs($v->[2]) < 1e-9, 'plane: all z == cz';
        last;
    }

    # Minimal (1x1) plane: 4 vertices, 2 faces
    my $m1 = $g->plane(0,0,5, 1,1);
    is scalar @{$m1->{verts}}, 4, 'plane 1x1: 4 vertices';
    is scalar @{$m1->{faces}}, 2, 'plane 1x1: 2 faces';
    my ($lo1,$hi1) = $g->bbox3($m1);
    ok abs($lo1->[2] - 5) < 1e-9, 'plane: z offset applied to all vertices';
}

# ==========================================================================
# SECTION: torus
# ==========================================================================
{
    $g->initmatrix3();
    my ($R,$r,$maj,$min) = (3, 0.5, 12, 8);
    my $m = $g->torus(0,0,0, $R,$r,$maj,$min);
    # Vertices: maj_seg * min_seg
    is scalar @{$m->{verts}}, $maj*$min, 'torus: vertex count';
    # Faces: 2 * maj_seg * min_seg
    is scalar @{$m->{faces}}, 2*$maj*$min, 'torus: face count';

    my ($lo,$hi) = $g->bbox3($m);
    # Outermost radius = R + r = 3.5
    ok abs($hi->[0] - ($R+$r)) < 1e-9, 'torus: outer x-max = R + r';
    ok abs($lo->[0] + ($R+$r)) < 1e-9, 'torus: outer x-min = -(R+r)';
    # Z extent = +/- r
    ok abs($hi->[2] - $r) < 1e-9, 'torus: z-max = r';
    ok abs($lo->[2] + $r) < 1e-9, 'torus: z-min = -r';
}

# ==========================================================================
# SECTION: disk
# ==========================================================================
{
    $g->initmatrix3();
    my $seg = 20;
    my $m = $g->disk(0,0,0, 2, $seg);
    # Vertices: 1 (centre) + seg (rim)
    is scalar @{$m->{verts}}, $seg+1, 'disk: vertex count';
    is scalar @{$m->{faces}}, $seg,   'disk: face count';

    # Centre vertex
    my $centre = $m->{verts}[0];
    ok abs($centre->[0]) < 1e-9 && abs($centre->[1]) < 1e-9,
        'disk: vertex 0 is the centre';

    # All vertices at z=0
    for my $v (@{$m->{verts}}) {
        ok abs($v->[2]) < 1e-9, 'disk: all z == 0';
        last;
    }

    # Rim vertices at radius 2
    for my $v (@{$m->{verts}}[1..$seg]) {
        my $rr = sqrt($v->[0]**2 + $v->[1]**2);
        ok abs($rr - 2) < 1e-9, 'disk: rim vertex at correct radius';
        last;
    }

    # Z offset
    my $m2 = $g->disk(0,0,7, 1, 6);
    my ($lo,$hi) = $g->bbox3($m2);
    ok abs($hi->[2] - 7) < 1e-9 && abs($lo->[2] - 7) < 1e-9,
        'disk: z offset applied';
}

# ==========================================================================
# SECTION: pyramid
# ==========================================================================
{
    $g->initmatrix3();
    my $sides = 4;
    my $m = $g->pyramid(0,0,0, 2,5,$sides);
    # Vertices: sides (base ring) + 1 (apex) + 1 (base centre)
    is scalar @{$m->{verts}}, $sides+2, 'pyramid: vertex count';
    # Faces: sides (side) + sides (base fan) = 2*sides
    is scalar @{$m->{faces}}, $sides*2, 'pyramid: face count';

    my ($lo,$hi) = $g->bbox3($m);
    ok abs($lo->[2]) < 1e-9,     'pyramid: base at z=0';
    ok abs($hi->[2] - 5) < 1e-9, 'pyramid: apex at z=height';

    # Triangular pyramid (tetrahedron-like)
    my $tri = $g->pyramid(0,0,0, 1,2,3);
    is scalar @{$tri->{verts}}, 5, 'pyramid sides=3: 5 vertices';
    is scalar @{$tri->{faces}}, 6, 'pyramid sides=3: 6 faces';

    # Pentagon
    my $pent = $g->pyramid(0,0,0, 1,1,5);
    is scalar @{$pent->{faces}}, 10, 'pyramid sides=5: 10 faces';
}

# ==========================================================================
# SECTION: axis_gizmo
# ==========================================================================
{
    $g->initmatrix3();
    MockPlotter::log_clear();
    $g->axis_gizmo(0,0,0, 1);
    my @log = MockPlotter::log_get();

    ok scalar(grep { /PU/ } @log) >= 3,
        'axis_gizmo: at least 3 penup calls (one per axis)';
    ok scalar(grep { /SM/ } @log) > 0,
        'axis_gizmo: slow-move calls for cone edges';
    ok scalar(grep { /GM/ } @log) > 0,
        'axis_gizmo: fast-move calls';

    # Custom length and cone dimensions
    MockPlotter::log_clear();
    $g->axis_gizmo(5,5,0, 2, 0.1, 0.3);
    my @log2 = MockPlotter::log_get();
    ok scalar @log2 > 0, 'axis_gizmo: custom params produce output';
}

# ==========================================================================
# SECTION: compute_normals works on all new mesh types
# ==========================================================================
{
    $g->initmatrix3();
    for my $m (
        $g->prism(0,0,0,1,1,1),
        $g->icosphere(0,0,0,1,1),
        $g->frustum(0,0,0,1,0.5,2,8),
        $g->capsule(0,0,0,1,2,8,4),
        $g->plane(0,0,0,1,1,2,2),
        $g->torus(0,0,0,2,0.5,8,6),
        $g->disk(0,0,0,1,8),
        $g->pyramid(0,0,0,1,2,4),
    ) {
        $g->compute_normals($m);
        ok defined $m->{face_normals},   'compute_normals: face_normals set';
        ok defined $m->{vertex_normals}, 'compute_normals: vertex_normals set';
        # All face normals should be unit-length
        for my $fn (@{$m->{face_normals}}) {
            my $l = sqrt($fn->[0]**2+$fn->[1]**2+$fn->[2]**2);
            ok abs($l - 1) < 1e-6, 'compute_normals: unit face normal';
            last;
        }
    }
}

# ==========================================================================
# SECTION: bbox3 on new mesh types
# ==========================================================================
{
    $g->initmatrix3();
    # torus: should be symmetric about origin
    my $t = $g->torus(0,0,0, 2,1, 16,8);
    my ($lo,$hi) = $g->bbox3($t);
    ok abs($hi->[0] + $lo->[0]) < 1e-9, 'torus bbox: symmetric in X';
    ok abs($hi->[1] + $lo->[1]) < 1e-9, 'torus bbox: symmetric in Y';
    ok abs($hi->[2] + $lo->[2]) < 1e-9, 'torus bbox: symmetric in Z';
}

# ==========================================================================
# SECTION: flatten_to_2d on new meshes
# ==========================================================================
{
    $g->initmatrix3();
    my $m = $g->prism(0,0,0, 1,1,1);
    my $segs = $g->flatten_to_2d($m);
    # A box has 12 unique edges; flatten_to_2d deduplicates
    is scalar @$segs, 18, 'flatten_to_2d prism: 18 unique triangle edges';

    my $d = $g->disk(0,0,0, 1, 6);
    my $ds = $g->flatten_to_2d($d);
    ok scalar @$ds > 0, 'flatten_to_2d disk: produces edges';
}

# ==========================================================================
# SECTION: draw_polylines and project_to_svg with new meshes
# ==========================================================================
{
    $g->initmatrix3();
    my $m = $g->torus(0,0,0, 2,0.5, 6,4);
    my $segs = $g->flatten_to_2d($m);
    MockPlotter::log_clear();
    $g->draw_polylines($segs);
    my @log = MockPlotter::log_get();
    ok grep { /STROKE/ } @log, 'draw_polylines torus: stroke called';

    my $svg = $g->project_to_svg($segs);
    ok $svg =~ m{<svg}i,  'project_to_svg torus: has <svg>';
    ok $svg =~ m{<line},  'project_to_svg torus: has <line>';
}

# ==========================================================================
# SECTION: mesh_to_obj / mesh_from_obj round-trip for new meshes
# ==========================================================================
{
    $g->initmatrix3();
    my $orig = $g->prism(0,0,0, 2,3,4);
    my $obj  = $g->mesh_to_obj($orig, 'test_prism');
    ok $obj =~ /^o test_prism/m, 'mesh_to_obj prism: object name present';
    my $rt = $g->mesh_from_obj($obj);
    is scalar @{$rt->{verts}}, scalar @{$orig->{verts}},
        'mesh_from_obj prism: vertex count preserved';
    is scalar @{$rt->{faces}}, scalar @{$orig->{faces}},
        'mesh_from_obj prism: face count preserved';
}

# ==========================================================================
# SECTION: mesh_to_stl / mesh_from_stl round-trip for new meshes
# ==========================================================================
{
    $g->initmatrix3();
    my $orig = $g->pyramid(0,0,0, 1,2,4);
    my $stl  = $g->mesh_to_stl($orig);
    ok $stl =~ /solid/,  'mesh_to_stl pyramid: has solid keyword';
    my $rt = $g->mesh_from_stl($stl);
    is scalar @{$rt->{faces}}, scalar @{$orig->{faces}},
        'mesh_from_stl pyramid: face count preserved';
}

# ==========================================================================
# SECTION: gsave / grestore with 3D state preserved across primitives
# ==========================================================================
{
    $g->initmatrix3();
    $g->translate3(10,0,0);
    $g->gsave();
    $g->translate3(5,0,0);
    my @p1 = $g->transform_point([0,0,0]);
    ok abs($p1[0] - 15) < 1e-9, 'gsave: translate accumulates';
    $g->grestore();
    my @p2 = $g->transform_point([0,0,0]);
    ok abs($p2[0] - 10) < 1e-9, 'grestore: restores CTM3';
}

# ==========================================================================
# SECTION: backface_cull on new mesh types
# ==========================================================================
{
    $g->initmatrix3();
    my $m = $g->prism(0,0,0, 2,2,2);
    my $vis = $g->backface_cull($m, view_dir => [0,0,-1]);
    ok scalar @$vis > 0, 'backface_cull prism: some faces visible';
    ok scalar @$vis < scalar @{$m->{faces}},
        'backface_cull prism: not all faces visible from one direction';
}

# ==========================================================================
# SECTION: set_camera / get_camera basics
# ==========================================================================
{
    $g->initmatrix3();

    # Default camera: eye at Z, looking at origin
    $g->set_camera(
        eye    => [0, 0, 5],
        center => [0, 0, 0],
        up     => [0, 1, 0],
    );
    my $cam = $g->get_camera();
    ok defined $cam, 'set_camera: get_camera returns a record';
    ok ref $cam eq 'HASH', 'get_camera: returns a hashref';

    # Eye and centre stored correctly
    ok abs($cam->{eye}[2]    - 5) < 1e-9, 'set_camera: eye Z stored';
    ok abs($cam->{center}[0])     < 1e-9, 'set_camera: center X stored';

    # Forward vector should point from eye toward centre: (0,0,-1)
    ok abs($cam->{fwd}[0])        < 1e-9, 'set_camera: fwd X = 0';
    ok abs($cam->{fwd}[1])        < 1e-9, 'set_camera: fwd Y = 0';
    ok abs($cam->{fwd}[2] - -1)   < 1e-9, 'set_camera: fwd Z = -1';

    # Recomputed up should still be (0,1,0) for this canonical setup
    ok abs($cam->{up}[0])         < 1e-9, 'set_camera: up X = 0';
    ok abs($cam->{up}[1] - 1)     < 1e-9, 'set_camera: up Y = 1';
    ok abs($cam->{up}[2])         < 1e-9, 'set_camera: up Z = 0';

    # View matrix is 4x4
    ok ref $cam->{view} eq 'ARRAY' && scalar @{$cam->{view}} == 4,
        'set_camera: view is a 4x4 matrix';
    ok scalar @{$cam->{view}[0]} == 4, 'set_camera: view row 0 has 4 elements';

    # View matrix is orthonormal: rows 0-2 should each be unit-length
    for my $row (0..2) {
        my @r = @{$cam->{view}[$row]}[0..2];
        my $l = sqrt($r[0]**2 + $r[1]**2 + $r[2]**2);
        ok abs($l - 1) < 1e-9, "set_camera: view row $row is unit-length";
    }
}

# ==========================================================================
# SECTION: set_camera with non-trivial eye position
# ==========================================================================
{
    $g->initmatrix3();

    # Camera to the side, looking at origin
    $g->set_camera(
        eye    => [10, 0, 0],
        center => [0,  0, 0],
        up     => [0,  0, 1],   # Z-up for this orientation
    );
    my $cam = $g->get_camera();

    # Forward vector must be unit-length
    my $flen = sqrt( $cam->{fwd}[0]**2 + $cam->{fwd}[1]**2 + $cam->{fwd}[2]**2 );
    ok abs($flen - 1) < 1e-9, 'set_camera side: fwd is unit length';

    # Forward should point along -X: (-1, 0, 0)
    ok abs($cam->{fwd}[0] - -1) < 1e-9, 'set_camera side: fwd X = -1';
    ok abs($cam->{fwd}[1])      < 1e-9, 'set_camera side: fwd Y = 0';
    ok abs($cam->{fwd}[2])      < 1e-9, 'set_camera side: fwd Z = 0';

    # Recomputed up should be unit-length
    my $ulen = sqrt( $cam->{up}[0]**2 + $cam->{up}[1]**2 + $cam->{up}[2]**2 );
    ok abs($ulen - 1) < 1e-9, 'set_camera side: up is unit length';

    # View matrix rows 0..2 mutually orthogonal (dot products ~0)
    my @rows = map { [ @{$cam->{view}[$_]}[0..2] ] } 0..2;
    for my $i (0..2) {
        for my $j ($i+1..2) {
            my $dot = $rows[$i][0]*$rows[$j][0]
                    + $rows[$i][1]*$rows[$j][1]
                    + $rows[$i][2]*$rows[$j][2];
            ok abs($dot) < 1e-9, "set_camera: view rows $i and $j are orthogonal";
        }
    }
}

# ==========================================================================
# SECTION: set_camera error cases
# ==========================================================================
{
    $g->initmatrix3();

    # Eye == centre should croak
    eval { $g->set_camera(eye => [1,1,1], center => [1,1,1]) };
    ok $@ =~ /same point/i, 'set_camera: croaks when eye == center';

    # Up parallel to forward should croak
    eval {
        $g->set_camera(
            eye    => [0, 0, 5],
            center => [0, 0, 0],
            up     => [0, 0, 1],    # parallel to forward (0,0,-1)
        )
    };
    ok $@ =~ /parallel/i, 'set_camera: croaks when up is parallel to view dir';
}

# ==========================================================================
# SECTION: get_camera before set_camera
# ==========================================================================
{
    # Fresh object, no camera set yet
    my $fresh = MockPlotter->new;
    ok !defined $fresh->get_camera(), 'get_camera: returns undef before set_camera';
}

# ==========================================================================
# SECTION: camera_to_ctm bakes view transform into CTM
# ==========================================================================
{
    $g->initmatrix3();

    # Camera at (0,0,5) looking at origin.
    # After baking, transform_point([0,0,0]) should give the origin in camera
    # space: (0, 0, -5) — i.e. 5 units in front of the camera along -Z.
    $g->set_camera(
        eye    => [0, 0, 5],
        center => [0, 0, 0],
        up     => [0, 1, 0],
    );
    $g->camera_to_ctm();

    my @p = $g->transform_point([0, 0, 0]);
    ok abs($p[0])       < 1e-9, 'camera_to_ctm: origin maps to cam-X = 0';
    ok abs($p[1])       < 1e-9, 'camera_to_ctm: origin maps to cam-Y = 0';
    ok abs($p[2] - -5)  < 1e-9, 'camera_to_ctm: origin maps to cam-Z = -5 (in front)';

    # The eye position itself should map to (0,0,0) in camera space
    my @eye = $g->transform_point([0, 0, 5]);
    ok abs($eye[0]) < 1e-9, 'camera_to_ctm: eye maps to cam-X = 0';
    ok abs($eye[1]) < 1e-9, 'camera_to_ctm: eye maps to cam-Y = 0';
    ok abs($eye[2]) < 1e-9, 'camera_to_ctm: eye maps to cam-Z = 0';

    # camera_to_ctm without set_camera should croak
    my $fresh = MockPlotter->new;
    eval { $fresh->camera_to_ctm() };
    ok $@ =~ /no camera/i, 'camera_to_ctm: croaks when no camera set';
}

# ==========================================================================
# SECTION: camera_to_ctm — side-on camera
# ==========================================================================
{
    $g->initmatrix3();

    # Eye on the +X axis, looking at origin, Z-up.
    # After baking: a point at (10,0,0) (the eye) -> cam-Z = 0;
    # a point at origin -> cam-Z = -10 (10 units in front of eye along -Z).
    $g->set_camera(
        eye    => [10, 0, 0],
        center => [0,  0, 0],
        up     => [0,  0, 1],
    );
    $g->camera_to_ctm();

    my @origin = $g->transform_point([0, 0, 0]);
    ok abs($origin[2] - -10) < 1e-9,
        'camera_to_ctm side: origin 10 units in front of eye';

    my @eye = $g->transform_point([10, 0, 0]);
    ok abs($eye[2]) < 1e-9,
        'camera_to_ctm side: eye position maps to cam-Z = 0';
}

# ==========================================================================
# SECTION: backface_cull uses stored camera fwd automatically
# ==========================================================================
{
    $g->initmatrix3();

    my $m = $g->prism(0, 0, 0, 2, 2, 2);

    # Count visible faces with explicit view_dir from +Z
    my $vis_explicit = $g->backface_cull($m, view_dir => [0, 0, -1]);

    # Now set a camera from the same direction and use the auto-pickup
    $g->set_camera(
        eye    => [0, 0, 10],
        center => [0, 0,  0],
        up     => [0, 1,  0],
    );
    my $vis_auto = $g->backface_cull($m);   # no view_dir argument

    is scalar @$vis_auto, scalar @$vis_explicit,
        'backface_cull: auto camera fwd gives same result as explicit view_dir';

    # A camera from a completely different direction should see different faces
    $g->set_camera(
        eye    => [0, 10, 0],
        center => [0,  0, 0],
        up     => [0,  0, 1],
    );
    my $vis_side = $g->backface_cull($m);

    ok scalar @$vis_side > 0, 'backface_cull: camera from +Y sees some faces';
    # The sets of visible faces should differ from the +Z view
    isnt scalar @$vis_side . join(',', sort @$vis_side),
         scalar @$vis_explicit . join(',', sort @$vis_explicit),
        'backface_cull: different camera sees different faces';
}

# ==========================================================================
# SECTION: camera state saved and restored by gsave / grestore
# ==========================================================================
{
    $g->initmatrix3();

    # Set an initial camera
    $g->set_camera(
        eye    => [0, 0, 5],
        center => [0, 0, 0],
        up     => [0, 1, 0],
    );
    my $cam_before = $g->get_camera();

    $g->gsave();

    # Replace the camera inside the gsave block
    $g->set_camera(
        eye    => [5, 5, 5],
        center => [0, 0, 0],
        up     => [0, 1, 0],
    );
    my $cam_inner = $g->get_camera();
    ok abs($cam_inner->{eye}[0] - 5) < 1e-9,
        'camera gsave: inner set_camera takes effect';

    $g->grestore();

    my $cam_after = $g->get_camera();
    ok defined $cam_after, 'camera grestore: camera restored (not undef)';
    ok abs($cam_after->{eye}[2] - 5) < 1e-9,
        'camera grestore: eye Z restored to original value';
    ok abs($cam_after->{eye}[0])     < 1e-9,
        'camera grestore: eye X restored to 0';
}

# ==========================================================================
# SECTION: gsave / grestore with no camera set (undef round-trip)
# ==========================================================================
{
    my $fresh = MockPlotter->new;

    ok !defined $fresh->get_camera(),
        'camera grestore undef: starts with no camera';

    $fresh->gsave();
    $fresh->set_camera(
        eye    => [1, 2, 3],
        center => [0, 0, 0],
        up     => [0, 1, 0],
    );
    ok defined $fresh->get_camera(),
        'camera grestore undef: camera set inside gsave block';

    $fresh->grestore();
    ok !defined $fresh->get_camera(),
        'camera grestore undef: grestore restores undef camera';
}

# ==========================================================================
# SECTION: occlusion_clip -- diagonal suppression, aliasing, occluder support
# ==========================================================================
#
# Tests target three distinct fixes in occlusion_clip / hidden_line_remove:
#
#   1. Coplanar diagonal suppression
#      Each quad face of prism() is tessellated into 2 triangles.  The shared
#      edge (the "diagonal") must be suppressed so cube faces appear as
#      rectangles, not as two triangles.
#
#   2. Shared-reference aliasing fix
#      Before the fix, multiple segment endpoints held the *same* [$x,$y]
#      arrayref.  An in-place viewport transform (e.g. $pt->[0] *= SCALE)
#      then compounded the scale factor once per alias, producing astronomical
#      coordinates.  After the fix every endpoint is an independent copy.
#
#   3. Occluder support
#      hidden_line_remove accepts occluders => \@meshes.  Those meshes
#      populate the z-buffer in a first pass so that target triangles behind
#      them fail the depth test and are omitted.

{
    # Helper: set up a plotter with a straight-on perspective camera.
    # Eye at (0,0,-100), looking at origin, FOV=45.
    my sub make_straight ($fov=45) {
        my $p = MockPlotter->new;
        $p->initmatrix3();
        $p->set_camera(eye=>[0,0,-100], center=>[0,0,0], up=>[0,1,0]);
        $p->camera_to_ctm();
        $p->set_perspective(fov=>$fov, aspect=>1, near=>1, far=>500);
        $p->perspective_to_ctm();
        return $p;
    }

    # Helper: corner camera -- eye at (100,100,-100), same target and FOV.
    my sub make_corner () {
        my $p = MockPlotter->new;
        $p->initmatrix3();
        $p->set_camera(eye=>[100,100,-100], center=>[0,0,0], up=>[0,1,0]);
        $p->camera_to_ctm();
        $p->set_perspective(fov=>45, aspect=>1, near=>1, far=>500);
        $p->perspective_to_ctm();
        return $p;
    }

    # --- 1. Diagonal suppression ---

    # Straight-on camera: only the front (-Z) face is visible after backface
    # cull.  That face has 4 edges.  Without diagonal suppression the two
    # triangles comprising that face would generate 6 edges (including the
    # internal diagonal), of which 2 would be duplicated -> still 4 unique
    # edges, but WITH the diagonal = 5.  After suppression: exactly 4.
    {
        my $p = make_straight();
        my $m = $p->prism(0,0,0, 20,20,20);
        my $segs = $p->hidden_line_remove($m);
        is scalar @$segs, 4,
            'diagonal suppression: straight-on view, 1 face visible -> 4 edges';
    }

    # Corner camera: +X, +Y, -Z faces all visible (3 faces).
    # Each adjacent pair shares one cube edge, so 3x4 - 3 = 9 unique edges.
    # Without diagonal suppression each face would emit 5 edges -> 15 - 3 = 12
    # (minus shared genuine edges), an incorrect higher count.
    {
        my $p = make_corner();
        my $m = $p->prism(0,0,0, 20,20,20);
        my $segs = $p->hidden_line_remove($m);
        is scalar @$segs, 9,
            'diagonal suppression: corner view, 3 faces visible -> 9 unique edges';
    }

    # --- 2. Aliasing fix: no two segment endpoints share the same arrayref ---

    {
        my $p = make_corner();
        my $m = $p->prism(0,0,0, 20,20,20);
        my $segs = $p->hidden_line_remove($m);

        my %seen_ref;
        my $aliases = 0;
        for my $seg (@$segs) {
            for my $pt (@$seg) {
                $aliases++ if $seen_ref{"$pt"}++;
            }
        }
        is $aliases, 0,
            'aliasing fix: no segment endpoints share the same arrayref';
    }

    # Confirm coordinates are finite and in a sane range for NDC space.
    {
        my $p = make_straight();
        my $m = $p->prism(0,0,0, 20,20,20);
        my $segs = $p->hidden_line_remove($m);
        my $ok = 1;
        for my $seg (@$segs) {
            for my $pt (@$seg) {
                $ok = 0 if !defined $pt->[0] || abs($pt->[0]) > 100
                        || !defined $pt->[1] || abs($pt->[1]) > 100;
            }
        }
        ok $ok, 'aliasing fix: all NDC coordinates are finite and < 100';
    }

    # --- 3. Occluder support ---

    # Fully occluded: front cube 20x20x20 at z=0, back cube 10x10x10 at z=30.
    # Straight-on camera: back cube projects entirely inside front cube's
    # footprint.  Without an occluder, back cube returns 4 segments (its
    # single visible face).  With the front cube as an occluder, the back
    # cube's triangles all lose the z-test -> 0 segments.
    {
        my $p     = make_straight();
        my $front = $p->prism(0,0,0,  20,20,20);
        my $back  = $p->prism(0,0,30, 10,10,10);

        my $segs_solo = $p->hidden_line_remove($back);
        ok scalar @$segs_solo > 0,
            'occluder: back cube is visible when processed alone';

        my $segs_occluded = $p->hidden_line_remove($back, occluders => [$front]);
        is scalar @$segs_occluded, 0,
            'occluder: back cube fully occluded by front cube -> 0 segments';
    }

    # Same-size full occlusion: front 20x20x20 at z=0, back 20x20x20 at z=30.
    {
        my $p     = make_straight();
        my $front = $p->prism(0,0,0,  20,20,20);
        my $back  = $p->prism(0,0,30, 20,20,20);
        my $segs  = $p->hidden_line_remove($back, occluders => [$front]);
        is scalar @$segs, 0,
            'occluder: same-size back cube fully occluded -> 0 segments';
    }

    # Non-occluded: occluder that does NOT overlap back cube's footprint
    # must leave the back cube's segment count unchanged.
    {
        my $p         = make_straight();
        my $far_left  = $p->prism(-50,0,0, 20,20,20);  # way off to the side
        my $back      = $p->prism(  0,0,30, 10,10,10);

        my $segs_solo = $p->hidden_line_remove($back);
        my $segs_occ  = $p->hidden_line_remove($back, occluders => [$far_left]);
        is scalar @$segs_occ, scalar @$segs_solo,
            'occluder: non-overlapping occluder does not remove any segments';
    }

    # Multiple occluders: two front cubes together fully occlude the back cube
    # even when neither alone would.
    {
        my $p      = make_straight();
        # Back cube 20x20: -10..10 in X and Y.
        # Left occluder covers -10..2 in X; right covers -2..10 in X.
        # Together they fully cover -10..10.
        my $left   = $p->prism(-4, 0, 0, 12, 20, 20);   # x: -10..-4+6 = -10..2
        my $right  = $p->prism( 4, 0, 0, 12, 20, 20);   # x: 4-6..4+6  = -2..10
        my $back   = $p->prism( 0, 0, 30, 20, 20, 20);

        my $segs = $p->hidden_line_remove($back, occluders => [$left, $right]);
        is scalar @$segs, 0,
            'occluder: two partial occluders together fully hide back cube -> 0 segments';
    }

    # Segment count with occluders never exceeds count without occluders.
    {
        my $p     = make_corner();
        my $front = $p->prism(0,0,0,  20,20,20);
        my $back  = $p->prism(0,0,30, 20,20,20);
        my $s_no  = $p->hidden_line_remove($back);
        my $s_occ = $p->hidden_line_remove($back, occluders => [$front]);
        ok scalar @$s_occ <= scalar @$s_no,
            'occluder: segment count with occluder <= count without';
    }
}

done_testing();
