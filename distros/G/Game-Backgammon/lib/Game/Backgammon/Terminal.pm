package Game::Backgammon::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Backgammon;
use Game::Backgammon::Board ();
use Game::Backgammon::Bot;

our $VERSION = '0.01';

my %CHECKER = (
	white => { ascii => 'O', wide => "\x{25CB}", colour => '1;37' },
	black => { ascii => 'X', wide => "\x{25CF}", colour => '1;36' },
);

use constant ROWS => 5;

has game => (
	is => 'rw',
	isa => Object
);

has out => (
	is => 'ro',
	isa => Any,
	default => sub { \*STDOUT }
);

has in => (
	is => 'ro',
	isa => Any,
	default => sub { \*STDIN }
);

has mode => (
	is => 'ro',
	isa => Str,
	default => 'bot'
);

has level => (
	is => 'ro',
	isa => Int,
	default => 3
);

has seat => (
	is => 'ro',
	isa => Str,
	default => 'white'
);

has view => (
	is => 'rw',
	isa => Str,
	default => ''
);

has ascii => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has [qw/colour interactive/] => (
	is => 'rw'
);

sub BUILD {
	my ($self) = @_;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0)
		unless defined $self->colour;
	binmode $self->out, ':encoding(UTF-8)' unless $self->ascii;

	my $previous = select $self->out;
	$| = 1;
	select $previous;
	return;
}

sub say_to { my ($self, @what) = @_; my $fh = $self->out; print {$fh} @what, "\n"; return }

sub board_lines {
	my ($self, $view) = @_;
	$view ||= $self->view || $self->game->turn;
	my $board = $self->game->board;
	my $other = Game::Backgammon::Board::other($view);

	my @lines = (
		$self->_border(13 .. 24),
		$self->_half($view, [13 .. 24], 0),
		' |' . (' ' x 18) . '|' . $self->_label('BAR') . '|'
			. (' ' x 18) . '|' . $self->_label('OFF') . '|',
		$self->_half($view, [reverse 1 .. 12], 1),
		$self->_border(reverse 1 .. 12)
	);

	$lines[1] .= sprintf '  %-5s %3d pips', ucfirst $other, $board->pip_count($other);
	$lines[11] .= sprintf '  %-5s %3d pips', ucfirst $view, $board->pip_count($view);
	if (my $last = $self->game->history->[-1]) {
		$lines[6] .= sprintf '  last: %s %s', $last->player, $last->notation;
	}
	push @lines, sprintf '  the points are numbered from %s', $view;
	return \@lines;
}

sub render {
	my ($self, $view) = @_;
	return join "\n", @{ $self->board_lines($view) };
}

sub _border {
	my ($self, @points) = @_;
	my @cell = map { my $c = sprintf '%2d-', $_; $c =~ s/\A /-/; $c } @points;
	return ' ' . $self->_label(
		'+' . join('', @cell[0 .. 5]) . '+---+' . join('', @cell[6 .. 11]) . '+---+'
	);
}

sub _half {
	my ($self, $view, $points, $bottom) = @_;
	my $board = $self->game->board;
	my $other = Game::Backgammon::Board::other($view);
	my @lines;
	for my $row (0 .. ROWS - 1) {
		my $edge = $bottom ? ROWS - 1 - $row : $row;
		my $middle = $bottom ? $row : ROWS - 1 - $row;
		my @cell;
		for my $n (@$points) {
			my ($mine, $theirs) = $board->point_for($view, $n);
			push @cell, $mine
				? $self->_cell($view, $mine, $edge)
				: $self->_cell($other, $theirs, $edge);
		}
		my $bar = $bottom
			? $self->_cell($other, $board->bar($other), $middle)
			: $self->_cell($view, $board->bar($view), $middle);
		my $off = $bottom
			? $self->_cell($view, $board->off($view), $edge)
			: $self->_cell($other, $board->off($other), $edge);
		push @lines, ' ' . $self->_label('|') . join('', @cell[0 .. 5])
			. $self->_label('|') . $bar . $self->_label('|')
			. join('', @cell[6 .. 11]) . $self->_label('|') . $off
			. $self->_label('|');
	}
	return @lines;
}

sub _cell {
	my ($self, $player, $count, $edge) = @_;
	return '   ' unless $count && $edge < ROWS;
	return $self->_paint(
		$count > 9 ? "$count " : " $count ", $CHECKER{$player}{colour}
	) if $edge == ROWS - 1 && $count > ROWS;
	return '   ' unless $edge < $count;
	return ' ' . $self->_paint(
		$CHECKER{$player}{$self->ascii ? 'ascii' : 'wide'}, $CHECKER{$player}{colour}
	) . ' ';
}

sub _label { my ($self, $text) = @_; return $self->_paint($text, '2') }

sub _paint {
	my ($self, $text, $code) = @_;
	return $text unless $self->colour;
	return "\e[${code}m" . $text . "\e[0m";
}

sub clear {
	my ($self) = @_;
	return unless $self->interactive;
	my $fh = $self->out;
	print {$fh} "\e[2J\e[H";
	return;
}

sub step {
	my ($self) = @_;
	my $game = $self->game;
	return 0 if $game->status ne 'active';

	my $who = $game->turn;
	$self->clear;
	$self->say_to($self->render($who));
	$self->say_to(sprintf '  %s to play %s', $who, join '-', @{ $game->dice });

	my $turns = $game->legal_turns;
	if ($turns->[0]->is_forfeit && @$turns == 1) {
		$self->say_to('  no play');
		$game->play($turns->[0]);
		return $game->status eq 'active' ? 1 : 0;
	}

	my $turn = $self->_ask($who, $turns);
	return 0 unless $turn;
	$game->play($turn) or do { $self->say_to('  ' . $@->message); return 1 };
	$self->say_to('  ' . $turn->notation);
	return $game->status eq 'active' ? 1 : 0;
}

sub _ask {
	my ($self, $who, $turns) = @_;
	return Game::Backgammon::Bot->new(level => $self->level)->choose($self->game)
		if $self->mode eq 'watch'
		|| ($self->mode eq 'bot' && $who ne $self->seat);

	$self->say_to($_) for @{ $self->offer_lines($turns) };
	my $fh = $self->in;
	my $out = $self->out;
	while (1) {
		print {$out} "  $who> ";
		my $line = <$fh>;
		return undef unless defined $line;
		$line =~ s/\s+\z//;
		return undef if $line eq 'q' || $line eq 'quit';
		return $turns->[ $line - 1 ] if $line =~ /\A\d+\z/ && $line >= 1 && $line <= @$turns;
		$self->say_to('  pick a number from the list, or q to stop');
	}
}

sub offer_lines {
	my ($self, $turns) = @_;
	my @item = map { sprintf '%2d) %s', $_ + 1, $turns->[$_]->notation } 0 .. $#$turns;
	my $width = 0;
	for my $item (@item) {
		$width = length $item if length $item > $width;
	}
	my $columns = int(74 / ($width + 2)) || 1;
	$columns = 4 if $columns > 4;
	my @lines;
	while (@item) {
		my @row = splice @item, 0, $columns;
		my $line = '  ' . join '  ', map { sprintf '%-*s', $width, $_ } @row;
		$line =~ s/\s+\z//;
		push @lines, $line;
	}
	return \@lines;
}

sub run {
	my ($self) = @_;
	$self->game(Game::Backgammon->new(seed => $self->_seed)) unless $self->game;
	my $guard = 0;
	while ($self->step) { last if ++$guard > 10_000 }
	$self->clear;
	$self->say_to($self->render($self->mode eq 'bot' ? $self->seat : undef));
	my $r = $self->game->result;
	$self->say_to($r ? $r->stringify : 'stopped');
	return $r;
}

sub _seed {
	require Digest::SHA;
	open my $ur, '<:raw', '/dev/urandom' or return Digest::SHA::sha256(rand() . $$ . time);
	read $ur, my $bytes, 32;
	close $ur;
	return length($bytes) == 32 ? $bytes : Digest::SHA::sha256(rand() . $$ . time);
}

1;

__END__

=head1 NAME

Game::Backgammon::Terminal - the game at a prompt

=head1 SYNOPSIS

    use Game::Backgammon::Terminal;

    Game::Backgammon::Terminal->new(mode => 'bot', level => 3)->run;

=head1 DESCRIPTION

All of this distribution's input and output lives here and in
F<bin/backgammon>. Nothing below this file reads or writes anything, which
is what makes the engine reusable; C<t/09-no-io.t> proves it by playing a
whole game with C<STDOUT> tied to something that dies on write.

C<in> and C<out> are attributes rather than bare handles, so a test can play
a game through this class without a terminal. A UI that only a human can
drive is a UI that rots without anybody noticing.

=head2 The board

    +13-14-15-16-17-18-+---+19-20-21-22-23-24-+---+
    | O           X    |   | X              O |   |  Black 167 pips
    | O           X    |   | X              O |   |
    | O           X    |   | X                |   |
    | O                |   | X                |   |
    | O                |   | X                |   |
    |                  |BAR|                  |OFF|
    | X                |   | O                |   |
    | X                |   | O                |   |
    | X           O    |   | O                |   |
    | X           O    |   | O              X |   |
    | X           O    |   | O              X |   |  White 167 pips
    +12-11-10--9--8--7-+---+-6--5--4--3--2--1-+---+

A real board: the twelve points of each half between their borders, the bar
down the middle and the tray on the right. Checkers hang down from the top
border and stand up from the bottom one; a point taller than five shows its
count in the last place. Round checkers unless L</ascii> is set, and colour
only when the session is interactive and C<NO_COLOR> is unset.

It is drawn from the numbering of whoever is on roll, so the board in front
of a player is the one their own moves are written in: their home board is
the bottom right quarter and they run anticlockwise into it. That is why the
numbers change sides between turns, and L</view> pins them to one side for
anybody who would rather they did not. Your own checkers on the bar are
drawn in the top of the middle column, where you re-enter, and your tray at
the bottom right beside your home board.

The pip counts are beside the side they belong to: the one number in the
game nobody can read off the board itself.

=head1 ATTRIBUTES

=head2 game, in, out, mode, level, seat

C<mode> is C<bot>, C<hotseat> or C<watch>.

=head2 view

C<white>, C<black>, or empty for whoever is on roll.

=head2 ascii

C<O> and C<X> instead of the round checkers.

=head2 colour, interactive

Both default from C<in>: colour when it is a terminal and C<NO_COLOR> is
unset, and the screen is only cleared between turns for a person, so a
captured transcript stays readable.

=head1 METHODS

=head2 render($view)

The board as one string.

=head2 board_lines($view)

The board as an arrayref of lines, without their newlines.

=head2 offer_lines($turns)

The legal turns, numbered, laid out across the width of the board. Doubles
from the bar can offer thirty of them, and a list that long pushes the board
it belongs to off the top of the screen.

=head2 clear

Clears the screen, but only for a person.

=head2 step

Play one turn. Returns true while the game is still on.

=head2 run

Play until the game ends or the player stops. Returns the
L<Game::Backgammon::Result>, or undef if it was stopped.

=head2 say_to(@what)

Write a line to C<out>.

=cut
