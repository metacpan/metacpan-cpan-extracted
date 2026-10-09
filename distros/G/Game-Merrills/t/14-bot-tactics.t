#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Points;
use Game::Merrills::Test::Position qw/p position_of/;

# Every tactic is asked of the LOWEST level meant to find it, and of each
# level above that up to 3, with several seeds where the seed is live. A
# tactic found only by a deep look proves nothing about the shallow ones.

sub bots {
	my (@levels) = @_;
	return map {
		my $level = $_;
		map { Game::Merrills::Bot->new(level => $level, seed => $_) }
			$level < 3 ? (1, 2, 3, 4, 5, 6) : (0);
	} @levels;
}

sub named { return 'level ' . $_[0]->level . ' seed ' . $_[0]->seed }

subtest 'it closes a mill when it can' => sub {
	# 7  W-----------W-----------.      white g4 steps up to g7
	# 4  .---B---.       .---.---W
	# 3  |   |   W---.---W   |   |
	# 1  B-----------B-----------.
	my $moving = position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 b4 e5 f2/],
	);
	# placing: black sits on d6 and a4, so no other white man makes a second
	# threat and the only way to win a man is to take it now
	my $placing = position_of(
		white => [qw/a7 d7/], black => [qw/d6 a4/], hand => { white => 7, black => 7 },
	);
	for my $bot (bots(1, 2, 3)) {
		my $move = $bot->choose(Game::Merrills->new(position => $moving));
		ok($move->is_capture && $move->to == p('g7'), named($bot) . ' moving: ' . $move->notation);
		my $placed = $bot->choose(Game::Merrills->new(position => $placing));
		ok($placed->is_capture && $placed->to == p('g7'), named($bot) . ' placing: ' . $placed->notation);
	}
};

subtest 'it stands in the way of a mill about to be closed' => sub {
	# black has a1 and d1 and a man in hand: g1 closes the row. White has one
	# man down, so it has no threat of its own to answer with.
	my $position = position_of(
		white => [qw/d6/], black => [qw/a1 d1/], hand => { white => 8, black => 7 },
	);
	for my $bot (bots(1, 2, 3)) {
		my $move = $bot->choose(Game::Merrills->new(position => $position));
		is($move->notation, 'g1', named($bot) . ' places on g1');
	}
};

subtest 'with three men left, it flies to stand in the way' => sub {
	# black a1 d1, and g4 ready to step down to g1. White has three men and
	# would be left with two. No two white men share a row, so there is no
	# mill to fly into instead: only a flight to g1 saves the game.
	my $position = position_of(
		white => [qw/b6 e3 c5/], black => [qw/a1 d1 g4 e5/],
	);
	for my $bot (bots(1, 2, 3)) {
		my $game = Game::Merrills->new(position => $position);
		is($game->phase, 'flying', 'white is flying') if $bot->seed < 2;
		my $move = $bot->choose($game);
		is($move->to, p('g1'), named($bot) . ' flies to g1: ' . $move->notation);
		ok($move->flew, 'and it is a flight');
	}
};

subtest 'closing a mill, it takes a man from the row that threatens it' => sub {
	# black b2 and d2 with f4 ready to step to f2. White closes the top row
	# and may take any of five men: b2, d2 or f4 ends the threat, e5 or a4
	# does not.
	my $position = position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/b2 d2 f4 e5 a4/],
	);
	my %ends_threat = map { p($_) => 1 } qw/b2 d2 f4/;
	for my $bot (bots(1, 2, 3)) {
		my $move = $bot->choose(Game::Merrills->new(position => $position));
		ok($move->is_capture && $ends_threat{ $move->remove }, named($bot) . ' plays ' . $move->notation);
	}
};

subtest 'it works a running mill: a man stepping between two rows, taking each time' => sub {
	# white b6 d6 f6 is a mill, and a7 g7 wait for d7. The man on d6 steps to
	# d7 and back, closing a mill every move, and black cannot reach d7 while
	# it has more than three men. Two turns: after that black is near flying
	# and the best play is no longer the plain shuttle.
	my $position = position_of(
		white => [qw/a7 g7 b6 d6 f6/], black => [qw/a1 d1 c3 e3 b2 f2 g4/],
	);
	for my $bot (bots(2, 3)) {
		my $game = Game::Merrills->new(position => $position);
		my @white;
		for my $turn (1 .. 2) {
			my $move = $bot->choose($game);
			push @white, $move->notation;
			$game->move($move);
			last unless $game->status eq 'active';
			my ($reply) = grep { !$_->is_capture } @{ $game->legal_moves };
			$game->move($reply);
		}
		is(scalar(grep { m/^d[67]-d[67]x/ } @white), scalar @white,
			named($bot) . ": every move is the shuttle with a capture: @white");
		is($game->on_board('black'), 7 - @white, 'and black has lost a man a move');
	}
};

subtest 'it takes a win in one over a mere capture' => sub {
	# black has three men. Either closing move takes one and wins; nothing
	# else does.
	my $position = position_of(
		white => [qw/a7 d7 g4 c3 e3/], black => [qw/b2 d2 e5/],
	);
	for my $bot (bots(1, 2, 3)) {
		my $game = Game::Merrills->new(position => $position);
		$game->move($bot->choose($game));
		is($game->status, 'finished', named($bot) . ' ends the game');
		is($game->result->winner, 'white', 'and wins it');
	}
};

done_testing;
