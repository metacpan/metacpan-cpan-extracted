use v5.40;
use blib;
use LibUI qw[:all];

# Grid Layout Demo - demonstrates uiNewGrid, uiGridAppend
my $mainwin;
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Grid Layout Demo', 500, 400, 0 );
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
    $mainwin
);
uiWindowSetMargined( $mainwin, 1 );

# Main vertical box
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );

# Grid 1: Simple 2x3 grid
my $grp1 = uiNewGroup('Simple 2x3 Grid');
uiGroupSetMargined( $grp1, 1 );
uiBoxAppend( $vbox, $grp1, 0 );
my $inner1 = uiNewVerticalBox();
uiBoxSetPadded( $inner1, 1 );
uiGroupSetChild( $grp1, $inner1 );
my $grid1 = uiNewGrid();
uiGridSetPadded( $grid1, 1 );
uiBoxAppend( $inner1, $grid1, 0 );

# Row 0
uiGridAppend( $grid1, uiNewButton('Row 0, Col 0'), 0, 0, 1, 1, 0, 0, 0, 0 );
uiGridAppend( $grid1, uiNewButton('Row 0, Col 1'), 1, 0, 1, 1, 0, 0, 0, 0 );

# Row 1
uiGridAppend( $grid1, uiNewButton('Row 1, Col 0'), 0, 1, 1, 1, 0, 0, 0, 0 );
uiGridAppend( $grid1, uiNewButton('Row 1, Col 1'), 1, 1, 1, 1, 0, 0, 0, 0 );

# Row 2
uiGridAppend( $grid1, uiNewButton('Row 2, Col 0'), 0, 2, 1, 1, 0, 0, 0, 0 );
uiGridAppend( $grid1, uiNewButton('Row 2, Col 1'), 1, 2, 1, 1, 0, 0, 0, 0 );

# Grid 2: Spanning cells
my $grp2 = uiNewGroup('Spanning Cells');
uiGroupSetMargined( $grp2, 1 );
uiBoxAppend( $vbox, $grp2, 1 );
my $inner2 = uiNewVerticalBox();
uiBoxSetPadded( $inner2, 1 );
uiGroupSetChild( $grp2, $inner2 );
my $grid2 = uiNewGrid();
uiGridSetPadded( $grid2, 1 );
uiBoxAppend( $inner2, $grid2, 1 );

# Spans 2 columns
uiGridAppend( $grid2, uiNewButton('Spans 2 columns (0,0)'), 0, 0, 2, 1, 0, 0, 0, 0 );

# Single cell
uiGridAppend( $grid2, uiNewButton('Cell (2,0)'), 2, 0, 1, 1, 0, 0, 0, 0 );

# Spans 2 rows
uiGridAppend( $grid2, uiNewButton("Spans\n2 rows"), 0, 1, 1, 2, 0, 0, 0, 0 );

# Fills remaining
uiGridAppend( $grid2, uiNewButton('Fills (1,1)'), 1, 1, 2, 1, 1, 1, 0, 0 );
uiGridAppend( $grid2, uiNewButton('Fills (1,2)'), 1, 2, 2, 1, 1, 1, 0, 0 );

# Grid 3: Stretchy controls
my $grp3 = uiNewGroup('Stretchy Grid');
uiGroupSetMargined( $grp3, 1 );
uiBoxAppend( $vbox, $grp3, 1 );
my $inner3 = uiNewVerticalBox();
uiBoxSetPadded( $inner3, 1 );
uiGroupSetChild( $grp3, $inner3 );
my $grid3 = uiNewGrid();
uiGridSetPadded( $grid3, 1 );
uiBoxAppend( $inner3, $grid3, 1 );

# Top-left: fixed
uiGridAppend( $grid3, uiNewButton('Fixed'), 0, 0, 1, 1, 0, 0, 0, 0 );

# Top-right: stretches horizontally
uiGridAppend( $grid3, uiNewButton('StretchX'), 1, 0, 1, 1, 1, 0, 0, 0 );

# Bottom-left: stretches vertically
uiGridAppend( $grid3, uiNewButton('StretchY'), 0, 1, 1, 1, 0, 1, 0, 0 );

# Bottom-right: stretches both
uiGridAppend( $grid3, uiNewButton('StretchXY'), 1, 1, 1, 1, 1, 1, 0, 0 );
uiControlShow($mainwin);
uiMain();
