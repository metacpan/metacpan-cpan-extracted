use v5.40;
use blib;
use LibUI qw[:all];

# Port of upstream libui-ng timer example
uiInit( { Size => 0 } );
my $win = uiNewWindow( 'Timer', 320, 240, 0 );
uiWindowSetMargined( $win, 1 );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $win, $vbox );
my $entry = uiNewMultilineEntry();
uiMultilineEntrySetReadOnly( $entry, 1 );
my $btn = uiNewButton('Say Something');
uiButtonOnClicked(
    $btn,
    sub {
        uiMultilineEntryAppend( $entry, "Saying something\n" );
    },
    undef
);
uiBoxAppend( $vbox, $btn,   0 );
uiBoxAppend( $vbox, $entry, 1 );
uiTimer(
    1000,
    sub {
        my $t = scalar localtime;
        uiMultilineEntryAppend( $entry, "$t\n" );
        return 1;    # keep timer running
    },
    undef
);
uiWindowOnClosing(
    $win,
    sub {
        uiQuit();
        return 1;
    },
    undef
);
#
uiControlShow($win);
uiMain();
