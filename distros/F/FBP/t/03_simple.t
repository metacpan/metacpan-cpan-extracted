#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 355;
use Test::NoWarnings;
use Scalar::Util 'refaddr';
use File::Spec::Functions ':ALL';
use FBP ();

my $FILE = catfile( 't', 'data', 'simple.fbp' );
ok( -f $FILE, "Found test file '$FILE'" );





######################################################################
# Simple Tests

# Create the empty object
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );

# Parse the file
my $ok = eval {
	$fbp->parse_file( $FILE );
};
is( $@, '', "Parsed '$FILE' without error" );
ok( $ok, '->parse_file returned true' );

# Check the project properties
my $project = $fbp->project;
isa_ok( $project, 'FBP::Project' );
is( $project->name, 'Simple', '->name' );
is( $project->relative_path, '1', '->relative_path' );
is( $project->internationalize, '1', '->internationalize' );
is( $project->encoding, 'UTF-8', '->encoding' );
is( $project->namespace, '', '->namespace' );

# Find a particular named dialog
my $dialog1 = $fbp->dialog('MyDialog1');
isa_ok( $dialog1, 'FBP::Dialog' );
my $form1 = $fbp->form('MyDialog1');
isa_ok( $dialog1, 'FBP::Dialog' );
is( refaddr($form1), refaddr($dialog1), 'Got the same thing with ->form and ->dialog' );
is( $dialog1->name,     'MyDialog1',  '->name'     );
is( $dialog1->subclass, '',           '->subclass' );
is( $dialog1->wxclass,  'Wx::Dialog', '->class'    );

# Repeat using the generic search
my $dialog2 = $fbp->find_first(
	isa  => 'FBP::Dialog',
	name => 'MyDialog1',
);
isa_ok( $dialog2, 'FBP::Dialog' );
is(
	$fbp->find_first( name => 'does_not_exists' ),
	undef,
	'->find_first(bad) returns undef',
);

# The search should work as well from children of the main object as well
my $dialog3 = $project->find_first( isa => 'FBP::Dialog' );
isa_ok( $dialog3, 'FBP::Dialog' );

# Multiple-search query equivalent
my @dialog4 = $project->find( isa => 'FBP::Dialog' );
is( scalar(@dialog4), 1, '->find(single)' );
isa_ok( $dialog4[0], 'FBP::Dialog' );

# Multiple-search query with multiple results
my @window = $project->find( isa => 'FBP::Window' );
is( scalar(@window), 70, '->find(multiple)' );
foreach ( @window ) {
	isa_ok( $_, 'FBP::Window' );
}

# Frame properties
my $frame1 = $fbp->form('MyFrame1');
isa_ok( $frame1, 'FBP::Frame' );
ok( $frame1->DOES('FBP::Form'), 'DOES FBP::Form' );
can_ok( $frame1, 'OnInitDialog' );

# Top level Panel properties
my $panel1 = $fbp->form('MyPanel1');
isa_ok( $panel1, 'FBP::FormPanel' );
isa_ok( $panel1, 'FBP::Panel' );
ok( $panel1->DOES('FBP::Form'), 'DOES FBP::Form' );

# Text properties
my $text = $fbp->find_first(
	isa => 'FBP::StaticText',
);
isa_ok( $text, 'FBP::StaticText' );
is( $text->id,         'wxID_ANY',       '->id'         );
is( $text->name,       'm_staticText1',  '->name'       );
is( $text->permission, 'protected',      '->permission' );
is( $text->subclass,   'My::Class;',     '->subclass'   );
is( $text->wxclass,    'My::Class',      '->class'      );
is( $text->wrap,       '-1',             '->wrap'       );
is(
	$text->label,
	'Michael "Killer" O\'Reilly <michael@localhost>',
	'->label',
);

# TextCtrl properties
my $textctrl = $fbp->find_first(
	isa => 'FBP::TextCtrl',
);
isa_ok( $textctrl, 'FBP::TextCtrl' );
is( $textctrl->value, 'This is also a test', '->value' );
is( $textctrl->maxlength, '50',        '->maxlength' );
is( $textctrl->fg,        '',          '->fg'        );
is( $textctrl->bg,        '255,128,0', '->bg'        );

# Button properties
my $button = $fbp->find_first(
	isa => 'FBP::Button',
);
isa_ok( $button, 'FBP::Button' );
is( $button->id,            'wxID_ANY',    '->id'            );
is( $button->name,          'm_button1',   '->name'          );
is( $button->label,         'MyButton',    '->label'         );
is( $button->default,       '1',           '->default'       );
is( $button->subclass,      '',            '->subclass'      );
is( $button->wxclass,       'Wx::Button',  '->wxclass'       );
is( $button->permission,    'protected',   '->permission'    );
is( $button->fg,            '',            '->fg'            );
is( $button->bg,            '',            '->bg'            );
is( $button->tooltip, 'This is a tooltip', '->tooltip'       );
is( $button->OnButtonClick, 'm_button1',   '->OnButtonClick' );

# ListCtrl properties
my $listctrl = $fbp->find_first(
	isa => 'FBP::ListCtrl',
);
isa_ok( $listctrl, 'FBP::ListCtrl' );
is( $listctrl->name, 'm_listCtrl1', '->name' );
is( $listctrl->minimum_size, '100,100', '->minimum_size' );
is( $listctrl->maximum_size, '200,200', '->maximum_size' );

# Choice box properties
my $choice = $fbp->find_first(
	isa => 'FBP::Choice',
);
isa_ok( $choice, 'FBP::Choice' );
is( $choice->id,      'wxID_ANY',  '->id'      );
is( $choice->name,    'm_choice1', '->name'    );
is( $choice->wxclass, 'Wx::Foo',   '->wxclass' );
is( scalar($choice->header), undef, '->header' );

# Combo properties
my $combo = $fbp->find_first(
	isa => 'FBP::ComboBox',
);
isa_ok( $combo, 'FBP::ComboBox' );
is( $combo->id,      'wxID_ANY',    '->id'      );
is( $combo->name,    'm_comboBox1', '->name'    );
is( $combo->value,   'Combo!',      '->value'   );
is( $combo->wxclass, 'Wx::Bar',     '->wxclass' );
is( scalar($combo->header), 'Wx::Bar', '->header' );
is(
	$combo->choices,
	'"one" "two" "a\'b" "c\\"d \\\\\\""',
	'->choices',
);
is( scalar($combo->items), 4, 'Scalar ->items' );
is_deeply(
	[ $combo->items ],
	[ 'one', 'two', "a'b", 'c"d \\"' ],
	'->items',
);
is( $combo->OnCombobox, 'on_combobox', '->OnCombobox' );

# Line properties
my $line = $fbp->find_first(
	isa => 'FBP::StaticLine',
);
isa_ok( $line, 'FBP::StaticLine' );
is( $line->id,           'wxID_ANY',                    '->id'           );
is( $line->name,         'm_staticline1',               '->name'         );
is( $line->enabled,      '1',                           '->enabled'      );
is( $line->pos,          '',                            '->pos'          );
is( $line->size,         '',                            '->size'         );
is( $line->style,        'wxLI_HORIZONTAL',             '->style'        );
is( $line->window_style, 'wxNO_BORDER',                 '->window_style' );
is( $line->styles,       'wxLI_HORIZONTAL|wxNO_BORDER', '->styles'       );

# Sizer properties
my $sizer = $fbp->find_first(
	isa  => 'FBP::Sizer',
	name => 'bSizer8',
);
isa_ok( $sizer, 'FBP::Sizer' );
is( $sizer->name,         'bSizer8',     '->name'         );
is( $sizer->orient,       'wxHORIZONTAL', '->orient'       );
is( $sizer->permission,   'none',         '->permission'   );
is( $sizer->minimum_size, '-1,50',        '->minimum_size' );

# Listbook properties
my $listbook = $fbp->find_first(
	isa => 'FBP::Listbook',
);
isa_ok( $listbook, 'FBP::Listbook' );
is( $listbook->style, 'wxLB_DEFAULT', '->style' );

# SplitterWindow properties
my $splitterwindow = $fbp->find_first(
	isa => 'FBP::SplitterWindow',
);
isa_ok( $splitterwindow, 'FBP::SplitterWindow' );
is( $splitterwindow->style, 'wxSP_3D', '->style' );
is( $splitterwindow->splitmode, 'wxSPLIT_VERTICAL', '->splitmode' );
is( $splitterwindow->sashpos, '0', '->sashpos' );
is( $splitterwindow->sashsize, '-1', '->sashsize' );
is( $splitterwindow->sashgravity, '0.0', '->sashgravity' );
is( $splitterwindow->min_pane_size, '0', '->min_pane_size' );
is( $splitterwindow->permission, 'protected', '->permission' );

# SplitterItem properties
my $splitteritem = $fbp->find_first(
	isa => 'FBP::SplitterItem',
);
isa_ok( $splitteritem, 'FBP::SplitterItem' );

# ColourPickerCtrl properties
my @colourpickerctrl = $fbp->find(
	isa => 'FBP::ColourPickerCtrl',
);
isa_ok( $colourpickerctrl[0], 'FBP::ColourPickerCtrl' );
isa_ok( $colourpickerctrl[1], 'FBP::ColourPickerCtrl' );
is( $colourpickerctrl[0]->style, 'wxCLRP_DEFAULT_STYLE', '->style' );
is( $colourpickerctrl[0]->colour, '255,0,0', '->colour' );
is( $colourpickerctrl[1]->colour, 'wxSYS_COLOUR_INFOBK', '->colour' );

# Test support for hidden
is( $colourpickerctrl[0]->hidden, 0, '->hidden false for visible element' );
is( $colourpickerctrl[1]->hidden, 1, '->hidden true for hidden element' );

# FontPickerCtrl properties
my $fontpickerctrl = $fbp->find_first(
	isa => 'FBP::FontPickerCtrl',
);
isa_ok( $fontpickerctrl, 'FBP::FontPickerCtrl' );
is( $fontpickerctrl->value, 'Times New Roman,90,92,10,74,0', '->value' );
is( $fontpickerctrl->max_point_size, 100, '->max_point_size' );
is( $fontpickerctrl->style, 'wxFNTP_DEFAULT_STYLE', '->stlye' );

# FilePickerCtrl properties
my $filepickerctrl = $fbp->find_first(
	isa => 'FBP::FilePickerCtrl',
);
isa_ok( $filepickerctrl, 'FBP::FilePickerCtrl' );
is( $filepickerctrl->value, '', '->value' );
is( $filepickerctrl->message, 'Select a file', '->message' );
is( $filepickerctrl->wildcard, '*.*', '->wildcard' );
is( $filepickerctrl->style, 'wxFLP_DEFAULT_STYLE', '->stlye' );

# DirPickerCtrl properties
my $dirpickerctrl = $fbp->find_first(
	isa => 'FBP::DirPickerCtrl',
);
isa_ok( $dirpickerctrl, 'FBP::DirPickerCtrl' );
is( $dirpickerctrl->value, '', '->value' );
is( $dirpickerctrl->message, 'Select a folder', '->message' );
is( $dirpickerctrl->style, 'wxDIRP_DEFAULT_STYLE', '->style' );

# SpinCtrl properties
my $spinctrl = $fbp->find_first(
	isa => 'FBP::SpinCtrl',
);
isa_ok( $spinctrl, 'FBP::SpinCtrl' );
is( $spinctrl->value,   '',   '->value'   );
is( $spinctrl->min,     '0',  '->min'     );
is( $spinctrl->max,     '10', '->max'     );
is( $spinctrl->initial, '5',  '->initial' );
is( $spinctrl->style, 'wxSP_ARROW_KEYS', '->style' );

# CustomControl properties
my $custom = $fbp->find_first(
	isa => 'FBP::CustomControl',
);
isa_ok( $custom, 'FBP::CustomControl' );
is( $custom->class, 'My::Class' );
is( $custom->wxclass, 'My::Class' );
is( $custom->include, 'My::Module' );
is( $custom->header, 'My::Module' );

# RadioBox properties
my $radiobox = $fbp->find_first(
	isa => 'FBP::RadioBox',
);
isa_ok( $radiobox, 'FBP::RadioBox' );
is( $radiobox->label, 'Radio Gaga', '->label' );
is( $radiobox->choices, '"One" "Two" "Three" "Four"', '->choices' );
is( $radiobox->selection, 2, '->selection' );
is( $radiobox->majorDimension, 2, '->majorDimension' );
is( $radiobox->style, 'wxRA_SPECIFY_COLS', '->style' );

# HyperLink properties
my $hyperlink = $fbp->find_first(
	isa => 'FBP::HyperlinkCtrl',
);
isa_ok( $hyperlink, 'FBP::HyperlinkCtrl' );
is( $hyperlink->name, 'm_hyperlink1', '->name' );
is( $hyperlink->label, 'wxFormBuilder Website', '->label' );
is( $hyperlink->url, 'http://www.wxformbuilder.org', '->url' );
is( $hyperlink->normal_color, 'wxSYS_COLOUR_WINDOWTEXT', '->normal_color' );

# Gauge properties
my $gauge = $fbp->find_first(
	isa => 'FBP::Gauge',
);
isa_ok( $gauge, 'FBP::Gauge' );
is( $gauge->name, 'm_gauge1', '->name' );
is( $gauge->value, 80, '->value' );
is( $gauge->range, 100, '->range' );

# SearchCtrl properties
my $searchctrl = $fbp->find_first(
	isa => 'FBP::SearchCtrl',
);
isa_ok( $searchctrl, 'FBP::SearchCtrl' );
is( $searchctrl->value, 'A search', '->value' );
is( $searchctrl->search_button, 1, '->search_button' );
is( $searchctrl->cancel_button, 0, '->cancel_button' );

# StatusBar properties
my $statusbar = $fbp->find_first(
	isa => 'FBP::StatusBar',
);
isa_ok( $statusbar, 'FBP::StatusBar' );
is( $statusbar->name, 'm_statusBar1', '->name' );
is( $statusbar->fields, 2, '->fields' );

# ToolBar properties
my $toolbar = $fbp->find_first(
	isa => 'FBP::ToolBar',
);
isa_ok( $toolbar, 'FBP::ToolBar' );
is( $toolbar->name, 'm_toolBar1', '->name' );
is( $toolbar->packing, 2, '->packing' );
is( $toolbar->separation, 5, '->separation' );
is( $toolbar->bitmapsize, '', '->bitmapsize' );
is( $toolbar->margins, '', '->margins' );
is( $toolbar->style, 'wxTB_HORIZONTAL', '->style' );

# Tool properties
my $tool = $fbp->find_first(
	isa => 'FBP::Tool',
);
isa_ok( $tool, 'FBP::Tool' );
is( $tool->name, 'm_tool1', '->name' );
is( $tool->label, 'tool', '->label' );
is( $tool->bitmap, 'x-document-close.png; Load From File', '->bitmap' );
is( $tool->kind, 'wxITEM_NORMAL', '->kind' );
is( $tool->tooltip, 'Tool 1 tooltip', '->tooltip' );
is( $tool->statusbar, 'Tool 1 status bar', '->statusbar' );

# ToolSeparator properties
my $toolseparator = $fbp->find_first(
	isa => 'FBP::ToolSeparator',
);
isa_ok( $toolseparator, 'FBP::ToolSeparator' );
is( $toolseparator->permission, 'none', '->permission' );

# MenuBar properties
my $menubar = $fbp->find_first(
	isa => 'FBP::MenuBar',
);
isa_ok( $menubar, 'FBP::MenuBar' );
is( $menubar->name, 'm_menubar1', '->name' );
is( $menubar->label, 'MyMenuBar', '->label' );
is( $menubar->style, 'wxMB_DOCKABLE', '->style' );

# Menu properties
my $menu = $fbp->find_first(
	isa => 'FBP::Menu',
);
isa_ok( $menu, 'FBP::Menu' );
is( $menu->name, 'm_menu1', '->name' );
is( $menu->label, 'File', '->label' );

# MenuItem properties
my $menuitem = $fbp->find_first(
	isa => 'FBP::MenuItem',
);
isa_ok( $menuitem, 'FBP::MenuItem' );
is( $menuitem->name, 'm_menuItem1', '->name' );
is( $menuitem->label, 'This', '->label' );
is( $menuitem->shortcut, '', '->shortcut' );
is( $menuitem->help, 'This is help text', '->help' );
is( $menuitem->bitmap, '; Load From File', '->bitmap' );
is( $menuitem->unchecked_bitmap, '', '->unchecked_bitmap' );
is( $menuitem->checked, 0, '->checked' );
is( $menuitem->enabled, 1, '->enabled' );
is( $menuitem->kind, 'wxITEM_NORMAL', '->kind' );

# MenuSeparator properties
my $menuseparator = $fbp->find_first(
	isa => 'FBP::MenuSeparator',
);
isa_ok( $menuseparator, 'FBP::MenuSeparator' );
is( $menuseparator->name, 'm_separator1', '->name' );

# StaticBitmap properties
my $staticbitmap = $fbp->find_first(
	isa => 'FBP::StaticBitmap',
);
isa_ok( $staticbitmap, 'FBP::StaticBitmap' );
is( $staticbitmap->name, 'm_bitmap1', '->name' );
is( $staticbitmap->bitmap, 'x-document-close.png; Load From File', '->bitmap' );

# BitmapButton properties
my $bitmapbutton = $fbp->find_first(
	isa => 'FBP::BitmapButton',
);
isa_ok( $bitmapbutton, 'FBP::BitmapButton' );
is( $bitmapbutton->name, 'm_bpButton1', '->name' );
is( $bitmapbutton->style, '', '->style' );
is( $bitmapbutton->bitmap, 'x-document-close.png; Load From File', '->bitmap' );
is( $bitmapbutton->disabled, '', '->disabled' );
is( $bitmapbutton->selected, '', '->selected' );
is( $bitmapbutton->focus, '', '->focus' );
is( $bitmapbutton->hover, '', '->hover' );

# Slider properties
my $slider = $fbp->find_first(
	isa => 'FBP::Slider',
);
isa_ok( $slider, 'FBP::Slider' );
is( $slider->name, 'm_slider1', '->name' );
is( $slider->value, 50, '->value' );
is( $slider->minValue, 0, '->minValue' );
is( $slider->maxValue, 100, '->maxValue' );
is( $slider->style, 'wxSL_HORIZONTAL', '->style' );

# ToggleButton properties
my $toggle = $fbp->find_first(
	isa => 'FBP::ToggleButton',
);
isa_ok( $toggle, 'FBP::ToggleButton' );
is( $toggle->name, 'm_toggleBtn1', '->name' );
is( $toggle->label, 'Toggle me!', '->label' );
is( $toggle->value, 0, '->value' );

# DatePickerCtrl properties
my $datepicker = $fbp->find_first(
	isa => 'FBP::DatePickerCtrl',
);
isa_ok( $datepicker, 'FBP::DatePickerCtrl' );
is( $datepicker->name, 'm_datePicker1', '->name' );
is( $datepicker->style, 'wxDP_DEFAULT', '->style' );

# CalendarCtrl properties
my $calendar = $fbp->find_first(
	isa => 'FBP::CalendarCtrl',
);
isa_ok( $calendar, 'FBP::CalendarCtrl' );
is( $calendar->name, 'm_calendar1', '->name' );
is( $calendar->style, 'wxCAL_SHOW_HOLIDAYS', '->style' );

# ScrolledWindow properties
my $scrolled = $fbp->find_first(
	isa => 'FBP::ScrolledWindow',
);
isa_ok( $scrolled, 'FBP::ScrolledWindow' );
is( $scrolled->name, 'm_scrolledWindow2', '->name' );
is( $scrolled->scroll_rate_x, 5, '->scroll_rate_x' );
is( $scrolled->scroll_rate_y, 5, '->scroll_rate_y' );

# StdDialogButtonSizer properties
my $buttonsizer = $fbp->find_first(
	isa => 'FBP::StdDialogButtonSizer',
);
isa_ok( $buttonsizer, 'FBP::StdDialogButtonSizer' );
is( $buttonsizer->name, 'm_sdbSizer1', '->name' );
is( $buttonsizer->OK,          0, '->OK'          );
is( $buttonsizer->Yes,         1, '->Yes'         );
is( $buttonsizer->Save,        0, '->Save'        );
is( $buttonsizer->Apply,       0, '->Apply'       );
is( $buttonsizer->No,          1, '->No'          );
is( $buttonsizer->Cancel,      1, '->Cancel'      );
is( $buttonsizer->Help,        0, '->Help'        );
is( $buttonsizer->ContextHelp, 0, '->ContextHelp' );

# GridBagSizer properties
my $gridbag = $fbp->find_first(
	isa => 'FBP::GridBagSizer',
);
isa_ok( $gridbag, 'FBP::GridBagSizer' );
is( $gridbag->name, 'gbSizer1', '->name' );
is( $gridbag->empty_cell_size, '', '->empty_cell_sizer' );
is( $gridbag->vgap, '0', '->vgap' );
is( $gridbag->hgap, '10', '->hgap' );
is( $gridbag->growablerows, '0', '->growablerows' );
is( $gridbag->growablecols, '0', '->growablecols' );
is( $gridbag->flexible_direction, 'wxBOTH', '->flexible_direction' );
is( $gridbag->non_flexible_grow_mode, 'wxFLEX_GROWMODE_SPECIFIED', '->non_flexible_grow_mode' );

# GridBagSizerItem properties
my $gridbagsizeritem = $fbp->find_first(
	isa => 'FBP::GridBagSizerItem',
);
isa_ok( $gridbagsizeritem, 'FBP::GridBagSizerItem' );
ok( $gridbagsizeritem->does('FBP::SizerItemBase'), 'DOES sizer item base' );
is( $gridbagsizeritem->row, 0, '->row' );
is( $gridbagsizeritem->column, 0, '->column' );
is( $gridbagsizeritem->rowspan, 1, '->rowspan' );
is( $gridbagsizeritem->colspan, 2, '->colspan' );
is( $gridbagsizeritem->border, 5, '->border' );
is( $gridbagsizeritem->flag, 'wxALIGN_CENTER_HORIZONTAL|wxALL', '->flag' );

# Notebook properties
my $notebook = $fbp->find_first(
	isa => 'FBP::Notebook',
);
isa_ok( $notebook, 'FBP::Notebook' );
is( $notebook->name, 'm_notebook1', '->name' );
is( $notebook->bitmapsize, '', '->bitmapsize' );
is( $notebook->style, '', '->style' );

# NotebookPage properties
my $notebookpage = $fbp->find_first(
	isa => 'FBP::NotebookPage',
);
isa_ok( $notebookpage, 'FBP::NotebookPage' );
is( $notebookpage->label, 'Checkboxes', '->label' );
is( $notebookpage->bitmap, '', '->bitmap' );
is( $notebookpage->select, 1, '->select' );

# RadioButton properties
my $radiobutton = $fbp->find_first(
	isa => 'FBP::RadioButton',
);
isa_ok( $radiobutton, 'FBP::RadioButton' );
is( $radiobutton->name, 'm_radioBtn1', '->name' );
is( $radiobutton->label, 'Choose Me!', '->label' );
is( $radiobutton->style, 'wxRB_GROUP', '->style' );
is( $radiobutton->value, 0, '->value' );

# Animation properties
my $animation = $fbp->find_first(
	isa => 'FBP::AnimationCtrl',
);
isa_ok( $animation, 'FBP::AnimationCtrl' );
is( $animation->name, 'm_animCtrl1', '->name' );
is( $animation->style, 'wxAC_DEFAULT_STYLE', '->style' );
is( $animation->animation, '', '->animation' );
is( $animation->inactive_bitmap, '', '->inactive_bitmap' );
is( $animation->play, 0, '->play' );

# TreeCtrl properties
my $treectrl = $fbp->find_first(
	isa => 'FBP::TreeCtrl',
);
isa_ok( $treectrl, 'FBP::TreeCtrl' );
is( $treectrl->name, 'm_treeCtrl1', '->name' );
is( $treectrl->style, 'wxTR_DEFAULT_STYLE', '->style' );

# Choicebook properties
my $choicebook = $fbp->find_first(
	isa => 'FBP::Choicebook',
);
isa_ok( $choicebook, 'FBP::Choicebook' );
is( $choicebook->name, 'm_choicebook1', '->name' );
is( $choicebook->style, 'wxCHB_DEFAULT', '->style' );

# RichTextCtrl properties
my $richtext = $fbp->find_first(
	isa => 'FBP::RichTextCtrl',
);
isa_ok( $richtext, 'FBP::RichTextCtrl' );
is( $richtext->name, 'm_richText1', '->name' );

# wxGrid properties
my $grid = $fbp->find_first(
	isa => 'FBP::Grid',
);
isa_ok( $grid, 'FBP::Grid' );
is( $grid->name, 'm_grid1', '->name' );
is( $grid->rows, 5, '->rows' );
is( $grid->cols, 5, '->cols' );

# wxScrollBar properties
my $scroll = $fbp->find_first(
	isa => 'FBP::ScrollBar',
);
isa_ok( $scroll, 'FBP::ScrollBar' );
is( $scroll->name, 'm_scrollBar1', '->name' );
is( $scroll->value, 0, '->value' );
is( $scroll->range, 100, '->range' );
is( $scroll->thumbsize, 1, '->thumbsize' );
is( $scroll->pagesize, 1, '->pagesize' );
is( $scroll->style, 'wxSB_HORIZONTAL', '->style' );

# wxSpinButton properties
my $spin = $fbp->find_first(
	isa => 'FBP::SpinButton',
);
isa_ok( $spin, 'FBP::SpinButton' );
is( $spin->name, 'm_spinBtn1', '->name' );
is( $spin->style, 'wxSP_HORIZONTAL', '->style' );
