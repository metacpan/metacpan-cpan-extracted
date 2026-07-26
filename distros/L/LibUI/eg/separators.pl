use v5.40;
use blib;
use LibUI qw[:all];
#
uiInit( { Size => 0 } );
#
my $main = uiNewWindow( 'uiSeparator', 400, 300, 0 );
uiWindowOnClosing( $main, sub { uiQuit(); return 1 }, undef );
uiWindowSetMargined( $main, 1 );
#
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $main, $vbox );
#
uiBoxAppend( $vbox, uiNewLabel('Section 1'), 0 );
uiBoxAppend( $vbox, uiNewEntry(),            0 );
#
uiBoxAppend( $vbox, uiNewHorizontalSeparator(), 0 );
#
uiBoxAppend( $vbox, uiNewLabel('Section 2'),   0 );
uiBoxAppend( $vbox, uiNewCheckbox('Option A'), 0 );
uiBoxAppend( $vbox, uiNewCheckbox('Option B'), 0 );
#
uiBoxAppend( $vbox, uiNewHorizontalSeparator(), 0 );
#
uiBoxAppend( $vbox, uiNewLabel('Section 3'), 0 );

# Vertical separator example: side-by-side panels
my $hbox = uiNewHorizontalBox();
uiBoxSetPadded( $hbox, 1 );
uiBoxAppend( $vbox, $hbox, 1 );
#
uiBoxAppend( $hbox, uiNewLabel('Left'),       1 );
uiBoxAppend( $hbox, uiNewVerticalSeparator(), 0 );
uiBoxAppend( $hbox, uiNewLabel('Right'),      1 );
#
uiControlShow($main);
uiMain();
