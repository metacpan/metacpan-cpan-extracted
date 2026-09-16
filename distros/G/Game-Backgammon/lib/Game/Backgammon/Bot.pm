package Game::Backgammon::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Backgammon::Board;
use Game::Backgammon::Rules ();
use Game::Backgammon::Shots qw(shots_at);

our $VERSION = '0.01';

has level => (
	is => 'ro',
	isa => Int,
	default => 3
);

sub knows_blots  { $_[0]->level >= 3 }
sub knows_shape  { $_[0]->level >= 2 }

sub choose {
	my ($self, $game) = @_;
	my $turns = $game->legal_turns;
	return undef unless @$turns;
	return $turns->[0] if @$turns == 1;

	my $player = $game->turn;
	my ($best, $best_score);
	for my $turn (@$turns) {
		my $board = $game->board;
		$board = Game::Backgammon::Rules::apply_move($board, $_) for @{ $turn->moves };
		my $score = $self->score($board, $player);
		next if defined $best_score
			&& ($score < $best_score
			|| ($score == $best_score && $turn->key ge $best->key));
		($best, $best_score) = ($turn, $score);
	}
	return $best;
}

sub score {
	my ($self, $board, $player) = @_;
	my $them = Game::Backgammon::Board::other($player);

	my $score = $board->pip_count($them) - $board->pip_count($player);

	$score += 4 * ($board->off($player) - $board->off($them));
	$score += 12 * ($board->bar($them) - $board->bar($player));

	if ($self->knows_shape) {
		$score += 2 * $self->_made_points($board, $player);
		$score += 3 * $self->_longest_prime($board, $player) ** 2;
		$score += 8 if $self->_has_anchor($board, $player);
	}

	if ($self->knows_blots) {
		$score -= $self->blot_exposure($board, $player);
	}
	return $score;
}

sub blot_exposure {
	my ($self, $board, $player) = @_;
	my $them = Game::Backgammon::Board::other($player);
	my $risk = 0;

	for my $n (1 .. 24) {
		next unless $board->mine_on($player, $n) == 1;

		my $worst = 0;
		for my $k (1 .. $n - 1) {
			next unless $board->theirs_on($player, $k);
			my $shots = shots_at($n - $k);
			$worst = $shots if $shots > $worst;
		}
		if ($board->bar($them)) {
			my $shots = shots_at($n);
			$worst = $shots if $shots > $worst;
		}
		$risk += $worst;
	}
	return $risk;
}

sub _made_points {
	my ($self, $board, $player) = @_;
	my $n = 0;
	for my $p (1 .. 24) { $n++ if $board->mine_on($player, $p) >= 2 }
	return $n;
}

sub _longest_prime {
	my ($self, $board, $player) = @_;
	my ($best, $run) = (0, 0);
	for my $p (1 .. 24) {
		$run = $board->mine_on($player, $p) >= 2 ? $run + 1 : 0;
		$best = $run if $run > $best;
	}
	return $best;
}

sub _has_anchor {
	my ($self, $board, $player) = @_;
	for my $p (19 .. 24) { return 1 if $board->mine_on($player, $p) >= 2 }
	return 0;
}

1;

__END__

=head1 NAME

Game::Backgammon::Bot - the backgammon opponent

=head1 SYNOPSIS

    my $bot  = Game::Backgammon::Bot->new(level => 3);
    my $turn = $bot->choose($game);
    $game->play($turn) if $turn;

=head1 DESCRIPTION

One ply over the legal turns, scoring the position each reaches: pip
advantage, checkers off and on the bar, made points, the longest prime, an
anchor in the opponent's home board, and blot exposure.

Backgammon does not reward depth. Past this turn the dice are unknown, so a
second ply averages over rolls rather than reading a line, and the branching
is already in the hundreds on a double.

=head2 Bounded in work, not in time

C<choose> scores each legal turn exactly once, so the cost is a property of
the position. A bot inside a transaction on a busy server does the same work
and picks the same turn as one on an idle server. Ties break on the turn's
notation rather than on enumeration order, so the answer is stable.

=head2 Levels

Lower levels are ignorant rather than shallow, which is what makes them
beatable in a way a person can feel.

=over

=item * B<3> everything, including blot exposure.

=item * B<2> shape but not blots, so it leaves shots a person will punish.

=item * B<1> the pip count alone: a pure running game.

=back

=head1 SEE ALSO

L<Game::Backgammon::Shots> for the hit-probability table and what it
ignores.

=head1 METHODS

=head2 level

1, 2 or 3.

=head2 knows_blots, knows_shape

What this level is allowed to take into account.

=head2 choose($game)

The turn it would play, or undef when the game offers none.

=head2 score($board, $player)

The position from that player's side; higher is better for them.

=head2 blot_exposure($board, $player)

The total risk that player is carrying: for each of their blots, the worst
single shot bearing on it.

=cut
