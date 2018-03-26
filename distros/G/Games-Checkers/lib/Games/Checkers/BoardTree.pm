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

package Games::Checkers::BoardTreeNode;

use Games::Checkers::Constants;
use Games::Checkers::MoveConstants;
use Games::Checkers::CreateMoveList;

my $stopped = No;
sub check_user_interaction () {
	# no user interaction yet
	return Ok;
}

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $move = shift;

	my $self = {
		board => $board,
		move => $move,
		sons => [],
		expanded => 0,
	};

	return bless $self, $class;
}

#       o                                                    3  0
#       |                                                         white max
#       o-----------------------o                            2  1
#       |                       |                                 black min
#       o-------o-------o       o-------o-------o            1  2
#       |       |       |       |       |       |                 white max
#       o-o-o   o-o-o   o-o-o   o-o-o   o-o-o   o-o-o        0  3

sub expand ($$) {
	my $self = shift;
	my $color = shift;

	my $board = $self->{board};
	my $builder = Games::Checkers::CreateMoveList->new($board, $color);

	@{$self->{sons}} = map {
		Games::Checkers::BoardTreeNode->new($_->[1], $_->[0])
	} @{$builder->get_move_boards};
	$self->{expanded} = 1;

	return $builder->{status};
}

sub unexpand ($) {
	my $self = shift;

	$_->unexpand foreach @{$self->{sons}};
	@{$self->{sons}} = ();
	$self->{expanded} = 0;
}

sub choose_best_son ($$$;$$) {
	my $self = shift;
	my $color = shift;
	my $level = shift;
	my $min = shift; $min = MIN_SCORE unless defined $min;
	my $max = shift; $max = MAX_SCORE unless defined $max;

#	return if $stopped || check_user_interaction() != Ok;

	my $is_maximizing = $color == ($::RULES{GIVE_AWAY} ? Black : White);
	my $best_node;

	if ($level <= 0) {
		$min = $max = $self->{board}->get_score($color);
	} else {
		$self->expand($color) unless $self->{expanded};

		foreach my $son (@{$self->{sons}}) {
			my ($score) = $son->choose_best_son(!$color, $level - 1,	$min, $max);

			if ($is_maximizing) {
				if ($score > $min) {
					$min = $score;
					$best_node = $son;
				}
			}
			else {
				if ($score < $max) {
					$max = $score;
					$best_node = $son;
				}
			}
			# alpha-beta pruning
			$is_maximizing ^= 1, last if $min >= $max;
		}

		# all moves if any lead to losage, choose a random one
		$best_node ||= $self->{sons}[rand(@{$self->{sons}})];

		$self->unexpand;
	}

	return wantarray ? ($is_maximizing ? $min : $max) : $best_node;
}

package Games::Checkers::BoardTree;

use Games::Checkers::MoveConstants;

use constant DEFAULT_LEVEL => 5;

sub new ($$$;$) {
	my $class = shift;
	my $board = shift;
	my $color = shift;
	my $level = shift || DEFAULT_LEVEL;

	my $self = {
		head => new Games::Checkers::BoardTreeNode($board, NO_MOVE),
		max_level => $level,
		real_level => undef,
		color => $color,
	};

	return bless $self, $class;
}

sub choose_best_move ($) {
	my $self = shift;

	my $max_level = $self->{max_level};
	my $son = $self->{head}->choose_best_son($self->{color}, $max_level);
#	foreach my $son0 (@{$self->{sons}}) {
#		next if defined $son && $son == $son0;
#		$son0->unexpand;
#	}
	return NO_MOVE unless $son;
	return $son->{move};
}

sub choose_random_move ($) {
	my $self = shift;

	$self->{head}->expand($self->{color});
	my $sons = $self->{head}->{sons};
	my $move = $sons->[int(rand(@$sons))]->{move};
	$self->{head}->unexpand;
	return $move;
}

1;
