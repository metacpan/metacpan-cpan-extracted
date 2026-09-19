package Game::Go::Bot;

use 5.010;
use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Go::Rules;
use Game::Go::Move;

our $VERSION = '0.01';

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

our %LEVEL;
BEGIN {
	%LEVEL = (
		9  => { 1 =>  50, 2 =>  200, 3 =>  600, 4 => 1500, 5 => 3000 },
		13 => { 1 =>  50, 2 =>  150, 3 =>  350, 4 =>  700, 5 => 1200 },
		19 => { 1 =>  50, 2 =>  100, 3 =>  160, 4 =>  240, 5 =>  320 },
	);
}

use constant EXPLORE => 700;

use constant DEAD_PLAYOUTS => 60;

has level => (is => 'ro', isa => Int, default => 3);
has seed  => (is => 'ro', default => 'go');

has last_search => (is => 'rw');

has _disputed => (is => 'rw', private => 1, default => 0);

sub BUILD {
	my ($self) = @_;
	my $level = $self->level;
	die "Game::Go::Bot: level must be 1 to 5, not '$level'"
		unless $level >= 1 && $level <= 5;
	return;
}

sub levels { (1 .. 5) }

sub budget {
	my ($self, $size) = @_;
	my $table = $LEVEL{$size} or return $LEVEL{19}{ $self->level };
	return $table->{ $self->level };
}

sub _rng_seed {
	my ($self, $game, $colour) = @_;
	my $label = join ':', 'go-bot', $self->seed,
		Game::Go::Rules::letter($colour), scalar @{ $game->log };
	my $digest = Digest::SHA::sha256($label);
	return unpack 'N', substr($digest, 0, 4);
}

sub choose {
	my ($self, $game, $colour) = @_;

	return undef unless $game->status eq 'active';
	return undef unless Game::Go::Rules::is_colour($colour);

	return $self->mark($game, $colour) if $game->phase eq 'marking';

	return undef unless $colour == $game->turn;

	my $moves = $game->legal($colour);
	return undef unless @$moves;

	my @allowed = map { $_->kind eq 'pass' ? -1 : $_->point } @$moves;

	my $result = $game->search_from(
		colour   => $colour,
		allowed  => \@allowed,
		seed     => $self->_rng_seed($game, $colour),
		playouts => $self->budget($game->size),
		explore  => EXPLORE,
	);

	$self->last_search({
		%$result,
		level    => $self->level,
		size     => $game->size,
		roots    => scalar @allowed,
	});

	return Game::Go::Move->new(kind => 'pass', colour => $colour)
		if $result->{point} < 0;

	return Game::Go::Move->new(kind => 'play', colour => $colour, point => $result->{point});
}

sub mark {
	my ($self, $game, $colour) = @_;
	my $m = $game->marking or return undef;
	return undef unless $colour == $m->turn;

	if ($m->proposed) {
		my %theirs = map { $_ => 1 } @{ $m->dead_points };
		my %mine   = map { $_ => 1 } @{ $self->_dead_ids($game) };

		my $agree = (keys %theirs) == (keys %mine)
			&& !grep { !$theirs{$_} } keys %mine;

		if (!$agree && !$self->_disputed) {
			$self->_disputed(1);
			return Game::Go::Move->new(kind => 'dispute', colour => $colour);
		}
		return Game::Go::Move->new(kind => 'accept', colour => $colour);
	}

	my @todo;
	my %already = map { $_ => 1 } @{ $m->dead_points };
	for my $id (@{ $self->_dead_ids($game) }) {
		next if $already{$id};
		push @todo, Game::Go::Move->new(kind => 'mark', colour => $colour, point => $id);
	}
	return $todo[0] if @todo;

	return Game::Go::Move->new(kind => 'done', colour => $colour);
}

sub _dead_ids {
	my ($self, $game) = @_;

	my $guess = $game->dead_guess_from(
		seed     => $self->_rng_seed($game, Game::Go::Rules::BLACK),
		playouts => DEAD_PLAYOUTS,
	);

	my %ids;
	for my $pt (@$guess) {
		next if $game->is_alive($pt);
		my $id = $game->chain_id($pt);
		$ids{$id} = 1 if defined $id;
	}
	return [ sort { $a <=> $b } keys %ids ];
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Bot - Monte Carlo, because alpha-beta does not work on Go

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Go::Bot->new(level => 3, seed => $bytes);

    my $move = $bot->choose($game, $colour);   # a Move, or undef
    $bot->last_search;                          # what it thought

=head1 DESCRIPTION

=head2 Why this is not alpha-beta

Every other engine in this family of distributions searches with alpha-beta.
Go is also perfect information and alpha-beta is useless on it, for two reasons
that compound:

B<There is no static evaluation.> A Reversi evaluation is a weight table plus
mobility, and it works because a corner is worth having in every Reversi
position ever. There is no equivalent here: whether a stone is strong depends on
whether its group will live, which is the thing the evaluation was wanted for.

B<The branching factor is 361 at the root>, and stays above 200 for most of a
19x19 game. Reversi's is under ten.

So the leaf value is the result of playing the position out at random and
counting it, which needs no evaluation function at all.

=head2 The budget is playouts, never seconds

The bot runs inside a web move transaction, and a loaded machine must return the
B<same move> as an idle one, or the replay of a bot game stops reproducing and
the seed published at the end proves nothing.

The levels are therefore playout counts, per board size, because a playout is
not the same work on 81 points as on 361. Measured on the machine this was
written on:

     size    playouts/sec    1000 playouts
      9x9          14,000            69 ms
     13x13         4,600           210 ms
     19x19         1,300           723 ms

A slower machine plays the same moves more slowly rather than playing different
ones.

=head2 How good is it

B<Weak, and weakest on the big board.> It is a plain Monte Carlo player with
uniform playouts and no Go knowledge beyond not filling its own eyes. On 9x9 at
the top rung it plays recognisable moves; on 19x19 it is a beginner, because
361 root moves cannot be compared inside a web request.

That is the known cost of the game rather than a defect to be tuned away, and
the plan this was built from deferred Go four times over it. What the
distribution does about it is cap the top rung on the biggest board and say so
on the page, rather than offering a strength it does not have.

=head1 ATTRIBUTES

=head2 level

1 to 5. Level 1 should be beatable by somebody who has just read the rules.

=head2 seed

The game's seed. Every stream the bot uses is derived from it by SHA-256
together with B<the seat and the move number>: the seat so the two colours do
not play one opening from one seed, and the move number so a position reached
twice (which a dispute makes possible) is not searched with the same stream
twice.

=head2 last_search

What the last search did: the chosen point, the playouts run, the chosen move's
visits and win rate in permille, how many playouts hit the move cap, and how
many root moves there were.

=head1 METHODS

=head2 levels

=head2 budget

The playout count for this bot's level on a board of a given size.

=head2 choose

    $bot->choose($game, $colour)

A L<Game::Go::Move>, or B<undef> where the bot has nothing to say: a finished
game, a colour that is not to play, or a position with no legal move. Undef
rather than an error, because the site's bot driver breaks its loop on it.

During the confirmation phase this hands off to C<mark>.

=head2 mark

The confirmation phase, which B<a bot has to be able to play> or a bot game
strands in it and the clock times the bot out of a game it may well have won.

As the proposer it marks what the playouts say is dead and then finishes. As the
answerer it accepts a proposal matching its own reading, and B<disputes at most
once in a game>: a bot that disputed every round trip against a stubborn human
would turn a finished game into an unbounded one, and between a bot and a person
the bot is the party that should yield.

It judges dead stones B<by playouts and not by heuristics>: from the stopped
position, play it out and see whose the points end up being. And it never
proposes a mark on a chain Benson's algorithm finds unconditionally alive,
because the engine would refuse it and a refused bot move is a stranded game.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Marking>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
