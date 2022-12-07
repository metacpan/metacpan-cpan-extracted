[![Actions Status](https://github.com/sanko/LibUI.pm/actions/workflows/linux.yaml/badge.svg)](https://github.com/sanko/LibUI.pm/actions) [![Actions Status](https://github.com/sanko/LibUI.pm/actions/workflows/windows.yaml/badge.svg)](https://github.com/sanko/LibUI.pm/actions) [![Actions Status](https://github.com/sanko/LibUI.pm/actions/workflows/osx.yaml/badge.svg)](https://github.com/sanko/LibUI.pm/actions) [![Actions Status](https://github.com/sanko/LibUI.pm/actions/workflows/freebsd.yaml/badge.svg)](https://github.com/sanko/LibUI.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/LibUI.svg)](https://metacpan.org/release/LibUI)
# NAME

LibUI - Simple, Portable, Native GUI Library

# SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    use LibUI::Label;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setChild( LibUI::Label->new('Hello, World!') );
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();

# DESCRIPTION

LibUI is a simple and portable (but not inflexible) GUI library in C that uses
the native GUI technologies of each platform it supports.

This distribution is under construction. It works but is incomplete.

# Container controls

- [LibUI::Window](https://metacpan.org/pod/LibUI%3A%3AWindow) - a top-level window
- [LibUI::HBox](https://metacpan.org/pod/LibUI%3A%3AHBox) - a horizontally aligned, boxlike container that holds a group of controls
- [LibUI::VBox](https://metacpan.org/pod/LibUI%3A%3AVBox) - a vertically aligned, boxlike container that holds a group of controls
- [LibUI::Tab](https://metacpan.org/pod/LibUI%3A%3ATab) - a multi-page control interface that displays one page at a time
- [LibUI::Group](https://metacpan.org/pod/LibUI%3A%3AGroup) - a container that adds a label to the child
- [LibUI::Form](https://metacpan.org/pod/LibUI%3A%3AForm) - a container to organize controls as labeled fields
- [LibUI::Grid](https://metacpan.org/pod/LibUI%3A%3AGrid) - a container to arrange controls in a grid

# Data entry controls

- [LibUI::Button](https://metacpan.org/pod/LibUI%3A%3AButton) - a button control that triggers a callback when clicked
- [LibUI::Checkbox](https://metacpan.org/pod/LibUI%3A%3ACheckbox) - a user checkable box accompanied by a text label
- [LibUI::Entry](https://metacpan.org/pod/LibUI%3A%3AEntry) - a single line text entry field
- [LibUI::PasswordEntry](https://metacpan.org/pod/LibUI%3A%3APasswordEntry) - a single line, obscured text entry field
- [LibUI::SearchEntry](https://metacpan.org/pod/LibUI%3A%3ASearchEntry) - a single line search query field
- [LibUI::Spinbox](https://metacpan.org/pod/LibUI%3A%3ASpinbox) - display and modify integer values via a text field or +/- buttons
- [LibUI::Slider](https://metacpan.org/pod/LibUI%3A%3ASlider) - display and modify integer values via a draggable slider
- [LibUI::Combobox](https://metacpan.org/pod/LibUI%3A%3ACombobox) - a drop down menu to select one of a predefined list of items
- [LibUI::EditableCombobox](https://metacpan.org/pod/LibUI%3A%3AEditableCombobox) - a drop down menu to select one of a predefined list of items or enter you own
- [LibUI::RadioButtons](https://metacpan.org/pod/LibUI%3A%3ARadioButtons) - a multiple choice control of check buttons from which only one can be selected at a time
- [LibUI::DateTimePicker](https://metacpan.org/pod/LibUI%3A%3ADateTimePicker) - a control to enter a date and/or time
- [LibUI::DatePicker](https://metacpan.org/pod/LibUI%3A%3ADatePicker) - a control to enter a date
- [LibUI::TimePicker](https://metacpan.org/pod/LibUI%3A%3ATimePicker) - a control to enter a time
- [LibUI::MultilineEntry](https://metacpan.org/pod/LibUI%3A%3AMultilineEntry) - a multi line entry that visually wraps text when lines overflow
- [LibUI::NonWrappingMultilineEntry](https://metacpan.org/pod/LibUI%3A%3ANonWrappingMultilineEntry) - a multi line entry that scrolls text horizontally when lines overflow
- [LibUI::FontButton](https://metacpan.org/pod/LibUI%3A%3AFontButton) - a control that opens a font picker when clicked

## Static controls

- [LibUI::Label](https://metacpan.org/pod/LibUI%3A%3ALabel) - a control to display non-interactive text
- [LibUI::ProgressBar](https://metacpan.org/pod/LibUI%3A%3AProgressBar) - a control that visualizes the progress of a task via the fill level of a horizontal bar
- [LibUI::HorizontalSeparator](https://metacpan.org/pod/LibUI%3A%3AHorizontalSeparator) - a control to visually separate controls horizontally
- [LibUI::VerticalSeparator](https://metacpan.org/pod/LibUI%3A%3AVerticalSeparator) - a control to visually separate controls vertically

## Dialog windows

- `openFile( )` - File chooser to select a single file
- `openFolder( )` - File chooser to select a single folder
- `saveFile( )` - Save file dialog
- `msgBox( ... )` - Message box dialog
- `msgBoxError( ... )` - Error message box dialog

See ["Dialog windows" in LibUI::Window](https://metacpan.org/pod/LibUI%3A%3AWindow#Dialog-windows) for more.

## Menus

- `LibUI::Menu` - application-level menu bar
- `LibUI::MenuItem` - menu items used in conjunction with [LibUI::Menu](https://metacpan.org/pod/LibUI%3A%3AMenu)

## Tables

The upstream API is a mess so I'm still plotting around this.

# GUI Functions

Some basics you gotta use just to keep a modern GUI running.

This is incomplete but... well, I'm working on it.

## `Init( ... )`

    Init( { Size => 1024 } );

Ask LibUI to do all the platform specific work to get up and running.

Expected parameters include:

- `$options`

    LibUI::InitOptions structure.

## `Uninit( ... )`

    Uninit( );

Ask LibUI to break everything down before quitting.

## `Quit( ... )`

    Quit( );

Quit.

## `Main( ... )`

    Main( );

Let LibUI's event loop run until interrupted.

## `Timer( ... )`

    Timer( 1000, sub { die 'do not do this here' }, undef);

Expected parameters include:

- `$time`

    Time in milliseconds.

- `$func`

    CodeRef that will be triggered when `$time` runs out.

    Return a true value from your `$func` to make your timer repeating.

- `$data`

    Any userdata you feel like passing.

# Requirements

See [Alien::libui](https://metacpan.org/pod/Alien%3A%3Alibui)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
