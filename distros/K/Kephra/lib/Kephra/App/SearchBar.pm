package Kephra::App::SearchBar;
our $VERSION = '0.15';

use strict;
use warnings;

sub _ID            { 'searchbar' }
sub _ref           { Kephra::ToolBar::_ref( _ID(), $_[0]) }
sub _config        { Kephra::API::settings()->{app}{ _ID() } }
sub _search_config { Kephra::API::settings()->{search} }
my $highlight_search; # set 1 if searchbar turns red
#
sub create {
	# load searchbar definition
	my $bar_def = Kephra::Config::File::load_from_node_data( _config() );
	unless ($bar_def) {
		$bar_def = Kephra::Config::Tree::get_subtree
			( Kephra::Config::Default::toolbars(), _ID() );
	}

	# create searchbar with buttons
	my $rest_widgets = Kephra::ToolBar::create_new( _ID(), $bar_def);
	my $bar = _ref();
	# apply special searchbar widgets
	for my $item_data (@$rest_widgets){
		my $ctrl;
		if ($item_data->{type} eq 'combobox' and $item_data->{id} eq 'find'){
			my $find_input = $bar->{find_input} = Wx::ComboBox->new (
				$bar , -1, '', [-1,-1], [$item_data->{size},-1], [],
				&Wx::wxTE_PROCESS_ENTER
			);
			$find_input->SetDropTarget
				( Kephra::Edit::Search::InputTarget->new($find_input, 'find'));
			$find_input->SetValue( Kephra::Edit::Search::get_find_item() );
			$find_input->SetSize($item_data->{size},-1) if $item_data->{size};
			if ( _search_config()->{history}{use} ){
				$find_input->Append($_) for @{ Kephra::Edit::Search::get_find_history() }
			}

			Wx::Event::EVT_TEXT( $bar, $find_input, sub {
				my ($bar, $event) = @_;
				my $old = Kephra::Edit::Search::get_find_item();
				my $new = $find_input->GetValue;
				if ($new ne $old){
					Kephra::Edit::Search::set_find_item( $new );
					Kephra::Edit::Search::first_increment()
						if _search_config()->{attribute}{incremental}
						and Wx::Window::FindFocus() eq $find_input;
				}
			} );
			Wx::Event::EVT_KEY_DOWN( $find_input, sub {
				my ( $fi, $event ) = @_;
				my $key = $event->GetKeyCode;
				my $found_something;
				my $ep = Kephra::App::EditPanel::_ref();
				if      ( $key == &Wx::WXK_RETURN ) {
					if    ($event->ControlDown and $event->ShiftDown)   
					                           {Kephra::Edit::Search::find_last() }
					elsif ($event->ControlDown){Kephra::Edit::Search::find_first()}
					elsif ($event->ShiftDown)  {Kephra::Edit::Search::find_prev() }
					else                       {Kephra::Edit::Search::find_next() }
				} elsif ($key == &Wx::WXK_F3){
					$event->ShiftDown 
						? Kephra::Edit::Search::find_prev()
						: Kephra::Edit::Search::find_next();
				} elsif ($key == &Wx::WXK_ESCAPE) {
					give_editpanel_focus_back(); switch_visibility();
				} elsif ($key == 65 and $event->ControlDown) {# A
					$bar->{find_input}->SetSelection
						(0, $bar->{find_input}->GetLastPosition);
				} elsif ($key == 70 and $event->ControlDown) {# F
					give_editpanel_focus_back()
				} elsif ( $key == 71 ) { # G
					if ($event->ControlDown and $event->ShiftDown){
						give_editpanel_focus_back();
						Kephra::Edit::Goto::last_edit();
					}
				} elsif ($key == 81) { # Q
					switch_visibility() if $event->ControlDown;
				#} elsif ( $key == &Wx::WXK_LEFT ){ &Wx::wxSTC_CMD_CHARLEFT return
				#} elsif ($key == &Wx::WXK_RIGHT ){ &Wx::wxSTC_CMD_CHARRIGHT return;
				} elsif ($key == &Wx::WXK_UP){
					if ($event->ControlDown) {
						$ep->CmdKeyExecute( &Wx::wxSTC_CMD_LINESCROLLUP ); return;
					}
				} elsif ($key == &Wx::WXK_DOWN) {
					if ($event->ControlDown) {
						$ep->CmdKeyExecute( &Wx::wxSTC_CMD_LINESCROLLDOWN ); return;
					}
				} elsif ($key == &Wx::WXK_PAGEUP) {
					if ($event->ControlDown) {
						my $pos = $bar->{find_input}->GetInsertionPoint;
						Kephra::Document::Change::tab_left();
						Wx::Window::SetFocus($bar->{find_input});
						$bar->{find_input}->SetInsertionPoint($pos);
					} else {
						$ep->CmdKeyExecute( &Wx::wxSTC_CMD_PAGEUP );
					}
					return;
				} elsif ($key == &Wx::WXK_PAGEDOWN){
					if ($event->ControlDown) {
						my $pos = $bar->{find_input}->GetInsertionPoint;
						Kephra::Document::Change::tab_right();
						Wx::Window::SetFocus($bar->{find_input});
						$bar->{find_input}->SetInsertionPoint($pos);
					} else {
						$ep->CmdKeyExecute( &Wx::wxSTC_CMD_PAGEDOWN );
					}
					return;
				} elsif ($key == &Wx::WXK_HOME and $event->ControlDown) {
					$ep->CmdKeyExecute( &Wx::wxSTC_CMD_DOCUMENTSTART ); return;
				} elsif ($key == &Wx::WXK_END and $event->ControlDown) {
					$ep->CmdKeyExecute( &Wx::wxSTC_CMD_DOCUMENTEND ); return;
				} elsif ($key == &Wx::WXK_BACK and $event->ControlDown and $event->ShiftDown) {
					my $pos = $bar->{find_input}->GetInsertionPoint;
					Kephra::Document::Change::switch_back();
					Wx::Window::SetFocus($bar->{find_input});
					$bar->{find_input}->SetInsertionPoint($pos);
				} else  {
					#print "$key\n"
				}
				$event->Skip;
			} );
			#Wx::Event::EVT_COMBOBOX( $find_input, -1, sub{ } );
			Wx::Event::EVT_ENTER_WINDOW( $find_input, sub {
				Wx::Window::SetFocus($find_input) if _config()->{autofocus};
				disconnect_find_input();
			});
			Wx::Event::EVT_LEAVE_WINDOW( $find_input,sub{connect_find_input($find_input) });
			connect_find_input($find_input);
			$highlight_search = 1;
			$ctrl = $find_input;
		}
		elsif ($item_data->{type} eq 'combobox' and $item_data->{id} eq 'replace'){
			my $replace_input = $bar->{replace_input} = Wx::ComboBox->new (
				$bar , -1, '', [-1,-1], [$item_data->{size},-1], [],
				&Wx::wxTE_PROCESS_ENTER
			);
			$replace_input->SetDropTarget
				( Kephra::Edit::Search::InputTarget->new($replace_input, 'replace'));
			$replace_input->SetValue( Kephra::Edit::Search::get_replace_item() );
			$replace_input->SetSize($item_data->{size},-1) if $item_data->{size};
			if ( _search_config()->{history}{use} ){
				$replace_input->Append($_) for @{ Kephra::Edit::Search::get_replace_history() }
			}
			$ctrl = $replace_input;
		}
		if (ref $ctrl) {
			$bar->InsertControl( $item_data->{pos}, $ctrl );
		}
	}

	Wx::Event::EVT_MIDDLE_DOWN( $bar,  sub {
		my ($widget, $event) = @_;
		my $ep = Kephra::App::EditPanel::_ref();
		if ($ep->GetSelectedText){
			Kephra::Edit::Search::set_selection_as_find_item();
			Kephra::Edit::Search::find_next();
		} else {
			Kephra::Edit::Goto::last_edit();
		}
	} );
	Wx::Event::EVT_RIGHT_DOWN ( $bar,  sub {
		return unless get_contextmenu_visibility();
		my ($widget, $event) = @_;
		my ($x, $y) = ($event->GetX, $event->GetY);
		my $menu = Kephra::App::ContextMenu::get(_config()->{contextmenu});
		$bar->PopupMenu($menu, $x, $y) if Kephra::Menu::is($menu);
	} );
	Wx::Event::EVT_LEAVE_WINDOW($bar, \&leave_focus);
	$bar->Realize;
	$bar;
}


sub destroy{ Kephra::ToolBar::destroy ( _ID() ) }
#
sub connect_find_input {
	my $find_input = shift;
	my $ID = _ID();
	my $add_call = \&Kephra::EventTable::add_call;
	&$add_call( 'find.item.changed', $ID.'_input_refresh', sub {
			my $value = Kephra::Edit::Search::get_find_item();
			return if $value eq $find_input->GetValue;
			$find_input->SetValue( $value );
			my $pos = $find_input->GetLastPosition;
			$find_input->SetSelection($pos,$pos);
	}, $ID);
	&$add_call( 'find.item.history.changed', $ID.'_popupmenu', sub {
			$find_input->Clear();
			$find_input->Append($_) for @{ Kephra::Edit::Search::get_find_history() };
			$find_input->SetValue( Kephra::Edit::Search::get_find_item() );
			$find_input->SetInsertionPointEnd;
	}, $ID);
	&$add_call( 'find', $ID.'_color_refresh', \&colour_find_input, $ID);
}
sub disconnect_find_input{ Kephra::EventTable::del_own_subscriptions(_ID()) }
#
sub colour_find_input {
	my $find_input      = _ref()->{find_input};
	my $found_something = Kephra::Edit::Search::_find_pos() > -1
		? 1 : 0;
	return if $highlight_search eq $found_something;
	$highlight_search = $found_something;
	if ($found_something){
		$find_input->SetForegroundColour( Wx::Colour->new( 0x00, 0x00, 0x55 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	} else {
		$find_input->SetForegroundColour( Wx::Colour->new( 0xff, 0x33, 0x33 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	}
	$find_input->Refresh;
}

sub enter_focus {
	my $bar = _ref();
	switch_visibility() unless get_visibility();
	Wx::Window::SetFocus($bar->{find_input}) if defined $bar->{find_input};
}
sub leave_focus { switch_visibility() if _config()->{autohide} }
#
sub give_editpanel_focus_back{
	leave_focus();
	Wx::Window::SetFocus( Kephra::App::EditPanel::_ref() );
}

sub position { _config()->{position} }
#
# set visibility
sub show {
	my $visible = shift || get_visibility();
	my $bar = _ref();
	return unless $bar;
	my $sizer = $bar->GetParent->GetSizer;
	$sizer->Show( $bar, $visible );
	$sizer->Layout();
	_config()->{visible} = $visible;
}
sub get_visibility    { _config()->{visible} }
sub switch_visibility { _config()->{visible} ^= 1; show(); }

sub get_contextmenu_visibility    { _config()->{contextmenu_visible} }
sub switch_contextmenu_visibility { _config()->{contextmenu_visible} ^= 1 }

1;