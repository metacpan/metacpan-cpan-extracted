package Game::Oware::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();

use Game::Oware::Board;
use Game::Oware::Rules;
use Game::Oware::Scoring;
use Game::Oware::Variant ();

our $VERSION = '0.01';

our $STORE      = 100;
our $MATERIAL   = 2;
our $VULNERABLE = 5;
our $LOADED     = 3;
our $TERMINAL   = 1000;

my %LEVEL = (
	1 => { depth => 1,  nodes =>    500, blunder => 1 },
	2 => { depth => 3,  nodes =>   4000, blunder => 1 },
	3 => { depth => 5,  nodes =>  20000, blunder => 0 },
	4 => { depth => 8,  nodes => 120000, blunder => 0 },
	5 => { depth => 11, nodes => 400000, blunder => 0 },
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
);

has last_search => (
	is      => 'rw',
	isa     => HashRef,
	default => {}
);

sub BUILD {
	my ($self) = @_;
	die 'Game::Oware::Bot: there is no level ' . $self->level
		unless $LEVEL{ $self->level };
	return $self;
}

sub levels { return sort { $a <=> $b } keys %LEVEL }

sub setting_for {
	my ($class, $level) = @_;
	die "Game::Oware::Bot: there is no level $level" unless $LEVEL{$level};
	return { %{ $LEVEL{$level} } };
}

sub choose {
	my ($self, $game, $seat) = @_;

	return undef unless $game->status eq 'active';
	return undef unless defined $seat && $seat eq $game->turn;

	my $legal = $game->legal($seat);
	return undef unless @$legal;

	$self->last_search({ depth => 0, nodes => 0, score => undef, move => $legal->[0] });
	return $legal->[0] if @$legal == 1;

	my $state = {
		nodes   => 0,
		setting => $LEVEL{ $self->level },
		variant => $game->variant,
	};

	my @ranked = $self->_search($state, $game, $seat, $legal);
	my $pick = $self->_pick($state, $game, $seat, \@ranked);

	$self->last_search({
		depth => $state->{depth} // 0,
		nodes => $state->{nodes},
		score => $ranked[0]{score},
		move  => $pick,
	});

	return $pick;
}

sub _search {
	my ($self, $state, $game, $seat, $legal) = @_;

	my @children = $self->_children($state, $game->board, $seat, $legal);
	my @ranked = map { { house => $_->{house}, score => 0 } } @children;

	for my $depth (1 .. $state->{setting}{depth}) {
		last if $state->{nodes} >= $state->{setting}{nodes};

		my @round;
		$state->{spent} = 0;

		for my $child (@children) {
			my $score = -$self->_alphabeta($state, $child->{board},
				Game::Oware::Board->other($seat), $depth - 1,
				-1_000_000, 1_000_000);
			push @round, { house => $child->{house}, score => $score };
		}

		last if $state->{spent};

		@ranked = sort { $b->{score} <=> $a->{score} } @round;
		$state->{depth} = $depth;

		my %order = map { $ranked[$_]{house} => $_ } 0 .. $#ranked;
		@children = sort { $order{ $a->{house} } <=> $order{ $b->{house} } } @children;
	}

	return @ranked;
}

sub _children {
	my ($self, $state, $board, $seat, $legal) = @_;

	my @children;
	for my $house (@$legal) {
		my ($next, $move) =
			Game::Oware::Rules->resolve($board, $house, $seat, $state->{variant});
		push @children, { house => $house, board => $next, taken => $move->taken };
	}

	return sort { $b->{taken} <=> $a->{taken} || $a->{house} <=> $b->{house} } @children;
}

sub _alphabeta {
	my ($self, $state, $board, $seat, $depth, $alpha, $beta) = @_;

	$state->{nodes}++;

	return $self->_final($board, $seat)
		if Game::Oware::Scoring->target_reached($board)
		|| Game::Oware::Scoring->is_draw($board);

	my @legal =
		Game::Oware::Rules->legal_moves($board, $seat, $state->{variant});

	return $self->_final(Game::Oware::Scoring->sweep_to($board, $seat), $seat)
		unless @legal;

	if ($state->{nodes} >= $state->{setting}{nodes}) {
		$state->{spent} = 1;
		return $self->_leaf($board, $seat);
	}

	return $self->_leaf($board, $seat) if $depth <= 0;

	my $best = -1_000_000;

	for my $child ($self->_children($state, $board, $seat, \@legal)) {
		my $score = -$self->_alphabeta($state, $child->{board},
			Game::Oware::Board->other($seat), $depth - 1, -$beta, -$alpha);

		$best  = $score if $score > $best;
		$alpha = $score if $score > $alpha;
		last if $alpha >= $beta;
	}

	return $best;
}

sub _final {
	my ($self, $board, $seat) = @_;
	my $captured = Game::Oware::Scoring->captured($board);
	my $foe = Game::Oware::Board->other($seat);
	return ($captured->{$seat} - $captured->{$foe}) * $TERMINAL;
}

sub _leaf {
	my ($self, $board, $seat) = @_;

	my $foe = Game::Oware::Board->other($seat);
	my $captured = Game::Oware::Scoring->captured($board);

	my $score = ($captured->{$seat} - $captured->{$foe}) * $STORE;

	$score += (Game::Oware::Board->seeds_on_side($board, $seat)
		- Game::Oware::Board->seeds_on_side($board, $foe)) * $MATERIAL;

	my ($mine, $theirs, $loaded_mine, $loaded_theirs) = (0, 0, 0, 0);
	for my $house (Game::Oware::Board->houses_of($seat)) {
		$mine++        if $board->[$house] == 1 || $board->[$house] == 2;
		$loaded_mine++ if $board->[$house] >= 12;
	}
	for my $house (Game::Oware::Board->houses_of($foe)) {
		$theirs++        if $board->[$house] == 1 || $board->[$house] == 2;
		$loaded_theirs++ if $board->[$house] >= 12;
	}

	$score -= ($mine - $theirs) * $VULNERABLE;
	$score += ($loaded_mine - $loaded_theirs) * $LOADED;

	return $score;
}

sub _draw {
	my ($self, $game, $seat, $range) = @_;
	my $ply = scalar @{ $game->log };
	my $hash = Digest::SHA::sha256_hex($self->seed . ':' . $seat . ':' . $ply);
	return hex(substr $hash, 0, 8) % $range;
}

sub _pick {
	my ($self, $state, $game, $seat, $ranked) = @_;

	my $best = $ranked->[0]{score};
	my @tied = grep { $_->{score} == $best } @$ranked;

	unless ($state->{setting}{blunder}) {
		return $tied[ $self->_draw($game, $seat, scalar @tied) ]{house};
	}

	my $roll = $self->_draw($game, $seat, 100);
	return $ranked->[1]{house} if $roll < 25 && @$ranked > 1;
	return $ranked->[2]{house} if $roll < 35 && @$ranked > 2;
	return $tied[ $self->_draw($game, $seat, scalar @tied) ]{house};
}

1;

__END__

=head1 NAME

Game::Oware::Bot - an opponent, on a node budget

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Bot;

    my $bot   = Game::Oware::Bot->new(level => 3, seed => $bytes);
    my $house = $bot->choose($game, 'p1');

    $game->play('p1', $house);
    $bot->last_search;    # { depth => 5, nodes => 18211, score => 312, move => 4 }

=head1 DESCRIPTION

Negamax with alpha-beta over a state that fits in fourteen integers, which is
the cheapest search on any board this author has written an engine for.

=head2 choose returns one of the moves the game already offered

It asks C<< $game->legal($seat) >> and picks from what comes back. It never
builds a candidate list of its own, so it cannot play an illegal move however
wrong its judgement is.

That matters more here than in most games. The feeding obligation means the
legal list is B<not> "the houses with seeds in them", so a bot that generated
its own candidates would offer refused moves in exactly the positions a human
finds most confusing: the ones where the opponent has been starved.

=head2 The budget is in nodes, never in seconds

A loaded machine must choose the same move as an idle one, or a bot game stops
replaying and the whole verification story goes with it. The budget is spent
through iterative deepening, so running out always leaves a complete search of a
shallower depth rather than half of a deeper one.

The counter is a plain hashref carried down the recursion rather than a
property. An accessor call per node would be most of the cost of the bot.

=head2 Capturing is the right primary term here, which is the opposite of Reversi

L<Game::Reversi::Bot> warns that maximising discs is the beginner's mistake,
because a disc can be flipped back. B<An Oware capture cannot be undone>: a seed
in a store never returns to the board. So the captured difference is the
objective rather than a proxy for it, and it dominates the evaluation.

That contrast is worth stating because the Reversi bot is the nearest template
in this author's tree, and copying its warning across would produce an Oware bot
that ignores the only thing that scores.

=head2 The other three terms are what stop it being a counting machine

=over

=item C<$MATERIAL>

Seeds in your own row, weighted low. They are not yours until captured and a
sow gives them away, so this is a tiebreak rather than a goal.

=item C<$VULNERABLE>

Houses of one or two seeds on your own side, weighted B<negative>. Those are
precisely what an opponent captures by bringing them to two or three, so
counting them is how the bot learns to defend without being told the rule.

=item C<$LOADED>

Houses of twelve or more, weighted slightly positive. A house that laps the
board is a real threat and is hard to answer, and it is also the one thing the
origin-skip rule exists for, so a bot blind to it has never met the hardest rule
in the game.

=back

They are C<our> variables rather than constants on purpose: C<use constant> is
inlined at compile time, so a caller sweeping the weights to tune them would
silently measure the same value however many times it ran.

=head2 The search ignores the cycle rule, and that is a documented limitation

The value of a position under D2 depends on its history: the same board is a
draw if it is the third occurrence and is not otherwise. The search does not
carry that, so it evaluates lines past a point where the cycle rule would
already have swept the board.

It is bounded rather than dangerous: the ply cap guarantees the game terminates
whatever the bot believes, and C<t/19-bot-terminates.t> asserts that a
bot-against-bot game always ends. B<Do not add a transposition table keyed on
the twelve houses to fix this.> That key is unsound near a cycle for the same
reason, and it collides across positions with different stores, which is where
the endgame is decided.

=head2 Tie-breaks come from the seed AND the seat

No C<rand>, ever. The choice among equally-scored moves is drawn from a hash of
the bot's seed, the seat, and the ply.

B<The seat is not decoration.> Without it both bots in a game are the same bot,
open the same way every time, and a human reads the rule off two games.
C<Game::Goofspiel> on the site this engine feeds shipped with exactly that fault
and every bot game finished level.

=head2 blunder is how a low rung loses gently

Levels 1 and 2 take the second or third best move some of the time, drawn from
the same hash. A bot that always plays its best move at depth one does not play
badly, it plays B<predictably> badly, and a human reads it in two games.

=head2 There is no blind gate here, because there is nothing to hide

Oware is perfect information. The hidden-information engines in this author's
tree carry a test proving C<choose> cannot see what a seat should not; this one
does not need one, and its absence is a fact about the game rather than a
missing test.

=head1 PROPERTIES

=head2 level

One to five. C<BUILD> dies on anything else.

=head2 seed

Mixed with the seat and the ply for every tie-break. Defaults to the empty
string, which is deterministic but makes both seats behave alike, so a real
consumer passes one.

=head2 last_search

C<< { depth, nodes, score, move } >> from the most recent C<choose>.

=head1 METHODS

=head2 levels

Every level, ascending.

=head2 setting_for

A copy of one level's table, so a caller can see what a rung means without
reaching into the module.

=head2 choose

    my $house = $bot->choose($game, $seat);

A house index, or C<undef> when the game is over, when it is not that seat's
turn, or when the seat has nothing to play.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Rules>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
