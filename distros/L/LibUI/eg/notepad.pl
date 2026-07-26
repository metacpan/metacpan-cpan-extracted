use v5.40;
use blib;
use LibUI qw[:all];

# Notepad Demo - multi-document tabbed text editor with dirty tracking
my $mainwin;
my $tab;
my $status_label;
my @docs;    # [{ title => ..., editor => ..., file => ..., modified => 0 }]
my $doc_count = 0;

sub update_title() {
    my $sel = uiTabSelected($tab);
    if ( $sel >= 0 && $sel < @docs ) {
        my $d     = $docs[$sel];
        my $title = $d->{file} // '(untitled)';
        $title .= ' *' if $d->{modified};
        uiWindowSetTitle( $mainwin, 'Notepad - ' . $title );
    }
    else {
        uiWindowSetTitle( $mainwin, 'Notepad' );
    }
}

sub update_status() {
    my $sel = uiTabSelected($tab);
    if ( $sel >= 0 && $sel < @docs ) {
        my $text  = uiMultilineEntryText( $docs[$sel]{editor} ) // '';
        my $chars = length($text);
        my $lines = ( () = $text =~ /\n/g ) + 1;
        uiLabelSetText( $status_label, 'Tab ' . ( $sel + 1 ) . " | $lines lines, $chars chars" );
    }
    else {
        uiLabelSetText( $status_label, 'No documents open' );
    }
}

sub new_document() {
    $doc_count++;
    my $editor = uiNewMultilineEntry();
    my $d      = { title => 'Untitled ' . $doc_count, editor => $editor, file => undef, modified => 0 };
    uiMultilineEntryOnChanged(
        $editor,
        sub {
            unless ( $d->{modified} ) {
                $d->{modified} = 1;
                update_title();
            }
            update_status();
        },
        undef
    );
    push @docs, $d;
    uiTabAppend( $tab, $d->{title}, $editor );
    uiTabSetSelected( $tab, $#docs );
    update_title();
    update_status();
}

sub open_file() {
    my $path = uiOpenFile($mainwin);
    return unless defined $path && -f $path;
    open my $fh, '<:raw', $path or do {
        uiMsgBoxError( $mainwin, 'Error', "Cannot open $path: $!" );
        return;
    };
    my $content = do { local $/; <$fh> };
    close $fh;
    $doc_count++;
    my $editor = uiNewMultilineEntry();
    uiMultilineEntrySetText( $editor, $content // '' );
    my $basename = $path;
    $basename =~ s{.*[/\\]}{};
    my $d = { title => $basename, editor => $editor, file => $path, modified => 0 };
    uiMultilineEntryOnChanged(
        $editor,
        sub {
            unless ( $d->{modified} ) {
                $d->{modified} = 1;
                update_title();
            }
            update_status();
        },
        undef
    );
    push @docs, $d;
    uiTabAppend( $tab, $d->{title}, $editor );
    uiTabSetSelected( $tab, $#docs );
    update_title();
    update_status();
}

sub save_current() {
    my $sel = uiTabSelected($tab);
    return if $sel < 0 || $sel >= @docs;
    my $d = $docs[$sel];
    if ( defined $d->{file} ) {
        save_to( $sel, $d->{file} );
    }
    else {
        save_as($sel);
    }
}

sub save_as() {
    my $sel = uiTabSelected($tab);
    return if $sel < 0 || $sel >= @docs;
    my $path = uiSaveFile($mainwin);
    return unless defined $path;
    save_to( $sel, $path );
}

sub save_to( $idx, $path ) {
    my $d       = $docs[$idx];
    my $content = uiMultilineEntryText( $d->{editor} ) // '';
    open my $fh, '>:raw', $path or do {
        uiMsgBoxError( $mainwin, 'Error', "Cannot write to $path: $!" );
        return;
    };
    print $fh $content;
    close $fh;
    $d->{file}     = $path;
    $d->{modified} = 0;
    my $basename = $path;
    $basename =~ s{.*[/\\]}{};
    $d->{title} = $basename;
    update_title();
    update_status();
}

sub close_tab() {
    my $sel = uiTabSelected($tab);
    return if $sel < 0 || $sel >= @docs;
    uiTabDelete( $tab, $sel );
    splice @docs, $sel, 1;
    update_title();
    update_status();
}

sub on_closing( $w, $data ) {
    uiQuit();
    return 1;
}

sub should_quit($data) {
    uiControlHide($mainwin);
    return 1;
}

# --- Main ---
uiInit( { Size => 0 } );

# Menus
my $mnu_file  = uiNewMenu('File');
my $mi_new    = uiMenuAppendItem( $mnu_file, 'New' );
my $mi_open   = uiMenuAppendItem( $mnu_file, 'Open...' );
my $mi_save   = uiMenuAppendItem( $mnu_file, 'Save' );
my $mi_saveas = uiMenuAppendItem( $mnu_file, 'Save As...' );
uiMenuAppendSeparator($mnu_file);
my $mi_close_tab = uiMenuAppendItem( $mnu_file, 'Close Tab' );
uiMenuAppendSeparator($mnu_file);
uiMenuAppendQuitItem($mnu_file);
my $mnu_help = uiNewMenu('Help');
my $mi_about = uiMenuAppendAboutItem($mnu_help);

# Window
$mainwin = uiNewWindow( 'Notepad', 750, 550, 1 );
uiWindowSetMargined( $mainwin, 1 );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );

# Toolbar
my $hbox = uiNewHorizontalBox();
uiBoxSetPadded( $hbox, 1 );
uiBoxAppend( $vbox, $hbox, 0 );
my $btn_new  = uiNewButton('New');
my $btn_open = uiNewButton('Open');
my $btn_save = uiNewButton('Save');
uiButtonOnClicked( $btn_new,  sub { new_document() }, undef );
uiButtonOnClicked( $btn_open, sub { open_file() },    undef );
uiButtonOnClicked( $btn_save, sub { save_current() }, undef );
uiBoxAppend( $hbox, $btn_new,  0 );
uiBoxAppend( $hbox, $btn_open, 0 );
uiBoxAppend( $hbox, $btn_save, 0 );

# Tab
$tab = uiNewTab();
uiBoxAppend( $vbox, $tab, 1 );

# Status
$status_label = uiNewLabel('No documents open');
uiBoxAppend( $vbox, $status_label, 0 );

# Menu callbacks
uiMenuItemOnClicked( $mi_new,       sub { new_document() },                                                                                undef );
uiMenuItemOnClicked( $mi_open,      sub { open_file() },                                                                                   undef );
uiMenuItemOnClicked( $mi_save,      sub { save_current() },                                                                                undef );
uiMenuItemOnClicked( $mi_saveas,    sub { save_as() },                                                                                     undef );
uiMenuItemOnClicked( $mi_close_tab, sub { close_tab() },                                                                                   undef );
uiMenuItemOnClicked( $mi_about, sub { uiMsgBox( $mainwin, 'About Notepad', "A multi-document tabbed text editor\nBuilt with LibUI.pm" ) }, undef );

# Tab selection tracking
uiTabOnSelected(
    $tab,
    sub {
        update_title();
        update_status();
    },
    undef
);

# Start with one document
new_document();
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
uiControlShow($mainwin);
uiMain();
