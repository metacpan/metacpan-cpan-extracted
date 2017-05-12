package Kephra::Dialog::Exit;
our $VERSION = '0.07';

use strict;
use warnings;


sub save_on_exit {

	# checking settings if i should save or quit without question
	my $save = Kephra::API::settings()->{file}{save}{b4_quit};
	if    ($save eq '0') {                         return}
	elsif ($save eq '1') {&Kephra::File::save_all; return}

	# count unsaved dacuments?
	my $unsaved_docs = 0;
	for ( @{ Kephra::Document::Data::all_nr() } ) {
		$unsaved_docs++ if Kephra::Document::Data::get_attribute('modified', $_)
	}

	# if so...
	if ($unsaved_docs) {
		my $d18n = Kephra::Config::Localisation::strings()->{dialog};
		my $dialog = $Kephra::app{dialog}{exit} = Wx::Dialog->new(
			Kephra::App::Window::_ref(), -1,
			$d18n->{file}{quit_unsaved}, [-1,-1], [-1,-1],
			&Wx::wxNO_FULL_REPAINT_ON_RESIZE | &Wx::wxCAPTION | &Wx::wxSTAY_ON_TOP,
		);

		# starting dialog layout
		my $v_sizer      = Wx::BoxSizer->new(&Wx::wxVERTICAL);
		my $h_sizer      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
		my $button_sizer = Wx::GridSizer->new( 1, 4, 0, 25 );
		my ( @temp_sizer, @check_boxes );
		my ( $border,     $b_border, $max_width ) = ( 10, 20, 0 );
		my ( $x_size,     $y_size );
		my ( $file_name,  $check_label );
		my $align_lc = &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL;
		my $l10n = Kephra::Config::Localisation::strings()->{dialog}{general};

		# generating checkbox list of unsaved files
		for ( @{ Kephra::Document::Data::all_nr() } ) {
			if ( Kephra::Document::Data::get_attribute('modified', $_) ) {
				$file_name = 
					Kephra::Document::Data::get_file_path($_) || 
					Kephra::Config::Localisation::strings()->{app}{general}{untitled};
				$check_label = 1 + $_ . ' ' . $file_name;
				$check_boxes[$_] = Wx::CheckBox->new($dialog, -1, $check_label);
				$check_boxes[$_]->SetValue(1);
				$temp_sizer[$_] = Wx::BoxSizer->new(&Wx::wxVERTICAL);
				$temp_sizer[$_]->Add($check_boxes[$_], 0, $align_lc, $border );
				$v_sizer->Add( $temp_sizer[$_], 0, &Wx::wxTOP, $border );
				$temp_sizer[$_]->Fit($dialog);
				( $x_size, $y_size ) = $dialog->GetSizeWH;
				$max_width = $x_size if $x_size > $max_width;
			}
		}

		# seperator, label, buttons
		my $base_line = Wx::StaticLine->new( $dialog, -1, [-1,-1],[2000,2], &Wx::wxLI_HORIZONTAL);
		my $save_label = Wx::StaticText->new($dialog, -1, $l10n->{save} . ' : ');
		$dialog->{save_all} = Wx::Button->new($dialog, -1, $l10n->{all} );
		$dialog->{save_sel} = Wx::Button->new($dialog, -1, $l10n->{selected} );
		$dialog->{save_none}= Wx::Button->new($dialog, -1, $l10n->{none} );
		$dialog->{cancel}   = Wx::Button->new($dialog, -1, $l10n->{cancel} );

		# events
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{save_all}, sub 
			{ &quit_dialog; &Kephra::File::save_all} );
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{save_sel}, sub 
			{&quit_dialog; save_selected(\@check_boxes)} );
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{save_none},sub {quit_dialog()} );
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{cancel},   sub
			{ &quit_dialog; $dialog->{cancel} = 1; } );
		Wx::Event::EVT_CLOSE( $dialog,                      sub {quit_dialog()});

		# assembling the fix bottom of dialog layout
		$h_sizer->Add( $save_label, 0, $align_lc, $border );
		$h_sizer->Add( $dialog->{save_all}, 0, $align_lc, $border + $b_border );
		$h_sizer->Add( $dialog->{save_sel}, 0, $align_lc, $b_border );
		$h_sizer->Add( $dialog->{save_none}, 0, $align_lc, $b_border );
		$h_sizer->Add( $dialog->{cancel}, 0, $align_lc, $b_border );

		$v_sizer->Add( $base_line, 0, &Wx::wxTOP | &Wx::wxCENTER, $border );
		$v_sizer->Add( $h_sizer, 0, &Wx::wxTOP, $border );

		# figuring dialog size
		$dialog->SetSizer($v_sizer);
		$v_sizer->Fit($dialog);
		( $x_size, $y_size ) = $dialog->GetSizeWH;
		$h_sizer->Fit($dialog);
		( $x_size, ) = $dialog->GetSizeWH;
		$max_width = $x_size if ( $x_size > $max_width );
		$dialog->SetSize( $max_width + $b_border, $y_size + $border );

		# go
		$dialog->SetAutoLayout(1);
		$dialog->CenterOnScreen;
		$dialog->ShowModal;
		return 'cancel' if $dialog->{cancel} == 1;
	}
}

# internal subs
################
sub save_selected {
	my @check_boxes = @{ shift; };
	for ( 0 .. $#check_boxes ) {
		Kephra::File::_save_nr($_)
			if ref $check_boxes[$_] ne '' and $check_boxes[$_]->GetValue;
	}
}

sub quit_dialog {
	my ( $win, $event ) = @_;
	$Kephra::app{dialog}{exit}->Destroy;
}

1;
