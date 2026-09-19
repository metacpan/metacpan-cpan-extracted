package Game::Oware::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Oware;
use Game::Oware::Board;
use Game::Oware::Bot;
use Game::Oware::Notation;
use Game::Oware::Rules;
use Game::Oware::Variant ();

our $VERSION = '0.01';

my %LINE = (
	wide  => { bar => '-', corner => '+', edge => '|' },
	ascii => { bar => '-', corner => '+', edge => '|' },
);

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
	default => 'abapa'
);

has seat => (
	is      => 'ro',
	isa     => Str,
	default => 'p1'
);

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
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

has game => (
	is  => 'rw',
	isa => Object
);

has bot => (
	is  => 'rw',
	isa => Object
);

has _wants_ansi => (
	is       => 'ro',
	init_arg => 'ansi',
	private  => 1
);

sub BUILD {
	my ($self) = @_;

	Game::Oware::Variant::check_variant($self->variant);

	die 'Game::Oware::Terminal: seat must be p1 or p2, not ' . $self->seat
		unless $self->seat eq 'p1' || $self->seat eq 'p2';

	Game::Oware::Bot->setting_for($self->level);

	$self->game(Game::Oware->new(
		variant => $self->variant,
		seed    => $self->seed,
	)) unless $self->game;

	$self->bot(Game::Oware::Bot->new(
		level => $self->level,
		seed  => $self->seed . ':bot',
	)) unless $self->bot;

	return $self;
}

sub ansi {
	my ($self) = @_;
	return 0 if defined $ENV{NO_COLOR} && length $ENV{NO_COLOR};
	return $self->_wants_ansi ? 1 : 0 if defined $self->_wants_ansi;
	return -t $self->out ? 1 : 0;
}

sub rows_for {
	my ($self, $seat) = @_;
	return $seat eq 'p1'
		? ([ reverse 6 .. 11 ], [ 0 .. 5 ])
		: ([ reverse 0 .. 5 ],  [ 6 .. 11 ]);
}

sub board_text {
	my ($self, $game, $seat) = @_;
	$seat ||= $self->seat;

	my $board = $game->board;
	my ($top, $bottom) = $self->rows_for($seat);
	my $them = Game::Oware::Board->other($seat);
	my $line = $LINE{ $self->ascii ? 'ascii' : 'wide' };

	my $rule = ' ' . ($line->{corner} . $line->{bar} x 3) x 6 . $line->{corner};

	my @out;
	push @out, '   ' . join '   ',
		map { Game::Oware::Notation->letter_of($_) } @$top;
	push @out, $rule;
	push @out, ' ' . join('', map { sprintf '%s%3d', $line->{edge}, $board->[$_] } @$top)
		. $line->{edge} . '   ' . $them . ': ' . $game->captured->{$them};
	push @out, $rule;
	push @out, ' ' . join('', map { sprintf '%s%3d', $line->{edge}, $board->[$_] } @$bottom)
		. $line->{edge} . '   ' . $seat . ': ' . $game->captured->{$seat};
	push @out, $rule;
	push @out, '   ' . join '   ',
		map { Game::Oware::Notation->letter_of($_) } @$bottom;

	return @out;
}

sub start {
	my ($self) = @_;

	$self->_intro unless $self->quiet;

	my $game = $self->game;

	while ($game->status eq 'active') {
		my ($turn) = $game->waiting_on;
		last unless defined $turn;

		if ($turn eq $self->seat) {
			last unless $self->_human_turn;
		}
		else {
			$self->_bot_turn($turn);
		}
	}

	$self->_finish unless $self->quiet;

	return $game->result;
}

sub command {
	my ($self, $line) = @_;

	return 'quit' unless defined $line;
	$line =~ s/\A\s+|\s+\z//g;

	return 'again' unless length $line;
	return 'quit' if $line =~ /\A(?:q|quit|exit)\z/i;
	return 'help' if $line =~ /\A(?:\?|h|help)\z/i;
	return 'board' if $line =~ /\Aboard\z/i;

	return $line;
}

sub _say {
	my ($self, @lines) = @_;
	my $out = $self->out;
	print {$out} "$_\n" for @lines;
	return;
}

sub _paint {
	my ($self, $text) = @_;
	return $text unless $self->ansi;
	return "\e[1m" . $text . "\e[0m";
}

sub _intro {
	my ($self) = @_;
	$self->_say(
		'Oware, ' . $self->variant . ' rules. You are ' . $self->seat . '.',
		'Sow from one of your six houses by typing its letter.',
		'Type help for the rules that surprise people, or quit to stop.',
		'',
	);
	return;
}

sub _help {
	my ($self) = @_;
	$self->_say(
		'Take every seed from one of your houses and drop one in each house',
		'counter-clockwise, skipping the house you took them from.',
		'',
		'If your last seed brings one of your opponent houses to exactly two or',
		'three, you capture it, and the walk continues backwards while that',
		'holds. Twenty-five seeds wins. Twenty-four each is a draw.',
		'',
		'Three rules surprise people:',
		'  - a move that would take EVERY seed your opponent has takes none;',
		'  - if your opponent has no seeds you must play a house that reaches',
		'    them, and if you cannot, you take your own seeds and the game ends;',
		'  - a game that will not end is stopped by a house rule, not a rule of',
		'    Oware. See the note when it happens.',
		'',
	);
	return;
}

sub _prompt_for {
	my ($self, $seat) = @_;

	my $game = $self->game;
	my @legal = @{ $game->legal($seat) };
	my @sowable = Game::Oware::Rules->sowable($game->board, $seat);

	if (@sowable > @legal) {
		my $them = Game::Oware::Board->other($seat);
		$self->_say('', $them . ' has no seeds, so you must play a house that'
			. ' reaches them: '
			. join(' ', map { Game::Oware::Notation->letter_of($_) } @legal));
	}

	return join ' ', map { Game::Oware::Notation->letter_of($_) } @legal;
}

sub _human_turn {
	my ($self) = @_;

	my $game = $self->game;
	my $seat = $self->seat;
	my $in   = $self->in;
	my $out  = $self->out;

	$self->_say('', $self->board_text($game, $seat));
	my $legal = $self->_prompt_for($seat);

	while (1) {
		print {$out} $self->_paint('your move') . " [$legal] > ";

		my $line = <$in>;
		my $command = $self->command($line);

		return 0 if $command eq 'quit';

		if ($command eq 'help') { $self->_help; next }
		if ($command eq 'again') { next }
		if ($command eq 'board') {
			$self->_say($self->board_text($game, $seat));
			next;
		}

		my $house = eval { Game::Oware::Notation->index_of($command) };
		if (!defined $house) {
			$self->_say('That is not a house. Type one of: ' . $legal);
			next;
		}

		my $out_of = $game->play($seat, $house);
		if (ref $out_of && $out_of->isa('Game::Oware::Error')) {
			$self->_say($out_of->message . '.');
			next;
		}

		$self->_narrate($out_of, $seat);
		return 1;
	}
}

sub _bot_turn {
	my ($self, $seat) = @_;

	my $game = $self->game;
	my $house = $self->bot->choose($game, $seat);
	return unless defined $house;

	my $move = $game->play($seat, $house);
	$self->_narrate($move, $seat) unless $self->quiet;

	return;
}

sub _narrate {
	my ($self, $move, $seat) = @_;
	return if $self->quiet;

	my $name = Game::Oware::Notation->letter_of($move->house);
	my $them = Game::Oware::Board->other($seat);

	$self->_say('', "$seat sows $name.");

	$self->_say('  The sow went right round, so it skipped '
		. "$name on the way past.")
		if $move->sown >= 12;

	if (@{ $move->forfeited }) {
		my $houses = join ', ',
			map { Game::Oware::Notation->letter_of($_) } @{ $move->forfeited };
		$self->_say("  That would have taken every seed $them has, from "
			. "$houses, so it takes none and they stay on the board.");
	}
	elsif (@{ $move->captured }) {
		my $houses = join ', ',
			map { Game::Oware::Notation->letter_of($_) } @{ $move->captured };
		$self->_say('  It captures ' . $move->taken . " seeds, from $houses.");
		$self->_say('  Every seed left on the board goes to ' . $them . '.')
			if $move->slammed;
	}

	return;
}

sub _finish {
	my ($self) = @_;

	my $game = $self->game;
	my $result = $game->result;

	$self->_say('', $self->board_text($game, $self->seat), '');

	unless ($result) {
		$self->_say('Stopped. Nobody won.');
		return;
	}

	my $reason = $result->reason;

	if ($reason eq 'no_feed') {
		my ($swept) = map { $_->{payload}{p} }
			grep { $_->{kind} eq 'sweep' } @{ $game->events };
		$self->_say("$swept had no move that could give the other side seeds,"
			. ' so it took every seed in its own territory and the game ended.');
	}
	elsif ($reason eq 'cycle') {
		my ($cycle) = grep { $_->{kind} eq 'cycle' } @{ $game->events };
		my $why = $cycle->{payload}{why} eq 'repetition'
			? 'the same position came round for the third time'
			: $cycle->{payload}{plies} . ' moves passed with nothing captured';
		$self->_say("This game was going nowhere: $why.",
			'So each side took the seeds on its own half.',
			'THAT IS A HOUSE RULE AND NOT A RULE OF OWARE. The published rule',
			'ends a cycle when both players agree, which is not something this',
			'program can ask you.');
	}

	$self->_say('', $result->stringify . '.');

	return;
}

1;

__END__

=head1 NAME

Game::Oware::Terminal - a playable game on two filehandles

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Terminal;

    my $terminal = Game::Oware::Terminal->new(level => 3, seat => 'p1');
    my $result = $terminal->start;

=head1 DESCRIPTION

=head2 It is separate from the engine on purpose

L<Game::Cribbage> is about a thousand lines of escape codes in its B<top level
namespace module>, so that only its C<::Board> was ever reusable by anything
else. This is a consumer of the engine exactly as a web adapter would be, and
the suite asserts that loading L<Game::Oware> does not pull this in.

=head2 in and out are properties

Defaulting to C<STDIN> and C<STDOUT>. That is what makes a terminal testable:
the suite drives a whole game in process against in-memory handles, with no
pipe, no fork, and no subprocess writing into the TAP stream.

=head2 start returns, and never exits

A module that calls C<exit> cannot be tested and cannot be embedded. The exit
status belongs to F<bin/oware>, which is the only part that knows it is a
program.

=head2 Every option is validated in the constructor

An unknown variant, an unknown level or a seat that does not exist all die from
C<BUILD>, before a game is built and before anything is printed.
C<Game::Reversi> validated its variant three calls deeper and shipped a
C<--variant draughts> that died with a raw Perl message and an exit status of
255.

=head2 Counts, not glyphs

Oware is a game about numbers and a pile of dots is unreadable past four, so the
board shows the seed count in each house. Two things follow.

The letters are the interface, so they are printed above and below the board and
the prompt takes one, matching L<Game::Oware::Notation> exactly. A terminal that
invented its own numbering would give the distribution two notations.

And there is B<no alternative glyph set to write> for C<--ascii>, unlike the
board games in this author's tree, because there are no glyphs. C<--ascii> still
picks the plain box drawing, and C<NO_COLOR> still beats everything.

=head2 The board is turned round for whoever is looking

Your own six houses are always the bottom row, because the whole spatial
vocabulary of this game is "your row" and "their row". B<The letters do not
move>: C<A> to C<F> is p1's side and C<a> to C<f> is p2's, in both views and in
every line of narration, so two people looking at one game can never disagree
about where a house is.

=head2 Four moments have to be said in words

Oware's failure mode on a terminal is that the board changes in ways the player
cannot account for, so each of these gets a sentence rather than being left to
be inferred:

=over

=item *

B<a forfeited slam>. A capturing move captures nothing. Unexplained, that is a
bug report.

=item *

B<a sow of twelve or more>, which skipped its own house on the way past, so the
counts do not add up by eye and the player will count them again.

=item *

B<the feeding rule>, when it has pruned the move list. The refusal message
exists, but a player who never tries the illegal move never sees it.

=item *

B<the cycle ending>, named as a house rule with the count that triggered it,
because a game ending on a rule no book contains has to say so.

=back

The failed-feed ending is a fifth: a seat that cannot move takes its own seeds,
which reads backwards to anybody who knows chess.

=head1 PROPERTIES

=head2 in

The handle to read from. Defaults to C<STDIN>.

=head2 out

The handle to write to. Defaults to C<STDOUT>.

=head2 level

The bot's level, 1 to 5.

=head2 variant

C<abapa> or C<awari>.

=head2 seat

Which seat the human plays, C<p1> or C<p2>.

=head2 seed

Passed to the game and, with a suffix, to the bot.

=head2 quiet

Suppress the narration and the banner.

=head2 ascii

Plain box drawing.

=head2 game

The L<Game::Oware> being played. Built by C<BUILD> unless one is supplied, which
is how the suite starts from a constructed position.

=head2 bot

The L<Game::Oware::Bot> playing the other seat.

=head1 METHODS

=head2 ansi

Whether to emit escapes. C<NO_COLOR> wins over everything; an explicit C<ansi>
option beats the tty check; otherwise it follows whether C<out> is a terminal.

Colour carries no information here: strip every escape and the board reads
exactly the same.

=head2 rows_for

The house indices of the top and bottom rows, from a seat's point of view.

=head2 board_text

The board as a list of lines, from a seat's point of view.

=head2 command

One line of input as an instruction: C<quit>, C<help>, C<board>, C<again> for an
empty line, or the text itself.

B<There is no single-letter shortcut for C<board>.> C<b> and C<B> are houses,
and the first draft of this module accepted C<b> as the command, so typing a
perfectly ordinary move redrew the board instead of playing it. C<q> and C<h>
are safe because no house is called either.

=head2 start

Plays the game and returns its L<Game::Oware::Result>, or C<undef> if the player
quit.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Bot>, L<Game::Oware::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
