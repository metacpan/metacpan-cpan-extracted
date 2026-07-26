use v5.40;
use blib;
use LibUI qw[:all];

# Port of upstream libui-ng controlgallery example
my $mainwin;

# Tab 1: Basic Controls
sub makeBasicControlsPage() {
    my $hbox = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox, 1 );
    my $group = uiNewGroup("Basic Controls");
    uiGroupSetMargined( $group, 1 );
    uiBoxAppend( $hbox, $group, 0 );
    my $inner = uiNewVerticalBox();
    uiBoxSetPadded( $inner, 1 );
    uiGroupSetChild( $group, $inner );
    uiBoxAppend( $inner, uiNewButton('Button'),                                           0 );
    uiBoxAppend( $inner, uiNewCheckbox('Checkbox'),                                       0 );
    uiBoxAppend( $inner, uiNewLabel("This is a label.\nLabels can span multiple lines."), 0 );
    uiBoxAppend( $inner, uiNewHorizontalSeparator(),                                      0 );

    # Date/Time pickers
    uiBoxAppend( $inner, uiNewDatePicker(),     0 );
    uiBoxAppend( $inner, uiNewTimePicker(),     0 );
    uiBoxAppend( $inner, uiNewDateTimePicker(), 0 );

    # Font and Color buttons
    uiBoxAppend( $inner, uiNewFontButton(),  0 );
    uiBoxAppend( $inner, uiNewColorButton(), 0 );
    #
    $hbox;
}

#Tab 2: Numbers and Lists
my ( $spinbox, $slider, $pbar );

sub update($value) {
    uiSpinboxSetValue( $spinbox, $value );
    uiSliderSetValue( $slider, $value );
    uiProgressBarSetValue( $pbar, $value );
}

sub makeNumbersPage() {
    my $hbox = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox, 1 );

    # Numbers group
    my $group = uiNewGroup('Numbers');
    uiGroupSetMargined( $group, 1 );
    uiBoxAppend( $hbox, $group, 1 );
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiGroupSetChild( $group, $vbox );
    $spinbox = uiNewSpinbox( 0, 100 );
    $slider  = uiNewSlider( 0, 100 );
    $pbar    = uiNewProgressBar();
    uiSpinboxOnChanged( $spinbox, sub { update( uiSpinboxValue($spinbox) ) }, undef );
    uiSliderOnChanged( $slider, sub { update( uiSliderValue($slider) ) }, undef );
    uiBoxAppend( $vbox, $spinbox, 0 );
    uiBoxAppend( $vbox, $slider,  0 );
    uiBoxAppend( $vbox, $pbar,    0 );
    my $ip = uiNewProgressBar();
    uiProgressBarSetValue( $ip, -1 );
    uiBoxAppend( $vbox, $ip, 0 );

    # Lists group
    $group = uiNewGroup('Lists');
    uiGroupSetMargined( $group, 1 );
    uiBoxAppend( $hbox, $group, 1 );
    $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiGroupSetChild( $group, $vbox );
    my $cbox = uiNewCombobox();
    uiComboboxAppend( $cbox, 'Combobox Item 1' );
    uiComboboxAppend( $cbox, 'Combobox Item 2' );
    uiComboboxAppend( $cbox, 'Combobox Item 3' );
    uiBoxAppend( $vbox, $cbox, 0 );
    my $ecbox = uiNewEditableCombobox();
    uiEditableComboboxAppend( $ecbox, 'Editable Item 1' );
    uiEditableComboboxAppend( $ecbox, 'Editable Item 2' );
    uiEditableComboboxAppend( $ecbox, 'Editable Item 3' );
    uiBoxAppend( $vbox, $ecbox, 0 );
    my $rb = uiNewRadioButtons();
    uiRadioButtonsAppend( $rb, 'Radio Button 1' );
    uiRadioButtonsAppend( $rb, 'Radio Button 2' );
    uiRadioButtonsAppend( $rb, 'Radio Button 3' );
    uiBoxAppend( $vbox, $rb, 0 );
    #
    $hbox;
}

# Tab 3: Data Choosers
sub makeDataChoosersPage() {
    my $hbox = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox, 1 );
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiBoxAppend( $hbox, $vbox,                    0 );
    uiBoxAppend( $vbox, uiNewDatePicker(),        0 );
    uiBoxAppend( $vbox, uiNewTimePicker(),        0 );
    uiBoxAppend( $vbox, uiNewDateTimePicker(),    0 );
    uiBoxAppend( $vbox, uiNewFontButton(),        0 );
    uiBoxAppend( $vbox, uiNewColorButton(),       0 );
    uiBoxAppend( $hbox, uiNewVerticalSeparator(), 0 );
    $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiBoxAppend( $hbox, $vbox, 1 );
    my $form = uiNewForm();
    uiFormSetPadded( $form, 1 );
    uiBoxAppend( $vbox, $form, 0 );

    # Open File
    my $e1 = uiNewEntry();
    uiEntrySetReadOnly( $e1, 1 );
    {
        my $entry = $e1;
        my $btn   = uiNewButton('Open File');
        uiButtonOnClicked(
            $btn,
            sub {
                my $filename = uiOpenFile($mainwin);
                uiEntrySetText( $entry, defined $filename ? $filename : '(cancelled)' );
            },
            undef
        );
        uiFormAppend( $form, 'Open File', $btn,   0 );
        uiFormAppend( $form, '',          $entry, 1 );
    }

    # Open Folder
    my $e2 = uiNewEntry();
    uiEntrySetReadOnly( $e2, 1 );
    {
        my $entry = $e2;
        my $btn   = uiNewButton('Open Folder');
        uiButtonOnClicked(
            $btn,
            sub {
                my $filename = uiOpenFolder($mainwin);
                uiEntrySetText( $entry, defined $filename ? $filename : '(cancelled)' );
            },
            undef
        );
        uiFormAppend( $form, 'Open Folder', $btn,   0 );
        uiFormAppend( $form, '',            $entry, 1 );
    }

    # Save File
    my $e3 = uiNewEntry();
    uiEntrySetReadOnly( $e3, 1 );
    {
        my $entry = $e3;
        my $btn   = uiNewButton('Save File');
        uiButtonOnClicked(
            $btn,
            sub {
                my $filename = uiSaveFile($mainwin);
                uiEntrySetText( $entry, defined $filename ? $filename : '(cancelled)' );
            },
            undef
        );
        uiFormAppend( $form, 'Save File', $btn,   0 );
        uiFormAppend( $form, '',          $entry, 1 );
    }

    # Message boxes
    my $msgform = uiNewForm();
    uiFormSetPadded( $msgform, 1 );
    uiBoxAppend( $vbox, $msgform, 0 );
    {
        my $btn = uiNewButton('Message Box');
        uiButtonOnClicked(
            $btn,
            sub {
                uiMsgBox( $mainwin, 'This is a normal message box.', 'More detailed information can be shown here.' );
            },
            undef
        );
        uiFormAppend( $msgform, 'Message', $btn, 0 );
    }
    {
        my $btn = uiNewButton('Error Box');
        uiButtonOnClicked(
            $btn,
            sub {
                uiMsgBoxError( $mainwin, 'This message box describes an error.', 'More detailed information can be shown here.' );
            },
            undef
        );
        uiFormAppend( $msgform, 'Error', $btn, 0 );
    }
    $hbox;
}
#
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'libui Control Gallery', 640, 480, 1 );
uiWindowOnClosing(
    $mainwin,
    sub ( $w, $data ) {
        uiQuit();
        1;
    },
    undef
);
uiOnShouldQuit(
    sub ($data) {
        uiControlHide($mainwin);
        1;
    },
    $mainwin
);
uiWindowSetMargined( $mainwin, 1 );
my $tab = uiNewTab();
uiWindowSetChild( $mainwin, $tab );
uiTabAppend( $tab, 'Basic Controls', makeBasicControlsPage() );
uiTabSetMargined( $tab, 0, 1 );
uiTabAppend( $tab, 'Numbers and Lists', makeNumbersPage() );
uiTabSetMargined( $tab, 1, 1 );
uiTabAppend( $tab, 'Data Choosers', makeDataChoosersPage() );
uiTabSetMargined( $tab, 2, 1 );
uiControlShow($mainwin);
uiMain();
