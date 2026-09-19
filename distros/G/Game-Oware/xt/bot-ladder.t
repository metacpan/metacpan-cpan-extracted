#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Bot;

# Does a higher level actually play better?
#
# In xt because it takes minutes, and double guarded so that a smoker never
# waits on it.
unless ($ENV{RELEASE_TESTING} || $ENV{OWARE_LADDER}) {
	plan(skip_all => 'set RELEASE_TESTING or OWARE_LADDER to run the ladder');
}

# TWO DETERMINISTIC BOTS AT ONE RUNG PLAY ONE GAME.
#
# Oware has no deal, no dice and no shuffle: the opening position is the same
# every time and both bots are functions of it. So a "tournament" of two hundred
# games between one pair of levels is ONE game played two hundred times, and its
# result is a coin flip reported with false confidence.
#
# The seed is what varies them, through the tie-break hash, so every game below
# gets its own. The seeds are written out rather than generated, so a run is
# reproducible and a failure can be reopened.
my @SEEDS = qw(
	ladder-01 ladder-02 ladder-03 ladder-04 ladder-05
	ladder-06 ladder-07 ladder-08 ladder-09 ladder-10
);

# TEN GAMES PER PAIR, AND THE NUMBER WAS FIXED BEFORE ANY RESULT WAS SEEN.
#
# Ten is enough to catch a rung that plays identically to its neighbour, which
# is the fault this test exists for, and it is not enough to resolve a small
# real difference in strength. It is chosen against the cost: one game between
# levels four and five takes about thirty seconds.
my $GAMES = scalar @SEEDS;

my $PLY_CAP = 400;

sub play {
	my ($seed, $white, $black) = @_;

	my $game = Game::Oware->new(seed => $seed);
	my %bot = (
		p1 => Game::Oware::Bot->new(level => $white, seed => "$seed-p1"),
		p2 => Game::Oware::Bot->new(level => $black, seed => "$seed-p2"),
	);

	my $plies = 0;
	while ($game->status eq 'active' && $plies < $PLY_CAP) {
		my ($seat) = $game->waiting_on;
		my $house = $bot{$seat}->choose($game, $seat);
		last unless defined $house;
		my $out = $game->play($seat, $house);
		last if ref $out && $out->isa('Game::Oware::Error');
		$plies++;
	}

	return ($game->winner, $plies);
}

# Each pair plays half its games with the stronger rung in each seat, because
# p1 moves first and this engine has never measured what that is worth.
sub match {
	my ($weak, $strong) = @_;

	my %score = (strong => 0, weak => 0, drawn => 0);
	my $plies = 0;

	for my $i (0 .. $GAMES - 1) {
		my $strong_is_p1 = $i % 2 == 0;
		my ($winner, $length) = $strong_is_p1
			? play($SEEDS[$i], $strong, $weak)
			: play($SEEDS[$i], $weak, $strong);

		$plies += $length;

		if (!defined $winner) { $score{drawn}++ }
		elsif ($winner eq ($strong_is_p1 ? 'p1' : 'p2')) { $score{strong}++ }
		else { $score{weak}++ }
	}

	return (\%score, $plies);
}

for my $pair ([ 1, 2 ], [ 2, 3 ], [ 3, 4 ], [ 4, 5 ]) {
	my ($weak, $strong) = @$pair;

	subtest "level $strong against level $weak" => sub {
		my ($score, $plies) = match($weak, $strong);

		diag(sprintf 'level %d v level %d: %d won, %d lost, %d drawn, %d plies total',
			$strong, $weak, $score->{strong}, $score->{weak}, $score->{drawn}, $plies);

		# The top pair is asserted as "does not lose" rather than "wins".
		# Oware is a draw under perfect play (Romein and Bal, 2002), so strong
		# levels converge, and demanding a win from the strongest rung is
		# demanding something the game may not have to give.
		if ($strong == 5) {
			cmp_ok($score->{strong}, '>=', $score->{weak},
				"level $strong does not lose the match to level $weak");
		}
		else {
			cmp_ok($score->{strong}, '>', $score->{weak},
				"level $strong beats level $weak over $GAMES games");
		}
	};
}

done_testing;
