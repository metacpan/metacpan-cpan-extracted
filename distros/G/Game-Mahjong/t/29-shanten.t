#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub hand { return Game::Mahjong::Hand->from_notation($_[0]) }
sub sh { return Game::Mahjong::Shanten::shanten(hand($_[0])) }
sub codes { return [ map { Game::Mahjong::Tiles::code_of($_) } @_ ] }

plan tests => 8;

# HAND VECTORS, the number computed by hand beside each: sets S, partials P,
# head H, 8 - 2S - P - H with S + P at most four.
subtest 'the standard form' => sub {
	is(sh('123m 456p 789s 111s 55m'), -1, 'a complete fourteen is -1');
	is(sh('123m 456p 789s 111s 5m'), 0, 'thirteen waiting on the pair: ready');
	is(sh('123m 456p 789s 11s 55m'), 0, 'two pairs: ready (either pungs)');
	is(sh('123m 456p 789s 11s 5m 8m'), 1, 'three sets, a pair as head, one loose: S3 P0 H1 = 1');
	is(sh('123m 456p 78s 11s 5m 8m'), 2, 'two sets, the partial 7-8, the head 11s: S2 P1 H1 = 8-4-1-1 = 2');
	# 1-2m, 8-9m and 1-3p are three partials among twelve tiles: 8-0-3-0 = 5
	is(sh('19m 19p 19s 2m 5m 8m 3p 6p 4s'), 5, 'three partials in a scatter of orphans: 5');
	# 1 2 4 5 7 8 of characters are three adjacent partials, 1 3 4 7 of dots a
	# 3-4 and a 1-3 gap: five partials capped at four with no set, 8-0-4-0 = 4;
	# the knitted reading (2-5-8m, 1-4-7p, nothing in bamboo) is 13-6 = 7
	is(sh('1m 4m 7m 1p 4p 7p 1s 4s 7s 2m 5m 8m 3p'), 4, 'five partials capped at four: 4');
	is(sh('123m 456p 789s 111s 55m pung(EEE)') , -1, 'with a meld the concealed count is eleven and complete') if 0;
	is(sh('123m 456p 789s 55m pung(EEE)'), -1, 'a meld and eleven concealed: complete');
	is(sh('123m 456p 789s 5m pung(EEE)'), 0, 'ten concealed and a meld: ready');
	is(sh('123m 456p 78s 5m pung(EEE)'), 1, 'S3 (one melded) P1 H0: 8-6-1 = 1');
};

subtest 'the special forms' => sub {
	is(sh('11p 33p 55p 77p 99p EE S'), 0, 'seven pairs less one: ready');
	is(sh('11p 33p 55p 77p 99p E S'), 1, 'six pairs... five pairs and two singles: 6-5 = 1');
	is(sh('11p 33p 55p 77p 9p E S N'), 2, 'four pairs and four singles: 6-4 = 2');
	is(sh('19m 19p 19s ESWN RGB'), 0, 'thirteen orphans with no pair: ready');
	is(sh('19m 19p 19s ESWN RG 5m'), 1, 'twelve orphans and a five: 13-12-0 = 1');
	is(sh('19m 19p 19s ESWN RG B B'), -1, 'the thirteen with a pair: complete');
	is(sh('147m 258p 369s ESWN R'), -1, 'lesser honours and knitted: complete');
	is(sh('147m 258p 369s ESW N 5m'), 0, 'thirteen usable singles: ready') if 0;
	is(sh('147m 258p 369s ESWN'), 0, 'thirteen usable singles: ready');
	is(sh('147m 258p 36s ESWN 5m'), 1, 'twelve usable: one away');
	my $f = Game::Mahjong::Shanten::forms(hand('19m 19p 19s ESWN RGB'));
	is($f->{thirteen_orphans}, 0, 'forms: orphans 0');
	cmp_ok($f->{standard}, '>=', 6, 'standard far away');
	is($f->{seven_pairs}, 6, 'seven pairs: thirteen singles, 6 - 0 + 0 = 6');
	my $m = Game::Mahjong::Shanten::forms(hand('123m 456p 789s 5m pung(EEE)'));
	is($m->{seven_pairs}, 99, 'seven pairs cannot be had with a meld');
	is($m->{thirteen_orphans}, 99, 'nor thirteen orphans');
	is($m->{honours_knitted}, 99, 'nor the knitted singles');
};

subtest 'ukeire' => sub {
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('123m 456p 789s 111s 5m'))), ['m5'], 'ready on the pair: the five');
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('123m 456p 789s 11s 55m'))), [qw(m5 s1)], 'two pairs: either');
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('23m 456p 789s 111s 55m'))), [qw(m1 m4)], '2-3: the 1 or the 4');
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('13m 456p 789s 111s 55m'))), ['m2'], '1-3: the 2');
	my @u = Game::Mahjong::Shanten::ukeire(hand('123m 456p 789s 11s 5m 8m'));
	ok((grep { $_ == id('m5') } @u) && (grep { $_ == id('m8') } @u) && (grep { $_ == id('s1') } @u),
		'one away with a pair and two loose: the pair to pung, or either loose to pair');
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('5555m 678p 234s 99s 6m'))), [qw(m4 m7)], 'four fives held: never a fifth');
	is_deeply(codes(Game::Mahjong::Shanten::ukeire(hand('19m 19p 19s ESWN RGB'))), [qw(m1 m9 p1 p9 s1 s9 we ws ww wn dr dg dw)], 'thirteen orphans accept any of the thirteen');
};

subtest 'after_discard' => sub {
	my $h = hand('123m 456p 789s 111s 55m');
	is(Game::Mahjong::Shanten::after_discard($h, id('m5')), 0, 'discard a five: ready');
	is(Game::Mahjong::Shanten::after_discard($h, id('m1')), 0, 'discard the one: 2-3 a partial, three sets, the head 55: 8-6-1-1 = 0, still ready');
	ok(!eval { Game::Mahjong::Shanten::after_discard($h, id('we')); 1 }, 'a kind not held dies');
};

subtest 'the memo gives the same answer cold and warm' => sub {
	my @hands = ('123m 456p 789s 111s 5m', '11p 33p 55p 77p 99p EE S', '19m 19p 19s ESWN RG 5m', '2m 5m 8m 3p 6p 9p 1s 4s 7s EE SS W');
	my @cold = map { sh($_) } @hands;
	my @warm = map { sh($_) } @hands;
	is_deeply(\@warm, \@cold, 'the same numbers');
	my @again = map { sh($_) } reverse @hands;
	is_deeply([ reverse @again ], \@cold, 'in any order');
};

subtest 'the melds enter only in the combination' => sub {
	# ten concealed tiles with a meld: S counts the meld; the same ten
	# concealed with no meld are a different, incomplete hand
	is(sh('123m 456p 789s 5m pung(EEE)'), 0, 'ten and a meld: ready');
	is(sh('123m 456p 789s 5m'), 2, 'the same ten alone: three sets and a loose tile need a set and a head: 8-6-0-0 = 2');
	is(sh('123m 456p 5m pung(EEE) pung(SSS)'), 0, 'seven and two melds: ready');
	is(sh('5m pung(EEE) pung(SSS) pung(WWW) chow(123m)'), 0, 'one and four melds: ready on the pair');
};

subtest 'the door refuses' => sub {
	ok(!eval { Game::Mahjong::Shanten::_shanten([ (0) x 10, 5 ], 0); 1 }, 'a count of five');
	ok(!eval { Game::Mahjong::Shanten::_shanten([], 5); 1 }, 'five melds');
	is(Game::Mahjong::Shanten::_shanten([], 0), 8, 'an empty hand is eight away');
};

subtest 'the cost of one evaluation' => sub {
	my $h = hand('2m 5m 8m 3p 6p 9p 1s 4s 7s EE SS W');
	Game::Mahjong::Shanten::shanten($h);
	my $t0 = Time::HiRes::time();
	Game::Mahjong::Shanten::shanten($h) for 1 .. 1000;
	my $us = (Time::HiRes::time() - $t0) * 1e6 / 1000;
	diag sprintf 'one shanten, warm: %.1f us', $us;
	cmp_ok($us, '<', 200, 'under two hundred microseconds warm');
};
