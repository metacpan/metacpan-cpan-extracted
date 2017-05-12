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

package Games::Checkers::ExpandMoveList;

use base 'Games::Checkers::MoveLocationConstructor';
use Games::Checkers::Constants; 
use Games::Checkers::IteratorConstants;

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;
	my $self = $class->SUPER::new($board, $color);

	$self->{figure_iterator} =
		new Games::Checkers::FigureIterator($board, $color);
	$self->{status} = Ok;
	return $self;
}

sub status ($) {
	my $self = shift;
	return $self->{status};
}

sub build ($) {
	my $self = shift;
	while ($self->{figure_iterator}->left) {
		if ($self->source($self->{figure_iterator}->next) == Ok) {
			$self->build_continue;
			return if $self->{status} == Err;
		}
	}
}

sub build_continue ($) {
	my $self = shift;

	my $iterator_class = "Games::Checkers::";
	$iterator_class .= (qw(PawnStepIterator PawnBeatIterator KingStepIterator KingBeatIterator))
		[($self->{piece} == King) * 2 + $self->{must_beat}];
	my $rule_iterator = $iterator_class->new($self->dst_1, $self->{color});

#	if (type == Pawn &&  must_beat) rule_iterator = &pawn_beat_iterator;
#	if (type == Pawn && !must_beat) rule_iterator = &pawn_step_iterator;
#	if (type == King &&  must_beat) rule_iterator = &king_beat_iterator;
#	if (type == King && !must_beat) rule_iterator = &king_step_iterator;
#	rule_iterator->init(dst_1(), color);
#	if (type == Pawn && !must_beat) rule_iterator = new PawnStepIterator(dst_1(), color);
#	if (type == Pawn &&  must_beat) rule_iterator = new PawnBeatIterator(dst_1(), color);
#	if (type == King && !must_beat) rule_iterator = new KingStepIterator(dst_1(), color);
#	if (type == King &&  must_beat) rule_iterator = new KingBeatIterator(dst_1(), color);
#	if (type == King &&  must_beat) rule_iterator = new ValidKingBeatIterator(dst_1(), color, *this);
#	unless ($rule_iterator)

	while ($rule_iterator->left) {
		next if $self->add_dst($rule_iterator->next) == Err;
		if ($self->can_create_move) {
			$self->{status} = $self->add_move;
		} else {
			$self->build_continue;
		}
		$self->del_dst;
		last if $self->{status} == Err;
	}
}

sub add_move ($) {
	my $self = shift;
	die "Pure virtual method is called";
}

1;
