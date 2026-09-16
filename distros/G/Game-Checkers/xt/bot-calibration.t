#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ($ENV{AUTHOR_TESTING}) {
	plan skip_all => 'Author tests not required for installation';
}

use Game::Checkers;
use Game::Checkers::Bot;

# A level is worth having only if it beats the one below it. Two bots of the
# same strength from the same position draw every time, so each pair plays from
# several openings with the colours swapped.
#
# Runtime: the 1 against 2 pair is seconds and 2 against 3 is a couple of
# minutes. Set CHECKERS_CALIBRATE_ALL to add 3 against 4 and 4 against 5, which
# are tens of minutes: level 5 alone is about thirteen seconds a move from the
# opening in pure Perl. CHECKERS_CALIBRATE_OPENINGS trims the set.

my $OPENINGS = $ENV{CHECKERS_CALIBRATE_OPENINGS} || 7;
my $PLIES = $ENV{CHECKERS_CALIBRATE_PLIES} || 40;

my @PAIRS = ([1, 2], [2, 3]);
push @PAIRS, [3, 4], [4, 5] if $ENV{CHECKERS_CALIBRATE_ALL};

plan tests => scalar @PAIRS;

my %VALUE = (1 => 100, 2 => 160, -1 => -100, -2 => -160);

sub material {
	my ($game) = @_;
	my $score = 0;
	my $position = $game->board->position;
	$score += $VALUE{$position->[$_]} || 0 for 1 .. 32;
	return $score;
}

# a game stopped at the ply cap is decided on material, as an adjourned game is
sub play {
	my ($opening, $black, $white) = @_;
	my $game = Game::Checkers->new;
	$game->move($opening);
	my %bot = (
		black => Game::Checkers::Bot->new(level => $black, seed => 1),
		white => Game::Checkers::Bot->new(level => $white, seed => 2)
	);
	while ($game->status eq 'active' && $game->ply < $PLIES) {
		$game->move($bot{$game->turn}->choose($game));
	}
	return $game->result->winner || 'draw' if $game->result;
	my $material = material($game);
	return $material > 50 ? 'black' : $material < -50 ? 'white' : 'draw';
}

my @OPENING = do {
	my $game = Game::Checkers->new;
	(map { $_->notation } @{$game->legal_moves})[0 .. $OPENINGS - 1];
};

for my $pair (@PAIRS) {
	my ($low, $high) = @{$pair};
	my %score = (wins => 0, losses => 0, draws => 0);

	for my $opening (@OPENING) {
		# the stronger bot takes each colour once from each opening
		my $as_black = play($opening, $high, $low);
		$score{$as_black eq 'black' ? 'wins' : $as_black eq 'white' ? 'losses' : 'draws'}++;

		my $as_white = play($opening, $low, $high);
		$score{$as_white eq 'white' ? 'wins' : $as_white eq 'black' ? 'losses' : 'draws'}++;
	}

	diag sprintf 'level %d against level %d: %d wins, %d losses, %d draws',
		$high, $low, @score{qw/wins losses draws/};

	cmp_ok $score{wins}, '>=', $score{losses},
		"level $high does not lose to level $low over " . (2 * @OPENING) . ' games';
}
