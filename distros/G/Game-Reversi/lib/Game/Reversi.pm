package Game::Reversi;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Carp ();

use Game::Reversi::Board;
use Game::Reversi::Move;
use Game::Reversi::Error;
use Game::Reversi::Opening;
use Game::Reversi::Rules;
use Game::Reversi::Notation;
use Game::Reversi::Scoring;
use Game::Reversi::Result;

our $VERSION = '0.01';

has variant => (
	is      => 'ro',
	isa     => Str,
	default => 'historic'
);

has turn => (
	is => 'rw'
);

has board => (
	is  => 'rw',
	isa => ArrayRef
);

has status => (
	is      => 'rw',
	isa     => Str,
	default => 'active'
);

has [qw/winner result/] => (
	is => 'rw'
);

has log => (
	is      => 'rw',
	isa     => ArrayRef,
	default => []
);

has _held_seed => (
	is       => 'ro',
	init_arg => 'seed',
	private  => 1
);

sub BUILD {
	my ($self) = @_;
	my $variant = $self->variant;
	Carp::croak("Game::Reversi: there is no variant '$variant'")
		unless Game::Reversi::Opening->describes($variant);

	my $given = defined $self->board ? 1 : 0;
	$self->board($given ? [ @{ $self->board } ]
		: Game::Reversi::Opening->board_for($variant));
	Carp::croak('Game::Reversi: a board is an arrayref of 64 cells')
		unless @{ $self->board } == 64;

	my $first = defined $self->turn ? $self->turn : Game::Reversi::Opening->first;
	$self->turn(Game::Reversi::Rules->opening_turn($self->board, $first));
	$self->log([]);

	$self->_emit('sys', 'start', {
		variant => $variant,
		first   => $first,
		($given ? (board => join '', map { defined $_ ? $_ : '.' } @{ $self->board }) : ()),
	});

	$self->_finish unless defined $self->turn;
	return $self;
}

sub from_board {
	my ($class, $board, %o) = @_;
	Carp::croak('Game::Reversi: a board is an arrayref of 64 cells')
		unless ref $board eq 'ARRAY' && @$board == 64;
	return $class->new(%o, board => $board);
}

sub seats  { return ('b', 'w') }
sub events { return [ @{ $_[0]->log } ] }

sub places {
	my ($self) = @_;
	return undef unless $self->result;
	return $self->result->places;
}

sub phase {
	my ($self) = @_;
	return Game::Reversi::Rules->in_opening($self->board) ? 'opening' : 'play';
}

sub seed {
	my ($self) = @_;
	return undef unless $self->status eq 'finished';
	return $self->_held_seed;
}

sub counts { return Game::Reversi::Scoring->count($_[0]->board) }

sub score {
	my ($self) = @_;
	return undef unless $self->result && $self->result->natural;
	return $self->result->score;
}

sub scores {
	my ($self) = @_;
	my $count = $self->counts;
	return { map { $_ => { current => $count->{$_} } } $self->seats };
}

sub legal {
	my ($self, $colour) = @_;
	return [] unless $self->status eq 'active';
	return [] unless defined $colour && defined $self->turn;
	return [] unless $colour eq $self->turn;
	return [ Game::Reversi::Rules->legal($self->board, $colour) ];
}

sub waiting_on {
	my ($self) = @_;
	return () unless $self->status eq 'active' && defined $self->turn;
	return ($self->turn);
}

sub play {
	my ($self, $colour, $square) = @_;

	return Game::Reversi::Error->throw('game_over')
		unless $self->status eq 'active';
	return Game::Reversi::Error->throw('not_your_turn')
		unless defined $colour && defined $self->turn && $colour eq $self->turn;

	my $move;
	if (Game::Reversi::Rules->in_opening($self->board)) {
		my $error = Game::Reversi::Opening->check($self->board, $square);
		return $error if $error;
		$move = Game::Reversi::Move->place($square, $colour);
		$self->board(Game::Reversi::Opening->apply($self->board, $square, $colour));
		$self->_emit($colour, 'place', { square => $square });
	}
	else {
		return Game::Reversi::Error->throw('square_taken',
			legal => [ map { $_->square } @{ $self->legal($colour) } ])
			if defined $square && $square >= 0 && $square < 64
			&& defined $self->board->[$square];

		my @flips = Game::Reversi::Board->flips_for($self->board, $square, $colour);
		return Game::Reversi::Error->throw('no_flip',
			legal => [ map { $_->square } @{ $self->legal($colour) } ])
			unless @flips;

		$move = Game::Reversi::Move->play($square, $colour, @flips);
		$self->board(Game::Reversi::Board->apply($self->board, $square, $colour));
		$self->_emit($colour, 'play', { square => $square, flips => [ @flips ] });
	}

	$self->_advance($colour);
	return $move;
}

sub pass {
	my ($self, $colour) = @_;
	return Game::Reversi::Error->throw('game_over')
		unless $self->status eq 'active';
	return Game::Reversi::Error->throw('not_your_turn')
		unless defined $colour && defined $self->turn && $colour eq $self->turn;
	return Game::Reversi::Error->throw('has_move',
		legal => [ map { $_->square } @{ $self->legal($colour) } ]);
}

sub clone {
	my ($self) = @_;
	my $copy = Object::Proto::clone($self);
	$copy->board([ @{ $self->board } ]);
	$copy->log([ map { { %$_, payload => { %{ $_->{payload} } } } } @{ $self->log } ]);
	return $copy;
}

sub _emit {
	my ($self, $actor, $kind, $payload) = @_;
	push @{ $self->log }, { actor => $actor, kind => $kind, payload => $payload || {} };
	return;
}

sub _advance {
	my ($self, $just_moved) = @_;
	my ($turn, $forfeited) =
		Game::Reversi::Rules->next_turn($self->board, $just_moved);

	$self->_emit('sys', 'pass', { colour => $forfeited })
		if defined $forfeited && defined $turn;

	$self->turn($turn);
	$self->_finish unless defined $turn;
	return;
}

sub _finish {
	my ($self, $winner, $result) = @_;
	my $count = $self->counts;

	if (!defined $result) {
		$winner = Game::Reversi::Scoring->winner($self->board);
		$result = defined $winner ? 'score' : 'draw';
	}

	my $natural = ($result eq 'score' || $result eq 'draw') ? 1 : 0;
	$self->winner($winner);
	$self->status('finished');
	$self->turn(undef);
	$self->result(Game::Reversi::Result->new(
		winner => $winner,
		result => $result,
		counts => $count,
		score  => $natural ? Game::Reversi::Scoring->score($self->board) : undef,
		places => {
			map { $_ => (!defined $winner ? 1 : $_ eq $winner ? 1 : 2) } $self->seats
		},
	));

	$self->_emit('sys', 'game_end', { winner => $winner, result => $result });
	return;
}

sub timeout {
	my ($self, $colour) = @_;
	return Game::Reversi::Error->throw('game_over')
		unless $self->status eq 'active';
	Carp::croak('Game::Reversi: timeout wants the seat that ran out')
		unless defined $colour && ($colour eq 'b' || $colour eq 'w');

	$self->_emit('sys', 'timeout', { colour => $colour });
	$self->_finish(Game::Reversi::Board->other($colour), 'timeout');
	return $self->result;
}

sub abandon {
	my ($self) = @_;
	return Game::Reversi::Error->throw('game_over')
		unless $self->status eq 'active';
	$self->_emit('sys', 'abandon', {});
	$self->_finish(undef, 'abandoned');
	return $self->result;
}

sub resign {
	my ($self, $colour) = @_;
	return Game::Reversi::Error->throw('game_over')
		unless $self->status eq 'active';
	return Game::Reversi::Error->throw('not_your_turn')
		unless defined $colour && ($colour eq 'b' || $colour eq 'w');

	$self->_emit($colour, 'resign', {});
	$self->_finish(Game::Reversi::Board->other($colour), 'resign');
	return $self->result;
}

sub replay {
	my ($self, $log) = @_;
	Carp::croak('Game::Reversi: a log is an arrayref of events')
		unless ref $log eq 'ARRAY';
	Carp::croak('Game::Reversi: replay wants a game that has not been played')
		unless @{ $self->log } == 1;

	my @events = @$log;
	my $start = shift @events;
	Carp::croak('Game::Reversi: the log does not open with a start')
		unless $start && ($start->{actor} // '') eq 'sys'
		&& ($start->{kind} // '') eq 'start';
	Carp::croak('Game::Reversi: the log was made under a different variant')
		unless ($start->{payload}{variant} // '') eq $self->variant;

	my $began = join '', map { defined $_ ? $_ : '.' } @{ $self->board };
	my $logged = $start->{payload}{board};
	Carp::croak('Game::Reversi: the log began from a different position')
		if defined($logged) && $logged ne $began;

	for my $event (@events) {
		my $kind = $event->{kind} // '';

		if (($event->{actor} // '') eq 'sys') {
			$self->timeout($event->{payload}{colour}) if $kind eq 'timeout';
			$self->abandon                            if $kind eq 'abandon';
			next;
		}

		my $result = $kind eq 'resign'
			? $self->resign($event->{actor})
			: $self->play($event->{actor}, $event->{payload}{square});
		Carp::croak('Game::Reversi: the log does not replay: '
			. $result->stringify)
			if ref $result && $result->isa('Game::Reversi::Error');
	}

	my $ours   = join '|', map { _signature($_) } @{ $self->log };
	my $theirs = join '|', map { _signature($_) } @$log;
	Carp::croak('Game::Reversi: the log does not replay to itself, so it '
		. 'records something this game would not have produced')
		unless $ours eq $theirs;

	return $self;
}

sub _signature {
	my ($event) = @_;
	my $payload = $event->{payload} || {};
	return join ':', $event->{actor} // '?', $event->{kind} // '?',
		join ',', map {
			my $v = $payload->{$_};
			$_ . '=' . (ref $v eq 'ARRAY' ? join('.', @$v) : defined $v ? $v : '')
		} sort keys %$payload;
}

sub to_text {
	my ($self) = @_;
	return Game::Reversi::Notation->render(
		[ map { $_->{payload}{square} }
		  grep { $_->{kind} eq 'place' || $_->{kind} eq 'play' } @{ $self->log } ]);
}

sub from_text {
	my ($class, $text, %o) = @_;
	my $self = $class->new(%o);
	for my $square (@{ Game::Reversi::Notation->parse($text) }) {
		my $result = $self->play($self->turn, $square);
		Carp::croak('Game::Reversi: the transcript does not fit this game: '
			. $result->stringify) if ref $result && $result->can('error');
	}
	return $self;
}

1;

__END__

=head1 NAME

Game::Reversi - the board game of 1883, with its own opening

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $game = Game::Reversi->new(variant => 'historic', seed => $bytes);

    while ($game->status eq 'active') {
        my $moves = $game->legal($game->turn);
        my $result = $game->play($game->turn, $moves->[0]->square);
        die $result->message if ref $result && $result->error;
    }

    $game->winner;      # 'b', 'w', or undef for a tie
    $game->to_text;     # the transcript

=head1 DESCRIPTION

Reversi. Two players, an 8x8 board, and discs that turn when they are
outflanked.

It is the engine behind the reversi at L<https://peer2peergames.com>.

=head2 This is Reversi, not Othello, and the difference is the opening

They are different games. Wikipedia:

=over 4

B<Reversi> is an abstract strategy board game for two players, played on an 8x8
uncheckered board. It was invented in 1883. I<Othello>, a variant with a fixed
initial setup of the board, was patented in 1971.

=back

Othello starts with four discs already on the two centre diagonals. Reversi
starts empty and the players place those four discs themselves, capturing
nothing. That opening is the default here, and it is why the distribution can
carry this name: "Othello" is a registered trademark, owned outside Japan by
MegaHouse, while Reversi is the free ancestor it was built from.

The historic opening reaches B<six> distinct positions, of which the Othello
position is one. See L<Game::Reversi::Opening>. The Othello start is available
as C<< variant => 'othello' >>.

=head2 Refusals are returned, never thrown

Every rejection a player can cause comes back as a L<Game::Reversi::Error>, so a
caller tests a return value and never wraps a move in C<eval>. C<die> is kept
for programmer error.

=head2 The move log is the canonical serialisation, not the position

Two identical boards can have different sides to move, depending on whether a
turn was just forfeited. So a position alone cannot resume a game. That is a
fact about this game's rules rather than a preference about event sourcing.

=head1 METHODS

=head2 new

C<variant> defaults to C<historic>. C<seed> is stored and never consulted; see
L</seed>.

=head2 from_board

A game from a position rather than from the beginning. Takes the board and
optionally C<turn>, C<variant> and C<seed>. It is C<new> with the board handed
in: C<turn> is the side to move if it can, and the rules decide if it cannot. A colour that cannot move in that
position does not get the turn; the rules forfeit for it.

The position is recorded in the start event, so such a game still replays, and
L</replay> refuses a log that began from a different one.

=head2 variant, board, status, turn, winner, seats, phase, log

The state. C<phase> is C<opening> while the first four discs are being placed
and C<play> afterwards. C<winner> is C<undef> for a tie.

C<log> is the events as the game holds them, and L</events> is a copy of that
list: append to the one this returns and you are appending to the game's own
record of itself.

=head2 seed

The seed, and only once the game is finished. It is held in a private property
rather than a plain one, so this gate is the only way to it.

B<Reversi has no randomness in it at all>, so this is never consulted. It is
stored because the site that consumes this engine hands every game 32 bytes and
publishes them at the end so that a finished game can be checked; an engine that
dropped the seed would quietly break that page for this one game. Do not remove
it on the grounds that nothing reads it.

=head2 result

A L<Game::Reversi::Result> once the game is over, and C<undef> before.

=head2 places

The finishing order, C<1> for the winner and C<2> for the loser, both C<1> on a
tie. C<undef> while the game is running: a Reversi position in progress has no
standings worth the name, because the side ahead on discs in the midgame is very
often the side losing.

=head2 score

The official score, and only once the game has reached its own end. See
L</timeout> for why a game that was stopped does not get one.

=head2 timeout

Ends the game, with the seat named as the one that ran out and the other as the
winner.

B<The engine takes no view on what a timeout is worth.> The sources give three
different answers: WOF's championship rules guarantee the non-defaulting player
at least 33-31, the same document scores an abandoned game 64-0, and Wikipedia
describes a common procedure guaranteeing only a one disc margin while conceding
that "There are varying methods to determine the official score when a player
defaults". A timeout is the host talking, and whatever is running the game
already has a policy. So the result names the winner, C<counts> says what was on
the board, and L</score> is C<undef>.

This matters far more in correspondence play than over a board, where a default
is rare.

=head2 abandon

Ends the game with no winner at all.

=head2 resign

Ends the game with the other seat as the winner. Unlike a timeout this is a move
a player made, so it appears in the log as theirs rather than as the engine's.

=head2 counts

Discs on the board, by colour. B<Not the final score>: a game that ends with
squares still empty awards them to the winner. The two are separate names on
purpose, so that a midgame reading cannot reach for the end of game rule.

=head2 scores

The same counts in the shape the site wants.

=head2 legal

The moves open to a seat, as L<Game::Reversi::Move> objects. Placements during
the opening, plays afterwards, and B<never a pass>. Empty for the seat not on
turn and empty once the game is over.

=head2 waiting_on

The seat on turn, or nothing.

=head2 play

Plays a square. Returns the L<Game::Reversi::Move> made, or a
L<Game::Reversi::Error>.

=head2 pass

Always an error, C<has_move>. WOF rule 2 forbids forfeiting a turn you can play,
and a seat on turn always can, because the engine forfeits automatically for a
seat that cannot. There is no way to reach this method legitimately, and it
exists so that a caller which offers a pass button gets a sentence to show
rather than silence.

=head2 clone

A deep enough copy to search from: the board and the log are copied and
everything else is shared. It copies the object rather than building a new one,
because a constructor would deal the opening again and emit a start event, and
the state worth cloning is exactly the state a constructor does not take.

=head2 events

The log: C<sys start>, C<place>, C<play>, C<sys pass>, C<sys game_end>.

=head2 replay

Rebuilds this game from a log. Only the player events are applied; every C<sys>
event is regenerated from the position, and the resulting log must then match
what was handed in. So a log carrying a pass at a position where that seat could
have moved is refused, which matters because B<a forged pass is the cheapest
possible cheat in this game>: it hands the opponent's turn back to you.

=head2 to_text, from_text

The squares played, in order, as a transcript. Placements and plays alike, since
both are squares and which is which follows from how many came before.

=head1 SEE ALSO

L<Game::Reversi::Board>, L<Game::Reversi::Opening>, L<Game::Reversi::Rules>,
L<Game::Reversi::Move>, L<Game::Reversi::Notation>, L<Game::Reversi::Error>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
