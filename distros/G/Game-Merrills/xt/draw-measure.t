#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills;
use Game::Merrills::Rules;

unless ($ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

# HOW LONG CAN A GAME GO WITHOUT A MILL AND STILL BE GOING SOMEWHERE?
#
# NO_MILL_PLIES draws a game after that many moves with no mill closed. Set it
# too low and it ends games that were about to be won; too high and a shuffle
# lasts for ever. This file measures, with the limit switched off, the longest
# mill-free stretch in games that ended by themselves, and holds the constant
# above it.
#
# Two players, neither of them the dist's bot, which is tuned against the
# limit and so cannot be the instrument that sets it:
#
#   random   any legal move
#   greedy   close a mill if one can be closed, else stand where the enemy
#            would close one, else any legal move
#
# Repetition stays on, as it is a rule of the game and not the thing measured.
# A game still going after CAP plies is stopped and counted, never dropped.

use constant GAMES => $ENV{MERRILLS_DRAW_GAMES} || 2000;
use constant CAP => 2000;

sub stream {
	my ($seed) = @_;
	return sub {
		my ($count) = @_;
		$seed = ($seed * 1103515245 + 12345) % 2147483648;
		return int($seed / 65536) % $count;
	};
}

sub random_move {
	my ($game, $next) = @_;
	my $legal = $game->legal_moves;
	return $legal->[ $next->(scalar @{$legal}) ];
}

sub greedy_move {
	my ($game, $next) = @_;
	my $legal = $game->legal_moves;
	my @closing = grep { $_->is_capture } @{$legal};
	return $closing[ $next->(scalar @closing) ] if @closing;

	my $enemy = $game->turn eq 'white' ? 'black' : 'white';
	my $position = Game::Merrills::Rules::position($game->board);
	my %threat = map { $_ => 1 }
		grep { !$position->[$_] && Game::Merrills::Rules::closes($position, $enemy, undef, $_) }
		0 .. 23;
	my @blocking = grep { $threat{ $_->to } } @{$legal};
	return $blocking[ $next->(scalar @blocking) ] if @blocking;
	return $legal->[ $next->(scalar @{$legal}) ];
}

sub play {
	my ($chooser, $seed, $games) = @_;
	my $next = stream($seed);
	my (%ended, @natural, @all, @plies);
	for (1 .. $games) {
		my $game = Game::Merrills->new;
		my $longest = 0;
		while ($game->status eq 'active' && $game->ply < CAP) {
			$game->move($chooser->($game, $next));
			$longest = $game->no_mill if $game->no_mill > $longest;
		}
		my $reason = $game->result ? $game->result->reason : 'capped';
		$ended{$reason}++;
		push @all, $longest;
		push @natural, $longest if $reason eq 'few' || $reason eq 'blocked';
		push @plies, $game->ply;
	}
	return { ended => \%ended, natural => \@natural, all => \@all, plies => \@plies, games => $games };
}

sub percentile {
	my ($values, $percent) = @_;
	my @sorted = sort { $a <=> $b } @{$values};
	return 0 unless @sorted;
	my $index = int(($percent / 100) * @sorted + 0.999999) - 1;
	$index = 0 if $index < 0;
	$index = $#sorted if $index > $#sorted;
	return $sorted[$index];
}

sub report {
	my ($name, $run) = @_;
	my $games = $run->{games};
	diag sprintf '%s, %d games, the no-mill limit off', $name, $games;
	diag sprintf '  ended by: %s', join ', ',
		map { sprintf '%s %d (%.1f%%)', $_, $run->{ended}{$_}, 100 * $run->{ended}{$_} / $games }
		sort keys %{ $run->{ended} };
	diag sprintf '  plies: median %d, p95 %d, longest %d',
		percentile($run->{plies}, 50), percentile($run->{plies}, 95), percentile($run->{plies}, 100);
	diag sprintf '  longest mill-free stretch in a game that ended by few or blocked (%d games):',
		scalar @{ $run->{natural} };
	diag sprintf '    median %d, p95 %d, p99 %d, longest %d',
		map { percentile($run->{natural}, $_) } 50, 95, 99, 100;
	for my $limit (20, 30, 40, 50, 60, 80, 100, 150, 200) {
		my $cut_short = grep { $_ >= $limit } @{ $run->{natural} };
		my $ended = grep { $_ >= $limit } @{ $run->{all} };
		diag sprintf '    a limit of %3d would end %5.1f%% of all games, and %5.2f%% of the natural ones early',
			$limit, 100 * $ended / $games,
			@{ $run->{natural} } ? 100 * $cut_short / @{ $run->{natural} } : 0;
	}
	return;
}

my $limit = Game::Merrills::NO_MILL_PLIES;
my ($random, $greedy);

{
	local $Game::Merrills::NO_MILL_LIMIT = 0;
	$random = play(\&random_move, 404, GAMES);
	$greedy = play(\&greedy_move, 405, GAMES);
}

report('random', $random);
report('greedy', $greedy);

subtest 'the measurement measured something' => sub {
	for my $run ([ random => $random ], [ greedy => $greedy ]) {
		my ($name, $got) = @{$run};
		is($got->{ended}{no_mill} || 0, 0, "$name: with the limit off, no game ended on it");
		cmp_ok(scalar @{ $got->{natural} }, '>', GAMES / 4,
			"$name: " . scalar @{ $got->{natural} } . ' games ended by themselves');
	}
};

subtest 'the limit ships above the longest stretch a natural game needs' => sub {
	my $need = percentile($greedy->{natural}, 99);
	cmp_ok($limit, '>', $need,
		"NO_MILL_PLIES is $limit; ninety-nine in a hundred greedy games that ended by themselves needed no more than $need");
	my $cut_short = grep { $_ >= $limit } @{ $greedy->{natural} };
	cmp_ok($cut_short / @{ $greedy->{natural} }, '<', 0.01,
		"and it would have cut short $cut_short of them");
};

subtest 'and the instrument can fail: at a limit of 4 most games end on it' => sub {
	local $Game::Merrills::NO_MILL_LIMIT = 4;
	my $short = play(\&greedy_move, 405, 200);
	cmp_ok($short->{ended}{no_mill} || 0, '>', 100,
		($short->{ended}{no_mill} || 0) . ' of 200 games ended on a limit of 4');
};

done_testing;
