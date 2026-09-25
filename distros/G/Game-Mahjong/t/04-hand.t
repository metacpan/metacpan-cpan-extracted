#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub ids { return [ map { id($_) } @_ ] }

plan tests => 10;

subtest 'a hand is counts, conserved' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('123m 55p EEE 78s');
	is($hand->size, 10, 'ten tiles');
	is($hand->total, 10, 'and ten in total with no melds');
	is($hand->count(id('p5')), 2, 'two fives of dots');
	is($hand->count(id('m9')), 0, 'no nine of characters');
	is_deeply([ $hand->tiles ], ids(qw(m1 m2 m3 p5 p5 s7 s8 we we we)), 'the tiles, sorted, with repeats');
	is_deeply([ $hand->kinds ], ids(qw(m1 m2 m3 p5 s7 s8 we)), 'the kinds');
	$hand->add(id('s9'));
	is($hand->size, 11, 'eleven after a draw');
	$hand->remove(id('p5'));
	is($hand->count(id('p5')), 1, 'one five of dots after a discard');
	is($hand->to_notation, '123m 5p 789s EEE', 'and it prints back');
	is($hand->meld_count, 0, 'no melds');
	is_deeply($hand->flowers, [], 'no flowers');
	my $from_tiles = Game::Mahjong::Hand->from_tiles(ids(qw(m1 m1 dw)));
	is($from_tiles->to_notation, '11m B', 'from a list of kinds');
};

subtest 'what add and remove refuse' => sub {
	my $hand = Game::Mahjong::Hand->new;
	ok(!eval { $hand->remove(id('m1')); 1 }, 'removing what is not there dies');
	like($@, qr/no m1 to remove/, 'with the reason');
	$hand->add(id('m1')) for 1 .. 4;
	ok(!eval { $hand->add(id('m1')); 1 }, 'a fifth dies');
	ok(!eval { $hand->add(id('f1')); 1 }, 'a flower into the hand dies');
	like($@, qr/add_flower/, 'and says where it goes');
	ok(!eval { $hand->add(43); 1 }, 'a kind off the table dies');
	ok(!eval { $hand->add_flower(id('m1')); 1 }, 'a suit tile as a flower dies');
	$hand->add_flower(id('t2'));
	ok(!eval { $hand->add_flower(id('t2')); 1 }, 'the same flower twice dies');
	$hand->add_flower(id('f1'));
	is_deeply($hand->flowers, ids(qw(f1 t2)), 'flowers sorted');
};

subtest 'expects and total, zero to four melds' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('1m');
	is($hand->expects, 13, 'thirteen with no melds');
	my @melds = (
		'pung(EEE)', 'chow(234s)', 'ckong(5555p)', 'kong(9999m)',
	);
	for my $n (1 .. 4) {
		my $h = Game::Mahjong::Hand->from_notation('1m ' . join(' ', @melds[0 .. $n - 1]));
		is($h->expects, 13 - 3 * $n, "$n melds: expects " . (13 - 3 * $n));
		is($h->total, 1 + 3 * $n, "and a kong counts three in the total");
	}
};

subtest 'concealed, and the concealed kong' => sub {
	my $bare = Game::Mahjong::Hand->from_notation('123m');
	ok($bare->is_concealed, 'no melds is concealed');
	my $ck = Game::Mahjong::Hand->from_notation('123m ckong(5555p)');
	ok($ck->is_concealed, 'a concealed kong keeps the hand concealed (3.6.8)');
	is(scalar @{ $ck->concealed_kongs }, 1, 'and it is listed to show at the end');
	my $pung = Game::Mahjong::Hand->from_notation('123m pung(EEE)');
	ok(!$pung->is_concealed, 'a claimed pung does not');
	is(scalar @{ $pung->concealed_kongs }, 0, 'no concealed kong there');
};

subtest 'chow_shapes' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('2346m');
	is_deeply([ $hand->chow_shapes(id('m5')) ], [ ids(qw(m3 m4)), ids(qw(m4 m6)) ],
		'holding 2 3 4 6, a 5 makes 3-4-5 and 4-5-6 (not 5-6-7: no 7)');
	my $three = Game::Mahjong::Hand->from_notation('3467m');
	is_deeply([ $three->chow_shapes(id('m5')) ], [ ids(qw(m3 m4)), ids(qw(m4 m6)), ids(qw(m6 m7)) ],
		'holding 3 4 6 7, a 5 makes three shapes');
	is_deeply([ $three->chow_shapes(id('m1')) ], [], 'a 1 makes nothing with 3 4 6 7');
	my $edge = Game::Mahjong::Hand->from_notation('23m 89s');
	is_deeply([ $edge->chow_shapes(id('m1')) ], [ ids(qw(m2 m3)) ], 'a 1 with 2 3: the edge');
	is_deeply([ $edge->chow_shapes(id('s7')) ], [ ids(qw(s8 s9)) ], 'a 7 with 8 9: the other edge');
	is_deeply([ $edge->chow_shapes(id('p1')) ], [], 'the wrong suit makes nothing');
	is_deeply([ $edge->chow_shapes(id('we')) ], [], 'an honour makes nothing');
	my $pair = Game::Mahjong::Hand->from_notation('44m');
	is_deeply([ $pair->chow_shapes(id('m4')) ], [], 'a pair of the kind itself is not a chow shape');
	my $wrap = Game::Mahjong::Hand->from_notation('9m 1p');
	is_deeply([ $wrap->chow_shapes(id('m8')) ], [], 'nothing runs from 9m into 1p');
};

subtest 'holds_pair, holds_pung_of, holds_kong_of, exposed_pung_of' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('EE 555p 9999s pung(WWW)');
	ok($hand->holds_pair(id('we')), 'a pair of east');
	ok(!$hand->holds_pung_of(id('we')), 'not a pung of east');
	ok($hand->holds_pung_of(id('p5')), 'a pung of fives');
	ok(!$hand->holds_kong_of(id('p5')), 'not a kong of fives');
	ok($hand->holds_kong_of(id('s9')), 'a kong of nines');
	ok($hand->holds_pair(id('s9')), 'which is also a pair');
	ok(!$hand->holds_kong_of(id('ww')), 'three in hand and a melded pung of the same is NOT a concealed kong');
	ok($hand->exposed_pung_of(id('ww')), 'it is an exposed pung to promote');
	ok(!$hand->exposed_pung_of(id('p5')), 'a concealed pung is not exposed');
};

subtest 'the claims move the tiles and build the meld' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('34m 66p 888s WWWW 1m');
	$hand->waits([ id('m5') ]);

	my $chow = $hand->claim_chow(id('m5'), id('m3'), id('m4'), 3);
	is($chow->to_notation, 'chow(345m)', 'the chow');
	is($chow->claimed_from, 3, 'from seat 3');
	is($chow->claimed_tile, id('m5'), 'the five');
	is($hand->count(id('m3')), 0, 'the three left the hand');
	is($hand->waits, undef, 'and the waits were cleared');

	my $pung = $hand->claim_pung(id('p6'), 0);
	is($pung->to_notation, 'pung(666p)', 'the pung');
	is($hand->count(id('p6')), 0, 'both sixes left');

	my $kong = $hand->claim_kong(id('s8'), 1);
	is($kong->to_notation, 'kong(8888s)', 'the claimed kong');
	ok(!$kong->concealed, 'exposed');
	is($hand->count(id('s8')), 0, 'the three eights left');

	my $ck = $hand->concealed_kong(id('ww'));
	is($ck->to_notation, 'ckong(WWWW)', 'the concealed kong');
	ok($ck->concealed, 'concealed');
	is($hand->count(id('ww')), 0, 'all four left');

	is($hand->meld_count, 4, 'four melds');
	is($hand->size, 1, 'one tile left concealed');
	is($hand->total, 13, 'thirteen in total');
	is($hand->expects, 1, 'and expects one');
	is($hand->to_notation, '1m chow(345m) pung(666p) kong(8888s) ckong(WWWW)', 'prints back in meld order');
};

subtest 'promotion' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('E 1m pung(EEE)');
	my $pung = $hand->exposed_pung_of(id('we'));
	$hand->waits([ 1 ]);
	my $kong = $hand->promote_kong(id('we'));
	is($kong->to_notation, 'kong(EEEE)', 'a kong');
	ok($kong->promoted, 'promoted');
	is($hand->count(id('we')), 0, 'the fourth east left the hand');
	is($hand->meld_count, 1, 'still one meld');
	ok($hand->melds->[0] == $kong, 'and it is the kong, in the pung\'s place');
	is($hand->waits, undef, 'waits cleared');
	ok(!eval { $hand->promote_kong(id('we')); 1 }, 'promoting it again dies');
	my $no = Game::Mahjong::Hand->from_notation('E pung(SSS)');
	ok(!eval { $no->promote_kong(id('we')); 1 }, 'no exposed pung of east: dies');
	my $ck = Game::Mahjong::Hand->from_notation('S ckong(EEEE)');
	ok(!eval { $ck->promote_kong(id('we')); 1 }, 'a concealed kong is not promoted');
};

subtest 'what the claims refuse' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('3m 6p 88s WWW');
	ok(!eval { $hand->claim_chow(id('m5'), id('m3'), id('m4'), 0); 1 }, 'a chow needing a four not held dies');
	ok(!eval { $hand->claim_chow(id('m5'), id('m3'), id('m3'), 0); 1 }, 'a chow of 3 3 5 dies');
	ok(!eval { $hand->claim_pung(id('p6'), 0); 1 }, 'a pung with one six dies');
	ok(!eval { $hand->claim_kong(id('s8'), 0); 1 }, 'a claimed kong with two eights dies');
	ok(!eval { $hand->concealed_kong(id('ww')); 1 }, 'a concealed kong with three dies');
	ok(!eval { $hand->claim_chow(id('we'), id('ws'), id('ww'), 0); 1 }, 'a chow of winds dies');
	is($hand->to_notation, '3m 6p 88s WWW', 'and nothing moved');
};

subtest 'clone' => sub {
	my $hand = Game::Mahjong::Hand->from_notation('123m pung(EEE) F1');
	$hand->waits([ 4 ]);
	my $copy = $hand->clone;
	$copy->add(id('m9'));
	$copy->claim_pung(id('m9'), 0) if 0;
	push @{ $copy->melds }, Game::Mahjong::Meld->new(kind => 'chow', tiles => ids(qw(s1 s2 s3)));
	$copy->add_flower(id('t1'));
	is($hand->size, 3, 'the original is untouched');
	is($hand->meld_count, 1, 'its melds too');
	is_deeply($hand->flowers, ids('f1'), 'its flowers too');
	is_deeply($hand->waits, [ 4 ], 'its waits too');
	is($copy->size, 4, 'the copy changed');
	is($copy->meld_count, 2, 'the copy has two melds');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   count a kong as 4 in total                    -> 'a kong counts three in the total' fails
#   let chow_shapes run across suits (drop suit)  -> 'nothing runs from 9m into 1p' fails
#   forget waits(undef) in claim_chow             -> 'the waits were cleared' fails
