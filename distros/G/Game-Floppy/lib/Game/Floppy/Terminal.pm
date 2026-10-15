package Game::Floppy::Terminal;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Getopt::Long ();
use Object::Proto::Sugar -types;

use Game::Floppy;
use Game::Floppy::Bot;
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Run;
use Game::Terminal::Kit::Screen;
use Game::Terminal::Kit::Ticker;

our $VERSION = '0.10';

my %GLYPH = (
	wide => {
		pipe   => "\xE2\x96\x88",
		top    => "\xE2\x96\x80",
		bottom => "\xE2\x96\x84",
		bird   => "\xE2\x97\x8F",
		centre => "\xE2\x97\x89",
		sky    => ' ',
		h  => "\xE2\x94\x80", v  => "\xE2\x94\x82",
		tl => "\xE2\x95\xAD", tr => "\xE2\x95\xAE", bl => "\xE2\x95\xB0", br => "\xE2\x95\xAF",
	},
	ascii => {
		pipe   => '#',
		top    => '=',
		bottom => '=',
		bird   => 'o',
		centre => '@',
		sky    => ' ',
		h  => '-', v  => '|',
		tl => '+', tr => '+', bl => '+', br => '+',
	},
);

my %SGR = (
	pipe   => '32',
	top    => '32',
	bottom => '32',
	bird   => '1;36',
	centre => '1;36',
	frame  => '2',
	status => '1',
	paused => '1;33',
	over   => '1;31',
	legend => '2',
);

my %FLAP = map { $_ => 1 } ' ', 'up', 'enter', 'w', 'k';


my ($MIN_ROWS, $MAX_ROWS) = (10, 25);

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
	default => 3
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

has columns => (is => 'rw');
has lines   => (is => 'rw');

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

has games => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has best => (
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

has _view_cols => (is => 'rw', private => 1);
has _view_rows => (is => 'rw', private => 1);

my $clamp = sub {
	my ($value, $low, $high) = @_;
	return $low if $value < $low;
	return $high if $value > $high;
	return $value;
};

my $cols_for = sub {
	my ($game, $rows) = @_;
	return int($rows * $game->width / $game->height * 2 + 0.5);
};

sub BUILD {
	my ($self) = @_;

	Game::Floppy::Bot->describe($self->level);

	for my $name (qw/ cols rows columns lines max_ticks /) {
		my $value = $self->$name;
		next unless defined $value;
		Carp::croak("Game::Floppy::Terminal: $name must be a whole number, not '$value'")
			unless $value =~ /\A[0-9]+\z/;
	}

	$self->stopped('') unless defined $self->stopped;
	$self->refusal('') unless defined $self->refusal;

	Carp::croak('Game::Floppy::Terminal: the clock is a code reference')
		unless ref $self->clock eq 'CODE';
	Carp::croak('Game::Floppy::Terminal: the sleeper is a code reference')
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
		my $seed = $self->seed;
		$seed = Digest::SHA::sha256_hex(join ':', $self->clock->(), $$)
			unless CORE::length $seed;
		$self->game(Game::Floppy->new(seed => $seed));
	}

	my ($w, $h) = $self->_measure;
	my $rows = defined $self->rows ? $self->rows
		: $h ? $clamp->($h - 5, $MIN_ROWS, $MAX_ROWS) : 20;
	my $cols = defined $self->cols ? $self->cols : $cols_for->($self->game, $rows);
	if (!defined $self->cols && !defined $self->rows && $w && $cols + 2 > $w) {
		$rows = $clamp->(int(($w - 2) / ($self->game->width / $self->game->height * 2)), $MIN_ROWS, $MAX_ROWS);
		$cols = $cols_for->($self->game, $rows);
	}
	Carp::croak('Game::Floppy::Terminal: a view is at least 10 by 10')
		if $cols < 10 || $rows < 10;
	$self->_view_cols($cols);
	$self->_view_rows($rows);

	$self->ticker(Game::Terminal::Kit::Ticker->new(clock => $self->clock)) unless $self->ticker;

	return;
}

sub view { my ($self) = @_; return ($self->_view_cols, $self->_view_rows) }

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
		. ' Install Term::ReadKey, or run floppy --watch to watch the bot play.';
}

sub _measure {
	my ($self) = @_;
	return ($self->columns, $self->lines) if defined $self->columns;
	return () if $self->keysource || !$self->interactive;
	my ($w, $h) = $self->_synced->measured;
	return $w ? ($w, $h) : ();
}

sub too_narrow {
	my ($self) = @_;
	my ($w, $h) = $self->_measure;
	return undef unless $w;
	my ($cols, $rows) = $self->view;
	my ($need_w, $need_h) = ($cols + 2, $rows + 5);
	return undef if $w >= $need_w && (!$h || $h >= $need_h);
	return sprintf 'This window is %d columns by %d lines, and a view %d by %d needs %d by %d.'
		. ' Widen it, or ask for a smaller view with --cols and --rows.',
		$w, ($h || 0), $cols, $rows, $need_w, $need_h;
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
	my $line = sprintf ' Floppy   score %d   best %d', $game->score, $self->best;
	$line = $self->_paint($line, 'status');
	if (defined $note && CORE::length $note) {
		my $key = $note eq 'paused' ? 'paused' : $note =~ /\AGame over/ ? 'over' : 'legend';
		$line .= '   ' . $self->_paint($note, $key);
	}
	return $line;
}

sub legend {
	my ($self, $mode) = @_;
	$mode = '' unless defined $mode;
	my $text = $self->watch
		? ' watching level ' . $self->level . ': q quits, p pauses'
		: $mode eq 'again' ? ' space plays again; q quits'
		: ' space, up, enter, w or k flap; p pauses; q quits';
	return $self->_paint($text, 'legend');
}

sub board_lines {
	my ($self) = @_;
	my $game = $self->game;
	my $g = $self->_glyphs;
	my ($cols, $rows) = $self->view;
	my ($width, $height) = ($game->width, $game->height);
	my $ppc = $width / $cols;
	my $ppr = $height / $rows;

	my @cell = map { [ ('sky') x $cols ] } 1 .. $rows;

	for my $tube (@{ $game->tubes }) {
		my $from = int($tube->{x} / $ppc);
		my $to = int(($tube->{x} + $game->tube_width - 1) / $ppc);
		for my $c ($from .. $to) {
			next if $c < 0 || $c >= $cols;
			for my $r (0 .. $rows - 1) {
				my ($y0, $y1) = ($r * $ppr, ($r + 1) * $ppr);
				if ($y1 <= $tube->{gap_top}) {
					$cell[$r][$c] = 'pipe';
				}
				elsif ($y0 < $tube->{gap_top} && $tube->{gap_top} - $y0 >= $ppr / 2) {
					$cell[$r][$c] = 'top';
				}
				elsif ($y0 >= $tube->{gap_bottom}) {
					$cell[$r][$c] = 'pipe';
				}
				elsif ($y1 > $tube->{gap_bottom} && $y1 - $tube->{gap_bottom} >= $ppr / 2) {
					$cell[$r][$c] = 'bottom';
				}
			}
		}
	}

	my $bird = $game->bird;
	my $r2 = $bird->{radius} ** 2;
	for my $r (0 .. $rows - 1) {
		for my $c (0 .. $cols - 1) {
			my $dx = ($c + 0.5) * $ppc - $bird->{x};
			my $dy = ($r + 0.5) * $ppr - $bird->{y};
			$cell[$r][$c] = 'bird' if $dx * $dx + $dy * $dy <= $r2;
		}
	}
	my ($bc, $br) = (int($bird->{x} / $ppc), int($bird->{y} / $ppr));
	$cell[$br][$bc] = 'centre' if $br >= 0 && $br < $rows && $bc >= 0 && $bc < $cols;

	my $v = $self->_paint($g->{v}, 'frame');
	my @lines = ($self->_paint($g->{tl} . ($g->{h} x $cols) . $g->{tr}, 'frame'));
	for my $r (0 .. $rows - 1) {
		push @lines, $v . join('', map { my $k = $cell[$r][$_]; $self->_paint($g->{$k}, $k eq 'sky' ? undef : $k) } 0 .. $cols - 1) . $v;
	}
	push @lines, $self->_paint($g->{bl} . ($g->{h} x $cols) . $g->{br}, 'frame');
	return @lines;
}

sub frame_lines {
	my ($self, $note, $mode) = @_;
	return ($self->status_line($note), $self->board_lines, $self->legend($mode));
}

sub _frame {
	my ($self, $note, $mode) = @_;
	return if $self->quiet;
	$self->frames($self->frames + 1);
	my @lines = $self->frame_lines($note, $mode);
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
	$game->flap if Game::Floppy::Bot->choose($game, level => $self->level);
	return;
}

sub _on_key {
	my ($self, $key) = @_;
	return 0 if !defined $key || $key eq 'q' || $key eq 'eof' || $key eq 'interrupt';
	if ($FLAP{$key}) {
		return 1 if $self->watch;
		$self->refused($self->refused + 1) unless $self->game->flap;
		return 1;
	}
	return $self->_pause if $key eq 'p';
	return 1;
}

sub _pause {
	my ($self) = @_;
	$self->_frame('paused');
	while (1) {
		my $key = $self->read_key(undef);
		return 0 if !defined $key || $key eq 'q' || $key eq 'eof' || $key eq 'interrupt';
		last if $key eq 'p';
		if ($FLAP{$key}) {
			$self->_on_key($key);
			last;
		}
	}
	$self->ticker->start(1 / 20);
	return 1;
}

my $PERIOD = 1 / 20;

my $one_game = sub {
	my ($self, $queued) = @_;
	my $game = $self->game;
	my $ticker = $self->ticker;

	$self->games($self->games + 1);
	$self->_frame($self->watch || $queued ? undef : 'space to start');

	unless ($self->watch || $queued) {
		my $key = $self->read_key(undef);
		return 'quit' unless $self->_on_key($key);
	}

	$ticker->start($PERIOD);

	while ($game->status ne 'finished') {
		return 'capped' if $self->max_ticks && $ticker->ticks >= $self->max_ticks;

		unless ($ticker->due) {
			my $key = $self->read_key($ticker->remaining);
			if (defined $key) {
				return 'quit' unless $self->_on_key($key);
				next;
			}
		}

		$self->_bot_turn if $self->watch;
		my $step = $game->tick;
		$ticker->tick($PERIOD);
		$self->best($game->score) if $game->score > $self->best;
		$self->_frame($step->{died} ? ($game->result->stringify, 'again') : ());
	}

	return 'died';
};

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

	my $queued = 0;
	while (1) {
		my $how = $self->$one_game($queued);

		if ($how ne 'died') {
			$self->stopped($how);
			return $self->$finish;
		}

		return $self->$finish if $self->watch || $self->max_ticks;

		while (1) {
			my $key = $self->read_key(undef);
			if (!defined $key || $key eq 'q' || $key eq 'eof' || $key eq 'interrupt') {
				$self->stopped('quit');
				return $self->$finish;
			}
			last if $FLAP{$key};
		}

		$game->reset;
		$game->flap;
		$queued = 1;
	}
}

sub usage {
	return <<'USAGE';
usage: floppy [options]

  --seed TEXT           the game to play: the same seed and the same flaps are the same game
  --watch               watch the bot play
  --level N             the bot's level for --watch, 1 to 3 (default 3)
  --ticks N             stop after N ticks (0, the default, plays to the end)
  --rows N, --cols N    the view in cells; the default fits the window, at most 25 rows
  --quiet               no frames, only how it ended
  --ascii               plain characters instead of block glyphs
  --colour, --no-colour force colour on or off; NO_COLOR in the environment wins
  --raylib              open a window instead of playing in the terminal
                        (needs Raylib::FFI and perl 5.38 or later)
  --version, --help

keys: space, up, enter, w or k flap; p pauses; q quits; after a death, space plays again.

exit status: 0 the game ended or you quit; 2 a bad option, or a game that could not start.
USAGE
}

my $sentence = sub {
	my ($why) = @_;
	$why =~ s/ at \S+ line \d+\.?\s*\z//s;
	$why =~ s/\A(?:Game::Floppy(?:::\w+)*|floppy): //;
	$why =~ s/\s+\z//;
	$why .= '.' unless $why =~ /[.!?]\z/;
	return $why;
};

sub options {
	return [
		{ name => 'level', type => 'int', min => 1, max => 3, help => "the bot's level, for watch" },
		{ name => 'watch', type => 'flag', help => 'watch the bot fly' },
		{ name => 'rows', type => 'int', min => 10, max => 25, help => 'the view in cells; the default fits the window' },
		{ name => 'seed', type => 'str', help => 'the same seed and the same flaps are the same game' },
	];
}

sub run {
	my ($class, @argv) = @_;

	my %opt;
	my $ok = eval {
		local $SIG{__WARN__} = sub { my $w = $_[0]; $w =~ s/\s+\z//; print STDERR "floppy: $w\n" };
		Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
			'seed=s', 'level|l=i', 'watch|w', 'ticks=i', 'rows=i', 'cols=i',
			'quiet|q', 'ascii|a', 'colour|color!', 'raylib', 'version|v', 'help|h');
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
		print "floppy $VERSION\n";
		return 0;
	}
	if (@argv) {
		print STDERR "floppy: I do not know '$argv[0]'.\n", usage();
		return 2;
	}

	my %with;
	$with{seed}      = $opt{seed}  if defined $opt{seed};
	$with{level}     = $opt{level} if defined $opt{level};
	$with{max_ticks} = $opt{ticks} if defined $opt{ticks};
	$with{rows}      = $opt{rows}  if defined $opt{rows};
	$with{cols}      = $opt{cols}  if defined $opt{cols};
	$with{watch}     = 1 if $opt{watch};
	$with{quiet}     = 1 if $opt{quiet};
	$with{ascii}     = 1 if $opt{ascii};
	$with{ansi}      = $opt{colour} ? 1 : 0 if defined $opt{colour};

	if ($opt{raylib}) {
		unless (eval { require Game::Floppy::Raylib; 1 }) {
			print STDERR "floppy: the window is not part of this build; play in the terminal.\n";
			return 2;
		}
		unless (Game::Floppy::Raylib->available) {
			print STDERR 'floppy: ' . Game::Floppy::Raylib->why_not . "\n";
			return 2;
		}
		delete @with{qw/ quiet ascii ansi rows cols /};
		my $window = eval { Game::Floppy::Raylib->new(%with) };
		unless ($window) {
			print STDERR 'floppy: ' . $sentence->($@) . "\n";
			return 2;
		}
		return $window->start ? 0 : 2;
	}

	my $terminal = eval { $class->new(%with) };
	unless ($terminal) {
		print STDERR 'floppy: ' . $sentence->($@) . "\n";
		return 2;
	}

	my $result = Game::Terminal::Kit::Run::guard(sub { $terminal->start }, $terminal);

	return 0 if $result;
	print STDERR 'floppy: ' . $terminal->refusal . "\n" if CORE::length $terminal->refusal;
	return 2;
}

1;

__END__

=head1 NAME

Game::Floppy::Terminal - Floppy in a terminal

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    use Game::Floppy::Terminal;

    my $terminal = Game::Floppy::Terminal->new(seed => 'anything');
    my $result = $terminal->start;        # returns; never exits

    exit Game::Floppy::Terminal->run(@ARGV);   # which is all of bin/floppy

=head1 DESCRIPTION

The playable game on two filehandles, twenty frames a second. It draws the
field, reads the keys and ticks the engine; the rules are L<Game::Floppy>'s
and nothing here knows them. It is a separate module so the engine can be
loaded by anything without pulling a terminal in.

The field is 516 by 400 pixels whatever the window: the view scales it to a
grid of cells that keeps the field's shape (a cell is about twice as tall as
it is wide, so 20 rows take 52 columns), at most 25 rows. A pipe is drawn to
the cell its lip reaches, with a half block where it reaches half a cell, and
the bird is the cells its circle covers. What you see is what collides.

The one wait in the loop is a timed read of the keyboard: a key ends it early
and is acted on, and the deadline passing is the tick. A tick that is late
fires once and the schedule restarts (L<Game::Terminal::Kit::Ticker>).

A game lasts seconds. After a death the last frame stays on the screen with
its sentence; space plays again and quits remain quits. The best score of
the run is kept.

The keys need L<Term::ReadKey>, which is recommended and not required.
Without it, or without a terminal, the game cannot be played by hand and
says so; C<--watch> still works anywhere because it reads nothing.

=head1 PROPERTIES

=head2 in, out

The handles, read-write, defaulting to C<STDIN> and C<STDOUT>.

=head2 rows, cols

The view, in cells. Left out, the view is fitted to the window.

=head2 seed

The game. Left out, a fresh one is made.

=head2 level, watch

The bot's level (1 to 3) and whether it, not you, flies.

=head2 quiet, ascii

Draw no frames; use plain characters instead of block glyphs.

=head2 ansi, interactive

Given to C<new> only. C<ansi> forces colour on or off, and C<NO_COLOR> in the
environment beats it. C<interactive> forces the redrawn-in-place frame on or
off; the default follows whether C<out> is a terminal.

=head2 max_ticks

Stop after that many ticks; 0, the default, plays to the end.

=head2 game, ticker

The L<Game::Floppy> being played and its L<Game::Terminal::Kit::Ticker>, built in
C<new> unless given.

=head2 keysource, clock, sleeper, columns, lines

For tests. C<keysource> is a code reference called with the seconds to wait
that returns one character, or undefined when none came in time; C<clock>
returns seconds; C<sleeper> is called with seconds to wait when there is
nothing to read; C<columns> and C<lines> stand in for the window's size.

=head2 pending

Characters to be read before any others, an array reference.

=head2 keyboard, screen

The L<Game::Terminal::Kit::Keys> the keys are read through and the
L<Game::Terminal::Kit::Screen> the frames are drawn through, built in C<new>
from the handles unless given.

=head2 frames, refused, games, best, stopped, refusal

After C<start>: frames drawn, flaps refused, games played, the best score,
how it stopped (empty for a death, C<quit>, C<capped>, C<narrow> or C<keys>)
and the sentence saying why it could not start.

=head1 METHODS

=head2 start

Plays until a quit, a cap, or a death that is not followed by space, and
returns the last game's L<Game::Floppy::Result>; undefined when it could not
start, with C<refusal> saying why. Never calls C<exit>.

=head2 options

    my $fields = Game::Floppy::Terminal->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<level>

A whole number from 1 to 3: the bot's level, for watch.

=item C<watch>

A switch: watch the bot fly.

=item C<rows>

A whole number from 10 to 25: the view in cells; the default fits the window.

=item C<seed>

Text: the same seed and the same flaps are the same game.

=back

=head2 run

    exit Game::Floppy::Terminal->run(@ARGV);

The program. Parses the options, plays, and returns the exit status: 0 when
a game ended or was quit, 2 for a bad option or a game that could not start.
C<--help> goes to C<STDOUT>; the usage after a bad option, and every
refusal, to C<STDERR>.

=head2 view

The view's columns and rows.

=head2 too_narrow, cannot_play

The sentence for a window that cannot hold the view, or undefined; the
sentence for a game with no way to read keys.

=head2 keys_available, enter_raw, leave_raw, raw, read_key

Whether keys can be read; reading a key at a time, giving the terminal back
with its cursor, and whether a key at a time is how it is being read now; one
key by name within the wait, the names being L<Game::Terminal::Kit::Keys>'s.

=head2 board_lines, frame_lines, status_line, legend

The field as lines, the whole frame, and its two text lines.

=head2 ansi, interactive, usage

Whether colour and in-place redrawing are on; the usage text.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
