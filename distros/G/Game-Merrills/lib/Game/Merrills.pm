package Game::Merrills;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp ();
use Object::Proto::Sugar -types;
use Game::Merrills::Points;
use Game::Merrills::Board;
use Game::Merrills::Move;
use Game::Merrills::Notation;
use Game::Merrills::Rules;
use Game::Merrills::Error;
use Game::Merrills::Result;

use constant NO_MILL_PLIES => 100;

our $NO_MILL_LIMIT = NO_MILL_PLIES;

my %OTHER = (white => 'black', black => 'white');
my $OPENING = '........................ w 9 9 0 0';

has [qw/position turn/] => (
	is => 'rw',
	isa => Str
);

has flying => (
	is => 'rw',
	isa => Bool,
	default => 1
);

has [qw/result draw_offered_by _legal _position/] => (
	is => 'rw'
);

has [qw/history _undo/] => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { [] }
);

has [qw/no_mill _base_ply/] => (
	is => 'rw',
	isa => Int,
	default => 0
);

has repetition => (
	is => 'rw',
	isa => HashRef,
	default => sub { {} }
);

sub BUILD {
	my ($self) = @_;
	my $start = Game::Merrills::Notation::parse_position(
		defined $self->position ? $self->position : $OPENING
	);
	$self->position(Game::Merrills::Notation::format_position($start));
	$self->_position([ @{ $start->{cells} }, @{ $start->{hand} }{qw/white black/} ]);
	$self->turn($start->{turn});
	$self->no_mill($start->{no_mill});
	$self->_base_ply($start->{ply});
	$self->flying($self->flying ? 1 : 0);
	$self->repetition->{ $self->_key }++ if $self->_counting;
	$self->_check_end;
	return $self;
}

sub status {
	return $_[0]->result ? 'finished' : 'active';
}

sub ply {
	return $_[0]->_base_ply + scalar @{ $_[0]->history };
}

sub board {
	return Game::Merrills::Rules::board($_[0]->_position);
}

sub in_hand {
	my ($self, $side) = @_;
	return $self->_position->[
		$self->_side($side) eq 'white'
			? Game::Merrills::Rules::HAND_WHITE
			: Game::Merrills::Rules::HAND_BLACK
	];
}

sub on_board {
	my ($self, $side) = @_;
	my $value = $Game::Merrills::Board::VALUE{ $self->_side($side) };
	return scalar grep { $_ == $value } @{ $self->_position }[ 0 .. 23 ];
}

sub men {
	my ($self, $side) = @_;
	return $self->on_board($side) + $self->in_hand($side);
}

sub phase {
	return $_[0]->phase_of($_[0]->turn);
}

sub phase_of {
	my ($self, $side) = @_;
	return Game::Merrills::Rules::phase($self->_position, $self->_side($side), $self->flying);
}

sub legal_moves {
	my ($self) = @_;
	my $legal = $self->_legal;
	return $legal if $legal;
	$legal = [];
	unless ($self->result) {
		my $turn = $self->turn;
		$legal = [
			map { Game::Merrills::Move->from_raw($_, $turn) }
			@{ Game::Merrills::Rules::generate($self->_position, $turn, $self->flying) }
		];
	}
	$self->_legal($legal);
	return $legal;
}

sub legal_moves_for {
	my ($self, $point) = @_;
	Game::Merrills::Points::_check($point);
	return [
		grep { (defined $_->from ? $_->from : $_->to) == $point } @{ $self->legal_moves }
	];
}

sub move {
	my ($self, $move) = @_;
	return $self->_error('game_over') if $self->result;

	my $want = $self->_parse($move)
		or return $self->_error('not_a_move');

	for my $legal (@{ $self->legal_moves }) {
		next unless $legal->to == $want->{to};
		next unless _same($legal->from, $want->{from});
		next unless _same($legal->remove, $want->{remove});
		return $self->_play($legal);
	}
	return $self->_diagnose($want);
}

sub undo {
	my ($self) = @_;
	my $record = pop @{ $self->_undo }
		or return $self->_error('nothing_to_undo');
	my $move = pop @{ $self->history };

	if ($record->{counted}) {
		my $key = $self->_key;
		delete $self->repetition->{$key} unless --$self->repetition->{$key};
	}
	$self->repetition($record->{repetition}) if $record->{repetition};

	$self->turn($OTHER{ $self->turn });
	Game::Merrills::Rules::unapply($self->_position, $self->turn, $record->{raw});
	$self->no_mill($record->{no_mill});
	$self->draw_offered_by($record->{draw_offered_by});
	$self->result(undef);
	$self->_legal(undef);
	return $move;
}

sub resign {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	return $self->_finish($OTHER{$side}, 'resign');
}

sub timeout {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	return $self->_finish($OTHER{$side}, 'timeout');
}

sub offer_draw {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	$self->draw_offered_by($side);
	return $side;
}

sub accept_draw {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	my $offered = $self->draw_offered_by;
	return $self->_error('no_offer') unless $offered && $offered ne $side;
	return $self->_finish(undef, 'agreement');
}

sub decline_draw {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	my $offered = $self->draw_offered_by;
	return $self->_error('no_offer') unless $offered && $offered ne $side;
	$self->draw_offered_by(undef);
	return $side;
}

sub to_position {
	my ($self) = @_;
	my $position = $self->_position;
	return Game::Merrills::Notation::format_position({
		cells => [ @{$position}[ 0 .. 23 ] ],
		turn => $self->turn,
		hand => {
			white => $position->[Game::Merrills::Rules::HAND_WHITE],
			black => $position->[Game::Merrills::Rules::HAND_BLACK],
		},
		no_mill => $self->no_mill,
		ply => $self->ply,
	});
}

sub from_position {
	my ($class, $position, %option) = @_;
	return $class->new(%option, position => $position);
}

sub to_text {
	my ($self) = @_;
	return Game::Merrills::Notation::format_record(
		[ map { $_->notation } @{ $self->history } ],
		$self->position eq $OPENING ? () : (position => $self->position)
	);
}

sub from_text {
	my ($class, $text, %option) = @_;
	my $moves = Game::Merrills::Notation::parse_record($text);
	my $position = Game::Merrills::Notation::record_position($text);
	my $self = $class->new(%option, defined $position ? (position => $position) : ());
	my $number = 0;
	for my $move (@{$moves}) {
		$number++;
		my $played = $self->move($move);
		next unless ref $played eq 'Game::Merrills::Error';
		die "illegal record: move $number, '"
			. Game::Merrills::Notation::format_move($move) . "': " . $played->message . "\n";
	}
	return $self;
}

sub clone {
	my ($self) = @_;
	my $clone = ref($self)->new(position => $self->position, flying => $self->flying);
	$clone->_position([ @{ $self->_position } ]);
	$clone->turn($self->turn);
	$clone->history([ @{ $self->history } ]);
	$clone->_undo([
		map {
			{ %{$_}, $_->{repetition} ? (repetition => { %{ $_->{repetition} } }) : () }
		} @{ $self->_undo }
	]);
	$clone->no_mill($self->no_mill);
	$clone->repetition({ %{ $self->repetition } });
	$clone->draw_offered_by($self->draw_offered_by);
	$clone->result($self->result);
	$clone->_legal(undef);
	return $clone;
}

sub _same {
	my ($one, $two) = @_;
	return defined $one ? (defined $two && $one == $two) : !defined $two;
}

sub _side {
	my ($self, $side) = @_;
	$side = $self->turn unless defined $side;
	die "side must be white or black, got '$side'" unless $OTHER{$side};
	return $side;
}

sub _key {
	my ($self) = @_;
	return join '', @{ $self->_position }[ 0 .. 23 ], $self->turn;
}

sub _counting {
	my $position = $_[0]->_position;
	return !$position->[Game::Merrills::Rules::HAND_WHITE]
		&& !$position->[Game::Merrills::Rules::HAND_BLACK];
}

sub _error {
	my ($self, $flag, %extra) = @_;
	return Game::Merrills::Error->throw(
		$flag,
		legal => $self->legal_moves,
		%extra
	);
}

sub _parse {
	my ($self, $move) = @_;
	if (ref $move eq 'Game::Merrills::Move') {
		$move = { from => $move->from, to => $move->to, remove => $move->remove };
	}
	return Game::Merrills::Notation::parse_move($move) unless ref $move;
	return undef unless ref $move eq 'HASH';

	my %want;
	for my $part (qw/from to remove/) {
		my $point = $move->{$part};
		next unless defined $point;
		return undef if ref $point;
		$point = Game::Merrills::Points::point($point) if $point =~ m/^[a-g][1-7]$/i;
		return undef unless defined $point && $point =~ m/^[0-9]+$/ && $point < 24;
		$want{$part} = $point + 0;
	}
	return undef unless defined $want{to};
	return \%want;
}

sub _diagnose {
	my ($self, $want) = @_;
	my ($from, $to, $remove) = @{$want}{qw/from to remove/};
	my $position = $self->_position;
	my $side = $self->turn;
	my $value = $Game::Merrills::Board::VALUE{$side};
	my $phase = $self->phase;

	if (defined $from) {
		return $self->_error('men_in_hand') if $phase eq 'placing';
		return $self->_error('not_your_man') unless $position->[$from] == $value;
		return $self->_error('occupied') if $position->[$to];
		return $self->_error('not_adjacent')
			if $phase eq 'moving' && !Game::Merrills::Points::is_adjacent($from, $to);
	}
	else {
		return $self->_error('no_men_in_hand') unless $phase eq 'placing';
		return $self->_error('occupied') if $position->[$to];
	}

	my $closes = Game::Merrills::Rules::closes($position, $side, $from, $to);
	unless (defined $remove) {
		return $self->_error('not_legal') unless $closes;
		return $self->_error('must_remove', legal => [
			grep { $_->to == $to && _same($_->from, $from) } @{ $self->legal_moves }
		]);
	}
	return $self->_error('nothing_to_remove') unless $closes;
	return $self->_error('no_man_there') unless $position->[$remove] == -$value;
	return $self->_error('man_in_mill')
		unless grep { $_ == $remove } Game::Merrills::Rules::removable($position, $side);
	return $self->_error('not_legal');
}

sub _play {
	my ($self, $move) = @_;
	my $raw = $move->to_raw;
	my $mover = $self->turn;
	my $position = $self->_position;

	my %record = (
		raw => $raw,
		no_mill => $self->no_mill,
		draw_offered_by => $self->draw_offered_by,
	);
	push @{ $self->history }, $move;

	Game::Merrills::Rules::apply($position, $mover, $raw);
	$self->_legal(undef);

	my $offered = $self->draw_offered_by;
	$self->draw_offered_by(undef) if $offered && $offered ne $mover;

	if ($move->is_placement || $move->is_capture) {
		$record{repetition} = $self->repetition;
		$self->repetition({});
		$self->no_mill(0);
	}
	else {
		$self->no_mill($self->no_mill + 1);
	}
	$self->turn($OTHER{$mover});

	my $count = 0;
	if ($self->_counting) {
		$count = ++$self->repetition->{ $self->_key };
		$record{counted} = 1;
	}
	push @{ $self->_undo }, \%record;

	$self->_check_end;
	return $move if $self->result;

	if ($count >= 3) {
		$self->_finish(undef, 'repetition');
	}
	elsif ($NO_MILL_LIMIT && $self->no_mill >= $NO_MILL_LIMIT) {
		$self->_finish(undef, 'no_mill');
	}
	return $move;
}

sub _check_end {
	my ($self) = @_;
	return if $self->result;
	my $turn = $self->turn;
	return $self->_finish($OTHER{$turn}, 'few') if $self->men($turn) < 3;
	return $self->_finish($turn, 'few') if $self->men($OTHER{$turn}) < 3;
	return if Game::Merrills::Rules::has_move($self->_position, $turn, $self->flying);
	return $self->_finish($OTHER{$turn}, 'blocked');
}

sub _finish {
	my ($self, $winner, $reason) = @_;
	$self->result(Game::Merrills::Result->new(
		winner => $winner,
		reason => $reason
	));
	$self->_legal([]);
	return $self->result;
}

1;

__END__

=head1 NAME

Game::Merrills - Nine Men's Morris as an engine

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills;

	my $game = Game::Merrills->new;

	$game->turn;                    # 'white'
	$game->phase;                   # 'placing'
	$game->legal_moves;             # the 24 opening moves
	$game->move('d2');              # a Game::Merrills::Move

	my $bad = $game->move('d2');
	$bad->message if ref $bad eq 'Game::Merrills::Error';

	$game->status;                  # 'active' until somebody wins
	$game->result->stringify;       # 'White wins: Black has no move'

=head1 DESCRIPTION

Nine Men's Morris, also called Merrills, Merels and Mill: two players, nine
men each, and a board of three squares joined at the middle of their sides.

A game object holds one game. It knows whose turn it is, what may be played,
and when the game has ended and how. It reads and writes nothing, keeps no
clock and never guesses, so the same moves always make the same game.

It is the engine behind the Nine Men's Morris at L<https://peer2peergames.com>.

=head2 The rules as played here

White moves first.

Each side in turn places a man on any empty point until all eighteen are
down. After that a turn moves one man along a line to the next point, if it
is empty.

Three men of one side in a row along a line make a mill. The move that
completes one takes an enemy man off the board, and that man is named as part
of the move. A man in a mill cannot be taken while any enemy man stands
outside one. A man that completes two mills at once takes one man, not two.

A side with exactly three men left and none in hand flies: its men move to
any empty point. This is the usual rule and can be turned off with L</flying>.

A side with fewer than three men has lost, and so has a side whose turn it is
and which has no move.

=head2 Draws

Printed rules for this game give no draw, and two careful players can shuffle
for ever, so this module adds three:

=over 4

=item *

The same men on the same points with the same side to move, for the third
time.

=item *

L</NO_MILL_PLIES> moves in a row, counting both sides, with no mill closed.

=item *

One side offers a draw and the other accepts.

=back

Both counts begin once every man is placed. A position cannot come round
again while men are still going down, or after a man has been taken, so each
placement and each capture starts both counts afresh.

=head2 Refusals

A move the rules do not allow is not an exception. L</move> returns a
L<Game::Merrills::Error> saying why, and the game is unchanged. What dies is a
mistake in the calling code: a side that is not one, a position that could
not be one, a written game that does not play.

=head2 The game to play

The C<merrills> script plays the game in a terminal, against a bot at one of
five strengths, between two people, or bot against bot. C<merrills --help>
lists what it takes. It is L<Game::Merrills::Terminal> and nothing more.

=head2 The modules

=over 4

=item L<Game::Merrills::Points>

The 24 points, the lines between them and the 16 mills.

=item L<Game::Merrills::Board>

The men on the points and the men still in hand.

=item L<Game::Merrills::Move>

One whole move: where from, where to, and the man it took.

=item L<Game::Merrills::Notation>

Moves, positions and whole games as text.

=item L<Game::Merrills::Rules>

Which moves are legal, and what a move does to a position.

=item L<Game::Merrills::Error>

A move the game refused, and why.

=item L<Game::Merrills::Result>

How a game ended.

=item L<Game::Merrills::Bot>

A player that chooses its own moves, at five strengths.

=item L<Game::Merrills::Terminal>

The game at a prompt, on a drawn board. The only module that reads or writes.

=back

=head1 PROPERTIES

Give C<position> and C<flying> to C<new>. The rest are the game's own record
and are there to be read.

=head2 position

The position the game began from, as L<Game::Merrills::Notation> writes one.
Defaults to the empty board with white to move. L</to_position> gives the
position as it stands now.

	my $game = Game::Merrills->new(position => 'WWW.BB..B..W....B..W.B.. w 4 4 0 10');

=head2 flying

Whether a side down to three men flies. Defaults to true.

	my $game = Game::Merrills->new(flying => 0);

=head2 turn

The side to move, C<white> or C<black>.

	$game->turn;

=head2 result

The L<Game::Merrills::Result> once the game has ended, and undef before.

	$game->result;

=head2 history

An arrayref of the L<Game::Merrills::Move> objects played, in order.

	$game->history;

=head2 no_mill

How many moves in a row have been played without a mill being closed.

	$game->no_mill;

=head2 repetition

A hashref counting how often each position has stood since the last
placement or capture.

	$game->repetition;

=head2 draw_offered_by

The side with a draw offer standing, or undef.

	$game->draw_offered_by;

=head1 METHODS

Where a method takes a side and is given none, it means the side to move.

=head2 status

C<active> while the game is going and C<finished> once it has a result.

	$game->status;

=head2 ply

How many moves have been played, counting each side's as one, and counting
from the ply of the position the game began from.

	$game->ply;

=head2 phase

What the side to move does on its turn: C<placing>, C<moving> or C<flying>.

	$game->phase;

=head2 phase_of

The same for a named side. One side can be flying while the other is not.

	$game->phase_of('black');

=head2 in_hand

The men a side has yet to place.

	$game->in_hand('white');

=head2 on_board

The men a side has on the board.

	$game->on_board('white');

=head2 men

The men a side has left, on the board and in hand together.

	$game->men('white');

=head2 board

The men as a L<Game::Merrills::Board>, a copy that can be changed without
touching the game.

	$game->board->in_mill($point);

=head2 legal_moves

An arrayref of every L<Game::Merrills::Move> the side to move may play, in a
fixed order. A move that closes a mill is there once for each man it could
take. Empty once the game is over.

	my $moves = $game->legal_moves;

=head2 legal_moves_for

The legal moves of the man on a point, as an arrayref. While men are being
placed, the legal moves that put a man on that point.

	my $moves = $game->legal_moves_for($point);

=head2 move

Plays a move for the side to move. Takes a L<Game::Merrills::Move>, a string
such as C<d2>, C<d2-d3> or C<d2-d3xa1>, or a hashref of C<from>, C<to> and
C<remove> whose values are point numbers or coordinates. Returns the move
played, or a L<Game::Merrills::Error> when it is refused.

A move that closes a mill must say which man it takes.

	$game->move('d2-d3xa1');
	$game->move({ from => 'd2', to => 'd3', remove => 'a1' });

=head2 undo

Takes back the last move and returns it, lifting any result the game had
reached. Returns a L<Game::Merrills::Error> when no move has been played.

	$game->undo;

=head2 resign

A side gives up and the other wins. Returns the result, or a
L<Game::Merrills::Error> when the game is already over.

	$game->resign('black');

=head2 timeout

A side has run out of time and the other wins. Returns the result, or a
L<Game::Merrills::Error> when the game is already over.

	$game->timeout('black');

=head2 offer_draw

A side offers a draw. The offer stands until the other side accepts it,
declines it or plays a move. Returns the side.

	$game->offer_draw('white');

=head2 accept_draw

A side accepts the draw the other offered, and the game ends. Returns the
result, or a L<Game::Merrills::Error> when there is no such offer.

	$game->accept_draw('black');

=head2 decline_draw

A side turns down the draw the other offered. Returns the side, or a
L<Game::Merrills::Error> when there is no such offer.

	$game->decline_draw('black');

=head2 to_position

The position as it stands, as one line of text.

	my $text = $game->to_position;

=head2 from_position

A new game beginning from a position. Further arguments go to C<new>. A game
begun this way has no earlier moves to take back and no earlier positions to
repeat.

	my $game = Game::Merrills->from_position($text, flying => 0);

=head2 to_text

The whole game as text: the moves in numbered pairs, after a line naming the
position it began from when that was not the empty board.

	my $text = $game->to_text;

=head2 from_text

A new game played through from its text. Further arguments go to C<new>. Dies,
naming the move, when one of them is refused.

	my $game = Game::Merrills->from_text($text);

=head2 clone

A second game in the same state that shares nothing with the first. Moves
played on one, or taken back, leave the other alone.

	my $copy = $game->clone;

=head1 CONSTANTS

=head2 NO_MILL_PLIES

100. The number of moves in a row, counting both sides, that may pass with no
mill closed before the game is drawn.

The number was measured. Over 2,000 games between two players that take a
mill when they can and block one when they must, with no limit at all, 99 in
100 of the games that ended by themselves never went more than 61 moves
without a mill, and none went more than 89. A limit of 100 would have cut
short none of them. The measurement ships as F<xt/draw-measure.t>, which
fails if this number is ever set below what it finds.

=head1 PACKAGE VARIABLES

=over 4

=item C<$NO_MILL_LIMIT>

The limit in force, L</NO_MILL_PLIES> unless changed. Set it to 0 and no game
is drawn for want of a mill, which is of use when measuring how long games
run and of none when playing them.

=back

=head1 CAVEATS

C<Carp> is loaded before L<Object::Proto::Sugar> on purpose. In a plain
script, under Devel::Hook before 0.011, the other order fails to compile.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-merrills at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Merrills>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Merrills

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Merrills>

=item * Search CPAN

L<https://metacpan.org/release/Game-Merrills>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
