use v5.40;
use blib;
use LibUI qw[:all];

# Calculator Demo
my $display_text = '0';
my $current_val  = 0;
my $pending_op   = undef;
my $reset_next   = 0;
my $settings_win = undef;
my $lbl_display  = undef;

# Helpers
sub update_display() {
    uiLabelSetText( $lbl_display, $display_text );
}

sub handle_number($num) {
    if ($reset_next) {
        $display_text = "$num";
        $reset_next   = 0;
    }
    elsif ( $display_text eq '0' ) {
        $display_text = "$num";
    }
    else {
        $display_text .= "$num";
    }
    update_display();
}

sub handle_operator($op) {
    my $val = $display_text;
    if ( defined $pending_op ) {
        $current_val  = compute( $current_val, $val, $pending_op );
        $display_text = "$current_val";
    }
    else {
        $current_val = $val;
    }
    $pending_op = $op;
    $reset_next = 1;
    update_display();
}

sub compute( $a, $b, $op ) {
    return $a + $b     if $op eq '+';
    return $a - $b     if $op eq '-';
    return $a * $b     if $op eq '*';
    return ( $a / $b ) if $op eq '/' && $b != 0;
    return 0;
}

sub handle_equals() {
    if ( defined $pending_op ) {
        my $val = $display_text;
        $current_val  = compute( $current_val, $val, $pending_op );
        $display_text = "$current_val";
        $pending_op   = undef;
        $reset_next   = 1;
        update_display();
    }
}

sub handle_clear() {
    $display_text = '0';
    $current_val  = 0;
    $pending_op   = undef;
    $reset_next   = 0;
    update_display();
}

sub handle_backspace() {
    if ( length($display_text) > 1 ) {
        chop $display_text;
    }
    else {
        $display_text = '0';
    }
    update_display();
}

sub handle_negate() {
    if ( $display_text ne '0' ) {
        if ( substr( $display_text, 0, 1 ) eq '-' ) {
            substr( $display_text, 0, 1 ) = '';
        }
        else {
            $display_text = "-$display_text";
        }
        update_display();
    }
}
#
sub open_settings() {
    return if $settings_win;
    $settings_win = uiNewWindow( 'Calculator Settings', 300, 200, 0 );
    uiWindowSetMargined( $settings_win, 1 );
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiWindowSetChild( $settings_win, $vbox );

    # Precision setting
    my $grp_precision = uiNewGroup('Display');
    uiBoxAppend( $vbox, $grp_precision, 0 );
    my $inner = uiNewVerticalBox();
    uiBoxSetPadded( $inner, 1 );
    uiGroupSetChild( $grp_precision, $inner );
    uiBoxAppend( $inner, uiNewLabel('Max display digits:'), 0 );
    my $spn_digits = uiNewSpinbox( 1, 20 );
    uiSpinboxSetValue( $spn_digits, 12 );
    uiBoxAppend( $inner, $spn_digits, 0 );

    # Theme options
    my $grp_theme = uiNewGroup('Appearance');
    uiBoxAppend( $vbox, $grp_theme, 0 );
    my $inner2 = uiNewVerticalBox();
    uiBoxSetPadded( $inner2, 1 );
    uiGroupSetChild( $grp_theme, $inner2 );
    my $chk_scientific = uiNewCheckbox('Show scientific notation');
    uiBoxAppend( $inner2, $chk_scientific, 0 );
    my $chk_thousands = uiNewCheckbox('Use thousands separator');
    uiBoxAppend( $inner2, $chk_thousands, 0 );

    # Color picker
    uiBoxAppend( $inner2, uiNewLabel('Accent color:'), 0 );
    my $clr_btn = uiNewColorButton();
    uiColorButtonSetColor( $clr_btn, 0.2, 0.4, 0.8, 1.0 );
    uiBoxAppend( $inner2, $clr_btn, 0 );
    uiWindowOnClosing(
        $settings_win,
        sub {
            $settings_win = undef;
            return 1;
        },
        undef
    );
    uiControlShow($settings_win);
}
#
uiInit( { Size => 0 } );
my $main_win = uiNewWindow( 'Perl Calc', 280, 400, 0 );
uiWindowSetMargined( $main_win, 1 );
uiWindowSetResizeable( $main_win, 0 );

# Menu
my $mnu_file = uiNewMenu('File');
uiMenuAppendQuitItem($mnu_file);
my $mnu_edit = uiNewMenu('Edit');
my $mi_copy  = uiMenuAppendItem( $mnu_edit, 'Copy Result' );
my $mi_clear = uiMenuAppendItem( $mnu_edit, 'Clear' );
uiMenuAppendSeparator($mnu_edit);
my $mi_sci   = uiMenuAppendCheckItem( $mnu_edit, 'Scientific Mode' );
my $mnu_help = uiNewMenu('Help');
my $mi_about = uiMenuAppendAboutItem($mnu_help);

# Display
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $main_win, $vbox );
$lbl_display = uiNewLabel('0');
uiBoxAppend( $vbox, $lbl_display, 0 );
my $sep = uiNewHorizontalSeparator();
uiBoxAppend( $vbox, $sep, 0 );

# Button grid
my $grid = uiNewGrid();
uiGridSetPadded( $grid, 1 );
uiBoxAppend( $vbox, $grid, 1 );

# Button helper
sub make_btn( $label, $cb ) {
    my $btn = uiNewButton($label);
    uiButtonOnClicked( $btn, $cb, undef );
    return $btn;
}

# uiGridAppend(grid, control, left, top, xspan, yspan, hexpand, halign, vexpand, valign)
# halign/valign: 0=fill, 1=start, 2=center, 3=end
my @grid_btns;

# Row 0: C, ±, ⌫, ÷
push @grid_btns, [ make_btn( 'C', sub { handle_clear() } ),     0, 0 ];
push @grid_btns, [ make_btn( '±', sub { handle_negate() } ),    1, 0 ];
push @grid_btns, [ make_btn( '⌫', sub { handle_backspace() } ), 2, 0 ];
push @grid_btns, [ make_btn( '÷', sub { handle_operator('/') } ), 3, 0 ];

# Row 1: 7, 8, 9, ×
push @grid_btns, [ make_btn( '7', sub { handle_number(7) } ),     0, 1 ];
push @grid_btns, [ make_btn( '8', sub { handle_number(8) } ),     1, 1 ];
push @grid_btns, [ make_btn( '9', sub { handle_number(9) } ),     2, 1 ];
push @grid_btns, [ make_btn( '×', sub { handle_operator('*') } ), 3, 1 ];

# Row 2: 4, 5, 6, −
push @grid_btns, [ make_btn( '4', sub { handle_number(4) } ),     0, 2 ];
push @grid_btns, [ make_btn( '5', sub { handle_number(5) } ),     1, 2 ];
push @grid_btns, [ make_btn( '6', sub { handle_number(6) } ),     2, 2 ];
push @grid_btns, [ make_btn( '−', sub { handle_operator('-') } ), 3, 2 ];

# Row 3: 1, 2, 3, +
push @grid_btns, [ make_btn( '1', sub { handle_number(1) } ),     0, 3 ];
push @grid_btns, [ make_btn( '2', sub { handle_number(2) } ),     1, 3 ];
push @grid_btns, [ make_btn( '3', sub { handle_number(3) } ),     2, 3 ];
push @grid_btns, [ make_btn( '+', sub { handle_operator('+') } ), 3, 3 ];

# Row 4: 0 (span 2), ., =
push @grid_btns, [ make_btn( '0', sub { handle_number(0) } ), 0, 4, 2 ];
push @grid_btns, [ make_btn( '.', sub { $display_text .= '.'; update_display(); } ), 2, 4, 1 ];
push @grid_btns, [ make_btn( '=', sub { handle_equals() } ), 3, 4, 1 ];
for my $b (@grid_btns) {
    my ( $btn, $col, $row, $xspan ) = @$b;
    $xspan //= 1;
    uiGridAppend( $grid, $btn, $col, $row, $xspan, 1, 1, 0, 1, 0 );
}
#
uiMenuItemOnClicked(
    $mi_copy,
    sub {
        # Copy result to clipboard would go here
        uiMsgBox( $main_win, 'Copy', 'Result: ' . $display_text );
    },
    undef
);
uiMenuItemOnClicked( $mi_clear, sub { handle_clear() }, undef );
uiWindowOnClosing(
    $main_win,
    sub {
        uiQuit();
        return 1;
    },
    undef
);
#
uiControlShow($main_win);
uiMain();
