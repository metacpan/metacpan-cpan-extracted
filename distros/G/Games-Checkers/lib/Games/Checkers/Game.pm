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

package Games::Checkers::Game;

use Games::Checkers::Board;
use Games::Checkers::Constants;
use Games::Checkers::BoardTree;
use Games::Checkers::CreateMoveList;
use Games::Checkers::MoveConstants;

sub new ($%) {
	my $class = shift;
	my %params = @_;

	$ENV{DUMB_CHARS} = 1 if $params{dumb_chars};

	my $title = $params{title} || "Unknown White - Unknown Black";
	my $board = Games::Checkers::Board->new;

	# probe and use if available
	my $frontend = !($params{use_term} || $ENV{USE_TERM}) && eval q{
		use Games::Checkers::SDL;
		Games::Checkers::SDL->new($title, $board, fullscreen => $params{fullscreen});
	};

	my $self = {
		title => $params{title} || $title,
		board => $board,
		frontend => $frontend,
		dumb_term => $params{dumb_term},
		level => $params{level} || 3,
		random => $params{random} || 0,
		max_move_num => $params{max_move_num} || 1000,
	};

	bless $self, $class;

	$self->_init;
}

sub _init ($) {
	my $self = shift;

	if ($self->{frontend}) {
		$self->{frontend}->init;
	} else {
		$| = 1;
		print "\e[2J" unless $self->{dumb_term};
	}

	$self->{move_count} = 0;
	$self->{color} = White;

	return $self;
}

sub sleep ($$) {
	my $self = shift;
	my $secs = shift || 0;

	if ($self->{frontend}) {
		$self->{frontend}->sleep($secs);
	} else {
		sleep($secs);
	}	
}

sub show_board ($) {
	my $self = shift;

	if ($self->{frontend}) {
		$self->{frontend}->show_board;
	} else {
		my $title = $self->{title};
		my $indent = int((37 - length($title)) / 2);
		print "\e[1;1H\e[?25l" unless $self->{dumb_term};
		print " " x $indent, $title, "\n";
		print $self->{board}->dump;
		print "\e[?25h" unless $self->{dumb_term};
	}
}

sub can_move ($) {
	my $self = shift;

	$self->{board}->can_color_move($self->{color});
}

sub is_max_move_num_reached ($) {
	my $self = shift;

	return $self->{move_count} >= $self->{max_move_num} * 2;
}

sub choose_move ($) {
	my $self = shift;

	my ($board, $color, $level, $random) = map {
		$self->{$_}
	} qw(board color level random);

	my $board_tree = Games::Checkers::BoardTree->new($board, $color, $level);

	my $move = $random eq 1 || $random eq ($color == White ? 'w' : 'b')
		? $board_tree->choose_random_move
		: $board_tree->choose_best_move;

	return $move;
}

sub create_move ($$$$) {
	my $self = shift;
	my $is_beat = shift;
	my $src = shift;
	my $dst = shift;

	my $creating_move = Games::Checkers::CreateVergeMove->new(
		$self->{board}, $self->{color}, $is_beat, $src, $dst
	);
	die "Internal problem" unless $creating_move->status == Ok;
	my $move = $creating_move->get_move;

	return $move == NO_MOVE ? undef : $move;
}

sub show_move ($$) {
	my $self = shift;
	my $move = shift;

	my ($board, $color, $move_count) = map {
		$self->{$_}
	} qw(board color move_count);

	if ($self->{frontend}) {
		$self->{frontend}->show_move($move, $color, $move_count);
	} else {
		printf "  %02d. %s", 1 + $move_count / 2, $color == White ? "" : "... ";
		print $move->dump, "                           \n";
	}

	$board->transform($move);

	$self->{color} = $color == White ? Black : White;
	$self->{move_count}++;
}

sub show_result ($;$) {
	my $self = shift;
	my $message = shift || ($self->is_max_move_num_reached
		? "Automatic draw after $self->{max_move_num} moves."
		: (($self->{color} == White xor $Games::Checkers::give_away)
			? "Black" : "White") . " won."
	);

	if ($self->{frontend}) {
		$self->{frontend}->show_result($message);
	} else {
		print "\n$message\e[0K\n";
	}
}

1;
