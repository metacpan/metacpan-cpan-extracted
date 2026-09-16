#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;

# The calibration ladder. A bot that is not measured is not a bot, it is a
# heuristic somebody hopes about.
#
# Game::Checkers found, only because it ran this, that its jitter was making
# the bot WORSE the deeper it searched: level 2 lost to level 1 by 0 games to
# 13. Nothing else in that suite would have noticed, because every move was
# legal and every game finished.
#
# Reported as a WIN COUNT and never as a percentage. A percentage on twenty
# games is noise wearing a decimal point.
#
# In xt/ because it plays hundreds of hands and takes a couple of minutes. It
# does not run on a smoker.

plan tests => 3;

# Play one game between two bots and return the winning seat, or undef when
# the game did not finish inside the ply cap.
sub duel {
	my (%args) = @_;
	my $game = Game::Dominoes->new(
		seed => sprintf('%032d', $args{seed}),
		players => 2,
		# A short target: the ladder is about who plays better, not about
		# sitting through eleven hands to find out.
		target => 100,
	);

	my %bot = (
		1 => Game::Dominoes::Bot->new(level => $args{one}, seed => $args{seed} * 2),
		2 => Game::Dominoes::Bot->new(level => $args{two}, seed => $args{seed} * 3),
	);

	my $plies = 0;
	while ($game->status eq 'active' && $plies++ < 4000) {
		my $seat = $game->turn;
		my $move = $bot{$seat}->choose($game, $seat) or last;
		my $out = $game->play($seat, $move);
		die $out->stringify if ref $out eq 'Game::Dominoes::Error';
	}

	return undef unless $game->result;
	return $game->result->winner;
}

# Play $n games with the seats swapped halfway, so that neither level gets the
# lead in more than half of them. Returns wins for the first level.
sub ladder {
	my ($strong, $weak, $n) = @_;
	my ($strong_wins, $weak_wins, $drawn) = (0, 0, 0);

	for my $i (1 .. $n) {
		my $swap = $i % 2 == 0;
		my $winner = duel(
			seed => $i,
			one => $swap ? $weak : $strong,
			two => $swap ? $strong : $weak,
		);
		if (!defined $winner) { $drawn++ }
		elsif (($winner == 1) xor $swap) { $strong_wins++ }
		else { $weak_wins++ }
	}

	return ($strong_wins, $weak_wins, $drawn);
}

subtest 'level 2 beats level 1' => sub {
	plan tests => 2;

	my ($strong, $weak, $drawn) = ladder(2, 1, 60);
	diag("level 2: $strong wins, level 1: $weak wins, $drawn unfinished");

	is $drawn, 0, 'every game finished';
	cmp_ok $strong, '>', $weak,
		"level 2 won $strong to $weak, so the shape term is worth something";
};

subtest 'level 3 beats level 1' => sub {
	plan tests => 2;

	# If the determinised search does not beat pure greed convincingly then
	# the search is not working, and no amount of tuning the evaluation will
	# fix that. This is the control, and it is the whole reason levels 1 and
	# 2 exist.
	my ($strong, $weak, $drawn) = ladder(3, 1, 40);
	diag("level 3: $strong wins, level 1: $weak wins, $drawn unfinished");

	is $drawn, 0, 'every game finished';
	cmp_ok $strong, '>', $weak,
		"level 3 won $strong to $weak, so the search is doing work";
};

subtest 'a higher level is not WORSE, which is the failure checkers found' => sub {
	plan tests => 1;

	# Checkers' level 2 lost to its level 1 by 0 to 13 because a bound plus
	# jitter beat the true best move. The shape of that bug is "more search
	# made it worse", so the assertion is one-sided on purpose: level 3 need
	# not thrash level 2, but it must not be beaten by it.
	my ($strong, $weak, $drawn) = ladder(3, 2, 40);
	diag("level 3: $strong wins, level 2: $weak wins, $drawn unfinished");

	cmp_ok $strong, '>=', $weak,
		"level 3 won $strong to $weak, so searching more did not make it worse";
};
