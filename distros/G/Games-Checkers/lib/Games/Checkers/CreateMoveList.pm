# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# ----------------------------------------------------------------------------

package Games::Checkers::CreateMoveList;

use base 'Games::Checkers::ExpandMoveList';

use Games::Checkers::Constants;
use Games::Checkers::MoveConstants;

sub new ($$$) {
	my $class = shift;
	my $board_tree_node = shift;
	my $color = shift;
	my $self = $class->SUPER::new($board_tree_node, $color);

	$self->{board_tree_node} = $board_tree_node;

	$self->build;
	return $self;
}

sub add_move ($) {
	my $self = shift;
	my $move = $self->create_move;
	return Err unless $move;  ### not needed
	die "Internal Error" if $move == NO_MOVE;
	my $new_board_tree_node = Games::Checkers::BoardTreeNode->new($self, $move);
	return Err unless $new_board_tree_node;  ### not needed
	push @{$self->{board_tree_node}->{sons}}, $new_board_tree_node;
	return Ok;
}

# ----------------------------------------------------------------------------

package Games::Checkers::CountMoveList;

use base 'Games::Checkers::ExpandMoveList';

use Games::Checkers::Constants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;
	my $self = $class->SUPER::new($board, $color);

	$self->{count} = 0;

	$self->build;
	return $self;
}

sub add_move ($) {
	my $self = shift;
	$self->{count}++;
	return Ok;
}

sub get_count ($) {
	my $self = shift;
	return $self->{status} == Ok ? $self->{count} : 0;
}

# ----------------------------------------------------------------------------

package Games::Checkers::CreateUniqueMove;

use base 'Games::Checkers::ExpandMoveList';

use Games::Checkers::Constants;
use Games::Checkers::MoveConstants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;
	my $self = $class->SUPER::new($board, $color);

	$self->{move} = NO_MOVE;

	$self->build;
	return $self;
}

sub add_move ($) {
	my $self = shift;
	return Err if $self->{move} != NO_MOVE;
	$self->{move} = $self->create_move;
	return Ok;
}

sub get_move ($) {
	my $self = shift;
	return $self->{status} == Ok ? $self->{move} : NO_MOVE;
}

# ----------------------------------------------------------------------------

package Games::Checkers::CreateVergeMove;

use base 'Games::Checkers::ExpandMoveList';

use Games::Checkers::Constants;
use Games::Checkers::MoveConstants;
use Games::Checkers::Move;

sub new ($$$$$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;
	my $self = $class->SUPER::new($board, $color);

	die "Not enough arguments in constructor" unless @_ >= 3;
	my $is_beat = $self->{is_beat} = shift;
	my $src = $self->{src0} = shift;
	my $dst = $self->{dst0} = shift;

	die "Bad verge move source location ($src): not occupied\n"
		unless $board->occup($src);
	die "Bad verge move source location ($src): incorrect color\n"
		unless $board->color($src) == $color;
	die "Bad verge move source location ($src): can't beat\n"
		unless !$is_beat || $board->can_piece_beat($src);
#	die "Bad verge move source location ($src): can't step\n"
#		unless $is_beat || $board->can_piece_step($src);

	if (!$is_beat) {
		if ($board->can_piece_step($src, $dst)) {
			$self->{move} = new Games::Checkers::Move($is_beat, $src, [$dst]);
			return $self;
		}
		# give it the last chance
		$board->can_piece_beat($src) ? $is_beat = 1 :
			die "Bad verge move ($src-$dst): can't step\n";
	}

	# support British rules
	if ($is_beat) {
		if ($board->can_piece_beat($src, $dst)) {
			$self->{move} = new Games::Checkers::Move($is_beat, $src, [$dst]);
			return $self;
		}
	}
	$self->{move} = NO_MOVE;

	$self->build;
	return $self;
}

sub add_move ($) {
	my $self = shift;

	return Err if !$self->{must_beat};
	return Ok if $self->{src} != $self->{src0} || $self->dst_1 != $self->{dst0};

	return Err if $self->{move} != NO_MOVE;
	$self->{move} = $self->create_move;
	return Ok;
}

sub get_move ($) {
	my $self = shift;
	return $self->{status} == Ok ? $self->{move} : NO_MOVE;
}

1;
