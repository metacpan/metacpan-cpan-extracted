use v5.40;
use blib;
use LibUI qw[:all];

# Graph Demo - plots sin(x) from table data, redraws on edit
use constant PI => 3.14159265358979;
use constant { X_OFF_LEFT => 40, Y_OFF_TOP => 20, X_OFF_RIGHT => 20, Y_OFF_BOTTOM => 30, NUM_POINTS => 20 };
my $mainwin;
my $area;
my $combobox;
my @data_points;    # spinbox widgets for y values
my @data_values;    # current y values (cached)
my @functions = (
    { name => 'sin(x)',          fn => sub { sin( $_[0] ) } },
    { name => 'cos(x)',          fn => sub { cos( $_[0] ) } },
    { name => 'sin(x)+cos(x)/2', fn => sub { sin( $_[0] ) + cos( $_[0] ) / 2 } },
    { name => '|sin(x)|',        fn => sub { abs( sin( $_[0] ) ) } },
    { name => 'x mod 3',         fn => sub { $_[0] % 3 } }
);
my $current_fn = 0;

sub refresh_values() {
    my $fn = $functions[$current_fn]{fn};
    for my $i ( 0 .. NUM_POINTS - 1 ) {
        my $x = $i / ( NUM_POINTS - 1 ) * 4 * PI - 2 * PI;
        my $y = $fn->($x);

        # Map -1..1 to 0..100 for spinbox
        my $mapped = int( ( $y + 1 ) / 2 * 100 );
        $mapped = 0   if $mapped < 0;
        $mapped = 100 if $mapped > 100;
        uiSpinboxSetValue( $data_points[$i], $mapped );
        $data_values[$i] = $mapped;
    }
}
sub graph_size( $area_w, $area_h ) { $area_w - X_OFF_LEFT - X_OFF_RIGHT, $area_h - Y_OFF_TOP - Y_OFF_BOTTOM }
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Graph', 700, 500, 0 );
uiWindowSetMargined( $mainwin, 1 );
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
my $hbox = uiNewHorizontalBox();
uiBoxSetPadded( $hbox, 1 );
uiWindowSetChild( $mainwin, $hbox );

# Left panel: controls
my $ctrl = uiNewVerticalBox();
uiBoxSetPadded( $ctrl, 1 );
uiBoxAppend( $hbox, $ctrl, 0 );

# Function selector
uiBoxAppend( $ctrl, uiNewLabel('Function:'), 0 );
$combobox = uiNewCombobox();
for my $f (@functions) {
    uiComboboxAppend( $combobox, $f->{name} );
}
uiComboboxSetSelected( $combobox, 0 );
uiComboboxOnSelected(
    $combobox,
    sub {
        $current_fn = uiComboboxSelected($combobox);
        refresh_values();
        uiAreaQueueRedrawAll($area);
    },
    undef
);
uiBoxAppend( $ctrl, $combobox,                             0 );
uiBoxAppend( $ctrl, uiNewHorizontalSeparator(),            0 );
uiBoxAppend( $ctrl, uiNewLabel('Data points (editable):'), 0 );

# Create spinboxes for data points
for my $i ( 0 .. NUM_POINTS - 1 ) {
    my $sb = uiNewSpinbox( 0, 100 );
    uiSpinboxOnChanged(
        $sb,
        sub {
            $data_values[$i] = uiSpinboxValue($sb);
            uiAreaQueueRedrawAll($area);
        },
        undef
    );
    push @data_points, $sb;
    push @data_values, 50;
    uiBoxAppend( $ctrl, $sb, 0 );
}

# Graph area
$area = uiNewArea(
    {   Draw => sub ( $ah, $a, $p ) {
            my $dc = $p->{Context};
            my $w  = $p->{AreaWidth};
            my $h  = $p->{AreaHeight};
            my ( $gw, $gh ) = graph_size( $w, $h );

            # White background
            my $bg = uiDrawNewPath(0);
            uiDrawPathAddRectangle( $bg, 0, 0, $w, $h );
            uiDrawPathEnd($bg);
            uiDrawFill( $dc, $bg, solid_brush( 1.0, 1.0, 1.0, 1.0 ) );
            uiDrawFreePath($bg);

            # Grid lines (minor)
            my $grid = uiDrawNewPath(0);
            for my $i ( 1 .. 9 ) {
                my $x = $gw * $i / 10;
                uiDrawPathNewFigure( $grid, $x, 0 );
                uiDrawPathLineTo( $grid, $x, $gh );
            }
            for my $i ( 1 .. 4 ) {
                my $y = $gh * $i / 5;
                uiDrawPathNewFigure( $grid, 0, $y );
                uiDrawPathLineTo( $grid, $gw, $y );
            }
            uiDrawPathEnd($grid);
            uiDrawStroke( $dc, $grid, solid_brush( 0.90, 0.90, 0.90, 1.0 ), draw_stroke( thickness => 0.5 ) );
            uiDrawFreePath($grid);

            # Axes
            my $dsp = draw_stroke( cap => 0, join => 0, thickness => 1.5 );

            # X axis (at y = 50%)
            my $xaxis = uiDrawNewPath(0);
            uiDrawPathNewFigure( $xaxis, 0, $gh / 2 );
            uiDrawPathLineTo( $xaxis, $gw, $gh / 2 );
            uiDrawPathEnd($xaxis);
            uiDrawStroke( $dc, $xaxis, solid_brush( 0.3, 0.3, 0.3, 1.0 ), $dsp );
            uiDrawFreePath($xaxis);

            # Y axis
            my $yaxis = uiDrawNewPath(0);
            uiDrawPathNewFigure( $yaxis, 0, 0 );
            uiDrawPathLineTo( $yaxis, 0, $gh );
            uiDrawPathEnd($yaxis);
            uiDrawStroke( $dc, $yaxis, solid_brush( 0.3, 0.3, 0.3, 1.0 ), $dsp );
            uiDrawFreePath($yaxis);

            # Tick marks on axes
            for my $i ( 0 .. NUM_POINTS - 1 ) {
                my $x    = $gw * $i / ( NUM_POINTS - 1 );
                my $tick = uiDrawNewPath(0);
                uiDrawPathNewFigure( $tick, $x, $gh / 2 - 3 );
                uiDrawPathLineTo( $tick, $x, $gh / 2 + 3 );
                uiDrawPathEnd($tick);
                uiDrawStroke( $dc, $tick, solid_brush( 0.5, 0.5, 0.5, 1.0 ), draw_stroke( thickness => 0.8 ) );
                uiDrawFreePath($tick);
            }

            # Fill under curve
            my $fill_path = uiDrawNewPath(0);
            my $x0        = 0;
            my $y0        = $gh - ( $data_values[0] / 100.0 ) * $gh;
            uiDrawPathNewFigure( $fill_path, $x0, $y0 );
            for my $i ( 1 .. NUM_POINTS - 1 ) {
                my $x = $gw * $i / ( NUM_POINTS - 1 );
                my $y = $gh - ( $data_values[$i] / 100.0 ) * $gh;
                uiDrawPathLineTo( $fill_path, $x, $y );
            }
            uiDrawPathLineTo( $fill_path, $gw, $gh / 2 );
            uiDrawPathLineTo( $fill_path, 0,   $gh / 2 );
            uiDrawPathCloseFigure($fill_path);
            uiDrawPathEnd($fill_path);
            uiDrawFill( $dc, $fill_path, solid_brush( 0.2, 0.5, 0.8, 0.15 ) );
            uiDrawFreePath($fill_path);

            # Stroke the curve
            my $stroke_path = uiDrawNewPath(0);
            my $sx0         = 0;
            my $sy0         = $gh - ( $data_values[0] / 100.0 ) * $gh;
            uiDrawPathNewFigure( $stroke_path, $sx0, $sy0 );
            for my $i ( 1 .. NUM_POINTS - 1 ) {
                my $x = $gw * $i / ( NUM_POINTS - 1 );
                my $y = $gh - ( $data_values[$i] / 100.0 ) * $gh;
                uiDrawPathLineTo( $stroke_path, $x, $y );
            }
            uiDrawPathEnd($stroke_path);
            uiDrawStroke( $dc, $stroke_path, solid_brush( 0.2, 0.5, 0.8, 1.0 ), draw_stroke( thickness => 2.0, cap => 1 ) );
            uiDrawFreePath($stroke_path);

            # Data point dots
            for my $i ( 0 .. NUM_POINTS - 1 ) {
                my $x   = $gw * $i / ( NUM_POINTS - 1 );
                my $y   = $gh - ( $data_values[$i] / 100.0 ) * $gh;
                my $dot = uiDrawNewPath(0);
                uiDrawPathNewFigureWithArc( $dot, $x, $y, 3, 0, 2 * PI, 0 );
                uiDrawPathEnd($dot);
                uiDrawFill( $dc, $dot, solid_brush( 0.2, 0.5, 0.8, 1.0 ) );
                uiDrawFreePath($dot);
            }
        }
    }
);
uiBoxAppend( $hbox, $area, 1 );

# Load initial function
refresh_values();
uiControlShow($mainwin);
uiMain();
