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

use base 'Games::Checkers::Board';

use Games::Checkers::Constants;
use Games::Checkers::MoveConstants;
use Games::Checkers::CreateMoveList;

use constant NO_COST => 1e9;
use constant EqualCostDeterminism => $ENV{EQUAL_COST_DETERMINISM};

my $stopped = No;
sub check_user_interaction () {
	# no user interaction yet
	return Ok;
}

sub new ($$$) {
	my $class = shift;
	my $board = shift;
	my $move = shift;

	my $self = $class->SUPER::new($board);
	$self->{move} = $move;
	$self->{sons} = [];
	$self->{expanded} = 0;
	return $self;
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

	my $creating_moves = Games::Checkers::CreateMoveList->new($self, $color);
	$self->{expanded} = 1;
	return $creating_moves->{status};
}

sub unexpand ($) {
	my $self = shift;
	$_->unexpand foreach @{$self->{sons}};
	@{$self->{sons}} = ();
	$self->{expanded} = 0;
}

sub is_better_cost ($$$$) {
	my $self = shift;
	my $color = shift;
	my $cost1 = shift;
	my $cost2 = shift;

	return int(rand(2)) unless $cost1 != $cost2 || EqualCostDeterminism;

	my $max = ($cost1 > $cost2) ? $cost1 : $cost2;
	my $min = ($cost1 < $cost2) ? $cost1 : $cost2;
	my $best = ($color == ($Games::Checkers::give_away ? Black : White)) ? $max : $min;
	return $best == $cost1;
}

sub choose_best_son ($$$$$) {
	my $self = shift;
	my $color = shift;
	my $level = shift;
	my $max_level = shift;

#	return undef if $stopped || check_user_interaction() != Ok;

	my $best_node = undef;
	my $best_cost = NO_COST;

	if ($level != 0) {
		# should use return value to determine actual thinking level
		$self->expand($color) unless $self->{expanded};

		foreach my $son (@{$self->{sons}}) {
			my ($deep_node, $deep_cost) = $son->choose_best_son(!$color, $level-1, $max_level);
			($best_node, $best_cost) = ($deep_node, $deep_cost)
				if $best_cost == NO_COST || $self->is_better_cost($color, $deep_cost, $best_cost);
		}

		$self->unexpand;
	}

	if (!defined $best_node) {
		$best_node = $self;
		$best_cost = $self->get_cost($color);
	} elsif ($level == $max_level - 1) {
		$best_node = $self;
	}

	return wantarray ? ($best_node, $best_cost) : $best_node;
}

package Games::Checkers::BoardTree;

use Games::Checkers::MoveConstants;
use Games::Checkers::BoardConstants;

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
	my $son = $self->{head}->choose_best_son($self->{color}, $max_level, $max_level);
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
