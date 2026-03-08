package Graphics::Penplotter::GcodeXY::Geometry2D v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Readonly    qw( Readonly );
use Math::Trig  qw( acos tan );
use Math::Bezier ();
use POSIX       qw( ceil );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Geometry2D
# Role providing all geometric primitives, coordinate transformations, and
# line-clipping for GcodeXY.
# ---------------------------------------------------------------------------

requires qw(penup pendown _genfastmove _genslowmove stroke _croak _penlock _penunlock);

# ---------------------------------------------------------------------------
# Constants -- private copies of values defined in GcodeXY.pm.
# ---------------------------------------------------------------------------

Readonly my $D2R       => 0.01745329251;    # degrees to radians
Readonly my $R2D       => 57.2957795130;    # radians to degrees
Readonly my $PI        => 3.14159265359;
Readonly my $HALFPI    => 1.57079632680;
Readonly my $TWOPI     => 6.28318530718;
Readonly my $THREEPI2  => 4.71238898038;
Readonly my $EPSILON   => 0.000001;
Readonly my $EOL       => qq{\n};

# Unit conversion table (multiplication factors from inches).
my %inches_to_unit = (
    pt => 72.0,
    in => 1.0,
    mm => 25.4,
    cm => 2.54,
    px => 96.0,
    pc => 6.0,
);

# ---------------------------------------------------------------------------
# Bezier curve module-level state -- moved from GcodeXY.pm.
# (These are mutable, not Readonly.)
# ---------------------------------------------------------------------------

my $m_approxscale     = 1.0;
my $m_disttolscale    = 0.5 / $m_approxscale;
$m_disttolscale      *= $m_disttolscale;
my $curve_colleps     = 1e-30;
my $m_angletol        = 0.0;
my $curve_angletoleps = 0.01;
my $m_cusp_limit      = 0.0;
my $m_count           = 0;
my $curve_reclim      = 50;
my @m_points          = ();


# ===========================================================================
# GRAPHICS STATE
# ===========================================================================

# Save the current graphics state (CTM, position, pen and font attributes)
# onto the graphics state stack.
sub gsave ($self) {
    push @{ $self->{gstate} }, $self->{fontname};
    push @{ $self->{gstate} }, $self->{fontsize};
    push @{ $self->{gstate} }, $self->{curvepts};
    push @{ $self->{gstate} }, $self->{penlocked};
    push @{ $self->{gstate} }, $self->{posx};
    push @{ $self->{gstate} }, $self->{posy};
    push @{ $self->{gstate} }, $self->{CTM}->[0][0];
    push @{ $self->{gstate} }, $self->{CTM}->[0][1];
    push @{ $self->{gstate} }, $self->{CTM}->[0][2];
    push @{ $self->{gstate} }, $self->{CTM}->[1][0];
    push @{ $self->{gstate} }, $self->{CTM}->[1][1];
    push @{ $self->{gstate} }, $self->{CTM}->[1][2];
    push @{ $self->{gstate} }, $self->{CTM}->[2][0];
    push @{ $self->{gstate} }, $self->{CTM}->[2][1];
    push @{ $self->{gstate} }, $self->{CTM}->[2][2];
    return 1;
}

# Restore the most recently saved graphics state.
sub grestore ($self) {
    $self->{CTM}->[2][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[2][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[2][0] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][0] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][0] = pop @{ $self->{gstate} };
    $self->{posy}        = pop @{ $self->{gstate} };
    $self->{posx}        = pop @{ $self->{gstate} };
    $self->{penlocked}   = pop @{ $self->{gstate} };
    $self->{curvepts}    = pop @{ $self->{gstate} };
    $self->{fontsize}    = pop @{ $self->{gstate} };
    $self->{fontname}    = pop @{ $self->{gstate} };
    return 1;
}


# ===========================================================================
# COORDINATE SYSTEM
# ===========================================================================

# We use three coordinate spaces:
#   User   -- result of scaling, translation and rotation applied by the caller.
#   Paper  -- absolute position on the page; found by applying the CTM to user.
#   Device -- physical inches; found by scaling paper coords by dscale.
# After translate(100,200), the user origin is at (0,0) and the paper at (100,200).

# Return the current point in USER coordinates, or set it if args are given.
sub currentpoint ($self, $new_x = undef, $new_y = undef) {
    if ( defined $new_x ) {
        $self->{posx} = $new_x;
        $self->{posy} = $new_y;
        return 1;
    }
    return ( $self->{posx}, $self->{posy} );
}

# Return paper coordinates of a user-space point (apply CTM).
sub _u_to_p ($self, $x, $y) {
    my @point = ( $x, $y );
    $self->_transform( 1, \@point );
    return @point;
}

# Return device coordinates of a paper-space point (scale by dscale).
sub _p_to_d ($self, $x, $y) {
    return ( $x * $self->{dscale}, $y * $self->{dscale} );
}

# Return device coordinates of a user-space point.
sub _u_to_d ($self, $x, $y) {
    my ( $rx, $ry ) = $self->_u_to_p( $x, $y );
    return $self->_p_to_d( $rx, $ry );
}


# ===========================================================================
# LINE PRIMITIVES
# ===========================================================================

# Move to ($x,$y), lifting and then lowering the pen.
sub moveto ($self, $x, $y) {
    $self->penup();
    $self->_genfastmove( $x, $y );
    $self->pendown();
    return 1;
}

# Move to ($x,$y) relative to the current point.
sub movetoR ($self, $x, $y) {
    my ( $cx, $cy ) = $self->currentpoint();
    $self->penup();
    $self->_genfastmove( $x + $cx, $y + $cy );
    $self->pendown();
    return 1;
}

# Draw a line.  With 4 args: moveto ($x1,$y1) then draw to ($x2,$y2).
# With 2 args: draw from the current point to ($x1,$y1).
sub line ($self, $x1, $y1 = undef, $x2 = undef, $y2 = undef) {
    if ( defined $x2 && defined $y2 ) {
        $self->moveto( $x1, $y1 );
        $self->_genslowmove( $x2, $y2 );
        return 1;
    }
    elsif ( defined $x2 && !defined $y2 ) {
        $self->_croak('wrong number of args for line (2 or 4)');
        return 0;
    }
    elsif ( defined $y1 ) {
        $self->_genslowmove( $x1, $y1 );
        return 1;
    }
    else {
        $self->_croak('wrong number of args for line (2 or 4)');
        return 0;
    }
}

# Draw a line from the current point using relative coordinates.
sub lineR ($self, $x, $y) {
    my ( $cx, $cy ) = $self->currentpoint();
    $self->_genslowmove( $x + $cx, $y + $cy );
    return 1;
}


# ===========================================================================
# POLYGON / HIDDEN-LINE CLIPPING
# ===========================================================================

# Compute the axis-aligned bounding box of a flat list of (x,y) pairs.
sub _bbox_from_points ($self, @pts) {
    my ( $minx, $miny, $maxx, $maxy );
    $minx = $miny = 1e99;
    $maxx = $maxy = -1e99;
    while (@pts) {
        my $x = shift @pts;
        my $y = shift @pts;
        $minx = $x if $x < $minx;
        $miny = $y if $y < $miny;
        $maxx = $x if $x > $maxx;
        $maxy = $y if $y > $maxy;
    }
    return ( $minx, $miny, $maxx, $maxy );
}

# Return true if two bounding boxes (each [minx,miny,maxx,maxy]) intersect.
sub _bbox_intersect ($self, $a, $b) {
    return !(  $a->[2] < $b->[0] || $a->[0] > $b->[2]
            || $a->[3] < $b->[1] || $a->[1] > $b->[3] );
}

# Point-in-polygon test (ray-crossing algorithm).
# Returns 1 if ($px,$py) is inside the polygon, 0 otherwise.
sub _point_in_poly ($self, $px, $py, @poly) {
    my $inside = 0;
    my $n      = scalar @poly / 2;
    return 0 if $n < 3;
    for ( my $i = 0; $i < $n; $i++ ) {
        my $xi = $poly[ 2 * $i ];
        my $yi = $poly[ 2 * $i + 1 ];
        my $j  = ( $i == 0 ) ? $n - 1 : $i - 1;
        my $xj = $poly[ 2 * $j ];
        my $yj = $poly[ 2 * $j + 1 ];
        my $intersect =
            ( ( $yi > $py ) != ( $yj > $py ) ) &&
            ( $px < ( $xj - $xi ) * ( $py - $yi ) / ( $yj - $yi + 0.0 ) + $xi );
        $inside = !$inside if $intersect;
    }
    return $inside ? 1 : 0;
}

# Add a polygon to the clip queue, removing parts of previously queued
# polygons that fall inside the new one.
sub polygon_clip ($self, $x, $y, @rest) {
    if ( scalar @rest == 0 ) {
        $self->_croak('bad polygon_clip - no line segments found');
        return 0;
    }
    if ( scalar @rest % 2 ) {
        $self->_croak('bad polygon_clip - odd number of points');
        return 0;
    }
    my @poly = ( $x, $y, @rest );
    # Ensure the polygon is closed
    if ( $poly[-2] != $poly[0] || $poly[-1] != $poly[1] ) {
        push @poly, $poly[0], $poly[1];
    }
    $self->{clip_queue} //= [];
    my ( $minx, $miny, $maxx, $maxy ) = $self->_bbox_from_points(@poly);
    my $newbbox = [ $minx, $miny, $maxx, $maxy ];

    foreach my $old ( @{ $self->{clip_queue} } ) {
        next unless $self->_bbox_intersect( $old->{bbox}, $newbbox );
        my @newsegs = ();
        foreach my $seg ( @{ $old->{segs} } ) {
            my @ts = ( 0.0, 1.0 );
            for ( my $i = 0; $i < @poly - 2; $i += 2 ) {
                my ( $x2, $y2 ) = ( $poly[$i],     $poly[ $i + 1 ] );
                my ( $x3, $y3 ) = ( $poly[ $i + 2 ], $poly[ $i + 3 ] );
                my $t = $self->_getsegintersect(
                    $seg->{sx}, $seg->{sy}, $seg->{dx}, $seg->{dy},
                    $x2, $y2, $x3, $y3 );
                if ( $t && $t > 0.0 && $t < 1.0 ) { push @ts, $t }
            }
            my %seen;
            @ts = sort { $a <=> $b }
                  grep { !$seen{ sprintf( "%.8f", $_ ) }++ } @ts;
            for ( my $k = 0; $k < @ts - 1; $k++ ) {
                my ( $t1, $t2 ) = ( $ts[$k], $ts[ $k + 1 ] );
                my $mx = $seg->{sx} + ( $seg->{dx} - $seg->{sx} ) * ( ( $t1 + $t2 ) / 2.0 );
                my $my = $seg->{sy} + ( $seg->{dy} - $seg->{sy} ) * ( ( $t1 + $t2 ) / 2.0 );
                next if $self->_point_in_poly( $mx, $my, @poly );
                my $sx = $seg->{sx} + ( $seg->{dx} - $seg->{sx} ) * $t1;
                my $sy = $seg->{sy} + ( $seg->{dy} - $seg->{sy} ) * $t1;
                my $dx = $seg->{sx} + ( $seg->{dx} - $seg->{sx} ) * $t2;
                my $dy = $seg->{sy} + ( $seg->{dy} - $seg->{sy} ) * $t2;
                push @newsegs, { sx => $sx, sy => $sy, dx => $dx, dy => $dy };
            }
        }
        $old->{segs} = [@newsegs];
    }
    my @segs = ();
    for ( my $i = 0; $i < @poly - 2; $i += 2 ) {
        my ( $sx, $sy ) = ( $poly[$i],       $poly[ $i + 1 ] );
        my ( $dx, $dy ) = ( $poly[ $i + 2 ], $poly[ $i + 3 ] );
        push @segs, { sx => $sx, sy => $sy, dx => $dx, dy => $dy };
    }
    push @{ $self->{clip_queue} }, { segs => [@segs], bbox => $newbbox };
    return 1;
}

# Flush the clip queue: draw all surviving segments and clear the queue.
sub polygon_clip_end ($self) {
    $self->{clip_queue} //= [];
    foreach my $poly ( @{ $self->{clip_queue} } ) {
        foreach my $seg ( @{ $poly->{segs} } ) {
            $self->penup();
            $self->_genfastmove( $seg->{sx}, $seg->{sy} );
            $self->pendown();
            $self->_genslowmove( $seg->{dx}, $seg->{dy} );
        }
    }
    $self->stroke();
    @{ $self->{clip_queue} } = ();
    return 1;
}

# Draw a series of consecutive line segments from ($x,$y).
sub polygon ($self, $x, $y, @rest) {
    if ( scalar @rest == 0 ) {
        $self->_croak('bad polygon - no line segments found');
        return 0;
    }
    if ( scalar @rest % 2 ) {
        $self->_croak('bad polygon - odd number of points');
        return 0;
    }
    $self->moveto( $x, $y );
    while (@rest) {
        $x = shift @rest;
        $y = shift @rest;
        $self->line( $x, $y );
    }
    return 1;
}

# Draw a series of consecutive line segments from the current position,
# in absolute coordinates.
sub polygonC ($self, @coords) {
    if ( scalar @coords < 2 ) {
        $self->_croak('bad polygon (C) - not enough points');
        return 0;
    }
    if ( scalar @coords % 2 ) {
        $self->_croak('bad polygon (C) - odd number of points');
        return 0;
    }
    while (@coords) {
        my $x = shift @coords;
        my $y = shift @coords;
        $self->line( $x, $y );
    }
    return 1;
}

# Draw a series of consecutive line segments in relative coordinates.
sub polygonR ($self, @coords) {
    if ( scalar @coords < 2 ) {
        $self->_croak('bad polygon (C) - not enough points');
        return 0;
    }
    if ( scalar @coords % 2 ) {
        $self->_croak('bad polygon (C) - odd number of points');
        return 0;
    }
    while (@coords) {
        my ( $cx, $cy ) = $self->currentpoint();
        my $x = shift @coords;
        my $y = shift @coords;
        $self->line( $x + $cx, $y + $cy );
    }
    return 1;
}

# Draw a polygon with rounded corners between line segments.
# Requires at least 3 points (6 numbers) plus a radius $r.
sub polygonround ($self, $r, @rest) {
    if ( scalar @rest < 6 ) {
        $self->_croak('bad polygonround - need at least 3 points (6 numbers)');
        return 0;
    }
    if ( scalar @rest % 2 ) {
        $self->_croak('bad polygonround - odd number of coordinates');
        return 0;
    }
    my $x = shift @rest;
    my $y = shift @rest;
    $self->moveto( $x, $y );
    my $dx    = shift @rest;
    my $dy    = shift @rest;
    my $halfx = ( $dx - $x ) / 2.0;
    my $halfy = ( $dy - $y ) / 2.0;
    $self->lineR( $halfx, $halfy );
    my ( $newhalfx, $newhalfy );
    while (@rest) {
        $x  = $dx;
        $y  = $dy;
        $dx = shift @rest;
        $dy = shift @rest;
        $newhalfx = ( $dx - $x ) / 2.0;
        $newhalfy = ( $dy - $y ) / 2.0;
        $self->arcto( $x, $y, $x + $newhalfx, $y + $newhalfy, $r );
        $halfx = $newhalfx;
        $halfy = $newhalfy;
    }
    $self->line( $dx, $dy );
    return 1;
}


# ===========================================================================
# RECTANGLES
# ===========================================================================

# Create a rectangle.  With 4 args: (x1,y1) to (x2,y2).
# With 2 args: extend from the current point by (x,y).
sub box ($self, $x1, $y1, $x2 = undef, $y2 = undef) {
    if ( defined $x2 && defined $y2 ) {
        $self->polygon( $x1, $y1, $x2, $y1, $x2, $y2, $x1, $y2, $x1, $y1 );
    }
    elsif ( !defined $x2 && !defined $y2 ) {
        $x2 = $x1;
        $y2 = $y1;
        ( $x1, $y1 ) = $self->currentpoint();
        $self->polygonC( $x2, $y1, $x2, $y2, $x1, $y2, $x1, $y1 );
    }
    else {
        $self->_croak('box: wrong number of arguments (must be 2 or 4)');
        return 0;
    }
    return 1;
}

# Create a rectangle from the current point using relative coordinates.
sub boxR ($self, $x, $y) {
    my ( $cx, $cy ) = $self->currentpoint();
    $self->polygonR( $x, 0, 0, $y, -$x, 0, 0, -$y );
    return 1;
}

# Create a box with rounded corners.
sub boxround ($self, $r, $bx, $by, $tx, $ty) {
    my $halfheight = ( $ty - $by ) / 2.0;
    my $halfwidth  = ( $tx - $bx ) / 2.0;
    $self->moveto( $bx, $by + $halfheight );
    $self->arcto( $bx, $ty, $bx + $halfwidth, $ty,              $r );
    $self->arcto( $tx, $ty, $tx,              $ty - $halfheight, $r );
    $self->arcto( $tx, $by, $tx - $halfwidth, $by,               $r );
    $self->arcto( $bx, $by, $bx,              $by + $halfheight, $r );
    return 1;
}


# ===========================================================================
# ARROWHEAD AND PAGE BORDER
# ===========================================================================

# Create an arrowhead at the tip of the most recent segment.
# $type is 'open' (default) or 'closed'.
sub arrowhead ($self, $length, $width, $type = 'open') {
    my ( $tailx, $taily, $tipx, $tipy, $dx, $dy, $angle );
    if ( scalar $self->{psegments} > 0 ) {
        $tailx = $self->{psegments}[-1]{sx};
        $taily = $self->{psegments}[-1]{sy};
        $tipx  = $self->{psegments}[-1]{dx};
        $tipy  = $self->{psegments}[-1]{dy};
        $dx    = $tipx - $tailx;
        $dy    = $tipy - $taily;
        $angle = atan2( $dy, $dx );    # radians
    }
    else {
        ( $tipx, $tipy ) = $self->currentpoint();
        $angle = 0.0;
    }
    $self->gsave();
    # Segments are already scaled to inches; scale back to the current unit.
    $self->translate( $self->_in_unitfied($tipx), $self->_in_unitfied($tipy) );
    $self->rotate( $angle * $R2D );
    $self->line( -$length, $width / 2.0 );
    if ( $type eq 'closed' ) {
        $self->line( -$length, -$width / 2.0 );
        $self->line( 0, 0 );
    }
    else {
        $self->line( -$length, -$width / 2.0, 0, 0 );
    }
    $self->grestore();
    return 1;
}

# Draw a box inset by $margin from the page edges.
sub pageborder ($self, $margin) {
    $self->box(
        $margin, $margin,
        $self->{xsize} - $margin, $self->{ysize} - $margin
    );
    return 1;
}


# ===========================================================================
# BEZIER CURVES
# ===========================================================================

# Draw a Bézier curve.  6 control points = quadratic, 8 = cubic, more = higher order.
sub curve ($self, @control) {
    if ( scalar @control < 6 ) {
        $self->_croak('wrong number of args for curve');
        return 0;
    }
    if ( scalar @control == 6 ) {
        $self->_curve3(@control);
    }
    elsif ( scalar @control == 8 ) {
        $self->_curve4(@control);
    }
    else {
        my $b      = Math::Bezier->new(@control);
        my $pts    = $self->{curvepts};
        my @points = $b->curve($pts);
        $self->polygon(@points);
    }
    return 1;
}

# Draw a Bézier curve starting from the current position.
sub curveto ($self, @control) {
    if ( scalar @control < 6 ) {
        $self->_croak('wrong number of args for curveto');
        return 0;
    }
    unshift @control, $self->currentpoint();
    if ( scalar @control == 6 ) {
        $self->_penlock();
        $self->_curve3(@control);
        $self->_penunlock();
    }
    elsif ( scalar @control == 8 ) {
        $self->_penlock();
        $self->_curve4(@control);
        $self->_penunlock();
    }
    else {
        my $b      = Math::Bezier->new(@control);
        my $pts    = $self->{curvepts};
        my @points = $b->curve($pts);
        shift @points;
        shift @points;    # remove start point — already there
        $self->polygonC(@points);
    }
    return 1;
}

# Internal: render a quadratic Bézier curve by recursive subdivision.
sub _curve3 ($self, $x1, $y1, $x2, $y2, $x3, $y3) {
    @m_points = ();
    push @m_points, ( $x1, $y1 );
    $self->_recbezier3( $x1, $y1, $x2, $y2, $x3, $y3, 0 );
    push @m_points, ( $x3, $y3 );
    $self->polygon(@m_points);
    return 1;
}

sub _recbezier3 ($self, $x1, $y1, $x2, $y2, $x3, $y3, $level) {
    if ( $level > $curve_reclim ) { return }
    my $x12  = ( $x1 + $x2 ) / 2;
    my $y12  = ( $y1 + $y2 ) / 2;
    my $x23  = ( $x2 + $x3 ) / 2;
    my $y23  = ( $y2 + $y3 ) / 2;
    my $x123 = ( $x12 + $x23 ) / 2;
    my $y123 = ( $y12 + $y23 ) / 2;
    my $dx   = $x3 - $x1;
    my $dy   = $y3 - $y1;
    my $d    = _fabs( ( ( $x2 - $x3 ) * $dy - ( $y2 - $y3 ) * $dx ) );
    my $da;
    if ( $d > $curve_colleps ) {
        if ( $d * $d <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x123, $y123 );
                return;
            }
            $da = _fabs(
                atan2( $y3 - $y2, $x3 - $x2 ) - atan2( $y2 - $y1, $x2 - $x1 ) );
            if ( $da >= $PI ) { $da = 2 * $PI - $da }
            if ( $da < $m_angletol ) {
                push @m_points, ( $x123, $y123 );
                return;
            }
        }
    }
    else {
        $da = $dx * $dx + $dy * $dy;
        if ( $da == 0 ) {
            $d = _calc_sq_distance( $x1, $y1, $x2, $y2 );
        }
        else {
            $d = ( ( $x2 - $x1 ) * $dx + ( $y2 - $y1 ) * $dy ) / $da;
            if ( $d > 0 && $d < 1 ) { return }
            if    ( $d <= 0 ) { $d = _calc_sq_distance( $x2, $y2, $x1, $y1 ) }
            elsif ( $d >= 1 ) { $d = _calc_sq_distance( $x2, $y2, $x3, $y3 ) }
            else {
                $d = _calc_sq_distance( $x2, $y2, $x1 + $d * $dx, $y1 + $d * $dy );
            }
        }
        if ( $d < $m_disttolscale ) {
            push @m_points, ( $x2, $y2 );
            return;
        }
    }
    $self->_recbezier3( $x1,   $y1,   $x12, $y12, $x123, $y123, $level + 1 );
    $self->_recbezier3( $x123, $y123, $x23, $y23, $x3,   $y3,   $level + 1 );
    return 1;
}

# Internal: render a cubic Bézier curve by recursive subdivision.
# Algorithm translated from the Anti-Grain Geometry library.
sub _curve4 ($self, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) {
    @m_points = ();
    push @m_points, ( $x1, $y1 );
    $self->_recbezier4( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, 0 );
    push @m_points, ( $x4, $y4 );
    $self->polygon(@m_points);
    return 1;
}

sub _recbezier4 ($self, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, $level) {
    my ( $da1, $da2, $k );
    if ( $level > $curve_reclim ) { return }
    my $x12   = ( $x1 + $x2 ) / 2.0;
    my $y12   = ( $y1 + $y2 ) / 2.0;
    my $x23   = ( $x2 + $x3 ) / 2.0;
    my $y23   = ( $y2 + $y3 ) / 2.0;
    my $x34   = ( $x3 + $x4 ) / 2.0;
    my $y34   = ( $y3 + $y4 ) / 2.0;
    my $x123  = ( $x12 + $x23 ) / 2.0;
    my $y123  = ( $y12 + $y23 ) / 2.0;
    my $x234  = ( $x23 + $x34 ) / 2.0;
    my $y234  = ( $y23 + $y34 ) / 2.0;
    my $x1234 = ( $x123 + $x234 ) / 2.0;
    my $y1234 = ( $y123 + $y234 ) / 2.0;
    my $dx    = $x4 - $x1;
    my $dy    = $y4 - $y1;
    my $d2    = _fabs( ( ( $x2 - $x4 ) * $dy - ( $y2 - $y4 ) * $dx ) );
    my $d3    = _fabs( ( ( $x3 - $x4 ) * $dy - ( $y3 - $y4 ) * $dx ) );
    my $tmp   = ( int( $d2 > $curve_colleps ) << 1 ) + int( $d3 > $curve_colleps );
    if ( $tmp == 0 ) {
        $k = $dx * $dx + $dy * $dy;
        if ( $k == 0 ) {
            $d2 = _calc_sq_distance( $x1, $y1, $x2, $y2 );
            $d3 = _calc_sq_distance( $x4, $y4, $x3, $y3 );
        }
        else {
            $k   = 1.0 / $k;
            $da1 = $x2 - $x1;
            $da2 = $y2 - $y1;
            $d2  = $k * ( $da1 * $dx + $da2 * $dy );
            $da1 = $x3 - $x1;
            $da2 = $y3 - $y1;
            $d3  = $k * ( $da1 * $dx + $da2 * $dy );
            if ( $d2 > 0 && $d2 < 1 && $d3 > 0 && $d3 < 1 ) { return }
            if    ( $d2 <= 0 ) { $d2 = _calc_sq_distance( $x2, $y2, $x1, $y1 ) }
            elsif ( $d2 >= 1 ) { $d2 = _calc_sq_distance( $x2, $y2, $x4, $y4 ) }
            else {
                $d2 = _calc_sq_distance( $x2, $y2,
                    $x1 + $d2 * $dx, $y1 + $d2 * $dy );
            }
            if    ( $d3 <= 0 ) { $d3 = _calc_sq_distance( $x3, $y3, $x1, $y1 ) }
            elsif ( $d3 >= 1 ) { $d3 = _calc_sq_distance( $x3, $y3, $x4, $y4 ) }
            else {
                $d3 = _calc_sq_distance( $x3, $y3,
                    $x1 + $d3 * $dx, $y1 + $d3 * $dy );
            }
        }
        if ( $d2 > $d3 ) {
            if ( $d2 < $m_disttolscale ) { push @m_points, ( $x2, $y2 ); return }
        }
        else {
            if ( $d3 < $m_disttolscale ) { push @m_points, ( $x3, $y3 ); return }
        }
    }
    if ( $tmp == 1 ) {
        if ( $d3 * $d3 <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            $da1 = _fabs(
                atan2( $y4 - $y3, $x4 - $x3 ) - atan2( $y3 - $y2, $x3 - $x2 ) );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da1 < $m_angletol ) {
                push @m_points, ( $x2, $y2 );
                push @m_points, ( $x3, $y3 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) { push @m_points, ( $x3, $y3 ); return }
            }
        }
    }
    if ( $tmp == 2 ) {
        if ( $d2 * $d2 <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            $da1 = _fabs(
                atan2( $y3 - $y2, $x3 - $x2 ) - atan2( $y2 - $y1, $x2 - $x1 ) );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da1 < $m_angletol ) {
                push @m_points, ( $x2, $y2 );
                push @m_points, ( $x3, $y3 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) { push @m_points, ( $x2, $y2 ); return }
            }
        }
    }
    if ( $tmp == 3 ) {
        if ( ( $d2 + $d3 ) * ( $d2 + $d3 ) <=
             $m_disttolscale * ( $dx * $dx + $dy * $dy ) )
        {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            $k   = atan2( $y3 - $y2, $x3 - $x2 );
            $da1 = _fabs( $k - atan2( $y2 - $y1, $x2 - $x1 ) );
            $da2 = _fabs( atan2( $y4 - $y3, $x4 - $x3 ) - $k );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da2 >= $PI ) { $da2 = 2 * $PI - $da2 }
            if ( $da1 + $da2 < $m_angletol ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) { push @m_points, ( $x2, $y2 ); return }
                if ( $da2 > $m_cusp_limit ) { push @m_points, ( $x3, $y3 ); return }
            }
        }
    }
    $self->_recbezier4( $x1,    $y1,    $x12,  $y12,  $x123,  $y123,  $x1234, $y1234, $level + 1 );
    $self->_recbezier4( $x1234, $y1234, $x234, $y234, $x34,   $y34,   $x4,    $y4,    $level + 1 );
    return 1;
}


# ===========================================================================
# ARCS
# ===========================================================================

# Draw a circular arc centred at ($x,$y), radius $r, from $start to $finish degrees.
# The number of segments is derived automatically from the radius and arc span.
sub arc ($self, $x, $y, $r, $start, $finish) {
    if ( !defined $finish ) {
        $self->_croak('bad arc - need x, y, r, start, finish');
        return 0;
    }
    my $full_n = circle_segments($r);
    my $steps  = int( _fabs( $full_n * ( $finish - $start ) / 360.0 ) );
    $steps = 8 if $steps < 8;
    my @points = ();
    my $s      = radians($start);
    my $f      = radians($finish);
    my $inc    = ( $f - $s ) / $steps;
    for my $i ( 0 .. $steps ) {
        my $curs = $s + $i * $inc;
        push @points, $x + $r * cos $curs;
        push @points, $y + $r * sin $curs;
    }
    $self->polygon(@points);
    return 1;
}

# Join two lines with a circular arc fillet.
# Miller, "Joining Two Lines with a Circular Arc Fillet," Graphics Gems III.
sub arcto ($self, $x2, $y2, $x4, $y4, $r) {
    if ( !defined $r ) {
        $self->_croak('bad arcto - need x1, y1, x2, y2, r');
        return 0;
    }
    my ( $x1, $y1 ) = $self->currentpoint();
    my ( $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y, $xc, $yc, $pa, $aa ) =
        $self->_fillet( $x1, $y1, $x2, $y2, $x2, $y2, $x4, $y4, $r );
    if ( defined $p1x ) {
        $self->line( $p2x, $p2y );
        $self->arc( $xc, $yc, $r, $pa, $pa + $aa );
        $self->line( $p4x, $p4y );
        return 1;
    }
    return 0;
}


# ===========================================================================
# CIRCLE AND ELLIPSE
# ===========================================================================

sub circle ($self, $x, $y, $r) {
    if ( !defined $r ) {
        $self->_croak('bad circle - need x, y, r');
        return 0;
    }
    $self->ellipse( $x, $y, $r, $r );
    return 1;
}

sub ellipse ($self, $x, $y, $a, $b) {
    if ( !defined $b ) {
        $self->_croak('bad ellipse - need x, y, a, b');
        return 0;
    }
    $self->polygon( ellipse_points( $x, $y, $a, $b ) );
    return 1;
}

# CIRCLE / ELLIPSE SEGMENT CALCULATION
# Return the number of line segments needed to approximate a circle of
# radius $r with a maximum deviation of $max_err from the true circle.
# The derivation: for a regular n-gon inscribed in a circle of radius r,
# the sagitta (max inward error) of each chord is r(1 - cos(π/n)).
# Setting that equal to max_err and solving for n gives:
#   n = ceil( π / acos(1 - max_err/r) )
# $max_err defaults to 0.25 user units if omitted.
# Returns an even number >= 8.
sub circle_segments ($r, $max_err = undef) {
    return 4 if $r <= 0;
    $max_err //= 0.25;
    $max_err = $r if $max_err > $r;
    if ( $max_err / $r >= 0.5 ) {
        return 8;    # octagon is close enough for very coarse tolerance
    }
    my $ratio = 1.0 - $max_err / $r;
    $ratio =  1.0 if $ratio >  1.0;
    $ratio = -1.0 if $ratio < -1.0;
    my $half_theta = acos($ratio);
    if ( $half_theta <= 0 ) {
        # Extremely small error: one segment per unit of circumference
        return int( ceil( 2 * $PI * $r ) );
    }
    my $n = int( ceil( $PI / $half_theta ) );
    $n = 8     if $n < 8;
    $n += $n % 2;    # keep even
    return $n;
}

# Return the number of segments for an ellipse with semi-axes $a and $b.
# Uses the larger radius as the governing dimension.
sub ellipse_segments ($a, $b, $max_err = undef) {
    my $r = ( $a > $b ) ? $a : $b;
    return circle_segments( $r, $max_err );
}

# Return a flat, closed list of (x,y,...,x0,y0) vertices for a circle.
# The list is closed (first point repeated at the end) so it can be
# passed directly to polygon().  $max_err controls rendering accuracy.
sub circle_points ($cx, $cy, $r, $max_err = undef) {
    my $n = circle_segments( $r, $max_err );
    my @pts;
    for my $i ( 0 .. $n - 1 ) {
        my $t = 2.0 * $PI * $i / $n;
        push @pts, $cx + $r * cos($t), $cy + $r * sin($t);
    }
    push @pts, $pts[0], $pts[1];    # close the polygon
    return @pts;
}

# Return a flat, closed list of (x,y,...,x0,y0) vertices for an ellipse.
# The list is closed (first point repeated at the end) so it can be
# passed directly to polygon().  $max_err controls rendering accuracy.
sub ellipse_points ($cx, $cy, $a, $b, $max_err = undef) {
    my $n = ellipse_segments( $a, $b, $max_err );
    my @pts;
    for my $i ( 0 .. $n - 1 ) {
        my $t = 2.0 * $PI * $i / $n;
        push @pts, $cx + $a * cos($t), $cy + $b * sin($t);
    }
    push @pts, $pts[0], $pts[1];    # close the polygon
    return @pts;
}


# ===========================================================================
# TRANSFORMATIONS (CTM)
# ===========================================================================

# Rotate about a point ($rxx,$ryy) in user coordinates, or the origin if omitted.
# Code from Hearn's "Computer Graphics with C".
sub rotate ($self, $a, $rxx = undef, $ryy = undef) {
    my @m;
    my ( $rx, $ry );
    if ( !defined $a ) {
        $self->_croak('bad rotate - need 1 or 3 parameters');
        return 0;
    }
    if ( !defined $rxx ) {
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );
    }
    else {
        ( $rx, $ry ) = $self->_u_to_p( $rxx, $ryy );
    }
    $a       = radians($a);
    @m       = ( [1, 0, 0], [0, 1, 0], [0, 0, 1] );
    $m[0][0] = cos $a;
    $m[0][1] = -sin $a;
    $m[0][2] = $rx * ( 1 - cos $a ) + $ry * sin $a;
    $m[1][0] = sin $a;
    $m[1][1] = cos $a;
    $m[1][2] = $ry * ( 1 - cos $a ) - $rx * sin $a;
    $self->_premulmat( \@m, \@{ $self->{CTM} } );
    return 1;
}

# Reset the CTM to the identity matrix.
sub initmatrix ($self) {
    $self->{CTM} = [ [1, 0, 0], [0, 1, 0], [0, 0, 1] ];
    return 1;
}

# Move the point ($tx,$ty) in user space to the origin.
sub translate ($self, $tx, $ty) {
    if ( !defined $ty ) {
        $self->_croak('wrong number of args for translate');
        return 0;
    }
    $self->moveto( $tx, $ty );
    $self->translateC();
    return 1;
}

# Move the current page location (in user coords) to the origin.
sub translateC ($self) {
    my ( $x, $y ) = $self->currentpoint();
    my ( $v, $w ) = $self->_u_to_p( $x, $y );
    $self->{CTM}[0][2] = $v;
    $self->{CTM}[1][2] = $w;
    $self->currentpoint( 0, 0 );
    return 1;
}

# Scale about ($rxx,$ryy) or the origin.  $sy defaults to $sx if omitted.
sub scale ($self, $sx, $sy = undef, $rxx = undef, $ryy = undef) {
    my ( $rx, $ry );
    my @ma;
    if ( defined $rxx && !defined $ryy ) {
        $self->_croak('bad scaling - need 1, 2 or 4 parameters');
        return 0;
    }
    if ( !defined $sy ) {
        $sy = $sx;
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );
    }
    elsif ( !defined $rxx ) {
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );
    }
    else {
        ( $rx, $ry ) = $self->_u_to_p( $rxx, $ryy );
    }
    @ma       = ( [1, 0, 0], [0, 1, 0], [0, 0, 1] );
    $ma[0][0] = $sx;
    $ma[0][2] = ( 1 - $sx ) * $rx;
    $ma[1][1] = $sy;
    $ma[1][2] = ( 1 - $sy ) * $ry;
    $self->_premulmat( \@ma, \@{ $self->{CTM} } );
    return 1;
}

# Shear in the X direction by $deg degrees.
sub skewX ($self, $deg) {
    if ( !defined $deg ) {
        $self->_croak('wrong number of args for skewX');
        return 0;
    }
    my $tana   = tan radians($deg);
    my @matrix = ( [1, $tana, 0], [0, 1, 0], [0, 0, 1] );
    $self->_premulmat( \@matrix, \@{ $self->{CTM} } );
    return 1;
}

# Shear in the Y direction by $deg degrees.
sub skewY ($self, $deg) {
    if ( !defined $deg ) {
        $self->_croak('wrong number of args for skewY');
        return 0;
    }
    my $tana   = tan radians($deg);
    my @matrix = ( [1, 0, 0], [$tana, 1, 0], [0, 0, 1] );
    $self->_premulmat( \@matrix, \@{ $self->{CTM} } );
    return 1;
}

# Premultiply matrix $a into matrix $b (result stored in $b).
sub _premulmat ($self, $aref, $bref) {
    my @a   = @{$aref};
    my @b   = @{$bref};
    my @tmp;
    foreach my $r ( 0 .. 2 ) {
        foreach my $c ( 0 .. 2 ) {
            $tmp[$r][$c] =
                $a[$r][0] * $b[0][$c] +
                $a[$r][1] * $b[1][$c] +
                $a[$r][2] * $b[2][$c];
        }
    }
    foreach my $r ( 0 .. 2 ) {
        foreach my $c ( 0 .. 2 ) {
            $bref->[$r][$c] = $tmp[$r][$c];
        }
    }
    return 1;
}

# Apply the CTM to an array of $npts points stored as a flat (x0,y0,x1,y1,...) list.
sub _transform ($self, $npts, $ptsref) {
    foreach my $k ( 0 .. $npts - 1 ) {
        my $tmp =
            $self->{CTM}->[0][0] * $ptsref->[ 2 * $k ] +
            $self->{CTM}->[0][1] * $ptsref->[ 2 * $k + 1 ] +
            $self->{CTM}->[0][2];
        $ptsref->[ 2 * $k + 1 ] =
            $self->{CTM}->[1][0] * $ptsref->[ 2 * $k ] +
            $self->{CTM}->[1][1] * $ptsref->[ 2 * $k + 1 ] +
            $self->{CTM}->[1][2];
        $ptsref->[ 2 * $k ] = $tmp;
    }
    return 1;
}


# ===========================================================================
# ARC / FILLET GEOMETRY HELPERS
# ===========================================================================

# Signed cross product of two 2-D vectors.
sub _cross2 ($self, $v1x, $v1y, $v2x, $v2y) {
    return ( $v1x * $v2y - $v2x * $v1y );
}

# Angle subtended by two vectors: cos(a) = u·v / (‖u‖·‖v‖).
sub _dot2 ($self, $ux, $uy, $vx, $vy) {
    my $d = sqrt( ( $ux*$ux + $uy*$uy ) * ( $vx*$vx + $vy*$vy ) );
    return 0.0 if $d == 0.0;
    return acos( ( $ux*$vx + $uy*$vy ) / $d );
}

# Find a,b,c for Ax + By + C = 0 through p1 and p2.
sub _linecoefs ($self, $p1x, $p1y, $p2x, $p2y) {
    my $c = ( $p2x * $p1y ) - ( $p1x * $p2y );
    my $a = $p2y - $p1y;
    my $b = $p1x - $p2x;
    return ( $a, $b, $c );
}

# Return signed distance from line Ax + By + C = 0 to point P.
sub _linetopoint ($self, $a, $b, $c, $px, $py) {
    my $d = sqrt( $a*$a + $b*$b );
    return 0.0 if $d == 0.0;
    return ( $a*$px + $b*$py + $c ) / $d;
}

# Given line ax + by + c = 0 and point p, find the foot of the perpendicular from p.
sub _pointperp ($self, $a, $b, $c, $px, $py) {
    my ( $x, $y ) = ( 0.0, 0.0 );
    my $d  = $a*$a + $b*$b;
    my $cp = $a*$py - $b*$px;
    if ( $d != 0.0 ) {
        $x = ( -$a*$c - $b*$cp ) / $d;
        $y = (  $a*$cp - $b*$c ) / $d;
    }
    return ( $x, $y );
}

# Compute a circular arc fillet between lines L1 (p1..p2) and L2 (p3..p4) with radius $r.
# Returns the 8 clipped endpoint coordinates plus the arc centre and angle, or undef on failure.
# Miller, "Joining Two Lines with a Circular Arc Fillet," Graphics Gems III.
sub _fillet ($self, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y, $r) {
    my ( $a1, $b1, $c1, $a2, $b2, $c2, $c1p, $c2p, $d1, $d2, $xa, $xb, $ya, $yb, $d, $rr );
    my ( $mpx, $mpy, $pcx, $pcy, $gv1x, $gv1y, $gv2x, $gv2y, $xc, $yc, $pa, $aa );
    ( $a1, $b1, $c1 ) = $self->_linecoefs( $p1x, $p1y, $p2x, $p2y );
    ( $a2, $b2, $c2 ) = $self->_linecoefs( $p3x, $p3y, $p4x, $p4y );
    if ( ( $a1 * $b2 ) == ( $a2 * $b1 ) ) { return (undef) }    # parallel or coincident
    $mpx = ( $p3x + $p4x ) / 2.0;
    $mpy = ( $p3y + $p4y ) / 2.0;
    $d1  = $self->_linetopoint( $a1, $b1, $c1, $mpx, $mpy );
    if ( $d1 == 0.0 ) { return (undef) x 12 }
    $mpx = ( $p1x + $p2x ) / 2.0;
    $mpy = ( $p1y + $p2y ) / 2.0;
    $d2  = $self->_linetopoint( $a2, $b2, $c2, $mpx, $mpy );
    if ( $d2 == 0.0 ) { return (undef) x 12 }
    $rr  = ( $d1 <= 0.0 ) ? -$r : $r;
    $c1p = $c1 - $rr * sqrt( $a1*$a1 + $b1*$b1 );
    $rr  = ( $d2 <= 0.0 ) ? -$r : $r;
    $c2p = $c2 - $rr * sqrt( $a2*$a2 + $b2*$b2 );
    $d   = $a1*$b2 - $a2*$b1;
    $xc  = ( $c2p*$b1 - $c1p*$b2 ) / $d;
    $yc  = ( $c1p*$a2 - $c2p*$a1 ) / $d;
    $pcx = $xc;
    $pcy = $yc;
    ( $xa, $ya ) = $self->_pointperp( $a1, $b1, $c1, $pcx, $pcy );
    ( $xb, $yb ) = $self->_pointperp( $a2, $b2, $c2, $pcx, $pcy );
    $p2x  = $xa;  $p2y  = $ya;
    $p3x  = $xb;  $p3y  = $yb;
    $gv1x = $xa - $xc;  $gv1y = $ya - $yc;
    $gv2x = $xb - $xc;  $gv2y = $yb - $yc;
    $pa   = atan2( $gv1y, $gv1x );
    $aa   = $self->_dot2( $gv1x, $gv1y, $gv2x, $gv2y );
    if ( $self->_cross2( $gv1x, $gv1y, $gv2x, $gv2y ) < 0.0 ) { $aa = -$aa }
    return ( $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y,
             $xc, $yc, $pa * $R2D, $aa * $R2D );
}


# ===========================================================================
# FLOATING-POINT UTILITIES
# ===========================================================================

# Floating-point absolute value.
sub _fabs ($val) {
    return ( $val >= 0.0 ) ? $val : -$val;
}

# Floating-point equality within $EPSILON.
sub _feq ($x, $y) {
    return ( _fabs( $x - $y ) < $EPSILON ) ? 1 : 0;
}

# Square of the Euclidean distance between two points.
sub _calc_sq_distance ($x1, $y1, $x2, $y2) {
    return ( $x2 - $x1 )**2 + ( $y2 - $y1 )**2;
}


# ===========================================================================
# UNIT CONVERSION
# ===========================================================================

# Convert a value in PostScript points to the current drawing unit.
sub _pt_unitfied ($self, $p) {
    return $p * $inches_to_unit{ $self->{units} } / $inches_to_unit{pt};
}

# Convert a value in inches to the current drawing unit.
sub _in_unitfied ($self, $p) {
    return $p * $inches_to_unit{ $self->{units} };
}


# ===========================================================================
# ANGLE CONVERSION (public utility functions)
# ===========================================================================

# Convert degrees to radians.
sub radians ($deg) { return $deg * $D2R }

# Convert radians to degrees.
sub degrees ($rad) { return $rad / $D2R }


# ===========================================================================
# SEGMENT INTERSECTION (Cramer's Rule)
# ===========================================================================

# Return the parametric intersection parameter t of two line segments,
# or 0 if they do not intersect.  Touching segments are not considered to intersect.
#
# Theory (parametric line representation):
#   P  = P1 + k(P2-P1)         Q  = P3 + l(P4-P3)
#   Intersection when P=Q:
#       k = [ (x4-x3)(y1-y3) - (y4-y3)(x1-x3) ] / denom
#       l = [ (x2-x1)(y1-y3) - (y2-y1)(x1-x3) ] / denom
#   where denom = (y4-y3)(x2-x1) - (x4-x3)(y2-y1)
#   Intersection is valid when both k and l are in (0,1).
sub _getsegintersect ($self, $p0x, $p0y, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y) {
    my ( $s02x, $s02y, $s10x, $s10y, $s32x, $s32y, $s_numer, $t_numer, $denom );
    $s10x  = $p1x - $p0x;
    $s10y  = $p1y - $p0y;
    $s32x  = $p3x - $p2x;
    $s32y  = $p3y - $p2y;
    $denom = $s10x * $s32y - $s32x * $s10y;
    return 0 if $denom == 0;    # collinear
    my $denomPositive = ( $denom > 0 );
    $s02x    = $p0x - $p2x;
    $s02y    = $p0y - $p2y;
    $s_numer = $s10x * $s02y - $s10y * $s02x;
    return 0 if ( ( $s_numer < 0 ) == $denomPositive );
    $t_numer = $s32x * $s02y - $s32y * $s02x;
    return 0 if ( ( $t_numer < 0 ) == $denomPositive );
    return 0 if (  ( $s_numer > $denom ) == $denomPositive
                || ( $t_numer > $denom ) == $denomPositive );
    return $t_numer / $denom;
}


# ===========================================================================
# LIANG-BARSKY LINE CLIPPING
# ===========================================================================

# Clip a line segment to an axis-aligned rectangle.
#
# ($x1,$y1,$x2,$y2,$info) =
#     $obj->_LiangBarsky($botx,$boty,$topx,$topy, $x0src,$y0src,$x1src,$y1src);
#
# $info values:
#   1  entire segment inside boundary
#   2  entirely outside (returns -1,-1,-1,-1,2)
#   3  start inside, end clipped
#   4  end inside, start clipped
#   5  both endpoints outside but interior intersects
#
# Algorithm by Daniel White (skytopia.com), bug-fixed and translated to Perl.
sub _LiangBarsky ($self, $botx, $boty, $topx, $topy, $x0src, $y0src, $x1src, $y1src) {
    my $t0     = 0.0;
    my $t1     = 1.0;
    my $xdelta = $x1src - $x0src;
    my $ydelta = $y1src - $y0src;
    my ( $p, $q, $r );
    my $info = 0;
    foreach my $edge ( 0 .. 3 ) {
        if ( $edge == 0 ) { $p = -$xdelta; $q = -( $botx - $x0src ) }
        if ( $edge == 1 ) { $p =  $xdelta; $q =    $topx - $x0src   }
        if ( $edge == 2 ) { $p = -$ydelta; $q = -( $boty - $y0src ) }
        if ( $edge == 3 ) { $p =  $ydelta; $q =    $topy - $y0src   }
        if ( $p == 0 && $q < 0 ) {
            return ( -1, -1, -1, -1, 2 );    # parallel and outside
        }
        if ( $p < 0 ) {
            $r = 1.0 * $q / $p;
            return ( -1, -1, -1, -1, 2 ) if $r > $t1;
            $t0 = $r if $r > $t0;            # clip start
        }
        elsif ( $p > 0 ) {
            $r = 1.0 * $q / $p;
            return ( -1, -1, -1, -1, 2 ) if $r < $t0;
            $t1 = $r if $r < $t1;            # clip end
        }
    }
    $info = 1 if $t0 == 0.0 && $t1 == 1.0;
    $info = 3 if $t0 == 0.0 && $t1 != 1.0;
    $info = 4 if $t0 != 0.0 && $t1 == 1.0;
    $info = 5 if $t0 != 0.0 && $t1 != 1.0;
    return (
        $x0src + $t0 * $xdelta,
        $y0src + $t0 * $ydelta,
        $x0src + $t1 * $xdelta,
        $y0src + $t1 * $ydelta,
        $info,
    );
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Geometry2D - Geometric primitives and transformations for GcodeXY

=head1 SYNOPSIS

    $g->moveto(10, 20);
    $g->line(30, 40);
    $g->circle(50, 50, 10);
    $g->rotate(45);
    $g->arc(0, 0, 5, 0, 180);

=head1 DESCRIPTION

A L<Role::Tiny> role providing all geometric drawing primitives,
coordinate-system transformations, and clipping routines for
L<Graphics::Penplotter::GcodeXY>.

=head2 Coordinate spaces

Three coordinate spaces are used:

=over 4

=item User space

The result of scaling, rotation, and translation applied by the caller.
Methods such as C<translate>, C<rotate>, and C<scale> manipulate the
Current Transformation Matrix (CTM) that maps user to paper space.

=item Paper space

Absolute position on the page.  Found by applying the CTM to user
coordinates.

=item Device space

Physical inches.  Found by multiplying paper coordinates by C<dscale>.

=back

=head1 METHODS

All the public drawing methods (C<moveto>, C<line>, C<polygon>, C<box>,
C<curve>, C<arc>, C<circle>, C<ellipse>, C<rotate>, C<translate>,
C<scale>, etc.) as well as the graphics-state methods C<gsave> and
C<grestore> are provided by this role.

The line-clipping functions C<_getsegintersect> (Cramer's Rule) and
C<_LiangBarsky> (Liang-Barsky rectangle clipping) are also included here
since they are pure geometric computations.

=head1 REQUIRED METHODS

This role requires the consuming class to provide:
C<penup>, C<pendown>, C<_genfastmove>, C<_genslowmove>,
C<stroke>, C<_croak>, C<_penlock>, C<_penunlock>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
