#!perl

# Handicap stones and the komi that goes with them.
#
# NEITHER IS IN THE RULES OF GO. The Japanese rules of 1989 have thirteen
# articles and mention neither komi nor handicap. Sensei's Library says so of
# the placement outright, quoting Andrew Grant: "It is a fallacy that Japanese
# rules do not allow free handicap placement. In fact the official Japanese
# rules say nothing at all about handicap placement. It's true that the fixed
# pattern is universally used in Japan, but this is just a tradition, nothing
# more."
#
# So everything here is convention, and this file is careful about which parts
# are cited and which are ours:
#
#   CITED   the 19x19 star points, and which of them each handicap from 1 to 9
#           uses. Wikipedia's "Handicapping in Go", whose table references
#           Iwamoto Kaoru, "Go for Beginners", Pantheon 1977, pp. 109-114.
#   CITED   that 13x13 and 9x9 have only FIVE star points (Sensei's Library),
#           which is why nine stones cannot be placed on them.
#   OURS    where those five points are, and that a small-board handicap runs
#           2 to 5 in the same order as the big board's.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Rules;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'an even game gives nothing away' => sub {
	my $g = Game::Go->new(size => 19);
	is($g->handicap, 0, 'no handicap');
	is($g->komi, 6.5, 'the ordinary komi');
	is($g->turn, $B, 'and black moves first, which is Article 2');
	is($g->board->stones($B), 0, 'with nothing on the board');
	done_testing();
};

subtest 'a handicap of one places no stones at all' => sub {
	# The cited table's first row: "1 | Black plays their first stone as they
	# wish, and give no komi | None". So the whole of a one-stone handicap is
	# the komi, and black still moves first.
	my $g = Game::Go->new(size => 19, handicap => 1);
	is($g->handicap, 1, 'a handicap of one');
	is($g->board->stones($B), 0, 'places nothing');
	is($g->turn, $B, 'and black still moves first');
	is($g->komi, 0.5, 'but the komi is 0.5');

	my @kinds = map { $_->{kind} } @{ $g->events };
	is(scalar(grep { $_ eq 'handicap' } @kinds), 0, 'with no handicap events in the log');
	done_testing();
};

subtest 'two stones, and WHITE is left to play' => sub {
	# Sensei's Library: "In all cases the weaker player plays Black, and there
	# is no komi (or it is just 0.5, to prevent a draw). AFTER HANDICAP STONES
	# HAVE BEEN PLACED, IT IS WHITE'S TURN TO PLAY."
	#
	# Leaving the turn with black is the obvious mistake, and it hands black
	# one more free move than the handicap says it gets.
	my $g = Game::Go->new(size => 19, handicap => 2);
	is($g->board->stones($B), 2, 'two black stones');
	is($g->board->stones($W), 0, 'and none for white');
	is($g->turn, $W, 'WHITE is to play');
	is($g->komi, 0.5, 'at a komi of 0.5');
	is_deeply([ $g->waiting_on ], [ $W ], 'and white is who the game is waiting on');

	# "Black plays the star points to their upper right and lower left":
	# 0-indexed on a 19x19 those are (15,3) and (3,15).
	is($g->board->at(15, 3), $B, 'a stone on the upper right star point');
	is($g->board->at(3, 15), $B, 'and one on the lower left');
	is($g->board->at(3, 3), Game::Go::EMPTY, 'the upper left is empty');
	is($g->board->at(15, 15), Game::Go::EMPTY, 'and so is the lower right');
	done_testing();
};

subtest 'the cited placements, one handicap at a time' => sub {
	# Straight from the table. Each row names the points in the labels the
	# table uses, and the count is what this asserts; the three and six rows
	# are the ones that were actually in doubt.
	my %want = (
		2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7, 8 => 8, 9 => 9,
	);

	for my $n (sort { $a <=> $b } keys %want) {
		my $g = Game::Go->new(size => 19, handicap => $n);
		is($g->board->stones($B), $want{$n}, "handicap $n places $want{$n} stones");
		is($g->turn, $W, "handicap $n leaves white to play");

		my $events = [ grep { $_->{kind} eq 'handicap' } @{ $g->events } ];
		is(scalar @$events, $want{$n}, "handicap $n logs $want{$n} events");
	}

	# THREE STONES LEAVES OUT THE UPPER LEFT. "3 | Black adds the star point to
	# their lower right | A,B,C", and A, B and C are upper right, lower left
	# and lower right. This was the thing the plan could not settle from the
	# diagrams and it is settled here.
	my $three = Game::Go->new(size => 19, handicap => 3);
	is($three->board->at(15, 3), $B, 'three: upper right');
	is($three->board->at(3, 15), $B, 'three: lower left');
	is($three->board->at(15, 15), $B, 'three: lower right');
	is($three->board->at(3, 3), Game::Go::EMPTY, 'three: and the UPPER LEFT is the one left out');

	# SIX USES THE LEFT AND RIGHT SIDES, NOT THE TOP AND BOTTOM. "6 | Black
	# takes all three star points at left and right | A,B,C,D,F,G".
	my $six = Game::Go->new(size => 19, handicap => 6);
	is($six->board->at(3, 9), $B, 'six: the left side star');
	is($six->board->at(15, 9), $B, 'six: the right side star');
	is($six->board->at(9, 3), Game::Go::EMPTY, 'six: the top side star is NOT used');
	is($six->board->at(9, 15), Game::Go::EMPTY, 'six: nor the bottom');
	is($six->board->at(9, 9), Game::Go::EMPTY, 'six: nor tengen');

	# SEVEN ADDS THE CENTRE. "7 | Black adds the center star point".
	my $seven = Game::Go->new(size => 19, handicap => 7);
	is($seven->board->at(9, 9), $B, 'seven: tengen');

	# EIGHT IS EVERYTHING BUT THE CENTRE.
	my $eight = Game::Go->new(size => 19, handicap => 8);
	is($eight->board->at(9, 9), Game::Go::EMPTY, 'eight: everything except tengen');
	is($eight->board->at(9, 3), $B, 'eight: including the top side');

	# NINE IS ALL OF THEM, so every star point holds a stone.
	my $nine = Game::Go->new(size => 19, handicap => 9);
	my $missing = grep { $nine->board->at(@$_) != $B }
		@{ Game::Go::Rules::star_points(19) };
	is($missing, 0, 'nine: every one of the nine star points has a stone on it');
	done_testing();
};

subtest 'a small board cannot take nine stones, because it has five points' => sub {
	# Sensei's Library: "A 13x13 board has only five star points", and "A 9x9
	# board also has only five star points. However, some leave out that in the
	# center, some those in the corners."
	#
	# So the cap is a property of the BOARD and not one number. There is no
	# cited convention for these at all, and this refuses rather than inventing
	# four more points to put stones on.
	for my $size (9, 13) {
		is(Game::Go::Rules::max_handicap($size), 5, "${size}x$size takes at most five");

		my $g = Game::Go->new(size => $size, handicap => 5);
		is($g->board->stones($B), 5, "${size}x$size: five stones go on");
		is($g->turn, $W, "${size}x$size: and white plays");

		for my $too_many (6, 7, 9) {
			ok(!eval { Game::Go->new(size => $size, handicap => $too_many); 1 },
				"${size}x$size: a handicap of $too_many is refused");
			like($@, qr/0 to 5/, "${size}x$size: saying what the board can take");
		}
	}

	is(Game::Go::Rules::max_handicap(19), 9, '19x19 takes nine');
	ok(!eval { Game::Go->new(size => 19, handicap => 10); 1 }, 'and not ten');
	ok(!eval { Game::Go->new(size => 19, handicap => -1); 1 }, 'nor a negative one');
	done_testing();
};

subtest 'a handicap stone is not a move' => sub {
	my $g = Game::Go->new(size => 19, handicap => 4);

	# ITS OWN EVENT KIND, and not a `play`. Three reasons: the log can say
	# "black takes four handicap stones" rather than narrating four moves
	# nobody made; Article 10.2's prisoner arithmetic is untouched, because a
	# handicap stone was never captured and was never a move; and a replay can
	# check the stones landed where this board would have put them, which a
	# `play` event would make indistinguishable from black opening on a star
	# point.
	my @handicap = grep { $_->{kind} eq 'handicap' } @{ $g->events };
	is(scalar @handicap, 4, 'four handicap events');
	is(scalar(grep { $_->{kind} eq 'play' } @{ $g->events }), 0, 'and not one play');
	is($handicap[0]{actor}, 'b', 'logged as black');

	is($g->prisoners->{$B}, 0, 'nobody has taken a prisoner');
	is($g->prisoners->{$W}, 0, '...');

	# No ko is created by placing them. They are put on the board rather than
	# played, so nothing about them is subject to Article 6.
	is($g->ko_point, -1, 'and no ko exists');
	done_testing();
};

subtest 'a handicap game replays, and a forged stone does not' => sub {
	my $g = Game::Go->new(size => 19, handicap => 5);
	$g->play($W, $g->point(10, 10));
	$g->play($B, $g->point(11, 11));

	my $r = Game::Go->new(size => 19, handicap => 5);
	my $n = eval { $r->replay($g->events) };
	ok(!$@, 'a handicap game replays') or diag $@;
	is($n, scalar @{ $g->events }, 'every event seen');
	is($r->board->to_text, $g->board->to_text, 'to the same position');
	is($r->turn, $g->turn, 'the same turn');
	is($r->komi, $g->komi, 'and the same komi');

	# THE STONES ARE COMPARED, NOT RE-APPLIED. They go on in the constructor
	# from the size and the handicap, so a replay has already placed them
	# before it sees the log; applying them again would double them.
	is($r->board->stones($B), 6, 'five handicap stones and one played, not ten');

	# Which means a log claiming stones on points this board would not use is
	# refused, the same treatment every other derivable event gets.
	my $lie = $g->events;
	for my $e (@$lie) {
		next unless $e->{kind} eq 'handicap';
		$e->{payload}{pt} = $g->point(0, 0);
		last;
	}
	ok(!eval { Game::Go->new(size => 19, handicap => 5)->replay($lie); 1 },
		'a forged handicap point is refused');
	like($@, qr/wrong point/, 'saying so');

	# And a log with more handicap stones than the board places.
	my $extra = $g->events;
	splice @$extra, 1, 0, { actor => 'b', kind => 'handicap', payload => { pt => $g->point(0, 0) } };
	ok(!eval { Game::Go->new(size => 19, handicap => 5)->replay($extra); 1 },
		'and one with a stone too many');
	done_testing();
};

subtest 'the komi a handicap brings with it' => sub {
	# Sensei's: "there is no komi (or it is just 0.5, to prevent a draw)". The
	# half point is doing ONE job there and it is not compensation: it is what
	# stops a jigo, which Article 10.2 would otherwise permit.
	for my $n (1 .. 9) {
		my $g = Game::Go->new(size => 19, handicap => $n);
		is($g->komi, 0.5, "handicap $n takes komi 0.5");
	}
	is(Game::Go::Rules::HANDICAP_KOMI, 0.5, 'and it is one constant');

	# An explicit komi still wins, because a tournament may say otherwise and
	# the engine is not the place to argue with it.
	my $g = Game::Go->new(size => 19, handicap => 4, komi => 6.5);
	is($g->komi, 6.5, 'an explicit komi is not overridden');
	done_testing();
};

subtest 'free placement is a documented non-feature' => sub {
	# Wikipedia: "Some rulesets allow for free placement of handicap stones,
	# rather than the fixed star point locations. In free placement, one can
	# place handicap stones anywhere on the board without restriction ... For
	# example, Ing rules allow free placement."
	#
	# Not implemented. There is no constructor option for it and no way to ask,
	# which is the honest state: a half-supported variant is worse than a named
	# absent one.
	my $g = Game::Go->new(size => 19, handicap => 4);
	my @on = grep { $g->board->at(@$_) == $B } @{ Game::Go::Rules::star_points(19) };
	is(scalar @on, 4, 'every handicap stone is on a star point, always');
	done_testing();
};

done_testing();
