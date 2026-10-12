package Game::Reversi::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Bot;
use Game::Reversi::Notation;
use Game::Reversi::Opening;
use Getopt::Long ();

our $VERSION = '0.03';

my %GLYPH = (
	b => { wide => "\x{25CF}", ascii => 'X' },
	w => { wide => "\x{25CB}", ascii => 'O' },
);

my %TURNED = (
	b => { wide => "\x{25C9}", ascii => 'x' },
	w => { wide => "\x{25CE}", ascii => 'o' },
);
my %NAME  = (b => 'dark', w => 'light');

my %LINE = (
	wide  => { h => "\x{2500}", v => "\x{2502}", tl => "\x{250C}", tr => "\x{2510}",
	           bl => "\x{2514}", br => "\x{2518}", t => "\x{252C}", b => "\x{2534}",
	           l => "\x{251C}", r => "\x{2524}", x => "\x{253C}" },
	ascii => { h => '-', v => '|', tl => '+', tr => '+', bl => '+', br => '+',
	           t => '+', b => '+', l => '+', r => '+', x => '+' },
);

my %INK = (b => "\e[1m", w => "\e[2m", '*' => "\e[33m", grid => "\e[2m",
           turned => "\e[1;32m", placed => "\e[1;36m", cursor => "\e[1;7m");
my $OFF = "\e[0m";

has in => (
	is      => 'rw',
	isa     => Any,
	default => sub { \*STDIN }
);

has out => (
	is      => 'rw',
	isa     => Any,
	default => sub { \*STDOUT }
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has variant => (
	is      => 'ro',
	isa     => Str,
	default => 'historic'
);

has colour => (
	is      => 'ro',
	isa     => Str,
	default => 'b'
);

has seed => (
	is      => 'ro',
	default => 'terminal'
);

has [qw/quiet ascii/] => (
	is      => 'rw',
	isa     => Bool,
	default => 0
);

has game => (
	is  => 'rw',
	isa => Any
);

has last_move => (is => 'rw');

has raw => (is => 'rw', default => 0);

has keysource => (is => 'rw');

has pending => (is => 'rw', default => sub { [] });

has _picking => (is => 'rw', init_arg => 'picking', private => 1);

our %SEQUENCE = (
	'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
	'H' => 'home', 'F' => 'end',
	'1~' => 'home', '4~' => 'end', '5~' => 'page_up', '6~' => 'page_down',
	'7~' => 'home', '8~' => 'end',
);

our %CONTROL = (
	"\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
	"\x7f" => 'backspace', "\x08" => 'backspace',
	"\x03" => 'interrupt', "\x04" => 'eof',
);

has _wants_ansi => (
	is       => 'rw',
	init_arg => 'ansi',
	private  => 1
);

sub BUILD {
	my ($self) = @_;

	binmode $self->out, ':encoding(UTF-8)' unless $self->ascii;
	my $previous = select $self->out;
	$| = 1;
	select $previous;

	die "Game::Reversi::Terminal: colour must be b or w"
		unless $self->colour eq 'b' || $self->colour eq 'w';
	die "Game::Reversi::Terminal: there is no variant '" . $self->variant . "'"
		unless Game::Reversi::Opening->describes($self->variant);

	die 'Game::Reversi::Terminal: there is no level ' . $self->level
		unless grep { $_ == $self->level } Game::Reversi::Bot->levels;

	return $self;
}

sub ansi {
	my ($self) = @_;
	return 0 if defined $ENV{NO_COLOR} && length $ENV{NO_COLOR};
	return $self->_wants_ansi ? 1 : 0 if defined $self->_wants_ansi;
	return -t $self->out ? 1 : 0;
}

sub _paint {
	my ($self, $glyph, $key) = @_;
	return $glyph unless $self->ansi;
	return ($INK{$key} || '') . $glyph . $OFF;
}

sub _say {
	my ($self, @lines) = @_;
	my $fh = $self->out;
	print {$fh} $_, "\n" for @lines;
	return;
}

sub _ask {
	my ($self, $prompt) = @_;
	my $fh = $self->out;
	print {$fh} $prompt;
	my $in = $self->in;
	my $line = <$in>;
	return undef unless defined $line;

	print {$fh} "\n";

	$line =~ s/\A\s+|\s+\z//g;
	return lc $line;
}

sub glyph {
	my ($self, $colour) = @_;
	return $GLYPH{$colour}{ $self->ascii ? 'ascii' : 'wide' };
}

sub board_text {
	my ($self, $game, $colour, %o) = @_;
	my %legal = map { $_->square => 1 }
	            @{ defined $colour ? $game->legal($colour) : [] };
	my %flipped = map { $_ => 1 } @{ $o{flips} || [] };
	my $line = $LINE{ $self->ascii ? 'ascii' : 'wide' };
	my $kind = $self->ascii ? 'ascii' : 'wide';

	my $files = '     ' . join '   ', 'a' .. 'h';
	my $rule = sub {
		my ($left, $join, $right) = @_;
		return '   ' . $self->_paint(
			$left . join($join, ($line->{h} x 3) x 8) . $right, 'grid');
	};

	my @lines = ($files, $rule->(@{$line}{qw/tl t tr/}));
	for my $row (0 .. 7) {
		my $rank = 8 - $row;
		my @cells;
		for my $col (0 .. 7) {
			my $square = $row * 8 + $col;
			my $cell = $game->board->[$square];
			push @cells, $self->_cell($square, $cell, $kind, \%legal,
				\%flipped, %o);
		}
		my $bar = $self->_paint($line->{v}, 'grid');
		push @lines, " $rank " . $bar . join($bar, @cells) . $bar . " $rank";
		push @lines, $rule->(@{$line}{qw/l x r/}) unless $row == 7;
	}
	push @lines, $rule->(@{$line}{qw/bl b br/}), $files;
	return @lines;
}

sub since {
	my ($self) = @_;
	my $move = $self->last_move or return ();
	return (last => $move->square, flips => $move->flips);
}

sub remember {
	my ($self, $move) = @_;
	$self->last_move(ref $move && $move->can('square') ? $move : undef);
	return $self;
}

sub _cell {
	my ($self, $square, $cell, $kind, $legal, $flipped, %o) = @_;

	my $cursor = defined $o{cursor} && $o{cursor} == $square;
	my $placed = defined $o{last} && $o{last} == $square;

	if ($cursor) {
		my $face = defined $cell ? $self->glyph($cell)
			: $o{to_play} ? $GLYPH{ $o{to_play} }{$kind} : '*';
		return $self->_paint('>' . $face . '<', 'cursor');
	}

	return $self->_paint('[' . $self->glyph($cell) . ']', 'placed')
		if $placed && defined $cell;

	return ' ' . $self->_paint($TURNED{$cell}{$kind}, 'turned') . ' '
		if defined $cell && $flipped->{$square};

	return ' ' . (defined $cell ? $self->_paint($self->glyph($cell), $cell)
		: $legal->{$square} ? $self->_paint('*', '*')
		: ' ') . ' ';
}

sub start {
	my ($self) = @_;

	my $game = Game::Reversi->new(
		variant => $self->variant, seed => $self->seed);
	$self->game($game);
	my $bot = Game::Reversi::Bot->new(
		level => $self->level, seed => $self->seed . ':bot');
	my $me = $self->colour;

	$self->_intro;
	my $seen = scalar @{ $game->events };

	while ($game->status eq 'active') {
		my $turn = $game->turn;

		if ($turn eq $me) {
			my $quit = $self->_human_turn($game, $me);
			if ($quit) {
				$game->resign($me);
				last;
			}
		}
		else {
			my $move = $bot->choose($game, $turn);
			last unless $move;
			my $done = $game->play($turn, $move->square);
			$self->remember($done);
			$self->_say('', $NAME{$turn} . ' plays ' . $move->name
				. ', turning ' . $move->turned
				. ($move->turned == 1 ? ' disc' : ' discs'))
				if $move->phase eq 'play';
			$self->_say('', $NAME{$turn} . ' places on ' . $move->name)
				if $move->phase eq 'place';
		}

		$seen = $self->_announce_passes($game, $seen);
	}

	$self->_finish($game);
	return $game->result;
}

sub _intro {
	my ($self) = @_;
	my $me = $self->colour;
	$self->_say(
		'Reversi. You are ' . $self->glyph($me) . ', ' . $NAME{$me} . '.',
		$self->variant eq 'historic'
			? 'The historic opening: the first four discs are placed by the '
			  . 'players, on the centre four, and turn nothing.'
			: 'The Othello opening: four discs are already on the board.',
		'Enter a square such as d3. "help" for help, "quit" to give up.',
	) unless $self->quiet;
	return;
}

sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless eval { -t $self->in };
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub picking {
	my ($self, @set) = @_;
	$self->_picking($set[0] ? 1 : 0) if @set;
	return 0 if $self->quiet;
	return $self->_picking ? 1 : 0 if defined $self->_picking;
	return $self->keys_available;
}

sub enter_raw {
	my ($self) = @_;
	return $self if $self->raw;
	if ($self->keysource) { $self->raw(1); return $self }
	return undef unless $self->keys_available;
	return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
	$self->raw(1);
	return $self;
}

sub leave_raw {
	my ($self) = @_;
	return $self unless $self->raw;
	eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
	$self->raw(0);
	return $self;
}

sub read_char {
	my ($self, $wait) = @_;
	my $pending = $self->pending;
	return shift @$pending if @$pending;
	return $self->keysource->($wait) if $self->keysource;
	my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
	return $char if defined $char || $wait;
	select undef, undef, undef, 0.05;
	return Term::ReadKey::ReadKey(-1, $self->in);
}

sub read_key {
	my ($self) = @_;
	my $char = $self->read_char(1);
	return undef unless defined $char;
	return $CONTROL{$char} if $CONTROL{$char};
	return $self->read_sequence if $char eq "\e";
	return $char;
}

sub read_sequence {
	my ($self) = @_;
	my $opener = $self->read_char(0);
	return 'escape' unless defined $opener;
	unless ($opener eq '[' || $opener eq 'O') {
		unshift @{ $self->pending }, $opener;
		return 'escape';
	}
	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->read_char(0);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ /[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'escape';
}

sub interactive {
	my ($self) = @_;
	my $out = $self->out or return 0;
	return (eval { -t $out }) ? 1 : 0;
}

sub clear {
	my ($self) = @_;
	return $self unless $self->interactive;
	my $fh = $self->out;
	print {$fh} "\e[2J\e[3J\e[H";
	return $self;
}

sub square_line {
	my ($self, $game, $me, $square) = @_;

	my $name = Game::Reversi::Board->name_of($square);
	my $trial = $game->clone;
	my $move = $trial->play($me, $square);

	return "$name: " . $move->message
		if ref $move && $move->isa('Game::Reversi::Error');

	return "$name: placed, turning nothing yet" if $move->phase eq 'place';

	my $count = $trial->counts;
	return sprintf '%s: turns %d %s, and you would be %d to %d',
		$name, $move->turned, ($move->turned == 1 ? 'disc' : 'discs'),
		$count->{$me}, $count->{ $me eq 'b' ? 'w' : 'b' };
}

sub pick_help {
	return (
		'arrows walk the squares marked *, which are the only ones that play.',
		'the line under the board says what the move would turn.',
		'enter plays it, t goes back to typing, q gives up.',
	);
}

sub pick_square {
	my ($self, $game, $me) = @_;

	my @legal = sort { $a <=> $b } map { $_->square } @{ $game->legal($me) };
	return $self->_typed_turn($game, $me) unless @legal;

	my $at = 0;
	if (my $last = $self->last_move) {
		my ($near) = sort { abs($a - $last->square) <=> abs($b - $last->square) }
			0 .. $#legal;
		$at = $near if defined $near;
	}

	my @notice;

	while (1) {
		my $count = $game->counts;
		$self->clear;
		$self->_say('', $self->board_text($game, $me, $self->since,
			cursor => $legal[$at], to_play => $me));
		$self->_say('  discs: ' . $self->glyph(q{b}) . ' ' . $count->{b}
			. '   ' . $self->glyph(q{w}) . ' ' . $count->{w});
		$self->_say('  ' . $self->square_line($game, $me, $legal[$at]));
		$self->_say('  ' . $_) for @notice;
		@notice = ();
		$self->_say('  ' . $self->_paint(
			'arrows to choose, enter to play, ? for the keys', 'grid'));

		my $key = $self->read_key;
		return 1 if !defined $key || $key eq 'eof' || $key eq 'interrupt';

		if ($key eq 'left' || $key eq 'up') { $at = ($at - 1) % @legal; next }
		if ($key eq 'right' || $key eq 'down' || $key eq 'tab') {
			$at = ($at + 1) % @legal;
			next;
		}
		if ($key eq 'home') { $at = 0;        next }
		if ($key eq 'end')  { $at = $#legal;  next }

		if ($key eq 'enter' || $key eq ' ') {
			my $played = $game->play($me, $legal[$at]);
			if (ref $played && $played->isa('Game::Reversi::Error')) {
				@notice = ($played->message . '.');
				next;
			}
			$self->remember($played);
			$self->_say('  you play ' . $played->name
				. ($played->phase eq 'play'
					? ', turning ' . $played->turned
					  . ($played->turned == 1 ? ' disc' : ' discs')
					: ''));
			return 0;
		}

		if ($key eq 'q') { return 1 }
		if ($key eq 't') { $self->picking(0); return $self->_typed_turn($game, $me) }
		if ($key eq '?') { @notice = $self->pick_help; next }

		@notice = ('that key does nothing here. ? for the ones that do');
	}
}

sub _human_turn {
	my ($self, $game, $me) = @_;

	if ($self->picking) {
		return $self->pick_square($game, $me) if $self->enter_raw;
		$self->picking(0);
	}

	return $self->_typed_turn($game, $me);
}

sub _typed_turn {
	my ($self, $game, $me) = @_;

	while (1) {
		my $count = $game->counts;
		$self->_say("", $self->board_text($game, $me, $self->since));
		$self->_say(
			'  discs: ' . $self->glyph(q{b}) . ' ' . $count->{b} . '   '
				. $self->glyph(q{w}) . ' ' . $count->{w},
			'  ' . ($game->phase eq 'opening'
				? 'Place a disc on one of the centre four.'
				: 'Your move. The squares marked * are the ones that outflank something.'),
		);

		my $answer = $self->_ask('  > ');

		return 1 unless defined $answer;
		return 1 if $answer eq 'quit' || $answer eq 'resign';

		if ($answer eq 'help') {
			$self->_help($game, $me);
			next;
		}
		if ($answer eq 'board' || $answer eq '') {
			next;
		}

		my $square = Game::Reversi::Notation->text_to_square($answer);
		if (!defined $square) {
			$self->_say('  "' . $answer . '" is not a square. Try d3, or "help".');
			next;
		}

		my $played = $game->play($me, $square);
		$self->remember($played) unless ref $played && $played->isa("Game::Reversi::Error");
		if (ref $played && $played->isa('Game::Reversi::Error')) {
			$self->_say('  ' . $played->message . '.');
			next;
		}

		$self->_say('  you play ' . $played->name
			. ($played->phase eq 'play'
				? ', turning ' . $played->turned
				  . ($played->turned == 1 ? ' disc' : ' discs')
				: ''));
		return 0;
	}
}

sub _help {
	my ($self, $game, $me) = @_;
	$self->_say(
		'',
		'  Enter a square as a file and a rank, such as d3 or f5.',
		'  A move must outflank at least one of the other side\'s discs;',
		'  every disc it outflanks is turned, and you do not get to choose.',
		'  The squares marked * are the ones you can play.',
		'  A turn with no legal move is forfeited for you automatically.',
		'  The game ends when neither side can move, which can happen with',
		'  the board not full. "quit" gives up.',
		'',
	);
	return;
}

sub _announce_passes {
	my ($self, $game, $seen) = @_;
	my $events = $game->events;
	for my $i ($seen .. $#$events) {
		my $event = $events->[$i];
		next unless $event->{kind} eq 'pass';
		my $colour = $event->{payload}{colour};
		$self->_say('  ' . $NAME{$colour} . ' has no legal move, so that turn is '
			. 'forfeited and the other side plays again.');
	}
	return scalar @$events;
}

sub _finish {
	my ($self, $game) = @_;
	my $result = $game->result;
	return unless $result;

	$self->_say('', $self->board_text($game, undef), '');

	my $count = $result->counts;
	$self->_say('  discs on the board: ' . $self->glyph(q{b}) . ' ' . $count->{b}
		. '   ' . $self->glyph(q{w}) . ' ' . $count->{w});

	my $score = $result->score;
	if ($score) {
		my $empty = Game::Reversi::Board->empties($game->board);
		$self->_say('  final score:        ' . $self->glyph(q{b}) . ' ' . $score->{b}
			. '   ' . $self->glyph(q{w}) . ' ' . $score->{w}
			. ($empty ? "   (the $empty empty squares go to the winner)" : ''));
	}

	my $me = $self->colour;
	$self->_say('', !defined $result->winner ? '  A tie.'
		: $result->winner eq $me ? '  You win.'
		: '  You lose.');
	$self->_say('  (' . $result->result . ')') unless $result->natural;
	return;
}

sub _usage {
	return <<'USAGE';
reversi - play Reversi in a terminal

    reversi [--level 1..5] [--variant historic|othello]
            [--colour b|w] [--seed STRING] [--ascii]

  --level    how hard the opponent is, 1 to 5. Default 3.
  --variant  historic, the real Reversi opening where the players place the
             first four discs themselves, or othello, where those four are
             already down. Default historic.
  --colour   b to play dark and move first, w to play light. Default b.
  --seed     makes a game reproducible, and decides how the bot opens.
  --ascii    X and O on a plain grid, for a terminal without box characters.
  --nopick   type the squares out instead of pointing at them.

  On a terminal the arrow keys walk the squares marked *, which are the only
  ones that play, and the line under the board says what the move would turn
  and what the score would become. Enter plays it, t goes back to typing and
  ? lists the keys. Needs Term::ReadKey; without it the squares are typed.

  The square the last move went on is bracketed and the discs it turned are
  drawn ringed, so both are visible with --ascii and with colour off.

  Exit status is 0 if you won or tied, 1 if you lost, 2 for a bad option.
USAGE
}

sub run {
	my ($class, @argv) = @_;
	my %opt = (level => 3, variant => 'historic', colour => 'b', seed => 'reversi');

	my $ok = eval {
		local $SIG{__WARN__} = sub { print STDERR "reversi: $_[0]" };
		Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
			'level=i', 'variant=s', 'colour=s', 'seed=s', 'ascii', 'pick!', 'help|h');
	};
	if (!$ok) { print STDERR _usage(); return 2 }
	if ($opt{help}) { print _usage(); return 0 }
	if (@argv) { print STDERR "reversi: not an option: $argv[0]\n", _usage(); return 2 }

	$opt{colour} = 'b' if lc $opt{colour} eq 'dark'  || lc $opt{colour} eq 'black';
	$opt{colour} = 'w' if lc $opt{colour} eq 'light' || lc $opt{colour} eq 'white';

	my $terminal = eval {
		$class->new(
			level => $opt{level}, variant => $opt{variant},
			colour => $opt{colour}, seed => $opt{seed},
			ascii => $opt{ascii},
			(defined $opt{pick} ? (picking => $opt{pick} ? 1 : 0) : ()));
	};
	if (!$terminal) {
		my $why = $@ || "could not start\n";
		$why =~ s/ at \S+ line \d+\.?\n?\z//;
		$why =~ s/\AGame::Reversi(?:::\w+)*: //;
		chomp $why;
		print STDERR "reversi: $why\n";
		return 2;
	}

	local @SIG{qw(INT TERM HUP)};
	for my $sig (qw(INT TERM HUP)) {
		$SIG{$sig} = sub { $terminal->leave_raw; $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
	}

	my $result = eval { $terminal->start };
	my $died = $@;
	$terminal->leave_raw;
	die $died if $died;
	return 0 unless $result;
	return 0 if !defined $result->winner;
	return 0 if $result->winner eq $opt{colour};
	return 1;
}


1;

__END__

=encoding utf8

=head1 NAME

Game::Reversi::Terminal - a playable game on two filehandles

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $terminal = Game::Reversi::Terminal->new(
        level => 3, variant => 'historic', colour => 'b');

    my $result = $terminal->start;    # returns, never exits

    # and in a test, with no pipe and no subprocess:
    my $terminal = Game::Reversi::Terminal->new(in => $in, out => $out);

=head1 DESCRIPTION

A person against L<Game::Reversi::Bot>, on a board drawn in text.

The distribution ships something playable because a rules engine nobody can play
is a rules engine nobody has checked. This one found two faults during phase 06
that the suite had not.

=head2 It is separate from the engine on purpose

L<Game::Cribbage> put about a thousand lines of escape codes in the top level
namespace module, which is why only its C<::Board> ever turned out to be
reusable. The top level module here is the engine, and this is a consumer of it
exactly as a web adapter would be. The suite asserts that the engine can be
loaded without pulling this in.

=head2 in and out are properties

Defaulting to C<STDIN> and C<STDOUT>. That is what makes a terminal testable: the
suite drives a whole game in process against in memory handles, with no pipe, no
fork, and no subprocess writing into the TAP stream.

=head2 start returns, and never exits

A module that calls C<exit> cannot be tested and cannot be embedded. The exit
status belongs to C<bin/reversi>, which is the only part that knows it is a
program.

=head2 The board

	     a   b   c   d   e   f   g   h
	   ┌───┬───┬───┬───┬───┬───┬───┬───┐
	 8 │   │   │   │   │   │   │   │   │ 8
	   ├───┼───┼───┼───┼───┼───┼───┼───┤
	 ...
	 5 │   │   │   │ ● │ ○ │ * │   │   │ 5
	   ├───┼───┼───┼───┼───┼───┼───┼───┤
	 4 │   │   │ * │ ○ │ ● │   │   │   │ 4
	 ...
	   └───┴───┴───┴───┴───┴───┴───┴───┘
	     a   b   c   d   e   f   g   h

A ruled grid with the discs sitting in it, because a reversi board is a grid
and eight rows of dots are a list. C<ascii> draws the same board as C<X> and
C<O> on C<+-|>, for a terminal that cannot manage the rest.

=head2 Two glyphs, not one glyph in two colours

Two discs told apart only by an escape code are indistinguishable in half the
terminals in the world and unreadable to a good fraction of the people using the
other half. A filled disc and a hollow one are as far apart on a screen as they
are on a table, and they are still that far apart with no colour at all. So the
glyphs carry all of the information and colour carries none: strip the escapes
and the board reads exactly the same.

Colour is off unless the output is a terminal, and off regardless if C<NO_COLOR>
is set to anything non-empty. An explicit C<ansi> option overrides the terminal
check but not C<NO_COLOR>, because somebody who set that meant it.

=head2 Every option is validated in the constructor, including the level

This distribution is the cautionary tale four of its siblings' POD cite: it
validated its variant three calls deeper than the constructor and shipped a
C<--variant draughts> that died with a raw Perl message and a useless exit
status.

That was fixed for the variant and B<left for the level>, which lived in
L<Game::Reversi::Bot> and so was not checked until C<start> built one, outside
F<bin/reversi>'s C<eval>. C<--level 9> died with a file and a line number at
exit 25, one option along from the bug this dist is quoted for. Both are
checked in C<BUILD> now, and F<t/20-terminal.t> asserts the level refusal
carries no file and no line.

=head2 What the last move did, in characters

Every cell is three characters wide, which is a glyph and a character either
side of it to spend. They are spent rather than left as padding: the square
the last move was placed on is B<bracketed>, C<[●]>, and the discs it turned
are drawn B<ringed>, C<◉> and C<◎>, against C<●> and C<○> for discs that were
already there.

B<That is not decoration in this game.> The flipped discs are the move. The
narration said "turning 3 discs" and the board that followed said neither
which disc was new nor which three had changed hands, so the one thing a
Reversi player needs to see was the one thing not drawn.

Both marks are characters, so they survive C<--ascii>, C<NO_COLOR> and a
redirected handle. Colour is laid over them as a second telling, never as the
only one.

=head2 You point at the move you mean

On a terminal with L<Term::ReadKey> installed the arrow keys walk a cursor
over the board, return plays the square it is on, C<t> goes back to typing,
C<?> lists the keys and C<q> gives up. Without L<Term::ReadKey>, off a
terminal, or under C<--nopick>, the squares are typed as before.

B<The cursor walks the starred squares and nothing else>, in reading order.
That is the difference from L<Game::Go::Terminal>, where every point is a
candidate and the cursor is free: measured over 2400 turns, Reversi offers
between one and fifteen legal moves and eight or fewer on 71% of turns. They
are already marked on the board, so a cursor crawling the other fifty squares
would spend most of its time on squares that refuse.

=head2 What the square under the cursor says

One line, from the engine rather than from arithmetic here:

    d3: turns 3 discs, and you would be 5 to 2

The square is played on a B<clone> and the clone is asked, so nothing moves
and the numbers are the ones the game will really produce. A clone is 0.003 ms,
so the line is recomputed on every keystroke without anybody noticing, and
F<t/20-terminal.t> checks both halves against a second game that plays the move
for real.

=head1 METHODS

=head2 new

C<in>, C<out>, C<level>, C<variant>, C<colour>, C<seed>, C<quiet>, C<ansi>,
C<ascii>.

=head2 ansi

Whether colour will be used.

=head2 in, out, game

The handles, and the game once C<start> has built one. All three are read and
write: a test hands this a tied handle and reads the game back out of it.

The C<ansi> option is held privately, because L</ansi> is a question about the
handle and the environment as well as the option, and there should be one
public answer to it rather than two.

=head2 level, variant, colour, seed, quiet, ascii

The options, as properties. C<colour> is the side the person is playing.

=head2 glyph

The disc a colour is drawn as, which C<ascii> decides.

=head2 last_move, remember, since

The move just played, the setter for it, and that move as the C<last> and
C<flips> pair L</board_text> marks from.

=head2 interactive, clear

Whether C<out> is a terminal, and the screen clear the picker does before each
frame. The board is nineteen lines, so a picker that scrolled one of them per
keystroke would be unreadable.

=head2 picking

Whether a square is pointed at rather than typed. Settable, because a failed
C<enter_raw> and the C<t> key turn it off for the rest of the game. Unset, it
follows L</keys_available>.

=head2 keys_available, enter_raw, leave_raw

Whether there is anything to read keys with, and cbreak on and off. B<cbreak
rather than raw>, so an interrupt stays an interrupt. F<bin/reversi> calls
C<leave_raw> from a signal handler and after an C<eval> round the game, because
a program that dies in cbreak leaves the shell with no echo.

=head2 keysource, pending, raw

A coderef returning ONE character in place of L<Term::ReadKey>, characters read
and given back, and the cbreak state. C<keysource> is what lets F<t/20> drive
the key loop with no terminal and no L<Term::ReadKey> installed; one character
a call, because a source handing back C<"\e[C"> whole never becomes a right
arrow.

=head2 read_char, read_key, read_sequence

One character, one keystroke as a name, and the tail of an escape sequence. A
name is always longer than one character so it never collides with one, and an
opener that turns out not to open a sequence goes back on L</pending>.

=head2 pick_square, pick_help

The cursor loop and its key list. C<pick_square> returns true to give up and
false when a turn was taken, the same contract as the typed turn.

=head2 square_line

What playing a square would do, as the one line printed under the board. Played
on a clone; the game is not touched.

=head2 board_text

The board as lines of text: a ruled grid, files across the top and the bottom,
ranks down both sides, and the legal moves for a colour marked with C<*>.
Marking them is not decoration: working out which squares outflank something is
the engine's job, and a person doing it by hand every turn will get it wrong.

=head2 start

Plays a game and returns its L<Game::Reversi::Result>.

=head2 run

	exit Game::Reversi::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options
F<bin/reversi> documents, builds the terminal, plays, and B<returns the exit
status rather than calling C<exit>>: C<0> if you won or tied, C<1> if you lost,
C<2> for a bad option, a leftover word or a value the terminal refuses, with the
reason and the usage on C<STDERR>. C<--help> prints the usage on C<STDOUT> and
returns C<0>. Signal handlers are local to the call and the terminal is left in
cooked mode on every way out, so a launcher such as L<Game::Terminal> can call it
in its own process and carry on afterwards. Colour is off when C<NO_COLOR> is
set, as it is off a terminal.


=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
