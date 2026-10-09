#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;

unless ($ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

# THE LADDER: DOES EACH LEVEL BEAT THE ONE BELOW IT?
#
# Two bots that never guess play one game however often they are asked, so
# every game here is made different on purpose:
#
#   - game i of a pairing starts from opening int(i / 2): four placements
#     drawn from a fixed stream, the same four for both games of the pair;
#   - the two games of a pair swap colours;
#   - each bot's seed is the game's number, which matters at levels 1 and 2.
#
# A win scores 1, a draw a half. The score printed is the HIGHER level's.
#
# Level 0 is not a level of the dist. It plays the first legal move, and is
# here so that the harness can be checked: if 3v0 does not come out near 100%
# the table has its sides the wrong way round.
#
#   MERRILLS_LADDER        pairings, "3v2,2v1" (default: 1v0,2v1,3v2)
#   MERRILLS_LADDER_GAMES  games a pairing (default 20)
#   MERRILLS_LADDER_FROM   number of the first game (default 0), so that a
#                          long run can be split across several processes
#   MERRILLS_LADDER_ZERO   a weight of the higher bot's to set to nought,
#                          "RUNNING": the ablation
#   MERRILLS_LADDER_LIMIT  the no-mill limit for the run, 0 for none
#   MERRILLS_LADDER_BAR    the share a level must score to stay (default 0.6)
#
# Every game prints a line, "GAME high low number score plies reason quiet",
# so that runs split across processes can be added up afterwards.

my @PAIRINGS = map { [ split /v/ ] } split /,/, $ENV{MERRILLS_LADDER} || '1v0,2v1,3v2';
my $GAMES = $ENV{MERRILLS_LADDER_GAMES} || 20;
my $FROM = $ENV{MERRILLS_LADDER_FROM} || 0;
my $ZERO = $ENV{MERRILLS_LADDER_ZERO};
my $BAR = $ENV{MERRILLS_LADDER_BAR} || 0.6;

sub stream {
	my ($seed) = @_;
	return sub {
		my ($count) = @_;
		$seed = ($seed * 1103515245 + 12345) % 2147483648;
		return int($seed / 65536) % $count;
	};
}

sub chooser {
	my ($level, $seed, $zero) = @_;
	return sub { $_[0]->legal_moves->[0] } unless $level;
	my $bot = Game::Merrills::Bot->new(level => $level, seed => $seed);
	return sub { $bot->choose($_[0]) } unless $zero;
	return sub {
		no strict 'refs';
		local ${"Game::Merrills::Bot::$zero"} = 0;
		return $bot->choose($_[0]);
	};
}

sub game {
	my ($high, $low, $number) = @_;
	my $next = stream(9000 + int($number / 2));
	my $game = Game::Merrills->new;
	for (1 .. 4) {
		my $legal = $game->legal_moves;
		$game->move($legal->[ $next->(scalar @{$legal}) ]);
	}
	my $high_side = $number % 2 ? 'black' : 'white';
	my %choose = (
		$high_side => chooser($high, $number, $ZERO),
		($high_side eq 'white' ? 'black' : 'white') => chooser($low, $number + 5000),
	);
	my $quiet = 0;
	while ($game->status eq 'active' && $game->ply < 3000) {
		$game->move($choose{ $game->turn }->($game));
		$quiet = $game->no_mill if $game->no_mill > $quiet;
	}
	my $result = $game->result;
	my $score = !$result ? 0.5
		: $result->is_draw ? 0.5
		: $result->winner eq $high_side ? 1 : 0;
	return ($score, $game->ply, $result ? $result->reason : 'capped', $quiet);
}

local $Game::Merrills::NO_MILL_LIMIT = $ENV{MERRILLS_LADDER_LIMIT}
	if defined $ENV{MERRILLS_LADDER_LIMIT};

{
	no strict 'refs';
	die "there is no weight called $ZERO\n"
		if $ZERO && !defined ${"Game::Merrills::Bot::$ZERO"};
}

for my $pairing (@PAIRINGS) {
	my ($high, $low) = @{$pairing};
	my ($total, %reason, $wins, $draws) = (0);
	for my $number ($FROM .. $FROM + $GAMES - 1) {
		my ($score, $plies, $reason, $quiet) = game($high, $low, $number);
		diag join ' ', 'GAME', $high, $low, $number, $score, $plies, $reason, $quiet;
		$total += $score;
		$reason{$reason}++;
		$wins++ if $score == 1;
		$draws++ if $score == 0.5;
	}
	my $share = $total / $GAMES;
	diag sprintf 'level %d v level %d%s: %.1f of %d (%.1f%%), %d won %d drawn; ended by %s',
		$high, $low, $ZERO ? " without $ZERO" : '', $total, $GAMES, 100 * $share,
		$wins || 0, $draws || 0, join ', ', map { "$_ $reason{$_}" } sort keys %reason;
	next if $ZERO || $high == $low;
	cmp_ok($share, '>=', $BAR, sprintf 'level %d scores %.1f%% against level %d', $high, 100 * $share, $low);
}

pass('the ladder ran');
done_testing;
