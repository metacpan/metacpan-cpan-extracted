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

use Games::Checkers::Rules;
use Games::Checkers::Board;
use Games::Checkers::Constants;
use Games::Checkers::BoardTree;
use Games::Checkers::CreateMoveList;
use Games::Checkers::MoveConstants;

sub new ($%) {
	my $class = shift;
	my %params = @_;

	my $variant = $params{variant};
	Games::Checkers::Rules::set_variant($variant);

	$ENV{DUMB_CHARS} = 1 if $params{dumb_chars};

	my $title = $params{title} || "Unknown White - Unknown Black";
	my $board = Games::Checkers::Board->new($params{board}, $params{size});
	my $color = defined $params{color} ? $params{color} :
		(defined $ENV{_WHITE_STARTS} ? $ENV{_WHITE_STARTS} :
		$::RULES{WHITE_STARTS}) ^ ($params{black} || 0) ? White : Black;

	# probe and use if available
	my $frontend = !($params{use_term} || $ENV{USE_TERM}) && eval q{
		use Games::Checkers::SDL;
		Games::Checkers::SDL->new($title, $board, fullscreen => $params{fullscreen});
	};

	my $self = {
		variant => $variant,
		title => $title,
		board => $board,
		color => $color,
		frontend => $frontend,
		dumb_term => $params{dumb_term},
		level => $params{level} || 3,
		random => $params{random} || 0,
		max_move_num => $params{max_move_num} || 1000,
		plies => [],
		initial => {
			board => $board->clone,
			color => $color,
		},
	};

	bless $self, $class;

	$SIG{__DIE__} = sub {
		$self->show_result(shift);
	};

	$self->edit_board if $params{edit_board};

	$self->show_menu if $params{show_menu};

	$self->init;
}

sub show_menu ($) {
	my $self = shift;

	if ($self->{frontend}) {
		$self->{board} = $self->{frontend}->show_menu($self->{board});
	}

	$self->quit unless $self->{board};
}

sub init ($) {
	my $self = shift;

	$self->{plies} = [];

	if ($self->{frontend}) {
		$self->{frontend}->init;
	} else {
		$| = 1;
		print "\e[2J" unless $self->{dumb_term};
	}

	return $self;
}

sub restart ($) {
	my $self = shift;

	$self->{board} = $self->{initial}{board}->clone;
	$self->{color} = $self->{initial}{color};

	if ($self->{frontend}) {
		$self->{frontend}->restart($self->{board});
	}

	$self->init;
	$self->show_board;
	$self->sleep(1);
}

sub quit ($) {
	my $self = shift;

	if ($self->{frontend}) {
		$self->{frontend}->quit or return;
	}

	exit(0);
}

sub call_frontend ($$@) {
	my $self = shift;
	my $method = shift || die;

	my $rv = $self->{frontend}->$method(@_);

	if ($rv == -1) {
		$self->restart;
	}
	if ($rv == -2) {
		$self->quit;
	}

	return $rv;
}

sub sleep ($$) {
	my $self = shift;
	my $secs = shift || 0;

	if ($self->{frontend}) {
		$self->call_frontend('sleep', $secs);
	} else {
		sleep($secs);
	}	
}

sub hold ($;$) {
	my $self = shift;
	my $break = shift;

	if ($self->{frontend}) {
		$self->call_frontend('hold', $break);
	} else {
		$self->sleep($break) if $break;
	}
}

sub show_board ($) {
	my $self = shift;

	if ($self->{frontend}) {
		$self->call_frontend('show_board');
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

	return @{$self->{plies}} >= $self->{max_move_num} * 2;
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

sub create_move ($$$@) {
	my $self = shift;
	my $is_beat = shift;
	my $src = shift;
	my @dsts = @_;

	my $creating_move = Games::Checkers::CreateVergeMove->new(
		$self->{board}, $self->{color}, $is_beat, $src, @dsts
	);
	die "Internal problem" unless $creating_move->status == Ok;
	my $move = $creating_move->get_move;

	return $move == NO_MOVE ? undef : $move;
}

sub show_move ($$) {
	my $self = shift;
	my $move = shift;

	my ($board, $color, $plies) = map {
		$self->{$_}
	} qw(board color plies);

	my $move_str = $move->dump($board);
	my $is_second = ($color eq White) != $::RULES{WHITE_STARTS};

	if ($self->{frontend}) {
		$self->call_frontend('show_move', $move, $move_str, $is_second, $plies)
			&& return;  # return on "restart" or unconfirmed "quit"
	} else {
		printf "  %02d. %s", 1 + @$plies / 2, $is_second ? "... " : "";
		print "$move_str                           \n";
	}

	$board->apply_move($move);

	$self->{color} = $color == White ? Black : White;
	push @$plies, $move;
}

sub color_name ($;$$) {
	my $self = shift;
	my $opposite = shift || 0;
	my $starting = shift || 0;

	# does it ever make sense to use $self->{initial}{color} instead?
	my $starting_color = $::RULES{WHITE_STARTS} ? White : Black;

	return (($starting ? $starting_color : $self->{color})
		== White xor $opposite) ? 'White' : 'Black';
}

sub show_result ($;$$) {
	my $self = shift;
	my $message = shift || ($self->is_max_move_num_reached
		? "Automatic draw after $self->{max_move_num} moves"
		: $self->color_name(!$::RULES{GIVE_AWAY}) . " won"
	);
	my $break = shift;

	if ($self->{frontend}) {
		$self->call_frontend('show_result', $message)
			&& return;  # return on "restart" or unconfirmed "quit"
	} else {
		print "\n$message.\e[0K\n";
	}

	$self->hold($break);
}

sub show_result_code ($;$$) {
	my $self = shift;
	my $code = shift || '';
	my $break = shift;

	my $message =
		$code eq '1-0'     || $code eq '2-0' ? '%C %l' :
		$code eq '0-1'     || $code eq '0-2' ? '%c %l' :
		$code eq '1/2-1/2' || $code eq '1-1' ? 'Draw is agreed' :
		$code eq '*' ? 'Unfinished game' : "Unknown result ($code)";

	$message =~ s/%([cC])/$self->color_name($1 ne 'c', 1)/e;
	$message =~ s/%l/$self->can_move ? 'resigned' : 'lost'/e;

	$self->show_result($message, $break);
}

sub edit_board ($) {
	my $self = shift;

	my $board = $self->{board};

	if ($self->{frontend}) {
		$self->{frontend}->edit_board($board);
	}

	$self->{initial}{board}->copy($board);
}

1;
