package Kephra::App::EditPanel;
our $VERSION = '0.14';

use strict;
use warnings; 
#
# internal API to config und app pointer
#
my $ref;
my %mouse_commands;
sub _ref     { $ref }
sub _set_ref { $ref = $_[0] if is($_[0]) }
sub _all_ref { Kephra::Document::Data::get_all_ep() }
sub is       { 1 if ref $_[0] eq 'Wx::StyledTextCtrl'}
sub _config  { Kephra::API::settings()->{editpanel} }
# splitter_pos
sub new {
	my $ep = Wx::StyledTextCtrl->new( Kephra::App::Window::_ref() );
	$ep->DragAcceptFiles(1) if Wx::wxMSW();
	return $ep;
}
sub gets_focus { Wx::Window::SetFocus( _ref() ) if is( _ref() ) }

# general settings
sub apply_settings_here {
	my $ep        = shift || _ref() || _create();
	return unless is($ep);
	my $conf      = _config();

	load_font($ep);

	# indicators: caret, selection, whitespaces...
	Kephra::App::EditPanel::Indicator::apply_all_here($ep);

	# Margins on left side
	Kephra::App::EditPanel::Margin::apply_settings_here($ep);

	#misc: scroll width, codepage, wordchars
	apply_autowrap_settings_here($ep);

	$ep->SetScrollWidth($conf->{scroll_width})
		unless $conf->{scroll_width} eq 'auto';

	#wxSTC_CP_UTF8 Wx::wxUNICODE()
	$ep->SetCodePage(65001);#
	set_word_chars_here($ep);

	# internal
	$ep->SetLayoutCache(&Wx::wxSTC_CACHE_PAGE);
	$ep->SetBufferedDraw(1);
	$conf->{contextmenu}{visible} eq 'default' ? $ep->UsePopUp(1) : $ep->UsePopUp(0);

	Kephra::Edit::eval_newline_sub();
	Kephra::Edit::Marker::define_marker($ep);
	connect_events($ep);
	Kephra::EventTable::add_call ( 'editpanel.focus', 'editpanel', sub {
		Wx::Window::SetFocus( _ref() ) unless $Kephra::temp{dialog}{active};
	}, __PACKAGE__ ) if $conf->{auto}{focus};
	Kephra::EventTable::add_call( 'document.text.change', 'update_edit_pos', sub {
		Kephra::Document::Data::attr('edit_pos', _ref()->GetCurrentPos());
	}, __PACKAGE__);
}

sub connect_events {
	my $ep = shift || _ref();
	my $trigger = \&Kephra::EventTable::trigger;
	my $config = _config();
	my $selection;
	my $rectangular_mode;
	my ($dragpos,$droppos);

	# override sci presets
	Wx::Event::EVT_DROP_FILES       ($ep, \&Kephra::File::add_dropped);
	Wx::Event::EVT_STC_START_DRAG   ($ep, -1, sub {
		my ( $ep, $event) = @_;
		$dragpos = $ep->GetCurrentPos();
		$selection = $ep->GetSelectedText();
		$rectangular_mode = $ep->SelectionIsRectangle();
		$event->Skip;
	});
	Wx::Event::EVT_STC_DRAG_OVER    ($ep, -1, sub { $droppos = $_[1]->GetPosition });
	Wx::Event::EVT_STC_DO_DROP      ($ep, -1, sub {
		my ( $ep, $event) = @_;
		$rectangular_mode
		 ? Kephra::Edit::paste_rectangular($selection, $ep, $dragpos, $droppos)
		 : $event->Skip;
	});

	Wx::Event::EVT_ENTER_WINDOW     ($ep,     sub { &$trigger('editpanel.focus')} );
	Wx::Event::EVT_LEFT_DOWN        ($ep,     sub { 
		my ($ep, $event) = @_;
		my $nr = Kephra::App::EditPanel::Margin::in_nr( $event->GetX, $ep );
		if ($nr == -1) { Kephra::Edit::copy() if clicked_on_selection($event) }
		else { Kephra::App::EditPanel::Margin::on_left_click($ep, $event, $nr) } 

		$event->Skip;
	});
	Wx::Event::EVT_MIDDLE_DOWN      ($ep,     sub {
		my ($ep, $event) = @_;
		my $nr = Kephra::App::EditPanel::Margin::in_nr( $event->GetX, $ep );
		# click is above text area
		if ($nr == -1) {
			if ($event->LeftIsDown){
				Kephra::Edit::paste();
				set_caret_on_cursor($event);
			}
			# just middle clicked
			else {
				if ($ep->GetSelectedText){
					if (clicked_on_selection($event, $ep)) {
						Kephra::Edit::Search::set_selection_as_find_item();
						Kephra::Edit::Search::find_next();
					} 
					else { insert_selection_at_cursor($event, $ep) }
				} 
				else { Kephra::Edit::Goto::last_edit() }
			}
		} 
		else { Kephra::App::EditPanel::Margin::on_middle_click($ep, $event, $nr) }
	});
	Wx::Event::EVT_RIGHT_DOWN       ($ep,     sub {
		my ($ep, $event) = @_;
		my $nr = Kephra::App::EditPanel::Margin::in_nr( $event->GetX, $ep );
		if ($nr == -1) {
			if ($event->LeftIsDown){
				Kephra::Edit::_selection_left_to_right($ep)
					? Kephra::Edit::cut()
					: Kephra::Edit::clear();
				set_caret_on_cursor($event);
			} else {
				my $mconf = $config->{contextmenu};
				if ($mconf->{visible} eq 'custom'){
					my $menu_id = $ep->GetSelectedText
						? $mconf->{ID_selection} : $mconf->{ID_normal};
					my $menu = Kephra::App::ContextMenu::get($menu_id);
					$ep->PopupMenu($menu, $event->GetX, $event->GetY) if $menu;
				}
			} 
		} else {Kephra::App::EditPanel::Margin::on_right_click($ep, $event, $nr)}
	});
	#Wx::EVT_SET_FOCUS               ($ep,     sub {});
	Wx::Event::EVT_STC_SAVEPOINTREACHED($ep, -1, \&Kephra::File::savepoint_reached);
	Wx::Event::EVT_STC_SAVEPOINTLEFT($ep, -1, \&Kephra::File::savepoint_left);
	# -DEP
	#Wx::Event::EVT_STC_MARGINCLICK  ($ep, -1, \&Kephra::App::EditPanel::Margin::on_left_click);
	Wx::Event::EVT_STC_CHANGE       ($ep, -1, sub {&$trigger('document.text.change')} );
	Wx::Event::EVT_STC_UPDATEUI     ($ep, -1, sub {
		my ( $ep, $event) = @_;
		my ( $sel_beg, $sel_end ) = $ep->GetSelection;
		my $is_sel = $sel_beg != $sel_end;
		my $was_sel = Kephra::Document::Data::attr('text_selected');
		Kephra::Document::Data::attr('text_selected', $is_sel);
		&$trigger('document.text.select') if $is_sel xor $was_sel;
		&$trigger('caret.move');
	});

	Wx::Event::EVT_KEY_DOWN         ($ep,     sub {
		my ($ep, $event) = @_;
		#$ep = _ref(); 
		my $key = $event->GetKeyCode +
			1000 * ($event->ShiftDown + $event->ControlDown*2 + $event->AltDown*4);
		# reacting on shortkeys that are defined in the Commanlist
		#print "$key\n";
		return if Kephra::CommandList::run_cmd_by_keycode($key);
		# reacting on Enter
		if ($key ==  &Wx::WXK_RETURN) {
			if ($config->{auto}{brace}{indention}) {
				my $pos  = $ep->GetCurrentPos - 1;
				my $char = $ep->GetCharAt($pos);
				if      ($char == 123) {
					return Kephra::Edit::Format::blockindent_open($pos);
				} elsif ($char == 125) {
					return Kephra::Edit::Format::blockindent_close($pos);
				}
			}
			$config->{auto}{indention}
				? Kephra::Edit::Format::autoindent()
				: $ep->CmdKeyExecute(&Wx::wxSTC_CMD_NEWLINE) ;
		}
		# scintilla handles the rest of the shortkeys
		else { $event->Skip }
		#SCI_SETSELECTIONMODE
		#($key == 350){use Kephra::Ext::Perl::Syntax; Kephra::Ext::Perl::Syntax::check()};
	});
}
sub create_mouse_binding {
	my @cmd = qw(left-middle left-right left-selection 
	             middle middle-selected middle-selection
	);

	if (_config()->{control}{use_mouse_function}) {
		my $config = _config()->{control}{mouse_function};
		$mouse_commands{$_} = Kephra::Macro::create_from_cmd_list($config->{$_})
				for @cmd
	}
	else { $mouse_commands{$_} = sub {} for @cmd }
}
sub set_caret_on_cursor {
	my $event = shift;
	my $ep = shift || _ref();
	return unless ref $event eq 'Wx::MouseEvent' and is($ep);
	my $pos = cursor_2_caret_pos($event, $ep);
	$pos = $ep->GetCurrentPos() if $pos == -1;
	$ep->SetSelection( $pos, $pos );
}
sub clicked_on_selection {
	my $event = shift;
	my $ep = shift || _ref();
	return unless ref $event eq 'Wx::MouseEvent' and is($ep);
	my ($start, $end) = $ep->GetSelection();
	my $pos = cursor_2_caret_pos($event, $ep);
	return 1 if $start != $end and $pos >= $start and $pos <= $end;
}
sub insert_selection_at_cursor {
	my $event = shift;
	my $ep = shift || _ref();
	my $pos = cursor_2_caret_pos($event, $ep);
	Kephra::Edit::insert_text($ep->GetSelectedText(), $pos) if $pos > -1;
}
sub cursor_2_caret_pos {
	my $event = shift;
	my $ep = shift || _ref();
	return -1 unless ref $event eq 'Wx::MouseEvent' and is($ep);
	my $pos = $ep->PositionFromPointClose($event->GetX, $event->GetY);
	if ($pos == -1) {
		my $width = Kephra::App::EditPanel::Margin::width($ep)
		          + Kephra::App::EditPanel::Margin::get_text_width();
		my $y = $event->GetY;
		my $line = $ep->LineFromPosition( $ep->PositionFromPointClose($width, $y) );
		$pos = $ep->GetLineEndPosition ($line);
		my $font_size = _config()->{font}{size};
		if ($line == 0 and $y > $font_size + 12) {
			my $lcc = 0;
			$pos = $ep->PositionFromPointClose($width-1, $y);
			while ($pos == -1 and $lcc < $ep->GetLineCount() ){
				$lcc++; # line counter
				$y += $font_size;
				$pos = $ep->PositionFromPointClose($width, $y);
			}
			return -1 if $pos == -1;
			return $ep->PositionFromLine(  $ep->LineFromPosition($pos) - $lcc );
		}
	}
	$pos;
}

sub disconnect_events {
	my $ep = shift || _ref();
	Wx::Event::EVT_STC_CHANGE  ($ep, -1, sub {});
	Wx::Event::EVT_STC_UPDATEUI($ep, -1, sub {});
}

sub set_contextmenu_custom  { set_contextmenu('custom') }
sub set_contextmenu_default { set_contextmenu('default')}
sub set_contextmenu_none    { set_contextmenu('none')   }
sub set_contextmenu {
	my $mode = shift;
	$mode = 'custom' unless $mode;
	my $ep = _ref();
	$mode eq 'default' ? $ep->UsePopUp(1) : $ep->UsePopUp(0);
	_config()->{contextmenu}{visible} = $mode;
}
sub get_contextmenu { _config()->{contextmenu}{visible} }
#
sub set_word_chars { set_word_chars_here($_) for @{_all_ref()} }
sub set_word_chars_here { 
	my $ep = shift || _ref();
	my $conf = _config();
	if ( $conf->{word_chars} ) {
		$ep->SetWordChars( $conf->{word_chars} );
	} else {
		$ep->SetWordChars( '$%&-@_abcdefghijklmnopqrstuvwxyzäöüßABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ0123456789' );
	}
}


# line wrap
sub apply_autowrap_settings { apply_autowrap_settings_here($_) for @{_all_ref()} }
sub apply_autowrap_settings_here {
	my $ep = shift || _ref();
	$ep->SetWrapMode( _config()->{line_wrap} );
	Kephra::EventTable::trigger('editpanel.autowrap');
}

sub get_autowrap_mode { _config()->{line_wrap} == &Wx::wxSTC_WRAP_WORD}
sub switch_autowrap_mode {
	_config()->{line_wrap} = get_autowrap_mode()
		? &Wx::wxSTC_WRAP_NONE
		: &Wx::wxSTC_WRAP_WORD;
	apply_autowrap_settings();
}

# font settings
sub load_font {
	my $ep = shift || _ref();
	my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
	my $font = _config()->{font};
	$fontweight = &Wx::wxLIGHT  if $font->{weight} eq 'light';
	$fontweight = &Wx::wxBOLD   if $font->{weight} eq 'bold';
	$fontstyle  = &Wx::wxSLANT  if $font->{style}  eq 'slant';
	$fontstyle  = &Wx::wxITALIC if $font->{style}  eq 'italic';
	my $wx_font = Wx::Font->new( $font->{size}, &Wx::wxDEFAULT, 
		$fontstyle, $fontweight, 0, $font->{family} );
	$ep->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}
sub change_font {
	my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
	my $font_config = _config()->{font};
	$fontweight = &Wx::wxLIGHT  if ( $$font_config{weight} eq 'light' );
	$fontweight = &Wx::wxBOLD   if ( $$font_config{weight} eq 'bold' );
	$fontstyle  = &Wx::wxSLANT  if ( $$font_config{style}  eq 'slant' );
	$fontstyle  = &Wx::wxITALIC if ( $$font_config{style}  eq 'italic' );
	my $oldfont = Wx::Font->new( $$font_config{size}, &Wx::wxDEFAULT, $fontstyle,
		$fontweight, 0, $$font_config{family} );
	my $newfont = Kephra::Dialog::get_font( $oldfont );

	if ( $newfont->Ok > 0 ) {
		($fontweight, $fontstyle) = ($newfont->GetWeight, $newfont->GetStyle);
		$$font_config{size}   = $newfont->GetPointSize;
		$$font_config{family} = $newfont->GetFaceName;
		$$font_config{weight} = 'normal';
		$$font_config{weight} = 'light' if $fontweight == &Wx::wxLIGHT;
		$$font_config{weight} = 'bold' if $fontweight == &Wx::wxBOLD;
		$$font_config{style}  = 'normal';
		$$font_config{style}  = 'slant' if $fontstyle == &Wx::wxSLANT;
		$$font_config{style}  = 'italic' if $fontstyle == &Wx::wxITALIC;
		Kephra::Document::SyntaxMode::reload($_) for @{Kephra::Document::Data::all_nr()};
		Kephra::App::EditPanel::Margin::apply_line_number_width();
	}
}
#
sub zoom_in {
	my $ep = shift || _ref();
	$ep->SetZoom( $ep->GetZoom()+1 ) if $ep->GetZoom() < 45;
}
sub zoom_out {
	my $ep = shift || _ref();
	$ep->SetZoom( $ep->GetZoom()-1 ) if $ep->GetZoom() > -10;
}
sub zoom_normal {
	my $ep = shift || _ref();
	$ep->SetZoom( 0 ) ;
}
#
# auto indention
sub get_autoindention { Kephra::App::EditPanel::_config()->{auto}{indention} }
sub set_autoindention {
	Kephra::App::EditPanel::_config()->{auto}{indention} = shift;
	Kephra::Edit::eval_newline_sub();
}
sub switch_autoindention { set_autoindention( get_autoindention() ^ 1 ) } 
sub set_autoindent_on    { set_autoindention( 1 ) }
sub set_autoindent_off   { set_autoindention( 0 ) }
#
# brace indention
sub get_braceindention { Kephra::App::EditPanel::_config()->{auto}{brace}{indention}}
sub set_braceindention {
	Kephra::App::EditPanel::_config()->{auto}{brace}{indention} = shift;
	Kephra::Edit::eval_newline_sub();
}
sub switch_braceindention { set_braceindention( get_braceindention() ^ 1 ) }
sub set_braceindent_on    { set_braceindention( 1 ) }
sub set_braceindent_off   { set_braceindention( 0 ) }
#
#
sub get_bracecompletion { Kephra::App::EditPanel::_config()->{auto}{brace}{make} }
sub set_bracecompletion {
	Kephra::App::EditPanel::_config()->{auto}{brace}{make} = shift;
}
sub switch_bracecompletion{  set_bracecompletion( get_bracecompletion() ^ 1 ) }
1;
#EVT_STC_CHARADDED EVT_STC_MODIFIED
#wxSTC_CP_UTF8 wxSTC_CP_UTF16 Wx::wxUNICODE()
#wxSTC_WS_INVISIBLE wxSTC_WS_VISIBLEALWAYS
#$ep->StyleSetForeground (wxSTC_STYLE_CONTROLCHAR, Wx::Colour->new(0x55, 0x55, 0x55));
#$ep->CallTipShow(3,"testtooltip\n next line"); #tips
#SetSelectionMode(wxSTC_SEL_RECTANGLE);
