use v5.40;
use blib;
use LibUI qw[:all];

# Tab Demo - demonstrates uiTab: append, insert, delete, margined, selection
my $mainwin;
my $tab;
my $info_label;
my $tab_count = 0;

sub update_info() {
    my $n    = uiTabNumPages($tab);
    my $sel  = uiTabSelected($tab);
    my $marg = $sel >= 0 ? uiTabMargined( $tab, $sel ) : -1;
    uiLabelSetText( $info_label, "Tabs: $n | Selected: $sel | Margined: $marg" );
}

sub make_tab_content($title) {
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiBoxAppend( $vbox, uiNewLabel("Content of \"$title\""), 0 );
    my $entry = uiNewEntry();
    uiEntrySetText( $entry, 'Edit me in ' . $title );
    uiBoxAppend( $vbox, $entry, 0 );
    return $vbox;
}

sub add_tab() {
    $tab_count++;
    my $title   = 'Tab ' . $tab_count;
    my $content = make_tab_content($title);
    uiTabAppend( $tab, $title, $content );
    update_info();
}

sub insert_tab() {
    $tab_count++;
    my $title = 'Inserted ' . $tab_count;
    my $idx   = uiTabSelected($tab);
    $idx = 0 if $idx < 0;
    my $content = make_tab_content($title);
    uiTabInsertAt( $tab, $title, $idx, $content );
    update_info();
}

sub delete_tab() {
    my $sel = uiTabSelected($tab);
    return if $sel < 0;
    uiTabDelete( $tab, $sel );
    my $n = uiTabNumPages($tab);
    if ( $n > 0 ) {
        my $next = $sel < $n ? $sel : $n - 1;
        uiTabSetSelected( $tab, $next );
    }
    update_info();
}

sub toggle_margined() {
    my $sel = uiTabSelected($tab);
    return if $sel < 0;
    my $current = uiTabMargined( $tab, $sel );
    uiTabSetMargined( $tab, $sel, $current ? 0 : 1 );
    update_info();
}

sub on_closing( $w, $data ) {
    uiQuit();
    return 1;
}

sub should_quit($data) {
    uiControlHide($mainwin);
    return 1;
}
#
uiInit( { Size => 0 } );
#
$mainwin = uiNewWindow( 'Tab Demo', 500, 400, 0 );
uiWindowSetMargined( $mainwin, 1 );
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
#
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );

# Toolbar
my $hbox = uiNewHorizontalBox();
uiBoxSetPadded( $hbox, 1 );
uiBoxAppend( $vbox, $hbox, 0 );
#
my $btn_add    = uiNewButton('Add Tab');
my $btn_insert = uiNewButton('Insert at Current');
my $btn_delete = uiNewButton('Delete Current');
my $btn_margin = uiNewButton('Toggle Margined');
#
uiButtonOnClicked( $btn_add,    sub { add_tab() },         undef );
uiButtonOnClicked( $btn_insert, sub { insert_tab() },      undef );
uiButtonOnClicked( $btn_delete, sub { delete_tab() },      undef );
uiButtonOnClicked( $btn_margin, sub { toggle_margined() }, undef );
#
uiBoxAppend( $hbox, $btn_add,    0 );
uiBoxAppend( $hbox, $btn_insert, 0 );
uiBoxAppend( $hbox, $btn_delete, 0 );
uiBoxAppend( $hbox, $btn_margin, 0 );

# Info label
$info_label = uiNewLabel('');
uiBoxAppend( $vbox, $info_label, 0 );

# Tab widget
$tab = uiNewTab();
uiBoxAppend( $vbox, $tab, 1 );

# Add initial tabs
for my $i ( 1 .. 3 ) {
    my $title = 'Page ' . $i;
    uiTabAppend( $tab, $title, make_tab_content($title) );
    $tab_count++;
}

# Selection change callback
uiTabOnSelected(
    $tab,
    sub {
        update_info();
    },
    undef
);
#
update_info();
#
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
uiControlShow($mainwin);
uiMain();
