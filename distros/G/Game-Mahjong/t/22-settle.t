#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub sum { my $s = 0; $s += $_ for @_; return $s }

plan tests => 6;

subtest 'the constants' => sub {
	is(Game::Mahjong::Result::BASE, 8, 'eight from every loser (3.9.1.2)');
	is(Game::Mahjong::Result::SEATS, 4, 'four seats');
	is(Game::Mahjong::Result::HANDS, 16, 'sixteen hands');
	is(Game::Mahjong::Result::ROUNDS, 4, 'four rounds');
	is(Game::Mahjong::Score::MINIMUM, 8, 'eight to win');
};

# 3.9.1.3: "Win by self-drawn: Extra Points + Basic Points, then multiply x3
# (each player pays Extra Points + Basic Points to the winner)". A 16-point
# hand: each of three gives 8 + 16 = 24, the winner takes 72.
subtest 'a self-drawn win' => sub {
	my $d = Game::Mahjong::Result::settle(winner => 2, by => 'self', points => 16);
	is_deeply($d, [ -24, -24, 72, -24 ], 'seat 2 takes 72, the others give 24 each');
	is(sum(@$d), 0, 'zero-sum');
};

# "Win by discard: Extra Points x3 + Basic Points x1 (Discarder pays winner
# Basic Points + Extra Points, and the other two players pay the winner Extra
# Points only)". A 16-point hand off seat 0: seat 0 gives 24, the others 8,
# the winner takes 40.
subtest 'a win by discard' => sub {
	my $d = Game::Mahjong::Result::settle(winner => 2, by => 'discard', from => 0, points => 16);
	is_deeply($d, [ -24, -8, 40, -8 ], 'the discarder gives 24, the other two 8, the winner takes 40');
	is(sum(@$d), 0, 'zero-sum');
	my $r = Game::Mahjong::Result::settle(winner => 1, by => 'rob', from => 3, points => 88);
	is_deeply($r, [ -8, 112, -8, -96 ], 'robbing the kong: the seat that promoted it is the discarder');
	is(sum(@$r), 0, 'zero-sum');
};

subtest 'a drawn hand moves nothing' => sub {
	is_deeply(Game::Mahjong::Result::settle(by => 'exhausted'), [ 0, 0, 0, 0 ], 'four zeros');
};

subtest 'what settle refuses' => sub {
	ok(!eval { Game::Mahjong::Result::settle(winner => 4, by => 'self', points => 8); 1 }, 'seat 4');
	ok(!eval { Game::Mahjong::Result::settle(winner => 0, by => 'discard', points => 8); 1 }, 'a discard with no discarder');
	ok(!eval { Game::Mahjong::Result::settle(winner => 0, by => 'discard', from => 0, points => 8); 1 }, 'the winner as the discarder');
	ok(!eval { Game::Mahjong::Result::settle(winner => 0, by => 'self', points => -1); 1 }, 'negative points');
	ok(!eval { Game::Mahjong::Result::settle(winner => 0, by => 'bogus', points => 8); 1 }, 'a way to win it does not know');
};

subtest 'the standings' => sub {
	is_deeply(Game::Mahjong::Result::places([ 40, -10, 40, -70 ]), [ 1, 3, 1, 4 ], 'a shared first, the next place skipped');
	is(Game::Mahjong::Result::winner([ 40, -10, 40, -70 ]), undef, 'a shared first is nobody');
	is(Game::Mahjong::Result::winner([ 50, -10, 40, -80 ]), 0, 'a sole first');
	is_deeply(Game::Mahjong::Result::places([ 0, 0, 0, 0 ]), [ 1, 1, 1, 1 ], 'all level');
	# totals that went negative, as sixteen hands of zero-sum settlement can leave them
	my @totals = (0) x 4;
	for my $h (1 .. 16) {
		my $d = Game::Mahjong::Result::settle(winner => $h % 4, by => 'discard', from => ($h + 1) % 4, points => 8 + $h);
		$totals[$_] += $d->[$_] for 0 .. 3;
	}
	is(sum(@totals), 0, 'sixteen hands still sum to zero');
	ok((grep { $_ < 0 } @totals), 'and somebody is below zero');
	ok(!Game::Mahjong::Result::finished(15), 'fifteen hands is not finished');
	ok(Game::Mahjong::Result::finished(16), 'sixteen is');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   BASE 10                                 -> 'seat 2 takes 72' fails
#   the discarder gives BASE only           -> 'the discarder gives 24' fails
#   count flowers before the minimum        -> t/21 'a flower does not count toward the eight' fails
