package Kephra::App::Panel::Notepad;
our $VERSION = '0.16';

use strict;
use warnings;

my $global_notepad;
my $local_notepad;
sub _global_ref {
	$global_notepad = ref $_[0] eq 'Wx::StyledTextCtrl' ? $_[0] : $global_notepad
}
sub _local_ref {
	$local_notepad = ref $_[0] eq 'Wx::StyledTextCtrl' ? $_[0] : $local_notepad
} #document.current.number.changed
sub _ref {
	_global_ref()
}
sub _local_splitter {}
sub _config  { Kephra::API::settings()->{app}{panel}{notepad} }
sub _splitter{ $Kephra::app{splitter}{right} }

sub create {
	my $win    = Kephra::App::Window::_ref();
	my $notepad;
	if ( _global_ref()) {$notepad = _global_ref()}
	else {
		my $color  = \&Kephra::Config::color;
		my $indicator = Kephra::App::EditPanel::_config()->{indicator};
		my $config = _config();
		$notepad = Wx::StyledTextCtrl->new( $win, -1, [-1,-1], [-1,-1] );
		$notepad->SetWrapMode(&Wx::wxSTC_WRAP_WORD);
		$notepad->SetScrollWidth(210);
		$notepad->SetMarginWidth(0,0);
		$notepad->SetMarginWidth(1,0);
		$notepad->SetMarginWidth(2,0);
		$notepad->SetMargins(3,3);
		$notepad->SetCaretPeriod( $indicator->{caret}{period} );
		$notepad->SetCaretWidth( $indicator->{caret}{width} );
		$notepad->SetCaretForeground( &$color( $indicator->{caret}{color} ) );
		if ( $indicator->{selection}{fore_color} ne '-1' ) {
			$notepad->SetSelForeground
				( 1, &$color( $indicator->{selection}{fore_color} ) );
		}
		$notepad->SetSelBackground( 1, &$color( $indicator->{selection}{back_color}));
		$notepad->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, Wx::Font->new
			(_config()->{font_size}, &Wx::wxDEFAULT, &Wx::wxNORMAL, &Wx::wxNORMAL, 0,
			_config()->{font_family}) 
		);
		$notepad->SetTabWidth(4);
		$notepad->SetIndent(4);
		$notepad->SetHighlightGuide(4);

		# load content
		my $file_name = $config->{content_file};
		if ($file_name) {
			$file_name = Kephra::Config::filepath($file_name);
			if (-e $file_name){
				open my $FILE, '<', $file_name;
				$notepad->AppendText( $_ ) while <$FILE>;
			}
		}
	}
	$notepad->Show( get_visibility() );

	Wx::Event::EVT_KEY_DOWN( $notepad, sub {
			my ( $fi, $event ) = @_;
			my $key = $event->GetKeyCode;
			my $ep = Kephra::App::EditPanel::_ref();
			if ($key == &Wx::WXK_ESCAPE ) {
				Wx::Window::SetFocus( $ep );
			} elsif ($key == &Wx::WXK_UP ) {
				Kephra::Edit::selection_move_up($notepad)
					if $event->ControlDown and $event->AltDown;
			} elsif ($key == &Wx::WXK_DOWN){
				Kephra::Edit::selection_move_down($notepad)
					if $event->ControlDown and $event->AltDown;
			} elsif ($key == &Wx::WXK_F3 ) {
				if ($event->ControlDown) {
					my $sel = $notepad->GetSelectedText;
					$event->ShiftDown
						? Kephra::Edit::Search::set_replace_item($sel)
						: Kephra::Edit::Search::set_find_item($sel);
				}
			} elsif ($key == &Wx::WXK_F5) {
				my ( $sel_beg, $sel_end ) = $notepad->GetSelection;
				Kephra::App::Panel::Output::ensure_visibility();
				my $code = $sel_beg == $sel_end
					? $notepad->GetText
					: $notepad->GetSelectedText;
				my $result;
				my $interpreter = _config->{eval_with};
				if (not defined $interpreter or $interpreter eq 'eval') {
					$result = eval $code;
					$result = $@ if $@;
				} else {
					$result = `$interpreter $code`;
				}
				Kephra::App::Panel::Output::say($result);
			} elsif ($key == &Wx::WXK_F12) {
				Wx::Window::SetFocus( $ep );
				switch_visibility() if $event->ControlDown;
			} elsif ($key == 70 and $event->ControlDown) {# F
				Kephra::CommandList::run_cmd_by_id('view-searchbar-goto');
			}
			$event->Skip;
	});	

	Kephra::EventTable::add_call( 'app.splitter.right.changed',__PACKAGE__,sub {
			if ( get_visibility() and not _splitter()->IsSplit() ) {
				show( 0 );
				return;
			}
			save_size();
	});

	_global_ref($notepad);
	$notepad;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility { show( get_visibility() ^ 1 ) }
sub show {
	my $visibile = shift;
	my $config = _config();
	$visibile = $config->{visible} unless defined $visibile;
	my $win = Kephra::App::Window::_ref();
	my $main_panel = $Kephra::app{panel}{main};
	my $notepad  = _ref();
	my $splitter = _splitter();
	if ($visibile) {
		$splitter->SplitVertically( $main_panel, $notepad );
		$splitter->SetSashPosition( -1*$config->{size}, 1);
	} else {
		$splitter->Unsplit();
		$splitter->Initialize( $main_panel );
	}
	$notepad->Show( $visibile );
	$win->Layout;
	$config->{visible} = $visibile;
	Kephra::EventTable::trigger('panel.notepad.visible');
}

sub note {
	show( 1 );
	Wx::Window::SetFocus( _ref() );
}

sub append {
	my $text = shift;
	return unless defined $text and $text;
	my $np = _ref();
	$text = "\n" . $text if $np->GetLength();
	$np->AppendText( $text );
}

sub append_selection { append( Kephra::Edit::get_selection() ) }

sub save {
	my $file_name = _config()->{content_file};
	if ($file_name) {
		$file_name = Kephra::Config::filepath($file_name);
		if (open my $FH, '>', $file_name) {print $FH _ref()->GetText;}
	}
	save_size();
}

sub save_size {
	my $splitter = _splitter();
	return unless $splitter->IsSplit();
	my $ww=Kephra::App::Window::_ref()->GetSize->GetWidth;
	_config()->{size} = -1*($ww-($ww-$splitter->GetSashPosition));
}


1;
