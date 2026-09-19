package Game::Oware;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Carp ();

use Game::Oware::Board;
use Game::Oware::Move;
use Game::Oware::Error;
use Game::Oware::Rules;
use Game::Oware::Scoring;
use Game::Oware::Notation;
use Game::Oware::Result;
use Game::Oware::Variant ();

our $VERSION = '0.01';

has variant => (
	is      => 'ro',
	isa     => Str,
	default => 'abapa'
);

has board => (
	is  => 'rw',
	isa => ArrayRef
);

has turn => (is => 'rw');

has status => (
	is      => 'rw',
	isa     => Str,
	default => 'active'
);

has [qw/ winner result /] => (is => 'rw');

has log => (
	is      => 'rw',
	isa     => ArrayRef,
	default => []
);

has no_capture => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has seen => (
	is      => 'rw',
	isa     => HashRef,
	default => {}
);

has _held_seed => (
	is       => 'ro',
	init_arg => 'seed',
	private  => 1
);

sub BUILD {
	my ($self) = @_;

	Game::Oware::Variant::check_variant($self->variant);

	$self->board(Game::Oware::Board->opening) unless $self->board;
	Carp::croak('Game::Oware: a board is fourteen cells')
		unless @{ $self->board } == Game::Oware::Board->CELLS;

	$self->turn('p1') unless defined $self->turn;

	$self->_emit('sys', 'start', {
		variant => $self->variant,
		first   => $self->turn,
		board   => join(',', @{ $self->board }),
	});

	$self->_remember;

	return $self;
}

sub seats { return qw/ p1 p2 / }

sub events { return [ @{ $_[0]->log } ] }

sub other { return Game::Oware::Board->other($_[1]) }

sub captured { return Game::Oware::Scoring->captured($_[0]->board) }

sub score { return Game::Oware::Scoring->score($_[0]->board, $_[0]->status) }

sub scores {
	my ($self) = @_;
	my $captured = $self->captured;
	return { map { $_ => { current => $captured->{$_} } } $self->seats };
}

sub places {
	my ($self) = @_;
	return undef unless $self->status eq 'finished';
	return $self->result->places;
}

sub seed {
	my ($self) = @_;
	return undef unless $self->status eq 'finished';
	return $self->_held_seed;
}

sub legal {
	my ($self, $seat) = @_;
	return [] unless $self->status eq 'active';
	return [] unless defined $seat && $seat eq $self->turn;
	return [ Game::Oware::Rules->legal_moves($self->board, $seat, $self->variant) ];
}

sub waiting_on {
	my ($self) = @_;
	return () unless $self->status eq 'active';
	return ($self->turn);
}

sub play {
	my ($self, $seat, $house) = @_;

	return Game::Oware::Error->throw('game_over')
		unless $self->status eq 'active';

	return Game::Oware::Error->throw('not_your_turn')
		unless defined $seat && ($seat eq 'p1' || $seat eq 'p2')
		&& $seat eq $self->turn;

	Game::Oware::Board->assert_house($house);

	return Game::Oware::Error->throw('not_your_house')
		unless Game::Oware::Board->owner_of($house) eq $seat;

	return Game::Oware::Error->throw('empty_house')
		unless $self->board->[$house];

	my $legal = $self->legal($seat);
	return Game::Oware::Error->throw('must_feed', legal => [ @$legal ])
		unless grep { $_ == $house } @$legal;

	my ($next, $move) =
		Game::Oware::Rules->resolve($self->board, $house, $seat, $self->variant);

	$self->board($next);

	if ($move->taken) {
		$self->no_capture(0);
		$self->seen({});
	}
	else {
		$self->no_capture($self->no_capture + 1);
	}

	$self->_emit($seat, 'sow', {
		house     => $house,
		captured  => [ @{ $move->captured } ],
		taken     => $move->taken,
		slammed   => $move->slammed,
		forfeited => [ @{ $move->forfeited } ],
	});

	$self->_after($move);

	return $move;
}

sub timeout {
	my ($self, $seat) = @_;
	return Game::Oware::Error->throw('game_over')
		unless $self->status eq 'active';
	Carp::croak('Game::Oware: a seat is p1 or p2')
		unless defined $seat && ($seat eq 'p1' || $seat eq 'p2');

	$self->_emit('sys', 'timeout', { p => $seat });
	return $self->_finish($self->other($seat), 'timeout', 'timeout');
}

sub abandon {
	my ($self) = @_;
	return Game::Oware::Error->throw('game_over')
		unless $self->status eq 'active';

	$self->_emit('sys', 'abandon', {});
	return $self->_finish(undef, 'abandoned', 'abandon');
}

sub resign {
	my ($self, $seat) = @_;
	return Game::Oware::Error->throw('game_over')
		unless $self->status eq 'active';
	Carp::croak('Game::Oware: a seat is p1 or p2')
		unless defined $seat && ($seat eq 'p1' || $seat eq 'p2');

	$self->_emit($seat, 'resign', {});
	return $self->_finish($self->other($seat), 'resign', 'resign');
}

sub clone {
	my ($self) = @_;
	my $copy = Object::Proto::clone($self);
	$copy->board([ @{ $self->board } ]);
	$copy->log([ map { { %$_, payload => { %{ $_->{payload} } } } } @{ $self->log } ]);
	$copy->seen({ %{ $self->seen } });
	return $copy;
}

sub to_text {
	my ($self) = @_;
	return Game::Oware::Notation->render(
		[ map { $_->{payload}{house} } grep { $_->{kind} eq 'sow' } @{ $self->log } ]);
}

sub from_text {
	my ($class, $text, %options) = @_;
	my $game = $class->new(%options);
	for my $house (@{ Game::Oware::Notation->parse($text) }) {
		my $out = $game->play($game->turn, $house);
		Carp::croak('Game::Oware: the transcript does not play: ' . $out->stringify)
			if ref $out && $out->isa('Game::Oware::Error');
	}
	return $game;
}

sub replay {
	my ($self, $log) = @_;

	Carp::croak('Game::Oware: a log is an arrayref of events')
		unless ref $log eq 'ARRAY';
	Carp::croak('Game::Oware: replay wants a game that has not been played')
		unless @{ $self->log } == 1;

	my @events = @$log;
	my $start = shift @events;
	Carp::croak('Game::Oware: the log does not open with a start')
		unless $start && ($start->{actor} // '') eq 'sys'
		&& ($start->{kind} // '') eq 'start';
	Carp::croak('Game::Oware: the log was made under a different variant')
		unless ($start->{payload}{variant} // '') eq $self->variant;

	my $began = join ',', @{ $self->board };
	my $logged = $start->{payload}{board};
	Carp::croak('Game::Oware: the log began from a different position')
		if defined($logged) && $logged ne $began;

	for my $event (@events) {
		my $actor = $event->{actor} // '';
		my $kind  = $event->{kind}  // '';

		if ($actor eq 'sys') {
			$self->timeout($event->{payload}{p}) if $kind eq 'timeout';
			$self->abandon                       if $kind eq 'abandon';
			next;
		}

		my $out = $kind eq 'resign'
			? $self->resign($actor)
			: $self->play($actor, $event->{payload}{house});
		Carp::croak('Game::Oware: the log does not replay: ' . $out->stringify)
			if ref $out && $out->isa('Game::Oware::Error');
	}

	my $ours   = join '|', map { _signature($_) } @{ $self->log };
	my $theirs = join '|', map { _signature($_) } @$log;
	Carp::croak('Game::Oware: the log does not replay to itself, so it records '
		. 'something this game would not have produced')
		unless $ours eq $theirs;

	return $self;
}

sub _emit {
	my ($self, $actor, $kind, $payload) = @_;
	push @{ $self->log },
		{ actor => $actor, kind => $kind, payload => $payload || {} };
	return;
}

sub _key {
	my ($self) = @_;
	return join(',', @{ $self->board }) . ':' . $self->turn;
}

sub _remember {
	my ($self) = @_;
	my $seen = $self->seen;
	return ++$seen->{ $self->_key };
}

sub _after {
	my ($self, $move) = @_;

	my $target = Game::Oware::Scoring->target_reached($self->board);
	return $self->_finish($target, 'score', 'target') if $target;

	return $self->_finish(undef, 'draw', 'even')
		if Game::Oware::Scoring->is_draw($self->board);

	my $limit = Game::Oware::Variant::plies_without_capture($self->variant);
	if ($self->no_capture >= $limit) {
		$self->board(Game::Oware::Scoring->sweep_split($self->board));
		$self->_emit('sys', 'cycle', { why => 'plies', plies => $self->no_capture });
		return $self->_settle('cycle');
	}

	$self->turn($self->other($move->seat));

	my $repeats = $self->_remember;
	if ($repeats >= Game::Oware::Variant::repetition_limit($self->variant)) {
		$self->board(Game::Oware::Scoring->sweep_split($self->board));
		$self->_emit('sys', 'cycle', { why => 'repetition', times => $repeats });
		return $self->_settle('cycle');
	}

	unless (@{ $self->legal($self->turn) }) {
		my $swept = $self->turn;
		$self->board(Game::Oware::Scoring->sweep_to($self->board, $swept));
		$self->_emit('sys', 'sweep', { p => $swept, why => 'no_feed' });
		return $self->_settle('no_feed');
	}

	return;
}

sub _settle {
	my ($self, $reason) = @_;

	my $captured = $self->captured;
	return $self->_finish(undef, 'draw', $reason)
		if $captured->{p1} == $captured->{p2};

	my $winner = $captured->{p1} > $captured->{p2} ? 'p1' : 'p2';
	return $self->_finish($winner, 'score', $reason);
}

sub _finish {
	my ($self, $winner, $result, $reason) = @_;

	$self->status('finished');
	$self->winner($winner);

	my $captured = $self->captured;
	my $natural  = $result eq 'score' || $result eq 'draw';

	my %places = defined $winner
		? ($winner => 1, $self->other($winner) => 2)
		: (p1 => 1, p2 => 1);

	my $done = Game::Oware::Result->new(
		winner   => $winner,
		result   => $result,
		reason   => $reason,
		captured => $captured,
		($natural ? (score => $captured) : ()),
		places   => \%places,
	);

	$self->result($done);
	$self->_emit('sys', 'game_end', {
		winner   => $winner,
		result   => $result,
		reason   => $reason,
		captured => $captured,
	});

	return $done;
}

sub _signature {
	my ($event) = @_;
	my $payload = $event->{payload} || {};
	my @pairs;
	for my $key (sort keys %$payload) {
		my $value = $payload->{$key};
		$value = join '.', @$value if ref $value eq 'ARRAY';
		$value = join ';', map { "$_=" . ($value->{$_} // '') } sort keys %$value
			if ref $value eq 'HASH';
		push @pairs, $key . '=' . (defined $value ? $value : '');
	}
	return ($event->{actor} // '') . ':' . ($event->{kind} // '')
		. ':' . join(',', @pairs);
}

1;

__END__

=head1 NAME

Game::Oware - the African sow and capture game, Abapa rules

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware;

    my $game = Game::Oware->new(seed => $bytes);

    while ($game->status eq 'active') {
        my ($seat) = $game->waiting_on;
        my $house  = $game->legal($seat)->[0];
        $game->play($seat, $house);
    }

    print $game->result->stringify;

=head1 DESCRIPTION

Twelve houses, two stores and forty-eight seeds. Two seats, no hidden
information, and no randomness at all.

It is the engine behind the oware at L<https://peer2peergames.com>.

=head2 Refusals are returned, never thrown

C<play> gives back a L<Game::Oware::Move> or a L<Game::Oware::Error>, and the
error is an object with a flag on it. Nothing a player can do causes this module
to die.

C<die> is for programmer error: a house index outside 0 to 11, an unknown
variant, a seat that does not exist, a log that does not replay. A consumer
validates its own input at its own boundary and this engine assumes it did.

=head2 The move log is the canonical serialisation, not the position

Two identical boards can differ in how many plies have passed since a capture
and in how many times the position has already occurred, and under the cycle
rule both decide the result. So a board cannot resume a game, and that is a fact
about these rules rather than a preference about event sourcing.

A C<sow> event carries the house and what the move did with it. On replay the
house is applied and everything else is B<recomputed and compared>, so a log
claiming a capture the rules would not have made is refused rather than
believed.

=head2 The cycle rule is a HOUSE RULE and is not the rule of Oware

The published rule is:

    "If both players agree that the game has been reduced to an endless cycle,
     the game ends when each player has seeds in their holes and then each
     player captures the seeds on their side of the board."

B<"If both players agree" has no mechanism> where one seat is a program and
there is a deadline. So the ending is kept and the trigger is replaced, and
anything presenting this game to a player has to say so in as many words rather
than implying a book says it.

Two triggers, either of which fires, both ending in
L<Game::Oware::Scoring/sweep_split>:

=over

=item * the same position, with the same seat to move, for the third time;

=item * C<plies_without_capture> plies with no seed entering either store.

=back

=head2 Why both triggers, and why the table can be cleared

Seeds go into a store and never come out, so a capture changes the stores
monotonically and B<a position can only ever repeat inside a capture-free
stretch>. Three things follow, and the second is the one that makes this cheap:

=over

=item *

repetition is strictly contained in the ply counter's window, so it is the fast
path and the counter is the outer bound;

=item *

the repetition table can be B<cleared on every capture>, so it never grows past
the cap and costs nothing to keep;

=item *

a shuffle that never repeats a position is exactly what repetition cannot see,
which is what the counter is for.

=back

Without that argument written down the second trigger reads as belt and braces
and somebody deletes it.

=head2 There are four natural endings and two result tokens

A store reaching twenty-five, both stores reaching twenty-four, the seat on turn
being unable to feed a starved opponent, and the cycle rule. The first and third
and fourth are all C<score> or C<draw>; which one happened is
L<Game::Oware::Result/reason>.

The order they are checked in after a move is fixed and matters: target, then
the level draw, then the ply counter, then the turn advances, then repetition,
then the failed feed. The sweeps run B<before> the result is decided, because a
sweep can carry a store past twenty-five and that is a win rather than whatever
the score was a moment earlier.

=head2 The seed is stored, published at the end, and never read

Oware has no randomness in it: no deal, no dice, no shuffle. The seed is held
because a consumer that hands every game some bytes and publishes them when it
finishes, so that a completed game can be checked, would otherwise have one game
for which that page is empty.

B<Do not remove it on the grounds that nothing reads it.> C<seed> returns
C<undef> until the game is over, and the value lives in a private property so
that gate is the only way to it.

=head1 PROPERTIES

=head2 variant

C<abapa> by default. See L<Game::Oware::Variant>.

=head2 board

The fourteen cells. See L<Game::Oware::Board>.

=head2 turn

The seat to move, C<p1> or C<p2>. p1 opens.

=head2 status

C<active> or C<finished>.

=head2 winner

C<p1>, C<p2>, or C<undef>.

=head2 result

A L<Game::Oware::Result> once finished.

=head2 log

The events, oldest first.

=head2 no_capture

How many plies have passed with no seed entering a store. Part of the position
for the cycle rule, which is why it is here and not on the board.

=head2 seen

How many times each position has occurred, cleared by every capture.

=head1 METHODS

=head2 seats

C<p1> and C<p2>, in order.

=head2 events

A copy of the log.

=head2 other

The other seat.

=head2 captured

The running totals.

=head2 score

The official result, or C<undef> while the game is active.

=head2 scores

C<< { p1 => { current => N }, p2 => { current => N } } >>, which is the shape a
scoreboard wants.

=head2 places

The finishing order, or C<undef> while the game is running. It is not a live
standing: a player with forty seeds in their row has captured nothing.

=head2 seed

The seed, once the game has finished.

=head2 legal

An arrayref of the houses a seat may play. Empty off turn, and empty once the
game is over.

=head2 waiting_on

The seat on turn, or nothing.

=head2 play

    my $out = $game->play('p1', 4);

A L<Game::Oware::Move>, or a L<Game::Oware::Error>.

=head2 timeout

Finishes the game with the other seat as winner. The clock is the caller's.

=head2 abandon

Finishes the game with no winner.

=head2 resign

Finishes the game with the other seat as winner.

=head2 clone

A deep enough copy to play on independently.

=head2 to_text

The game as a transcript of house letters.

=head2 from_text

    Game::Oware->from_text('EcAb', seed => $bytes);

A game played out from a transcript. Croaks if the transcript does not play.

=head2 replay

Rebuilds this game from a log. Only the player events are applied; every C<sys>
event is regenerated from the position, and the resulting log must then match
what was handed in.

So a log carrying a capture the rules would not have made, a sweep at a position
where a feeding move existed, or a cycle ending before the counter reached the
cut, is refused. Those are the cheapest possible cheats in this game, because
each of them awards seeds.

=head1 SEE ALSO

L<Game::Oware::Board>, L<Game::Oware::Rules>, L<Game::Oware::Variant>,
L<Game::Oware::Result>, L<Game::Oware::Error>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
