use v5.40;
use blib;
use LibUI qw[:all];

# Group Demo - demonstrates uiNewGroup, uiGroupSetMargined, uiGroupSetTitle
my $mainwin;

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
$mainwin = uiNewWindow( 'Group Demo', 500, 500, 0 );
uiWindowSetMargined( $mainwin, 1 );
uiWindowOnClosing( $mainwin, \&on_closing, undef );
uiOnShouldQuit( \&should_quit, undef );
my $scroll = uiNewVerticalBox();
uiBoxSetPadded( $scroll, 1 );
uiWindowSetChild( $mainwin, $scroll );

# Group 1: Basic controls with margined group
my $grp1 = uiNewGroup('Personal Info (Margined)');
uiGroupSetMargined( $grp1, 1 );
uiBoxAppend( $scroll, $grp1, 0 );
my $inner1 = uiNewVerticalBox();
uiBoxSetPadded( $inner1, 1 );
uiGroupSetChild( $grp1, $inner1 );
uiBoxAppend( $inner1, uiNewLabel('Name:'), 0 );
my $entry_name = uiNewEntry();
uiEntrySetText( $entry_name, 'Jane Doe' );
uiBoxAppend( $inner1, $entry_name,        0 );
uiBoxAppend( $inner1, uiNewLabel('Age:'), 0 );
my $spin_age = uiNewSpinbox( 0, 150 );
uiSpinboxSetValue( $spin_age, 30 );
uiBoxAppend( $inner1, $spin_age, 0 );

# Group 2: Without margins
my $grp2 = uiNewGroup('Preferences (No Margins)');
uiGroupSetMargined( $grp2, 0 );
uiBoxAppend( $scroll, $grp2, 0 );
my $inner2 = uiNewVerticalBox();
uiBoxSetPadded( $inner2, 1 );
uiGroupSetChild( $grp2, $inner2 );
my $chk_dark = uiNewCheckbox('Dark mode');
uiBoxAppend( $inner2, $chk_dark, 0 );
my $chk_notif = uiNewCheckbox('Notifications');
uiCheckboxSetChecked( $chk_notif, 1 );
uiBoxAppend( $inner2, $chk_notif, 0 );
my $chk_auto = uiNewCheckbox('Auto-save');
uiBoxAppend( $inner2, $chk_auto, 0 );

# Group 3: Color and font
my $grp3 = uiNewGroup('Appearance');
uiGroupSetMargined( $grp3, 1 );
uiBoxAppend( $scroll, $grp3, 0 );
my $inner3 = uiNewVerticalBox();
uiBoxSetPadded( $inner3, 1 );
uiGroupSetChild( $grp3, $inner3 );
uiBoxAppend( $inner3, uiNewLabel('Accent color:'), 0 );
my $clr = uiNewColorButton();
uiColorButtonSetColor( $clr, 0.2, 0.5, 0.8, 1.0 );
uiBoxAppend( $inner3, $clr,                   0 );
uiBoxAppend( $inner3, uiNewLabel('UI font:'), 0 );
my $font = uiNewFontButton();
uiBoxAppend( $inner3, $font, 0 );

# Group 4: Slider and progress
my $grp4 = uiNewGroup('Volume');
uiGroupSetMargined( $grp4, 1 );
uiBoxAppend( $scroll, $grp4, 0 );
my $inner4 = uiNewVerticalBox();
uiBoxSetPadded( $inner4, 1 );
uiGroupSetChild( $grp4, $inner4 );
my $slider = uiNewSlider( 0, 100 );
uiSliderSetValue( $slider, 50 );
my $lbl_vol = uiNewLabel('50%');
uiSliderOnChanged(
    $slider,
    sub {
        my $val = uiSliderValue($slider);
        uiLabelSetText( $lbl_vol, "$val%" );
    },
    undef
);
uiBoxAppend( $inner4, $slider,  0 );
uiBoxAppend( $inner4, $lbl_vol, 0 );
my $pbar = uiNewProgressBar();
uiProgressBarSetValue( $pbar, 50 );
uiSliderOnChanged(
    $slider,
    sub {
        uiProgressBarSetValue( $pbar, uiSliderValue($slider) );
    },
    undef
);
uiBoxAppend( $inner4, $pbar, 0 );

# Group 5: Dynamic title
my $grp5 = uiNewGroup('Dynamic Title');
uiGroupSetMargined( $grp5, 1 );
uiBoxAppend( $scroll, $grp5, 1 );
my $inner5 = uiNewVerticalBox();
uiBoxSetPadded( $inner5, 1 );
uiGroupSetChild( $grp5, $inner5 );
my $entry_title = uiNewEntry();
uiEntrySetText( $entry_title, 'Edit me' );
uiBoxAppend( $inner5, uiNewLabel('Type a new group title:'), 0 );
uiBoxAppend( $inner5, $entry_title,                          0 );
my $btn_apply = uiNewButton('Apply Title');
uiButtonOnClicked(
    $btn_apply,
    sub {
        my $new_title = uiEntryText($entry_title);
        uiGroupSetTitle( $grp5, $new_title ) if defined $new_title && length($new_title);
    },
    undef
);
uiBoxAppend( $inner5, $btn_apply, 0 );
uiControlShow($mainwin);
uiMain();
