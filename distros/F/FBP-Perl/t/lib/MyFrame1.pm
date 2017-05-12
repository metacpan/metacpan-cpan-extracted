package t::lib::MyFrame1;

## no critic

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';

our $VERSION = '0.78';
our @ISA     = 'Wx::Frame';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("Frame Title"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);
	$self->CreateStatusBar( 2, Wx::wxST_SIZEGRIP, -1 );

	Wx::Event::EVT_ACTIVATE(
		$self,
		sub {
			shift->on_activate(@_);
		},
	);

	Wx::Event::EVT_ACTIVATE_APP(
		$self,
		sub {
			shift->on_activate_app(@_);
		},
	);

	Wx::Event::EVT_CLOSE(
		$self,
		sub {
			shift->on_close(@_);
		},
	);

	Wx::Event::EVT_ICONIZE(
		$self,
		sub {
			shift->on_iconize(@_);
		},
	);

	Wx::Event::EVT_IDLE(
		$self,
		sub {
			shift->on_idle(@_);
		},
	);

	$self->{m_menu1} = Wx::Menu->new;

	my $m_menuItem1 = Wx::MenuItem->new(
		$self->{m_menu1},
		-1,
		Wx::gettext("MyMenuItem"),
		'',
		Wx::wxITEM_NORMAL,
	);

	Wx::Event::EVT_MENU(
		$self,
		$m_menuItem1,
		sub {
			shift->menu_event(@_);
		},
	);

	my $m_menuItem2 = Wx::MenuItem->new(
		$self->{m_menu1},
		-1,
		Wx::gettext("MyMenuItem..."),
		'',
		Wx::wxITEM_NORMAL,
	);

	$self->{m_menu1}->Append( $m_menuItem1 );
	$self->{m_menu1}->AppendSeparator;
	$self->{m_menu1}->Append( $m_menuItem2 );

	$self->{m_menubar1} = Wx::MenuBar->new(0);

	$self->{m_menubar1}->Append(
		$self->{m_menu1},
		Wx::gettext("File"),
	);

	$self->SetMenuBar( $self->{m_menubar1} );

	$self->{m_toolBar1} = $self->CreateToolBar( Wx::wxTB_HORIZONTAL, -1 );
	$self->{m_toolBar1}->AddTool(
		-1,
		Wx::gettext("Tool 1"),
		Wx::Bitmap->new( "padre-plugin.png", Wx::wxBITMAP_TYPE_ANY ),
		'',
		Wx::wxITEM_NORMAL,
	);
	$self->{m_toolBar1}->AddSeparator;
	$self->{m_toolBar1}->AddTool(
		-1,
		Wx::gettext("Tool 2"),
		Wx::wxNullBitmap,
		'',
		Wx::wxITEM_NORMAL,
	);
	$self->{m_toolBar1}->Realize;

	$self->{m_staticText5} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("MyLabel:"),
	);

	$self->{m_sdbSizer1_yes} = Wx::Button->new(
		$self,
		Wx::wxID_YES,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{m_sdbSizer1_yes},
		sub {
			shift->yes_clicked(@_);
		},
	);

	$self->{m_sdbSizer1_no} = Wx::Button->new(
		$self,
		Wx::wxID_NO,
	);

	$self->{m_sdbSizer1_cancel} = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
	);

	$self->{m_sdbSizer1} = Wx::StdDialogButtonSizer->new;
	$self->{m_sdbSizer1}->AddButton( $self->{m_sdbSizer1_yes} );
	$self->{m_sdbSizer1}->AddButton( $self->{m_sdbSizer1_no} );
	$self->{m_sdbSizer1}->AddButton( $self->{m_sdbSizer1_cancel} );
	$self->{m_sdbSizer1}->Realize;

	my $bSizer7 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer7->Add( $self->{m_staticText5}, 1, Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxALL, 10 );
	$bSizer7->Add( $self->{m_sdbSizer1}, 0, Wx::wxBOTTOM | Wx::wxEXPAND, 5 );

	$self->SetSizerAndFit($bSizer7);
	$self->Layout;

	return $self;
}

sub on_activate {
	warn 'Handler method on_activate for event t::lib::MyFrame1.OnActivate not implemented';
}

sub on_activate_app {
	warn 'Handler method on_activate_app for event t::lib::MyFrame1.OnActivateApp not implemented';
}

sub on_close {
	warn 'Handler method on_close for event t::lib::MyFrame1.OnClose not implemented';
}

sub on_iconize {
	warn 'Handler method on_iconize for event t::lib::MyFrame1.OnIconize not implemented';
}

sub on_idle {
	warn 'Handler method on_idle for event t::lib::MyFrame1.OnIdle not implemented';
}

sub menu_event {
	warn 'Handler method menu_event for event m_menuItem1.OnMenuSelection not implemented';
}

sub yes_clicked {
	warn 'Handler method yes_clicked for event m_sdbSizer1.OnYesButtonClick not implemented';
}

1;
