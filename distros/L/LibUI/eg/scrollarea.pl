use v5.40;
use blib;
use LibUI qw[:all];

# Canvas constants
my $CANVAS_W = 3000;
my $CANVAS_H = 2000;

# Territory shapes (pre-generated random polygons)
# Each territory: name, center, polygon vertices [{x,y},...], color
sub make_polygon ( $cx, $cy, $avg_r, $nverts ) {
    my @verts;
    for my $i ( 0 .. $nverts - 1 ) {
        my $angle = 6.2832 * $i / $nverts + ( rand() - 0.5 ) * 0.6;
        my $r     = $avg_r * ( 0.65 + rand() * 0.70 );
        push @verts, { x => $cx + $r * cos($angle), y => $cy + $r * sin($angle) };
    }
    return @verts;
}
my @territories = (
    { name => 'North Forest',    cx => 400,  cy => 280,  r => 0.25, g => 0.70, b => 0.35 },
    { name => 'East Mountains',  cx => 1050, cy => 500,  r => 0.60, g => 0.50, b => 0.40 },
    { name => 'South Desert',    cx => 550,  cy => 950,  r => 0.90, g => 0.80, b => 0.35 },
    { name => 'West Ocean',      cx => 240,  cy => 750,  r => 0.25, g => 0.45, b => 0.90 },
    { name => 'Central City',    cx => 1225, cy => 725,  r => 0.70, g => 0.70, b => 0.72 },
    { name => 'Northwest Lake',  cx => 355,  cy => 1175, r => 0.30, g => 0.60, b => 0.90 },
    { name => 'SE Hills',        cx => 1200, cy => 1200, r => 0.50, g => 0.80, b => 0.40 },
    { name => 'Far East Plains', cx => 1950, cy => 575,  r => 0.80, g => 0.88, b => 0.50 },
    { name => 'North Tundra',    cx => 1675, cy => 190,  r => 0.80, g => 0.88, b => 1.00 },
    { name => 'South Jungle',    cx => 975,  cy => 1550, r => 0.15, g => 0.60, b => 0.25 },
    { name => 'Grand Canyon',    cx => 2150, cy => 1325, r => 0.75, g => 0.40, b => 0.25 },
    { name => 'Crystal Peaks',   cx => 2250, cy => 300,  r => 0.55, g => 0.65, b => 0.85 }
);

# Generate random polygon vertices for each territory
for my $t (@territories) {
    my $avg_r  = 200 + rand(120);
    my $nverts = 5 + int( rand(4) );    # 5-8 vertices
    $t->{verts} = [ make_polygon( $t->{cx}, $t->{cy}, $avg_r, $nverts ) ];

    # Compute bounding box for hit-test fast-reject
    my ( $minx, $miny, $maxx, $maxy ) = ( 1e9, 1e9, -1e9, -1e9 );
    for my $v ( @{ $t->{verts} } ) {
        $minx = $v->{x} if $v->{x} < $minx;
        $miny = $v->{y} if $v->{y} < $miny;
        $maxx = $v->{x} if $v->{x} > $maxx;
        $maxy = $v->{y} if $v->{y} > $maxy;
    }
    $t->{bbox} = [ $minx, $miny, $maxx, $maxy ];
}

# State
my $hovered_idx = -1;
my ( $mouse_x,     $mouse_y ) = ( 0, 0 );
my ( $mainwin,     $area );
my ( $coord_label, $region_label );

# Point-in-polygon (ray casting)
sub point_in_polygon ( $px, $py, $verts ) {
    my $n      = @$verts;
    my $inside = 0;
    for my $i ( 0 .. $n - 1 ) {
        my $j = ( $i + 1 ) % $n;
        my ( $xi, $yi ) = ( $verts->[$i]{x}, $verts->[$i]{y} );
        my ( $xj, $yj ) = ( $verts->[$j]{x}, $verts->[$j]{y} );
        if ( ( $yi > $py ) != ( $yj > $py ) && $px < ( $xj - $xi ) * ( $py - $yi ) / ( $yj - $yi ) + $xi ) {
            $inside = !$inside;
        }
    }
    return $inside;
}

sub find_territory ( $x, $y ) {
    for my $i ( 0 .. $#territories ) {
        my $t = $territories[$i];

        # Fast reject with bounding box
        my ( $minx, $miny, $maxx, $maxy ) = @{ $t->{bbox} };
        next unless $x >= $minx && $x <= $maxx && $y >= $miny && $y <= $maxy;
        return $i if point_in_polygon( $x, $y, $t->{verts} );
    }
    return -1;
}

# Area callbacks
sub on_draw ( $ah, $a, $p ) {
    my $dc = $p->{Context};

    # Pparchment background
    my $bg = uiDrawNewPath(0);
    uiDrawPathAddRectangle( $bg, 0, 0, $CANVAS_W, $CANVAS_H );
    uiDrawPathEnd($bg);
    uiDrawFill( $dc, $bg, solid_brush( 0.96, 0.94, 0.88 ) );
    uiDrawFreePath($bg);

    # Minor grid (every 100px)
    my $minor = uiDrawNewPath(0);
    for my $x ( grep { $_ % 500 != 0 } 100 .. $CANVAS_W - 100 ) {
        uiDrawPathNewFigure( $minor, $x, 0 );
        uiDrawPathLineTo( $minor, $x, $CANVAS_H );
    }
    for my $y ( grep { $_ % 500 != 0 } 100 .. $CANVAS_H - 100 ) {
        uiDrawPathNewFigure( $minor, 0, $y );
        uiDrawPathLineTo( $minor, $CANVAS_W, $y );
    }
    uiDrawPathEnd($minor);
    uiDrawStroke( $dc, $minor, solid_brush( 0.88, 0.86, 0.82 ), draw_stroke( thickness => 0.5 ) );
    uiDrawFreePath($minor);

    # Major grid (every 500px)
    my $major = uiDrawNewPath(0);
    for my $x ( 0, 500, 1000, 1500, 2000, 2500, $CANVAS_W ) {
        uiDrawPathNewFigure( $major, $x, 0 );
        uiDrawPathLineTo( $major, $x, $CANVAS_H );
    }
    for my $y ( 0, 500, 1000, 1500, $CANVAS_H ) {
        uiDrawPathNewFigure( $major, 0, $y );
        uiDrawPathLineTo( $major, $CANVAS_W, $y );
    }
    uiDrawPathEnd($major);
    uiDrawStroke( $dc, $major, solid_brush( 0.75, 0.73, 0.68 ), draw_stroke( thickness => 1.5 ) );
    uiDrawFreePath($major);

    # Territories (random polygons)
    for my $i ( 0 .. $#territories ) {
        my $t          = $territories[$i];
        my $is_hovered = ( $hovered_idx == $i );
        my $verts      = $t->{verts};

        # Fill polygon
        my $fill = uiDrawNewPath(0);
        uiDrawPathNewFigure( $fill, $verts->[0]{x}, $verts->[0]{y} );
        for my $v ( @$verts[ 1 .. $#$verts ] ) {
            uiDrawPathLineTo( $fill, $v->{x}, $v->{y} );
        }
        uiDrawPathCloseFigure($fill);
        uiDrawPathEnd($fill);
        uiDrawFill( $dc, $fill, solid_brush( $t->{r}, $t->{g}, $t->{b}, $is_hovered ? 0.75 : 0.55 ) );
        uiDrawFreePath($fill);

        # Border
        my $border = uiDrawNewPath(0);
        uiDrawPathNewFigure( $border, $verts->[0]{x}, $verts->[0]{y} );
        for my $v ( @$verts[ 1 .. $#$verts ] ) {
            uiDrawPathLineTo( $border, $v->{x}, $v->{y} );
        }
        uiDrawPathCloseFigure($border);
        uiDrawPathEnd($border);
        uiDrawStroke(
            $dc, $border,
            solid_brush( $is_hovered ? 0.9 : 0.3, $is_hovered ? 0.1 : 0.2, $is_hovered ? 0.1 : 0.15 ),
            draw_stroke( thickness => $is_hovered ? 3.5 : 1.2 )
        );
        uiDrawFreePath($border);

        # Capital marker
        my $dot = uiDrawNewPath(0);
        uiDrawPathNewFigureWithArc( $dot, $t->{cx}, $t->{cy}, $is_hovered ? 8 : 5, 0, 6.283, 0 );
        uiDrawPathEnd($dot);
        uiDrawFill( $dc, $dot, solid_brush( 0.1, 0.1, 0.1 ) );
        uiDrawFreePath($dot);

        # libui doesn't have text drawing in areas, so we rely on the hover label
    }

    # Border of entire map
    my $frame = uiDrawNewPath(0);
    uiDrawPathAddRectangle( $frame, 0, 0, $CANVAS_W, $CANVAS_H );
    uiDrawPathEnd($frame);
    uiDrawStroke( $dc, $frame, solid_brush( 0.3, 0.3, 0.3 ), draw_stroke( thickness => 3 ) );
    uiDrawFreePath($frame);
}

sub on_mouse_event ( $ah, $a, $ev ) {
    $mouse_x = $ev->{X};
    $mouse_y = $ev->{Y};
    uiLabelSetText( $coord_label, sprintf 'Mouse: (%.0f, %.0f)', $mouse_x, $mouse_y );
    my $idx = find_territory( $mouse_x, $mouse_y );
    if ( $idx != $hovered_idx ) {
        $hovered_idx = $idx;
        if ( $idx >= 0 ) {
            uiLabelSetText( $region_label, "Region: $territories[$idx]{name}" );
        }
        else {
            uiLabelSetText( $region_label, 'Region: --' );
        }
        uiAreaQueueRedrawAll($a);
    }
}

sub on_mouse_crossed ( $ah, $a, $left ) {
    if ($left) {
        $hovered_idx = -1;
        uiLabelSetText( $coord_label,  'Mouse: --' );
        uiLabelSetText( $region_label, 'Region: --' );
        uiAreaQueueRedrawAll($a);
    }
}
sub on_drag_broken ( $ah, $a )     { }
sub on_key_event   ( $ah, $a, $e ) { return 0; }
sub on_closing     ( $w, $data )   { uiQuit();                return 1; }
sub should_quit    ($data)         { uiControlHide($mainwin); return 1; }
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Map Explorer', 920, 620, 0 );
uiWindowSetMargined( $mainwin, 1 );
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, $mainwin );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );

# Info bar
my $info = uiNewLabel( "Canvas: ${CANVAS_W}x${CANVAS_H}  |  " . scalar(@territories) . ' territories  |  Hover to highlight' );
uiBoxAppend( $vbox, $info, 0 );

# Status bar
my $sbox = uiNewHorizontalBox();
uiBoxSetPadded( $sbox, 1 );
uiBoxAppend( $vbox, $sbox, 0 );
$coord_label  = uiNewLabel('Mouse: --');
$region_label = uiNewLabel('Region: --');
uiBoxAppend( $sbox, $coord_label,  0 );
uiBoxAppend( $sbox, $region_label, 0 );

# Scrolling Area
$area = uiNewScrollingArea( { Draw => \&on_draw, MouseEvent => \&on_mouse_event, }, $CANVAS_W, $CANVAS_H );
uiBoxAppend( $vbox, $area, 1 );
#
uiControlShow($mainwin);
uiMain();
