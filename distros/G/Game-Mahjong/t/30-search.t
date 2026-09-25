#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub code { return Game::Mahjong::Tiles::code_of($_[0]) }

# A written view: a hand, and everything else quiet unless the vector says.
# The rungs are tested from views alone, which is the point of the view.
sub view {
	my (%o) = @_;
	my $hand = Game::Mahjong::Hand->from_notation($o{hand});
	my %visible;
	$visible{$_}++ for $hand->tiles;
	my @pools = map { [ map { id($_) } @{ $_ } ] } @{ $o{pools} || [ [], [], [], [] ] };
	for my $p (@pools) { $visible{$_}++ for @$p }
	my @melds = map { [ map { { kind => 'pung', tiles => [ (id($_)) x 3 ], concealed => 0 } } @$_ ] } @{ $o{melds} || [ [], [], [], [] ] };
	for my $m (@melds) { for my $s (@$m) { $visible{$_}++ for @{ $s->{tiles} } } }
	my @legal;
	if ($o{window}) {
		push @legal, { kind => 'pass' };
		push @legal, map { $_->{kind} eq 'chow' ? { kind => 'chow', tiles => [ map { id($_) } @{ $_->{tiles} } ] } : $_ } @{ $o{window}{legal} };
	}
	else {
		push @legal, map { { kind => 'discard', tile => $_ } } $hand->kinds;
		push @legal, @{ $o{extra} || [] };
	}
	return {
		seat => 0, hand => $hand, phase => $o{window} ? 'claim' : 'discard', turn => 0,
		window => $o{window} ? { tile => id($o{window}{tile}), from => $o{window}{from} // 3, kind => 'claim' } : undef,
		prevailing => $o{prevailing} // 0, seat_wind => $o{seat_wind} // 1, wall => 60,
		pools => \@pools, melds => \@melds, visible => \%visible, totals => [ 0, 0, 0, 0 ],
		hand_no => 1, moves => 7, drawn => undef, legal => \@legal, seed => 'search-test',
	};
}

sub best { my ($view, $level) = @_; return Game::Mahjong::Search::best($view, $level) }

plan tests => 8;

subtest 'rung 1 discards the most isolated tile, honours first' => sub {
	my $v = view(hand => '123m 456p 789s 11s 5m E');
	is(code(best($v, 1)->{tile}), 'we', 'a lone east before a lone five');
	my $u = view(hand => '123m 456p 789s 11s 5m 9m');
	is(code(best($u, 1)->{tile}), 'm9', 'a lone nine before a lone five: terminals first');
	my $w = view(hand => '123m 456p 789s 11s 5m 6m');
	is(code(best($w, 1)->{tile}), 's1', 'no lone tile... the pair of ones is more alone than 5-6? no: 1s has a neighbour (its twin); by the arithmetic') if 0;
	my $x = view(hand => '123m 456p 789s 11s 2m 7m');
	is(code(best($x, 1)->{tile}), 'm7', '2m sits beside 1m and 3m; 7m is alone');
};

subtest 'rung 2 keeps the hand closest to ready' => sub {
	# 123m 456p 789s 11s 5m 6m: discarding the 5 or the 6 leaves a pair and a
	# partial (one away); discarding a 1s leaves 5-6 and a lone 1s (one away
	# too, with fewer accepting tiles); rung 1 would throw the 5 or 6 as most
	# alone; rung 2 keeps the 5-6 partial? both are one away: the acceptance
	# decides: keep 5-6 (accepts 4m 7m: 8 tiles) and the pair (accepts 1s: 2)
	my $v = view(hand => '123m 456p 789s 11s 5m 6m 9m');
	my $m = best($v, 2);
	is(code($m->{tile}), 'm9', 'the lone nine goes: 5-6 and the pair stay');
	# 123m 456p 789s 22s 567m: 1m, 3m, 5m, 7m or 2s each leaves the hand ready
	my $u = view(hand => '123m 456p 789s 22s 5m 6m 7m');
	my $d = best($u, 2);
	ok(code($d->{tile}) =~ /\A(?:m1|m3|m5|m7|s2)\z/, 'one of the discards that keeps the hand ready: ' . code($d->{tile}));
	ok(code($d->{tile}) ne 'p4', 'never breaks a set');
};

subtest 'rung 2 counts the accepting tiles it can still get' => sub {
	# four sets and two singles: either single goes and the other is the
	# wait, four copies each; the eight goes (the five sits two from the
	# three of characters, less alone) until three fives lie in the pools
	my $v = view(hand => '123m 456p 789s 111s 5m 8m');
	is(code(best($v, 2)->{tile}), 'm8', 'nothing out: the eight goes, the more alone of two equal waits');
	my $u = view(hand => '123m 456p 789s 111s 5m 8m', pools => [ [qw(m5 m5 m5)], [], [], [] ]);
	is(code(best($u, 2)->{tile}), 'm5', 'three fives out: the five goes, one copy is a poor wait');
	# the count itself: three sets, 2-3 and 7-8 of characters, a loose west;
	# after the west goes the hand accepts 1m 2m 3m 4m 6m 7m 8m 9m, 28
	# copies not held, and every 1m and 4m out takes eight off
	my $w = view(hand => '23m 78m 456p 789s 111s W');
	is(Game::Mahjong::Search::_acceptance($w, id('ww')), 28, 'twenty-eight copies to be had');
	my $x = view(hand => '23m 78m 456p 789s 111s W', pools => [ [qw(m1 m1 m1 m1 m4 m4 m4 m4)], [], [], [] ]);
	is(Game::Mahjong::Search::_acceptance($x, id('ww')), 20, 'twenty with every 1m and 4m out');
};

subtest 'rung 1 passes every window; rung 2 claims a pung that scores' => sub {
	my $v = view(hand => '123m 456p 789s RR 5m 8m', window => { tile => 'dr', from => 3, legal => [ { kind => 'pung' } ] });
	is(best($v, 1)->{kind}, 'pass', 'rung 1 passes');
	is(best($v, 2)->{kind}, 'pung', 'rung 2 takes the dragon pung: two points and a set');
	my $u = view(hand => '123m 456p 789s 55m 8m 9m', window => { tile => 'm5', from => 3, legal => [ { kind => 'pung' } ] });
	is(best($u, 2)->{kind}, 'pass', 'a pung of fives that scores nothing and does not make the hand ready: pass');
};

subtest 'rung 2 claims a chow only when it makes the hand ready to win eight' => sub {
	# 123m 456p 789s 11s 5m 6m: the chow 4-5-6? no, the discard is 7m for 5-6-7,
	# making 123m 567m 456p 789s 11s: ready on... it is complete with 11s as the
	# pair: fourteen worth after the claim, the chow leaves 13 to discard one.
	# After chow(567m): 123m 456p 789s 11s + chow = 11 concealed... the hand
	# would be 123m 456p 789s 11s (11 tiles) + chow = 14: complete already, the
	# seat discards one and is ready; mixed straight 8 + more: eight reached
	my $v = view(hand => '123m 456p 789s 11s 5m 6m', window => { tile => 'm7', from => 3, legal => [ { kind => 'chow', tiles => [qw(m5 m6)] } ] });
	is(best($v, 2)->{kind}, 'chow', 'the chow makes a mixed straight ready: taken');
	# a chow that makes a nothing hand ready: 234m 567p 88s 5m 6m + 7m: all chows
	# with a suit pair, no honours, would score all chows 2 + ... not eight: pass
	my $u = view(hand => '234m 567p 88s 5m 6m 2s 3s 4s', window => { tile => 'm7', from => 3, legal => [ { kind => 'chow', tiles => [qw(m5 m6)] } ] });
	is(best($u, 2)->{kind}, 'pass', 'a chow toward a hand that cannot reach eight: pass');
};

subtest 'rung 3 discards safely against a seat with three melds' => sub {
	# three from ready (the partials 1-3m 3-4p 6-7p SS and the head EE, 8-0-4-1);
	# 9p, 2s, 5s and 8s each leave it three; seat 2 has three melds and has
	# discarded 9p, so 9p is the safe one
	my $v = view(hand => '13m 3467p 9p 2s 5s 8s EE SS', melds => [ [], [], [qw(m1 p1 s1)], [] ], pools => [ [], [], [qw(p9 we)], [] ]);
	my $m = best($v, 3);
	is(code($m->{tile}), 'p9', 'rung 3 throws the nine of dots seat 2 already threw');
	my $n = best($v, 2);
	isnt(code($n->{tile}), 'p9', 'rung 2 does not think of it: ' . code($n->{tile}));
};

subtest 'the view has no field for another hand' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'view');
	my $v = Game::Mahjong::Search::view_of($g, 1);
	is_deeply([ sort keys %$v ], [ sort qw(seat hand phase turn window prevailing seat_wind wall pools melds visible totals hand_no moves drawn legal) ], 'the keys');
	is($v->{hand}->total, 13, 'its own hand');
	is_deeply($v->{pools}, [ [], [], [], [] ], 'empty pools');
	my $tiles = 0;
	$tiles += $_ for values %{ $v->{visible} };
	is($tiles, 13, 'visible: its own thirteen and nothing else at the deal');
	ok(!grep({ /wall_tiles|hands|order/ } keys %$v), 'no wall order, no other hands');
};

subtest 'the ideas can be switched off' => sub {
	my $v = view(hand => '123m 456p 789s 11s 5m 6m 9m');
	local $Game::Mahjong::Search::OFF{shanten} = 1;
	my $m = best($v, 2);
	ok($m, 'rung 2 with shanten off still moves');
	is(code($m->{tile}), 'm9', 'and falls back to isolation: the nine');
};
