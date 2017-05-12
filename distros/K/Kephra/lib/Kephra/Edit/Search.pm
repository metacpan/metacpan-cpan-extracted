package Kephra::Edit::Search;
our $VERSION = '0.31';

use strict;
use warnings;

# internal and menu functions about find and replace text
# drag n drop target class

# internal functions
my ($find_item, $found_pos, $old_pos, $replace_item);
my $flags;
my $history_refresh;
my @find_history;
my @replace_history;
sub _config    { Kephra::API::settings()->{search} }
sub _attributes{ _config()->{attribute} }
sub _history   { _config()->{history}   }
sub _find_pos  { $found_pos }

sub _refresh_search_flags {
	my $attr = _attributes();
	$flags = 0;

	$flags |= &Wx::wxSTC_FIND_MATCHCASE
		if defined $attr->{match_case} and $attr->{match_case};
	if ( defined $attr->{match_whole_word} and $attr->{match_whole_word} ) {
		$flags |= &Wx::wxSTC_FIND_WHOLEWORD
	} else {
		$flags |= &Wx::wxSTC_FIND_WORDSTART
			if $attr->{match_word_begin} and $attr->{match_word_begin};
	}
	$flags |= &Wx::wxSTC_FIND_REGEXP
		if defined $attr->{match_regex} and $attr->{match_regex};
}


sub load_search_data {
	my $file = Kephra::Config::filepath( _config()->{data_file} );
	my $config_tree = Kephra::Config::File::load($file);

	set_find_item( $config_tree->{find}{item}  || '' );
	set_replace_item( $config_tree->{replace}{item}  || '' );
	if (defined $config_tree->{find}{history}){
		if (ref $config_tree->{find}{history} eq 'ARRAY'){
				 @find_history = @{ $config_tree->{find}{history} };
		} else { $find_history[0] = $config_tree->{find}{history} }
	}
	if (defined $config_tree->{replace}{history}){
		if (ref $config_tree->{replace}{history} eq 'ARRAY'){
				 @replace_history = @{ $config_tree->{replace}{history} };
		} else { $replace_history[0] = $config_tree->{replace}{history} }
	}
	my $history = _history();

	# remove dups and cut to the configured length
	if ( $history->{use} ) {
		my ( %seen1, %seen2 );
		my @uniq = grep { !$seen1{$_}++ } @find_history;
		@find_history = splice @uniq, 0, $history->{length};
		@uniq = grep { !$seen2{$_}++ } @replace_history;
		@replace_history = splice @uniq, 0, $history->{length};
	} else {
		@find_history    = ();
		@replace_history = ();
	}
	# search item is findable
	$found_pos = 0;
	Kephra::EventTable::trigger
		('find.item.history.changed', 'replace.item.history.changed');
	Kephra::Edit::Marker::restore_bookmarks( $config_tree->{bookmark} );
}

sub save_search_data {
	my $file = Kephra::Config::filepath( _config()->{data_file} );
	my $config_tree = Kephra::Config::File::load($file);
	$config_tree->{find}{item}       = get_find_item();
	$config_tree->{find}{history}    = get_find_history();
	$config_tree->{replace}{item}    = get_replace_item();
	$config_tree->{replace}{history} = get_replace_history();
	$config_tree->{bookmark}         = Kephra::Edit::Marker::get_bookmark_data();
	Kephra::Config::File::store($file, $config_tree);
	Kephra::Edit::Marker::store();
}
#
sub get_find_item { $find_item  || ''}
sub set_find_item {
	my $old = $find_item;
	my $new = shift;
	if (defined $new and (not defined $old or $new ne $old)){
		$find_item = $new;
		$found_pos = -1;
		Kephra::EventTable::trigger('find.item.changed');
	}
}

sub set_selection_as_find_item {
	set_find_item( Kephra::App::EditPanel::_ref()->GetSelectedText )
}

sub item_findable       { _exist_find_item() }
sub _exist_find_item    { (defined $find_item and $find_item) ? 1 : 0 }
sub _exist_replace_item { (defined $replace_item and $replace_item) ? 1 : 0 }

sub get_replace_item { $replace_item || ''}
sub set_replace_item {
	my $old = $replace_item;
	my $new = shift;
	if (defined $new and (not defined $old or $new ne $old)){
		$replace_item = $new;
		Kephra::EventTable::trigger('replace.item.changed');
	}
}

sub set_selection_as_replace_item {
	set_replace_item( Kephra::App::EditPanel::_ref()->GetSelectedText )
}
sub get_find_history    { \@find_history    }
sub get_replace_history { \@replace_history }
sub refresh_find_history {
	my $found_match = shift;
	my $find_item   = get_find_item();
	my $history     = _history();
	return unless $history->{use};
	# check if refresh needed
	return if $history->{remember_only_matched} and not $found_match;

	if ($find_item and $find_history[0] ne $find_item) {
		for ( 0 .. $#find_history ) {      # delete the dup
			if ( $find_history[$_] eq $find_item ) {
				@find_history = @find_history[ 0 .. $_-1, $_+1 .. $#find_history ];
				last;
			}
			pop @find_history if $_ == $history->{length} - 1;
		}
		unshift @find_history, $find_item; # insert new history item
		Kephra::EventTable::trigger('find.item.history.changed');
	}
}
sub refresh_replace_history {
	my $replace_item = get_replace_item();
	my $history      = _history();

	if ($replace_item) {
		for ( 0 .. $#replace_history ) {
			if ( $replace_history[$_] eq $replace_item ) {
				@replace_history = @replace_history[ 0 .. $_-1, $_+1 .. $#replace_history ];
				last;
			}
			pop @replace_history if $_ == $history->{length} - 1;
		}
		unshift @replace_history, $replace_item;
		Kephra::EventTable::trigger('replace.item.history.changed');
	}
}

sub _caret_2_sel_end {
	my $ep = Kephra::App::EditPanel::_ref();
	my $pos       = $ep->GetCurrentPos;
	my $sel_start = $ep->GetSelectionStart;
	my $sel_end   = $ep->GetSelectionEnd;
	if ( $pos != $sel_end ) {
		$ep->SetCurrentPos($sel_end);
		$ep->SetSelectionStart($sel_start);
	}
}

#
sub set_range{ _attributes()->{in} = shift }
sub get_range{ _attributes()->{in}         }

sub get_attribute{
	my $attr = shift;
	if ($attr eq 'match_case'      or 
		$attr eq 'match_word_begin'or
		$attr eq 'match_whole_word'or
		$attr eq 'match_regex'     or
		$attr eq 'auto_wrap'       or
		$attr eq 'incremental'       ) {
		_attributes()->{$attr}
	}
}

sub switch_attribute{
	my $attr = shift;
	if ($attr eq 'match_case'      or 
		$attr eq 'match_word_begin'or
		$attr eq 'match_whole_word'or
		$attr eq 'match_regex'     or
		$attr eq 'auto_wrap'       or
		$attr eq 'incremental'       ) {
		unless (defined _attributes->{$attr}) 
			 { _attributes->{$attr}  = 1 }
		else { _attributes->{$attr} ^= 1 }
		_refresh_search_flags() if substr($attr, 0, 1) eq 'm';
	}
}

# find helper function
sub replace_selection  {
	Kephra::App::EditPanel::_ref()->ReplaceSelection( get_replace_item() )
}

sub _find_next  {
	my $ep = Kephra::App::EditPanel::_ref();
	$ep->SearchAnchor;
	$found_pos = $ep->SearchNext( $flags, get_find_item() );
	Kephra::EventTable::trigger('find');
	return $found_pos;
}

sub _find_prev {
	my $ep = Kephra::App::EditPanel::_ref();
	$ep->SearchAnchor;
	$found_pos = $ep->SearchPrev( $flags, get_find_item() );
	Kephra::EventTable::trigger('find');
	return $found_pos;
}

sub _find_first {
	Kephra::Edit::Goto::_pos(0);
	_find_next();
}

sub _find_last  {
	Kephra::Edit::Goto::_pos(-1);
	_find_prev();
}


sub first_increment {
	my $ep = Kephra::App::EditPanel::_ref();
	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions;
		if ( _find_first() > -1 ) {
			#_caret_2_sel_end();
			Kephra::Edit::_center_caret;
			return 1;
		}
	}
	Kephra::Edit::Goto::_pos( $old_pos ) if defined $old_pos;
	return 0;
}

#sub next_increment {}
# find related menu calls
sub find_all {
#Kephra::Dialog::msg_box(&Wx::wxUNICODE(), '');
	my $ep = Kephra::App::EditPanel::_ref();
	if ( _exist_find_item() ) {
		my $search_result = _find_first();
		my ($sel_start, $sel_end);
		#Kephra::Dialog::msg_box( , '');
		#$ep->IndicatorSetStyle(0, &Wx::wxSTC_INDIC_TT );
		#$ep->IndicatorSetForeground(0, &Wx::Colour->new(0xff, 0x00, 0x00));
		$ep->IndicatorSetStyle(1, &Wx::wxSTC_INDIC_TT );
		$ep->IndicatorSetForeground(1, &Wx::Colour->new(0xff, 0x00, 0x00));
		# ^= &Wx::wxSTC_INDIC_STRIKE;
		$ep->SetSelection(0,0);
		return 0 if $search_result == -1;
		while ($search_result > -1){
			($sel_start, $sel_end) = $ep->GetSelection;
			Kephra::Edit::Goto::_pos( $sel_end );
			$ep->StartStyling($sel_start, 224);#224
			$ep->SetStyleBytes($sel_end - $sel_start, 128);
			$search_result = _find_next();
		}
		Kephra::Edit::Goto::_pos( $sel_end );
		$ep->Colourise( 0, $sel_end);
		return 1;
	} else {
		Kephra::Edit::Goto::_pos( $old_pos ) if defined $old_pos;
		return 1;
	}
}

sub find_prev {
	my $ep    = Kephra::App::EditPanel::_ref();
	my $attr  = _attributes();
	my $return = -1;
	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions;
		Kephra::Edit::Goto::_pos( $ep->GetSelectionStart - 1 );
		$return = _find_prev();
		if ( $return == -1 ) {
			if ( get_range() eq 'document' ) {
				$return = _find_last() if $attr->{auto_wrap};
			} elsif ( get_range() eq 'open_docs' ) {
				$Kephra::temp{dialog}{control} = 1;
				my $begin_doc = Kephra::Document::Data::current_nr();
				while ( $return == -1 ) {
					Kephra::Edit::_restore_positions;
					last if ( ( Kephra::Document::Data::current_nr() == 0 )
						 and !$attr->{auto_wrap} );
					Kephra::Document::Change::tab_left();
					Kephra::Edit::_save_positions();
					$return = _find_last();
					last
						if ( Kephra::Document::Data::current_nr() == $begin_doc );
				}
				$Kephra::temp{dialog}{control} = 0;
			}
		}
		if ( $return == -1 ) { Kephra::Edit::_restore_positions() }
		else { _caret_2_sel_end(); Kephra::Edit::_center_caret() }
		refresh_find_history($return);
	}
	$return;
}

sub find_next {
	my $ep   = Kephra::App::EditPanel::_ref();
	my $attr =  _attributes();
	my $return = -1;

	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions();
		Kephra::Edit::Goto::_pos( $ep->GetSelectionEnd );
		$return = _find_next();
		if ( $return == -1 ) {
			if ( get_range() eq 'document' ) {
				$return = _find_first() if $attr->{auto_wrap};
			} elsif ( get_range() eq 'open_docs' ) {
				$Kephra::temp{dialog}{control} = 1;
				my $begin_doc = Kephra::Document::Data::current_nr();
				while ( $return == -1 ) {
					Kephra::Edit::_restore_positions();
					last if Kephra::Document::Data::current_nr()
							== Kephra::Document::Data::last_nr()
						 and not $attr->{auto_wrap};
					Kephra::Document::Change::tab_right();
					Kephra::Edit::_save_positions();
					$return = _find_first();
					last if ( Kephra::Document::Data::current_nr() == $begin_doc );
				}
				$Kephra::temp{dialog}{control} = 0;
			}
		}
		if ( $return == -1 ) { Kephra::Edit::_restore_positions() }
		else { _caret_2_sel_end(); Kephra::Edit::_center_caret(); }
		refresh_find_history($return);
	}
	$return;
}

sub fast_back {
	my $ep   = Kephra::App::EditPanel::_ref();
	my $attr = _attributes();
	my $return    = -1;
	if (_exist_find_item()) {
		for ( 1 .. $attr->{fast_steps} ) {
			Kephra::Edit::_save_positions();
			Kephra::Edit::Goto::_pos( $ep->GetSelectionStart - 1 );
			$return = _find_prev();
			if ( $return == -1 ) {
				if ( get_range() eq 'document' ) {
					$return = _find_last() if $attr->{auto_wrap};
				} elsif ( get_range() eq 'open_docs' ) {
					$Kephra::temp{dialog}{control} = 1;
					my $begin_doc = Kephra::Document::Data::current_nr();
					while ( $return == -1 ) {
						Kephra::Edit::_restore_positions();
						last if Kephra::Document::Data::current_nr() == 0
							and not $attr->{auto_wrap};
						Kephra::Document::Change::tab_left();
						Kephra::Edit::_save_positions();
						$return = _find_last();
						last if Kephra::Document::Data::current_nr() == $begin_doc;
					}
					$Kephra::temp{dialog}{control} = 0;
				}
			}
			refresh_find_history($return) if ( $_ == 1 );
			if ( $return == -1 ) { Kephra::Edit::_restore_positions(); last; }
			else { _caret_2_sel_end(); Kephra::Edit::_center_caret(); }
		}
	}
}

sub fast_fore {
	my $ep   = Kephra::App::EditPanel::_ref();
	my $attr = _attributes();
	my $return    = -1;
	if (_exist_find_item()) {
		for ( 1 .. $attr->{fast_steps} ) {
			Kephra::Edit::_save_positions();
			Kephra::Edit::Goto::_pos( $ep->GetSelectionEnd );
			$return = _find_next();
			if ( $return == -1 ) {
				if ( get_range() eq 'document' ) {
					$return = _find_first() if $attr->{auto_wrap};
				} elsif ( get_range() eq 'open_docs' ) {
					$Kephra::temp{dialog}{control} = 1;
					my $begin_doc = Kephra::Document::Data::current_nr();
					while ( $return == -1 ) {
						Kephra::Edit::_restore_positions();
						last if Kephra::Document::Data::current_nr()
								== Kephra::Document::Data::last_nr()
							and not $attr->{auto_wrap};
						Kephra::Document::Change::tab_right();
						Kephra::Edit::_save_positions();
						$return = _find_first();
						last if Kephra::Document::Data::current_nr() == $begin_doc;
					}
					$Kephra::temp{dialog}{control} = 0;
				}
			}
			refresh_find_history($return) if $_ == 1;
			if ( $return == -1 ) { Kephra::Edit::_restore_positions(); last; }
			else { _caret_2_sel_end(); Kephra::Edit::_center_caret(); }
		}
	}
}

sub find_first {
	my $menu_call = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my $attr = _attributes();
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if ( _exist_find_item() ) {
		Kephra::Edit::_save_positions();
		if ($menu_call
		and $sel_begin != $sel_end
		and $sel_end - $sel_begin > $len ) {
			set_range('selection') 
		}
		if ( get_range() eq 'selection' ) {
			Kephra::Edit::Goto::_pos($sel_begin);
			$return = _find_next();
			if ($return > -1 and $ep->GetCurrentPos + $len <= $sel_end) {
				Kephra::Edit::_center_caret();
			} else {
				Kephra::Edit::_restore_positions();
				$return = -1;
			}
		} else {
			$return = _find_first();
			if ( get_range() eq 'open_docs'
			and ($sel_begin == $ep->GetSelectionStart or $return == -1 ) ){
				$Kephra::temp{dialog}{control} = 1;
				$return = -1;
				my $begin_doc = Kephra::Document::Data::current_nr();
				while ( $return == -1 ) {
					Kephra::Edit::_restore_positions();
					last if Kephra::Document::Data::current_nr() == 0
						and not $attr->{auto_wrap};
					Kephra::Document::Change::tab_left();
					Kephra::Edit::_save_positions();
					$return = _find_first();
					last if ( Kephra::Document::Data::current_nr() == $begin_doc );
				}
				$Kephra::temp{dialog}{control} = 0;
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				Kephra::Edit::_center_caret();
			} else {
				Kephra::Edit::_restore_positions();
			}
		}
		refresh_find_history($return);
	}
	$return;
}

sub find_last {
	my $menu_call = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my $attr = _attributes();
	my ( $sel_begin, $sel_end ) = $ep->GetSelection;
	my $pos = $ep->GetCurrentPos;
	my $len = _exist_find_item();
	my $return;
	if (_exist_find_item()) {
		Kephra::Edit::_save_positions();
		if ($menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len) {
			set_range('selection');
		}
		if ( get_range() eq 'selection' ) {
			Kephra::Edit::Goto::_pos($sel_end);
			$return = _find_prev();
			if ($return > -1 and $ep->GetCurrentPos >= $sel_begin) {
				Kephra::Edit::_center_caret();
			} else {
				Kephra::Edit::_restore_positions();
				$return = -1;
			}
		} else {
			$return = _find_last();
			if (get_range() eq 'open_docs'
				and ($sel_begin == $ep->GetSelectionStart or $return == -1) ){
				$Kephra::temp{dialog}{control} = 1;
				$return = -1;
				my $begin_doc = Kephra::Document::Data::current_nr();
				while ( $return == -1 ) {
					Kephra::Edit::_restore_positions();
					last if Kephra::Document::Data::current_nr()
							== Kephra::Document::Data::last_nr()
						and not $attr->{auto_wrap};
					Kephra::Document::Change::tab_right();
					Kephra::Edit::_save_positions();
					$return = _find_last();
					last if ( Kephra::Document::Data::current_nr() == $begin_doc );
				}
				$Kephra::temp{dialog}{control} = 0;
			}
			if ( $return > -1 ) {
				_caret_2_sel_end();
				Kephra::Edit::_center_caret();
			} else {
				Kephra::Edit::_restore_positions();
			}
		}
		refresh_find_history($return);
	}
	$return;
}

  # replace
sub replace_back {
	my $ep = Kephra::App::EditPanel::_ref();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		replace_selection();
		refresh_replace_history();
		find_prev();
	}
}

sub replace_fore {
	my $ep = Kephra::App::EditPanel::_ref();
	if ( $ep->GetSelectionStart != $ep->GetSelectionEnd ) {
		replace_selection();
		refresh_replace_history();
		find_next();
	}
}

sub replace_all {
	my $menu_call = shift;
	my $ep = Kephra::App::EditPanel::_ref();
	my ($sel_begin, $sel_end ) = $ep->GetSelection;
	my $line           = $ep->GetCurrentLine;
	my $len            = _exist_find_item();
	my $replace_string = get_replace_item();
	#if ($len) { # forbid replace with nothing
		if (    $menu_call
		    and $sel_begin != $sel_end 
			and $sel_end - $sel_begin > $len ) {
			_attributes()->{in} = 'selection';
		}
		if ( get_range() eq 'selection' ) {
			$ep->BeginUndoAction;
			Kephra::Edit::Goto::_pos($sel_begin);
			while ( _find_next() > -1 ) {
				last if ( $ep->GetCurrentPos + $len >= $sel_end );
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( get_range() eq 'document' ) {
			$ep->BeginUndoAction;
			Kephra::Edit::Goto::_pos(0);
			while ( _find_next() > -1 ) {
				$ep->ReplaceSelection($replace_string);
			}
			$ep->EndUndoAction;
		} elsif ( get_range() eq 'open_docs' ) {
			my $begin_doc = Kephra::Document::Data::current_nr();
			do {
				{
					Kephra::Edit::_save_positions();
					$ep->BeginUndoAction;
					Kephra::Edit::Goto::_pos(0);
					while ( _find_next() > -1 ) {
						$ep->ReplaceSelection($replace_string);
					}
					$ep->EndUndoAction;
					Kephra::Edit::_restore_positions();
				}
			} until ( Kephra::Document::Change::tab_right() == $begin_doc );
		}
		$ep->GotoLine($line);
		refresh_replace_history;
		Kephra::Edit::_keep_focus();
	#} # end of don't replace nothing
}

sub replace_confirm {
	if (_exist_find_item()) {
		my $ep = Kephra::App::EditPanel::_ref();
		my $attr = _attributes();
		my $line = $ep->LineFromPosition( $ep->GetCurrentPos );
		my $len  = _exist_find_item();
		my $sel_begin = $ep->GetSelectionStart;
		my $sel_end   = $ep->GetSelectionEnd;
		my $answer    = &Wx::wxYES;
		my $menu_call = shift;

		set_range('selection')
			if $menu_call
			and $sel_begin != $sel_end
			and $sel_end - $sel_begin > $len;

		if (get_range() eq 'selection') {
			sniff_selection( $ep, $sel_begin, $sel_end, $len, $line );
		} elsif (get_range() eq 'document') {
			sniff_selection( $ep, 0, $ep->GetTextLength, $len, $line );
		} elsif (get_range() eq 'open_docs') {
			my $begin_doc = Kephra::Document::Data::current_nr();
			do {
				{
					next if $answer == &Wx::wxCANCEL;
					Kephra::Edit::_save_positions();
					$answer = sniff_selection
						( $ep, 0, $ep->GetTextLength, $len, $line );
					Kephra::Edit::_restore_positions();
				}
			} until ( Kephra::Document::Change::tab_right() == $begin_doc );
		}
	}

	sub sniff_selection {
		my ( $ep, $sel_begin, $sel_end, $len, $line ) = @_;
		my $l10n = Kephra::Config::Localisation::strings()->{dialog}{search}{confirm};
		my $answer;
		Kephra::Edit::Goto::_pos($sel_begin);
		$ep->BeginUndoAction();
		while ( _find_next() > -1 ) {
			last if $ep->GetCurrentPos + $len >= $sel_end;
			Kephra::Edit::_center_caret();
			$answer = Kephra::Dialog::get_confirm_3
				($l10n->{text}, $l10n->{title}, 100, 100);
			last if $answer == &Wx::wxCANCEL;
			if ($answer == &Wx::wxYES) {replace_selection()}
			else                    {$ep->SetCurrentPos( $ep->GetCurrentPos + 1 )}
		}
		$ep->EndUndoAction;
		Kephra::Edit::Goto::_pos( $ep->PositionFromLine($line) );
		Kephra::Edit::_center_caret();
		$answer;
	}
	refresh_replace_history();
	Kephra::Edit::_keep_focus();
}

1;

=head1 NAME

Kephra::Edit::Search - find and replace functions

=head1 DESCRIPTION

=cut