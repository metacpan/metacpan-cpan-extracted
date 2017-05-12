package Kephra::Dialog::Keymap;
our $VERSION = '0.02';

use strict;
use warnings;


sub keymap {
	my $frame = shift;

	elements::proton::show::keyboard_map();
	return 0;

	if ( !$Kephra::temp{keymap}{dialog_active}
		|| $Kephra::temp{keymap}{dialog_active} == 0 ) {

		# init win mit grunddesign
		$Kephra::temp{'keymap'}{'dialog_active'} = 1;
		my $l18n = Kephra::Localisation::strings()->{dialogs}{keyboard_map};
		my $keymap_win = Wx::Frame->new(
			$frame, -1, ' ' . $l18n->{title},
			[ 10,  10 ], [ 420, 460 ],
			&Wx::wxNO_FULL_REPAINT_ON_RESIZE | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION |
			&Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX | &Wx::wxRESIZE_BORDER,
		);
		$frame->{keymap_win} = $keymap_win;
		Kephra::App::Window::load_icon( $keymap_win,
			Kephra::API::settings()->{main}{icon} );
		$keymap_win->SetBackgroundColour(&Wx::wxWHITE);

	  #my $keymap_ground = Wx::Panel->new($keymap_win, -1, [0,0], [-1,-1], ,);
		my $keymap_label
			= Wx::Panel->new( $keymap_win, -1, [ 0, 0 ], [ 100, 22 ],, );
		my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);

		#inhalt
		my $keymap_list = Wx::Grid->new(
			$keymap_win, -1,
			[ 0,  22 ], [ -1, -1 ],
			&Wx::wxWANTS_CHARS,,
		);
		$keymap_list->AppendCols( 3, 0 );
		$keymap_list->AppendRows( 3, 0 );
		$keymap_list->SetColLabelValue( 1, 'Beschreibung' );
		$keymap_list->SetRowLabelValue( 2, 'Kombintion' );

		#$keymap_list->AppendRows(3, 1);SetColLabelValue and SetRowLabelValue
		$sizer->Add( $keymap_label, 0, &Wx::wxTOP | &Wx::wxGROW,    0 );
		$sizer->Add( $keymap_list,  1, &Wx::wxBOTTOM | &Wx::wxGROW, 0 );
		$keymap_win->SetSizer($sizer);
		$keymap_win->SetAutoLayout(1);
		$keymap_win->Centre(&Wx::wxBOTH);
		$keymap_win->Show(1);

		Wx::Event::EVT_CLOSE( $keymap_win, \&quit_keymap_dialog );

		sub quit_keymap_dialog {
			my ( $win, $event ) = @_;

			$Kephra::temp{'keymap'}{'dialog_active'} = 0;
			$win->Destroy();
		}

		} else {
		$frame->{'keymap_win'}->Iconize(0);
		$frame->{'keymap_win'}->Raise();
	}
}

1;

