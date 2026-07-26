use v5.40;
use blib;
use LibUI qw[:all];

# Demonstrates all menu types: items, check items, separators, Preferences, About, Quit, and enable/disable
my $mainwin;
my $info_label;
my $mi_dynamic;
my $mi_disable_target;
my $check_item;
my $dynamic_enabled = 1;

sub on_closing( $w, $data ) {
    uiQuit();
    return 1;
}

sub should_quit($data) {
    uiControlHide($mainwin);
    return 1;
}

sub update_info() {
    my $state = $dynamic_enabled               ? 'Dynamic item enabled' : 'Dynamic item disabled';
    my $check = uiMenuItemChecked($check_item) ? 'checked'              : 'unchecked';
    uiLabelSetText( $info_label, "$state | Toggle item $check" );
}

# Menus must be created before windows when hasMenubar=1
uiInit( { Size => 0 } );

# File menu
my $mnu_file = uiNewMenu('File');
my $mi_new   = uiMenuAppendItem( $mnu_file, 'New' );
my $mi_open  = uiMenuAppendItem( $mnu_file, 'Open...' );
my $mi_save  = uiMenuAppendItem( $mnu_file, 'Save' );
uiMenuAppendSeparator($mnu_file);
my $mi_exit = uiMenuAppendQuitItem($mnu_file);

# Edit menu
my $mnu_edit = uiNewMenu('Edit');
my $mi_undo  = uiMenuAppendItem( $mnu_edit, 'Undo' );
my $mi_redo  = uiMenuAppendItem( $mnu_edit, 'Redo' );
uiMenuAppendSeparator($mnu_edit);
$check_item = uiMenuAppendCheckItem( $mnu_edit, 'Word Wrap' );

# View menu
my $mnu_view = uiNewMenu('View');
$mi_dynamic        = uiMenuAppendItem( $mnu_view, 'Dynamic Action' );
$mi_disable_target = uiMenuAppendItem( $mnu_view, 'Toggle This Item' );
uiMenuAppendSeparator($mnu_view);
my $mi_fullscreen = uiMenuAppendCheckItem( $mnu_view, 'Fullscreen' );

# Advanced submenu (via check items inside a group)
my $mnu_advanced = uiNewMenu('Advanced');
my $mi_debug     = uiMenuAppendCheckItem( $mnu_advanced, 'Debug Mode' );
my $mi_verbose   = uiMenuAppendCheckItem( $mnu_advanced, 'Verbose Logging' );

# Help menu
my $mnu_help = uiNewMenu('Help');
my $mi_about = uiMenuAppendAboutItem($mnu_help);

# Callbacks
uiMenuItemOnClicked( $mi_new,  sub { uiMsgBox( $mainwin, 'New',  'New document.' ) },                   undef );
uiMenuItemOnClicked( $mi_open, sub { uiMsgBox( $mainwin, 'Open', 'Open file dialog would go here.' ) }, undef );
uiMenuItemOnClicked( $mi_save, sub { uiMsgBox( $mainwin, 'Save', 'File saved.' ) },                     undef );
uiMenuItemOnClicked( $mi_undo, sub { uiMsgBox( $mainwin, 'Undo', 'Undo.' ) },                           undef );
uiMenuItemOnClicked( $mi_redo, sub { uiMsgBox( $mainwin, 'Redo', 'Redo.' ) },                           undef );
uiMenuItemOnClicked(
    $check_item,
    sub {
        update_info();
    },
    undef
);
uiMenuItemOnClicked(
    $mi_dynamic,
    sub {
        uiMsgBox( $mainwin, 'Dynamic', 'Dynamic action triggered!' );
    },
    undef
);
uiMenuItemOnClicked(
    $mi_disable_target,
    sub {
        if ($dynamic_enabled) {
            uiMenuItemDisable($mi_dynamic);
            $dynamic_enabled = 0;
        }
        else {
            uiMenuItemEnable($mi_dynamic);
            $dynamic_enabled = 1;
        }
        update_info();
    },
    undef
);
uiMenuItemOnClicked(
    $mi_fullscreen,
    sub {
        my $fs = uiMenuItemChecked($mi_fullscreen);
        uiWindowSetFullscreen( $mainwin, $fs ? 1 : 0 );
    },
    undef
);
uiMenuItemOnClicked( $mi_debug,   sub { update_info() },                                   undef );
uiMenuItemOnClicked( $mi_verbose, sub { update_info() },                                   undef );
uiMenuItemOnClicked( $mi_about,   sub { uiMsgBox( $mainwin, 'About Menu Demo', <<~'' ); }, undef );
            Demonstrates all menu types:
              - Regular items
              - Check items
              - Separators
              - Quit, Preferences, About
              - Enable/Disable

#
$mainwin = uiNewWindow( 'Menu Demo', 400, 200, 1 );
uiWindowSetMargined( $mainwin, 1 );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );
uiBoxAppend( $vbox, uiNewLabel('Explore the menus above. Use Edit > Toggle to enable/disable the Dynamic Action item.'), 0 );
$info_label = uiNewLabel('');
uiBoxAppend( $vbox, $info_label, 0 );
update_info();
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
uiControlShow($mainwin);
uiMain();
