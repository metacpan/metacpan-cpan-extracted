package Kephra::App::EditPanel::Fold;
our $VERSION = '0.05';

use strict;
use warnings;
#
sub _ep_ref {
	Kephra::App::EditPanel::is($_[0]) ? $_[0] : Kephra::App::EditPanel::_ref()   
}
sub _config { Kephra::App::EditPanel::Margin::_config()->{fold} }
sub _attribute { 'folded_lines' }
#
sub _is_head_level { # is this the fold level of a head node ?
	my $level = shift;
	return 1 if ($level % 1024) < (($level >> 16) % 1024);
}
sub _is_node {
	my $line = shift;
	return 1 if _ep_ref()->GetFoldParent($line+1) == $line;
}
sub _get_line { # 
	my ($ep, $event) = @_;
	$ep = _ep_ref();
	my $line = Kephra::App::EditPanel::Margin::clicked_on_line($event);
	# save position where context menu poped so we can fold there
	if ($line == -1){
		if (defined $event and ref $event eq 'Wx::StyledTextEvent'){
			$line = $ep->LineFromPosition( $event->GetPosition() );
		}
		else { $line = $ep->GetCurrentLine() }
	}
	return $line;
}
#
sub store {
	for my $doc_nr (@{Kephra::Document::Data::all_nr()}) {
		my $ep = Kephra::Document::Data::_ep($doc_nr);
		my @lines;
		for (0 .. $ep->GetLineCount()-1) {
			push @lines, $_ unless $ep->GetFoldExpanded( $_ );
		}
		Kephra::Document::Data::set_attribute( _attribute(), \@lines, $doc_nr);
	}
}

sub restore {
	my $doc_nr = Kephra::Document::Data::valid_or_current_doc_nr(shift);
	my $ep     = Kephra::Document::Data::_ep($doc_nr);
	return if $doc_nr < 0 or not ref $ep;
	my $lines = Kephra::Document::Data::get_attribute( _attribute(), $doc_nr);
	return unless ref $lines eq 'ARRAY';
	for (reverse @$lines){
		$ep->ToggleFold($_) if $ep->GetFoldExpanded($_);
	}
}
#
# folding functions
#
sub toggle_here {
	my $ep = _ep_ref();
	my $line = _get_line(@_);
	$ep->ToggleFold($line);
	Kephra::Edit::Goto::next_visible_pos() if _config()->{keep_caret_visible}
	                                       and not $ep->GetFoldExpanded($line);
}
sub toggle_recursively {
	my $ep = _ep_ref();
	my $line = _get_line(@_);


	unless ( _is_node( $line ) ) {
		$line = $ep->GetFoldParent($line);
		return if $line == -1;
	}

	my $node_xpanded = not $ep->GetFoldExpanded($line);
	my $cursor = $ep->GetLastChild($line, -1);
	while ($cursor >= $line) {
		$ep->ToggleFold($cursor) if $ep->GetFoldExpanded($cursor) xor $node_xpanded;
		$cursor--;
	}
	Kephra::Edit::Goto::next_visible_pos() if _config()->{keep_caret_visible} and not $node_xpanded;
}
sub toggle_siblings         { toggle_siblings_of_line( _get_line(@_) ) }
sub toggle_siblings_of_line {
	my $ep = _ep_ref();
	my $line = shift;
	return if $line < 0 or $line > ($ep->GetLineCount()-1);
	my $level = $ep->GetFoldLevel($line);
	my $parent = $ep->GetFoldParent($line);
	my $xp = not $ep->GetFoldExpanded($line);
	my $first_line = $parent;
	my $cursor = $ep->GetLastChild($parent, -1 );
	($first_line, $cursor) = (-1, $ep->GetLineCount()-2) if $parent == -1;
	while ($cursor > $first_line){
		$ep->ToggleFold($cursor) if $ep->GetFoldLevel($cursor) == $level
		                         and ($ep->GetFoldExpanded($cursor) xor $xp);
		$cursor--;
	}
	Kephra::Edit::Goto::next_visible_pos() if _config()->{keep_caret_visible}
	                                       and not $xp;
	$ep->EnsureCaretVisible;
}

sub toggle_level {
	my $ep = _ep_ref();
	my $line = _get_line(@_);
	return if $line < 0 or $line > ($ep->GetLineCount()-1);
	my $level = $ep->GetFoldLevel($line);
	my $xp = not $ep->GetFoldExpanded($line);
	for (0 .. $ep->GetLineCount()-1) {
		$ep->ToggleFold($_) if $ep->GetFoldLevel($_) == $level
		                    and ($ep->GetFoldExpanded($_) xor $xp);
	}
	Kephra::Edit::Goto::next_visible_pos() if _config()->{keep_caret_visible}
	                                       and not $xp;
	$ep->EnsureCaretVisible;
}

sub toggle_all {
	my $ep = _ep_ref();
	my $newline = my $oldline = $ep->GetLineCount();
	# looking for the head of heads // capi di capi
	while ($oldline == $newline and $oldline > 0){
		$newline = --$oldline;
		$newline = $ep->GetFoldParent($newline) while $ep->GetFoldParent($newline) > -1;
	}
	my $root_unfolded = $ep->GetFoldExpanded($newline);
	$root_unfolded ? fold_all() : unfold_all();
	Kephra::Edit::Goto::next_visible_pos() if _config()->{keep_caret_visible}
	                                       and $root_unfolded;
}
sub fold_all {
	my $ep  = _ep_ref();
	my $cursor = $ep->GetLineCount()-1;
	while ($cursor > -1) {
		$ep->ToggleFold($cursor) if $ep->GetFoldExpanded($cursor);
		$cursor--;
	}
}
sub unfold_all {
	my $ep  = _ep_ref();
	my $cursor = $ep->GetLineCount()-1;
	while ($cursor > -1) {
		$ep->ToggleFold($cursor) unless $ep->GetFoldExpanded($cursor);
		$cursor--;
	}
}
sub show_folded_children {
	#my $ep = _ep_ref();
	#my $parent = _get_line(@_);
	#unless ( _is_head_level( $ep->GetFoldLevel($parent) ) ) {
		#$parent = $ep->GetFoldParent($parent);
		#return if $parent == -1;
	#}
	#$ep->ToggleFold($parent) unless $ep->GetFoldExpanded($parent);
	#my $cursöor = $ep->GetLastChild( $parent, -1 );
	#my $level = $ep->GetFoldLevel($parent) >> 16;
	#while (@cursor > $parent) {
		#$ep->ToggleFold($cursor) if $ep->GetFoldLevel($cursor) % 2048 == $level
		                         #and $ep->GetFoldExpanded($cursor);
		#$cursor--;
	#}
}

1;

=head1 NAME

Kephra::App::EditPanel::Fold - code folding functions

=head1 DESCRIPTION

=cut