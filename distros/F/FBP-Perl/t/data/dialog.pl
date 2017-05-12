package MyDialog1;

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';
use Wx::Grid ();
use Wx::Calendar ();
use Wx::DateTime ();
use Wx::RichText ();
use t::lib::Custom ();
use t::lib::MyClass ();
use t::lib::MyHtmlWindow ();

our $VERSION = '0.78';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("Dialog Title"),
		wxDefaultPosition,
		wxDefaultSize,
		wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER,
	);

	Wx::Event::EVT_INIT_DIALOG(
		$self,
		sub {
			shift->on_init_dialog(@_);
		},
	);

	$self->{m_staticText1} = t::lib::MyClass->new(
		$self,
		-1,
		Wx::gettext("Michael \"Killer\" O'Reilly <michael\@localhost>"),
	);
	$self->{m_staticText1}->SetFont(
		Wx::Font->new( wxNORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" )
	);
	$self->{m_staticText1}->SetToolTip(
		Wx::gettext("Who is awesome")
	);

	$self->{m_bitmap1} = Wx::StaticBitmap->new(
		$self,
		-1,
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY ),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_textCtrl1} = Wx::TextCtrl->new(
		$self,
		-1,
		"This is also a test",
		wxDefaultPosition,
		wxDefaultSize,
		wxTE_CENTRE,
	);
	$self->{m_textCtrl1}->SetMaxLength(50);
	$self->{m_textCtrl1}->SetBackgroundColour(
		Wx::Colour->new( 255, 128, 0 )
	);

	Wx::Event::EVT_CHAR(
		$self->{m_textCtrl1},
		sub {
			$self->on_char($_[1]);
		},
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{m_textCtrl1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_button1} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("MyButton..."),
		wxDefaultPosition,
		wxDefaultSize,
	);
	$self->{m_button1}->SetDefault;
	$self->{m_button1}->SetToolTip(
		Wx::gettext("Click to do nothing")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{m_button1},
		sub {
			shift->m_button1(@_);
		},
	);

	$self->{m_toggleBtn1} = Wx::ToggleButton->new(
		$self,
		-1,
		Wx::gettext("Toggle me!"),
		wxDefaultPosition,
		[ 100, -1 ],
		wxFULL_REPAINT_ON_RESIZE,
	);
	$self->{m_toggleBtn1}->SetValue(1);
	$self->{m_toggleBtn1}->SetToolTip(
		Wx::gettext("Toggle something")
	);

	Wx::Event::EVT_TOGGLEBUTTON(
		$self,
		$self->{m_toggleBtn1},
		sub {
			shift->toggle_me(@_);
		},
	);

	$self->{m_bpButton1} = Wx::BitmapButton->new(
		$self,
		-1,
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY ),
		wxDefaultPosition,
		wxDefaultSize,
		wxBU_AUTODRAW,
	);
	$self->{m_bpButton1}->SetBitmapDisabled(
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY )
	);
	$self->{m_bpButton1}->SetBitmapSelected(
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY )
	);
	$self->{m_bpButton1}->SetBitmapHover(
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY )
	);
	$self->{m_bpButton1}->SetBitmapFocus(
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY )
	);

	$self->{m_spinBtn1} = Wx::SpinButton->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxSP_HORIZONTAL,
	);

	$self->{m_staticline1} = Wx::StaticLine->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxLI_HORIZONTAL | wxNO_BORDER,
	);

	$self->{m_splitter1} = Wx::SplitterWindow->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxSP_3D,
	);
	$self->{m_splitter1}->SetSashGravity(0.5);
	$self->{m_splitter1}->SetMinimumPaneSize(50);

	$self->{m_panel3} = Wx::Panel->new(
		$self->{m_splitter1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_choice1} = Wx::Choice->new(
		$self->{m_panel3},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		[],
	);
	$self->{m_choice1}->SetSelection(0);
	$self->{m_choice1}->Disable;

	Wx::Event::EVT_CHOICE(
		$self,
		$self->{m_choice1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_comboBox1} = Wx::ComboBox->new(
		$self->{m_panel3},
		-1,
		"Combo!",
		wxDefaultPosition,
		wxDefaultSize,
		[
			"one",
			"two",
			"a'b",
			"c\"d\\\"",
		],
	);

	Wx::Event::EVT_COMBOBOX(
		$self,
		$self->{m_comboBox1},
		sub {
			shift->on_combobox(@_);
		},
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{m_comboBox1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_listBox1} = Wx::ListBox->new(
		$self->{m_panel3},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		[],
	);

	$self->{m_listCtrl1} = Wx::ListCtrl->new(
		$self->{m_panel3},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxLC_ICON,
	);

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_col_click(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_item_activated(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_item_selected(@_);
		},
	);

	$self->{m_customControl1} = My::CustomControl->new(
		$self->{m_panel3},
		-1,
	);

	$self->{m_panel4} = Wx::Panel->new(
		$self->{m_splitter1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_scrolledWindow1} = Wx::ScrolledWindow->new(
		$self->{m_panel4},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxHSCROLL | wxVSCROLL,
	);
	$self->{m_scrolledWindow1}->SetScrollRate( 5, 5 );

	$self->{m_htmlWin1} = t::lib::MyHtmlWindow->new(
		$self->{m_scrolledWindow1},
		-1,
		wxDefaultPosition,
		[ 200, 200 ],
		wxHW_SCROLLBAR_AUTO,
	);

	$self->{m_notebook1} = Wx::Notebook->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_panel8} = Wx::Panel->new(
		$self->{m_notebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_checkBox1} = Wx::CheckBox->new(
		$self->{m_panel8},
		-1,
		Wx::gettext("Check Me!"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_checkBox2} = Wx::CheckBox->new(
		$self->{m_panel8},
		-1,
		Wx::gettext("Check Me!"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_checkBox3} = Wx::CheckBox->new(
		$self->{m_panel8},
		-1,
		Wx::gettext("Check Me!"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_checkBox4} = Wx::CheckBox->new(
		$self->{m_panel8},
		-1,
		Wx::gettext("Check Me!"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_panel9} = Wx::Panel->new(
		$self->{m_notebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_treeCtrl1} = Wx::TreeCtrl->new(
		$self->{m_panel9},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTR_DEFAULT_STYLE,
	);

	$self->{m_radioBtn1} = Wx::RadioButton->new(
		$self->{m_panel9},
		-1,
		Wx::gettext("One"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_radioBtn2} = Wx::RadioButton->new(
		$self->{m_panel9},
		-1,
		Wx::gettext("Two"),
		wxDefaultPosition,
		wxDefaultSize,
	);
	$self->{m_radioBtn2}->SetValue(1);

	$self->{m_radioBtn3} = Wx::RadioButton->new(
		$self->{m_panel9},
		-1,
		Wx::gettext("This"),
		wxDefaultPosition,
		wxDefaultSize,
		wxRB_GROUP,
	);

	$self->{m_radioBtn4} = Wx::RadioButton->new(
		$self->{m_panel9},
		-1,
		Wx::gettext("That"),
		wxDefaultPosition,
		wxDefaultSize,
	);
	$self->{m_radioBtn4}->SetValue(1);

	$self->{m_animCtrl1} = Wx::AnimationCtrl->new(
		$self->{m_panel9},
		-1,
		wxNullAnimation,
		wxDefaultPosition,
		wxDefaultSize,
		wxAC_DEFAULT_STYLE,
	);
	$self->{m_animCtrl1}->SetInactiveBitmap(
		Wx::Bitmap->new( "padre-plugin.png", wxBITMAP_TYPE_ANY )
	);

	$self->{m_panel11} = Wx::Panel->new(
		$self->{m_notebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_calendar2} = Wx::CalendarCtrl->new(
		$self->{m_panel11},
		-1,
		Wx::DateTime->new,
		wxDefaultPosition,
		wxDefaultSize,
		wxCAL_MONDAY_FIRST | wxCAL_SHOW_HOLIDAYS | wxCAL_SHOW_SURROUNDING_WEEKS,
	);

	$self->{m_listbook1} = Wx::Listbook->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxLB_DEFAULT,
	);

	$self->{m_panel1} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_staticText2} = Wx::StaticText->new(
		$self->{m_panel1},
		-1,
		Wx::gettext("This is a test"),
	);
	$self->{m_staticText2}->SetForegroundColour(
		Wx::Colour->new( 0, 0, 255 )
	);

	$self->{m_spinCtrl1} = Wx::SpinCtrl->new(
		$self->{m_panel1},
		-1,
		"",
		wxDefaultPosition,
		wxDefaultSize,
		wxSP_ARROW_KEYS,
		0,
		10,
		5,
	);

	Wx::Event::EVT_KEY_UP(
		$self->{m_spinCtrl1},
		sub {
			$self->on_key_up($_[1]);
		},
	);

	$self->{m_radioBox1} = Wx::RadioBox->new(
		$self->{m_panel1},
		-1,
		Wx::gettext("Radio Gaga"),
		wxDefaultPosition,
		wxDefaultSize,
		[
			"One",
			"Two",
			"Three",
			"Four",
		],
		2,
		wxRA_SPECIFY_COLS,
	);
	$self->{m_radioBox1}->SetSelection(2);

	Wx::Event::EVT_RADIOBOX(
		$self,
		$self->{m_radioBox1},
		sub {
			shift->on_radio_box(@_);
		},
	);

	$self->{m_slider1} = Wx::Slider->new(
		$self->{m_panel1},
		-1,
		50,
		0,
		100,
		wxDefaultPosition,
		wxDefaultSize,
		wxSL_HORIZONTAL,
	);

	$self->{m_panel2} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_textCtrl2} = Wx::TextCtrl->new(
		$self->{m_panel2},
		-1,
		"This is a test",
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_colourPicker1} = Wx::ColourPickerCtrl->new(
		$self->{m_panel2},
		-1,
		Wx::Colour->new( 255, 0, 0 ),
		wxDefaultPosition,
		wxDefaultSize,
		wxCLRP_DEFAULT_STYLE,
	);

	$self->{m_colourPicker2} = Wx::ColourPickerCtrl->new(
		$self->{m_panel2},
		-1,
		Wx::SystemSettings::GetColour( wxSYS_COLOUR_INFOBK ),
		wxDefaultPosition,
		wxDefaultSize,
		wxCLRP_DEFAULT_STYLE,
	);
	$self->{m_colourPicker2}->Disable;
	$self->{m_colourPicker2}->Hide;

	$self->{m_fontPicker1} = Wx::FontPickerCtrl->new(
		$self->{m_panel2},
		-1,
		wxNullFont,
		wxDefaultPosition,
		wxDefaultSize,
		wxFNTP_DEFAULT_STYLE,
	);
	$self->{m_fontPicker1}->SetMaxPointSize(100);

	$self->{m_filePicker1} = Wx::FilePickerCtrl->new(
		$self->{m_panel2},
		-1,
		"",
		Wx::gettext("Select a file"),
		"*.*",
		wxDefaultPosition,
		wxDefaultSize,
		wxFLP_DEFAULT_STYLE,
	);

	Wx::Event::EVT_FILEPICKER_CHANGED(
		$self,
		$self->{m_filePicker1},
		sub {
			shift->m_filePicker1_changed(@_);
		},
	);

	$self->{m_dirPicker1} = Wx::DirPickerCtrl->new(
		$self->{m_panel2},
		-1,
		"",
		Wx::gettext("Select a folder"),
		wxDefaultPosition,
		wxDefaultSize,
		wxDIRP_DEFAULT_STYLE,
	);

	$self->{m_panel5} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_listbook2} = Wx::Treebook->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_panel6} = Wx::Panel->new(
		$self->{m_listbook2},
		-1,
		wxDefaultPosition,
		[ 100, 100 ],
		wxTAB_TRAVERSAL,
	);

	$self->{m_hyperlink1} = Wx::HyperlinkCtrl->new(
		$self->{m_panel6},
		-1,
		Wx::gettext("wxFormBuilder Website"),
		"http://www.wxformbuilder.org",
		wxDefaultPosition,
		wxDefaultSize,
		wxHL_DEFAULT_STYLE,
	);
	$self->{m_hyperlink1}->SetNormalColour(
		Wx::SystemSettings::GetColour( wxSYS_COLOUR_WINDOWTEXT )
	);
	$self->{m_hyperlink1}->SetHoverColour(
		Wx::Colour->new( 255, 128, 0 )
	);

	$self->{m_button2} = Wx::Button->new(
		$self->{m_panel6},
		-1,
		Wx::gettext("MyButton"),
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{m_panel7} = Wx::Panel->new(
		$self->{m_listbook2},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_staticText3} = Wx::StaticText->new(
		$self->{m_panel7},
		-1,
		Wx::gettext("MyLabel"),
	);

	$self->{m_searchCtrl1} = Wx::SearchCtrl->new(
		$self->{m_panel7},
		-1,
		"",
		wxDefaultPosition,
		wxDefaultSize,
	);
	unless ( Wx::wxMAC ) {
		$self->{m_searchCtrl1}->ShowSearchButton(1);
	}
	$self->{m_searchCtrl1}->ShowCancelButton(0);

	$self->{m_gauge1} = Wx::Gauge->new(
		$self->{m_panel7},
		-1,
		100,
		wxDefaultPosition,
		wxDefaultSize,
		wxGA_HORIZONTAL,
	);
	$self->{m_gauge1}->SetValue(85);

	$self->{m_choicebook1} = Wx::Choicebook->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxCHB_DEFAULT,
	);

	$self->{m_panel13} = Wx::Panel->new(
		$self->{m_choicebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_richText1} = Wx::RichTextCtrl->new(
		$self->{m_panel13},
		-1,
		"",
		wxDefaultPosition,
		wxDefaultSize,
		wxVSCROLL | wxHSCROLL | wxNO_BORDER | wxWANTS_CHARS,
	);

	$self->{m_panel12} = Wx::Panel->new(
		$self->{m_choicebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_grid1} = Wx::Grid->new(
		$self->{m_panel12},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
	);
	$self->{m_grid1}->CreateGrid( 5, 5 );
	$self->{m_grid1}->EnableEditing(1);
	$self->{m_grid1}->EnableGridLines(1);
	$self->{m_grid1}->SetGridLineColour(
		Wx::Colour->new( 255, 0, 0 )
	);
	$self->{m_grid1}->EnableDragGridSize(0);
	$self->{m_grid1}->SetMargins( 1, 0 );
	$self->{m_grid1}->SetColSize( 0, 10 );
	$self->{m_grid1}->SetColSize( 1, 20 );
	$self->{m_grid1}->SetColSize( 2, 30 );
	$self->{m_grid1}->SetColSize( 3, 40 );
	$self->{m_grid1}->SetColSize( 4, 50 );
	$self->{m_grid1}->AutoSizeColumns;
	$self->{m_grid1}->EnableDragColMove(0);
	$self->{m_grid1}->EnableDragColSize(1);
	$self->{m_grid1}->SetColLabelSize(30);
	$self->{m_grid1}->SetColLabelValue( 0, Wx::gettext("A") );
	$self->{m_grid1}->SetColLabelValue( 1, Wx::gettext("B") );
	$self->{m_grid1}->SetColLabelValue( 2, Wx::gettext("C") );
	$self->{m_grid1}->SetColLabelValue( 3, Wx::gettext("D") );
	$self->{m_grid1}->SetColLabelValue( 4, Wx::gettext("E") );
	$self->{m_grid1}->SetColLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );
	$self->{m_grid1}->SetRowSize( 0, 10 );
	$self->{m_grid1}->SetRowSize( 1, 20 );
	$self->{m_grid1}->SetRowSize( 2, 30 );
	$self->{m_grid1}->SetRowSize( 3, 40 );
	$self->{m_grid1}->SetRowSize( 4, 50 );
	$self->{m_grid1}->AutoSizeRows;
	$self->{m_grid1}->EnableDragRowSize(1);
	$self->{m_grid1}->SetRowLabelValue( 0, Wx::gettext("1") );
	$self->{m_grid1}->SetRowLabelValue( 1, Wx::gettext("2") );
	$self->{m_grid1}->SetRowLabelValue( 2, Wx::gettext("3") );
	$self->{m_grid1}->SetRowLabelValue( 3, Wx::gettext("4") );
	$self->{m_grid1}->SetRowLabelValue( 4, Wx::gettext("5") );
	$self->{m_grid1}->SetRowLabelAlignment( wxALIGN_CENTRE, wxALIGN_CENTRE );
	$self->{m_grid1}->SetLabelBackgroundColour(
		Wx::SystemSettings::GetColour( wxSYS_COLOUR_INFOBK )
	);
	$self->{m_grid1}->SetLabelFont(
		Wx::Font->new( wxNORMAL_FONT->GetPointSize, 75, 90, 90, 0, "" )
	);
	$self->{m_grid1}->SetLabelTextColour(
		Wx::Colour->new( 0, 255, 0 )
	);
	$self->{m_grid1}->SetDefaultCellBackgroundColour(
		Wx::SystemSettings::GetColour( wxSYS_COLOUR_WINDOW )
	);
	$self->{m_grid1}->SetDefaultCellAlignment( wxALIGN_LEFT, wxALIGN_TOP );

	$self->{m_scrollBar1} = Wx::ScrollBar->new(
		$self->{m_panel12},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxSB_HORIZONTAL,
	);

	$self->{m_panel131} = Wx::Panel->new(
		$self->{m_choicebook1},
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{m_genericDirCtrl1} = Wx::GenericDirCtrl->new(
		$self->{m_panel131},
		-1,
		"default/folder",
		wxDefaultPosition,
		wxDefaultSize,
		wxDIRCTRL_3D_INTERNAL | wxSUNKEN_BORDER,
		"*.txt",
		0,
	);
	$self->{m_genericDirCtrl1}->ShowHidden(0);

	my $bSizer10 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer10->SetMinSize( [ -1, 50 ] );
	$bSizer10->Add( $self->{m_bitmap1}, 0, wxALL, 5 );
	$bSizer10->Add( $self->{m_textCtrl1}, 0, wxALL, 5 );
	$bSizer10->Add( $self->{m_button1}, 0, wxALL, 5 );
	$bSizer10->Add( $self->{m_toggleBtn1}, 0, wxALL, 5 );
	$bSizer10->Add( $self->{m_bpButton1}, 0, wxALL, 5 );
	$bSizer10->Add( $self->{m_spinBtn1}, 0, wxALL, 5 );

	my $fgSizer1 = Wx::FlexGridSizer->new( 1, 2, 3, 4 );
	$fgSizer1->AddGrowableCol(0);
	$fgSizer1->AddGrowableCol(1);
	$fgSizer1->SetFlexibleDirection(wxBOTH);
	$fgSizer1->SetNonFlexibleGrowMode(wxFLEX_GROWMODE_SPECIFIED);
	$fgSizer1->Add( $self->{m_choice1}, 0, wxALL, 5 );
	$fgSizer1->Add( $self->{m_comboBox1}, 0, wxALL | wxEXPAND, 5 );
	$fgSizer1->Add( $self->{m_listBox1}, 0, wxALL, 5 );
	$fgSizer1->Add( $self->{m_listCtrl1}, 0, wxALL | wxEXPAND, 5 );
	$fgSizer1->Add( $self->{m_customControl1}, 0, wxALL | wxEXPAND, 5 );

	$self->{m_panel3}->SetSizerAndFit($fgSizer1);
	$self->{m_panel3}->Layout;

	my $bSizer9 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer9->Add( $self->{m_htmlWin1}, 0, wxALL | wxEXPAND, 5 );

	$self->{m_scrolledWindow1}->SetSizerAndFit($bSizer9);
	$self->{m_scrolledWindow1}->Layout;

	my $sbSizer1 = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("The Interweb"),
		),
		wxVERTICAL,
	);
	$sbSizer1->Add( $self->{m_scrolledWindow1}, 1, wxEXPAND | wxALL, 5 );

	$self->{m_panel4}->SetSizerAndFit($sbSizer1);
	$self->{m_panel4}->Layout;

	$self->{m_splitter1}->SplitVertically(
		$self->{m_panel3},
		$self->{m_panel4},
	);

	my $gSizer1 = Wx::GridSizer->new( 1, 2, 3, 4 );
	$gSizer1->Add( $self->{m_checkBox1}, 0, wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox2}, 0, wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox3}, 0, wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox4}, 0, wxALL, 5 );

	$self->{m_panel8}->SetSizerAndFit($gSizer1);
	$self->{m_panel8}->Layout;

	my $bSizer12 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer12->Add( $self->{m_treeCtrl1}, 0, wxALL, 5 );
	$bSizer12->Add( $self->{m_radioBtn1}, 0, wxALL, 5 );
	$bSizer12->Add( $self->{m_radioBtn2}, 0, wxALL, 5 );
	$bSizer12->Add( $self->{m_radioBtn3}, 0, wxALL, 5 );
	$bSizer12->Add( $self->{m_radioBtn4}, 0, wxALL, 5 );
	$bSizer12->Add( $self->{m_animCtrl1}, 0, wxALL, 5 );

	$self->{m_panel9}->SetSizerAndFit($bSizer12);
	$self->{m_panel9}->Layout;

	my $bSizer14 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer14->Add( $self->{m_calendar2}, 0, wxALL, 5 );

	$self->{m_panel11}->SetSizerAndFit($bSizer14);
	$self->{m_panel11}->Layout;

	$self->{m_notebook1}->AddPage( $self->{m_panel8}, Wx::gettext("Checkboxes"), 1 );
	$self->{m_notebook1}->AddPage( $self->{m_panel9}, Wx::gettext("Empty Tree"), 0 );
	$self->{m_notebook1}->AddPage( $self->{m_panel11}, Wx::gettext("Calendar"), 0 );

	my $bSizer3 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer3->Add( $self->{m_staticText2}, 0, wxALL, 5 );
	$bSizer3->Add( $self->{m_spinCtrl1}, 0, wxALL, 5 );
	$bSizer3->Add( $self->{m_radioBox1}, 0, wxALL, 5 );
	$bSizer3->Add( $self->{m_slider1}, 0, wxALL | wxEXPAND, 5 );

	$self->{m_panel1}->SetSizerAndFit($bSizer3);
	$self->{m_panel1}->Layout;

	my $bSizer4 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer4->Add( $self->{m_textCtrl2}, 0, wxALL, 5 );
	$bSizer4->Add( $self->{m_colourPicker1}, 0, wxALL, 5 );
	$bSizer4->Add( $self->{m_colourPicker2}, 0, wxALL, 5 );
	$bSizer4->Add( $self->{m_fontPicker1}, 0, wxALL, 5 );
	$bSizer4->Add( $self->{m_filePicker1}, 0, wxALL, 5 );
	$bSizer4->Add( $self->{m_dirPicker1}, 0, wxALL, 5 );

	$self->{m_panel2}->SetSizerAndFit($bSizer4);
	$self->{m_panel2}->Layout;

	$self->{m_listbook1}->AddPage( $self->{m_panel1}, Wx::gettext("Page One"), 1 );
	$self->{m_listbook1}->AddPage( $self->{m_panel2}, Wx::gettext("Page Two"), 0 );
	$self->{m_listbook1}->AddPage( $self->{m_panel5}, Wx::gettext("Page Three"), 0 );

	my $bSizer5 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer5->Add( $self->{m_hyperlink1}, 0, wxALL, 5 );
	$bSizer5->Add( $self->{m_button2}, 0, wxALL, 5 );

	$self->{m_panel6}->SetSizer($bSizer5);
	$self->{m_panel6}->Layout;

	my $bSizer6 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer6->Add( $self->{m_staticText3}, 0, wxALL, 5 );
	$bSizer6->Add( $self->{m_searchCtrl1}, 0, wxALL, 5 );
	$bSizer6->Add( 0, 0, 1, wxEXPAND, 5 );
	$bSizer6->Add( $self->{m_gauge1}, 0, wxALL | wxEXPAND, 5 );

	$self->{m_panel7}->SetSizerAndFit($bSizer6);
	$self->{m_panel7}->Layout;

	$self->{m_listbook2}->AddPage( $self->{m_panel6}, Wx::gettext("Page One"), 0 );
	$self->{m_listbook2}->AddPage( $self->{m_panel7}, Wx::gettext("Page Two"), 1 );

	my $bSizer15 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer15->Add( $self->{m_richText1}, 1, wxEXPAND, 5 );

	$self->{m_panel13}->SetSizerAndFit($bSizer15);
	$self->{m_panel13}->Layout;

	my $bSizer151 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer151->Add( $self->{m_grid1}, 0, 0, 5 );
	$bSizer151->Add( $self->{m_scrollBar1}, 0, wxEXPAND, 5 );

	$self->{m_panel12}->SetSizerAndFit($bSizer151);
	$self->{m_panel12}->Layout;

	my $bSizer16 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer16->Add( $self->{m_genericDirCtrl1}, 1, wxEXPAND | wxALL, 5 );

	$self->{m_panel131}->SetSizerAndFit($bSizer16);
	$self->{m_panel131}->Layout;

	$self->{m_choicebook1}->AddPage( $self->{m_panel13}, Wx::gettext("Rich Text Control"), 1 );
	$self->{m_choicebook1}->AddPage( $self->{m_panel12}, Wx::gettext("Grid"), 0 );
	$self->{m_choicebook1}->AddPage( $self->{m_panel131}, Wx::gettext("Directory"), 0 );

	my $bSizer2 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer2->Add( $self->{m_staticText1}, 0, wxALL, 5 );
	$bSizer2->Add( 10, 5, 0, wxEXPAND, 5 );
	$bSizer2->Add( $bSizer10, 0, wxEXPAND, 5 );
	$bSizer2->Add( $self->{m_staticline1}, 0, wxEXPAND | wxALL, 5 );
	$bSizer2->Add( $self->{m_splitter1}, 1, wxEXPAND, 5 );
	$bSizer2->Add( $self->{m_notebook1}, 0, wxEXPAND | wxALL, 5 );
	$bSizer2->Add( $self->{m_listbook1}, 0, wxEXPAND | wxALL, 5 );
	$bSizer2->Add( $self->{m_listbook2}, 0, wxEXPAND | wxALL, 5 );
	$bSizer2->Add( $self->{m_choicebook1}, 1, wxEXPAND | wxALL, 5 );

	my $bSizer1 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer1->Add( $bSizer2, 1, wxEXPAND, 5 );

	$self->SetSizerAndFit($bSizer1);
	$self->Layout;

	return $self;
}

sub m_htmlWin1 {
	$_[0]->{m_htmlWin1};
}

sub on_init_dialog {
	warn 'Handler method on_init_dialog for event MyDialog1.OnInitDialog not implemented';
}

sub on_char {
	warn 'Handler method on_char for event m_textCtrl1.OnChar not implemented';
}

sub refresh {
	warn 'Handler method refresh for event m_textCtrl1.OnText not implemented';
}

sub m_button1 {
	warn 'Handler method m_button1 for event m_button1.OnButtonClick not implemented';
}

sub toggle_me {
	warn 'Handler method toggle_me for event m_toggleBtn1.OnToggleButton not implemented';
}

sub on_combobox {
	warn 'Handler method on_combobox for event m_comboBox1.OnCombobox not implemented';
}

sub list_col_click {
	warn 'Handler method list_col_click for event m_listCtrl1.OnListColClick not implemented';
}

sub list_item_activated {
	warn 'Handler method list_item_activated for event m_listCtrl1.OnListItemActivated not implemented';
}

sub list_item_selected {
	warn 'Handler method list_item_selected for event m_listCtrl1.OnListItemSelected not implemented';
}

sub on_key_up {
	warn 'Handler method on_key_up for event m_spinCtrl1.OnKeyUp not implemented';
}

sub on_radio_box {
	warn 'Handler method on_radio_box for event m_radioBox1.OnRadioBox not implemented';
}

sub m_filePicker1_changed {
	warn 'Handler method m_filePicker1_changed for event m_filePicker1.OnFileChanged not implemented';
}

1;
