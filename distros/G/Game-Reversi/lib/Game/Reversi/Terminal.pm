package Game::Reversi::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Bot;
use Game::Reversi::Notation;
use Game::Reversi::Opening;

our $VERSION = '0.01';

my %GLYPH = (
	b => { wide => "\x{25CF}", ascii => 'X' },
	w => { wide => "\x{25CB}", ascii => 'O' },
);
my %NAME  = (b => 'dark', w => 'light');

my %LINE = (
	wide  => { h => "\x{2500}", v => "\x{2502}", tl => "\x{250C}", tr => "\x{2510}",
	           bl => "\x{2514}", br => "\x{2518}", t => "\x{252C}", b => "\x{2534}",
	           l => "\x{251C}", r => "\x{2524}", x => "\x{253C}" },
	ascii => { h => '-', v => '|', tl => '+', tr => '+', bl => '+', br => '+',
	           t => '+', b => '+', l => '+', r => '+', x => '+' },
);

my %INK = (b => "\e[1m", w => "\e[2m", '*' => "\e[33m", grid => "\e[2m");
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
	$line =~ s/\A\s+|\s+\z//g;
	return lc $line;
}

sub glyph {
	my ($self, $colour) = @_;
	return $GLYPH{$colour}{ $self->ascii ? 'ascii' : 'wide' };
}

sub board_text {
	my ($self, $game, $colour) = @_;
	my %legal = map { $_->square => 1 }
	            @{ defined $colour ? $game->legal($colour) : [] };
	my $line = $LINE{ $self->ascii ? 'ascii' : 'wide' };

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
			push @cells, ' ' . (defined $cell ? $self->_paint($self->glyph($cell), $cell)
			           : $legal{$square} ? $self->_paint('*', '*')
			           : ' ') . ' ';
		}
		my $bar = $self->_paint($line->{v}, 'grid');
		push @lines, " $rank " . $bar . join($bar, @cells) . $bar . " $rank";
		push @lines, $rule->(@{$line}{qw/l x r/}) unless $row == 7;
	}
	push @lines, $rule->(@{$line}{qw/bl b br/}), $files;
	return @lines;
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
			$game->play($turn, $move->square);
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

sub _human_turn {
	my ($self, $game, $me) = @_;

	while (1) {
		my $count = $game->counts;
		$self->_say('', $self->board_text($game, $me));
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

1;

__END__

=head1 NAME

Game::Reversi::Terminal - a playable game on two filehandles

=head1 VERSION

Version 0.01

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

=head2 board_text

The board as lines of text: a ruled grid, files across the top and the bottom,
ranks down both sides, and the legal moves for a colour marked with C<*>.
Marking them is not decoration: working out which squares outflank something is
the engine's job, and a person doing it by hand every turn will get it wrong.

=head2 start

Plays a game and returns its L<Game::Reversi::Result>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
