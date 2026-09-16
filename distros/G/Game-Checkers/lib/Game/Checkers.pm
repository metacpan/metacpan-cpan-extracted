package Game::Checkers;

use strict;
use warnings;

our $VERSION = '0.01';

use Object::Proto::Sugar -types;
use Game::Checkers::Squares;
use Game::Checkers::Piece;
use Game::Checkers::Move;
use Game::Checkers::Notation;
use Game::Checkers::Board;
use Game::Checkers::Rules;
use Game::Checkers::Error;
use Game::Checkers::Result;

use constant NO_PROGRESS_PLIES => 80;

my $STEP = \@Game::Checkers::Squares::STEP;
my $JUMP_OVER = \@Game::Checkers::Squares::JUMP_OVER;
my $JUMP_TO = \@Game::Checkers::Squares::JUMP_TO;

my %FORWARD = (
	black => {
		Game::Checkers::Squares::SE, 1,
		Game::Checkers::Squares::SW, 1
	},
	white => {
		Game::Checkers::Squares::NE, 1,
		Game::Checkers::Squares::NW, 1
	},
);

has board => (
	is => 'rw',
	isa => Object
);

has [qw/turn variant fen/] => (
	is => 'rw',
	isa => Str
);

has [qw/result draw_offered_by _legal/] => (
	is => 'rw'
);

has [qw/history _undo/] => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has no_progress => (
	is => 'rw',
	isa => Int,
	default => 0
);

has repetition => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

sub BUILD {
	my ($self) = @_;
	$self->variant('english') unless defined $self->variant;
	die "variant must be english, got '" . $self->variant . "'"
		unless $self->variant eq 'english';

	if (!$self->board) {
		if (my $fen = $self->fen) {
			my ($board, $turn) = Game::Checkers::Board->from_fen($fen);
			$self->board($board);
			$self->turn($turn);
		} else {
			$self->board(Game::Checkers::Board->new);
		}
	}
	$self->turn('black') unless defined $self->turn;
	die "turn must be black or white, got '" . $self->turn . "'"
		unless $FORWARD{$self->turn};

	$self->fen($self->board->to_fen($self->turn)) unless defined $self->fen;
	$self->repetition->{$self->board->to_fen($self->turn)}++
		unless %{$self->repetition};
	$self->_check_end;
	return $self;
}

sub status {
	return $_[0]->result ? 'finished' : 'active';
}

sub ply {
	return scalar @{$_[0]->history};
}

sub to_fen {
	my ($self) = @_;
	return $self->board->to_fen($self->turn);
}

sub legal_moves {
	my ($self) = @_;
	my $legal = $self->_legal;
	return $legal if $legal;
	$legal = [];
	unless ($self->result) {
		my $turn = $self->turn;
		$legal = [
			map { Game::Checkers::Move->from_raw($_, $turn) }
			@{Game::Checkers::Rules::generate($self->board->position, $turn)}
		];
	}
	$self->_legal($legal);
	return $legal;
}

sub legal_moves_for {
	my ($self, $square) = @_;
	return [grep { $_->from == $square } @{$self->legal_moves}];
}

sub must_capture {
	my $legal = $_[0]->legal_moves;
	return @{$legal} && $legal->[0]->is_jump ? 1 : 0;
}

sub move {
	my ($self, $move) = @_;
	return $self->_error('game_over') if $self->result;

	my $parsed = $self->_parse($move)
		or return $self->_error('not_a_move');

	my ($from, $to) = @{$parsed}{qw/from to/};
	my $value = $self->board->at($from);
	return $self->_error('not_your_piece')
		unless $value && ($value > 0 ? 'black' : 'white') eq $self->turn;

	my @match = grep { $_->from == $from && $_->to == $to } @{$self->legal_moves};
	if (@{$parsed->{squares}} > 2) {
		my $path = join '.', @{$parsed->{squares}};
		@match = grep { join('.', @{$_->path}) eq $path } @match;
	}
	return $self->_error('ambiguous', legal => \@match) if @match > 1;
	return $self->_diagnose($parsed) unless @match;
	return $self->_play($match[0]);
}

sub undo {
	my ($self) = @_;
	my $record = pop @{$self->_undo}
		or return $self->_error('nothing_to_undo');
	my $move = pop @{$self->history};

	my $fen = $self->to_fen;
	delete $self->repetition->{$fen}
		unless --$self->repetition->{$fen};

	Game::Checkers::Rules::unapply($self->board->position, $record->{raw});
	$self->turn($self->turn eq 'black' ? 'white' : 'black');
	$self->no_progress($record->{no_progress});
	$self->draw_offered_by($record->{draw_offered_by});
	$self->result(undef);
	$self->_legal(undef);
	return $move;
}

sub resign {
	my ($self, $side) = @_;
	$side = $self->_side($side);
	return $self->_error('game_over') if $self->result;
	return $self->_finish($side eq 'black' ? 'white' : 'black', 'resign');
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
	my $offered = $self->draw_offered_by;
	return $self->_error('no_offer') unless $offered && $offered ne $side;
	$self->draw_offered_by(undef);
	return $side;
}

sub to_pdn {
	my ($self, %tags) = @_;
	my $opening = Game::Checkers::Board->new->to_fen('black');
	if ($self->fen ne $opening) {
		$tags{FEN} = $self->fen;
		$tags{SetUp} = '1';
	}
	return Game::Checkers::Notation::format_pdn({
		tags => \%tags,
		moves => [map { $_->notation } @{$self->history}],
		result => $self->result ? $self->result->pdn : '*'
	});
}

sub from_pdn {
	my ($class, $text) = @_;
	my $parsed = Game::Checkers::Notation::parse_pdn($text);
	my $self = $class->new(
		$parsed->{tags}{FEN} ? (fen => $parsed->{tags}{FEN}) : ()
	);
	my $number = 0;
	for my $notation (@{$parsed->{moves}}) {
		$number++;
		my $move = $self->move($notation);
		next unless ref $move eq 'Game::Checkers::Error';
		die "illegal PDN: move $number, '$notation': " . $move->message . "\n";
	}
	return $self;
}

sub clone {
	my ($self) = @_;
	my $clone = ref($self)->new(
		variant => $self->variant,
		fen => $self->fen,
		board => $self->board->clone,
		turn => $self->turn
	);
	$clone->history([@{$self->history}]);
	$clone->_undo([@{$self->_undo}]);
	$clone->no_progress($self->no_progress);
	$clone->repetition({%{$self->repetition}});
	$clone->draw_offered_by($self->draw_offered_by);
	$clone->result($self->result);
	$clone->_legal(undef);
	return $clone;
}

sub _side {
	my ($self, $side) = @_;
	$side = $self->turn unless defined $side;
	die "side must be black or white, got '$side'" unless $FORWARD{$side};
	return $side;
}

sub _error {
	my ($self, $flag, %extra) = @_;
	return Game::Checkers::Error->throw(
		$flag,
		legal => $self->legal_moves,
		%extra
	);
}

sub _parse {
	my ($self, $move) = @_;
	if (ref $move eq 'Game::Checkers::Move') {
		return {
			from => $move->from,
			to => $move->to,
			squares => [@{$move->path}],
			jump => $move->is_jump
		};
	}
	if (ref $move eq 'HASH') {
		my @squares = $move->{squares} ? @{$move->{squares}}
			: $move->{path} ? @{$move->{path}}
			: grep { defined } $move->{from}, $move->{to};
		return undef unless @squares > 1;
		for my $square (@squares) {
			return undef unless $square =~ m/^[0-9]+$/ && $square >= 1 && $square <= 32;
		}
		return {
			from => $squares[0],
			to => $squares[-1],
			squares => \@squares,
			jump => @squares > 2 ? 1 : $move->{jump}
		};
	}
	return undef if ref $move;
	return Game::Checkers::Notation::parse_move($move);
}

sub _diagnose {
	my ($self, $parsed) = @_;
	my ($from, $to) = @{$parsed}{qw/from to/};
	my $position = $self->board->position;
	my $value = $position->[$from];
	my $king = abs($value) == 2 ? 1 : 0;
	my $base = $from * 4;

	for my $dir (@Game::Checkers::Squares::DIRS) {
		my $forward = $king || $FORWARD{$self->turn}{$dir};
		if ($STEP->[$base + $dir] && $STEP->[$base + $dir] == $to) {
			return $self->_error('occupied') if $position->[$to];
			return $self->_error('wrong_direction') unless $forward;
			return $self->_error('must_capture') if $self->must_capture;
			return $self->_error('not_legal');
		}
		if ($JUMP_TO->[$base + $dir] && $JUMP_TO->[$base + $dir] == $to) {
			return $self->_error('occupied') if $position->[$to];
			return $self->_error('wrong_direction') unless $forward;
			return $self->_error('not_legal');
		}
	}
	return $self->_error('must_capture') if $self->must_capture;
	return $self->_error('not_legal');
}

sub _play {
	my ($self, $move) = @_;
	my $raw = $move->to_raw;
	my $mover = $self->turn;

	push @{$self->_undo}, {
		raw => $raw,
		no_progress => $self->no_progress,
		draw_offered_by => $self->draw_offered_by
	};
	push @{$self->history}, $move;

	Game::Checkers::Rules::apply($self->board->position, $raw);
	$self->_legal(undef);

	# an offer stands until the other side answers it with a move
	my $offered = $self->draw_offered_by;
	$self->draw_offered_by(undef) if $offered && $offered ne $mover;

	$self->no_progress(
		Game::Checkers::Rules::progress($raw) ? 0 : $self->no_progress + 1
	);
	$self->turn($mover eq 'black' ? 'white' : 'black');

	my $count = ++$self->repetition->{$self->to_fen};

	# a player with no move has lost, which beats either drawing counter
	$self->_check_end;
	return $move if $self->result;

	if ($count >= 3) {
		$self->_finish(undef, 'repetition');
	} elsif ($self->no_progress >= NO_PROGRESS_PLIES) {
		$self->_finish(undef, 'no_progress');
	}
	return $move;
}

sub _check_end {
	my ($self) = @_;
	return if $self->result;
	return if Game::Checkers::Rules::has_move($self->board->position, $self->turn);
	return $self->_finish($self->turn eq 'black' ? 'white' : 'black', 'no_moves');
}

sub _finish {
	my ($self, $winner, $reason) = @_;
	$self->result(Game::Checkers::Result->new(
		winner => $winner,
		reason => $reason
	));
	$self->_legal([]);
	return $self->result;
}

1;

__END__

=head1 NAME

Game::Checkers - English draughts as an engine, with a terminal game on top

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers;

	my $game = Game::Checkers->new;

	$game->turn;                    # 'black'
	$game->legal_moves;             # the seven opening moves
	$game->move('11-15');           # a Game::Checkers::Move

	my $bad = $game->move('11-15');
	$bad->message if ref $bad eq 'Game::Checkers::Error';

	$game->status;                  # 'active' until somebody wins
	$game->result->stringify;       # 'Black wins: White has no move'

=head1 DESCRIPTION

English draughts, also called American checkers: an eight by eight board, twelve
pieces a side, men moving and capturing forward only, kings one square in any
direction, capture compulsory, and the crown ending the turn.
L<Game::Checkers::Rules/The rules implemented> states them exactly.

It is the engine behind the checkers at L<https://peer2peergames.com>.

The engine does no input and no output. It never prints, never reads a handle,
never sleeps and never calls C<rand>, so a game is a pure function of its moves
and replays anywhere. The terminal game lives in L<Game::Checkers::Terminal> and
the C<checkers> script, and nothing in the engine loads either.

A player's mistake is returned as a L<Game::Checkers::Error>, never thrown. Only a
programmer error dies: a square outside 1 to 32, a colour that is not black or
white, a variant that is not English.

=head2 The modules

=over

=item L<Game::Checkers::Board>

The 32 playing squares and what stands on them.

=item L<Game::Checkers::Squares>

The numbering, and the step and jump tables built from it.

=item L<Game::Checkers::Piece>

One man or king.

=item L<Game::Checkers::Move>

One move, with its whole jump path and everything it captured.

=item L<Game::Checkers::Rules>

Move generation over a raw position, and the interface the search uses.

=item L<Game::Checkers::Notation>

Moves, positions and games as text: numeric notation, FEN and PDN.

=item L<Game::Checkers::Error>, L<Game::Checkers::Result>

Why a move was refused, and how a game ended.

=item L<Game::Checkers::Bot>

An opponent at five strengths, bounded by a node budget and never by a clock.

=item L<Game::Checkers::Terminal>

The game at a prompt, and the only module here that reads or writes a handle.
The C<checkers> script is a few lines of option parsing on top of it.

=back

=head2 Draws

Three of them, and the first two are counted by the game object as it goes:

=over

=item *

B<Threefold repetition.> Every position the game has been in is counted by its
FEN, which includes the side to move. The third occurrence ends the game.

=item *

B<No progress.> Forty moves by each side, counted here as eighty plies, with no
capture and no man moved. Any capture or man move resets it.

=item *

B<Agreement.> L</offer_draw> then L</accept_draw> by the other side. An offer
stands until the other side answers it with a move.

=back

When a move both blocks the opponent and completes a draw counter, the block
wins: a player with no move has lost.

=head1 PROPERTIES

=head2 board

Read and write L<Game::Checkers::Board>. Pass one to start from a position
without a FEN.

	$game->board;

=head2 turn

Read and write string, C<black> or C<white>. Black moves first.

	$game->turn;

=head2 variant

Read and write string. C<english> is the only value, and anything else dies at
construction. It is here so a later variant is an addition rather than a rewrite.

	$game->variant;

=head2 fen

Read and write string: the position the game STARTED from, filled in at
construction. Pass it to start from a position. The current position is
L</to_fen>.

	Game::Checkers->new(fen => 'W:WK5:BK28');

=head2 result

Read and write L<Game::Checkers::Result>, undef while the game is active.

	$game->result;

=head2 history

Read and write arrayref of the L<Game::Checkers::Move> objects played, in order.

	$game->history;

=head2 no_progress

Read and write integer: plies since the last capture or man move.

	$game->no_progress;

=head2 repetition

Read and write hashref counting how often each position has occurred, keyed by
FEN.

	$game->repetition;

=head2 draw_offered_by

Read and write C<black>, C<white> or undef.

	$game->draw_offered_by;

=head1 FUNCTIONS

=head2 status

C<active> or C<finished>.

	$game->status;

=head2 ply

How many moves have been played.

	$game->ply;

=head2 to_fen

The FEN of the current position, including the side to move.

	$game->to_fen;

=head2 legal_moves

An arrayref of the L<Game::Checkers::Move> objects the side to move may play,
empty once the game is finished. The order is stable, so a client may show them
numbered.

	$game->legal_moves;

=head2 legal_moves_for

The legal moves starting on one square.

	$game->legal_moves_for(11);

=head2 must_capture

True when a jump is available, which makes the legal list jumps only.

	$game->must_capture;

=head2 move

Plays one move and returns it, or returns a L<Game::Checkers::Error> saying why
not. Accepts a L<Game::Checkers::Move>, a notation string such as C<11-15> or
C<23x14x7>, the same move written as the squares on the board, C<f6-e5> and
C<e3xc5xe7>, or a hashref of C<from> and C<to> (or C<squares>).

The short form of a jump is resolved against the legal list: C<23x7> is one
sequence in most positions, and where it is two the error is C<ambiguous> rather
than a guess. A multi jump stopped part way is C<not_legal>, never completed on
the player's behalf, because a position with two continuations would then be
chosen for them.

	my $played = $game->move('11-15');

=head2 undo

Takes back the last move and returns it, restoring the position exactly,
including a crown the move gave and a king it captured. It also lifts a finish,
so a resigned game can be taken back. Returns an error when nothing has been
played.

	$game->undo;

=head2 resign

Ends the game, the other side winning. Defaults to the side to move.

	$game->resign('white');

=head2 offer_draw

Offers a draw on behalf of a side and returns it. The offer stands until the
other side answers it with a move.

	$game->offer_draw('black');

=head2 accept_draw

Accepts an offer made by the other side, ending the game as a draw by agreement.

	$game->accept_draw('white');

=head2 decline_draw

Clears an offer made by the other side.

	$game->decline_draw('white');

=head2 to_pdn

The game as PDN. Any arguments are tags, and a game that did not start from the
opening position carries its C<FEN> and C<SetUp> tags automatically.

	print $game->to_pdn(Event => 'Kitchen table', Black => 'Me');

=head2 from_pdn

Class method replaying a PDN game and returning it. Dies naming the move number
when one of them is illegal, because a game record that does not replay is not a
game record.

	my $game = Game::Checkers->from_pdn($text);

=head2 clone

A copy of the whole game, position, history and counters, sharing nothing that
matters.

	my $copy = $game->clone;

=head1 CONSTANTS

C<NO_PROGRESS_PLIES> is 80, the forty move rule counted in plies.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
