package Game::Backgammon::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Backgammon;
use Game::Backgammon::Board ();
use Game::Backgammon::Bot;
use Getopt::Long ();
use Game::Terminal::Kit::History;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Picker;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;

our $VERSION = '0.04';

my %CHECKER = (
	white => { ascii => 'O', wide => "\x{25CB}", colour => '1;37', ink => '1;38;5;231' },
	black => { ascii => 'X', wide => "\x{25CF}", colour => '1;36', ink => '1;38;5;16' },
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

has [qw/keyboard screen log picker/] => (
	is => 'rw'
);

has highlight => (
	is => 'rw',
	isa => HashRef,
	default => sub { {} }
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

has history => (
	is => 'rw'
);

sub BUILD {
	my ($self) = @_;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !Game::Terminal::Kit::Screen::no_colour() ? 1 : 0)
		unless defined $self->colour;
	$self->keyboard(Game::Terminal::Kit::Keys->new(
		in => $self->in,
		pending => $self->pending,
		($self->keysource ? (keysource => $self->keysource) : ()),
	)) unless $self->keyboard;
	$self->screen(Game::Terminal::Kit::Screen->new(
		out => $self->out,
		interactive => $self->interactive ? 1 : 0,
		colour => $self->colour ? 1 : 0,
		ascii => $self->ascii ? 1 : 0,
	)) unless $self->screen;
	$self->log(Game::Terminal::Kit::Log->new) unless $self->log;
	$self->picker(Game::Terminal::Kit::Picker->new(
		window => 0,
		log => $self->log,
		screen => $self->screen,
	)) unless $self->picker;
	$self->history(Game::Terminal::Kit::History->new(
		save => sub { $_[0]->to_text },
		load => sub { Game::Backgammon->from_text($_[0]) },
	)) unless $self->history;
	$self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
	$self->picking(0) unless $self->_keys_available;
	$self->screen->utf8->flush_on;
	return;
}

sub say_to { my ($self, @what) = @_; $self->screen->say(join '', @what); return }

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
	return $self->screen->paint($text, $code);
}

sub clear { my ($self) = @_; $self->screen->clear; return }

sub raw { my ($self) = @_; return $self->keyboard->raw }

sub _keys_available { my ($self) = @_; return $self->keyboard->keys_available }

sub _enter_raw { my ($self) = @_; return $self->keyboard->enter_raw ? $self : undef }

sub _leave_raw { my ($self) = @_; $self->keyboard->leave_raw; return $self }

sub _read_key { my ($self) = @_; return $self->keyboard->read_key }

sub step {
	my ($self) = @_;
	my $game = $self->game;
	return 0 if $game->status ne 'active';

	my $who = $game->turn;
	my $person = $self->_at_keys($who);
	my $picking = $self->picking && $self->raw && $person;
	unless ($picking) {
		$self->clear;
		$self->say_to($self->render($who));
		$self->say_to(sprintf '  %s to play %s', $who, join '-', @{ $game->dice });
		$self->_say_notes;
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
		return $self->_played;
	}

	$self->person_turn if $person;
	my $turn = $self->_ask($who, $turns);
	return 0 unless $turn;
	return 1 unless ref $turn;
	$game->play($turn) or do { $self->say_to('  ' . $@->message); return 1 };
	$self->say_to('  ' . $turn->notation);
	return $self->_played;
}

sub _at_keys {
	my ($self, $who) = @_;
	return 1 if $self->mode eq 'hotseat';
	return $self->mode eq 'bot' && $who eq $self->seat ? 1 : 0;
}

sub _played {
	my ($self) = @_;
	return 1 if $self->game->status eq 'active';
	$self->person_turn unless $self->mode eq 'watch';
	return 0;
}

sub _say_notes {
	my ($self) = @_;
	$self->say_to("  $_") for $self->log->lines;
	$self->log->shown;
	return;
}

sub person_turn {
	my ($self) = @_;
	$self->history->turn($self->game);
	return $self;
}

sub take_back {
	my ($self) = @_;
	my $game = $self->history->undo;
	return $self->_notify('There is nothing to take back.') unless $game;
	$self->swap($game);
	$self->_notify('Taken back.');
	return 1;
}

sub play_again {
	my ($self) = @_;
	my $game = $self->history->redo;
	return $self->_notify('There is nothing to play again.') unless $game;
	$self->swap($game);
	$self->_notify('Played again.');
	return 1;
}

sub swap {
	my ($self, $game) = @_;
	$self->game($game);
	$self->highlight({});
	$self->log->forget;
	return $self;
}

sub _notify {
	my ($self, $line) = @_;
	$self->log->note($line);
	return 0;
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
	while (1) {
		my $line = $self->keyboard->read_line("  $who> ", $self->out);
		return undef unless defined $line;
		return undef if $line eq 'q' || $line eq 'quit';
		if ($line eq 'undo' || $line eq 'redo') {
			return 'swapped' if $line eq 'undo' ? $self->take_back : $self->play_again;
			$self->_say_notes;
			next;
		}
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

sub _move_items {
	my ($self, $next) = @_;
	return [ map { { label => $_->notation, about => $self->_describe($_), value => $_ } } @$next ];
}

sub _pick_turn {
	my ($self, $who, $turns) = @_;
	return undef unless $self->raw;
	my $view = $self->view || $who;
	my $picker = $self->picker;
	my $log = $self->log;
	my (@chosen, $done);
	my $fresh = 1;

	while (1) {
		if ($fresh) {
			my $match = $self->_matching($turns, \@chosen);
			my $next = $self->_next_moves($match, \@chosen);
			$done = $self->_complete($match, \@chosen);
			return $done if $done && !@$next;
			$picker->reset($self->_move_items($next));
			$picker->game_keys({
				k => 'up', j => 'down', v => 'view', '?' => 'help',
				%{ Game::Terminal::Kit::History->game_keys },
				($done ? (f => 'finish') : ()),
			});
			$fresh = 0;
		}

		$self->highlight(
			$self->_move_marks($view, $who, \@chosen, $picker->current)
		);
		$self->_draw_choice($who, $view, $picker, \@chosen, $done);

		my ($event, $value) = $picker->step($self->_read_key);
		if ($event eq 'quit') {
			$self->highlight({});
			return undef;
		}
		if ($event eq 'chosen') {
			push @chosen, $value;
			$fresh = 1;
			next;
		}
		if ($event eq 'back') {
			$log->note('nothing taken back: no move chosen yet') unless @chosen;
			pop @chosen;
			$fresh = 1;
			next;
		}
		next unless $event eq 'key';
		return $done if $value eq 'finish';
		if ($value eq 'undo' || $value eq 'redo') {
			next unless $value eq 'undo' ? $self->take_back : $self->play_again;
			$log->note('The moves chosen this turn were dropped.') if @chosen;
			return 'swapped';
		}
		$picker->move($value eq 'up' ? -1 : 1) if $value eq 'up' || $value eq 'down';
		$self->view($view = Game::Backgammon::Board::other($view)) if $value eq 'view';
		$log->note(@{ $self->_key_lines }) if $value eq 'help';
	}
}

sub _key_lines {
	return [
		'up and down choose a move, enter plays it',
		'backspace or escape takes back the move chosen before it',
		'a digit jumps to that move, v turns the board round',
		'f finishes the turn where one can end, q stops the game',
		'u takes back your last turn, r plays it again',
	];
}

sub _draw_choice {
	my ($self, $who, $view, $picker, $chosen, $done) = @_;
	my $log = $self->log;
	$self->screen->show([
		@{ $self->board_lines($view) },
		sprintf('  %s to play %s', $who, join '-', @{ $self->game->dice }),
		(@$chosen
			? '  so far: ' . join ' ', map { $_->notation } @$chosen
			: '  nothing chosen yet'),
		'',
		(map { " $_" } $picker->rows),
		($done ? ('', '  f finishes the turn here') : ()),
		(map { "  $_" } $log->lines),
		'',
		'  up and down to choose, enter to play it, ? for the keys',
	]);
	$log->shown;
	return;
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

sub start {
	my ($self) = @_;
	$self->game(Game::Backgammon->new(seed => $self->_seed)) unless $self->game;
	$self->history->start($self->game);
	$self->picking(0) if $self->picking && !$self->_enter_raw;

	Game::Terminal::Kit::Run::guard(sub { $self->_turns }, $self->keyboard, $self->screen);

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

sub _usage {
	return <<'USAGE';
backgammon [--mode bot|hotseat|watch] [--level 1-3] [--seat white|black]
           [--view white|black] [--ascii] [--no-colour] [--no-pick]

  bot       play the computer (the default)
  hotseat   two people at one keyboard
  watch     the computer against itself

  --view    pin the board to one side's numbering. By default it is drawn
            from the side on roll, because a turn is written in the mover's
            own numbers and the board should agree with the list.
  --ascii   O and X instead of the round checkers.
  --no-pick choose a whole turn by number from the list, as 0.01 did, rather
            than one checker at a time with the keys.
  --help    this

The board is the usual one: your home board is the bottom right quarter and
you run into it anticlockwise, the bar is the middle column and the tray the
one on the right.

On a terminal a turn is built one checker at a time: the moves you can make
with the dice you have left are listed, up and down choose one and enter plays
it, backspace or escape takes the last one back, and the board shows where the checker
under the cursor is going. A roll that can be played three hundred ways is
still only a handful of choices at each step. v turns the board round, u takes
back your last turn and r plays it again, and q stops. Without a terminal, or
with --no-pick, every legal turn is numbered and you pick one, or type undo or
redo.

Exit status is 0 when the game ended or was stopped, 2 for an option the game
will not take.
USAGE
}

sub options {
	return [
		{ name => 'mode', type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the program, two people at one keyboard, or two programs' },
		{ name => 'level', type => 'int', min => 1, max => 3, help => 'how hard the program plays' },
		{ name => 'seat', type => 'enum', choices => [qw(white black)], help => 'your side' },
	];
}

sub run {
	my ($class, @argv) = @_;
	my %o = (mode => 'bot', level => 3, seat => 'white', view => '', ascii => 0);
	my ($colour, $pick, $help);

	my $ok = eval {
		local $SIG{__WARN__} = sub { print STDERR "backgammon: $_[0]" };
		Getopt::Long::GetOptionsFromArray(\@argv,
			'mode=s'  => \$o{mode},
			'level=i' => \$o{level},
			'seat=s'  => \$o{seat},
			'view=s'  => \$o{view},
			'ascii'   => \$o{ascii},
			'colour!' => \$colour,
			'pick!'   => \$pick,
			'help'    => \$help,
		);
	};
	if (!$ok) { print STDERR _usage(); return 2 }
	if ($help) { print _usage(); return 0 }
	if (@argv) { print STDERR "backgammon: not an option: $argv[0]\n", _usage(); return 2 }

	my %refused = (
		mode  => [ qr/\A(?:bot|hotseat|watch)\z/, 'bot, hotseat or watch' ],
		seat  => [ qr/\A(?:white|black)\z/, 'white or black' ],
		view  => [ qr/\A(?:white|black|)\z/, 'white or black' ],
		level => [ qr/\A[123]\z/, '1 to 3' ],
	);
	for my $k (qw(mode seat view level)) {
		next if $o{$k} =~ $refused{$k}[0];
		print STDERR "backgammon: --$k takes $refused{$k}[1], not '$o{$k}'\n", _usage();
		return 2;
	}

	my $terminal = $class->new(
		%o,
		(defined $colour ? (colour => $colour) : ()),
		(defined $pick ? (picking => $pick) : ()),
	);

	my $result = Game::Terminal::Kit::Run::guard(
		sub { $terminal->start }, $terminal->keyboard, $terminal->screen,
	);
	return 1 if $result && $terminal->mode eq 'bot' && $result->winner ne $terminal->seat;
	return 0;
}

1;

__END__

=head1 NAME

Game::Backgammon::Terminal - the game at a prompt

=head1 SYNOPSIS

    use Game::Backgammon::Terminal;

    Game::Backgammon::Terminal->new(mode => 'bot', level => 3)->start;

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
only when the session is interactive and C<NO_COLOR> is unset or empty.

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

Backspace or escape takes back the move before it and the options are worked
out again. Home and end go to the first and the last move offered.
Where the moves chosen so far are already a legal turn, which is how a roll
that can only be half played ends, C<f> finishes it.

=head2 Taking a turn back

C<u> takes back your last turn and the bot's reply to it, back to the board
and the dice you had then, and C<r> plays it again; with no picker, the typed
words C<undo> and C<redo> do the same. The dice that follow are the dice that
followed before, because they come from the game's seed. Against the bot a step
is one of your turns with everything the bot played after it; in C<hotseat>
every turn is a step; in C<watch> there is nothing to take back. A turn that is
forced to pass is not a step of its own. C<u> is a whole turn: the moves chosen
so far in the turn being built are dropped, and the note under the list says so,
where backspace and escape take back one of them. When there is nothing to take
back or play again a note says so and nothing changes.

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

=head2 keysource, pending

C<keysource> is a code reference called with a wait and returning one
character, which replaces reading the terminal and is how the suite builds a
turn with the keys with no terminal to build it on. C<pending> holds characters
read but not used, so that an escape which turns out not to begin a sequence
gives back the keystroke behind it. Both are given to L</keyboard> when it is
built.

=head2 colour, interactive

Both default from C<in>: colour when it is a terminal and C<NO_COLOR> is
unset or empty, and the screen is only cleared between turns for a person, so a
captured transcript stays readable. Both are given to L</screen> when it is
built.

=head2 keyboard

The L<Game::Terminal::Kit::Keys> the keys and the typed lines are read through,
built from L</in>, C<keysource> and C<pending>.

=head2 screen

The L<Game::Terminal::Kit::Screen> everything is written through, built from
L</out>, L</interactive>, L</colour> and L</ascii>.

=head2 log

The L<Game::Terminal::Kit::Log> holding what the picker has to say under its
list: the keys when they are asked for, and a key that did nothing.

=head2 picker

The L<Game::Terminal::Kit::Picker> a turn is built with. It is given the next
moves afresh at every step of the turn.

=head2 history

The L<Game::Terminal::Kit::History> the turns are kept in, as L<Game::Backgammon/to_text>,
built in C<new> unless one is given.

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

=head2 raw

Whether the terminal is being read a key at a time.

=head2 step

Play one turn. Returns true while the game is still on.

=head2 person_turn

Called by L</step> when the turn passes to a person at the keys, and once when
the game ends unless nobody is: keeps the game in L</history> as a turn.

=head2 take_back

The C<u> key and the C<undo> word: your last turn and the replies to it, taken
back. Returns 1, or 0 when there is nothing to take back.

=head2 play_again

The C<r> key and the C<redo> word: the turn L</take_back> took back, played
again. Returns 1, or 0 when there is nothing to play again.

=head2 swap($game)

Puts another game in place of this one, clearing L</highlight> and what the
picker had to say.

=head2 start

Play until the game ends or the player stops. Starts a new L</history> for
the game. Returns the
L<Game::Backgammon::Result>, or undef if it was stopped.

=head2 options

    my $fields = Game::Backgammon::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<mode>

One of C<bot>, C<hotseat>, C<watch>: you against the program, two people at one keyboard, or two programs.

=item C<level>

A whole number from 1 to 3: how hard the program plays.

=item C<seat>

One of C<white>, C<black>: your side.

=back

=head2 run

    exit Game::Backgammon::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options
F<bin/backgammon> documents, builds the terminal, plays, and returns the exit
status rather than calling C<exit>: C<0> when the game ended or was stopped,
C<2> for a bad option or a refused value, with the reason and the usage on
C<STDERR>. C<--help> prints the usage on C<STDOUT> and returns C<0>. Signal
handlers are local to the call and the terminal is left in cooked mode on
every way out, so a launcher such as L<Game::Terminal> can call it in its own
process and carry on afterwards. Colour is off under C<NO_COLOR> as well as
off a terminal.

=head2 say_to(@what)

Write a line to C<out>.

=cut
