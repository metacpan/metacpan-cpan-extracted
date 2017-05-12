package MyPanel1;

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';

our $VERSION = '0.78';
our @ISA     = 'Wx::Panel';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);
	$self->SetBackgroundColour(
		Wx::Colour->new( 255, 0, 0 )
	);

	Wx::Event::EVT_ENTER_WINDOW(
		$self,
		sub {
			shift->on_enter_window(@_);
		},
	);

	Wx::Event::EVT_LEAVE_WINDOW(
		$self,
		sub {
			shift->on_leave_window(@_);
		},
	);

	$self->{m_staticText6} = Wx::StaticText->new(
		$self,
		-1,
		": " . Wx::gettext("Long 2 column spanning text") . " :",
	);

	$self->{m_button5} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Left Button"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_button51} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Right Button") . "...",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_staticText61} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Don't press this") . ":",
	);

	my $bSizer11 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer11->Add( $self->{m_button51}, 0, Wx::wxALL, 5 );
	$bSizer11->Add( $self->{m_staticText61}, 0, Wx::wxALL, 5 );

	my $gbSizer2 = Wx::GridBagSizer->new( 0, 0 );
	$gbSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$gbSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$gbSizer2->Add(
		$self->{m_staticText6},
		Wx::GBPosition->new( 0, 0 ),
		Wx::GBSpan->new( 1, 3 ),
		Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxALL,
		5,
	);
	$gbSizer2->Add(
		$self->{m_button5},
		Wx::GBPosition->new( 1, 0 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxALL,
		5,
	);
	$gbSizer2->Add(
		20,
		10,
		Wx::GBPosition->new( 1, 1 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxEXPAND,
		5,
	);
	$gbSizer2->Add(
		$bSizer11,
		Wx::GBPosition->new( 1, 2 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxEXPAND,
		5,
	);

	my $bSizer8 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer8->Add( $gbSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizerAndFit($bSizer8);
	$self->Layout;

	return $self;
}

sub on_enter_window {
	warn 'Handler method on_enter_window for event MyPanel1.OnEnterWindow not implemented';
}

sub on_leave_window {
	warn 'Handler method on_leave_window for event MyPanel1.OnLeaveWindow not implemented';
}

1;
