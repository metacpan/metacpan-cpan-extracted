#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Bot;

# Does a higher level actually play better?
#
# NOTHING ELSE IN THE SUITE ASKS THIS. Every other bot test checks that the bot
# returns something legal and does not break the game, which a bot choosing at
# random would also pass. A level that searched more and played worse would look
# entirely healthy.
#
# That is not a theoretical worry. Game::Dominoes on the same shelf shipped a
# level 3 that lost to its own level 2 over forty games, because it was sampling
# too few worlds at greater depth, and its ladder was the only thing that
# noticed.
#
# xt/ rather than t/: a full game at level 5 takes about half a minute, so this
# file costs minutes and nobody installing the module should pay for it.

unless ($ENV{RELEASE_TESTING} || $ENV{REVERSI_LADDER}) {
	plan skip_all => 'set RELEASE_TESTING or REVERSI_LADDER to run the ladder';
}

my $B = 'Game::Reversi::Board';

# HOW MANY GAMES, WRITTEN DOWN BEFORE THE RESULTS ARE SEEN.
#
# Six per pairing, three with each level as Black, because the seat matters: the
# openings are not symmetric and Black moves first. Six is few, and it is chosen
# because a full game at the top of the ladder takes half a minute; the
# assertions below are sized for six and say so rather than pretending to more
# confidence than six games buy.
my $GAMES = 6;

# OBSERVED ON 15 SEP 2026, immediately after the ladder was written, so that a
# later reversal has something to be a reversal FROM:
#
#     level 2 vs level 1: 5-1-0
#     level 3 vs level 2: 6-0-0
#     level 4 vs level 3: 5-1-0
#     level 5 vs level 4: 6-0-0
#
# The assertions below are deliberately weaker than that. They are a floor
# written before the run, not a transcription of it, and the top of the ladder is
# only asked not to lose because the game itself does not promise more.

# Play one game. Returns the winner's colour, or undef for a tie.
sub match {
	my ($black_level, $white_level, $seed) = @_;
	my $game = Game::Reversi->new(variant => 'historic');
	my %bot = (
		b => Game::Reversi::Bot->new(level => $black_level, seed => "ladder-b-$seed"),
		w => Game::Reversi::Bot->new(level => $white_level, seed => "ladder-w-$seed"),
	);

	my $moves = 0;
	while ($game->status eq 'active' && $moves++ < 200) {
		my $colour = $game->turn;
		my $move = $bot{$colour}->choose($game, $colour) or last;
		$game->play($colour, $move->square);
	}
	die 'a ladder game did not finish' unless $game->status eq 'finished';
	return $game->winner;
}

# $high against $low over $GAMES games, alternating seats.
sub ladder {
	my ($high, $low) = @_;
	my ($won, $lost, $tied) = (0, 0, 0);

	for my $n (1 .. $GAMES) {
		my $high_is_black = $n % 2;
		my $winner = $high_is_black
			? match($high, $low, "$high-$low-$n")
			: match($low, $high, "$high-$low-$n");

		my $high_colour = $high_is_black ? 'b' : 'w';
		if (!defined $winner)              { $tied++ }
		elsif ($winner eq $high_colour)    { $won++ }
		else                               { $lost++ }
	}
	return ($won, $lost, $tied);
}

for my $low (1 .. 4) {
	my $high = $low + 1;
	my ($won, $lost, $tied) = ladder($high, $low);
	diag("level $high vs level $low: $won-$lost-$tied over $GAMES games");

	# REVERSI IS A DRAW UNDER PERFECT PLAY (Takizawa, "Othello is Solved",
	# arXiv:2310.19387, 2023), so the levels converge as they get stronger and a
	# ladder sized for a game with a decisive result would be wrong here.
	#
	# So the bottom of the ladder is asserted as "wins more than it loses", and
	# the top only as "does not lose the series". Asserting a win at the top
	# would be asserting something the game itself does not promise.
	if ($high <= 3) {
		cmp_ok($won, '>', $lost,
			"level $high beats level $low more often than it loses");
	}
	else {
		cmp_ok($won, '>=', $lost,
			"level $high does not lose a series to level $low");
	}
}

# A LADDER RESULT THAT REVERSES IS NOT AUTOMATICALLY A BUG. Six games is inside
# the noise for a game this drawish, and a single reversal should be re-run
# before anybody starts changing weights. Dominoes' ladder reversed once for real
# and once for variance, and telling them apart took repeated runs rather than
# reasoning.
diag('a reversal here is worth re-running before it is believed: '
	. "$GAMES games is few, and Reversi is drawish under strong play");

done_testing();
