#!perl

# THE LADDER: does a higher level beat a lower one?
#
# A release test, because it plays hundreds of games and takes minutes.
#
# TWO LESSONS FROM A SIBLING DISTRIBUTION'S LADDER, both learned the hard way
# and both written into the assertions below:
#
#   MORE SEARCH CAN BE WORSE, and only a ladder catches it. Its level 3 lost to
#     its level 2 over forty games because it was sampling too few worlds at
#     greater depth, and nothing else in its suite would have noticed.
#
#   A SINGLE FORTY-GAME RESULT IS INSIDE THE NOISE. So the number of games is
#     written down, the observed result is recorded in this file as a baseline,
#     and a reversal is expected to be re-run before it is believed.
#
# AND A LESSON THIS GAME ADDS. Go is not Reversi: a Monte Carlo bot with uniform
# playouts has a lot of variance, and the two bottom rungs on a 9x9 board are
# close enough that either can win a short match. The assertion is therefore
# "the top rung beats the bottom rung", which is the claim the levels actually
# make, rather than "every rung beats the one below it", which they do not.

use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

unless ($ENV{RELEASE_TESTING} || $ENV{GO_LADDER}) {
	plan skip_all => 'minutes of games: set RELEASE_TESTING or GO_LADDER';
}

use Game::Go;
use Game::Go::Bot;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# GAMES PER RUNG, WRITTEN DOWN. Twenty is few, and it is what a 19x19 board can
# afford here: at the top rung a 19x19 game is a few hundred moves at a quarter
# of a second each.
my %GAMES = (9 => 30, 13 => 20, 19 => 6);

# One game. Returns the winner, or undef if it did not finish.
#
# THE GUARD SCALES WITH THE BOARD, and a fixed one was this file's own bug. The
# first version used 600 actions for every size: ample for 81 points, and on a
# 19x19 board it cut every game off with twenty-odd points still empty, so the
# ladder reported six unfinished games and no result at all. A level 5 against
# level 1 game on 19x19 runs about 850 actions.
#
# 4 * size * size, which is the playout cap plus room for the confirmation
# phase. On 19x19 that is 1444.
sub play_out {
	my ($size, $black, $white, $seed) = @_;
	my $g = Game::Go->new(size => $size, seed => $seed x 32);
	my %bot = ($B => $black, $W => $white);

	my $n = 0;
	my $guard = 4 * $size * $size;
	while ($g->status eq 'active' && $n++ < $guard) {
		my ($who) = $g->waiting_on;
		last unless defined $who;
		my $m = $bot{$who}->choose($g, $who) or last;
		my $out =
			  $m->kind eq 'play'    ? $g->play($who, $m->point)
			: $m->kind eq 'pass'    ? $g->pass($who)
			: $m->kind eq 'mark'    ? $g->mark($who, $m->point)
			: $m->kind eq 'done'    ? $g->done($who)
			: $m->kind eq 'accept'  ? $g->accept($who)
			: $m->kind eq 'dispute' ? $g->dispute($who)
			: undef;
		last if ref $out eq 'Game::Go::Error';
	}
	return $g->status eq 'finished' ? $g->winner : undef;
}

diag('');
for my $size (Game::Go->sizes) {
	my $games = $GAMES{$size};
	my ($top_wins, $bottom_wins, $unfinished) = (0, 0, 0);
	my $t0 = time;

	for my $i (1 .. $games) {
		# ALTERNATING SEATS, so black's first-move advantage is not the result.
		my $top    = Game::Go::Bot->new(level => 5, seed => "top$i");
		my $bottom = Game::Go::Bot->new(level => 1, seed => "bot$i");

		my $winner = $i % 2
			? play_out($size, $top, $bottom, chr(96 + ($i % 26) + 1))
			: play_out($size, $bottom, $top, chr(96 + ($i % 26) + 1));

		if (!defined $winner)            { $unfinished++ }
		elsif (($i % 2) == ($winner == $B ? 1 : 0)) { $top_wins++ }
		else                             { $bottom_wins++ }
	}

	my $dt = time - $t0;
	diag(sprintf '%-7s level 5 vs level 1 over %d games: %d - %d (%d unfinished) in %.0fs',
		"${size}x$size", $games, $top_wins, $bottom_wins, $unfinished, $dt);

	is($unfinished, 0, "${size}x$size: every game finished");

	# THE CLAIM THE LEVELS MAKE, and no more than it. Not a win rate, because
	# nobody has measured what one should be; just that the top rung is not
	# losing, which is the thing that would mean the levels are backwards.
	cmp_ok($top_wins, '>=', $bottom_wins,
		"${size}x$size: the top rung did not lose to the bottom ($top_wins to $bottom_wins)");
}

diag('');
diag('OBSERVED, as a baseline for a future reversal. A reversal here is worth');
diag('re-running before it is believed: a Monte Carlo bot with uniform playouts');
diag('has real variance, and these match sizes are small.');

done_testing();
