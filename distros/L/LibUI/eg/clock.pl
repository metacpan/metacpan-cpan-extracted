use v5.40;
use blib;
use LibUI       qw[:all];
use Time::HiRes qw[gettimeofday];

# Animated analog clock using uiArea and uiTimer
use constant PI => 3.14159265358979;
my $mainwin;
my $area;

sub draw_hand( $dc, $cx, $cy, $length, $angle, $thickness, $color ) {
    my $end_x = $cx + $length * sin($angle);
    my $end_y = $cy - $length * cos($angle);
    my $path  = uiDrawNewPath(0);
    uiDrawPathNewFigure( $path, $cx, $cy );
    uiDrawPathLineTo( $path, $end_x, $end_y );
    uiDrawPathEnd($path);
    uiDrawStroke( $dc, $path, solid_brush(@$color), draw_stroke( thickness => $thickness, cap => 1 ) );
    uiDrawFreePath($path);
}

sub draw_circle( $dc, $cx, $cy, $r, $color ) {
    my $path = uiDrawNewPath(0);
    uiDrawPathNewFigureWithArc( $path, $cx, $cy, $r, 0, 2 * PI, 0 );
    uiDrawPathEnd($path);
    uiDrawFill( $dc, $path, solid_brush(@$color) );
    uiDrawFreePath($path);
}

sub draw_tick( $dc, $cx, $cy, $outer_r, $inner_r, $angle, $color ) {
    my $x1   = $cx + $inner_r * sin($angle);
    my $y1   = $cy - $inner_r * cos($angle);
    my $x2   = $cx + $outer_r * sin($angle);
    my $y2   = $cy - $outer_r * cos($angle);
    my $path = uiDrawNewPath(0);
    uiDrawPathNewFigure( $path, $x1, $y1 );
    uiDrawPathLineTo( $path, $x2, $y2 );
    uiDrawPathEnd($path);
    uiDrawStroke( $dc, $path, solid_brush(@$color), draw_stroke( thickness => 1.5 ) );
    uiDrawFreePath($path);
}
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Clock', 400, 400, 0 );
uiWindowSetMargined( $mainwin, 1 );
uiWindowSetResizeable( $mainwin, 1 );
uiWindowOnClosing(
    $mainwin,
    sub ( $w, $data ) {
        uiQuit();
        return 1;
    },
    undef
);
uiOnShouldQuit(
    sub ($data) {
        uiControlHide($mainwin);
        return 1;
    },
    undef
);
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );
$area = uiNewArea(
    {   Draw => sub ( $ah, $a, $p ) {
            my $dc     = $p->{Context};
            my $w      = $p->{AreaWidth};
            my $h      = $p->{AreaHeight};
            my $cx     = $w / 2;
            my $cy     = $h / 2;
            my $radius = ( $w < $h ? $w : $h ) / 2 - 20;

            # Background
            my $bg = uiDrawNewPath(0);
            uiDrawPathAddRectangle( $bg, 0, 0, $w, $h );
            uiDrawPathEnd($bg);
            uiDrawFill( $dc, $bg, solid_brush( 0.96, 0.96, 0.96, 1.0 ) );
            uiDrawFreePath($bg);

            # Clock face border
            my $face = uiDrawNewPath(0);
            uiDrawPathNewFigureWithArc( $face, $cx, $cy, $radius + 5, 0, 2 * PI, 0 );
            uiDrawPathEnd($face);
            uiDrawFill( $dc, $face, solid_brush( 1.0, 1.0, 1.0, 1.0 ) );
            uiDrawFreePath($face);
            my $border = uiDrawNewPath(0);
            uiDrawPathNewFigureWithArc( $border, $cx, $cy, $radius + 5, 0, 2 * PI, 0 );
            uiDrawPathEnd($border);
            uiDrawStroke( $dc, $border, solid_brush( 0.2, 0.2, 0.2, 1.0 ), draw_stroke( thickness => 2.0 ) );
            uiDrawFreePath($border);

            # Tick marks
            for my $i ( 0 .. 59 ) {
                my $angle = 2 * PI * $i / 60;
                my $outer = $radius - 5;
                my $inner = $i % 5 == 0 ? $radius - 18           : $radius - 10;
                my $thick = $i % 5 == 0 ? 2.0                    : 1.0;
                my $color = $i % 5 == 0 ? [ 0.2, 0.2, 0.2, 1.0 ] : [ 0.5, 0.5, 0.5, 1.0 ];
                draw_tick( $dc, $cx, $cy, $outer, $inner, $angle, $color );
            }

            # Hour numbers
            for my $i ( 1 .. 12 ) {
                my $angle = 2 * PI * $i / 12;
                my $num_r = $radius - 30;
                my $nx    = $cx + $num_r * sin($angle);
                my $ny    = $cy - $num_r * cos($angle);

                # Draw a dot at each hour position since we can't draw text in areas
                draw_circle( $dc, $nx, $ny, 3, [ 0.3, 0.3, 0.3, 1.0 ] );
            }

            # Get current time
            my ( $sec, $min, $hour ) = localtime();
            my $sec_angle  = 2 * PI * $sec / 60;
            my $min_angle  = 2 * PI * ( $min + $sec / 60 ) / 60;
            my $hour_angle = 2 * PI * ( $hour % 12 + $min / 60 ) / 12;

            # Hour hand
            draw_hand( $dc, $cx, $cy, $radius * 0.50, $hour_angle, 4.0, [ 0.2, 0.2, 0.2, 1.0 ] );

            # Minute hand
            draw_hand( $dc, $cx, $cy, $radius * 0.72, $min_angle, 2.5, [ 0.2, 0.2, 0.2, 1.0 ] );

            # Second hand
            draw_hand( $dc, $cx, $cy, $radius * 0.80, $sec_angle, 1.0, [ 0.8, 0.1, 0.1, 1.0 ] );

            # Center dot
            draw_circle( $dc, $cx, $cy, 4, [ 0.2, 0.2, 0.2, 1.0 ] );
        }
    }
);
uiBoxAppend( $vbox, $area, 1 );

# Timer to redraw every 100ms for smooth second hand movement
uiTimer(
    100,
    sub {
        uiAreaQueueRedrawAll($area);
        return 1;
    },
    undef
);
uiControlShow($mainwin);
uiMain();
