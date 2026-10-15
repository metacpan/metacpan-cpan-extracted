package Game::Snake::Terminal;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Getopt::Long ();
use Object::Proto::Sugar -types;

use Game::Snake;
use Game::Snake::Bot;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Ticker;

our $VERSION = '0.13';

my %GLYPH = (
	wide => {
		head   => { up => "\xE2\x96\x80\xE2\x96\x80", down => "\xE2\x96\x84\xE2\x96\x84", left => "\xE2\x96\x8C\xE2\x96\x88", right => "\xE2\x96\x88\xE2\x96\x90" },
		body   => "\xE2\x96\x88\xE2\x96\x88",
		tail   => "\xE2\x96\x92\xE2\x96\x92",
		food   => "\xE2\x97\x86 ",
		ground => '  ',
		h  => "\xE2\x94\x80", v  => "\xE2\x94\x82",
		tl => "\xE2\x95\xAD", tr => "\xE2\x95\xAE", bl => "\xE2\x95\xB0", br => "\xE2\x95\xAF",
	},
	ascii => {
		head   => { up => '^^', down => 'vv', left => '<<', right => '>>' },
		body   => '##',
		tail   => '::',
		food   => '()',
		ground => '  ',
		h  => '-', v  => '|',
		tl => '+', tr => '+', bl => '+', br => '+',
	},
);

my %SGR = (
	head   => '1;32',
	body   => '32',
	tail   => '2;32',
	food   => '1;31',
	frame  => '2',
	status => '1',
	paused => '1;33',
	over   => '1;31',
	legend => '2',
);

my %STEER = (
	up => 'up', down => 'down', left => 'left', right => 'right',
	w  => 'up', s    => 'down', a    => 'left', d     => 'right',
	k  => 'up', j    => 'down', h    => 'left', l     => 'right',
);


my ($MIN_COLS, $MAX_COLS, $MIN_ROWS, $MAX_ROWS) = (10, 40, 8, 28);

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

has cols => (is => 'ro');
has rows => (is => 'ro');

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 2
);

has watch => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has quiet => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has ascii => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has max_ticks => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has game => (
	is  => 'rw',
	isa => Object
);

has [qw/keyboard screen/] => (
	is => 'rw'
);

has keysource => (is => 'rw');

has pending => (
	is      => 'rw',
	isa     => ArrayRef,
	default => sub { [] }
);

has clock => (
	is      => 'ro',
	isa     => Any,
	default => sub { \&Time::HiRes::time }
);

has sleeper => (
	is      => 'ro',
	isa     => Any,
	default => sub { sub { select undef, undef, undef, $_[0] } }
);

has ticker => (
	is  => 'rw',
	isa => Object
);

has width  => (is => 'rw');
has height => (is => 'rw');

has frames => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has refused => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has stopped => (
	is      => 'rw',
	isa     => Str,
	default => ''
);

has refusal => (
	is      => 'rw',
	isa     => Str,
	default => ''
);

has _wants_ansi => (
	is       => 'ro',
	init_arg => 'ansi',
	private  => 1
);

has _wants_interactive => (
	is       => 'ro',
	init_arg => 'interactive',
	private  => 1
);

my $clamp = sub {
	my ($value, $low, $high) = @_;
	return $low if $value < $low;
	return $high if $value > $high;
	return $value;
};

sub BUILD {
	my ($self) = @_;

	Game::Snake::Bot->describe($self->level);

	for my $name (qw/ cols rows width height max_ticks /) {
		my $value = $self->$name;
		next unless defined $value;
		Carp::croak("Game::Snake::Terminal: $name must be a whole number, not '$value'")
			unless $value =~ /\A[0-9]+\z/;
	}

	$self->stopped('') unless defined $self->stopped;
	$self->refusal('') unless defined $self->refusal;

	Carp::croak('Game::Snake::Terminal: the clock is a code reference')
		unless ref $self->clock eq 'CODE';
	Carp::croak('Game::Snake::Terminal: the sleeper is a code reference')
		unless ref $self->sleeper eq 'CODE';

	$self->keyboard(Game::Terminal::Kit::Keys->new(
		in => $self->in,
		pending => $self->pending,
		sleeper => $self->sleeper,
		($self->keysource ? (keysource => $self->keysource) : ()),
	)) unless $self->keyboard;
	$self->screen(Game::Terminal::Kit::Screen->new(
		out => $self->out,
		interactive => $self->interactive,
		colour => $self->ansi,
		ascii => $self->ascii ? 1 : 0,
	)) unless $self->screen;

	unless ($self->game) {
		my ($w, $h) = $self->_measure;
		my $cols = defined $self->cols ? $self->cols
			: $w ? $clamp->(int(($w - 2) / 2), $MIN_COLS, $MAX_COLS) : $MAX_COLS;
		my $rows = defined $self->rows ? $self->rows
			: $h ? $clamp->($h - 5, $MIN_ROWS, $MAX_ROWS) : $MAX_ROWS;
		my $seed = $self->seed;
		$seed = Digest::SHA::sha256_hex(join ':', $self->clock->(), $$)
			unless CORE::length $seed;
		$self->game(Game::Snake->new(cols => $cols, rows => $rows, seed => $seed));
	}

	$self->ticker(Game::Terminal::Kit::Ticker->new(clock => $self->clock)) unless $self->ticker;

	return;
}

sub ansi {
	my ($self) = @_;
	return 0 if defined $ENV{NO_COLOR} && CORE::length $ENV{NO_COLOR};
	return $self->_wants_ansi ? 1 : 0 if defined $self->_wants_ansi;
	return -t $self->out ? 1 : 0;
}

sub interactive {
	my ($self) = @_;
	return $self->_wants_interactive ? 1 : 0 if defined $self->_wants_interactive;
	return -t $self->out ? 1 : 0;
}

sub _synced {
	my ($self) = @_;
	my $screen = $self->screen;
	$screen->out($self->out);
	$screen->interactive($self->interactive);
	$screen->colour($self->ansi);
	return $screen;
}

sub raw {
	my ($self) = @_;
	return $self->keyboard->raw;
}

sub keys_available {
	my ($self) = @_;
	return $self->keyboard->keys_available;
}

sub enter_raw {
	my ($self) = @_;
	return $self->keyboard->enter_raw ? $self : undef;
}

sub leave_raw {
	my ($self) = @_;
	$self->screen->restore;
	$self->keyboard->leave_raw;
	return $self;
}

sub read_key {
	my ($self, $wait) = @_;
	return $self->keyboard->read_key($wait);
}

sub cannot_play {
	return 'A real-time game needs a terminal and Term::ReadKey to read the keys.'
		. ' Install Term::ReadKey, or run snake --watch to watch the bot play.';
}

sub _measure {
	my ($self) = @_;
	return ($self->width, $self->height) if defined $self->width;
	return () if $self->keysource || !$self->interactive;
	my ($w, $h) = $self->_synced->measured;
	return $w ? ($w, $h) : ();
}

sub too_narrow {
	my ($self) = @_;
	my ($w, $h) = $self->_measure;
	return undef unless $w;
	my $game = $self->game;
	my ($need_w, $need_h) = (2 * $game->cols + 2, $game->rows + 5);
	return undef if $w >= $need_w && (!$h || $h >= $need_h);
	return sprintf 'This window is %d columns by %d lines, and a %d by %d board needs %d by %d.'
		. ' Widen it, or ask for a smaller board with --cols and --rows.',
		$w, ($h || 0), $game->cols, $game->rows, $need_w, $need_h;
}

sub _glyphs { return $GLYPH{ $_[0]->ascii ? 'ascii' : 'wide' } }

sub _paint {
	my ($self, $text, $key) = @_;
	return $text unless defined $key && defined $SGR{$key};
	return $self->_synced->paint($text, $SGR{$key});
}

sub _say {
	my ($self, @lines) = @_;
	$self->_synced->say(@lines) if @lines;
	return;
}

sub status_line {
	my ($self, $note) = @_;
	my $game = $self->game;
	my $line = sprintf ' Snake   score %d   length %d   speed %d/s',
		$game->score, $game->length, $game->speed;
	$line = $self->_paint($line, 'status');
	if (defined $note && CORE::length $note) {
		my $key = $note eq 'paused' ? 'paused' : 'over';
		$line .= '   ' . $self->_paint($note, $key);
	}
	return $line;
}

sub legend {
	my ($self) = @_;
	my $text = $self->watch
		? ' watching level ' . $self->level . ': q quits, p pauses'
		: ' arrows, wasd or hjkl steer; p pauses; q quits';
	return $self->_paint($text, 'legend');
}

sub board_lines {
	my ($self) = @_;
	my $game = $self->game;
	my $g = $self->_glyphs;
	my ($cols, $rows) = ($game->cols, $game->rows);

	my @cell = map { [ ($g->{ground}) x $cols ] } 1 .. $rows;
	my @key  = map { [ (undef) x $cols ] } 1 .. $rows;

	if (my $food = $game->food) {
		$cell[ $food->[1] ][ $food->[0] ] = $g->{food};
		$key[ $food->[1] ][ $food->[0] ]  = 'food';
	}

	my $segments = $game->segments;
	for my $i (0 .. $#$segments) {
		my $segment = $segments->[$i];
		my ($glyph, $key) = $i == 0 ? ($g->{head}{ $segment->{dir} }, 'head')
			: $segment->{last} ? ($g->{tail}, 'tail')
			: ($g->{body}, 'body');
		$cell[ $segment->{y} ][ $segment->{x} ] = $glyph;
		$key[ $segment->{y} ][ $segment->{x} ]  = $key;
	}

	my $v = $self->_paint($g->{v}, 'frame');
	my @lines = ($self->_paint($g->{tl} . ($g->{h} x (2 * $cols)) . $g->{tr}, 'frame'));
	for my $y (0 .. $rows - 1) {
		push @lines, $v . join('', map { $self->_paint($cell[$y][$_], $key[$y][$_]) } 0 .. $cols - 1) . $v;
	}
	push @lines, $self->_paint($g->{bl} . ($g->{h} x (2 * $cols)) . $g->{br}, 'frame');
	return @lines;
}

sub frame_lines {
	my ($self, $note) = @_;
	return ($self->status_line($note), $self->board_lines, $self->legend);
}

sub _frame {
	my ($self, $note) = @_;
	return if $self->quiet;
	$self->frames($self->frames + 1);
	my @lines = $self->frame_lines($note);
	my $screen = $self->_synced->flush_on;
	$screen->show(\@lines);
	$screen->say('') unless $self->interactive;
	return;
}

sub _intro {
	my ($self) = @_;
	return unless $self->interactive && !$self->quiet;
	$self->_synced->flush_on->clear->hide_cursor;
	return;
}

sub _bot_turn {
	my ($self) = @_;
	my $game = $self->game;
	my $direction = Game::Snake::Bot->choose($game, level => $self->level);
	$game->turn($direction) if defined $direction && $direction ne $game->heading;
	return;
}

sub _on_key {
	my ($self, $key) = @_;
	return 0 if !defined $key || $key eq 'q' || $key eq 'eof' || $key eq 'interrupt';
	if (my $direction = $STEER{$key}) {
		return 1 if $self->watch;
		$self->refused($self->refused + 1) unless $self->game->turn($direction);
		return 1;
	}
	return $self->_pause if $key eq 'p' || $key eq ' ';
	return 1;
}

sub _pause {
	my ($self) = @_;
	$self->_frame('paused');
	while (1) {
		my $key = $self->read_key(undef);
		return 0 if !defined $key || $key eq 'q' || $key eq 'eof' || $key eq 'interrupt';
		last if $key eq 'p' || $key eq ' ';
		if ($STEER{$key}) {
			$self->_on_key($key);
			last;
		}
	}
	$self->ticker->start(1 / $self->game->speed);
	return 1;
}

my $finish = sub {
	my ($self) = @_;
	my $game = $self->game;
	$game->quit unless $game->status eq 'finished';
	$self->leave_raw;
	my $result = $game->result;
	$self->_say($result->stringify);
	return $result;
};

sub start {
	my ($self) = @_;
	my $game = $self->game;

	if (my $why = $self->too_narrow) {
		$self->refusal($why);
		$self->stopped('narrow');
		return undef;
	}

	if ($self->watch) {
		$self->enter_raw;
	}
	elsif (!$self->enter_raw) {
		$self->refusal($self->cannot_play);
		$self->stopped('keys');
		return undef;
	}

	$self->_intro;

	my $ticker = $self->ticker;
	$self->_frame;

	unless ($self->watch) {
		my $key = $self->read_key(undef);
		unless ($self->_on_key($key)) {
			$self->stopped('quit');
			return $self->$finish;
		}
	}

	$ticker->start(1 / $game->speed);

	while ($game->status ne 'finished') {
		last if $self->max_ticks && $ticker->ticks >= $self->max_ticks;

		unless ($ticker->due) {
			my $key = $self->read_key($ticker->remaining);
			if (defined $key) {
				unless ($self->_on_key($key)) {
					$self->stopped('quit');
					return $self->$finish;
				}
				next;
			}
		}

		$self->_bot_turn if $self->watch;
		my $step = $game->tick;
		$ticker->tick(1 / $game->speed);
		$self->_frame($step->{died} ? $game->result->stringify : undef);
	}

	$self->stopped('capped') unless $game->status eq 'finished';
	return $self->$finish;
}

sub usage {
	return <<'USAGE';
usage: snake [options]

  --cols N, --rows N    the board; the default fits the window, at most 40 by 28
  --seed TEXT           the game to play: the same seed and the same moves are the same game
  --watch               watch the bot play
  --level N             the bot's level for --watch, 1 or 2 (default 2)
  --ticks N             stop after N ticks (0, the default, plays to the end)
  --quiet               no frames, only how it ended
  --ascii               plain characters instead of block glyphs
  --colour, --no-colour force colour on or off; NO_COLOR in the environment wins
  --raylib              open a window instead of playing in the terminal
                        (needs Raylib::FFI and perl 5.38 or later)
  --cell N              the window's cell size in pixels (default 20)
  --version, --help

keys: arrows, wasd or hjkl steer; p or space pauses; q quits.

exit status: 0 the game ended or you quit; 2 a bad option, or a game that could not start.
USAGE
}

my $sentence = sub {
	my ($why) = @_;
	$why =~ s/ at \S+ line \d+\.?\s*\z//s;
	$why =~ s/\A(?:Game::Snake(?:::\w+)*|snake): //;
	$why =~ s/\s+\z//;
	$why .= '.' unless $why =~ /[.!?]\z/;
	return $why;
};

sub options {
	return [
		{ name => 'level', type => 'int', min => 1, max => 2, help => "the bot's level, for watch" },
		{ name => 'watch', type => 'flag', help => 'watch the bot play' },
		{ name => 'rows', type => 'int', min => 8, max => 28, help => 'the board; the default fits the window' },
		{ name => 'cols', type => 'int', min => 8, max => 40, help => 'the board; the default fits the window' },
		{ name => 'seed', type => 'str', help => 'the same seed and the same moves are the same game' },
	];
}

sub run {
	my ($class, @argv) = @_;

	my %opt;
	my $ok = eval {
		local $SIG{__WARN__} = sub { my $w = $_[0]; $w =~ s/\s+\z//; print STDERR "snake: $w\n" };
		Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
			'cols|c=i', 'rows|r=i', 'seed=s', 'level|l=i', 'watch|w', 'ticks=i',
			'quiet|q', 'ascii|a', 'colour|color!', 'raylib', 'cell=i', 'version|v', 'help|h');
	};
	if (!$ok) {
		print STDERR usage();
		return 2;
	}
	if ($opt{help}) {
		print usage();
		return 0;
	}
	if ($opt{version}) {
		print "snake $VERSION\n";
		return 0;
	}
	if (@argv) {
		print STDERR "snake: I do not know '$argv[0]'.\n", usage();
		return 2;
	}

	my %with;
	$with{cols}      = $opt{cols}  if defined $opt{cols};
	$with{rows}      = $opt{rows}  if defined $opt{rows};
	$with{seed}      = $opt{seed}  if defined $opt{seed};
	$with{level}     = $opt{level} if defined $opt{level};
	$with{max_ticks} = $opt{ticks} if defined $opt{ticks};
	$with{watch}     = 1 if $opt{watch};
	$with{quiet}     = 1 if $opt{quiet};
	$with{ascii}     = 1 if $opt{ascii};
	$with{ansi}      = $opt{colour} ? 1 : 0 if defined $opt{colour};

	if ($opt{raylib}) {
		unless (eval { require Game::Snake::Raylib; 1 }) {
			print STDERR "snake: the window is not part of this build; play in the terminal.\n";
			return 2;
		}
		unless (Game::Snake::Raylib->available) {
			print STDERR 'snake: ' . Game::Snake::Raylib->why_not . "\n";
			return 2;
		}
		$with{cell} = $opt{cell} if defined $opt{cell};
		delete @with{qw/ quiet ascii ansi /};
		my $window = eval { Game::Snake::Raylib->new(%with) };
		unless ($window) {
			print STDERR 'snake: ' . $sentence->($@) . "\n";
			return 2;
		}
		return $window->start ? 0 : 2;
	}

	my $terminal = eval { $class->new(%with) };
	unless ($terminal) {
		print STDERR 'snake: ' . $sentence->($@) . "\n";
		return 2;
	}

	my $result = Game::Terminal::Kit::Run::guard(sub { $terminal->start }, $terminal);

	return 0 if $result;
	print STDERR 'snake: ' . $terminal->refusal . "\n" if CORE::length $terminal->refusal;
	return 2;
}

1;

__END__

=head1 NAME

Game::Snake::Terminal - snake in a terminal

=head1 VERSION

Version 0.13

=head1 SYNOPSIS

    use Game::Snake::Terminal;

    my $terminal = Game::Snake::Terminal->new(seed => 'anything');
    my $result = $terminal->start;        # returns; never exits

    exit Game::Snake::Terminal->run(@ARGV);   # which is all of bin/snake

=head1 DESCRIPTION

The playable game on two filehandles. It draws the board, reads the keys and
ticks the engine; the rules are L<Game::Snake>'s and nothing here knows them.
It is a separate module so the engine can be loaded by anything without
pulling a terminal in.

Every other terminal game of this author's waits for a key. This one ticks.
The one wait in the loop is a timed read of the keyboard: a key ends it early
and is acted on, and the deadline passing is the tick. A tick that is late
fires once and the schedule restarts, so a stalled machine never hands the
snake a burst of moves (L<Game::Terminal::Kit::Ticker>).

The keys need L<Term::ReadKey>, which is recommended and not required.
Without it, or without a terminal, the game cannot be played by hand and
says so; C<--watch> still works anywhere because it reads nothing.

=head1 PROPERTIES

Every one may be given to C<new>; those marked read-write may be set after.

=head2 in, out

The handles, read-write, defaulting to C<STDIN> and C<STDOUT>.

=head2 cols, rows

The board. Left out, the board is fitted to the window, at most 40 by 28.

=head2 seed

The game. Left out, a fresh one is made.

=head2 level, watch

The bot's level (1 or 2) and whether it, not you, steers.

=head2 quiet, ascii

Draw no frames; use plain characters instead of block glyphs.

=head2 ansi, interactive

Given to C<new> only. C<ansi> forces colour on or off, and C<NO_COLOR> in the
environment beats it. C<interactive> forces the redrawn-in-place frame on or
off; the default follows whether C<out> is a terminal.

=head2 max_ticks

Stop the game after that many ticks; 0, the default, plays to the end.

=head2 game, ticker

The L<Game::Snake> being played and its L<Game::Terminal::Kit::Ticker>, built in
C<new> unless given.

=head2 keysource, clock, sleeper, width, height

For tests. C<keysource> is a code reference called with the seconds to wait
that returns one character, or undefined when none came in time; C<clock>
returns seconds; C<sleeper> is called with seconds to wait when there is
nothing to read; C<width> and C<height> stand in for the window's size.

=head2 pending

Characters to be read before any others, an array reference.

=head2 keyboard, screen

The L<Game::Terminal::Kit::Keys> the keys are read through and the
L<Game::Terminal::Kit::Screen> the frames are drawn through, built in C<new>
from the handles unless given.

=head2 frames, refused, stopped, refusal

After C<start>: frames drawn, turns refused, how it stopped (empty, C<quit>,
C<capped>, C<narrow> or C<keys>) and the sentence saying why it could not
start.

=head1 METHODS

=head2 start

Plays the game and returns its L<Game::Snake::Result>, or undefined when it
could not start (the window too narrow, or no way to read keys), with
C<refusal> saying why. Never calls C<exit>.

=head2 options

    my $fields = Game::Snake::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<level>

A whole number from 1 to 2: the bot's level, for watch.

=item C<watch>

A switch: watch the bot play.

=item C<rows>

A whole number from 8 to 28: the board; the default fits the window.

=item C<cols>

A whole number from 8 to 40: the board; the default fits the window.

=item C<seed>

Text: the same seed and the same moves are the same game.

=back

=head2 run

    exit Game::Snake::Terminal->run(@ARGV);

The program. Parses the options, plays, and returns the exit status: 0 when
a game ended or was quit, 2 for a bad option or a game that could not start.
C<--help> goes to C<STDOUT>; the usage after a bad option, and every
refusal, to C<STDERR>.

=head2 too_narrow

The sentence to print when the window cannot hold the board, or undefined.

=head2 cannot_play

The sentence for a game with no way to read keys.

=head2 keys_available, enter_raw, leave_raw, raw

Whether keys can be read; reading a key at a time, giving the terminal back
with its cursor, and whether a key at a time is how it is being read now.

=head2 read_key

    my $key = $terminal->read_key($seconds);

One key by name (C<up>, C<enter>, C<q>, ...) within the wait, or undefined.
Undefined seconds block; zero polls. The names are
L<Game::Terminal::Kit::Keys>'s.

=head2 board_lines, frame_lines, status_line, legend

The board as lines, the whole frame, and its two text lines.

=head2 ansi, interactive

Whether colour and in-place redrawing are on.

=head2 usage

The usage text.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
