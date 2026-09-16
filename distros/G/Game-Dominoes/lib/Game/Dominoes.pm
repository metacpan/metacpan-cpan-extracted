package Game::Dominoes;

use 5.010;
use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Dominoes::Tile;
use Game::Dominoes::Set;
use Game::Dominoes::Hand;
use Game::Dominoes::Boneyard;
use Game::Dominoes::Play;
use Game::Dominoes::Layout;
use Game::Dominoes::Rules;
use Game::Dominoes::Scoring;
use Game::Dominoes::Notation;
use Game::Dominoes::Error;
use Game::Dominoes::Result;

our $VERSION = '0.01';

our %HAND_SIZE = (2 => 9, 3 => 7, 4 => 5);

our %TARGET = (2 => 250, 3 => 200, 4 => 200);

our @VARIANTS = qw/all_fives draw block/;

has seed => (is => 'ro', isa => Str);
has players => (is => 'ro', isa => Int, default => 2);
has variant => (is => 'ro', isa => Str, default => 'all_fives');
has target => (is => 'rw', isa => Int);
has scale => (is => 'ro', isa => Int, default => 1);
has reserve => (is => 'ro', isa => Int, default => 0);

has status => (is => 'rw', isa => Str, default => 'active');
has hand_number => (is => 'rw', isa => Int, default => 0);
has turn => (is => 'rw', isa => Int);
has hands => (is => 'rw', isa => HashRef, default => {});
has scores => (is => 'rw', isa => HashRef, default => {});
has boneyard => (is => 'rw', isa => Object);
has layout => (is => 'rw', isa => Object);
has result => (is => 'rw', isa => Object);
has history => (is => 'rw', isa => ArrayRef, default => []);

has leader => (is => 'rw', isa => Int);
has forced_tile => (is => 'rw', isa => Object);

has passes => (is => 'rw', isa => Int, default => 0);

has deductions => (is => 'rw', isa => HashRef, default => {});

sub BUILD {
	my ($self) = @_;

	die 'Game::Dominoes: seed must be 32 bytes'
		unless defined $self->seed && length $self->seed == 32;
	die 'Game::Dominoes: players must be 2, 3 or 4'
		unless $HAND_SIZE{ $self->players };
	die 'Game::Dominoes: unknown variant ' . $self->variant
		unless grep { $_ eq $self->variant } @VARIANTS;
	die 'Game::Dominoes: scale must be a positive integer'
		unless $self->scale >= 1;

	$self->target($TARGET{ $self->players } / $self->scale)
		unless defined $self->target;
	die 'Game::Dominoes: target must be a positive integer'
		unless $self->target > 0;

	$self->scores({ map { $_ => 0 } $self->seats })
		unless keys %{ $self->scores };
	$self->leader($self->_by_lot(1)) unless defined $self->leader;

	if (keys %{ $self->hands }) {
		$self->layout(Game::Dominoes::Layout->new) unless $self->layout;
		$self->boneyard(Game::Dominoes::Boneyard->new(reserve => $self->reserve))
			unless $self->boneyard;
		$self->hand_number(1) unless $self->hand_number;
		$self->turn($self->leader) unless defined $self->turn;
	}
	else {
		$self->_deal;
	}
	return $self;
}

sub seats { return 1 .. $_[0]->players }

sub hand_size { return $HAND_SIZE{ $_[0]->players } }

sub _by_lot {
	my ($self, $n) = @_;
	my $word = unpack 'N', Digest::SHA::sha256($self->seed . "lot:$n");
	my $limit = int(4294967296 / $self->players) * $self->players;
	my $i = 0;
	while ($word >= $limit) {
		$word = unpack 'N', Digest::SHA::sha256($self->seed . "lot:$n:" . ++$i);
	}
	return ($word % $self->players) + 1;
}

sub _note {
	my ($self, $kind, %rest) = @_;
	push @{ $self->history }, { kind => $kind, hand => $self->hand_number, %rest };
	return;
}

sub _deal {
	my ($self) = @_;

	$self->hand_number($self->hand_number + 1);
	my $order = Game::Dominoes::Set::order_for($self->seed, $self->hand_number);
	my $size = $self->hand_size;

	my %hands;
	my $at = 0;
	for my $seat ($self->seats) {
		my @ids = @{$order}[ $at .. $at + $size - 1 ];
		$at += $size;
		$hands{$seat} = Game::Dominoes::Hand->new(
			tiles => [ map { Game::Dominoes::Set::tile_of($_) } @ids ]
		);
	}

	$self->hands(\%hands);
	$self->boneyard(Game::Dominoes::Boneyard->new(
		reserve => $self->reserve,
		tiles => [ map { Game::Dominoes::Set::tile_of($_) } @{$order}[ $at .. $#$order ] ],
	));
	$self->layout(Game::Dominoes::Layout->new);
	$self->turn($self->leader);
	$self->passes(0);
	$self->forced_tile(undef);
	$self->deductions({});

	$self->_note('deal', seat => $self->leader);
	return;
}

sub hand { return $_[0]->hands->{ $_[1] } }

sub hand_count {
	my ($self, $seat) = @_;
	my $hand = $self->hands->{$seat} or return 0;
	return $hand->count;
}

sub boneyard_count { return $_[0]->boneyard->count }

sub open_ends { return $_[0]->layout->open_ends }

sub count { return Game::Dominoes::Scoring::count($_[0]->layout) }

sub legal {
	my ($self, $seat) = @_;
	return [] unless $self->status eq 'active';
	return [] unless defined $seat && defined $self->turn && $seat == $self->turn;

	my $hand = $self->hands->{$seat} or return [];
	my $moves = Game::Dominoes::Rules::candidates($self->layout, $hand);

	if (my $forced = $self->forced_tile) {
		$moves = [ grep { $_->{tile}->id == $forced->id } @$moves ];
	}

	return [ map { {
		kind => 'play',
		tile => $_->{tile},
		arm => $_->{arm},
		points => Game::Dominoes::Rules::score_of(
			$self->layout, $_->{tile}, $_->{arm}, $self->scale
		),
	} } @$moves ];
}

sub view {
	my ($self, $seat) = @_;
	$seat = 'spectator' unless defined $seat;
	my $own = ($seat ne 'spectator' && $self->hands->{$seat}) ? $self->hands->{$seat} : undef;

	return {
		seat        => $seat,
		players     => $self->players,
		variant     => $self->variant,
		target      => $self->target,
		scale       => $self->scale,
		status      => $self->status,
		turn        => $self->turn,
		hand_number => $self->hand_number,
		scores      => { %{ $self->scores } },
		layout      => $self->layout,
		ends        => [ $self->open_ends ],
		count       => $self->count,
		counts      => { map { $_ => $self->hand_count($_) } $self->seats },
		boneyard    => $self->boneyard_count,
		deductions  => { map { $_ => { %{ $self->deductions->{$_} || {} } } } $self->seats },
		forced      => $self->forced_tile,
		hand        => $own ? [ @{ $own->tiles } ] : undef,
		count_own   => $own ? $own->count : 0,
	};
}

sub _error { return Game::Dominoes::Error->throw($_[1], @_[2 .. $#_]) }

sub _move_of {
	my ($self, $move) = @_;
	return undef unless defined $move;

	if (!ref $move) {
		my $parsed = eval { Game::Dominoes::Notation::parse_move($move) };
		return undef unless $parsed && ($parsed->{kind} // '') eq 'play';
		return { tile => $parsed->{tile}, arm => $parsed->{arm} };
	}
	if (ref $move eq 'HASH') {
		my $tile = $move->{tile};
		return undef unless defined $tile;
		$tile = eval { Game::Dominoes::Notation::parse_tile($tile) } unless ref $tile;
		return undef unless ref $tile;
		return { tile => $tile, arm => $move->{arm} };
	}
	return { tile => $move->tile, arm => $move->arm };
}

sub play {
	my ($self, $seat, $move) = @_;

	return $self->_error('game_over') unless $self->status eq 'active';
	return $self->_error('not_your_turn')
		unless defined $seat && defined $self->turn && $seat == $self->turn;

	my $want = $self->_move_of($move);
	return $self->_error('bad_move') unless $want && ref $want->{tile};

	my $hand = $self->hands->{$seat};
	return $self->_error('tile_not_held') unless $hand->holds($want->{tile});

	if (my $forced = $self->forced_tile) {
		return $self->_error('tile_not_held')
			unless $want->{tile}->id == $forced->id;
	}

	my $layout = $self->layout;
	my $arm = $want->{arm};
	$arm = ($layout->arms_open)[0] unless defined $arm;
	return $self->_error('no_such_arm')
		unless grep { $_ eq $arm } @Game::Dominoes::Layout::ARMS;
	return $self->_error('arm_closed')
		unless grep { $_ eq $arm } $layout->arms_open;
	return $self->_error('end_mismatch')
		unless $layout->can_place($want->{tile}, $arm);

	$hand->remove($want->{tile});
	my $play = $layout->place($want->{tile}, $arm);
	$self->forced_tile(undef);
	$self->passes(0);

	my $points = Game::Dominoes::Scoring::score_for($self->count, $self->scale);
	$play->points($points);
	$self->_award($seat, $points) if $points;
	$self->_note('play', seat => $seat, play => $play, points => $points);

	return $play if $self->_check_target;

	if ($hand->is_empty) {
		$self->_end_hand('out', $seat);
		return $play;
	}

	$self->_advance;
	return $play;
}

sub _award {
	my ($self, $seat, $points) = @_;
	$self->scores->{$seat} += $points;
	return;
}

sub _check_target {
	my ($self) = @_;
	my ($high) = sort { $b <=> $a } values %{ $self->scores };
	return 0 unless $high >= $self->target;
	$self->_finish('target');
	return 1;
}

sub _advance {
	my ($self) = @_;

	for (1 .. $self->players * 2) {
		$self->turn($self->turn % $self->players + 1);
		$self->forced_tile(undef);

		my $hand = $self->hands->{ $self->turn };
		return if Game::Dominoes::Rules::can_play($self->layout, $hand);

		my $drawn = 0;
		while ($self->boneyard->can_draw) {
			my $tile = $self->boneyard->draw;
			$hand->add($tile);
			$drawn++;
			next unless Game::Dominoes::Rules::can_play($self->layout, $hand);
			$self->forced_tile($tile);
			last;
		}
		$self->_note('draw', seat => $self->turn, count => $drawn) if $drawn;
		return if $self->forced_tile;

		my @shut = $self->layout->open_ends;
		$self->deductions->{ $self->turn }{$_} = 1 for @shut;

		$self->_note('pass', seat => $self->turn, cannot => [ sort { $a <=> $b } @shut ]);
		$self->passes($self->passes + 1);
		if ($self->passes >= $self->players) {
			$self->_end_hand('blocked');
			return;
		}
	}
	return;
}

sub _end_hand {
	my ($self, $reason, $out) = @_;

	my %pips = map { $_ => $self->hands->{$_}->pips } $self->seats;

	if ($reason eq 'out') {
		my $total = 0;
		$total += $pips{$_} for grep { $_ != $out } $self->seats;
		my $points = Game::Dominoes::Scoring::bonus($total, $self->scale);
		$self->_award($out, $points);
		$self->_note('hand_end', reason => 'out', seat => $out,
			points => $points, pips => \%pips);
		$self->leader($out);
	}
	else {
		my ($low) = sort { $a <=> $b } values %pips;
		my @light = sort { $a <=> $b } grep { $pips{$_} == $low } $self->seats;

		if (@light == 1) {
			my $total = 0;
			$total += $pips{$_} for grep { $_ != $light[0] } $self->seats;
			my $points = Game::Dominoes::Scoring::bonus($total, $self->scale);
			$self->_award($light[0], $points);
			$self->_note('hand_end', reason => 'blocked', seat => $light[0],
				points => $points, pips => \%pips);
		}
		elsif (@light == 2 && $self->players == 3) {
			my ($third) = grep { $pips{$_} != $low } $self->seats;
			my $points = Game::Dominoes::Scoring::bonus($pips{$third}, $self->scale);
			my $each = int($points / 2);
			$self->_award($light[0], $points - $each);
			$self->_award($light[1], $each);
			$self->_note('hand_end', reason => 'blocked_split',
				seats => \@light, points => $points, pips => \%pips);
		}
		else {
			$self->_note('hand_end', reason => 'blocked_tied',
				seats => \@light, points => 0, pips => \%pips);
		}
		$self->leader($self->_by_lot($self->hand_number + 1));
	}

	return if $self->_check_target;
	$self->_deal;
	return;
}

sub _finish {
	my ($self, $reason) = @_;
	$self->status('finished');
	$self->turn(undef);
	$self->result(Game::Dominoes::Result->new(
		places => $self->places,
		scores => { %{ $self->scores } },
		reason => $reason,
	));
	$self->_note('game_end', reason => $reason);
	return;
}

sub places {
	my ($self) = @_;
	my $scores = $self->scores;
	my @order = sort { $scores->{$b} <=> $scores->{$a} } $self->seats;

	my (%place, $last, $rank);
	my $seen = 0;
	for my $seat (@order) {
		$seen++;
		if (!defined $last || $scores->{$seat} != $last) {
			$rank = $seen;
			$last = $scores->{$seat};
		}
		$place{$seat} = $rank;
	}
	return \%place;
}

sub resign {
	my ($self, $seat) = @_;
	return $self->_error('game_over') unless $self->status eq 'active';
	return $self->_error('not_your_turn')
		unless defined $seat && $self->hands->{$seat};

	my $scores = $self->scores;
	my ($high) = sort { $b <=> $a } map { $scores->{$_} } grep { $_ != $seat } $self->seats;
	$scores->{$seat} = -1 if $scores->{$seat} >= $high;
	$self->_finish('resign');
	return $self->result;
}

sub to_text {
	my ($self) = @_;
	my @moves;
	for my $event (@{ $self->history }) {
		push @moves, $event->{play} if $event->{kind} eq 'play';
		push @moves, { kind => 'draw', count => $event->{count} }
			if $event->{kind} eq 'draw';
		push @moves, { kind => 'pass' } if $event->{kind} eq 'pass';
		push @moves, { kind => 'hand_end' } if $event->{kind} eq 'hand_end';
	}
	return Game::Dominoes::Notation::to_text(\@moves);
}

1;

__END__

=head1 NAME

Game::Dominoes - draw dominoes with All Fives scoring, as a reusable engine

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes;

	my $game = Game::Dominoes->new(seed => $bytes, players => 2);

	$game->turn;              # the seat to play
	$game->legal($game->turn);  # what it may do, never just a draw
	$game->play(1, '6-4@L');

	$game->scores;            # { 1 => 10, 2 => 0 }
	$game->hand_count(2);     # public; hand(2) is not
	$game->status;            # 'active' until somebody reaches the target
	$game->result->stringify;

=head1 DESCRIPTION

Draw dominoes with All Fives (Muggins) scoring on a double six set, for two to
four players.

The engine does no input and no output. It never prints, never reads a handle,
never sleeps and never calls C<rand>, so a game is a pure function of its seed
and its moves and replays anywhere.

It is the engine behind the dominoes at L<https://peer2peergames.com>.

A player's mistake is B<returned> as a L<Game::Dominoes::Error>, never thrown.
C<die> is reserved for programmer error: a seat that does not exist, a face
outside 0 to 6, a variant nobody defined.

=head2 The rules, and the one source they come from

Pinned to Pagat's All Fives page, verified against it rather than against a
summary of it. Dominoes has no single rule book and the sources contradict each
other on nearly everything, so taking the most popular answer to each question
separately would produce a ruleset B<no publication describes>, and therefore
one with no citable test vectors at all.

=over

=item Hand size

Nine, seven and five tiles at two, three and four players. The rest is the
boneyard.

=item The lead

The first player of the first hand is determined by lot, which here means from
the seed, so it is reproducible and checkable afterwards. B<The lead may be any
tile>; this engine does not require the highest double, which is what most
other sources say and is the branch not taken.

In later hands the seat that went out leads. After a blocked hand the lead is
determined by lot again, because nobody went out.

=item Drawing

A seat that cannot play B<must> draw until it can or the boneyard is empty, and
a seat holding a playable tile may not draw at all. A drawn playable tile goes
straight on the table and the turn ends, so a drawn tile is not a choice and
only its arm may be.

The boneyard is drawn to empty. A reserve of one or two tiles that may never be
drawn is a listed variation, not the rule, and is available as C<reserve>.

=item The end of a hand

A seat goes out, or every seat is blocked in succession.

=item A blocked hand

The lightest hand wins and scores as if it had gone out. On a tie for lightest
at two or four seats B<nobody> scores. At three seats the two tied seats split
the third seat's pips between them, which is the oddest rule on the page and is
implemented as written.

=item The target

250 at two seats and 200 at three or four, and the game stops the moment it is
reached: tiles still in hand are not played or counted.

=back

=head2 The Muggins claim rule is left out on purpose

In the parlour game a player must announce a score and an opponent may call
"Muggins!" to steal it. It is a rule about human inattention with no engine
meaning, it has no agreed resolution when three opponents race to call it, and
Pagat's All Fives page does not mention it at all. This engine scores
automatically.

=head2 A forced turn is not a decision

C<legal> B<never> returns a list whose only member is a draw. A seat that
cannot play draws until it can or the boneyard runs out, and the engine does
that itself before handing the turn on, recording each draw and each pass in
the history.

This matters most away from a table. On a correspondence site a turn limit is a
day or three, and spending one on a move with exactly one outcome is how a
thirty play hand becomes a three month game.

=head2 The log is the serialisation, not the position

A snapshot of the table carries neither the hands nor the boneyard order, and
both decide the result. A game is its seed and its moves.

=head1 PROPERTIES

=head2 seed

	$game->seed;

Thirty-two bytes. Everything random in the game comes from here, so a finished
game can be checked move by move once the seed is revealed. While a game is
running the seed must not be shown to a player.

=head2 players, variant, target, scale, reserve

	Game::Dominoes->new(seed => $s, players => 3, target => 61, scale => 5);

C<players> is 2, 3 or 4. C<variant> is C<all_fives>, C<draw> or C<block>.

C<target> defaults to 250 at two seats and 200 at three or four. C<scale>
divides every score, for the cited variation that keeps score on a cribbage
board to a target of 61. B<The scale and the target are a matched pair>: 61
with the raw scale, or 250 with a divided one, is the likeliest silent bug
here, so set both or neither.

C<reserve> is how many tiles at the back of the boneyard may never be drawn,
nought by default.

=head2 status, turn, hand_number, scores, layout, boneyard, history, result

	$game->status;        # 'active' | 'finished'
	$game->turn;          # the seat to play, undef when finished
	$game->hand_number;   # which deal, and the hand argument of order_for
	$game->scores;        # { seat => points }

=head2 hands

	$game->hands;   # { seat => Game::Dominoes::Hand }

Every seat's tiles, keyed by seat. B<This is the secret the whole game turns
on.> Read one seat's own hand through C<hand>, ask how many tiles another seat
holds through C<hand_count>, and never put this in a view.

=head2 leader

	$game->leader;

The seat that leads the current hand: whoever went out of the last one, or a
seat chosen by lot from the seed when the last hand was blocked and nobody did.

=head2 forced_tile

	$game->forced_tile;

The tile a forced draw has committed the seat on turn to playing, or undef when
that seat is free to choose.

A seat that cannot play draws until it can, and the tile it stops on must be
the tile it plays: "When a player draws a playable tile, it goes on the table
immediately and the player's turn ends." Only the arm is still a choice, so
C<legal> narrows to that one tile while this is set.

=head2 passes

	$game->passes;

How many seats have passed in a row. Reaching the seat count means every seat
is blocked and the hand is over. Any play resets it.

=head2 deductions

	$game->deductions;   # { seat => { face => 1 } }

What each seat has shown it cannot hold.

A seat that passes holds no tile matching any end that was open at the time,
and because a pass only happens once the boneyard is exhausted, no tile ever
enters that hand again: it only shrinks. So the deduction holds for the rest of
the hand rather than just for the moment it was made.

This is derived from the public event log and from nothing else. Anybody
watching the game could build the same table, which is what makes it fair to
put in a view and fair for L<Game::Dominoes::Bot> to use. A new deal clears it.

B<A draw is deliberately not recorded as a deduction.> A seat that drew was
short of the ends open at that moment, but the tiles it held then are now mixed
in with what it drew and nothing public says which are which, so treating the
whole hand as constrained would be unsound.

=head2 view

	my $view = $game->view($seat);
	my $view = $game->view('spectator');

What one seat may see, as a plain hashref: its own tiles, the layout, the open
ends, B<how many> tiles every seat holds, the boneyard count, the scores, the
deductions, and whose turn it is.

It never carries another seat's tiles, the boneyard's contents, or the seed
while the game is running. C<spectator> is a valid seat and sees everything
except any hand.

It is built B<up from nothing> rather than down from the whole game by deleting
keys, because a view built by deletion leaks the next field somebody adds to
the engine, and in this game what is hidden is the whole point.

L<Game::Dominoes::Bot> is handed this and reads nothing else, which
C<t/19-bot-blind.t> proves rather than assumes.

=head1 FUNCTIONS

=head2 seats, hand_size

	$game->seats;       # 1 .. players
	$game->hand_size;   # 9, 7 or 5

=head2 hand

	$game->hand($seat);

That seat's L<Game::Dominoes::Hand>. B<Private to the seat.>

=head2 hand_count

	$game->hand_count($seat);

How many tiles a seat holds. B<Public>, and a separate method from C<hand> so
that the difference is visible at the call site.

=head2 boneyard_count

	$game->boneyard_count;

How many tiles are left undealt. Public: a player at the table can see them.

=head2 open_ends, count

	$game->open_ends;   # the faces a tile may be matched against
	$game->count;       # the open end total, for scoring

=head2 legal

	my $moves = $game->legal($seat);

What that seat may do now, as an arrayref of
C<< { kind => 'play', tile, arm, points } >>, where C<points> is what the play
would score.

Empty unless it is that seat's turn and the game is running. Never a lone draw.

=head2 play

	my $out = $game->play($seat, '6-4@L');
	my $out = $game->play($seat, { tile => $tile, arm => 'L' });

Plays one tile. Accepts a notation string, a hashref, or a
L<Game::Dominoes::Play>. The arm may be left out when only one is possible.

Returns the L<Game::Dominoes::Play> on success, or a L<Game::Dominoes::Error>.
Scoring, the end of a hand, the next deal and the end of the game all happen
inside this call.

=head2 resign

	$game->resign($seat);

Ends the game at once with that seat last. Returns the
L<Game::Dominoes::Result>.

=head2 places

	$game->places;   # { 1 => 2, 2 => 1 }

The finishing order from the scores. Places start at 1 and repeat on a tie, so
two seats level on second means nobody on third.

=head2 to_text

	$game->to_text;

The whole game so far in this distribution's notation.

=head1 SEE ALSO

L<Game::Dominoes::Layout>, L<Game::Dominoes::Scoring>,
L<Game::Dominoes::Error>, L<Game::Dominoes::Result>.

L<Game::Cribbage> and L<Game::Checkers>, the other two engines in this shape.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Dominoes>

=item * Search CPAN

L<https://metacpan.org/release/Game-Dominoes>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
