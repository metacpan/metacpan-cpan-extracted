use v5.40;
use blib;
use LibUI qw[:all];
#
uiInit( { Size => 0 } );
#
my $main = uiNewWindow( 'uiForm', 320, 200, 0 );
uiWindowOnClosing( $main, sub { uiQuit(); return 1 }, undef );
uiWindowSetMargined( $main, 1 );
#
my $box = uiNewVerticalBox();
uiBoxSetPadded( $box, 1 );
uiWindowSetChild( $main, $box );
#
my $form = uiNewForm();
uiFormSetPadded( $form, 1 );
#
uiFormAppend( $form, 'Name:',      uiNewEntry(),               0 );
uiFormAppend( $form, 'Password:',  uiNewPasswordEntry(),       0 );
uiFormAppend( $form, 'Biography:', uiNewMultilineEntry(),      1 );
uiFormAppend( $form, '',           uiNewHorizontalSeparator(), 0 );
uiFormAppend( $form, 'Age:',       uiNewSpinbox( 0, 150 ),     0 );
uiFormAppend( $form, 'Height:',    uiNewSlider( 0, 200 ),      0 );
uiFormAppend( $form, 'Color:',     uiNewColorButton(),         0 );
uiFormAppend( $form, 'Font:',      uiNewFontButton(),          0 );
#
uiBoxAppend( $box, $form, 1 );
#
my $check = uiNewCheckbox('Padded');
uiCheckboxSetChecked( $check, 1 );
uiCheckboxOnToggled( $check, sub { uiFormSetPadded( $form, uiCheckboxChecked( $_[0] ) ) }, undef );
uiBoxAppend( $box, $check, 0 );
#
uiControlShow($main);
uiMain();
