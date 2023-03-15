use strict;
use Test::More 0.98;
use lib '../lib';
use_ok $_ for qw[
    LibUI
    LibUI::Align
    LibUI::Area
    LibUI::At
    LibUI::Button
    LibUI::Checkbox
    LibUI::ColorButton
    LibUI::Combobox
    LibUI::DateTimePicker
    LibUI::DatePicker
    LibUI::EditableCombobox
    LibUI::Entry
    LibUI::FontButton
    LibUI::FontDescriptor
    LibUI::Form
    LibUI::Grid
    LibUI::Group
    LibUI::HBox
    LibUI::HSeparator
    LibUI::Label
    LibUI::Menu
    LibUI::MenuItem
    LibUI::MultilineEntry
    LibUI::NonWrappingMultilineEntry
    LibUI::PasswordEntry
    LibUI::ProgressBar
    LibUI::RadioButtons
    LibUI::ScrollingArea
    LibUI::SearchEntry
    LibUI::Slider
    LibUI::Spinbox
    LibUI::Tab
    LibUI::TextItalic
    LibUI::TextStretch
    LibUI::TextWeight
    LibUI::Time
    LibUI::TimePicker
    LibUI::VBox
    LibUI::VSeparator
    LibUI::Window
];
diag prototype('LibUI::Timer');
done_testing;
