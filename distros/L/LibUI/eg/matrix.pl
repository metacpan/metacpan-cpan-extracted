use v5.40;
use blib;
use LibUI qw[:all];
$|++;
#
my $RED    = [ 0.9,  0.2,  0.2,  0.9 ];
my $GREEN  = [ 0.2,  0.7,  0.3,  0.9 ];
my $BLUE   = [ 0.2,  0.3,  0.9,  0.9 ];
my $ORANGE = [ 1.0,  0.6,  0.1,  0.9 ];
my $PURPLE = [ 0.6,  0.2,  0.8,  0.9 ];
my $LGRAY  = [ 0.85, 0.85, 0.85, 1.0 ];
my $DGRAY  = [ 0.3,  0.3,  0.3,  1.0 ];
#
sub grid ( $dc, $w, $h ) {
    my $step = 40;
    my $p    = uiDrawNewPath(0);
    for ( my $x = $step; $x < $w; $x += $step ) {
        uiDrawPathNewFigure( $p, $x, 0 );
        uiDrawPathLineTo( $p, $x, $h );
    }
    for ( my $y = $step; $y < $h; $y += $step ) {
        uiDrawPathNewFigure( $p, 0, $y );
        uiDrawPathLineTo( $p, $w, $y );
    }
    uiDrawPathEnd($p);
    uiDrawStroke( $dc, $p, solid_brush( $LGRAY->[0], $LGRAY->[1], $LGRAY->[2], $LGRAY->[3] ), draw_stroke( thickness => 0.5 ) );
    uiDrawFreePath($p);
    $p = uiDrawNewPath(0);
    uiDrawPathNewFigure( $p, 0, $h / 2 );
    uiDrawPathLineTo( $p, $w, $h / 2 );
    uiDrawPathNewFigure( $p, $w / 2, 0 );
    uiDrawPathLineTo( $p, $w / 2, $h );
    uiDrawPathEnd($p);
    uiDrawStroke( $dc, $p, solid_brush( $DGRAY->[0], $DGRAY->[1], $DGRAY->[2], $DGRAY->[3] ), draw_stroke( thickness => 1.5 ) );
    uiDrawFreePath($p);
}

sub square ( $dc, $s, $c ) {
    my $h = $s / 2;
    my $p = uiDrawNewPath(0);
    uiDrawPathAddRectangle( $p, -$h, -$h, $s, $s );
    uiDrawPathEnd($p);
    uiDrawFill( $dc, $p, solid_brush( $c->[0], $c->[1], $c->[2], $c->[3] ) );
    uiDrawFreePath($p);
}

sub cross( $dc, $s, $c ) {
    my $h = $s / 2;
    my $t = $s / 8;
    my $p = uiDrawNewPath(0);
    uiDrawPathAddRectangle( $p, -$h, -$t, $s,     $t * 2 );
    uiDrawPathAddRectangle( $p, -$t, -$h, $t * 2, $s );
    uiDrawPathEnd($p);
    uiDrawFill( $dc, $p, solid_brush( $c->[0], $c->[1], $c->[2], $c->[3] ) );
    uiDrawFreePath($p);
}

sub dot ( $dc, $x, $y, $c, $r ) {
    my $p = uiDrawNewPath(0);
    uiDrawPathNewFigureWithArc( $p, $x, $y, $r, 0, 6.283185307, 0 );
    uiDrawPathEnd($p);
    uiDrawFill( $dc, $p, solid_brush( $c->[0], $c->[1], $c->[2], $c->[3] ) );
    uiDrawFreePath($p);
}
my $angle = 0;
uiInit( { Size => 0 } );
my $main = uiNewWindow( 'uiDrawMatrix', 640, 480, 0 );
uiWindowOnClosing( $main, sub { uiQuit(); 1 }, undef );
uiWindowSetMargined( $main, 1 );
my $area = uiNewArea(
    {   Draw => sub ( $ah, $a, $p ) {
            my $dc = $p->{Context};
            my $w  = $p->{AreaWidth};
            my $h  = $p->{AreaHeight};
            my $bg = uiDrawNewPath(0);
            uiDrawPathAddRectangle( $bg, 0, 0, $w, $h );
            uiDrawPathEnd($bg);
            uiDrawFill( $dc, $bg, solid_brush( 0.96, 0.96, 0.96, 1.0 ) );
            uiDrawFreePath($bg);
            grid( $dc, $w, $h );
            my $cx = $w / 2;
            my $cy = $h / 2;

            # Reference crosshair at center
            uiDrawSave($dc);
            cross( $dc, 20, $DGRAY );
            uiDrawRestore($dc);

            # Translate (top-left)
            uiDrawSave($dc);
            {
                my $m = LibUI::Matrix->new();
                $m->translate( $cx - 120, $cy - 120 );
                $m->apply($dc);
                square( $dc, 40, $RED );
            }
            uiDrawRestore($dc);
            dot( $dc, $cx - 120, $cy - 120, $RED, 4 );

            # Scale 1.5x (top-right)
            uiDrawSave($dc);
            {
                my $m = LibUI::Matrix->identity();
                $m->translate( $cx + 80, $cy - 120 );
                $m->scale( $cx + 80, $cy - 120, 1.5, 1.5 );
                $m->apply($dc);
                square( $dc, 40, $GREEN );
            }
            uiDrawRestore($dc);
            dot( $dc, $cx + 80, $cy - 120, $GREEN, 4 );

            # Rotate (bottom-left, animated)
            uiDrawSave($dc);
            {
                my $m = LibUI::Matrix->identity();
                $m->translate( $cx - 120, $cy + 80 );
                $m->rotate( $cx - 120, $cy + 80, $angle );
                $m->apply($dc);
                square( $dc, 40, $BLUE );
            }
            uiDrawRestore($dc);
            dot( $dc, $cx - 120, $cy + 80, $BLUE, 4 );

            # Skew (bottom-right)
            uiDrawSave($dc);
            {
                my $m = LibUI::Matrix->identity();
                $m->translate( $cx + 80, $cy + 80 );
                $m->skew( $cx + 80, $cy + 80, 0.3, 0 );
                $m->apply($dc);
                square( $dc, 40, $ORANGE );
            }
            uiDrawRestore($dc);
            dot( $dc, $cx + 80, $cy + 80, $ORANGE, 4 );

            # Combined: translate + rotate + pulsing scale (center)
            uiDrawSave($dc);
            {
                my $sc = 0.5 + 0.4 * sin($angle);
                my $m  = LibUI::Matrix->identity();
                $m->translate( $cx, $cy );
                $m->rotate( $cx, $cy, $angle * 2 );
                $m->scale( $cx, $cy, $sc, $sc );
                $m->apply($dc);
                cross( $dc, 30, $PURPLE );
            }
            uiDrawRestore($dc);
            dot( $dc, $cx, $cy, $PURPLE, 4 );
        }
    }
);
uiWindowSetChild( $main, $area );
uiTimer(
    30,
    sub {
        $angle += 0.02;
        $angle -= 6.283185307 if $angle > 6.283185307;
        uiAreaQueueRedrawAll($area);
        return 1;
    },
    undef
);
uiControlShow($main);
uiMain();
