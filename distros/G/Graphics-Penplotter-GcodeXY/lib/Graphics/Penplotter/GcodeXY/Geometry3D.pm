package Graphics::Penplotter::GcodeXY::Geometry3D v0.9.4;

# Role::Tiny role adding 3-D geometry to Graphics::Penplotter::GcodeXY.
#
# Design constraints
# ------------------
# The host class (GcodeXY) already defines:
#   gsave / grestore / moveto / movetoR / line / lineR /
#   translate / translateC / scale / rotate / initmatrix / currentpoint
# Role::Tiny does NOT override methods that already exist in the consuming
# class, so all of those that we need 3-D variants of are renamed with a
# '3' suffix (translate3, scale3, rotate3, moveto3, line3, ...).
# gsave / grestore are extended via 'after'/'before' modifiers so that the
# 3-D CTM stack is kept in sync with the 2-D one transparently.
#
# All private 3-D state lives in $self->{_g3_*} keys; nothing collides with
# the host's own hash slots.

use v5.38.2;
use strict;
use warnings;
use Role::Tiny;
use POSIX qw( floor ceil acos tan );

# --------------------------------------------------------------------------
# The consuming class must provide these primitive hooks
# --------------------------------------------------------------------------
requires qw(
    penup pendown
    _genfastmove _genslowmove
    stroke
    _croak
    gsave grestore
);

# --------------------------------------------------------------------------
# Module-private constants (plain lexicals -- no Readonly dependency needed)
# --------------------------------------------------------------------------
my $PI      = 3.14159265358979323846;
my $D2R     = $PI / 180.0;
my $EPSILON = 1e-9;

# ==========================================================================
# SECTION: Private (non-method) helpers
# ==========================================================================

sub _g3_id4 {
    return [ [1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,0,1] ];
}

sub _g3_clone4 {
    my ($m) = @_;
    return defined $m ? [ map { [ @$_ ] } @$m ] : _g3_id4();
}

# Accessor that auto-initialises the 3-D CTM
sub _g3_ctm {
    my ($self) = @_;
    $self->{_g3_CTM} //= _g3_id4();
    return $self->{_g3_CTM};
}

# ==========================================================================
# SECTION: Extend gsave / grestore with 3-D state
# ==========================================================================

after 'gsave' => sub {
    my ($self) = @_;
    $self->{_g3_gstate} //= [];
    push @{ $self->{_g3_gstate} }, {
        CTM    => _g3_clone4( $self->{_g3_CTM} ),
        posx   => $self->{_g3_posx} // 0,
        posy   => $self->{_g3_posy} // 0,
        posz   => $self->{_g3_posz} // 0,
        camera     => $self->{_g3_camera},      # undef is fine; restores to no-camera
        projection => $self->{_g3_projection},  # undef is fine; restores to no-projection
    };
};

after 'grestore' => sub {
    my ($self) = @_;
    return unless $self->{_g3_gstate} && @{ $self->{_g3_gstate} };
    my $rec = pop @{ $self->{_g3_gstate} };
    $self->{_g3_CTM}    = _g3_clone4( $rec->{CTM} );
    $self->{_g3_posx}   = $rec->{posx};
    $self->{_g3_posy}   = $rec->{posy};
    $self->{_g3_posz}   = $rec->{posz};
    $self->{_g3_camera}     = $rec->{camera};
    $self->{_g3_projection} = $rec->{projection};
};

# ==========================================================================
# SECTION: 3-D CTM management
# ==========================================================================

# Reset the 3-D CTM to identity
sub initmatrix3 ($self) {
    $self->{_g3_CTM} = _g3_id4();
    return 1;
}

# Premultiply 4x4 matrix $aref into $bref  (B := A x B)
sub _g3_premul4 ($self, $aref, $bref) {
    my @tmp;
    for my $r (0..3) {
        for my $c (0..3) {
            $tmp[$r][$c] = 0;
            $tmp[$r][$c] += $aref->[$r][$_] * $bref->[$_][$c] for 0..3;
        }
    }
    for my $r (0..3) { $bref->[$r][$_] = $tmp[$r][$_] for 0..3 }
    return 1;
}

# Multiply two 4x4 matrices, returning a new matrix ref (A x B)
sub compose_matrix ($self, $aref, $bref) {
    my @out;
    for my $r (0..3) {
        for my $c (0..3) {
            $out[$r][$c] = 0;
            $out[$r][$c] += $aref->[$r][$_] * $bref->[$_][$c] for 0..3;
        }
    }
    return \@out;
}

# Gauss-Jordan 4x4 matrix inversion.  Returns matrix ref or undef on failure.
sub invert_matrix ($self, $mref) {
    my @m   = map { [ @$_ ] } @$mref;
    my @inv = ( [1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1] );
    for my $col (0..3) {
        my $piv = $col;
        for my $r ($col+1..3) {
            $piv = $r if abs($m[$r][$col]) > abs($m[$piv][$col]);
        }
        return undef if abs($m[$piv][$col]) < $EPSILON;
        if ($piv != $col) {
            @m[$col,$piv]   = @m[$piv,$col];
            @inv[$col,$piv] = @inv[$piv,$col];
        }
        my $d = $m[$col][$col];
        for my $c (0..3) { $m[$col][$c] /= $d;  $inv[$col][$c] /= $d }
        for my $r (0..3) {
            next if $r == $col;
            my $f = $m[$r][$col] or next;
            for my $c (0..3) {
                $m[$r][$c]   -= $f * $m[$col][$c];
                $inv[$r][$c] -= $f * $inv[$col][$c];
            }
        }
    }
    return [ map { [ @$_ ] } @inv ];
}

# Translate the 3-D CTM by (tx, ty, tz)
sub translate3 ($self, $tx, $ty, $tz = 0) {
    defined $tx && defined $ty
        or $self->_croak('translate3: need tx, ty [, tz]');
    my @m = ( [1,0,0,$tx],[0,1,0,$ty],[0,0,1,$tz],[0,0,0,1] );
    $self->_g3_premul4(\@m, _g3_ctm($self));
    return 1;
}

# Move the 3-D origin to the current 3-D position
sub translateC3 ($self) {
    my ($x,$y,$z) = $self->currentpoint3();
    my $m = _g3_ctm($self);
    $m->[0][3] = $x;  $m->[1][3] = $y;  $m->[2][3] = $z;
    $self->currentpoint3(0,0,0);
    return 1;
}

# Scale the 3-D CTM.  sy and sz default to sx.
sub scale3 ($self, $sx, $sy = undef, $sz = undef) {
    defined $sx or $self->_croak('scale3: need sx [, sy [, sz]]');
    $sy //= $sx;  $sz //= $sx;
    my @m = ( [$sx,0,0,0],[0,$sy,0,0],[0,0,$sz,0],[0,0,0,1] );
    $self->_g3_premul4(\@m, _g3_ctm($self));
    return 1;
}

# Rotate the 3-D CTM about an arbitrary axis.
# Usage: $g->rotate3(axis => [ax,ay,az], deg => $angle)
sub rotate3 ($self, %args) {
    my $axis = $args{axis}
        or $self->_croak('rotate3: need axis=>[ax,ay,az]');
    my $deg  = $args{deg} // $args{angle}
        // $self->_croak('rotate3: need deg=>angle');
    my ($ax,$ay,$az) = @$axis;
    my $len = sqrt($ax*$ax + $ay*$ay + $az*$az);
    $self->_croak('rotate3: zero-length axis') if $len < $EPSILON;
    ($ax,$ay,$az) = ($ax/$len, $ay/$len, $az/$len);
    my $rad = $deg * $D2R;
    my ($c,$s,$t) = (cos($rad), sin($rad), 1 - cos($rad));
    my @r = (
        [ $t*$ax*$ax+$c,      $t*$ax*$ay-$s*$az,  $t*$ax*$az+$s*$ay,  0 ],
        [ $t*$ax*$ay+$s*$az,  $t*$ay*$ay+$c,      $t*$ay*$az-$s*$ax,  0 ],
        [ $t*$ax*$az-$s*$ay,  $t*$ay*$az+$s*$ax,  $t*$az*$az+$c,      0 ],
        [ 0, 0, 0, 1 ],
    );
    $self->_g3_premul4(\@r, _g3_ctm($self));
    return 1;
}

# Euler rotation.  Order is a string like 'XYZ', 'ZYX', etc.
sub rotate3_euler ($self, $rx, $ry, $rz, $order = 'XYZ') {
    my ($sx,$cx) = (sin($rx*$D2R), cos($rx*$D2R));
    my ($sy,$cy) = (sin($ry*$D2R), cos($ry*$D2R));
    my ($sz,$cz) = (sin($rz*$D2R), cos($rz*$D2R));
    my %mat = (
        X => [ [1,0,0,0],[0,$cx,-$sx,0],[0,$sx,$cx,0],[0,0,0,1] ],
        Y => [ [$cy,0,$sy,0],[0,1,0,0],[-$sy,0,$cy,0],[0,0,0,1] ],
        Z => [ [$cz,-$sz,0,0],[$sz,$cz,0,0],[0,0,1,0],[0,0,0,1] ],
    );
    $self->_g3_premul4($mat{$_}, _g3_ctm($self)) for split //, $order;
    return 1;
}

# ==========================================================================
# SECTION: 3-D current point
# ==========================================================================

# Get or set the 3-D current point (stored independently of the host's 2-D one)
sub currentpoint3 ($self, $nx = undef, $ny = undef, $nz = undef) {
    if (defined $nx) {
        $self->{_g3_posx} = $nx;
        $self->{_g3_posy} = $ny // 0;
        $self->{_g3_posz} = $nz // 0;
        return 1;
    }
    return ( $self->{_g3_posx} // 0,
             $self->{_g3_posy} // 0,
             $self->{_g3_posz} // 0 );
}

# ==========================================================================
# SECTION: 3-D point transformation
# ==========================================================================

# Transform a single 3-D point through the current 3-D CTM.
# Input: arrayref [x,y,z] or flat list.
# Returns: list (tx, ty, tz) with perspective divide if w != 1.
sub transform_point ($self, $pt_or_x, $py = undef, $pz = undef) {
    my ($px,$y,$z);
    if (ref $pt_or_x eq 'ARRAY') { ($px,$y,$z) = @$pt_or_x }
    else                          { ($px,$y,$z) = ($pt_or_x, $py//0, $pz//0) }
    $z //= 0;
    my $m = _g3_ctm($self);
    my $tx = $m->[0][0]*$px + $m->[0][1]*$y + $m->[0][2]*$z + $m->[0][3];
    my $ty = $m->[1][0]*$px + $m->[1][1]*$y + $m->[1][2]*$z + $m->[1][3];
    my $tz = $m->[2][0]*$px + $m->[2][1]*$y + $m->[2][2]*$z + $m->[2][3];
    my $tw = $m->[3][0]*$px + $m->[3][1]*$y + $m->[3][2]*$z + $m->[3][3];
    if (defined $tw && $tw != 0 && $tw != 1) {
        return ($tx/$tw, $ty/$tw, $tz/$tw);
    }
    return ($tx, $ty, $tz);
}

# Transform an arrayref of points, returning an arrayref of [tx,ty,tz].
sub transform_points ($self, $pts_ref) {
    return [ map { [ $self->transform_point($_) ] } @$pts_ref ];
}

# ==========================================================================
# SECTION: 3-D drawing primitives
# ==========================================================================

# Move to a 3-D point.  Transforms through CTM3, calls host's 2-D move hooks.
sub moveto3 ($self, $x, $y, $z = 0) {
    my ($px,$py) = ($self->transform_point([$x,$y,$z]))[0,1];
    $self->penup();
    $self->_genfastmove($px,$py);
    $self->pendown();
    $self->currentpoint3($x,$y,$z);
    return 1;
}

# Relative moveto3 from current 3-D position
sub movetoR3 ($self, $dx, $dy, $dz = 0) {
    my ($cx,$cy,$cz) = $self->currentpoint3();
    return $self->moveto3($cx+$dx, $cy+$dy, $cz+$dz);
}

# Draw a line in 3-D space.
# 6-arg form: line3(x1,y1,z1, x2,y2,z2) - moves to start, draws to end
# 3-arg form: line3(x,y,z)               - pen assumed down, draws from current
sub line3 ($self, $x1, $y1, $z1 = 0, $x2 = undef, $y2 = undef, $z2 = undef) {
    if (defined $x2 && defined $y2) {
        $self->moveto3($x1,$y1,$z1);
        my ($px,$py) = ($self->transform_point([$x2,$y2,$z2//0]))[0,1];
        $self->_genslowmove($px,$py);
        $self->currentpoint3($x2,$y2,$z2//0);
    } else {
        my ($px,$py) = ($self->transform_point([$x1,$y1,$z1]))[0,1];
        $self->_genslowmove($px,$py);
        $self->currentpoint3($x1,$y1,$z1);
    }
    return 1;
}

# Relative line3 from current 3-D position
sub lineR3 ($self, $dx, $dy, $dz = 0) {
    my ($cx,$cy,$cz) = $self->currentpoint3();
    return $self->line3($cx+$dx, $cy+$dy, $cz+$dz);
}

# Open polygon: move to first point, draw to remaining points.
# Coordinates: flat list of triples (x1,y1,z1, x2,y2,z2, ...)
sub polygon3 ($self, @coords) {
    @coords >= 6         or $self->_croak('polygon3: need at least 6 numbers');
    @coords % 3 == 0     or $self->_croak('polygon3: coordinate count must be a multiple of 3');
    my ($x,$y,$z) = splice @coords, 0, 3;
    $self->moveto3($x,$y,$z);
    while (@coords) {
        ($x,$y,$z) = splice @coords, 0, 3;
        my ($px,$py) = ($self->transform_point([$x,$y,$z]))[0,1];
        $self->_genslowmove($px,$py);
        $self->currentpoint3($x,$y,$z);
    }
    return 1;
}

# Closed polygon: like polygon3 but auto-closes back to the first point.
sub polygon3C ($self, @coords) {
    @coords >= 6         or $self->_croak('polygon3C: need at least 6 numbers');
    @coords % 3 == 0     or $self->_croak('polygon3C: coordinate count must be a multiple of 3');
    my ($x0,$y0,$z0) = @coords[0,1,2];
    $self->polygon3(@coords);
    my ($px,$py) = ($self->transform_point([$x0,$y0,$z0]))[0,1];
    $self->_genslowmove($px,$py);
    $self->currentpoint3($x0,$y0,$z0);
    return 1;
}

# Relative polygon: like polygon3 but each triple is relative to the current point.
sub polygon3R ($self, @deltas) {
    @deltas >= 3         or $self->_croak('polygon3R: need at least 3 numbers');
    @deltas % 3 == 0     or $self->_croak('polygon3R: coordinate count must be a multiple of 3');
    while (@deltas) {
        my ($cx,$cy,$cz) = $self->currentpoint3();
        my ($dx,$dy,$dz) = splice @deltas, 0, 3;
        $self->line3($cx+$dx, $cy+$dy, $cz+$dz);
    }
    return 1;
}

# ==========================================================================
# SECTION: 3-D mesh constructor and solid primitives
# ==========================================================================

# Construct a mesh data structure { verts => \@v, faces => \@f }
sub mesh ($self, $verts_ref, $faces_ref) {
    return { verts => $verts_ref // [], faces => $faces_ref // [] };
}

# --------------------------------------------------------------------------
# Wireframe drawing primitives (draw directly, return 1)
# --------------------------------------------------------------------------

# Wireframe axis-aligned box
sub box3 ($self, $x1,$y1,$z1,$x2,$y2,$z2) {
    $self->polygon3C($x1,$y1,$z1, $x2,$y1,$z1, $x2,$y2,$z1, $x1,$y2,$z1);  # bottom face
    $self->polygon3C($x1,$y1,$z2, $x2,$y1,$z2, $x2,$y2,$z2, $x1,$y2,$z2);  # top face
    $self->line3($x1,$y1,$z1,$x1,$y1,$z2);   # vertical edges
    $self->line3($x2,$y1,$z1,$x2,$y1,$z2);
    $self->line3($x2,$y2,$z1,$x2,$y2,$z2);
    $self->line3($x1,$y2,$z1,$x1,$y2,$z2);
    return 1;
}

# Wireframe cube centred at (cx,cy,cz)
sub cube ($self, $cx,$cy,$cz,$side) {
    my $h = $side / 2.0;
    return $self->box3($cx-$h,$cy-$h,$cz-$h, $cx+$h,$cy+$h,$cz+$h);
}

# Three-axis wireframe gizmo.  Draws X, Y, Z axes as lines with arrow cones.
# $len is the full axis length (body + arrowhead).
# $cone_r / $cone_h default to 5% / 15% of $len.
sub axis_gizmo ($self, $cx,$cy,$cz,$len=1,$cone_r=undef,$cone_h=undef) {
    $cone_r //= $len * 0.05;
    $cone_h //= $len * 0.15;
    my $body  = $len - $cone_h;
    my $cseg  = 8;

    # Draw one axis: direction (dx,dy,dz), radial basis r1 and r2
    my $draw_arrow = sub {
        my ($dx,$dy,$dz,$r1x,$r1y,$r1z,$r2x,$r2y,$r2z) = @_;
        # Axis body
        $self->line3($cx, $cy, $cz,
                     $cx+$dx*$body, $cy+$dy*$body, $cz+$dz*$body);
        # Cone base ring
        my @ring;
        for my $i (0..$cseg-1) {
            my $t = 2*$PI*$i/$cseg;
            my $ca = $cone_r * cos($t);
            my $sa = $cone_r * sin($t);
            push @ring,
                $cx + $dx*$body + $r1x*$ca + $r2x*$sa,
                $cy + $dy*$body + $r1y*$ca + $r2y*$sa,
                $cz + $dz*$body + $r1z*$ca + $r2z*$sa;
        }
        $self->polygon3C(@ring);
        # Cone lines from ring to tip
        my ($tipx,$tipy,$tipz) = ($cx+$dx*$len, $cy+$dy*$len, $cz+$dz*$len);
        for my $i (0..$cseg-1) {
            $self->line3(@ring[$i*3..$i*3+2], $tipx,$tipy,$tipz);
        }
    };

    $draw_arrow->(1,0,0, 0,1,0, 0,0,1);  # X axis, radials in Y/Z
    $draw_arrow->(0,1,0, 1,0,0, 0,0,1);  # Y axis, radials in X/Z
    $draw_arrow->(0,0,1, 1,0,0, 0,1,0);  # Z axis, radials in X/Y
    return 1;
}

# --------------------------------------------------------------------------
# Mesh-returning solid primitives (all return { verts=>\@v, faces=>\@f })
# --------------------------------------------------------------------------

# Rectangular prism (box) mesh centred at (cx,cy,cz), dimensions w x h x d.
# Covers the cube as a special case (w == h == d).
sub prism ($self, $cx,$cy,$cz,$w,$h,$d) {
    my ($hw,$hh,$hd) = ($w/2.0, $h/2.0, $d/2.0);
    my @v = (
        [$cx-$hw, $cy-$hh, $cz-$hd],   # 0: left  bottom front
        [$cx+$hw, $cy-$hh, $cz-$hd],   # 1: right bottom front
        [$cx+$hw, $cy+$hh, $cz-$hd],   # 2: right top    front
        [$cx-$hw, $cy+$hh, $cz-$hd],   # 3: left  top    front
        [$cx-$hw, $cy-$hh, $cz+$hd],   # 4: left  bottom back
        [$cx+$hw, $cy-$hh, $cz+$hd],   # 5: right bottom back
        [$cx+$hw, $cy+$hh, $cz+$hd],   # 6: right top    back
        [$cx-$hw, $cy+$hh, $cz+$hd],   # 7: left  top    back
    );
    my @f = (
        [0,1,2],[0,2,3],   # front  (-z)
        [5,4,7],[5,7,6],   # back   (+z)
        [4,0,3],[4,3,7],   # left   (-x)
        [1,5,6],[1,6,2],   # right  (+x)
        [4,5,1],[4,1,0],   # bottom (-y)
        [3,2,6],[3,6,7],   # top    (+y)
    );
    return $self->mesh(\@v, \@f);
}

# UV-sphere tessellation mesh.  lat x lon quads, triangulated.
sub sphere ($self, $cx,$cy,$cz,$r,$lat=12,$lon=24) {
    my @verts;
    for my $i (0..$lat) {
        my $phi = $PI * $i / $lat;          # 0 .. pi
        for my $j (0..$lon-1) {
            my $theta = 2*$PI * $j / $lon;  # 0 .. 2*pi
            push @verts, [
                $cx + $r * sin($phi) * cos($theta),
                $cy + $r * sin($phi) * sin($theta),
                $cz + $r * cos($phi),
            ];
        }
    }
    my @faces;
    for my $i (0..$lat-1) {
        for my $j (0..$lon-1) {
            my $p0 = $i     * $lon + $j;
            my $p1 = ($i+1) * $lon + $j;
            my $p2 = $i     * $lon + ($j+1) % $lon;
            my $p3 = ($i+1) * $lon + ($j+1) % $lon;
            push @faces, [$p0,$p1,$p2] if $i != 0;
            push @faces, [$p2,$p1,$p3] if $i != $lat-1;
        }
    }
    return $self->mesh(\@verts, \@faces);
}

# Icosphere mesh.  Starts from a regular icosahedron and subdivides each
# triangle into four by midpoint bisection, then projects back onto the sphere.
# $subdivisions defaults to 2, giving 320 faces.
sub icosphere ($self, $cx,$cy,$cz,$r,$subdivisions=2) {
    my $phi = (1 + sqrt(5)) / 2;   # golden ratio

    # 12 icosahedron vertices (normalised to unit sphere)
    my @v = map {
        my $l = sqrt($_->[0]**2+$_->[1]**2+$_->[2]**2);
        [ map { $_/$l } @$_ ]
    } (
        [-1,  $phi, 0], [ 1,  $phi, 0], [-1, -$phi, 0], [ 1, -$phi, 0],
        [ 0, -1,  $phi], [ 0,  1,  $phi], [ 0, -1, -$phi], [ 0,  1, -$phi],
        [ $phi, 0, -1], [ $phi, 0,  1], [-$phi, 0, -1], [-$phi, 0,  1],
    );

    # 20 icosahedron faces
    my @f = (
        [0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
        [1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
        [3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
        [4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1],
    );

    # Midpoint cache: maps "$i,$j" => vertex index
    my %mid;
    my $midpoint = sub {
        my ($a,$b) = @_;
        my $key = $a < $b ? "$a,$b" : "$b,$a";
        unless (exists $mid{$key}) {
            my @m = map { ($v[$a][$_] + $v[$b][$_]) / 2 } 0..2;
            my $l = sqrt($m[0]**2+$m[1]**2+$m[2]**2) || 1;
            push @v, [map{$_/$l}@m];
            $mid{$key} = $#v;
        }
        return $mid{$key};
    };

    for (1..$subdivisions) {
        my @nf;
        for my $face (@f) {
            my ($a,$b,$c) = @$face;
            my $ab = $midpoint->($a,$b);
            my $bc = $midpoint->($b,$c);
            my $ca = $midpoint->($c,$a);
            push @nf, [$a,$ab,$ca], [$b,$bc,$ab], [$c,$ca,$bc], [$ab,$bc,$ca];
        }
        @f = @nf;
    }

    my @verts = map { [$cx+$r*$_->[0], $cy+$r*$_->[1], $cz+$r*$_->[2]] } @v;
    return $self->mesh(\@verts, \@f);
}

# Cylinder mesh.  $base_ref and $top_ref are [x,y,z] centre points.
# Side walls only (no end caps).
sub cylinder ($self, $base_ref, $top_ref, $r, $seg=24) {
    my ($bx,$by,$bz) = @$base_ref;
    my ($tx,$ty,$tz) = @$top_ref;
    my @verts;
    for my $i (0..$seg-1) {
        my $theta = 2*$PI*$i/$seg;
        push @verts, [$bx + $r*cos($theta), $by + $r*sin($theta), $bz];
    }
    for my $i (0..$seg-1) {
        my $theta = 2*$PI*$i/$seg;
        push @verts, [$tx + $r*cos($theta), $ty + $r*sin($theta), $tz];
    }
    my @faces;
    for my $i (0..$seg-1) {
        my $n = ($i+1) % $seg;
        push @faces, [$i, $seg+$i, $seg+$n];
        push @faces, [$i, $seg+$n, $n];
    }
    return $self->mesh(\@verts, \@faces);
}

# General frustum (truncated cone) mesh centred at (cx,cy,cz).
# $r_bot: bottom ring radius, $r_top: top ring radius, $height: total height.
# When $r_top == 0 this is a cone; when $r_bot == $r_top it is a cylinder.
# Both end caps are included in the mesh.
# Vertex layout:
#   [0..$seg-1]          : bottom ring
#   [$seg]               : bottom centre
#   [$seg+1..$seg*2]     : top ring
#   [$seg*2+1]           : top centre
sub frustum ($self, $cx,$cy,$cz,$r_bot,$r_top,$height,$seg=24) {
    my $hz = $height / 2.0;
    my @v;

    # Bottom ring
    for my $i (0..$seg-1) {
        my $t = 2*$PI*$i/$seg;
        push @v, [$cx + $r_bot*cos($t), $cy + $r_bot*sin($t), $cz - $hz];
    }
    my $bc = scalar @v;               # bottom centre index
    push @v, [$cx, $cy, $cz - $hz];

    # Top ring
    for my $i (0..$seg-1) {
        my $t = 2*$PI*$i/$seg;
        push @v, [$cx + $r_top*cos($t), $cy + $r_top*sin($t), $cz + $hz];
    }
    my $tc = scalar @v;               # top centre index
    push @v, [$cx, $cy, $cz + $hz];

    my @f;
    for my $i (0..$seg-1) {
        my $n = ($i+1) % $seg;
        my $ti = $seg + 1 + $i;   # top ring index for i
        my $tn = $seg + 1 + $n;   # top ring index for n
        # Side quad as two triangles
        push @f, [$i,  $ti, $tn];
        push @f, [$i,  $tn, $n ];
        # Bottom cap (fan, winding outward / facing -Z)
        push @f, [$bc, $n,  $i ];
        # Top cap (fan, winding outward / facing +Z)
        push @f, [$tc, $ti, $tn];
    }
    return $self->mesh(\@v, \@f);
}

# Cone mesh: convenience wrapper for frustum with $r_top = 0.
sub cone ($self, $cx,$cy,$cz,$r,$height,$seg=24) {
    return $self->frustum($cx,$cy,$cz,$r,0,$height,$seg);
}

# Capsule mesh: a cylinder capped with hemispherical ends.
# (cx,cy,cz) is the geometric centre.
# $height is the length of the cylindrical body (not counting the caps).
# $seg_r: longitudinal (radial) segments; $seg_h: latitudinal segments per hemisphere.
sub capsule ($self, $cx,$cy,$cz,$r,$height,$seg_r=16,$seg_h=8) {
    my $hz = $height / 2.0;
    my @v;
    my @f;

    # ------------------------------------------------------------------
    # Top hemisphere: phi from 0 (pole) to pi/2 (equator), body offset +hz
    # Ring layout: pole index 0, then seg_h rings of seg_r vertices each
    # ------------------------------------------------------------------
    push @v, [$cx, $cy, $cz + $hz + $r];   # top pole, index 0

    for my $i (1..$seg_h) {
        my $phi = ($PI / 2) * $i / $seg_h;  # 0 < phi <= pi/2
        for my $j (0..$seg_r-1) {
            my $theta = 2*$PI*$j/$seg_r;
            push @v, [
                $cx + $r * sin($phi) * cos($theta),
                $cy + $r * sin($phi) * sin($theta),
                $cz + $hz + $r * cos($phi),
            ];
        }
    }
    # top_equator_start: first vertex index of the equator ring (last top-hem ring)
    my $top_eq = 1 + ($seg_h-1)*$seg_r;

    # Pole fan
    for my $j (0..$seg_r-1) {
        my $n = ($j+1) % $seg_r;
        push @f, [0, 1+$j, 1+$n];
    }
    # Hemisphere bands
    for my $i (1..$seg_h-1) {
        my $ra = 1 + ($i-1)*$seg_r;
        my $rb = 1 +  $i   *$seg_r;
        for my $j (0..$seg_r-1) {
            my $n = ($j+1) % $seg_r;
            push @f, [$ra+$j, $rb+$j, $rb+$n];
            push @f, [$ra+$j, $rb+$n, $ra+$n];
        }
    }

    # ------------------------------------------------------------------
    # Cylinder body: equator-top to equator-bottom
    # ------------------------------------------------------------------
    my $bot_eq = scalar @v;   # start index of bottom equator ring
    for my $j (0..$seg_r-1) {
        my $theta = 2*$PI*$j/$seg_r;
        push @v, [
            $cx + $r * cos($theta),
            $cy + $r * sin($theta),
            $cz - $hz,
        ];
    }
    for my $j (0..$seg_r-1) {
        my $n = ($j+1) % $seg_r;
        push @f, [$top_eq+$j, $bot_eq+$j, $bot_eq+$n];
        push @f, [$top_eq+$j, $bot_eq+$n, $top_eq+$n];
    }

    # ------------------------------------------------------------------
    # Bottom hemisphere: phi from pi/2 (equator) to pi (pole), body offset -hz
    # seg_h-1 additional rings, then the pole
    # ------------------------------------------------------------------
    my $bot_hem_start = scalar @v;
    for my $i (1..$seg_h-1) {
        my $phi = ($PI/2) + ($PI/2) * $i / $seg_h;
        for my $j (0..$seg_r-1) {
            my $theta = 2*$PI*$j/$seg_r;
            push @v, [
                $cx + $r * sin($phi) * cos($theta),
                $cy + $r * sin($phi) * sin($theta),
                $cz - $hz + $r * cos($phi),
            ];
        }
    }
    push @v, [$cx, $cy, $cz - $hz - $r];   # bottom pole
    my $bot_pole = $#v;

    # Connect body bottom equator to first bottom-hemisphere ring (or directly to pole)
    if ($seg_h > 1) {
        my $ra = $bot_eq;
        my $rb = $bot_hem_start;
        for my $j (0..$seg_r-1) {
            my $n = ($j+1) % $seg_r;
            push @f, [$ra+$j, $rb+$j, $rb+$n];
            push @f, [$ra+$j, $rb+$n, $ra+$n];
        }
        for my $i (1..$seg_h-2) {
            my $ra = $bot_hem_start + ($i-1)*$seg_r;
            my $rb = $bot_hem_start +  $i   *$seg_r;
            for my $j (0..$seg_r-1) {
                my $n = ($j+1) % $seg_r;
                push @f, [$ra+$j, $rb+$j, $rb+$n];
                push @f, [$ra+$j, $rb+$n, $ra+$n];
            }
        }
        # Fan to bottom pole from last bottom-hemisphere ring
        my $last_ring = $bot_hem_start + ($seg_h-2)*$seg_r;
        for my $j (0..$seg_r-1) {
            my $n = ($j+1) % $seg_r;
            push @f, [$bot_pole, $last_ring+$n, $last_ring+$j];
        }
    } else {
        # Only one hemisphere ring (the equator itself) -- fan directly to pole
        for my $j (0..$seg_r-1) {
            my $n = ($j+1) % $seg_r;
            push @f, [$bot_pole, $bot_eq+$n, $bot_eq+$j];
        }
    }

    return $self->mesh(\@v, \@f);
}

# Flat rectangular plane mesh in the XY plane centred at (cx,cy,cz).
# $w / $h: width / height; $segs_w / $segs_h: subdivision counts.
sub plane ($self, $cx,$cy,$cz,$w,$h,$segs_w=1,$segs_h=1) {
    $segs_w >= 1 or $self->_croak('plane: segs_w must be >= 1');
    $segs_h >= 1 or $self->_croak('plane: segs_h must be >= 1');
    my ($hw,$hh) = ($w/2.0, $h/2.0);
    my @v;
    for my $j (0..$segs_h) {
        my $y = $cy - $hh + $h * $j / $segs_h;
        for my $i (0..$segs_w) {
            my $x = $cx - $hw + $w * $i / $segs_w;
            push @v, [$x, $y, $cz];
        }
    }
    my @f;
    my $stride = $segs_w + 1;
    for my $j (0..$segs_h-1) {
        for my $i (0..$segs_w-1) {
            my $tl = $j * $stride + $i;
            my $tr = $tl + 1;
            my $bl = $tl + $stride;
            my $br = $bl + 1;
            push @f, [$tl, $bl, $br];
            push @f, [$tl, $br, $tr];
        }
    }
    return $self->mesh(\@v, \@f);
}

# Torus mesh in the XY plane centred at (cx,cy,cz).
# $R: major radius (torus centre to tube centre).
# $r: minor radius (tube radius).
# $maj_seg / $min_seg: major / minor segment counts.
sub torus ($self, $cx,$cy,$cz,$R,$r,$maj_seg=24,$min_seg=12) {
    my @v;
    for my $i (0..$maj_seg-1) {
        my $theta = 2*$PI*$i/$maj_seg;
        for my $j (0..$min_seg-1) {
            my $phi = 2*$PI*$j/$min_seg;
            push @v, [
                $cx + ($R + $r*cos($phi)) * cos($theta),
                $cy + ($R + $r*cos($phi)) * sin($theta),
                $cz +  $r * sin($phi),
            ];
        }
    }
    my @f;
    for my $i (0..$maj_seg-1) {
        my $ni = ($i+1) % $maj_seg;
        for my $j (0..$min_seg-1) {
            my $nj = ($j+1) % $min_seg;
            my $a  = $i  *$min_seg + $j;
            my $b  = $i  *$min_seg + $nj;
            my $c  = $ni *$min_seg + $j;
            my $d  = $ni *$min_seg + $nj;
            push @f, [$a,$c,$d];
            push @f, [$a,$d,$b];
        }
    }
    return $self->mesh(\@v, \@f);
}

# Flat disk (filled circle) mesh in the XY plane centred at (cx,cy,cz).
# Vertex 0 is the centre; vertices 1..$seg are the rim.
sub disk ($self, $cx,$cy,$cz,$r,$seg=24) {
    my @v = ([$cx,$cy,$cz]);   # centre
    for my $i (0..$seg-1) {
        my $theta = 2*$PI*$i/$seg;
        push @v, [$cx + $r*cos($theta), $cy + $r*sin($theta), $cz];
    }
    my @f;
    for my $i (0..$seg-1) {
        my $n = ($i+1) % $seg;
        push @f, [0, $i+1, $n+1];
    }
    return $self->mesh(\@v, \@f);
}

# Regular polygon-base pyramid mesh.
# (cx,cy,cz): base centre; $r: circumradius of base; $height: height in +Z.
# $sides: number of base vertices (default 4 = square pyramid).
# Vertex layout: [0..$sides-1] base ring, [$sides] apex, [$sides+1] base centre.
sub pyramid ($self, $cx,$cy,$cz,$r,$height,$sides=4) {
    $sides >= 3 or $self->_croak('pyramid: sides must be >= 3');
    my @v;
    for my $i (0..$sides-1) {
        my $theta = 2*$PI*$i/$sides;
        push @v, [$cx + $r*cos($theta), $cy + $r*sin($theta), $cz];
    }
    my $apex   = scalar @v;  push @v, [$cx, $cy, $cz + $height];
    my $base_c = scalar @v;  push @v, [$cx, $cy, $cz];
    my @f;
    for my $i (0..$sides-1) {
        my $n = ($i+1) % $sides;
        push @f, [$i,    $n,      $apex  ];   # side face
        push @f, [$base_c, $n, $i        ];   # base fan (faces -Z)
    }
    return $self->mesh(\@v, \@f);
}

# ==========================================================================
# SECTION: Quaternions
# ==========================================================================

# Construct a unit quaternion [w,x,y,z] from axis + angle (degrees)
sub quat_from_axis_angle ($self, $axis_ref, $deg) {
    my ($ax,$ay,$az) = @$axis_ref;
    my $len = sqrt($ax*$ax + $ay*$ay + $az*$az);
    $self->_croak('quat_from_axis_angle: zero-length axis') if $len < $EPSILON;
    ($ax,$ay,$az) = ($ax/$len,$ay/$len,$az/$len);
    my $half = $deg * $D2R / 2.0;
    my $s = sin($half);
    return [ cos($half), $ax*$s, $ay*$s, $az*$s ];
}

# Convert quaternion to 4x4 rotation matrix
sub quat_to_matrix ($self, $q) {
    my ($w,$x,$y,$z) = @$q;
    return [
        [1-2*($y*$y+$z*$z),  2*($x*$y-$w*$z),   2*($x*$z+$w*$y),   0],
        [2*($x*$y+$w*$z),   1-2*($x*$x+$z*$z),  2*($y*$z-$w*$x),   0],
        [2*($x*$z-$w*$y),    2*($y*$z+$w*$x),   1-2*($x*$x+$y*$y), 0],
        [0,                  0,                  0,                  1],
    ];
}

# Spherical linear interpolation between two quaternions at parameter t (0 <= t <= 1)
sub quat_slerp ($self, $q1, $q2, $t) {
    my ($w1,$x1,$y1,$z1) = @$q1;
    my ($w2,$x2,$y2,$z2) = @$q2;
    my $dot = $w1*$w2 + $x1*$x2 + $y1*$y2 + $z1*$z2;
    if ($dot < 0) { ($w2,$x2,$y2,$z2) = (-$w2,-$x2,-$y2,-$z2); $dot = -$dot }
    if ($dot > 0.9995) {
        my @r = ($w1+$t*($w2-$w1), $x1+$t*($x2-$x1),
                 $y1+$t*($y2-$y1), $z1+$t*($z2-$z1));
        my $l = sqrt($r[0]**2+$r[1]**2+$r[2]**2+$r[3]**2) || 1;
        $_/=$l for @r;
        return \@r;
    }
    my $theta0 = acos($dot);
    my $theta   = $theta0 * $t;
    my $st0 = sin($theta0);
    my $s1  = cos($theta) - $dot * sin($theta) / $st0;
    my $s2  = sin($theta) / $st0;
    return [ $w1*$s1+$w2*$s2, $x1*$s1+$x2*$s2,
             $y1*$s1+$y2*$s2, $z1*$s1+$z2*$s2 ];
}

# ==========================================================================
# SECTION: Mesh utilities
# ==========================================================================

# Bounding box of a mesh or arrayref of points.
# Returns ([$minx,$miny,$minz], [$maxx,$maxy,$maxz])
sub bbox3 ($self, $arg) {
    my @pts = (ref $arg eq 'HASH' && $arg->{verts})
            ? @{ $arg->{verts} }
            : @$arg;
    my ($mnx,$mny,$mnz,$mxx,$mxy,$mxz) = (1e99,1e99,1e99,-1e99,-1e99,-1e99);
    for my $p (@pts) {
        $mnx=$p->[0] if $p->[0]<$mnx; $mxx=$p->[0] if $p->[0]>$mxx;
        $mny=$p->[1] if $p->[1]<$mny; $mxy=$p->[1] if $p->[1]>$mxy;
        $mnz=$p->[2] if $p->[2]<$mnz; $mxz=$p->[2] if $p->[2]>$mxz;
    }
    return ([$mnx,$mny,$mnz], [$mxx,$mxy,$mxz]);
}

# Compute face normals and averaged vertex normals; stores them in the mesh.
sub compute_normals ($self, $mesh) {
    my @v = @{ $mesh->{verts} };
    my @fn;
    my @vn = map { [0,0,0] } @v;
    my @vc = (0) x @v;
    for my $f (@{ $mesh->{faces} }) {
        my ($a,$b,$c) = @$f;
        my ($ux,$uy,$uz) = map { $v[$b][$_]-$v[$a][$_] } 0..2;
        my ($vx,$vy,$vz) = map { $v[$c][$_]-$v[$a][$_] } 0..2;
        my ($nx,$ny,$nz) = ($uy*$vz-$uz*$vy, $uz*$vx-$ux*$vz, $ux*$vy-$uy*$vx);
        my $l = sqrt($nx*$nx+$ny*$ny+$nz*$nz) || 1;
        push @fn, [$nx/$l,$ny/$l,$nz/$l];
        for my $i ($a,$b,$c) {
            $vn[$i][$_] += $fn[-1][$_] for 0..2;
            $vc[$i]++;
        }
    }
    for my $i (0..$#v) {
        next unless $vc[$i];
        my $l = sqrt($vn[$i][0]**2 + $vn[$i][1]**2 + $vn[$i][2]**2) || 1;
        $vn[$i] = [ map { $_/$l } @{$vn[$i]} ];
    }
    $mesh->{face_normals}   = \@fn;
    $mesh->{vertex_normals} = \@vn;
    return $mesh;
}

# ==========================================================================
# SECTION: Visibility -- back-face culling and z-buffer occlusion
# ==========================================================================

# Back-face culling.  Returns arrayref of visible face indices.
# Option view_dir: camera direction vector.  If omitted, uses the forward
# vector stored by set_camera(); falls back to [0,0,-1] if no camera is set.
sub backface_cull ($self, $mesh, %opts) {
    my $vd = $opts{view_dir}
          // ( $self->{_g3_camera} ? $self->{_g3_camera}{fwd} : [0,0,-1] );
    my @v  = @{ $mesh->{verts} };
    my @visible;
    for my $fi (0..$#{ $mesh->{faces} }) {
        my ($a,$b,$c) = @{ $mesh->{faces}[$fi] };
        my ($ux,$uy,$uz) = map { $v[$b][$_]-$v[$a][$_] } 0..2;
        my ($wx,$wy,$wz) = map { $v[$c][$_]-$v[$a][$_] } 0..2;
        my ($nx,$ny,$nz) = ($uy*$wz-$uz*$wy, $uz*$wx-$ux*$wz, $ux*$wy-$uy*$wx);
        my $dot = $nx*$vd->[0] + $ny*$vd->[1] + $nz*$vd->[2];
        push @visible, $fi if $dot < 0;
    }
    return \@visible;
}

# Z-buffer occlusion clip.
# Projects mesh through the current CTM3, rasterises into a $res x $res buffer,
# and returns an arrayref of visible edge segments [[p1,p2], ...] where each
# point is an arrayref [$x,$y] in projected (2-D) space.
# Option: res => N (default 256)
sub occlusion_clip ($self, $mesh, %opts) {
    my $res       = $opts{res}       // 256;
    my $occluders = $opts{occluders} // [];

    my @v = @{ $mesh->{verts} };
    my @f = @{ $mesh->{faces} };

    # Project target mesh vertices
    my (@proj, @zdepth);
    for my $p (@v) {
        my ($tx,$ty,$tz) = $self->transform_point($p);
        push @proj,   [$tx,$ty];
        push @zdepth, $tz;
    }

    # Project occluder vertices
    my (@oproj, @ozdepth, @of_all);
    for my $om (@$occluders) {
        my $base = scalar @oproj;
        for my $p (@{ $om->{verts} }) {
            my ($tx,$ty,$tz) = $self->transform_point($p);
            push @oproj,   [$tx,$ty];
            push @ozdepth, $tz;
        }
        for my $face (@{ $om->{faces} }) {
            push @of_all, [ map { $_ + $base } @$face ];
        }
    }

    # Bounding box from TARGET mesh only.
    # Anchoring to the target keeps all 256 pixels focused on the region that
    # matters. Occluder triangles that extend outside are still rasterised
    # within the grid because the per-triangle pixel loops clamp to [0, res-1].
    my ($mnx,$mny,$mxx,$mxy) = (1e99,1e99,-1e99,-1e99);
    for my $p (@proj) {
        $mnx=$p->[0] if $p->[0]<$mnx;  $mxx=$p->[0] if $p->[0]>$mxx;
        $mny=$p->[1] if $p->[1]<$mny;  $mxy=$p->[1] if $p->[1]>$mxy;
    }
    my $rngx = $mxx-$mnx || 1;
    my $rngy = $mxy-$mny || 1;
    my $sx = ($res-1) / $rngx;
    my $sy = ($res-1) / $rngy;

    my @zbuf = map { [(1e99) x $res] } 0..$res-1;

    # --- inner rasteriser: writes z to zbuf only ---
    my $rasterise = sub ($px_arr, $py_arr, $pz_arr) {
        my ($x1,$y1,$z1) = ($px_arr->[0],$py_arr->[0],$pz_arr->[0]);
        my ($x2,$y2,$z2) = ($px_arr->[1],$py_arr->[1],$pz_arr->[1]);
        my ($x3,$y3,$z3) = ($px_arr->[2],$py_arr->[2],$pz_arr->[2]);

        my $pxlo = POSIX::floor((($x1<$x2&&$x1<$x3?$x1:($x2<$x3?$x2:$x3))-$mnx)*$sx);
        my $pxhi = POSIX::ceil( (($x1>$x2&&$x1>$x3?$x1:($x2>$x3?$x2:$x3))-$mnx)*$sx);
        my $pylo = POSIX::floor((($y1<$y2&&$y1<$y3?$y1:($y2<$y3?$y2:$y3))-$mny)*$sy);
        my $pyhi = POSIX::ceil( (($y1>$y2&&$y1>$y3?$y1:($y2>$y3?$y2:$y3))-$mny)*$sy);
        $pxlo = 0       if $pxlo < 0;
        $pylo = 0       if $pylo < 0;
        $pxhi = $res-1  if $pxhi >= $res;
        $pyhi = $res-1  if $pyhi >= $res;

        for my $px ($pxlo..$pxhi) {
            for my $py ($pylo..$pyhi) {
                my $fx = $mnx + $px/$sx;
                my $fy = $mny + $py/$sy;
                my $den = ($y2-$y3)*($x1-$x3) + ($x3-$x2)*($y1-$y3);
                next if abs($den) < 1e-12;
                my $ba = (($y2-$y3)*($fx-$x3)+($x3-$x2)*($fy-$y3)) / $den;
                my $bb = (($y3-$y1)*($fx-$x3)+($x1-$x3)*($fy-$y3)) / $den;
                my $bc = 1 - $ba - $bb;
                next if $ba < -1e-6 || $bb < -1e-6 || $bc < -1e-6;
                my $z = $ba*$z1 + $bb*$z2 + $bc*$z3;
                $zbuf[$py][$px] = $z if $z < $zbuf[$py][$px];
            }
        }
    };

    # Pass 1: rasterise occluder triangles (depth only)
    for my $face (@of_all) {
        my ($i1,$i2,$i3) = @$face;
        $rasterise->(
            [$oproj[$i1][0], $oproj[$i2][0], $oproj[$i3][0]],
            [$oproj[$i1][1], $oproj[$i2][1], $oproj[$i3][1]],
            [$ozdepth[$i1],  $ozdepth[$i2],  $ozdepth[$i3]],
        );
    }

    # Pass 2: rasterise target triangles (depth only).
    # After this pass zbuf contains the minimum z at each pixel across both
    # occluders and the target surface itself.  The edge-midpoint test below
    # then uses this combined depth to decide visibility.
    for my $fi (0..$#f) {
        my ($i1,$i2,$i3) = @{$f[$fi]};
        $rasterise->(
            [$proj[$i1][0], $proj[$i2][0], $proj[$i3][0]],
            [$proj[$i1][1], $proj[$i2][1], $proj[$i3][1]],
            [$zdepth[$i1],  $zdepth[$i2],  $zdepth[$i3]],
        );
    }

    # --- Build edge list ---
    #
    # Old approach (WRONG for partially-occluded faces):
    #   mark faces vis=1 if any pixel wins zbuf, then emit all edges of vis faces.
    #
    # New approach: test each edge midpoint against the zbuffer.
    #   - After pass 2, zbuf holds the closest z at every pixel (occluder OR target).
    #   - An edge midpoint on the VISIBLE surface has z_mid ≈ zbuf[pixel] (the
    #     target face wrote that value in pass 2).
    #   - An edge midpoint BEHIND an occluder has z_mid > zbuf[pixel] (the
    #     occluder wrote a smaller value in pass 1 that pass 2 couldn't overwrite).
    #   The epsilon (1e-5) handles floating-point noise while staying well below
    #   the typical z-gap between adjacent objects (≥ 1e-4 in this library's scenes).

    # Compute face normals for coplanar diagonal suppression
    my %edge_tris;
    my @fnorm;
    for my $fi (0..$#f) {
        my ($i1,$i2,$i3) = @{$f[$fi]};
        my ($ux,$uy,$uz) = map { $v[$i2][$_]-$v[$i1][$_] } 0..2;
        my ($wx,$wy,$wz) = map { $v[$i3][$_]-$v[$i1][$_] } 0..2;
        my ($nx,$ny,$nz) = ($uy*$wz-$uz*$wy, $uz*$wx-$ux*$wz, $ux*$wy-$uy*$wx);
        my $nl = sqrt($nx*$nx+$ny*$ny+$nz*$nz) || 1;
        $fnorm[$fi] = [$nx/$nl, $ny/$nl, $nz/$nl];
        for my $edge ([$i1,$i2],[$i2,$i3],[$i3,$i1]) {
            my $key = $edge->[0] < $edge->[1]
                ? "$edge->[0],$edge->[1]" : "$edge->[1],$edge->[0]";
            push @{ $edge_tris{$key} }, $fi;
        }
    }

    my %suppress;
    for my $key (keys %edge_tris) {
        my @tris = @{ $edge_tris{$key} };
        next unless @tris == 2;
        my ($na,$nb) = ($fnorm[$tris[0]], $fnorm[$tris[1]]);
        my $dot = $na->[0]*$nb->[0] + $na->[1]*$nb->[1] + $na->[2]*$nb->[2];
        $suppress{$key} = 1 if abs($dot) > 0.9999;
    }

    my %drawn;
    my @polylines;
    for my $fi (0..$#f) {
        my ($i1,$i2,$i3) = @{$f[$fi]};
        for my $edge ([$i1,$i2],[$i2,$i3],[$i3,$i1]) {
            my ($a,$b) = @$edge;
            my $key = $a < $b ? "$a,$b" : "$b,$a";
            next if $suppress{$key};
            next if $drawn{$key}++;

            # Test edge midpoint visibility against the combined zbuffer
            my $mx = ($proj[$a][0] + $proj[$b][0]) * 0.5;
            my $my = ($proj[$a][1] + $proj[$b][1]) * 0.5;
            my $mz = ($zdepth[$a]  + $zdepth[$b])  * 0.5;
            my $px = POSIX::floor(($mx - $mnx) * $sx + 0.5);
            my $py = POSIX::floor(($my - $mny) * $sy + 0.5);
            $px = 0       if $px < 0;
            $px = $res-1  if $px >= $res;
            $py = 0       if $py < 0;
            $py = $res-1  if $py >= $res;
            next if $mz > $zbuf[$py][$px] + 1e-5;

            push @polylines, [ [@{$proj[$a]}], [@{$proj[$b]}] ];
        }
    }
    return \@polylines;
}


# High-level hidden-line removal: backface cull, then z-buffer occlusion clip.
# Accepts occluders => \@meshes to populate the z-buffer from other objects.
sub hidden_line_remove ($self, $mesh, %opts) {
    my $culled = $self->backface_cull($mesh, %opts);
    my $visible_mesh = $self->mesh(
        $mesh->{verts},
        [ @{$mesh->{faces}}[@$culled] ],
    );
    # occluders option flows through to occlusion_clip
    return $self->occlusion_clip($visible_mesh, %opts);
}


# ==========================================================================
# SECTION: Projection to 2-D plotter output
# ==========================================================================

# Flatten a mesh or arrayref-of-polylines to 2-D edge segments via transform_point.
# Returns arrayref of [[x1,y1],[x2,y2]] segments.
sub flatten_to_2d ($self, $geometry, %opts) {
    my @segs;
    if (ref $geometry eq 'HASH' && $geometry->{verts}) {
        my @v = @{ $geometry->{verts} };
        my %drawn;
        for my $face (@{ $geometry->{faces} }) {
            my @idx = @$face;
            for my $ei (0..$#idx) {
                my ($a,$b) = ($idx[$ei], $idx[($ei+1)%@idx]);
                my $key = $a<$b ? "$a,$b" : "$b,$a";
                next if $drawn{$key}++;
                my ($x1,$y1) = ($self->transform_point($v[$a]))[0,1];
                my ($x2,$y2) = ($self->transform_point($v[$b]))[0,1];
                push @segs, [[$x1,$y1],[$x2,$y2]];
            }
        }
    } elsif (ref $geometry eq 'ARRAY') {
        @segs = @$geometry;
    }
    return \@segs;
}

# Draw an arrayref of [[p1,p2],...] edge segments via the host's 2-D pen hooks
sub draw_polylines ($self, $polylines_ref) {
    for my $seg (@$polylines_ref) {
        my ($p1,$p2) = @$seg;
        $self->penup();
        $self->_genfastmove($p1->[0], $p1->[1]);
        $self->pendown();
        $self->_genslowmove($p2->[0], $p2->[1]);
    }
    $self->stroke();
    return 1;
}

# ==========================================================================
# SECTION: SVG projection output
# ==========================================================================

sub project_to_svg ($self, $obj, %opts) {
    my $polylines;
    if (ref $obj eq 'HASH' && $obj->{verts}) {
        $polylines = $self->occlusion_clip($obj, %opts);
    } else {
        $polylines = $obj;
    }
    my ($mnx,$mny,$mxx,$mxy) = (1e99,1e99,-1e99,-1e99);
    for my $seg (@$polylines) {
        for my $p (@$seg) {
            $mnx=$p->[0] if $p->[0]<$mnx; $mxx=$p->[0] if $p->[0]>$mxx;
            $mny=$p->[1] if $p->[1]<$mny; $mxy=$p->[1] if $p->[1]>$mxy;
        }
    }
    $mnx=$mny=0 unless $mnx<$mxx;
    $mxx=$mxy=100 unless $mny<$mxy;
    my $svg = sprintf(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"%.4f %.4f %.4f %.4f\">\n",
        $mnx, $mny, $mxx-$mnx, $mxy-$mny
    );
    for my $seg (@$polylines) {
        my ($x1,$y1) = @{$seg->[0]};
        my ($x2,$y2) = @{$seg->[1]};
        $svg .= sprintf(
            "<line x1=\"%.4f\" y1=\"%.4f\" x2=\"%.4f\" y2=\"%.4f\" "
           ."stroke=\"black\" stroke-width=\"0.5\"/>\n",
            $x1,$y1,$x2,$y2
        );
    }
    $svg .= "</svg>\n";
    return $svg;
}

# ==========================================================================
# SECTION: Mesh I/O -- OBJ
# ==========================================================================

sub mesh_to_obj ($self, $mesh, $name='object') {
    my $out = "# Generated by Graphics::Penplotter::GcodeXY::Geometry3D\n";
    $out .= "o $name\n";
    for my $v (@{ $mesh->{verts} }) {
        $out .= sprintf("v %.6f %.6f %.6f\n", @$v);
    }
    for my $f (@{ $mesh->{faces} }) {
        $out .= sprintf("f %d %d %d\n", $f->[0]+1, $f->[1]+1, $f->[2]+1);
    }
    return $out;
}

sub mesh_from_obj ($self, $str) {
    my (@verts, @faces);
    for my $line (split /\n/, $str) {
        $line =~ s/^\s+//;
        if ($line =~ /^v\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)/) {
            push @verts, [$1+0, $2+0, $3+0];
        }
        elsif ($line =~ /^f\s+(\S+)\s+(\S+)\s+(\S+)/) {
            my @idx = map { (split m{/}, $_)[0] - 1 } ($1,$2,$3);
            push @faces, \@idx;
        }
    }
    return $self->mesh(\@verts, \@faces);
}

# ==========================================================================
# SECTION: Mesh I/O -- STL (ASCII)
# ==========================================================================

sub mesh_to_stl ($self, $mesh, $name='solid') {
    my $out = "solid $name\n";
    my @v   = @{ $mesh->{verts} };
    for my $f (@{ $mesh->{faces} }) {
        my ($a,$b,$c) = @$f;
        my ($ux,$uy,$uz) = map { $v[$b][$_]-$v[$a][$_] } 0..2;
        my ($wx,$wy,$wz) = map { $v[$c][$_]-$v[$a][$_] } 0..2;
        my ($nx,$ny,$nz) = ($uy*$wz-$uz*$wy, $uz*$wx-$ux*$wz, $ux*$wy-$uy*$wx);
        my $l = sqrt($nx*$nx+$ny*$ny+$nz*$nz) || 1;
        $out .= sprintf("  facet normal %.6f %.6f %.6f\n", $nx/$l,$ny/$l,$nz/$l);
        $out .= "    outer loop\n";
        $out .= sprintf("      vertex %.6f %.6f %.6f\n", @{$v[$a]});
        $out .= sprintf("      vertex %.6f %.6f %.6f\n", @{$v[$b]});
        $out .= sprintf("      vertex %.6f %.6f %.6f\n", @{$v[$c]});
        $out .= "    endloop\n  endfacet\n";
    }
    $out .= "endsolid $name\n";
    return $out;
}

sub mesh_from_stl ($self, $str) {
    my (@verts, @faces, %seen, @pending);
    my $vi = sub {
        my ($x,$y,$z) = @_;
        my $key = sprintf("%.9f,%.9f,%.9f", $x,$y,$z);
        unless (exists $seen{$key}) {
            $seen{$key} = scalar @verts;
            push @verts, [$x,$y,$z];
        }
        return $seen{$key};
    };
    for my $line (split /\n/, $str) {
        $line =~ s/^\s+//;
        if ($line =~ /^vertex\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)/) {
            push @pending, $vi->($1+0,$2+0,$3+0);
            if (@pending == 3) { push @faces, [@pending]; @pending = () }
        }
    }
    return $self->mesh(\@verts, \@faces);
}

# ==========================================================================
# SECTION: Numeric configuration
# ==========================================================================

sub set_tolerance ($self, $eps) {
    $eps > 0 or $self->_croak('set_tolerance: eps must be positive');
    $self->{_g3_tolerance} = $eps;
    return 1;
}

sub get_tolerance ($self) {
    return $self->{_g3_tolerance} // $EPSILON;
}

sub set_units ($self, $units) {
    $self->{_g3_units} = $units;
    return 1;
}

sub set_coordinate_convention ($self, %opts) {
    $self->{_g3_handedness}  = $opts{handedness}  if defined $opts{handedness};
    $self->{_g3_euler_order} = $opts{euler_order} if defined $opts{euler_order};
    return 1;
}

# ==========================================================================
# SECTION: Camera
# ==========================================================================

# Set the camera using a gluLookAt-style interface.
#
# Named arguments:
#   eye    => [$ex,$ey,$ez]   Camera (eye) position in world space.  Default [0,0,1].
#   center => [$cx,$cy,$cz]   Point the camera looks at.            Default [0,0,0].
#   up     => [$ux,$uy,$uz]   World-space up hint vector.            Default [0,1,0].
#
# The method computes an orthonormal right-handed camera basis
# (right, up, -forward) and stores:
#   _g3_camera->{eye}     the eye position
#   _g3_camera->{center}  the look-at point
#   _g3_camera->{up}      the recomputed, orthogonalised up vector
#   _g3_camera->{fwd}     the unit forward vector (from eye toward center)
#   _g3_camera->{view}    the 4x4 world-to-camera view matrix
#
# After calling set_camera() you can optionally call camera_to_ctm() to
# bake the view matrix into the 3-D CTM so that transform_point() and all
# drawing calls automatically include the camera transform.
#
# backface_cull() automatically picks up the stored forward vector when no
# explicit view_dir option is supplied.

sub set_camera ($self, %args) {
    my $eye    = $args{eye}    // [0, 0, 1];
    my $center = $args{center} // [0, 0, 0];
    my $up     = $args{up}     // [0, 1, 0];

    ref $eye    eq 'ARRAY' && @$eye    == 3
        or $self->_croak('set_camera: eye must be an arrayref [x,y,z]');
    ref $center eq 'ARRAY' && @$center == 3
        or $self->_croak('set_camera: center must be an arrayref [x,y,z]');
    ref $up     eq 'ARRAY' && @$up     == 3
        or $self->_croak('set_camera: up must be an arrayref [x,y,z]');

    # Forward vector: eye -> center
    my ($fx,$fy,$fz) = map { $center->[$_] - $eye->[$_] } 0..2;
    my $fl = sqrt($fx*$fx + $fy*$fy + $fz*$fz);
    $self->_croak('set_camera: eye and center cannot be the same point') if $fl < $EPSILON;
    ($fx,$fy,$fz) = ($fx/$fl, $fy/$fl, $fz/$fl);

    # Right vector: forward × up
    my ($ux,$uy,$uz) = @$up;
    my ($rx,$ry,$rz) = (
        $fy*$uz - $fz*$uy,
        $fz*$ux - $fx*$uz,
        $fx*$uy - $fy*$ux,
    );
    my $rl = sqrt($rx*$rx + $ry*$ry + $rz*$rz);
    $self->_croak('set_camera: up vector is parallel to the view direction') if $rl < $EPSILON;
    ($rx,$ry,$rz) = ($rx/$rl, $ry/$rl, $rz/$rl);

    # Recompute orthogonal up: right × forward
    ($ux,$uy,$uz) = (
        $ry*$fz - $rz*$fy,
        $rz*$fx - $rx*$fz,
        $rx*$fy - $ry*$fx,
    );

    # World-to-camera view matrix (row-major, same convention as the rest of the role).
    # Column layout: [right | up | -forward | translation]
    my $tx = -($rx*$eye->[0] + $ry*$eye->[1] + $rz*$eye->[2]);
    my $ty = -($ux*$eye->[0] + $uy*$eye->[1] + $uz*$eye->[2]);
    my $tz =   $fx*$eye->[0] + $fy*$eye->[1]  + $fz*$eye->[2];   # +fwd row
    my $view = [
        [ $rx,  $ry,  $rz,  $tx ],
        [ $ux,  $uy,  $uz,  $ty ],
        [-$fx, -$fy, -$fz,  $tz ],
        [  0,    0,    0,    1  ],
    ];

    $self->{_g3_camera} = {
        eye    => [ @$eye    ],
        center => [ @$center ],
        up     => [ $ux, $uy, $uz ],
        fwd    => [ $fx, $fy, $fz ],
        view   => $view,
    };
    return 1;
}

# Return the camera record set by set_camera(), or undef if none has been set.
sub get_camera ($self) {
    return $self->{_g3_camera};
}

# Bake the stored view matrix into the 3-D CTM by pre-multiplying.
# After this call transform_point() automatically includes the camera transform.
# Typically called once after set_camera() and before any drawing commands.
sub camera_to_ctm ($self) {
    my $cam = $self->{_g3_camera}
        or $self->_croak('camera_to_ctm: no camera set; call set_camera() first');
    $self->_g3_premul4($cam->{view}, _g3_ctm($self));
    return 1;
}


# ==========================================================================
# SECTION: Perspective projection
# ==========================================================================
#
# A perspective projection matrix introduces a 1/z foreshortening term.
# When pre-multiplied into the CTM via perspective_to_ctm(), transform_point()
# computes the homogeneous weight tw = -z (for objects in front of a camera
# looking down -Z), and the existing perspective divide (tw != 0,1 branch)
# produces correct perspective-foreshortened x and y coordinates.
#
# Typical workflow:
#   $g->initmatrix3();
#   $g->set_camera(eye => [5,5,10], center => [0,0,0]);
#   $g->camera_to_ctm();           # bake view matrix
#   $g->set_perspective(fov => 45, aspect => 1.0, near => 0.1, far => 100);
#   $g->perspective_to_ctm();      # bake projection matrix (P x V x CTM)
#   # ... drawing calls now include full perspective ...

# Build and store a symmetric perspective projection matrix (gluPerspective
# style).  Does NOT modify the CTM; call perspective_to_ctm() to apply it.
#
# Named arguments:
#   fov    => degrees   Vertical field of view (default 45).
#   aspect => ratio     Width / height ratio   (default 1.0).
#   near   => distance  Near clip distance, > 0 (default 0.1).
#   far    => distance  Far  clip distance, > near (default 100).
#
# The resulting 4x4 matrix (row-major, column-vector convention) is:
#
#   [ f/aspect   0      0                        0                    ]
#   [ 0          f      0                        0                    ]
#   [ 0          0   (far+near)/(near-far)   2*far*near/(near-far)    ]
#   [ 0          0     -1                        0                    ]
#
# where f = cot(fov/2).  Row 3 sets tw = -z, triggering the perspective
# divide in transform_point() for every drawn point.

sub set_perspective ($self, %args) {
    my $fov    = $args{fov}    // 45.0;
    my $aspect = $args{aspect} // 1.0;
    my $near   = $args{near}   // 0.1;
    my $far    = $args{far}    // 100.0;

    $self->_croak('set_perspective: fov must be > 0 and < 180')
        unless $fov > 0 && $fov < 180;
    $self->_croak('set_perspective: aspect must be > 0')
        unless $aspect > 0;
    $self->_croak('set_perspective: near must be > 0')
        unless $near > 0;
    $self->_croak('set_perspective: far must be > near')
        unless $far > $near;

    my $f  = 1.0 / tan( $fov * $D2R / 2.0 );
    my $nf = 1.0 / ($near - $far);

    $self->{_g3_projection} = [
        [ $f/$aspect, 0,   0,                      0                    ],
        [ 0,          $f,  0,                      0                    ],
        [ 0,          0,  ($far+$near)*$nf,        2*$far*$near*$nf     ],
        [ 0,          0,  -1,                      0                    ],
    ];
    return 1;
}

# Build and store an asymmetric (off-axis) perspective projection matrix
# (glFrustum style).  Does NOT modify the CTM; call perspective_to_ctm()
# to apply it.
#
# Named arguments:
#   left   => x coordinate of the left   clipping plane at near distance
#   right  => x coordinate of the right  clipping plane at near distance
#   bottom => y coordinate of the bottom clipping plane at near distance
#   top    => y coordinate of the top    clipping plane at near distance
#   near   => near clip distance (> 0)
#   far    => far  clip distance (> near)
#
# Useful for stereo rendering, anamorphic projections, or any off-centre
# viewport.  The symmetric case (left=-right, bottom=-top) is equivalent to
# set_perspective() with the corresponding fov and aspect ratio.

sub set_frustum ($self, %args) {
    my $left   = $args{left};
    my $right  = $args{right};
    my $bottom = $args{bottom};
    my $top    = $args{top};
    my $near   = $args{near} // 0.1;
    my $far    = $args{far}  // 100.0;

    for my $name (qw(left right bottom top)) {
        $self->_croak("set_frustum: '$name' is required")
            unless defined $args{$name};
    }
    $self->_croak('set_frustum: near must be > 0')          unless $near > 0;
    $self->_croak('set_frustum: far must be > near')        unless $far > $near;
    $self->_croak('set_frustum: left must not equal right') unless $right != $left;
    $self->_croak('set_frustum: bottom must not equal top') unless $top   != $bottom;

    my $rl = 1.0 / ($right - $left);
    my $tb = 1.0 / ($top   - $bottom);
    my $nf = 1.0 / ($near  - $far);
    my $n2 = 2.0 * $near;

    $self->{_g3_projection} = [
        [ $n2*$rl,  0,        ($right+$left)*$rl,    0                ],
        [ 0,        $n2*$tb,  ($top+$bottom)*$tb,    0                ],
        [ 0,        0,        ($far+$near)*$nf,   2*$far*$near*$nf    ],
        [ 0,        0,       -1,                    0                 ],
    ];
    return 1;
}

# Pre-multiply the stored projection matrix into the 3-D CTM (CTM := P x CTM).
# After this call transform_point() applies the full camera + projection
# pipeline to every point.  Croaks if set_perspective() or set_frustum()
# has not been called first.

sub perspective_to_ctm ($self) {
    my $proj = $self->{_g3_projection}
        or $self->_croak(
            'perspective_to_ctm: no projection set; '
          . 'call set_perspective() or set_frustum() first'
        );
    $self->_g3_premul4($proj, _g3_ctm($self));
    return 1;
}

# Return the stored projection matrix, or undef if none has been set.

sub get_projection ($self) {
    return $self->{_g3_projection};
}

1;

__END__

=encoding ASCII

=head1 NAME

Graphics::Penplotter::GcodeXY::Geometry3D - Role::Tiny role adding 3-D geometry to GcodeXY

=head1 VERSION

v0.4.0

=head1 SYNOPSIS

    $g->gsave();                              # saves both 2-D and 3-D state
    $g->initmatrix3();                        # reset 3-D CTM
    $g->translate3(50, 50, 0);               # move 3-D origin
    $g->rotate3(axis => [0,0,1], deg => 45); # spin around Z
    $g->scale3(10);                           # uniform scale

    my $m = $g->sphere(0, 0, 0, 1, 12, 24); # UV sphere mesh
    my $s = $g->flatten_to_2d($m);           # project to 2-D edge list
    $g->draw_polylines($s);                  # draw via host pen hooks

    $g->grestore();
    $g->output('myplot.gcode');

=head1 DESCRIPTION

This L<Role::Tiny> role grafts a full 3-D geometry pipeline onto
L<Graphics::Penplotter::GcodeXY>.  It is careful not to shadow any of the
host class's own methods:

=over 4

=item *

B<C<gsave>/C<grestore>> are extended via C<after> modifiers so the 3-D
Current Transformation Matrix (CTM3) stack stays in sync with the host's
2-D stack without overriding anything.

=item *

All 3-D variants of 2-D methods that would otherwise conflict are renamed
with a C<3> suffix: C<translate3>, C<scale3>, C<rotate3>, C<moveto3>,
C<line3>, C<lineR3>, C<initmatrix3>, C<translateC3>, C<currentpoint3>.

=item *

All 3-D private state lives in C<$self-E<gt>{_g3_*}> hash slots.

=back

The coordinate system is right-handed (+Z out of the screen) and the
internal representation uses 4x4 homogeneous matrices in row-major order.

=head1 REQUIRED METHODS

The consuming class must provide:

    penup  pendown  _genfastmove  _genslowmove  stroke  _croak  gsave  grestore

=head1 METHODS

=head2 CTM and transforms

=over 4

=item C<initmatrix3()>

Reset the 3-D CTM to identity.

=item C<translate3($tx, $ty [, $tz])>

Pre-multiply the 3-D CTM by a translation.

=item C<translateC3()>

Move the 3-D origin to the current 3-D position, then reset the position
to (0,0,0).

=item C<scale3($sx [, $sy [, $sz]])>

Pre-multiply by a scale matrix.  If C<$sy>/C<$sz> are omitted they default
to C<$sx> (uniform scale).

=item C<rotate3(axis =E<gt> [$ax,$ay,$az], deg =E<gt> $angle)>

Pre-multiply by a rotation around an arbitrary axis.

=item C<rotate3_euler($rx, $ry, $rz [, $order])>

Pre-multiply by a sequence of axis-aligned rotations.  C<$order> is a
three-character string such as C<'XYZ'> (default).

=item C<compose_matrix($aref, $bref)>

Multiply two 4x4 matrices; returns a new matrix ref.  Neither input is
modified.

=item C<invert_matrix($mref)>

Invert a 4x4 matrix (Gauss-Jordan with partial pivoting).  Returns a matrix
ref, or C<undef> if the matrix is singular.

=back

=head2 3-D current point

=over 4

=item C<currentpoint3()>

Return the current 3-D position as a list C<($x, $y, $z)>.

=item C<currentpoint3($x, $y, $z)>

Set the current 3-D position.

=back

=head2 Point transformation

=over 4

=item C<transform_point($pt_ref)>

Transform a point (arrayref C<[$x,$y,$z]>) through the current CTM3.
Returns C<($tx, $ty, $tz)>.

=item C<transform_points($pts_ref)>

Transform an arrayref of points; returns an arrayref of C<[$tx,$ty,$tz]>.

=back

=head2 3-D drawing primitives

=over 4

=item C<moveto3($x, $y [, $z])>

Lift the pen, fast-move to the projected 2-D position, lower pen.

=item C<movetoR3($dx, $dy [, $dz])>

Relative C<moveto3> from the current 3-D position.

=item C<line3($x1,$y1,$z1 [, $x2,$y2,$z2])>

Six-arg form: move to start, draw to end.
Three-arg form: draw from the current position.

=item C<lineR3($dx, $dy [, $dz])>

Relative line from the current 3-D position.

=item C<polygon3(x1,y1,z1, ...)>

Move to the first triple, draw through the remaining triples.

=item C<polygon3C(x1,y1,z1, ...)>

Like C<polygon3> but automatically closes back to the first point.

=item C<polygon3R(dx1,dy1,dz1, ...)>

Like C<polygon3> but each triple is relative to the preceding point.

=back

=head2 Wireframe solid drawing (draw directly, no mesh returned)

=over 4

=item C<box3($x1,$y1,$z1, $x2,$y2,$z2)>

Draw a wireframe axis-aligned box between two opposite corners.

=item C<cube($cx,$cy,$cz,$side)>

Draw a wireframe cube centred at C<(cx,cy,cz)>.

=item C<axis_gizmo($cx,$cy,$cz [, $len [, $cone_r [, $cone_h]]])>

Draw three labelled axis arrows (X, Y, Z) as wireframe lines with small
arrow cones.  C<$len> is the total axis length (default 1).  The cone
radius and height default to 5% and 15% of C<$len> respectively.

=back

=head2 Mesh-returning solid primitives

All of the following return a mesh structure
C<{ verts =E<gt> \@v, faces =E<gt> \@f }> which can be passed to
C<flatten_to_2d>, C<hidden_line_remove>, C<mesh_to_obj>, etc.

=over 4

=item C<mesh($verts_ref, $faces_ref)>

Low-level constructor.  Build a mesh from existing arrays.

=item C<prism($cx,$cy,$cz, $w,$h,$d)>

Axis-aligned rectangular prism (box) centred at C<(cx,cy,cz)>, with
dimensions C<w> (X), C<h> (Y), C<d> (Z).  A cube is C<prism> with
C<w == h == d>.  Returns a closed 12-face triangulated mesh.

=item C<sphere($cx,$cy,$cz, $r [, $lat [, $lon]])>

UV-sphere mesh.  C<$lat> and C<$lon> control the tessellation density
(defaults 12 and 24).

=item C<icosphere($cx,$cy,$cz, $r [, $subdivisions])>

Icosphere mesh built by repeated midpoint subdivision of a regular
icosahedron.  C<$subdivisions> defaults to 2 (320 faces).  Produces a more
uniform tessellation than C<sphere>.

=item C<cylinder($base_ref, $top_ref, $r [, $seg])>

Cylinder mesh.  C<$base_ref> and C<$top_ref> are C<[$x,$y,$z]> centre
points.  Side walls only; no end caps.

=item C<frustum($cx,$cy,$cz, $r_bot,$r_top,$height [, $seg])>

General truncated cone (frustum) centred at C<(cx,cy,cz)>.  Both end caps
are included.  When C<$r_top == 0> this is a cone; when
C<$r_bot == $r_top> it is a closed cylinder.

=item C<cone($cx,$cy,$cz, $r,$height [, $seg])>

Convenience wrapper: C<frustum> with C<r_top = 0>.

=item C<capsule($cx,$cy,$cz, $r,$height [, $seg_r [, $seg_h]])>

Cylinder with hemispherical end caps.  C<$height> is the length of the
cylindrical body (not counting the caps).  C<$seg_r> is the number of
radial segments (default 16); C<$seg_h> is the number of latitudinal
segments per hemisphere (default 8).

=item C<plane($cx,$cy,$cz, $w,$h [, $segs_w [, $segs_h]])>

Flat rectangular mesh in the XY plane, centred at C<(cx,cy,cz)>.
Dimensions C<$w> x C<$h>; subdivided into C<$segs_w> x C<$segs_h> quads.
Useful for floors, billboards, and UI surfaces.

=item C<torus($cx,$cy,$cz, $R,$r [, $maj_seg [, $min_seg]])>

Torus mesh in the XY plane.  C<$R> is the major radius (centre of tube to
centre of torus); C<$r> is the minor radius (tube radius).  Defaults:
24 major segments, 12 minor segments.

=item C<disk($cx,$cy,$cz, $r [, $seg])>

Flat circular disk mesh in the XY plane.  Fan-triangulated from the centre.
Vertex 0 is the centre; vertices C<1..$seg> are the rim.

=item C<pyramid($cx,$cy,$cz, $r,$height [, $sides])>

Regular-polygon-base pyramid.  C<(cx,cy,cz)> is the base centre; C<$r> is
the base circumradius; C<$height> is the height in +Z.  C<$sides> defaults
to 4 (square pyramid).  The base cap is included.

=back

=head2 Quaternions

=over 4

=item C<quat_from_axis_angle($axis_ref, $deg)>

Return a unit quaternion C<[$w,$x,$y,$z]>.

=item C<quat_to_matrix($q)>

Convert a quaternion to a 4x4 rotation matrix.

=item C<quat_slerp($q1, $q2, $t)>

Spherical linear interpolation (0 <= t <= 1).

=back

=head2 Mesh utilities

=over 4

=item C<bbox3($mesh_or_pts)>

Returns C<([$minx,$miny,$minz], [$maxx,$maxy,$maxz])>.

=item C<compute_normals($mesh)>

Compute face and averaged vertex normals in-place; returns C<$mesh>.

=back

=head2 Visibility

=over 4

=item C<backface_cull($mesh [, view_dir =E<gt> \@dir])>

Return an arrayref of the indices (into C<$mesh-E<gt>{faces}>) of faces whose
outward normal has a negative dot product with the view direction, i.e. faces
that are pointing toward the camera and therefore visible.

The view direction defaults, in order of preference, to:

=over 4

=item 1.

The C<fwd> vector stored by the most recent C<set_camera()> call, if one has
been made.

=item 2.

C<[0, 0, -1]> (looking along the negative Z axis) if no camera has been set.

=back

Pass C<view_dir =E<gt> \@v> to override both defaults with an explicit unit
vector pointing I<from> the scene I<toward> the camera.

=item C<occlusion_clip($mesh [, res =E<gt> N])>

Z-buffer rasterisation; returns arrayref of C<[[p1,p2],...]> edge segments.

=item C<hidden_line_remove($mesh [, %opts])>

Back-face cull then occlusion clip; returns edge segments.

=back

=head2 2-D output

=over 4

=item C<flatten_to_2d($mesh_or_polylines)>

Project mesh edges or pass-through polylines; returns C<[[$p1,$p2],...]>.

=item C<draw_polylines($segs_ref)>

Emit segments via the host's pen hooks; calls C<stroke()> at the end.

=item C<project_to_svg($obj [, %opts])>

Return an SVG string of the projected edges.

=back

=head2 Mesh I/O

=over 4

=item C<mesh_to_obj($mesh [, $name])>

Serialise to ASCII OBJ string.

=item C<mesh_from_obj($str)>

Parse an ASCII OBJ string; returns a mesh.

=item C<mesh_to_stl($mesh [, $name])>

Serialise to ASCII STL string.

=item C<mesh_from_stl($str)>

Parse an ASCII STL string; returns a mesh (vertices are de-duplicated).

=back

=head2 Camera

The three camera methods together provide a gluLookAt-style workflow for
positioning the viewer in 3-D space.  Typical usage:

    $g->set_camera(
        eye    => [5, 5, 10],   # camera position in world space
        center => [0, 0,  0],   # point to look at
        up     => [0, 1,  0],   # world up hint
    );
    $g->camera_to_ctm();        # bake view matrix into the 3-D CTM

    my $m = $g->sphere(0, 0, 0, 1);
    my $v = $g->backface_cull($m);          # uses stored fwd automatically
    $g->draw_polylines($g->flatten_to_2d(
        { verts => $m->{verts},
          faces => [ @{$m->{faces}}[@$v] ] }
    ));

Camera state is saved and restored by C<gsave()> / C<grestore()> alongside
the 3-D CTM and current point.

=over 4

=item C<set_camera(eye =E<gt> \@e, center =E<gt> \@c [, up =E<gt> \@u])>

Position the camera using a gluLookAt-style interface.

B<C<eye>> (required) is an arrayref C<[$ex,$ey,$ez]> giving the camera
position in world space.

B<C<center>> (required) is an arrayref C<[$cx,$cy,$cz]> giving the point in
world space the camera looks at.  Must differ from C<eye>; croaks with
C<"same point"> otherwise.

B<C<up>> (optional, default C<[0,1,0]>) is an arrayref C<[$ux,$uy,$uz]>
giving a world-space hint for the upward direction.  Must not be parallel to
the view direction (C<center - eye>); croaks with C<"parallel"> if it is.

The method builds an orthonormal right-handed camera basis:

    forward  =  normalise(center - eye)
    right    =  normalise(forward x up_hint)
    up       =  right x forward           # reorthogonalised

and assembles a standard 4x4 world-to-camera view matrix from those three
basis vectors and the eye position.  The result is stored internally and can
be retrieved with C<get_camera()>.

After the call, C<backface_cull()> picks up the stored C<fwd> vector
automatically unless an explicit C<view_dir> is supplied.

=item C<get_camera()>

Return the camera record set by the most recent C<set_camera()> call, or
C<undef> if C<set_camera()> has not yet been called (or if the record was
cleared by C<grestore()>).

The returned hashref contains:

=over 4

=item C<eye>

Arrayref C<[$ex,$ey,$ez]> - the eye position as supplied.

=item C<center>

Arrayref C<[$cx,$cy,$cz]> - the look-at point as supplied.

=item C<up>

Arrayref C<[$ux,$uy,$uz]> - the I<reorthogonalised> up vector (not
necessarily the same as the hint passed in).

=item C<fwd>

Arrayref C<[$fx,$fy,$fz]> - unit forward vector pointing from C<eye> toward
C<center>.  Used automatically by C<backface_cull()>.

=item C<view>

4x4 arrayref-of-arrayrefs - the world-to-camera view matrix in row-major
order.  The first three rows encode the camera basis (right, up, -forward);
the translation is in the rightmost column.

=back

=item C<camera_to_ctm()>

Pre-multiply the view matrix stored by C<set_camera()> into the 3-D CTM via
the same C<_g3_premul4> path used by C<translate3>, C<rotate3>, etc.

After this call every subsequent C<transform_point()>, C<moveto3()>,
C<line3()>, C<flatten_to_2d()>, etc. automatically includes the camera
transform; no further action is needed to get correct projected coordinates.

Croaks with C<"no camera"> if called before C<set_camera()>.

This method is I<additive>: calling it more than once will compound the
camera transform.  If you need to reposition the camera, call
C<initmatrix3()> first (or use C<gsave()> / C<grestore()>).

=item C<set_perspective(fov =E<gt> $deg [, aspect =E<gt> $r, near =E<gt> $n, far =E<gt> $f])>

Build and store a symmetric perspective projection matrix (equivalent to
OpenGL's C<gluPerspective>).  Does I<not> modify the CTM; call
C<perspective_to_ctm()> afterwards to apply it.

=over 4

=item C<fov> (optional, default C<45>)

Vertical field of view in degrees.  Must be in (0, 180).

=item C<aspect> (optional, default C<1.0>)

Viewport width / height ratio.

=item C<near> (optional, default C<0.1>)

Distance to the near clipping plane.  Must be E<gt> 0.

=item C<far> (optional, default C<100>)

Distance to the far clipping plane.  Must be E<gt> C<near>.

=back

The resulting 4x4 matrix (row-major, column-vector convention) has
C<-1> in position [3][2], which causes C<transform_point()> to compute
C<tw = -z>.  The existing perspective divide (triggered whenever C<tw != 0>
and C<tw != 1>) then gives correctly foreshortened X and Y coordinates.
Z is discarded by C<flatten_to_2d()>, which only retains X and Y.

Projection state is saved and restored by C<gsave()> / C<grestore()>.

=item C<set_frustum(left =E<gt> $l, right =E<gt> $r, bottom =E<gt> $b, top =E<gt> $t, near =E<gt> $n, far =E<gt> $f)>

Build and store an asymmetric (off-axis) perspective projection matrix
(equivalent to OpenGL's C<glFrustum>).  All six named arguments are
required; C<near> and C<far> default to C<0.1> and C<100> respectively.

C<left>, C<right>, C<bottom>, C<top> are the X/Y extents of the view volume
at the near plane.  Setting C<left = -right> and C<bottom = -top> reproduces
a symmetric frustum identical to C<set_perspective()>.

Use this method for off-centre viewports, stereo rendering, or anamorphic
projections.  As with C<set_perspective()>, call C<perspective_to_ctm()>
afterwards to apply it.

=item C<perspective_to_ctm()>

Pre-multiply the projection matrix stored by C<set_perspective()> or
C<set_frustum()> into the 3-D CTM (CTM := P x CTM).

After this call every subsequent C<transform_point()> call applies the full
view + projection pipeline, and C<flatten_to_2d()> yields perspective-correct
2-D coordinates.

Croaks if neither C<set_perspective()> nor C<set_frustum()> has been called.

Typical full workflow:

    $g->initmatrix3();
    $g->set_camera(eye => [5,5,10], center => [0,0,0]);
    $g->camera_to_ctm();
    $g->set_perspective(fov => 45, aspect => 1.0, near => 0.1, far => 100);
    $g->perspective_to_ctm();
    # All drawing calls now produce perspective-foreshortened output.

=item C<get_projection()>

Return the 4x4 projection matrix stored by the most recent
C<set_perspective()> or C<set_frustum()> call, or C<undef> if none has been
set.  The matrix is an arrayref of four arrayrefs (row-major).

=back

=head2 Numeric configuration

=over 4

=item C<set_tolerance($eps)>, C<get_tolerance()>

Set/get the floating-point equality tolerance (default 1e-9).

=item C<set_units($units)>

Store a units tag (e.g. C<'mm'>); no automatic scaling is applied.

=item C<set_coordinate_convention(handedness =E<gt> ..., euler_order =E<gt> ...)>

Store convention tags for downstream use.

=back

=head1 IMPLEMENTATION NOTES

=head2 State storage

All 3-D state lives in C<$self-E<gt>{_g3_*}> to avoid collisions with the
host:

    _g3_CTM          4x4 arrayref-of-arrayrefs (current 3-D transform)
    _g3_gstate       arrayref of save-state records
    _g3_posx/y/z     3-D current point
    _g3_camera       camera record (eye/center/up/fwd/view) set by set_camera()
    _g3_tolerance    floating-point epsilon
    _g3_units        units tag
    _g3_handedness   coordinate convention
    _g3_euler_order  default Euler axis order

=head2 Why method names have a C<3> suffix

L<Role::Tiny> does I<not> override methods that already exist in the
consuming class.  Because L<Graphics::Penplotter::GcodeXY> already defines
C<translate>, C<scale>, C<rotate>, C<moveto>, C<line>, C<lineR>, C<gsave>,
C<grestore>, and C<initmatrix>, any role method with the same name would be
silently discarded.  The C<3> suffix makes the 3-D variants unambiguous.
C<gsave>/C<grestore> are augmented instead via C<after> modifiers.

=head2 Mesh representation

All solid primitives that return a mesh use the structure:

    { verts => \@v, faces => \@f }

where C<@v> is an array of C<[$x,$y,$z]> position arrayrefs and C<@f> is
an array of C<[$i0,$i1,$i2]> triangle index arrayrefs.  Winding order is
counter-clockwise when viewed from the outside (right-hand normal pointing
outward).

=head1 AUTHOR

Albert Koelmans

=head1 LICENSE

Same terms as Perl itself.

=cut
