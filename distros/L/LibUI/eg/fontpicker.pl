use v5.40;
use blib;
use LibUI qw[:all];

# Font Picker Demo
# Demonstrates uiNewFontButton, uiFontButtonOnChanged, uiFontButtonFont
my $mainwin;
my $lbl_info;
my @weights   = qw[Thin UltraLight Light Book Normal Medium SemiBold Bold UltraBold Heavy UltraHeavy Maximum];
my @italics   = qw[Normal Oblique Italic];
my @stretches = qw[UltraCondensed ExtraCondensed Condensed SemiCondensed Normal SemiExpanded Expanded ExtraExpanded UltraExpanded];

sub onFontChanged( $btn, $data ) {
    my $d       = uiFontButtonFont($btn);
    my $family  = $d->{Family} // '(default)';
    my $size    = $d->{Size};
    my $weight  = $d->{Weight};
    my $italic  = $d->{Italic};
    my $stretch = $d->{Stretch};
    my $w       = $weight <= 1000 ? int( $weight / 100 ) : 3;
    my $i       = $italic <= 2    ? $italic              : 0;
    my $s       = $stretch <= 8   ? $stretch             : 4;
    my $info
        = sprintf( "Family: %s\nSize: %.1f pt\nWeight: %s\nItalic: %s\nStretch: %s", $family, $size, $weights[$w], $italics[$i], $stretches[$s] );
    uiLabelSetText( $lbl_info, $info );
}
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Font Picker Demo', 320, 240, 0 );
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
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );
my $fontbtn = uiNewFontButton();
uiBoxAppend( $vbox, $fontbtn, 0 );
uiFontButtonOnChanged( $fontbtn, \&onFontChanged, undef );
uiBoxAppend( $vbox, uiNewHorizontalSeparator(), 0 );
$lbl_info = uiNewLabel('Select a font above...');
uiBoxAppend( $vbox, $lbl_info, 0 );
uiControlShow($mainwin);
uiMain();
