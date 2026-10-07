package Game::Backgammon::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Backgammon;
use Game::Backgammon::Board ();
use Game::Backgammon::Bot;

our $VERSION = '0.02';

my %CHECKER = (
	white => { ascii => 'O', wide => "\x{25CB}", colour => '1;37', ink => '1;38;5;231' },
	black => { ascii => 'X', wide => "\x{25CF}", colour => '1;36', ink => '1;38;5;16' },
);

my %SEQUENCE = (
	'A' => 'up',
	'B' => 'down',
	'C' => 'right',
	'D' => 'left',
	'H' => 'home',
	'F' => 'end',
	'1~' => 'home',
	'4~' => 'end',
	'5~' => 'page_up',
	'6~' => 'page_down',
	'7~' => 'home',
	'8~' => 'end',
);

my %CONTROL = (
	"\r" => 'enter',
	"\n" => 'enter',
	"\t" => 'tab',
	"\x7f" => 'backspace',
	"\x08" => 'backspace',
	"\x03" => 'interrupt',
	"\x04" => 'eof',
);

my %GROUND = (
	light => '48;5;180',
	dark => '48;5;94',
	from => '48;5;136',
	to => '48;5;28',
	hit => '48;5;124',
	played => '48;5;24',
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

has [qw/colour interactive picking/] => (
	is => 'rw'
);

has highlight => (
	is => 'rw',
	isa => HashRef,
	default => sub { {} }
);

has raw => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has keysource => (
	is => 'rw',
	isa => CodeRef
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { [] }
);

sub BUILD {
	my ($self) = @_;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0)
		unless defined $self->colour;
	$self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
	$self->picking(0) unless $self->_keys_available;
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
				? $self->_cell($view, $mine, $edge, $n)
				: $self->_cell($other, $theirs, $edge, $n);
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
	my ($self, $player, $count, $edge, $point) = @_;
	return $self->_ground($point, '   ') unless $count && $edge < ROWS;
	return $self->_ground(
		$point, $count > 9 ? "$count " : " $count ", $player
	) if $edge == ROWS - 1 && $count > ROWS;
	return $self->_ground($point, '   ') unless $edge < $count;
	return $self->_ground(
		$point, ' ' . $CHECKER{$player}{$self->ascii ? 'ascii' : 'wide'} . ' ', $player
	);
}

sub _ground {
	my ($self, $point, $text, $player) = @_;
	return $player
		? $self->_paint($text, $CHECKER{$player}{colour})
		: $text
		unless $self->colour && defined $point;

	my $mark = $self->highlight->{$point};
	$mark = $point % 2 ? 'dark' : 'light' unless $mark && $GROUND{$mark};
	my @code = ($GROUND{$mark});
	push @code, $CHECKER{$player}{ink} if $player;
	return "\e[" . join(';', @code) . "m$text\e[0m";
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

sub _keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless defined $self->in && -t $self->in;
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub _enter_raw {
	my ($self) = @_;
	return $self if $self->raw;
	if ($self->keysource) {
		$self->raw(1);
		return $self;
	}
	return undef unless $self->_keys_available;
	return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
	$self->raw(1);
	return $self;
}

sub _leave_raw {
	my ($self) = @_;
	return $self unless $self->raw;
	eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
	$self->raw(0);
	return $self;
}

sub _read_char {
	my ($self, $wait) = @_;
	my $pending = $self->pending;
	return shift @$pending if @$pending;
	return $self->keysource->($wait) if $self->keysource;
	my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
	return $char if defined $char || $wait;
	select undef, undef, undef, 0.05;
	return Term::ReadKey::ReadKey(-1, $self->in);
}

sub _read_key {
	my ($self) = @_;
	my $char = $self->_read_char(1);
	return undef unless defined $char;
	return $CONTROL{$char} if $CONTROL{$char};
	return $self->_read_sequence if $char eq "\e";
	return $char;
}

sub _read_sequence {
	my ($self) = @_;
	my $opener = $self->_read_char(0);
	return 'escape' unless defined $opener;
	unless ($opener eq '[' || $opener eq 'O') {
		unshift @{ $self->pending }, $opener;
		return 'escape';
	}
	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->_read_char(0);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ /[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'escape';
}

sub step {
	my ($self) = @_;
	my $game = $self->game;
	return 0 if $game->status ne 'active';

	my $who = $game->turn;
	my $picking = $self->picking && $self->raw
		&& ($self->mode eq 'hotseat' || ($self->mode eq 'bot' && $who eq $self->seat));
	unless ($picking) {
		$self->clear;
		$self->say_to($self->render($who));
		$self->say_to(sprintf '  %s to play %s', $who, join '-', @{ $game->dice });
	}

	my $turns = $game->legal_turns;
	if ($turns->[0]->is_forfeit && @$turns == 1) {
		if ($picking) {
			$self->clear;
			$self->say_to($self->render($self->view || $who));
			$self->say_to(sprintf '  %s to play %s', $who, join '-', @{ $game->dice });
		}
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

	if ($self->picking && $self->raw) {
		my $turn = $self->_pick_turn($who, $turns);
		$self->highlight({});
		return $turn;
	}

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

sub _matching {
	my ($self, $turns, $chosen) = @_;
	my @match;
	TURN: for my $turn (@$turns) {
		my $moves = $turn->moves;
		next TURN if @$moves < @$chosen;
		for my $at (0 .. $#$chosen) {
			next TURN if $moves->[$at]->notation ne $chosen->[$at]->notation;
		}
		push @match, $turn;
	}
	return \@match;
}

sub _next_moves {
	my ($self, $match, $chosen) = @_;
	my (@move, %seen);
	for my $turn (@$match) {
		my $move = $turn->moves->[ scalar @$chosen ] or next;
		next if $seen{ $move->notation }++;
		push @move, $move;
	}
	return \@move;
}

sub _complete {
	my ($self, $match, $chosen) = @_;
	for my $turn (@$match) {
		return $turn if @{ $turn->moves } == @$chosen;
	}
	return undef;
}

sub _move_marks {
	my ($self, $view, $player, $chosen, $hover) = @_;
	my %mark;
	my $seen = sub {
		my ($point) = @_;
		return undef if $point eq 'bar' || $point eq 'off';
		return $view eq $player ? $point : 25 - $point;
	};
	for my $move (@$chosen) {
		for my $end ($move->from, $move->to) {
			my $point = $seen->($end) or next;
			$mark{$point} = 'played';
		}
	}
	if ($hover) {
		if (my $to = $seen->($hover->to)) {
			$mark{$to} = $hover->hit ? 'hit' : 'to';
		}
		if (my $from = $seen->($hover->from)) {
			$mark{$from} = 'from';
		}
	}
	return \%mark;
}

sub _pick_turn {
	my ($self, $who, $turns) = @_;
	return undef unless $self->raw;
	my $view = $self->view || $who;
	my @chosen;
	my $at = 0;
	my @notice;

	while (1) {
		my $match = $self->_matching($turns, \@chosen);
		my $next = $self->_next_moves($match, \@chosen);
		my $done = $self->_complete($match, \@chosen);
		return $done if $done && !@$next;

		$at = $#$next if $at > $#$next;
		$at = 0 if $at < 0;
		$self->highlight(
			$self->_move_marks($view, $who, \@chosen, $next->[$at])
		);
		$self->_draw_choice($who, $view, $next, $at, \@chosen, $done, \@notice);
		@notice = ();

		my $key = $self->_read_key;
		return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';

		if ($key eq 'up' || $key eq 'left' || $key eq 'k') {
			$at = ($at - 1) % @$next;
			next;
		}
		if ($key eq 'down' || $key eq 'right' || $key eq 'tab' || $key eq 'j') {
			$at = ($at + 1) % @$next;
			next;
		}
		if ($key eq 'enter' || $key eq ' ') {
			push @chosen, $next->[$at];
			$at = 0;
			next;
		}
		if ($key eq 'backspace') {
			@notice = ('nothing taken back: no move chosen yet') unless @chosen;
			pop @chosen;
			$at = 0;
			next;
		}
		if ($key =~ /\A[1-9]\z/ && $key <= @$next) {
			$at = $key - 1;
			next;
		}
		if ($key eq 'f' && $done) {
			return $done;
		}
		if ($key eq 'v') {
			$self->view($view = Game::Backgammon::Board::other($view));
			next;
		}
		if ($key eq 'q') {
			$self->highlight({});
			return undef;
		}
		if ($key eq '?') {
			@notice = @{ $self->_key_lines };
			next;
		}
		@notice = ('that key does nothing here, ? for the ones that do');
	}
}

sub _key_lines {
	return [
		'up and down choose a move, enter plays it',
		'backspace takes back the move chosen before it',
		'a digit jumps to that move, v turns the board round',
		'f finishes the turn where one can end, q stops the game',
	];
}

sub _draw_choice {
	my ($self, $who, $view, $next, $at, $chosen, $done, $notice) = @_;
	$self->clear;
	$self->say_to($self->render($view));
	$self->say_to(sprintf '  %s to play %s', $who, join '-', @{ $self->game->dice });
	$self->say_to(
		@$chosen
			? '  so far: ' . join ' ', map { $_->notation } @$chosen
			: '  nothing chosen yet'
	);
	$self->say_to('');
	$self->say_to($_) for @{ $self->_choice_lines($next, $at) };
	if ($done) {
		$self->say_to('');
		$self->say_to('  f finishes the turn here');
	}
	$self->say_to('  ' . $_) for @$notice;
	$self->say_to('');
	$self->say_to('  up and down to choose, enter to play it, ? for the keys');
	return;
}

sub _choice_lines {
	my ($self, $next, $at) = @_;
	my @lines;
	for my $index (0 .. $#$next) {
		my $move = $next->[$index];
		my $text = sprintf '%2d) %-9s %s',
			$index + 1, $move->notation, $self->_describe($move);
		$text =~ s/\s+\z//;
		push @lines, $index == $at
			? '  ' . $self->_paint("> $text", '1;7')
			: '    ' . $text;
	}
	return \@lines;
}

sub _describe {
	my ($self, $move) = @_;
	my @note;
	push @note, 'from the bar' if $move->is_bar;
	push @note, 'bears off' if $move->is_off;
	push @note, 'hits' if $move->hit;
	push @note, sprintf 'with the %d', $move->die unless @note;
	return join ', ', @note;
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
	$self->picking(0) if $self->picking && !$self->_enter_raw;

	my $interrupt = $SIG{INT};
	local $SIG{INT} = sub {
		$self->_leave_raw;
		$SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
		kill 'INT', $$;
	};

	my $played = eval { $self->_turns; 1 };
	my $error = $@;
	$self->_leave_raw;
	die $error unless $played;

	$self->clear;
	$self->highlight({});
	$self->say_to($self->render($self->mode eq 'bot' ? $self->seat : undef));
	my $r = $self->game->result;
	$self->say_to($r ? $r->stringify : 'stopped');
	return $r;
}

sub _turns {
	my ($self) = @_;
	my $guard = 0;
	while ($self->step) { last if ++$guard > 10_000 }
	return;
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

=head2 A painted board

With colour on, the points are painted light and dark the way the triangles of
a real board alternate, by the parity of the point number, and the checkers are
drawn on them. Nothing but the colour changes: the cells stay three columns
wide, the bar stays the middle column and the tray the one on the right, so the
picture is the same picture and the plain board is exactly the one above. The
bar and the tray are not points and are not painted.

L</highlight> is painted the same way, which is what lets a move be shown on
the board rather than only written in a list: where the checker leaves, where
it lands, whether that lands on a blot, and the points already used by the
moves chosen earlier in the turn.

=head2 Building a turn one checker at a time

A backgammon turn is two moves, or four on doubles, and the number of legal
turns is the number of ways those can be combined. A roll of double one from
the bar can be legal three hundred ways. Numbering three hundred turns and
asking somebody to read them is not a list anybody can use, which is what
L</offer_lines> has to do.

So on a terminal the turn is built a move at a time. At each step the moves
offered are the next move of every legal turn that starts with what has been
chosen so far, deduplicated. Three hundred turns becomes eight choices, then
three, then three, then three.

Taking the options from the legal turns, rather than from the dice and the
board, is what makes this safe. The rules oblige a player to play both dice if
any sequence plays both, and the larger die if only one can be played, so a
move that looks legal on its own can be one that leaves the rest of the turn
illegal. Because every option here is the next move of a turn the rules
already offered, no sequence of choices can reach a dead end, every legal turn
stays reachable, and what is finally played is one of the objects
C<legal_turns> returned rather than a turn assembled here and hoped for.

Backspace takes back the move before it and the options are worked out again.
Where the moves chosen so far are already a legal turn, which is how a roll
that can only be half played ends, C<f> finishes it.

This needs L<Term::ReadKey> to put the terminal into cbreak mode. Without it
L</picking> is turned off in the constructor and a turn is picked by number as
before, so the game plays with or without it and it is a recommendation rather
than a prerequisite.

=head1 ATTRIBUTES

=head2 game, in, out, mode, level, seat

C<mode> is C<bot>, C<hotseat> or C<watch>.

=head2 view

C<white>, C<black>, or empty for whoever is on roll.

=head2 ascii

C<O> and C<X> instead of the round checkers.

=head2 picking

Whether a turn is built with the keys rather than picked by number. Defaults to
L</interactive>, and is turned off in the constructor when the terminal cannot
be read a key at a time, so asking for it where it cannot work is not an error.

=head2 highlight

A hash reference, point number to the name of a colour: C<from>, C<to>, C<hit>
and C<played>. A painted board draws those points in that colour instead of the
light or dark they would have had. The keys are in the numbering of the side the
board is drawn from, which is not the mover's numbering when the board is pinned
with L</view>, so the mover's points are converted before they go in here.

=head2 raw, keysource, pending

C<raw> is whether the terminal is in cbreak mode. C<keysource> is a code
reference called with a wait flag and returning one character, which replaces
reading the terminal and is how the suite builds a turn with the keys with no
terminal to build it on. C<pending> holds characters read but not used, so that
an escape which turns out not to begin a sequence gives back the keystroke
behind it.

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
