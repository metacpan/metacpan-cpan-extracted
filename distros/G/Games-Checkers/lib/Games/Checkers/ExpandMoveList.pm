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

	my $method = $self->{must_beat} ? 'beat_destinations' : 'step_destinations';
	my $destinations = $self->{work_board}->$method($self->dst_1, $self->{piece}, $self->{color});

	for my $dst (@$destinations) {
		next if $self->add_dst($dst) == Err;
		if ($self->can_create_move) {
			$self->{status} = $self->gather_move;
		} else {
			$self->build_continue;
		}
		$self->del_dst;
		last if $self->{status} == Err;
	}
}

sub gather_move ($) {
	my $self = shift;
	die "Pure virtual method is called";
}

1;
