package Kephra::Edit::Marker;
our $VERSION = '0.24';

use strict;
use warnings;

# internal data handling subs
sub _ep     { Kephra::App::EditPanel::_ref() }
sub _config { Kephra::API::settings()->{search}{marker} }
my @bookmark;
my @bookmark_nr = 0..9;
my $marker_nr = 10;    # pos remembered by edit control
sub _attribute      {'marked_lines'}
sub _bookmarks      { @bookmark }
sub bookmark_is_set {
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr]{set};
}
sub _marker_search_byte {
	my $search_byte = 1 << $marker_nr;
	$search_byte |=  (1 << scalar(@bookmark_nr) )-1 if _config()->{any};
	$search_byte;
}
sub _refresh_bookmark_data { # checks if this bookmark is still valid
	# refresh or deletes data data if necessary
	my $nr = shift;
	return unless bookmark_is_set($nr);
	my $bm_data = $bookmark[$nr];
	my $doc_nr = Kephra::Document::Data::validate_doc_nr( $bm_data->{doc_nr} );
	$doc_nr = Kephra::Document::Data::nr_from_file_path($bm_data->{file})
		if Kephra::Document::Data::get_file_path($doc_nr) ne $bm_data->{file};
	_delete_bookmark_data($nr), return 0 if $doc_nr == -1;
	$bm_data->{doc_nr} = $doc_nr;
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	my $line = $ep->MarkerNext(0, (1 << $nr) );
	_delete_bookmark_data($nr), return 0 if $line == -1;
	my $ll = $ep->LineLength( $line );
	if ($bm_data->{col} > $ll) {
		$bm_data->{col} = $ll;
		$bm_data->{pos} = $ep->PositionFromLine( $line ) + $bm_data->{col};
	}
	return $bm_data->{line} = $line;
}

sub _refresh_all_bookmarks { _refresh_bookmark_data($_) for @bookmark_nr }
sub _delete_bookmark_data {
	my $nr = shift;
	return if $nr < 0 or $nr > 9;
	$bookmark[$nr] = {};
}

sub _get_pos {# switch: was command triggered from context menu or key/main menu
	my $ep = _ep();
	my $line = Kephra::App::EditPanel::Margin::clicked_on_line();
	return $line > -1 ? $ep->PositionFromLine($line) : $ep->GetCurrentPos();
}
sub _get_line {# switch: was command triggered from context menu or key/main menu
	my $line = Kephra::App::EditPanel::Margin::clicked_on_line();
	return $line > -1 ? $line : _ep()->GetCurrentLine();
}
#
# external API
#
sub define_marker {
	my $ep = shift;
	my $conf = Kephra::App::EditPanel::Margin::_marker_config();

	my $color = \&Kephra::Config::color;
	my $fore = &$color( $conf->{fore_color} );
	my $back = &$color( $conf->{back_color} );
	$ep->MarkerDefineBitmap
		( $_, Kephra::CommandList::get_cmd_property
			( 'bookmark-goto-'.$_, 'icon' ) ) for @bookmark_nr;
	$ep->MarkerDefineBitmap( $marker_nr, 
		Kephra::CommandList::get_cmd_property('marker-toggle-here', 'icon'));
}

sub delete_doc {
	my $doc_nr = shift;
	delete_all_bookmarks_in_doc($doc_nr);
	delete_all_marker_in_doc($doc_nr);
}
# bookmarks
sub restore_bookmarks {
	my $bookmark_data = shift;
	for my $nr (@bookmark_nr) {
		if ( defined $bookmark_data->{$nr}){
			my $this_bm = $bookmark_data->{$nr};
			next unless ref $this_bm eq 'HASH' and $this_bm->{file} and $this_bm->{pos};
			$bookmark[$nr]{file} = $this_bm->{file};
			my $bookmark = $bookmark[$nr];
			my $doc_nr = $bookmark->{doc_nr} = 
				Kephra::Document::Data::nr_from_file_path( $this_bm->{file} );
			next if $doc_nr < 0;
			my $ep      = Kephra::Document::Data::_ep($doc_nr);
			my $pos = $bookmark->{pos} = $this_bm->{pos};
			my $line = $bookmark->{line} = $ep->LineFromPosition( $pos );
			$bookmark->{col} = $pos - $ep->PositionFromLine( $line );
			$bookmark->{set} = 1 if $ep->MarkerAdd( $line, $nr ) > -1;
		}
	}
}

sub get_bookmark_data {
	_refresh_bookmark_data($_) for @bookmark_nr;
	my %bm_data;
	for my $nr (@bookmark_nr) {
		next unless bookmark_is_set($nr);
		$bm_data{$nr}{file} = $bookmark[$nr]{file};
		$bm_data{$nr}{pos} = $bookmark[$nr]{pos};
	}
	\%bm_data;
}

sub toggle_bookmark_in_pos {
	my $nr = shift;
	my $pos = shift;
	my $ep = _ep();
	my $line = $ep->LineFromPosition($pos);
	# if bookmark is not in current line it will be set
	my $marker_in_line = (1 << $nr) & $ep->MarkerGet($line);
	delete_bookmark($nr);
	unless ($marker_in_line) {
		my $bookmark = $bookmark[$nr];
		$bookmark->{file} = Kephra::Document::Data::file_path();
		$bookmark->{pos}  = $pos;
		$bookmark->{doc_nr} = Kephra::Document::Data::current_nr();
		$bookmark->{col}    = $pos - $ep->PositionFromLine($line);
		$bookmark->{line}   = $line;
		$bookmark->{set}    = 1 if $ep->MarkerAdd( $line, $nr) > -1;
	}
}
sub toggle_bookmark_here   { # toggle triggered by margin middle click
	my ($ep, $event ) = @_;
	return unless ref $event eq 'Wx::MouseEvent';


	my $pos = $ep->PositionFromPoint( $event->GetPosition() );
	my $marker = $ep->MarkerGet($ep->LineFromPosition($pos) );
	if ( $marker & ((1 << 10)-1) ){
		for my $nr (@bookmark_nr) { # delete bookmarks in this line
			delete_bookmark($nr) if $marker & (1 << $nr) 
		}
	} else {
		for my $nr (@bookmark_nr) { # set a free bookmark with lowest number
			return toggle_bookmark_in_pos($nr, $pos) unless bookmark_is_set($nr);
		}
	}
}
sub toggle_bookmark   {    # toggle command, triggered from macro, key, [context] menu
	toggle_bookmark_in_pos(shift, _get_pos() );
}
sub goto_bookmark     {
	my $nr = shift;
	if ( _refresh_bookmark_data($nr) ) {
		Kephra::Document::Change::to_nr( $bookmark[$nr]{doc_nr} );
		Kephra::Edit::Goto::pos( $bookmark[$nr]{pos} );
	}
}

sub delete_bookmark   {
	my $nr = shift;
	if ( _refresh_bookmark_data( $nr ) ){
		my $ep = Kephra::Document::Data::_ep( $bookmark[$nr]->{doc_nr} );
		$ep->MarkerDeleteAll($nr);
		_delete_bookmark_data($nr);
	}
}
sub delete_all_bookmarks_in_doc {
	my $cnr = Kephra::Document::Data::current_nr();
	for my $nr (@bookmark_nr) {
		_refresh_bookmark_data( $nr );
		next unless bookmark_is_set($nr);
		delete_bookmark($nr) if $bookmark[$nr]->{doc_nr} eq $cnr;
	}
}
sub delete_all_bookmarks { delete_bookmark($_) for @bookmark_nr }

# marker
sub restore {
	my $doc_nr = shift;
	my $marker_pos = Kephra::Document::Data::get_attribute( _attribute(), $doc_nr);
	return unless ref $marker_pos eq 'ARRAY';
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	$ep->MarkerAdd( $_, $marker_nr) for @$marker_pos;
}

sub store { # update marker pos in the file data, saved later in File:Session
	# bookmarks are saved by Kephra::Edit::Search::save_search_data()
	my $search_byte = 1 << $marker_nr;
	for my $doc_nr  (@{Kephra::Document::Data::all_nr()}) {
		my $ep = Kephra::Document::Data::_ep($doc_nr);
		my $line = 0;
		my @marker_pos;
		push @marker_pos, $line++ 
			while -1 != ( $line = $ep->MarkerNext( $line, $search_byte ) );
		Kephra::Document::Data::set_attribute( _attribute(), \@marker_pos, $doc_nr);
	}
}

sub toggle_marker_in_line { # generic set / delete marker in line
	my $line = shift;
	my $ep = _ep();
	($ep->MarkerGet($line) & (1 << $marker_nr))
		? $ep->MarkerDelete( $line, $marker_nr)
		: $ep->MarkerAdd( $line, $marker_nr);
}

sub toggle_marker_here    { # toggle triggered by margin left click
	my ($ep, $event ) = @_;
	return unless ref $event eq 'Wx::MouseEvent';
	#$ep->LineFromPosition( $event->GetPosition() if ref $event eq 'Wx::StyledTextEvent'

	toggle_marker_in_line(
		$ep->LineFromPosition( $ep->PositionFromPoint( $event->GetPosition() ) )
	);
}

sub toggle_marker         { # toggle triggered by keyboard / icon / contextmenu
	toggle_marker_in_line(  _get_line() );
}

sub goto_prev_marker_in_doc {
	my $ep = _ep();
	my $do_wrap = _config()->{wrap};
	my $search_byte = _marker_search_byte();
	my $line = $ep->MarkerPrevious( $ep->GetCurrentLine - 1, $search_byte );
	$line = $ep->MarkerPrevious( $ep->GetLineCount(), $search_byte )
		if $line == -1 and $do_wrap;
	Kephra::Edit::Goto::line_nr( $line ) if $line > -1;
}

sub goto_next_marker_in_doc {
	my $ep = _ep();
	my $do_wrap = _config()->{wrap};
	my $search_byte = _marker_search_byte();
	my $line = $ep->MarkerNext( $ep->GetCurrentLine + 1, $search_byte );
	$line = $ep->MarkerNext( 0, $search_byte )
		if $line == -1 and $do_wrap;
	Kephra::Edit::Goto::line_nr( $line ) if $line > -1;
}

sub goto_prev_marker {
	my $search_byte = _marker_search_byte();
	my $ep = _ep();
	my $line = my $cur_line = 
		$ep->MarkerPrevious( $ep->GetCurrentLine() - 1, $search_byte );
	if ($line > -1) { Kephra::Edit::Goto::line_nr( $line ) }
	else {
		my $do_wrap = _config()->{wrap};
		my $doc_nr = my $cur_doc = Kephra::Document::Data::current_nr();
		while ( ($doc_nr = Kephra::Document::Data::next_nr(-1, $doc_nr)) != -1 ){
			return if $cur_doc < $doc_nr and not $do_wrap;
			$ep = Kephra::Document::Data::_ep($doc_nr);
			$line = $ep->MarkerPrevious( $ep->GetLineCount(), $search_byte );
			return if ($doc_nr == $cur_doc)
				  and ($line == $cur_line or $line == -1);
			if ($line > -1) {
				Kephra::Document::Change::to_number( $doc_nr );
				return Kephra::Edit::Goto::line_nr( $line );
			}
		}
	}
}

sub goto_next_marker {
	my $search_byte = _marker_search_byte();
	my $ep = _ep();
	my $line = my $cur_line = 
		$ep->MarkerNext( $ep->GetCurrentLine() + 1, $search_byte );
	if ($line > -1) { Kephra::Edit::Goto::line_nr( $line ) }
	else {
		my $do_wrap = _config()->{wrap};
		my $doc_nr = my $cur_doc = Kephra::Document::Data::current_nr();
		while ( ($doc_nr = Kephra::Document::Data::next_nr(-1, $doc_nr)) != -1 ){
			return if $cur_doc > $doc_nr and not $do_wrap;
			$ep = Kephra::Document::Data::_ep($doc_nr);
			$line = $ep->MarkerNext( 0, $search_byte );
			return if ($doc_nr == $cur_doc)
			      and ($line == $cur_line or $line == -1);
			if ($line > -1) {
				Kephra::Document::Change::to_number( $doc_nr );
				return Kephra::Edit::Goto::line_nr( $line );
			}
		}
	}
}

sub delete_all_marker_in_doc {
	my $doc_nr = Kephra::Document::Data::valid_or_current_doc_nr(shift);
	my $ep = Kephra::Document::Data::_ep($doc_nr);
	$ep->MarkerDeleteAll($marker_nr);
}
sub delete_all_marker { 
	$_->MarkerDeleteAll($marker_nr) for @{Kephra::Document::Data::get_all_ep()};
}

1;

=head1 NAME

Kephra::Edit::Marker - bookmark and marker functions

=head1 DESCRIPTION

Marker are position in the document, that are marked by symbols in the margin
on the left side. Every document can have many Marker. They can be navigated
via [Alt+][Shift+]F2 or search bar.

But there are only 10 bookmarks numbered from 0 to 9.

=cut