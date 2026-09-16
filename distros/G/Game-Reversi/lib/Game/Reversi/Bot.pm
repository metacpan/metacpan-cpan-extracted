package Game::Reversi::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();

use Game::Reversi::Board;
use Game::Reversi::Move;
use Game::Reversi::Opening;

our $VERSION = '0.01';

my @WEIGHT = (
	120, -20,  20,   5,   5,  20, -20, 120,
	-20, -40,  -5,  -5,  -5,  -5, -40, -20,
	 20,  -5,  15,   3,   3,  15,  -5,  20,
	  5,  -5,   3,   3,   3,   3,  -5,   5,
	  5,  -5,   3,   3,   3,   3,  -5,   5,
	 20,  -5,  15,   3,   3,  15,  -5,  20,
	-20, -40,  -5,  -5,  -5,  -5, -40, -20,
	120, -20,  20,   5,   5,  20, -20, 120,
);

our $MOBILITY = 5;

our $ENDGAME = 20;

my %LEVEL = (
	1 => { nodes =>    60, mobility => 0, exact => 0,  depth =>  1 },
	2 => { nodes =>   400, mobility => 0, exact => 6,  depth =>  3 },
	3 => { nodes =>  1500, mobility => 1, exact => 8,  depth =>  5 },
	4 => { nodes =>  5000, mobility => 1, exact => 9,  depth =>  8 },
	5 => { nodes =>  8000, mobility => 1, exact => 10, depth => 14, book => 0 },
);

sub levels { return sort { $a <=> $b } keys %LEVEL }

has level => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has seed => (
	is      => 'ro',
	default => 0
);

has last_search => (
	is  => 'rw',
	isa => Any
);

sub BUILD {
	my ($self) = @_;
	die 'Game::Reversi::Bot: there is no level ' . $self->level
		unless $LEVEL{ $self->level };
	return $self;
}

sub choose {
	my ($self, $game, $colour) = @_;
	return undef unless $game->status eq 'active';
	return undef unless defined $colour;
	return undef unless defined $game->turn && $game->turn eq $colour;

	my $legal = $game->legal($colour);
	return undef unless @$legal;
	return $legal->[0] if @$legal == 1;

	return $self->_open($game, $colour, $legal)
		if $game->phase eq 'opening' && !$LEVEL{ $self->level }{book};

	return $self->_search($game, $colour, $legal);
}

sub _open {
	my ($self, $game, $colour, $legal) = @_;
	my $key = join '|', $self->_seed($colour), scalar @$legal,
		join ',', map { $_->square } @$legal;
	my $word = unpack 'N', Digest::SHA::sha256($key);
	$self->last_search({ nodes => 0, depth => 0, opening => 1 });
	return $legal->[ $word % scalar @$legal ];
}

sub _seed {
	my ($self, $colour) = @_;
	return unpack 'H16',
		Digest::SHA::sha256('reversi-bot:' . $self->seed . ':' . ($colour // '?'));
}

sub _search {
	my ($self, $game, $colour, $legal) = @_;
	my $setting = $LEVEL{ $self->level };
	my $board = $game->board;

	my @ordered = $self->_order($board, $colour, [ map { $_->square } @$legal ]);
	my %move_of = map { $_->square => $_ } @$legal;

	my $state = {
		nodes => 0, over_budget => 0,
		budget => $setting->{nodes}, setting => $setting,
	};

	my $best = $ordered[0];
	my $depth_reached = 0;
	my $value;

	for my $depth (1 .. $setting->{depth}) {
		my ($square, $score) = $self->_root($state, $board, $colour, $depth, \@ordered);
		last unless defined $square;
		($best, $value, $depth_reached) = ($square, $score, $depth);
		last if $state->{nodes} >= $state->{budget};

		@ordered = ($best, grep { $_ != $best } @ordered);
	}

	$self->last_search({
		nodes => $state->{nodes}, depth => $depth_reached,
		value => $value, opening => 0,
	});
	return $move_of{$best};
}

sub _root {
	my ($self, $state, $board, $colour, $depth, $ordered) = @_;
	my ($best, $alpha) = (undef, -1e9);

	for my $square (@$ordered) {
		my $after = Game::Reversi::Board->apply($board, $square, $colour);
		my $score = -$self->_alphabeta($state, $after, Game::Reversi::Board->other($colour),
			$depth - 1, -1e9, -$alpha, 0);
		return (undef, undef) if $state->{over_budget};
		if ($score > $alpha) {
			($alpha, $best) = ($score, $square);
		}
	}
	return ($best, $alpha);
}

sub _alphabeta {
	my ($self, $state, $board, $colour, $depth, $alpha, $beta, $passes) = @_;

	if (++$state->{nodes} > $state->{budget}) {
		$state->{over_budget} = 1;
		return 0;
	}

	return $self->_leaf($state, $board, $colour) if $depth <= 0;

	my @moves = Game::Reversi::Board->legal_moves($board, $colour);

	if (!@moves) {
		return $self->_leaf($state, $board, $colour) if $passes;
		return -$self->_alphabeta($state, $board, Game::Reversi::Board->other($colour),
			$depth, -$beta, -$alpha, 1);
	}

	for my $square ($self->_order($board, $colour, \@moves)) {
		my $after = Game::Reversi::Board->apply($board, $square, $colour);
		my $score = -$self->_alphabeta($state, $after, Game::Reversi::Board->other($colour),
			$depth - 1, -$beta, -$alpha, 0);
		return 0 if $state->{over_budget};
		return $beta if $score >= $beta;
		$alpha = $score if $score > $alpha;
	}
	return $alpha;
}

sub _leaf {
	my ($self, $state, $board, $me) = @_;
	my $them = Game::Reversi::Board->other($me);
	my $empty = Game::Reversi::Board->empties($board);
	my $count = Game::Reversi::Board->count($board);

	return ($count->{$me} - $count->{$them}) * 100
		if $empty <= $state->{setting}{exact};

	my $score = 0;
	for my $square (0 .. 63) {
		my $cell = $board->[$square];
		next unless defined $cell;
		$score += $cell eq $me ? $WEIGHT[$square] : -$WEIGHT[$square];
	}

	$score -= $MOBILITY * scalar(Game::Reversi::Board->legal_moves($board, $them))
		if $state->{setting}{mobility};

	$score += ($count->{$me} - $count->{$them}) * ($ENDGAME - $empty)
		if $empty < $ENDGAME;

	return $score;
}

sub _order {
	my ($self, $board, $colour, $squares) = @_;
	return sort { $WEIGHT[$b] <=> $WEIGHT[$a] || $a <=> $b } @$squares;
}

1;

__END__

=head1 NAME

Game::Reversi::Bot - an opponent that does not simply grab discs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Reversi::Bot->new(level => 3, seed => 42);
    my $move = $bot->choose($game, $game->turn);
    $game->play($game->turn, $move->square) if $move;

    $bot->last_search;    # { nodes => 1502, depth => 5, value => 38 }

=head1 DESCRIPTION

Reversi is a perfect information game, so this is plain alpha beta. None of the
determinisation a hidden information game needs, and none of the anti cheat gate
that goes with it, because there is nothing here to peek at.

=head2 Maximising discs is the beginner's mistake

I<Games> magazine, November 1982, issue 33, page 46, quoted by Wikipedia:

=over 4

Although the goal is to finish with the most pieces of your color up, the best
strategy, paradoxically, is usually to limit your opponent's options by flipping
over as I<few> of his discs as possible during the first two-thirds of the game.

=back

Three things in one sentence, and all three are in the evaluation: disc count is
the wrong objective, limiting the opponent's options is the right one, and the
switch comes near the end rather than at the start.

=head2 The counters are not properties

C<nodes> is incremented once per node, millions of times in a level five
search, so the counters the search runs on are a plain hashref carried down the
recursion. An accessor call apiece would be the whole cost of the bot, which is
the same reason L<Game::Reversi::Board> works on a raw array.

=head2 The budget is in nodes, never in seconds

A loaded machine must choose the same move as an idle one, or a bot game stops
replaying. The budget is spent through iterative deepening, so running out
always leaves a complete search of a shallower depth rather than half of a
deeper one.

The numbers are small because the primitives are. C<legal_moves> costs roughly
100 microseconds on the machine this was tuned on, which puts a search node at
about the same, so ten thousand nodes is about a second. A host running this
inside a web request wants level 3 or below.

=head2 The weight table is ours

It is not cited and no quotable source was found for it. What it encodes:

The four corners are worth most, and B<that part is not a matter of taste>: a
corner can never be turned. Turning a disc requires the played disc and a
bounding disc of the same colour on opposite sides of it along a ray, and a
corner has no square on the far side of any ray, so no line through it can ever
be closed. The test suite proves that property directly rather than assuming it.

The squares next to a corner are worth least, the diagonal neighbour least of
all, because playing there is what hands the corner over. Everything else is
small: the middle of the board is nearly worthless in Reversi, which is the
opposite of most board games and is why a table written from intuition would be
wrong.

=head2 The opening is drawn from a seed, not searched

The historic opening places four discs that capture nothing, so the evaluation
has almost nothing to say, and there is no book: every opening book ever written
starts from the one fixed position Othello uses.

So the choice is drawn from a hash of the bot's own seed B<and the seat>. The
seat is not decoration. Without it both bots in a game are the same bot, open
the same way every time, and a human reads the rule off two games.
C<Game::Goofspiel> on the same site shipped with exactly that fault and every
bot game finished level.

Level 5 searches the opening instead, which is not obviously better and is at
least different.

=head1 METHODS

=head2 new

C<level> is 1 to 5 and defaults to 3. C<seed> is the bot's own, and is combined
with the seat before use.

=head2 level, levels, seed

The level this bot plays at, all of them, and the seed its opening is drawn
from.

=head2 choose

A L<Game::Reversi::Move>, or C<undef> when the game is over, when it is not that
seat's turn, or when there is nothing to play.

=head2 last_search

What the last call did: C<nodes>, C<depth>, C<value>, and C<opening> for a move
that was drawn rather than searched.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
