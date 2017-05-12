package Kephra::Dialog::Config;
our $VERSION = '0.18';

use strict;
use warnings;

my $dialog;
sub _ref { $dialog = ref $_[0] eq 'Wx::Dialog' ? $_[0] : $dialog }

sub main {
	if ( !$Kephra::temp{dialog}{config}{active}
	or    $Kephra::temp{dialog}{config}{active} == 0 ) {

		# init search and replace dialog
		$Kephra::temp{dialog}{config}{active} = 1;
		my $frame  = Kephra::App::Window::_ref();
		my $config = Kephra::API::settings()->{dialog}{config};
		my $l18n   = Kephra::Config::Localisation::strings();
		my $d_l10n = $l18n->{dialog}{config};
		my $g_l10n = $l18n->{dialog}{general};
		my $m_l10n = $l18n->{app}{menu};
		my $cl_l10n = $l18n->{commandlist}{label};
		my $d_style= &Wx::wxNO_FULL_REPAINT_ON_RESIZE | &Wx::wxSYSTEM_MENU | 
			&Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX;
		#$d_style |= &Wx::wxSTAY_ON_TOP if Kephra::API::settings()->{app}{window}{stay_on_top};


# my $staticbox = Wx::StaticBox->new( $panel, -1, 'Wx::StaticBox' );
# my $button    = Wx::Button->new( $panel, -1, 'Button 3' );
# my $nsz = Wx::StaticBoxSizer->new( $staticbox, &Wx::wxVERTICAL);
#	$panel->SetSizer($nsz);
#	$nsz->Add( $button, 0, &Wx::wxGROW|&Wx::wxTOP, 5 );
	
		# making window & main design
		my $d = Wx::Dialog->new( $frame, -1, ' '.$d_l10n->{title},
			[ $config->{position_x}, $config->{position_y} ], [ 470, 560 ],
			$d_style);
		my $icon_bmp = Kephra::CommandList::get_cmd_property
			('view-dialog-config', 'icon');
		my $icon = Wx::Icon->new;
		$icon->CopyFromBitmap($icon_bmp) if ref $icon_bmp eq 'Wx::Bitmap';
		$d->SetIcon($icon);
		_ref($d);

		# main panel
		#my $mainpanel = Wx::Panel->new( $d, -1, [-1,-1], [-1,-1] );
		# tree of categories
		my $cfg_tree = Wx::Treebook->new( $d, -1, [-1,-1], [-1,-1], &Wx::wxBK_LEFT);
		my ($panel);

		# general settings
		my $pg = $panel->{general} = Wx::Panel->new( $cfg_tree );
		$pg->{save} = Wx::StaticText->new( $pg, -1, 'Speichern');
		$pg->{sizer} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
		$pg->{sizer}->Add( $pg->{save} , 0, &Wx::wxLEFT, 5 );
		$pg->SetSizer( $pg->{sizer} );

		$cfg_tree->AddPage( $panel->{general}, 'General', 1);
		$panel->{Interface} = $cfg_tree->AddPage( undef, 'Interface', 1);
		$panel->{file} = $cfg_tree->AddPage( undef, 'File', 1);
		$cfg_tree->AddSubPage( undef, 'Defaults', 1);
		$cfg_tree->AddSubPage( undef, 'Save', 1);
		$cfg_tree->AddSubPage( undef, 'Endings', 1);
		$cfg_tree->AddSubPage( undef, 'Session', 1);
		$cfg_tree->AddPage( undef, 'Editpanel', 1);

		# button line
		$d->{apply_button} = Wx::Button->new ( $d, -1, $g_l10n->{apply} );
		$d->{cancel_button} = Wx::Button->new( $d, -1, $g_l10n->{cancel});
		Wx::Event::EVT_BUTTON( $d, $d->{apply_button}, sub {shift->Close} );
		Wx::Event::EVT_BUTTON( $d, $d->{cancel_button},sub {shift->Close} );
		my $button_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
		$button_sizer->Add( $d->{apply_button},  0, &Wx::wxRIGHT, 14 );
		$button_sizer->Add( $d->{cancel_button}, 0, &Wx::wxRIGHT, 22 );


		# assembling lines
		my $d_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
		$d_sizer->Add( $cfg_tree,     1, &Wx::wxEXPAND|&Wx::wxALL,   14);
		$d_sizer->Add( $button_sizer, 0, &Wx::wxBOTTOM|&Wx::wxALIGN_RIGHT, 12);

		# release
		$d->SetSizer($d_sizer);
		$d->SetAutoLayout(1);
		$d->Show(1);
		Wx::Window::SetFocus( $d->{cancel_button} );

		Wx::Event::EVT_CLOSE( $d, \&quit_config_dialog );
	} else {
		my $d = _ref();
		$d->Iconize(0);
		$d->Raise;
	}
}

# helper sub td { Wx::TreeItemData->new( $_[0] ) }

sub quit_config_dialog {
	my ( $win, $event ) = @_;
	my $cfg = Kephra::API::settings()->{dialog}{config};
	if ( $cfg->{save_position} == 1 ) {
		( $cfg->{position_x}, $cfg->{position_y} ) = $win->GetPositionXY;
	}
	$Kephra::temp{dialog}{config}{active} = 0;
	$win->Destroy;
}

1;
