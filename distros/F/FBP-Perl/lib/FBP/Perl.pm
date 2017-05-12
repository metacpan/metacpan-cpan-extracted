package FBP::Perl;

=pod

=head1 NAME

FBP::Perl - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $fbp = FBP->new;
  $fbp->parse_file( 'MyProject.fbp' );
  
  my $generator = FBP::Perl->new(
      project => $fbp->project
  );
  
  open( FILE, '>', 'MyDialog.pm');
  print $generator->flatten(
      $generator->dialog_class(
          $fbp->dialog('MyDialog')
      )
  );
  close FILE;

=head1 DESCRIPTION

B<FBP::Perl> is a cross-platform Perl code generator for the cross-platform
L<wxFormBuilder|http://wxformbuilder.org/> GUI designer application.

Used with the L<FBP> module for parsing native wxFormBuilder save files, it
allows the production of complete standalone classes representing a complete
L<Wx> dialog, frame or panel as it appears in wxFormBuilder.

As code generators go, the Wx code produced by B<FBP::Perl> is remarkebly
readable. The produced code can be used either as a starter template which
you modify, or as a pristine class which you subclass in order to customise.

Born from the L<Padre> Perl IDE project, the code generation API provided by
B<FBP::Perl> is also extremely amenable to being itself subclassed.

This allows you to relatively easily write customised code generators that
produce output more closely tailored to your large Wx-based application, or
to automatically integrate Perl Tidy or other beautifiers into your workflow.

=head1 METHODS

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use B                  ();
use Scalar::Util  1.19 ();
use Params::Util  1.00 ();
use FBP           0.41 ();

our $VERSION    = '0.78';
our $COMPATIBLE = '0.67';

# Event Macro Binding Table
our %MACRO = (
	# Common low level events
	OnEraseBackground         => [ 1, 'EVT_ERASE_BACKGROUND'           ],
	OnPaint                   => [ 1, 'EVT_PAINT'                      ],
	OnUpdateUI                => [ 2, 'EVT_UPDATE_UI'                  ],

	# wxActivateEvent
	OnActivate                => [ 1, 'EVT_ACTIVATE'                   ],
	OnActivateApp             => [ 1, 'EVT_ACTIVATE_APP'               ],

	# wxCalendar
	OnCalendar                => [ 2, 'EVT_CALENDAR'                   ],
	OnCalendarSelChanged      => [ 2, 'EVT_CALENDAR_SEL_CHANGED'       ],
	OnCalendarDay             => [ 2, 'EVT_CALENDAR_DAY'               ],
	OnCalendarMonth           => [ 2, 'EVT_CALENDAR_MONTH'             ],
	OnCalendarYear            => [ 2, 'EVT_CALENDAR_YEAR'              ],
	OnCalendarWeekDayClicked  => [ 2, 'EVT_CALENDAR_WEEKDAY_CLICKED'   ],

	# wxChoicebook
	OnChoicebookPageChanged   => [ 2, 'EVT_CHOICEBOOK_PAGE_CHANGED'    ],
	OnChoicebookPageChanging  => [ 2, 'EVT_CHOICEBOOK_PAGE_CHANGING'   ],

	# wxCommandEvent
	OnButtonClick             => [ 2, 'EVT_BUTTON'                     ],
	OnToggleButton            => [ 2, 'EVT_TOGGLEBUTTON'               ],
	OnCheckBox                => [ 2, 'EVT_CHECKBOX'                   ],
	OnChoice                  => [ 2, 'EVT_CHOICE'                     ],
	OnCombobox                => [ 2, 'EVT_COMBOBOX'                   ],
	OnListBox                 => [ 2, 'EVT_LISTBOX'                    ],
	OnListBoxDClick           => [ 2, 'EVT_LISTBOX_DCLICK'             ],
	OnText                    => [ 2, 'EVT_TEXT'                       ],
	OnTextEnter               => [ 2, 'EVT_TEXT_ENTER'                 ],
	OnMenu                    => [ 2, 'EVT_MENU'                       ],

	# wxColourPickerCtrl
	OnColourChanged           => [ 2, 'EVT_COLOURPICKER_CHANGED'       ],

	# wxCloseEvent
	OnClose                   => [ 1, 'EVT_CLOSE'                      ],

	# wxDatePickerCtrl
	OnDateChanged             => [ 2, 'EVT_DATE_CHANGED'               ],

	# wxFilePickerCtrl
	OnFileChanged             => [ 2, 'EVT_FILEPICKER_CHANGED'         ],

	# wxFocusEvent
	OnKillFocus               => [ 1, 'EVT_KILL_FOCUS'                 ],
	OnSetFocus                => [ 1, 'EVT_SET_FOCUS'                  ],

	# wxFontPickerCtrl
	OnFontChanged             => [ 2, 'EVT_FONTPICKER_CHANGED'         ],

	# wxGrid
	OnGridCellLeftClick       => [ 1, 'EVT_GRID_CELL_LEFT_CLICK'       ],
	OnGridCellRightClick      => [ 1, 'EVT_GRID_CELL_RIGHT_CLICK'      ],
	OnGridCellLeftDClick      => [ 1, 'EVT_GRID_CELL_LEFT_DCLICK'      ],
	OnGridCellRightDClick     => [ 1, 'EVT_GRID_CELL_RIGHT_DCLICK'     ],
	OnGridLabelLeftClick      => [ 1, 'EVT_GRID_LABEL_LEFT_CLICK'      ],
	OnGridLabelRightClick     => [ 1, 'EVT_GRID_LABEL_RIGHT_CLICK'     ],
	OnGridLabelLeftDClick     => [ 1, 'EVT_GRID_LABEL_LEFT_DCLICK'     ],
	OnGridLabelRightDClick    => [ 1, 'EVT_GRID_LABEL_RIGHT_DCLICK'    ],
	OnGridCellChange          => [ 1, 'EVT_GRID_CELL_CHANGE'           ],
	OnGridSelectCell          => [ 1, 'EVT_GRID_SELECT_CELL'           ],
	OnGridEditorHidden        => [ 1, 'EVT_GRID_EDITOR_HIDDEN'         ],
	OnGridEditorShown         => [ 1, 'EVT_GRID_EDITOR_SHOWN'          ],
	OnGridColSize             => [ 1, 'EVT_GRID_COL_SIZE'              ],
	OnGridRowSize             => [ 1, 'EVT_GRID_ROW_SIZE'              ],
	OnGridRangeSelect         => [ 1, 'EVT_GRID_RANGE_SELECT'          ],
	OnGridEditorCreated       => [ 1, 'EVT_GRID_EDITOR_CREATED'        ],

	# Not sure why wxFormBuilder makes these grid event duplicates
	# so we just slavishly cargo cult what they do in the C code.
	OnGridCmdCellLeftClick    => [ 1, 'EVT_GRID_CELL_LEFT_CLICK'       ],
	OnGridCmdCellRightClick   => [ 1, 'EVT_GRID_CELL_RIGHT_CLICK'      ],
	OnGridCmdCellLeftDClick   => [ 1, 'EVT_GRID_CELL_LEFT_DCLICK'      ],
	OnGridCmdCellRightDClick  => [ 1, 'EVT_GRID_CELL_RIGHT_DCLICK'     ],
	OnGridCmdLabelLeftClick   => [ 1, 'EVT_GRID_LABEL_LEFT_CLICK'      ],
	OnGridCmdLabelRightClick  => [ 1, 'EVT_GRID_LABEL_RIGHT_CLICK'     ],
	OnGridCmdLabelLeftDClick  => [ 1, 'EVT_GRID_LABEL_LEFT_DCLICK'     ],
	OnGridCmdLabelRightDClick => [ 1, 'EVT_GRID_LABEL_RIGHT_DCLICK'    ],
	OnGridCmdCellChange       => [ 1, 'EVT_GRID_CELL_CHANGE'           ],
	OnGridCmdSelectCell       => [ 1, 'EVT_GRID_SELECT_CELL'           ],
	OnGridCmdEditorHidden     => [ 1, 'EVT_GRID_EDITOR_HIDDEN'         ],
	OnGridCmdEditorShown      => [ 1, 'EVT_GRID_EDITOR_SHOWN'          ],
	OnGridCmdColSize          => [ 1, 'EVT_GRID_COL_SIZE'              ],
	OnGridCmdRowSize          => [ 1, 'EVT_GRID_ROW_SIZE'              ],
	OnGridCmdRangeSelect      => [ 1, 'EVT_GRID_RANGE_SELECT'          ],
	OnGridCmdEditorCreated    => [ 1, 'EVT_GRID_EDITOR_CREATED'        ],

	# wxHtmlWindow
	OnHtmlCellClicked         => [ 2, 'EVT_HTML_CELL_CLICKED'          ],
	OnHtmlCellHover           => [ 2, 'EVT_HTML_CELL_HOVER'            ],
	OnHtmlLinkClicked         => [ 2, 'EVT_HTML_LINK_CLICKED'          ],

	# wxIconizeEvent
	OnIconize                 => [ 1, 'EVT_ICONIZE'                    ],

	# wxIdleEvent
	OnIdle                    => [ 1, 'EVT_IDLE'                       ],

	# wxInitDialogEvent
	OnInitDialog              => [ 1, 'EVT_INIT_DIALOG'                ],

	# wxKeyEvent
	OnChar                    => [ 1, 'EVT_CHAR'                       ],
	OnKeyDown                 => [ 1, 'EVT_KEY_DOWN'                   ],
	OnKeyUp                   => [ 1, 'EVT_KEY_UP'                     ],

	# wxListEvent
	OnListBeginDrag           => [ 2, 'EVT_LIST_BEGIN_DRAG'            ],
	OnListBeginRDrag          => [ 2, 'EVT_LIST_BEGIN_RDRAG'           ],
	OnListBeginLabelEdit      => [ 2, 'EVT_LIST_BEGIN_LABEL_EDIT'      ],
	OnListCacheHint           => [ 2, 'EVT_LIST_CACHE_HINT'            ],
	OnListEndLabelEdit        => [ 2, 'EVT_LIST_END_LABEL_EDIT'        ],
	OnListDeleteItem          => [ 2, 'EVT_LIST_DELETE_ITEM'           ],
	OnListDeleteAllItems      => [ 2, 'EVT_LIST_DELETE_ALL_ITEMS'      ],
	OnListInsertItem          => [ 2, 'EVT_LIST_INSERT_ITEM'           ],
	OnListItemActivated       => [ 2, 'EVT_LIST_ITEM_ACTIVATED'        ],
	OnListItemSelected        => [ 2, 'EVT_LIST_ITEM_SELECTED'         ],
	OnListItemDeselected      => [ 2, 'EVT_LIST_ITEM_DESELECTED'       ],
	OnListItemFocused         => [ 2, 'EVT_LIST_ITEM_FOCUSED'          ],
	OnListItemMiddleClick     => [ 2, 'EVT_LIST_MIDDLE_CLICK'          ],
	OnListItemRightClick      => [ 2, 'EVT_LIST_RIGHT_CLICK'           ],
	OnListKeyDown             => [ 2, 'EVT_LIST_KEY_DOWN'              ],
	OnListColClick            => [ 2, 'EVT_LIST_COL_CLICK'             ],
	OnListColRightClick       => [ 2, 'EVT_LIST_COL_RIGHT_CLICK'       ],
	OnListColBeginDrag        => [ 2, 'EVT_LIST_COL_BEGIN_DRAG'        ],
	OnListColDragging         => [ 2, 'EVT_LIST_COL_DRAGGING'          ],
	OnListColEndDrag          => [ 2, 'EVT_LIST_COL_END_DRAG'          ],

	# wxMenuEvent
	OnMenuSelection           => [ 2, 'EVT_MENU'                       ],

	# wxMouseEvent
	OnEnterWindow             => [ 1, 'EVT_ENTER_WINDOW'               ],
	OnLeaveWindow             => [ 1, 'EVT_LEAVE_WINDOW'               ],
	OnLeftDClick              => [ 1, 'EVT_LEFT_DCLICK'                ],
	OnLeftDown                => [ 1, 'EVT_LEFT_DOWN'                  ],
	OnLeftUp                  => [ 1, 'EVT_LEFT_UP'                    ],
	OnMiddleDClick            => [ 1, 'EVT_MIDDLE_DCLICK'              ],
	OnMiddleDown              => [ 1, 'EVT_MIDDLE_DOWN'                ],
	OnMiddleUp                => [ 1, 'EVT_MIDDLE_UP'                  ],
	OnMotion                  => [ 1, 'EVT_MOTION'                     ],
	OnMouseEvents             => [ 1, 'EVT_MOUSE_EVENTS'               ],
	OnMouseWheel              => [ 1, 'EVT_MOUSEWHEEL'                 ],
	OnRightDClick             => [ 1, 'EVT_RIGHT_DCLICK'               ],
	OnRightDown               => [ 1, 'EVT_RIGHT_DOWN'                 ],
	OnRightUp                 => [ 1, 'EVT_RIGHT_UP'                   ],

	# wxNotebookEvent
	OnNotebookPageChanging    => [ 2, 'EVT_NOTEBOOK_PAGE_CHANGING'     ],
	OnNotebookPageChanged     => [ 2, 'EVT_NOTEBOOK_PAGE_CHANGED'      ],

	# wxRadioBox
	OnRadioBox                => [ 2, 'EVT_RADIOBOX'                   ],

	# wxRadioButton
	OnRadioButton             => [ 2, 'EVT_RADIOBUTTON'                ],

	# wxSizeEvent
	OnSize                    => [ 1, 'EVT_SIZE'                       ],

	# wxStdDialogButtonSizer (placeholders)
	OnOKButtonClick           => [                                  ],
	OnYesButtonClick          => [                                  ],
	OnSaveButtonClick         => [                                  ],
	OnApplyButtonClick        => [                                  ],
	OnNoButtonClick           => [                                  ],
	OnCancelButtonClick       => [                                  ],
	OnHelpButtonClick         => [                                  ],
	OnContextTextButtonClick  => [                                  ],

	# wxSearchCtrl
	OnSearchButton            => [ 2, 'EVT_SEARCHCTRL_SEARCH_BTN'      ],
	OnCancelButton            => [ 2, 'EVT_SEARCHCTRL_CANCEL_BTN'      ],

	# wxSpinButton
	OnSpin                    => [ 1, 'EVT_SCROLL_THUMBTRACK'          ],
	OnSpinUp                  => [ 1, 'EVT_SCROLL_LINEUP'              ],
	OnSpinDown                => [ 1, 'EVT_SCROLL_LINEDOWN'            ],

	# wxSplitterEvent
	OnSplitterSashPosChanging => [ 2, 'EVT_SPLITTER_SASH_POS_CHANGING' ],
	OnSplitterSashPosChanged  => [ 2, 'EVT_SPLITTER_SASH_POS_CHANGED'  ],
	OnSplitterUnsplit         => [ 2, 'EVT_SPLITTER_UNSPLIT'           ],
	OnSplitterDClick          => [ 2, 'EVT_SPLITTER_DCLICK'            ],

	# wxToolbar events
	OnToolClicked             => [ 2, 'EVT_TOOL'                       ],
	OnToolRClicked            => [ 2, 'EVT_TOOL_RCLICKED'              ],
	OnToolEnter               => [ 2, 'EVT_TOOL_ENTER'                 ],

	# wxTreeCtrl events
	OnTreeGetInfo             => [ 2, 'EVT_TREE_GET_INFO'              ],
	OnTreeSetInfo             => [ 2, 'EVT_TREE_SET_INFO'              ],
	OnTreeItemGetTooltip      => [ 2, 'EVT_TREE_ITEM_GETTOOLTIP'       ],
	OnTreeStateImageClick     => [ 2, 'EVT_TREE_STATE_IMAGE_CLICK'     ],
	OnTreeBeginDrag           => [ 2, 'EVT_TREE_BEGIN_DRAG'            ],
	OnTreeBeginRDrag          => [ 2, 'EVT_TREE_BEGIN_RDRAG'           ],
	OnTreeEndDrag             => [ 2, 'EVT_TREE_END_DRAG'              ],
	OnTreeBeginLabelEdit      => [ 2, 'EVT_TREE_BEGIN_LABEL_EDIT'      ],
	OnTreeEndLabelEdit        => [ 2, 'EVT_TREE_END_LABEL_EDIT'        ],
	OnTreeItemActivated       => [ 2, 'EVT_TREE_ITEM_ACTIVATED'        ],
	OnTreeItemCollapsed       => [ 2, 'EVT_TREE_ITEM_COLLAPSED'        ],
	OnTreeItemCollapsing      => [ 2, 'EVT_TREE_ITEM_COLLAPSING'       ],
	OnTreeItemExpanded        => [ 2, 'EVT_TREE_ITEM_EXPANDED'         ],
	OnTreeItemExpanding       => [ 2, 'EVT_TREE_ITEM_EXPANDING'        ],
	OnTreeItemRightClick      => [ 2, 'EVT_TREE_ITEM_RIGHT_CLICK'      ],
	OnTreeItemMiddleClick     => [ 2, 'EVT_TREE_ITEM_MIDDLE_CLICK'     ],
	OnTreeSelChanged          => [ 2, 'EVT_TREE_SEL_CHANGED'           ],
	OnTreeSelChanging         => [ 2, 'EVT_TREE_SEL_CHANGING'          ],
	OnTreeKeyDown             => [ 2, 'EVT_TREE_KEY_DOWN'              ],
	OnTreeItemMenu            => [ 2, 'EVT_TREE_ITEM_MENU'             ],
);

# Event Connect Binding Table
our %CONNECT = (
	# Common low level events
	# OnEraseBackground        => 'wxEVT_ERASE_BACKGROUND',
	# OnPaint                  => 'wxEVT_PAINT',
	# OnUpdateUI               => 'wxEVT_UPDATE_UI',

# # 	wxActivateEvent
	# OnActivate               => 'wxEVT_ACTIVATE',
	# OnActivateApp            => 'wxEVT_ACTIVATE_APP',

# # 	wxCalendar
	# OnCalendar               => 'wxEVT_CALENDAR_DOUBLECLICKED',
	# OnCalendarSelChanged     => 'wxEVT_CALENDAR_SEL_CHANGED',
	# OnCalendarDay            => 'wxEVT_CALENDAR_DAY_CHANGED',
	# OnCalendarMonth          => 'wxEVT_CALENDAR_MONTH_CHANGED',
	# OnCalendarYear           => 'wxEVT_CALENDAR_YEAR_CHANGED',
	# OnCalendarWeekDayClicked => 'wxEVT_CALENDAR_WEEKDAY_CLICKED',

# # 	wxChoicebook
	# OnChoicebookPageChanged  => 'wxEVT_COMMAND_CHOICEBOOK_PAGE_CHANGED',
	# OnChoicebookPageChanging => 'wxEVT_COMMAND_CHOICEBOOK_PAGE_CHANGING',

# # 	wxCommandEvent
	# OnButtonClick            => 'wxEVT_COMMAND_BUTTON_CLICKED',
	# OnCheckBox               => 'wxEVT_COMMAND_CHECKBOX_CLICKED',
	# OnChoice                 => 'wxEVT_COMMAND_CHOICE_SELECTED',
	# OnCombobox               => 'wxEVT_COMMAND_COMBOBOX_SELECTED',
	# OnListBox                => 'wxEVT_COMMAND_LISTBOX_SELECTED',
	# OnListBoxDClick          => 'wxEVT_COMMAND_LISTBOX_DOUBLECLICKED',
	# OnText                   => 'wxEVT_COMMAND_TEXT_UPDATED',
	# OnTextEnter              => 'wxEVT_COMMAND_TEXT_ENTER',
	# OnMenu                   => 'wxEVT_COMMAND_MENU_SELECTED',

# # 	wxColourPickerCtrl
	# OnColourChanged          => 'wxEVT_COLOURPICKER_CHANGED',

# # 	wxCloseEvent
	# OnClose                  => 'wxEVT_CLOSE_WINDOW',

# # 	wxDatePickerCtrl
	# OnDateChanged            => 'wxEVT_DATE_CHANGED',

# # 	wxFilePickerCtrl
	# OnFileChanged            => 'wxEVT_FILEPICKER_CHANGED',

# # 	wxFocusEvent
	# OnKillFocus              => 'wxEVT_KILL_FOCUS',
	# OnSetFocus               => 'wxEVT_SET_FOCUS',

# # 	wxFontPickerCtrl
	# OnFontChanged            => 'wxEVT_FONTPICKER_CHANGED',
);





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params and apply defaults
	unless ( Params::Util::_INSTANCE($self->project, 'FBP::Project') ) {
		die "Missing or invalid 'project' param";
	}
	unless ( defined $self->version ) {
		$self->{version} = '0.01';
	}
	unless ( defined Params::Util::_STRING($self->version) ) {
		die "Missing or invalid 'version' param";
	}
	unless ( defined $self->prefix ) {
		$self->{prefix} = 0;
	}
	unless ( defined Params::Util::_NONNEGINT($self->prefix) ) {
		die "Missing of invalid 'prefix' param";
	}
	unless ( defined $self->i18n ) {
		$self->{i18n} = $self->project->internationalize;
	}
	unless ( defined $self->i18n_trim ) {
		$self->{i18n_trim} = 0;
	}
	$self->{i18n_trim} = $self->i18n_trim ? 1 : 0;
	unless ( defined $self->nocritic ) {
		$self->{nocritic} = 0;
	}
	$self->{nocritic}  = $self->nocritic  ? 1 : 0;
	$self->{shim}      = $self->shim      ? 1 : 0;
	$self->{shim_deep} = $self->shim_deep ? 1 : 0;
	$self->{shim_deep} = 0 unless $self->shim;

	return $self;
}

sub project {
	$_[0]->{project};
}

sub version {
	$_[0]->{version};
}

sub prefix {
	$_[0]->{prefix};
}

sub i18n {
	$_[0]->{i18n};
}

sub i18n_trim {
	$_[0]->{i18n_trim};
}

sub nocritic {
	$_[0]->{nocritic};
}

sub shim {
	$_[0]->{shim};
}

sub shim_deep {
	$_[0]->{shim_deep};
}





######################################################################
# Project Wide Generators

sub project_header {
	my $self  = shift;
	my $lines = [];

	# If the code is being generated for use in a project that uses
	# Perl::Critic then we could generate all kinds of critic warnings the
	# maintainer can't do anything about it. So we nocritic the whole file.
	if ( $self->nocritic ) {
		push @$lines, (
			"## no critic",
		);
	}

	# Add an extra spacer line if needed
	if ( @$lines ) {
		push @$lines, "";
	}

	return $lines;
}

sub project_pragma {
	my $self = shift;
	my $perl = $self->project_perl;
	return [
		"use $perl;",
		( $self->project_utf8 ? "use utf8;" : () ),
		"use strict;",
		"use warnings;",
	]
}

sub project_version {
	my $self    = shift;
	my $version = $self->version;

	return [
		"our \$VERSION = '$version';",
	];
}

sub project_perl {
	my $self = shift;
	return $self->project_utf8 ? '5.008005' : '5.008';
}

sub project_utf8 {
	my $self = shift;
	return $self->project->encoding eq 'UTF-8';
}





######################################################################
# Launch Script Generator

sub script_app {
	my $self    = shift;
	my $header  = $self->script_header;
	my $pragma  = $self->script_pragma;
	my $package = $self->app_package;
	my $version = $self->script_version;

	return [
		"#!/usr/bin/perl",
		"",
		@$header,
		@$pragma,
		"use $package ();",
		"",
		@$version,
		"",
		"$package->run;",
		"",
		"exit(0);",
	];
}

sub script_header {
	shift->project_header(@_);
}

sub script_pragma {
	shift->project_pragma(@_);
}

sub script_version {
	$_[0]->project_version;
}





######################################################################
# Wx::App Generators

sub app_class {
	my $self    = shift;
	my $package = $self->app_package;
	my $header  = $self->app_header;
	my $pragma  = $self->app_pragma;
	my $wx      = $self->app_wx;
	my $forms   = $self->app_forms;
	my $version = $self->app_version;
	my $isa     = $self->app_isa;

	# Find the first frame, our default top frame
	my $frame   = $self->project->find_first( isa => 'FBP::Frame' );
	my $require = $self->shim
		? $self->shim_package($frame)
		: $self->form_package($frame);

	return [
		"package $package;",
		"",
		@$header,
		@$pragma,
		@$wx,
		# @$forms,
		"",
		@$version,
		@$isa,
		"",
		"sub run {",
		$self->indent(
			"my \$class = shift;",
			"my \$self  = \$class->new(\@_);",
			"return \$self->MainLoop;",
		),
		"}",
		"",
		"sub OnInit {",
		$self->indent(
			"my \$self = shift;",
			"",
			"# Create the primary frame",
			"require $require;",
			"\$self->SetTopWindow( $require->new );",
			"",
			"# Don't flash frames on the screen in tests",
			"unless ( \$ENV{HARNESS_ACTIVE} ) {",
			$self->indent(
				"\$self->GetTopWindow->Show(1);",
			),
			"}",
			"",
			"return 1;",
		),
		"}",
		"",
		"1;"
	];
}

# For the time being just use the plain name
sub app_package {
	my $self = shift;

	# Use the C++ namespace setting if we can
	if ( $self->project->namespace ) {
		return join '::', $self->list( $self->project->namespace );
	}

	# Fall back to the plain name
	return $self->project->name;
}

sub app_header {
	shift->project_header(@_);
}

sub app_pragma {
	shift->project_pragma(@_);
}

sub app_wx {
	my $self    = shift;
	my $project = $self->project;
	my @lines   = (
		"use Wx 0.98 ':everything';",
	);
	if ( $project->find_first( isa => 'FBP::HtmlWindow' ) ) {
		push @lines, "use Wx::Html ();";
	}
	if ( $project->find_first( isa => 'FBP::DatePickerCtrl' ) ) {
		push @lines, "use Wx::DateTime ();";
	}
	if ( $self->i18n ) {
		push @lines, "use Wx::Locale ();";
	}
	return \@lines;
}

sub app_forms {
	my $self  = shift;
	my @forms = $self->project->forms;
	my @names = $self->shim
		? ( map { $self->shim_package($_) } @forms )
		: ( map { $self->form_package($_) } @forms );

	return [
		map {
			"use $_ ();"
		} @names
	];
}

sub app_version {
	shift->project_version(@_);
}

sub app_isa {
	my $self = shift;
	return $self->ourisa(
		$self->app_super(@_)
	);
}

sub app_super {
	return 'Wx::App';
}





######################################################################
# Shim Generators

sub shim_class {
	my $self = shift;
	my $form = shift;
	my $package = $self->shim_package($form);
	my $header  = $self->shim_header($form);
	my $pragma  = $self->shim_pragma($form);
	my $more    = $self->shim_more($form);
	my $version = $self->shim_version($form);
	my $isa     = $self->shim_isa($form);

	return [
		"package $package;",
		"",
		@$header,
		@$pragma,
		@$more,
		"",
		@$version,
		@$isa,
		"",
		"1;",
	];
}

sub shim_package {
	my $self = shift;
	my $form = shift;
	my $name = $form->name;

	# If the project has a namespace nest the name inside it
	if ( $self->project->namespace ) {
		if ( $self->shim_deep ) {
			my $type = Scalar::Util::blessed($form);
			$type =~ s/^.*?(\w+)$/$1/;
			$name = join '::', $type, $name;
		}
		$name = join '::', $self->app_package, $name;
	}

	# Otherwise the name is the full namespace
	return $name;
}

sub shim_header {
	shift->project_header(@_);
}

sub shim_pragma {
	shift->project_pragma(@_);
}

sub shim_more {
	my $self = shift;
	my $form = shift;

	# We only need to load our super class
	my $super = $self->form_package($form);

	return [
		"use $super ();",
	];
}

sub shim_version {
	my $self = shift;
	my $form = shift;

	# Ignore the form and inherit from the parent project
	return $self->project_version;
}

sub shim_isa {
	my $self = shift;
	return $self->ourisa(
		$self->shim_super(@_)
	);
}

sub shim_super {
	shift->form_package(@_);
}





######################################################################
# Form Generators

sub form_class {
	my $self    = shift;
	my $form    = shift;
	my $package = $self->form_package($form);
	my $header  = $self->form_header($form);
	my $pragma  = $self->form_pragma($form);
	my $wx      = $self->form_wx($form);
	my $more    = $self->form_custom($form);
	my $version = $self->form_version($form);
	my $isa     = $self->form_isa($form);
	my $new     = $self->form_new($form);
	my $methods = $self->form_methods($form);

	return [
		"package $package;",
		"",
		@$header,
		@$pragma,
		@$wx,
		@$more,
		"",
		@$version,
		@$isa,
		"",
		@$new,
		@$methods,
		"",
		"1;",
	];
}

sub dialog_class {
	shift->form_class(@_);
}

sub frame_class {
	shift->form_class(@_);
}

sub panel_class {
	shift->form_class(@_);
}

sub form_package {
	my $self = shift;
	my $form = shift;

	unless ( $self->project->namespace ) {
		# A simple standalone full namespace
		if ( $self->shim ) {
			return join '::', $form->name, 'FBP';
		} else {
			return $form->name;
		}
	}

	# Nest the name inside the project namespace
	if ( $self->shim ) {
		return join(
			'::',
			$self->app_package,
			'FBP',
			$form->name,
		);
	} else {
		return join(
			'::',
			$self->app_package,
			$form->name,
		);
	}
}

sub form_header {
	shift->project_header(@_);
}

sub form_pragma {
	shift->project_pragma(@_);
}

sub form_wx {
	my $self  = shift;
	my $topic = shift;
	my $lines = [
		"use Wx 0.98 ':everything';",
	];
	if ( $self->find_plain( $topic => 'FBP::HtmlWindow' ) ) {
		push @$lines, "use Wx::Html ();";
	}
	if ( $self->find_plain( $topic => 'FBP::Grid' ) ) {
		push @$lines, "use Wx::Grid ();";
	}
	if ( $self->find_plain( $topic => 'FBP::CalendarCtrl' ) ) {
		push @$lines, "use Wx::Calendar ();";
		push @$lines, "use Wx::DateTime ();";
	} elsif ( $self->find_plain( $topic => 'FBP::DatePickerCtrl' ) ) {
		push @$lines, "use Wx::DateTime ();";
	}
	if ( $self->find_plain( $topic => 'FBP::RichTextCtrl' ) ) {
		push @$lines, "use Wx::RichText ();";
	}
	return $lines;
}

sub form_custom {
	my $self = shift;
	my $form = shift;

	# Search for all the custom classes and load them
	my %seen = ();
	return [
		map {
			"use $_ ();"
		} sort grep {
			not $seen{$_}++
		} map {
			$_->header
		} $form->find( isa => 'FBP::Window' )
	];
}

sub form_version {
	my $self = shift;
	my $form = shift;

	# Ignore the form and inherit from the parent project
	return $self->project_version;
}

sub form_isa {
	my $self  = shift;
	return $self->ourisa(
		$self->form_super(@_)
	);
}

sub form_super {
	my $self = shift;
	my $form = shift;
	if ( $form->isa('FBP::Dialog') ) {
		return 'Wx::Dialog';
	} elsif ( $form->isa('FBP::Frame') ) {
		return 'Wx::Frame';
	} elsif ( $form->isa('FBP::Panel') ) {
		return 'Wx::Panel';
	} else {
		die "Unsupported form " . ref($form);
	}
}

sub form_new {
	my $self    = shift;
	my $form    = shift;
	my $super   = $self->form_supernew($form);
	my @windows = $self->children_create($form);
	my @sizers  = $self->form_sizers($form);
	my $status  = $form->find_first( isa => 'FBP::StatusBar' );

	my @lines = ();
	if ( $self->form_setsizehints($form) ) {
		my $minsize = $self->wxsize($form->minimum_size);
		my $maxsize = $self->wxsize($form->maximum_size);
		push @lines, "\$self->SetSizeHints( $minsize, $maxsize );";
	}
	if ( $status ) {
		my $statusbar = $self->statusbar_create($status, $form);
		push @lines, @$statusbar;
	}

	# Add common modifications
	push @lines, $self->window_changes($form);
	push @lines, $self->object_bindings($form);

	return $self->nested(
		"sub new {",
		"my \$class  = shift;",
		"my \$parent = shift;",
		"",
		$super,
		@lines,
		"",
		( map { @$_, "" } grep { scalar @$_ } @windows ),
		( map { @$_, "" } grep { scalar @$_ } @sizers  ),
		"return \$self;",
		"}",
	);
}

sub form_supernew {
	my $self  = shift;
	my $form  = shift;
	my $lines = undef;

	if ( $form->isa('FBP::Dialog') ) {
		$lines = $self->dialog_supernew($form);
	} elsif ( $form->isa('FBP::Frame') ) {
		$lines = $self->frame_supernew($form);
	} elsif ( $form->isa('FBP::Panel') ) {
		$lines = $self->panel_supernew($form);
	} else {
		die "Unsupported top class " . ref($form);
	}

	return $lines;
}

sub dialog_supernew {
	my $self     = shift;
	my $dialog   = shift;
	my $id       = $self->object_id($dialog);
	my $title    = $self->text( $dialog->title );
	my $position = $self->object_position($dialog);
	my $size     = $self->object_wxsize($dialog);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$title,",
		"$position,",
		"$size,",
		$self->window_style($dialog, 'wxDEFAULT_DIALOG_STYLE'),
		");",
	);
}

sub frame_supernew {
	my $self     = shift;
	my $frame    = shift;
	my $id       = $self->object_id($frame);
	my $title    = $self->text( $frame->title );
	my $position = $self->object_position($frame);
	my $size     = $self->object_wxsize($frame);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$title,",
		"$position,",
		"$size,",
		$self->window_style($frame, 'wxDEFAULT_FRAME_STYLE'),
		");",
	);
}

sub panel_supernew {
	my $self     = shift;
	my $panel    = shift;
	my $id       = $self->object_id($panel);
	my $position = $self->object_position($panel);
	my $size     = $self->object_wxsize($panel);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($panel),
		");",
	);
}

sub form_sizers {
	my $self     = shift;
	my $form     = shift;
	my $sizer    = $self->form_rootsizer($form);
	my $variable = $self->object_variable($sizer);
	my @children = $self->sizer_pack($sizer);
	my $setsize  = $self->window_setsize($form);

	return (
		@children,
		[
			"\$self->$setsize($variable);",
			"\$self->Layout;",
		]
	);
}

sub form_rootsizer {
	my $self   = shift;
	my $form   = shift;
	my @sizers = grep { $_->isa('FBP::Sizer') } @{$form->children};
	unless ( @sizers ) {
		die "Form does not contain any sizers";
	}
	unless ( @sizers == 1 ) {
		die "Form contains more than one root sizer";
	}
	return $sizers[0];
}

sub form_setsizehints {
	my $self = shift;
	my $form = shift;

	# Only dialogs and frames can resize
	if ( $form->isa('FBP::Dialog') or $form->isa('FBP::Frame') ) {
		# If the dialog has size hints, we do need them
		if ( $self->size($form->minimum_size) ) {
			return 1;
		}
		if ( $self->size($form->maximum_size) ) {
			return 1;
		}
	}

	return 0;
}

sub form_methods {
	my $self    = shift;
	my $form    = shift;
	my @objects = (
		$form,
		$form->find( isa => 'FBP::Window' ),
		$form->find( isa => 'FBP::MenuItem' ),
		$form->find( isa => 'FBP::StdDialogButtonSizer' ),
	);
	my %seen    = ();
	my %done    = ();
	my @methods = ();

	# Add the accessor methods
	foreach my $object ( @objects ) {
		next unless $object->can('name');
		next unless $object->can('permission');
		next unless $object->permission eq 'public';

		# Protect against duplicates
		my $name = $object->name;
		if ( $seen{$name}++ ) {
			die "Duplicate method '$name' detected";
		}

		push @methods, $self->object_accessor($object);
	}

	# Add the event handler methods
	foreach my $object ( @objects ) {
		foreach my $event ( sort keys %MACRO ) {
			next unless $object->can($event);

			my $name   = $object->name;
			my $method = $object->$event();
			next unless defined $method;
			next unless length $method;

			# Protect against duplicates
			if ( $seen{$method} ) {
				die "Duplicate method '$method' detected";
			}
			next if $done{$method}++;

			push @methods, $self->object_event($object, $event);
		}
	}

	# Convert back to a single block of lines
	return [
		map { ( "", @$_ ) } grep { scalar @$_ } @methods
	];
}





######################################################################
# Window and Control Generators

sub children_create {
	my $self    = shift;
	my $object  = shift;
	my $parent  = shift;
	my @windows = ();

	foreach my $child ( @{$object->children} ) {
		# Skip elements we create outside the main recursion
		next if $child->isa('FBP::StatusBar');

		if ( $child->isa('FBP::Window') ) {
			push @windows, $self->window_create($child, $parent);
		} elsif ( $child->isa('FBP::StdDialogButtonSizer') ) {
			push @windows, $self->stddialogbuttonsizer_create($child, $parent);
		}

		# Descend to child windows
		next unless $child->does('FBP::Children');
		if ( $object->isa('FBP::Window') ) {
			push @windows, $self->children_create($child, $object);
		} else {
			push @windows, $self->children_create($child, $parent);
		}
	}

	return @windows;
}

sub window_create {
	my $self   = shift;
	my $window = shift;
	my $parent = shift;
	my $lines  = undef;

	if ( $window->isa('FBP::AnimationCtrl') ) {
		$lines = $self->animationctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::BitmapButton') ) {
		$lines = $self->bitmapbutton_create($window, $parent);
	} elsif ( $window->isa('FBP::Button') ) {
		$lines = $self->button_create($window, $parent);
	} elsif ( $window->isa('FBP::CalendarCtrl') ) {
		$lines = $self->calendarctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::CheckBox') ) {
		$lines = $self->checkbox_create($window, $parent);
	} elsif ( $window->isa('FBP::Choice') ) {
		$lines = $self->choice_create($window, $parent);
	} elsif ( $window->isa('FBP::Choicebook') ) {
		$lines = $self->choicebook_create($window, $parent);
	} elsif ( $window->isa('FBP::ComboBox') ) {
		$lines = $self->combobox_create($window, $parent);
	} elsif ( $window->isa('FBP::ColourPickerCtrl') ) {
		$lines = $self->colourpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::CustomControl' ) ) {
		$lines = $self->customcontrol_create($window, $parent);
	} elsif ( $window->isa('FBP::DatePickerCtrl') ) {
		die "Wx::DatePickerCtrl is not supported by Wx.pm";
		$lines = $self->datepickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::DirPickerCtrl') ) {
		$lines = $self->dirpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::FilePickerCtrl') ) {
		$lines = $self->filepickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::FontPickerCtrl') ) {
		$lines = $self->fontpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::Gauge') ) {
		$lines = $self->gauge_create($window, $parent);
	} elsif ( $window->isa('FBP::GenericDirCtrl') ) {
		$lines = $self->genericdirctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::Grid') ) {
		$lines = $self->grid_create($window, $parent);
	} elsif ( $window->isa('FBP::HtmlWindow') ) {
		$lines = $self->htmlwindow_create($window, $parent);
	} elsif ( $window->isa('FBP::HyperlinkCtrl') ) {
		$lines = $self->hyperlink_create($window, $parent);
	} elsif ( $window->isa('FBP::Listbook') ) {
		# We emulate the creation of simple listbooks via treebooks
		if ( $window->wxclass eq 'Wx::Treebook' ) {
			$lines = $self->treebook_create($window, $parent);
		} else {
			$lines = $self->listbook_create($window, $parent);
		}
	} elsif ( $window->isa('FBP::ListBox') ) {
		$lines = $self->listbox_create($window, $parent);
	} elsif ( $window->isa('FBP::ListCtrl') ) {
		$lines = $self->listctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::MenuBar') ) {
		$lines = $self->menubar_create($window, $parent);
	} elsif ( $window->isa('FBP::Notebook') ) {
		$lines = $self->notebook_create($window, $parent);
	} elsif ( $window->isa('FBP::Panel') ) {
		$lines = $self->panel_create($window, $parent);
	} elsif ( $window->isa('FBP::RadioBox') ) {
		$lines = $self->radiobox_create($window, $parent);
	} elsif ( $window->isa('FBP::RadioButton') ) {
		$lines = $self->radiobutton_create($window, $parent);
	} elsif ( $window->isa('FBP::RichTextCtrl') ) {
		$lines = $self->richtextctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::ScrollBar') ) {
		$lines = $self->scrollbar_create($window, $parent);
	} elsif ( $window->isa('FBP::ScrolledWindow') ) {
		$lines = $self->scrolledwindow_create($window, $parent);
	} elsif ( $window->isa('FBP::SearchCtrl') ) {
		$lines = $self->searchctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::Slider') ) {
		$lines = $self->slider_create($window, $parent);
	} elsif ( $window->isa('FBP::SpinButton') ) {
		$lines = $self->spinbutton_create($window, $parent);
	} elsif ( $window->isa('FBP::SpinCtrl') ) {
		$lines = $self->spinctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::SplitterWindow') ) {
		$lines = $self->splitterwindow_create($window, $parent);
	} elsif ( $window->isa('FBP::StaticBitmap') ) {
		$lines = $self->staticbitmap_create($window, $parent);
	} elsif ( $window->isa('FBP::StaticLine') ) {
		$lines = $self->staticline_create($window, $parent);
	} elsif ( $window->isa('FBP::StaticText') ) {
		$lines = $self->statictext_create($window, $parent);
	} elsif ( $window->isa('FBP::StatusBar') ) {
		$lines = $self->statusbar_create($window, $parent);
	} elsif ( $window->isa('FBP::TextCtrl') ) {
		$lines = $self->textctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::ToggleButton') ) {
		$lines = $self->togglebutton_create($window, $parent);
	} elsif ( $window->isa('FBP::ToolBar') ) {
		$lines = $self->toolbar_create($window, $parent);
	} elsif ( $window->isa('FBP::TreeCtrl') ) {
		$lines = $self->treectrl_create($window, $parent);
	} else {
		die 'Cannot create constructor code for ' . ref($window);
	}

	# Add common modifications
	push @$lines, $self->window_changes($window);
	push @$lines, $self->object_bindings($window);

	return $lines;
}

sub animationctrl_create {
	my $self      = shift;
	my $control   = shift;
	my $parent    = $self->object_parent(@_);
	my $id        = $self->object_id($control);
	my $animation = $self->animation($control->animation);
	my $position  = $self->object_position($control);
	my $size      = $self->object_wxsize($control);
	my $variable  = $self->object_variable($control);
	my $bitmap    = $self->bitmap($control->inactive_bitmap);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$animation,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	unless ( $bitmap eq $self->bitmap(undef) ) {
		push @$lines, $self->nested(
			"$variable->SetInactiveBitmap(",
			$bitmap,
			");",
		);
	}

	if ( $control->play ) {
		push @$lines, "$variable->Play;";
	}

	return $lines;
}

sub bitmapbutton_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $bitmap   = $self->object_bitmap($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $variable = $self->object_variable($control);
	my $disabled = $self->bitmap( $control->disabled );
	my $selected = $self->bitmap( $control->selected );
	my $hover    = $self->bitmap( $control->hover    );
	my $focus    = $self->bitmap( $control->focus    );

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$bitmap,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Set the optional images
	my $null = $self->bitmap(undef);
	if ( $disabled ne $null ) {
		push @$lines, (
			"$variable->SetBitmapDisabled(",
			"\t$disabled",
			");",
		);
	}
	if ( $selected ne $null ) {
		push @$lines, (
			"$variable->SetBitmapSelected(",
			"\t$selected",
			");",
		);
	}
	if ( $hover ne $null ) {
		push @$lines, (
			"$variable->SetBitmapHover(",
			"\t$hover",
			");",
		);
	}
	if ( $focus ne $null ) {
		push @$lines, (
			"$variable->SetBitmapFocus(",
			"\t$focus",
			");",
		);
	}

	if ( $control->default ) {
		push @$lines, "$variable->SetDefault;";
	}

	return $lines;
}

sub button_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $variable = $self->object_variable($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	if ( $control->default ) {
		push @$lines, "$variable->SetDefault;";
	}

	return $lines;
}

sub calendarctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	# my $value    = $self->wx('wxDefaultDateTime'); # NOT IMPLEMENTED
	my $value    = 'Wx::DateTime->new'; # Believed to be equivalent
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub checkbox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub choice_create {
	my $self      = shift;
	my $control   = shift;
	my $parent    = $self->object_parent(@_);
	my $id        = $self->object_id($control);
	my $position  = $self->object_position($control);
	my $size      = $self->object_wxsize($control);
	my $items     = $self->control_items($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$items,
		");",
	);
}

sub choicebook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub combobox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$items,
		$self->window_style($control),
		");",
	);
}

sub colourpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $colour   = $self->colour( $control->colour );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	# Wx::ColourPickerCtrl does not support defaulting null colours.
	# Use an explicit black instead until we find a better option.
	if ( $colour eq 'undef' ) {
		$colour = $self->colour('0,0,0');
	}

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$colour,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

# Completely generic custom control
sub customcontrol_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		");",
	);
}

sub datepickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	# my $value    = $self->wx('wxDefaultDateTime'); # NOT IMPLEMENTED
	my $value    = 'Wx::DateTime->new'; # Believed to be equivalent
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub dirpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $message  = $self->text( $control->message );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$message,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub filepickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $message  = $self->text( $control->message );
	my $wildcard = $self->quote( $control->wildcard );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$message,",
		"$wildcard,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub fontpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $variable = $self->object_variable($control);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $font     = $self->font( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$font,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	my $max_point_size = $control->max_point_size;
	if ( $max_point_size ) {
		push @$lines, "$variable->SetMaxPointSize($max_point_size);";
	}

	return $lines;
}

sub gauge_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $range    = $control->range;
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$range,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Set the value we are initially at
	my $variable = $self->object_variable($control);
	my $value    = $control->value;
	if ( $value ) {
		push @$lines, "$variable->SetValue($value);";
	}

	return $lines;
}

sub genericdirctrl_create {
	my $self          = shift;
	my $control       = shift;
	my $parent        = $self->object_parent(@_);
	my $id            = $self->object_id($control);
	my $defaultfolder = $self->quote( $control->defaultfolder );
	my $position      = $self->object_position($control);
	my $size          = $self->object_wxsize($control);
	my $filter        = $self->quote( $control->filter );
	my $defaultfilter = $control->defaultfilter;

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$defaultfolder,",
		"$position,",
		"$size,",
		$self->window_style($control, 0),
		"$filter,",
		"$defaultfilter,",
		");",
	);

	my $variable    = $self->object_variable($control);
	my $show_hidden = $control->show_hidden;
	push @$lines, "$variable->ShowHidden($show_hidden);";

	return $lines;
}

sub grid_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Grid
	my $variable         = $self->object_variable($control);
	my $rows             = $control->rows;
	my $cols             = $control->cols;
	my $editing          = $control->editing;
	my $grid_lines       = $control->grid_lines;
	my $drag_grid_size   = $control->drag_grid_size;
	my $margin_width     = $control->margin_width;
	my $margin_height    = $control->margin_height;

	push @$lines, (
		"$variable->CreateGrid( $rows, $cols );",
		"$variable->EnableEditing($editing);",
		"$variable->EnableGridLines($grid_lines);",
	);
	if ( $control->grid_line_color ) {
		push @$lines, $self->nested(
			"$variable->SetGridLineColour(",
			$self->colour( $control->grid_line_color ),
			");",
		);
	}
	push @$lines, (
		"$variable->EnableDragGridSize($drag_grid_size);",
		"$variable->SetMargins( $margin_width, $margin_height );",
	);

	# Columns
	my $drag_col_move             = $control->drag_col_move;
	my $drag_col_size             = $control->drag_col_size;
	my $col_label_size            = $control->col_label_size;
	my $col_label_horiz_alignment = $self->wx( $control->col_label_horiz_alignment );
	my $col_label_vert_alignment  = $self->wx( $control->col_label_vert_alignment );

	if ( $control->column_sizes ) {
		my @sizes = split /\s*,\s*/, $control->column_sizes;

		push @$lines, map {
			"$variable->SetColSize( $_, $sizes[$_] );"
		} ( 0 .. $#sizes );
	}
	if ( $control->autosize_cols ) {
		push @$lines, "$variable->AutoSizeColumns;";
	}
	push @$lines, (
		"$variable->EnableDragColMove($drag_col_move);",
		"$variable->EnableDragColSize($drag_col_size);",
		"$variable->SetColLabelSize($col_label_size);",
	);
	if ( $control->col_label_values ) {
		my @values = map {
			$self->text($_)
		} $self->list( $control->col_label_values );

		push @$lines, map {
			"$variable->SetColLabelValue( $_, $values[$_] );"
		} ( 0 .. $#values );
	}
	push @$lines, "$variable->SetColLabelAlignment( $col_label_horiz_alignment, $col_label_vert_alignment );";

	# Rows
	my $drag_row_size = $control->drag_row_size;
	my $row_label_horiz_alignment = $self->wx( $control->row_label_horiz_alignment );
	my $row_label_vert_alignment  = $self->wx( $control->row_label_vert_alignment );

	if ( $control->row_sizes ) {
		my @sizes = split /\s*,\s*/, $control->row_sizes;

		push @$lines, map {
			"$variable->SetRowSize( $_, $sizes[$_] );"
		} ( 0 .. $#sizes );
	}
	if ( $control->autosize_rows ) {
		push @$lines, "$variable->AutoSizeRows;";
	}
	push @$lines, "$variable->EnableDragRowSize($drag_row_size);";
	if ( $control->row_label_values ) {
		my @values = map {
			$self->text($_)
		} $self->list( $control->row_label_values );

		push @$lines, map {
			"$variable->SetRowLabelValue( $_, $values[$_] );"
		} ( 0 .. $#values );
	}
	push @$lines, "$variable->SetRowLabelAlignment( $row_label_horiz_alignment, $row_label_vert_alignment );";

	# Label Appearance
	if ( $control->label_bg ) {
		my $colour = $self->colour( $control->label_bg );
		push @$lines, (
			"$variable->SetLabelBackgroundColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->label_font ) {
		my $font = $self->font( $control->label_font );
		push @$lines, (
			"$variable->SetLabelFont(",
			"\t$font",
			");",
		);
	}
	if ( $control->label_text ) {
		my $colour = $self->colour( $control->label_text );
		push @$lines, (
			"$variable->SetLabelTextColour(",
			"\t$colour",
			");",
		);
	}

	# Cell Defaults
	my $cell_horiz_alignment = $self->wx( $control->cell_horiz_alignment );
	my $cell_vert_alignment  = $self->wx( $control->cell_vert_alignment );
	if ( $control->cell_bg ) {
		my $colour = $self->colour( $control->cell_bg );
		push @$lines, (
			"$variable->SetDefaultCellBackgroundColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->cell_font ) {
		my $font = $self->font( $control->cell_font );
		push @$lines, (
			"$variable->SetDefaultCellFont(",
			"\t$font",
			");",
		);
	}
	if ( $control->cell_text ) {
		my $colour = $self->colour( $control->cell_text );
		push @$lines, (
			"$variable->SetDefaultCellColour(",
			"\t$colour",
			");",
		);
	}
	push @$lines, "$variable->SetDefaultCellAlignment( $cell_horiz_alignment, $cell_vert_alignment );";

	return $lines;
}

sub htmlwindow_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub hyperlink_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $url      = $self->quote( $control->url );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$url,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Set additional properties
	my $variable = $self->object_variable($control);
	if ( $control->normal_color ) {
		my $colour = $self->colour( $control->normal_color );
		push @$lines, (
			"$variable->SetNormalColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->hover_color ) {
		my $colour = $self->colour( $control->hover_color );
		push @$lines, (
			"$variable->SetHoverColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->visited_color ) {
		my $colour = $self->colour( $control->visited_color );
		push @$lines, (
			"$variable->SetVisitedColour(",
			"\t$colour",
			");",
		);
	}

	return $lines;
}

sub listbook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub listbox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$items,
		$self->window_style($control),
		");",
	);
}

sub listctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub menu_create {
	my $self     = shift;
	my $menu     = shift;
	my $scope    = $self->object_scope($menu);
	my $variable = $self->object_variable($menu);

	# Generate our children
	my @lines = (
		"$scope$variable = Wx::Menu->new;",
		"",
	);
	foreach my $child ( @{$menu->children} ) {
		if ( $child->isa('FBP::Menu') ) {
			push @lines, @{ $self->menu_create($child, $menu) };

		} elsif ( $child->isa('FBP::MenuItem') ) {
			push @lines, @{ $self->menuitem_create($child, $menu) };

		} else {
			next;
		}
		push @lines, "";
	}

	# Fill the menu
	foreach my $child ( @{$menu->children} ) {
		if ( $child->isa('FBP::Menu') ) {
			push @lines, $self->nested(
				"$variable->Append(",
				$self->object_variable($_) . ',',
				$self->object_label($_) . ',',
				");",
			);
		} elsif ( $child->isa('FBP::MenuItem') ) {
			push @lines, "$variable->Append( "
				. $self->object_variable($child)
				. " );";
		} elsif ( $child->isa('FBP::MenuSeparator') ) {
			push @lines, "$variable->AppendSeparator;";
		}
	}

	return \@lines;
}

sub menubar_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($window);
	my $variable = $self->object_variable($window);
	my $style    = $self->wx($window->styles || 0);

	# Generate our children
	my @children = map {
		$self->menu_create($_, $self)
	} @{$window->children};

	# Build the append list
	my @append = map {
		$self->nested(
			"$variable->Append(",
			$self->object_variable($_) . ',',
			$self->object_label($_) . ',',
			");",
		)
	} @{$window->children};
 
	return [
		( map { @$_, "" } @children ),
		"$scope$variable = Wx::MenuBar->new($style);",
		"",
		@append,
		"",
		"$parent->SetMenuBar( $variable );",
	];
}

sub menuitem_create {
	my $self     = shift;
	my $menu     = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($menu);
	my $variable = $self->object_variable($menu);
	my $id       = $self->object_id($menu);
	my $label    = $self->object_label($menu);
	my $help     = $self->text( $menu->help );
	my $kind     = $self->wx( $menu->kind );

	# Create the menu item
	my $lines = $self->nested(
		"$scope$variable = Wx::MenuItem->new(",
		"$parent,",
		"$id,",
		"$label,",
		"$help,",
		"$kind,",
		");",
	);

	# Add the event bindings
	push @$lines, $self->object_bindings($menu);

	return $lines;
}

sub notebook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub panel_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($window);
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	return $self->nested(
		$self->object_new($window),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);
}

sub radiobox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);
	my $major    = $control->majorDimension || 1;

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$items,
		"$major,",
		$self->window_style($control),
		");",
	);
}

sub radiobutton_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	if ( $control->value ) {
		my $variable = $self->object_variable($control);
		push @$lines, "$variable->SetValue(1);";
	}

	return $lines;
}

sub richtextctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	# my $value    = $self->wx('wxEmptyString'); # NOT IMPLEMENTED
	my $value    = $self->quote('');
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub scrollbar_create {
	my $self     = shift;
	my $control   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub scrolledwindow_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($window);
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);
	my $variable = $self->object_variable($window);
	my $scroll_x = $window->scroll_rate_x;
	my $scroll_y = $window->scroll_rate_y;

	my $lines = $self->nested(
		$self->object_new($window),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->wx('wxHSCROLL|wxVSCROLL,'),
		");",
	);

	# Set the scroll rate for the window
	push @$lines, "$variable->SetScrollRate( $scroll_x, $scroll_y );";

	return $lines;
}

sub searchctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Control which optional features we show
	my $platform      = $self->wx('wxMAC');
	my $variable      = $self->object_variable($control);
	my $search_button = $control->search_button;
	my $cancel_button = $control->cancel_button;
	push @$lines, (
		"unless ( $platform ) {",
		"\t$variable->ShowSearchButton($search_button);",
		"}",
		"$variable->ShowCancelButton($cancel_button);",
	);

	return $lines;
}

sub slider_create {
	my $self    = shift;
	my $window  = shift;
	my $variable = $self->object_variable($window);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($window);
	my $value    = $window->value;
	my $minimum  = $window->minValue;
	my $maximum  = $window->maxValue;
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	return $self->nested(
		$self->object_new($window),
		"$parent,",
		"$id,",
		"$value,",
		"$minimum,",
		"$maximum,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);
}

sub spinbutton_create {
	my $self     = shift;
	my $control   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub spinctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $variable = $self->object_variable($control);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $style    = $self->wx( $control->styles );
	my $min      = $control->min;
	my $max      = $control->max;
	my $initial  = $control->initial;

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		"$style,",
		"$min,",
		"$max,",
		"$initial,",
		");",
	);
}

sub splitterwindow_create {
	my $self     = shift;
	my $window   = shift;
	my $variable = $self->object_variable($window);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($window);
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	# Object constructor
	my $lines = $self->nested(
		$self->object_new($window),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);

	# Optional settings
	my $sashsize      = $window->sashsize;
	my $sashgravity   = $window->sashgravity;
	my $min_pane_size = $window->min_pane_size;
	if ( length $sashgravity and $sashgravity >= 0 ) {
		push @$lines, "$variable->SetSashGravity($sashgravity);";
	}
	if ( length $sashsize and $sashsize >= 0 ) {
		push @$lines, "$variable->SetSashSize($sashsize);";
	}
	if ( $min_pane_size and $min_pane_size > 0 ) {
		push @$lines, "$variable->SetMinimumPaneSize($min_pane_size);";
	}

	return $lines;
}

sub staticbitmap_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($window);
	my $bitmap   = $self->object_bitmap($window);
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	return $self->nested(
		$self->object_new($window),
		"$parent,",
		"$id,",
		"$bitmap,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);
}

sub staticline_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub statictext_create {
	my $self    = shift;
	my $control = shift;
	my $parent  = $self->object_parent(@_);
	my $id      = $self->object_id($control);
	my $label   = $self->object_label($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		");",
	);
}

sub statusbar_create {
	my $self     = shift;
	my $object   = shift;
	my $variable = $self->object_variable($object);
	my $parent   = $self->object_parent(@_);
	my $fields   = $object->fields;
	my $style    = $self->window_style($object, 0);
	my $id       = $self->object_id($object);

	# If the status bar is not stored for later reference,
	# don't create the variable at all to avoid perlcritic'ism
	if ( $self->object_lexical($object) ) {
		$variable = "";
	} else {
		$variable = "$variable = ";
	}

	return [
		"$variable$parent->CreateStatusBar( $fields, $style $id );",
	];
}

use constant STDDIALOGBUTTONS => qw{
	OK Yes Save Apply No Cancel Help ContextHelp
};

sub stddialogbuttonsizer_create {
	my $self    = shift;
	my $sizer   = shift;
	my $parent  = $self->object_parent(@_);
	my @windows = ();

	# We don't create the sizer here, but we do create the buttons
	foreach my $button ( $self->stddialogbuttonsizer_buttons($sizer) ) {
		my $id = $self->object_id($button);

		my $lines = $self->nested(
			$self->object_new($button),
			"$parent,",
			"$id,",
			");",
		);

		push @$lines, $self->object_bindings($button);
		push @windows, $lines;
	}

	return @windows;
}

sub stddialogbuttonsizer_buttons {
	my $self  = shift;
	my $sizer = shift;
	return map {
		$self->stddialogbuttonsizer_button($sizer, $_)
	} grep {
		$sizer->$_()
	} STDDIALOGBUTTONS;
}

sub stddialogbuttonsizer_button {
	my $self  = shift;
	my $sizer = shift;
	my $type  = shift;
	my $name  = $sizer->name . '_' . lc($type);
	my $id    = 'wxID_' . uc($type);
	my $click = 'On' . $type . 'ButtonClick';
	my $event = $sizer->$click();
	return FBP::Button->new(
		name          => $name,
		id            => $id,
		permission    => $sizer->permission,
		( $event ? ( OnButtonClick => $event ) : () ),
	);
}

sub textctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	my $maxlength = $control->maxlength;
	if ( $maxlength ) {
		my $variable = $self->object_variable($control);
		push @$lines, "$variable->SetMaxLength($maxlength);";
	}

	return $lines;
}

sub togglebutton_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	if ( $control->value ) {
		my $variable = $self->object_variable($control);
		push @$lines, "$variable->SetValue(1);";
	}

	return $lines;
}

sub tool_create {
	my $self    = shift;
	my $tool    = shift;
	my $parent  = $self->object_parent(@_);
	my $id      = $self->object_id($tool);
	my $label   = $self->object_label($tool);
	my $bitmap  = $self->object_bitmap($tool);
	my $tooltip = $self->text( $tool->tooltip );
	my $kind    = $self->wx( $tool->kind );

	return $self->nested(
		"$parent->AddTool(",
		"$id,",
		"$label,",
		"$bitmap,",
		"$tooltip,",
		"$kind,",
		");",
	);
}

sub toolbar_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($window);
	my $variable = $self->object_variable($window);
	my $style    = $self->wx($window->styles || 0);
	my $id       = $self->object_id($window);

	# Generate child constructor code
	my @children = map {
		$_->isa('FBP::Tool')
		? $self->tool_create($_, $window)
		: "$variable->AddSeparator;"
	} @{$window->children};

	return [
		"$scope$variable = $parent->CreateToolBar( $style, $id );",
		( map { ref $_ ? @$_ : $_ } @children ),
		"$variable->Realize;",
	];
}

sub treebook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $style    = $self->wx(
		# Strip listbook-specific styles
		join ' | ', grep { ! /^wxLB_/ } split /\s*\|\s*/, $control->styles
	);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub treectrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->object_id($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->object_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}





######################################################################
# Sizer Generators

sub children_pack {
	my $self     = shift;
	my $object   = shift;
	my @children = ();

	foreach my $item ( @{$object->children} ) {
		my $child = $item->children->[0];
		if ( $child->isa('FBP::Sizer') ) {
			push @children, $self->sizer_pack($child);
		} elsif ( $child->isa('FBP::Choicebook') ) {
			push @children, $self->choicebook_pack($child);
		} elsif ( $child->isa('FBP::Listbook') ) {
			push @children, $self->listbook_pack($child);
		} elsif ( $child->isa('FBP::Notebook') ) {
			push @children, $self->notebook_pack($child);
		} elsif ( $child->isa('FBP::Panel') ) {
			push @children, $self->panel_pack($child);
		} elsif ( $child->isa('FBP::SplitterWindow') ) {
			push @children, $self->splitterwindow_pack($child);
		} elsif ( $child->isa('FBP::ScrolledWindow') ) {
			push @children, $self->scrolledwindow_pack($child);
		} elsif ( $child->does('FBP::Children') ) {
			if ( @{$child->children} ) {
				die "Unsupported parent " . ref($child);
			}
		}
	}

	return @children;
}

sub sizer_pack {
	my $self  = shift;
	my $sizer = shift;

	if ( $sizer->isa('FBP::GridBagSizer') ) {
		return $self->gridbagsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::FlexGridSizer') ) { 
		return $self->flexgridsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::GridSizer') ) {
		return $self->gridsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::StaticBoxSizer') ) {
		return $self->staticboxsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::BoxSizer') ) {
		return $self->boxsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::StdDialogButtonSizer') ) {
		return $self->stddialogbuttonsizer_pack($sizer);
	} else {
		die "Unsupported sizer " . ref($sizer);
	}
}

# Packing for Listbook, Notebook and Treebook
sub book_pack {
	my $self     = shift;
	my $book     = shift;
	my $variable = $self->object_variable($book);

	# Generate fragments for our child panels
	my @children = $self->children_pack($book);

	# Add each of our child pages
	my @lines = ();
	foreach my $item ( @{$book->children} ) {
		my $child = $item->children->[0];
		if ( $child->isa('FBP::Panel') ) {
			my $params = join(
				', ',
				$self->object_variable($child),
				$self->object_label($item),
				$item->select ? 1 : 0,
			);
			push @lines, "$variable->AddPage( $params );";

		} else {
			die "Unknown or unsupported book child " . ref($child);
		}
	}

	return ( @children, \@lines );
}

sub boxsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $scope    = $self->object_scope($sizer);
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::BoxSizer->new($orient);",
		$self->object_minimum_size($sizer),
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub flexgridsizer_pack {
	my $self      = shift;
	my $sizer     = shift;
	my $scope     = $self->object_scope($sizer);
	my $variable  = $self->object_variable($sizer);
	my $direction = $self->wx( $sizer->flexible_direction );
	my $growmode  = $self->wx( $sizer->non_flexible_grow_mode );
	my $params    = join( ', ',
		$sizer->rows,
		$sizer->cols,
		$sizer->vgap,
		$sizer->hgap,
	);

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::FlexGridSizer->new( $params );",
		$self->object_minimum_size($sizer),
	);
	foreach my $row ( split /\s*,\s*/, $sizer->growablerows ) {
		push @lines, "$variable->AddGrowableRow($row);";
	}
	foreach my $col ( split /\s*,\s*/, $sizer->growablecols ) {
		push @lines, "$variable->AddGrowableCol($col);";
	}
	push @lines, "$variable->SetFlexibleDirection($direction);";
	push @lines, "$variable->SetNonFlexibleGrowMode($growmode);";
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub gridbagsizer_pack {
	my $self      = shift;
	my $sizer     = shift;
	my $scope     = $self->object_scope($sizer);
	my $variable  = $self->object_variable($sizer);
	my $direction = $self->wx( $sizer->flexible_direction );
	my $growmode  = $self->wx( $sizer->non_flexible_grow_mode );
	my $params    = join ', ', $sizer->vgap, $sizer->hgap;

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::GridBagSizer->new( $params );",
		$self->object_minimum_size($sizer),
	);
	foreach my $row ( split /,/, $sizer->growablerows ) {
		push @lines, "$variable->AddGrowableRow($row);";
	}
	foreach my $col ( split /,/, $sizer->growablecols ) {
		push @lines, "$variable->AddGrowableCol($col);";
	}
	push @lines, "$variable->SetFlexibleDirection($direction);";
	push @lines, "$variable->SetNonFlexibleGrowMode($growmode);";
	foreach my $item ( @{$sizer->children} ) {
		my $child   = $item->children->[0];
		my $row     = $item->row;
		my $column  = $item->column;
		my $rowspan = $item->rowspan;
		my $colspan = $item->colspan;
		my $flag    = $self->wx( $item->flag );
		my $border  = $item->border;
		if ( $child->isa('FBP::Spacer') ) {
			my $width  = $child->width;
			my $height = $child->height;
			push @lines, $self->nested(
				"$variable->Add(",
				"$width,",
				"$height,",
				"Wx::GBPosition->new( $row, $column ),",
				"Wx::GBSpan->new( $rowspan, $colspan ),",
				"$flag,",
				"$border,",
				");",
			);
		} else {
			push @lines, $self->nested(
				"$variable->Add(",
				$self->object_variable($child) . ',',
				"Wx::GBPosition->new( $row, $column ),",
				"Wx::GBSpan->new( $rowspan, $colspan ),",
				"$flag,",
				"$border,",
				");",
			);
		}
	}

	return ( @children, \@lines );
}

sub gridsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $scope    = $self->object_scope($sizer);
	my $variable = $self->object_variable($sizer);
	my $params   = join( ', ',
		$sizer->rows,
		$sizer->cols,
		$sizer->vgap,
		$sizer->hgap,
	);

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::GridSizer->new( $params );",
		$self->object_minimum_size($sizer),
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub stddialogbuttonsizer_pack {
	my $self      = shift;
	my $sizer     = shift;
	my $scope     = $self->object_scope($sizer);
	my $variable  = $self->object_variable($sizer);

	# Create the sizer (it can't have child sizers)
	my @lines = ();
	foreach my $button ( $self->stddialogbuttonsizer_buttons($sizer) ) {
		my $button_variable = $self->object_variable($button);
		push @lines, "$variable->AddButton( $button_variable );";
	}

	return [
		"$scope$variable = Wx::StdDialogButtonSizer->new;",
		$self->object_minimum_size($sizer),
		@lines,
		"$variable->Realize;",
	];
}

sub choicebook_pack {
	shift->book_pack(@_);
}

sub listbook_pack {
	shift->book_pack(@_);
}

sub notebook_pack {
	shift->book_pack(@_);
}

sub panel_pack {
	my $self     = shift;
	my $panel    = shift;
	my $sizer    = $panel->children->[0] or return ();
	my $variable = $self->object_variable($panel);
	my $sizervar = $self->object_variable($sizer);
	my $setsize  = $self->window_setsize($panel);

	# Generate fragments for our (optional) child sizer
	my @children = $self->sizer_pack($sizer);

	# Attach the sizer to the panel
	return (
		@children,
		[
			"$variable->$setsize($sizervar);",
			"$variable->Layout;",
		]
	);
}

sub scrolledwindow_pack {
	my $self     = shift;
	my $window   = shift;
	my $sizer    = $window->children->[0] or return ();
	my $variable = $self->object_variable($window);
	my $sizervar = $self->object_variable($sizer);
	my $setsize  = $self->window_setsize($window);

	# Generate fragments for our (optional) child sizer
	my @children = $self->sizer_pack($sizer);

	# Attach the sizer to the panel
	return (
		@children,
		[
			"$variable->$setsize($sizervar);",
			"$variable->Layout;",
		],
	);
}

sub splitterwindow_pack {
	my $self     = shift;
	my $window   = shift;
	my $variable = $self->object_variable($window);
	my @windows  = map { $_->children->[0] } @{$window->children};

	# Add the content for all our child sizers
	my @children = $self->children_pack($window);

	if ( @windows == 1 ) {
		# One child window
		my $window1 = $self->object_variable($windows[0]);
		return (
			@children,
			[
				"$variable->Initialize(",
				"\t$window1,",
				");",
			],
		);
	}

	if ( @windows == 2 ) {
		# Two child windows
		my $sashpos = $window->sashpos;
		my $window1 = $self->object_variable($windows[0]);
		my $window2 = $self->object_variable($windows[1]);
		my $method  = $window->splitmode eq 'wxSPLIT_HORIZONTAL'
		            ? 'SplitHorizontally'
		            : 'SplitVertically';
		return (
			@children,
			[
				"$variable->$method(",
				"\t$window1,",
				"\t$window2,",
				( $sashpos ? "\t$sashpos," : () ),
				");",
			],
		);
	}

	die "Unexpected number of splitterwindow children";
}

sub staticboxsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $scope    = $self->object_scope($sizer);
	my $variable = $self->object_variable($sizer);
	my $label    = $self->object_label($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::StaticBoxSizer->new(",
		"\tWx::StaticBox->new(",
		"\t\t\$self,",
		"\t\t-1,",
		"\t\t$label,",
		"\t),",
		"\t$orient,",
		");",
		$self->object_minimum_size($sizer),
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}





######################################################################
# Window Statement Fragments

sub window_changes {
	my $self   = shift;
	my $window = shift;
	my @lines  = ();

	push @lines, $self->window_selection($window);
	push @lines, $self->object_minimum_size($window);
	push @lines, $self->object_maximum_size($window);
	push @lines, $self->window_fg($window);
	push @lines, $self->window_bg($window);
	push @lines, $self->window_font($window);
	push @lines, $self->window_tooltip($window);
	push @lines, $self->window_disable($window);
	push @lines, $self->window_hide($window);

	return @lines;
}

sub window_selection {
	my $self   = shift;
	my $window = shift;

	if ( $window->can('selection') ) {
		my $variable  = $self->object_variable($window);
		my $selection = $window->selection || 0;
		return (
			"$variable->SetSelection($selection);",
		);
	}

	return;
}

sub window_fg {
	my $self   = shift;
	my $window = shift;

	if ( $window->fg ) {
		my $variable = $self->object_variable($window);
		my $colour   = $self->colour( $window->fg );
		return (
			"$variable->SetForegroundColour(",
			"\t$colour",
			");",
		);
	};

	return;
}

sub window_bg {
	my $self   = shift;
	my $window = shift;

	if ( $window->bg ) {
		my $variable = $self->object_variable($window);
		my $colour   = $self->colour( $window->bg );
		return (
			"$variable->SetBackgroundColour(",
			"\t$colour",
			");",
		);
	};

	return;
}

sub window_font {
	my $self   = shift;
	my $window = shift;

	if ( $window->font ) {
		my $variable = $self->object_variable($window);
		my $font     = $self->font( $window->font );
		return (
			"$variable->SetFont(",
			"\t$font",
			");",
		);
	}

	return;
}

sub window_tooltip {
	my $self   = shift;
	my $window = shift;

	if ( $window->tooltip ) {
		my $variable = $self->object_variable($window);
		my $tooltip  = $self->text( $window->tooltip );
		return (
			"$variable->SetToolTip(",
			"\t$tooltip",
			");",
		);
	}

	return;
}

sub window_disable {
	my $self   = shift;
	my $window = shift;

	unless ( $window->enabled ) {
		my $variable = $self->object_variable($window);
		return (
			"$variable->Disable;",
		);
	}

	return;
}

sub window_hide {
	my $self   = shift;
	my $window = shift;

	if ( $window->hidden ) {
		my $variable = $self->object_variable($window);
		return (
			"$variable->Hide;",
		);
	}

	return;
}

sub object_bindings {
	my $self   = shift;
	my $object = shift;
	return map {
		$CONNECT{$_}
		? $self->object_connect( $object, $_ )
		: $self->object_macro( $object, $_ )
	} grep {
		$object->can($_) and $object->$_()
	} sort keys %MACRO;
}

sub object_macro {
	my $self      = shift;
	my $object    = shift;
	my $attribute = shift;
	my $variable  = $self->object_variable($object);
	my $method    = $object->$attribute() or return;

	# Add the binding for it
	my $args  = $MACRO{$attribute}->[0];
	my $macro = $MACRO{$attribute}->[1];
	if ( $args == 2 ) {
		return (
			"",
			"Wx::Event::$macro(",
			"\t\$self,",
			"\t$variable,",
			"\tsub {",
			"\t\tshift->$method(\@_);",
			"\t},",
			");",
		);
	}
	if ( $variable eq '$self' ) {
		return (
			"",
			"Wx::Event::$macro(",
			"\t\$self,",
			"\tsub {",
			"\t\tshift->$method(\@_);",
			"\t},",
			");",
		);
	}

	# Using $self here is a cop out but ok for now
	return (
		"",
		"Wx::Event::$macro(",
		"\t$variable,",
		"\tsub {",
		"\t\t\$self->$method(\$_[1]);",
		"\t},",
		");",
	);
}

sub object_minimum_size {
	my $self    = shift;
	my $object  = shift;
	my $minimum = $object->minimum_size;

	if ( $minimum and $self->size($minimum) ) {
		my $variable = $self->object_variable($object);
		my $size     = $self->wxsize($minimum);
		return (
			"$variable->SetMinSize( $size );",
		);
	}

	return;
}

sub object_maximum_size {
	my $self    = shift;
	my $object  = shift;
	my $maximum = $object->maximum_size;

	if ( $maximum and $self->size($maximum) ) {
		my $variable = $self->object_variable($object);
		my $size     = $self->wxsize($maximum);
		return (
			"$variable->SetMaxSize( $size );",
		);
	}

	return;
}

sub object_connect {
	my $self      = shift;
	my $object    = shift;
	my $attribute = shift;
	my $variable  = $self->object_variable($object);
	my $method    = $object->$attribute() or return;
	my $constant  = $CONNECT{$attribute}  or return;

	return (
		"",
		"\$self->Connect(",
		"\t$variable,",
		"\t-1,",
		"\tWx::$constant,",
		"\tsub {",
		"\t\tshift->$method(\@_);",
		"\t},",
		");",
	);
}





######################################################################
# Window Fragment Generators

sub object_lexical {
	$_[1]->permission !~ /^(?:protected|public)\z/;
}

sub object_label {
	$_[0]->text( $_[1]->label );
}

sub object_scope {
	my $self   = shift;
	my $object = shift;
	if ( $self->object_lexical($object) ) {
		return 'my ';
	} else {
		return '';
	}
}

sub object_variable {
	my $self   = shift;
	my $object = shift;
	if ( $object->does('FBP::Form') ) {
		return '$self';
	} elsif ( $self->object_lexical($object) ) {
		return '$' . $object->name;
	} else {
		return '$self->{' . $object->name . '}';
	}
}

sub object_parent {
	my $self   = shift;
	my $object = shift;
	if ( $object and not $object->does('FBP::Form') ) {
		return $self->object_variable($object);
	} else {
		return '$self';
	}
}

sub object_position {
	my $self     = shift;
	my $object   = shift;
	my $position = $object->pos;
	unless ( $position ) {
		return $self->wx('wxDefaultPosition');
	}
	$position =~ s/,/, /;
	return "[ $position ]";
}

sub object_wxsize {
	my $self   = shift;
	my $object = shift;
	return $self->wxsize($object->size);
}

# Is an object a top level project asset.
# i.e. A Dialog, Frame or top level Panel
sub object_top {
	my $self   = shift;
	my $object = shift;
	return 1 if $object->isa('FBP::Dialog');
	return 1 if $object->isa('FBP::Frame');
	return 0;
}

sub object_new {
	my $self     = shift;
	my $object   = shift;
	my $scope    = $self->object_scope($object);
	my $variable = $self->object_variable($object);
	my $wxclass  = $object->wxclass;
	return "$scope$variable = $wxclass->new(";
}

sub window_new {
	my $self    = shift;
	my $window  = shift;
	my $parent  = $self->object_parent(@_);
	my $id      = $self->object_id($window);
	return (
		$self->object_new($window),
		"$parent,",
		"$id,",
	);
}

sub window_style {
	my $self    = shift;
	my $window  = shift;
	my $default = shift;
	my $styles  = $window->styles || $default;

	if ( defined $styles and length $styles ) {
		return $self->wx($styles) . ',';
	}

	return;
}

sub window_setsize {
	my $self     = shift;
	my $window   = shift;
	return 'SetSizer' if $self->size( $window->size );
	return 'SetSizerAndFit';
}

sub object_id {
	my $self   = shift;
	my $object = shift;
	return $self->wx( $object->id );
}

sub object_accessor {
	my $self   = shift;
	my $object = shift;
	my $name   = $object->name;

	return $self->nested(
		"sub $name {",
		"\$_[0]->{$name};",
		"}",
	);
}

sub object_bitmap {
	my $self   = shift;
	my $object = shift;
	return $self->bitmap( $object->bitmap );
}

sub object_event {
	my $self   = shift;
	my $window = shift;
	my $event  = shift;
	my $name   = $window->name;
	my $method = $window->$event();

	return $self->nested(
		"sub $method {",
		"warn 'Handler method $method for event $name.$event not implemented';",
		"}",
	);
}

sub control_items {
	my $self    = shift;
	my $control = shift;
	my @items   = $control->items;
	unless ( @items ) {
		return '[],';
	}

	return $self->nested(
		'[',
		( map { $self->quote($_) . ',' } @items ),
		'],',
	);
}





######################################################################
# Support Methods

sub list {
	my $self = shift;
	my @list = $_[0] =~ /" ( (?: \\. | . )+? ) "/xg;
	foreach ( @list ) {
		s/\\(.)/$1/g;
	}
	return @list;
}

sub ourisa {
	my $self  = shift;

	# Complex inheritance
	if ( @_ > 1 ) {
		return [
			"our \@ISA     = qw{",
			( map { "\t$_" } @_ ),
			"};",
		];
	}

	# Simple inheritance
	if ( @_ ) {
		return [
			"our \@ISA     = '$_[0]';",
		];
	}

	# No inheritance
	return [ ];
}

sub wx {
	my $self   = shift;
	my $string = shift;
	return 0  if $string eq '';
	return -1 if $string eq 'wxID_ANY';

	# Apply constant prefix policy
	if ( $self->prefix ) {
		# The capture here keeps Wx::WXK_KEYNAME sane
		$string =~ s/\b(wx[A-Z])/Wx::$1/g;
	} else {
		# For a limited group of constants we must be explicit
		$string =~ s/\bwxMAC\b/Wx::wxMAC/;
	}

	# Tidy a collection of multiple constants
	$string =~ s/\s*\|\s*/ | /g;

	return $string;
}

sub text {
	my $self   = shift;
	my $string = shift;
	unless ( defined $string and length $string ) {
		return "''";
	}

	# Handle the simple boring case
	unless ( $self->i18n ) {
		return $self->quote($string);
	}

	# Trim off leading and trailing punctuation
	my $leading  = '';
	my $trailing = '';
	if ( $self->i18n_trim ) {
		if ( $string =~ /^[ :]+\z/ ) {
			return $self->quote($string);
		}
		if ( $string =~ s/^([ :]+)//s ) {
			$leading = $self->quote("$1");
		}
		if ( $string =~ s/(\s*\.\.\.)\z//s ) {
			$trailing = $self->quote("$1");
		} elsif ( $string =~ s/([ :]+)\z//s ) {
			$trailing = $self->quote("$1");
		}
	}

	# Translate the remaining part of the string
	$string = $self->quote($string);
	$string = "Wx::gettext($string)";

	# Put leading and trailing punctuation back on
	if ( length $leading ) {
		$string = "$leading . $string";
	}
	if ( length $trailing ) {
		$string = "$string . $trailing";
	}

	return $string;
}

# This gets tricky if you ever hit weird characters
# or Unicode, so hand off to an expert.
# The only reason this is a standalone method is so that
# specialised subclasses can change it if desired.
sub quote {
	my $self   = shift;
	my $string = shift;
	my $code   = B::perlstring($string);
	return $code unless $self->project_utf8;

	# Attempt to convert the escaped string into unicode
	my $unicode = $code;
	my $found   = $unicode =~ s/
		( \\\\ | (?: \\x\{[0-9a-f]{3,}\} )+ )
	/
		length($1) > 2 ? eval("\"$1\"") : $1
	/gex;

	return $code unless utf8::is_utf8($unicode);
	return $unicode;
}

sub wxsize {
	my $self   = shift;
	my $string = $self->size(shift);
	return $self->wx('wxDefaultSize') unless $string;
	$string =~ s/,/, /;
	return "[ $string ]";
}

sub size {
	my $self   = shift;
	my $string = shift;
	return '' unless defined $string;
	return '' if $string eq '-1,-1';
	return $string;
}

sub colour {
	my $self   = shift;
	my $string = shift;

	# Default colour
	unless ( length $string ) {
		return 'undef';
	}

	# Explicit colour
	if ( $string =~ /^\d/ ) {
		$string =~ s/,(\d)/, $1/g; # Space the numbers a bit
		return "Wx::Colour->new( $string )";
	}

	# System colour
	if ( $string =~ /^wx/ ) {
		my $string = $self->wx($string);
		return "Wx::SystemSettings::GetColour( $string )";
	}

	die "Invalid or unsupported colour '$string'";
}

sub font {
	my $self   = shift;
	my $string = shift;

	# Default font
	unless ( length $string ) {
		return $self->wx('wxNullFont');
	}

	# Generate a font from the overcompact FBP format.
	# It will probably look something like ",90,92,-1,70,0"
	my @font = split /,/, $string;
	if ( @font == 6 ) {
		my $point_size = $font[3];
		my $family     = $font[4];
		my $style      = $font[1];
		my $weight     = $font[2];
		my $underlined = $font[5];
		my $face_name  = $font[0];
		my $params     = join( ', ',
			$self->points($point_size),
			$family,
			$style,
			$weight,
			$underlined,
			$self->quote($face_name),
		);
		return "Wx::Font->new( $params )";
	}

	die "Invalid or unsupported font '$string'";
}

sub points {
	my $self = shift;
	my $size = shift;
	if ( $size and $size > 0 ) {
		return $size;
	}
	$self->wx('wxNORMAL_FONT') . '->GetPointSize';
}

sub bitmap {
	my $self = shift;
	my $file = $self->file(shift);
	unless ( defined $file ) {
		return $self->wx('wxNullBitmap');
	}

	# Use the file path exactly as is for now
	my $type = $self->wx('wxBITMAP_TYPE_ANY');
	return "Wx::Bitmap->new( $file, $type )";
}

sub animation {
	my $self   = shift;
	my $string = shift;
	unless ( Params::Util::_STRING($string) ) {
		return $self->wx('wxNullAnimation');
	}

	### To be completed
	return $self->wx('wxNullAnimation');
}

sub file {
	my $self   = shift;
	my $string = shift;
	return undef unless Params::Util::_STRING($string);
	return undef unless $string =~ s/; Load From File$//;
	return $self->quote($string);
}

sub indent {
	map { /\S/ ? "\t$_" : $_ } (
		ref($_[1]) ? @{$_[1]} : @_[1..$#_]
	);
}

# Indent except for the first and last lines.
# Return as an array reference.
sub nested {
	my $self   = shift;
	my @lines  = map { ref $_ ? @$_ : $_ } @_;
	my $top    = shift @lines;
	my $bottom = pop @lines;
	return [
		$top,
		( map { /\S/ ? "\t$_" : $_ } @lines ),
		$bottom,
	];
}

sub flatten {
	join '', map { "$_\n" } @{$_[1]};
}

# Are there any FBP objects of a particular type in a FBP tree
# that do NOT use a custom subclass.
sub find_plain {
	my $self  = shift;
	my $topic = shift;
	my $plain = shift;

	# Search for all objects of that type
	return !! scalar grep {
		not $_->subclass
	} $topic->find( isa => $plain );
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP-Perl>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
