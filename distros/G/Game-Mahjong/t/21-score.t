#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub hand { return Game::Mahjong::Hand->from_notation($_[0]) }

sub tally {
	my ($notation, $winning, %ctx) = @_;
	my $h = hand($notation);
	die "$notation is " . $h->total . " tiles" unless $h->total == 14;
	return Game::Mahjong::Score::score($h, $winning ? id($winning) : 0, { by => 'discard', prevailing => 0, seat => 1, %ctx });
}

sub fans_of { my ($t) = @_; return { map { $_->{key} => $_->{times} } @{ $t->fans } } }

plan tests => 7;

# EIGHT HANDS WITH THE TOTAL BY HAND. Each comment is the arithmetic; the
# context is by discard, east round, south seat, unless the row says.
subtest 'eight hands, totals by hand' => sub {
	my @rows = (
		# big three dragons 88; three concealed pungs 16; concealed 2; single 1;
		# one voided suit (m, p) 1 = 108
		[ 'RRR GGG BBB 123m 55p', 'p5', {}, 108,
			{ big_three_dragons => 1, three_concealed_pungs => 1, concealed_hand => 1, single_wait => 1, one_voided_suit => 1 } ],
		# mixed triple chow 8 (implies mixed double chow); fully concealed 4 (implies
		# self-drawn); pung of terminals 999m 1; single 1; no honours 1 = 15
		[ '123m 123p 123s 999m 55p', 'p5', { by => 'self' }, 15,
			{ mixed_triple_chow => 1, fully_concealed_hand => 1, pung_of_terminals_or_honours => 1, single_wait => 1, no_honours => 1 } ],
		# seven pairs 24 (excludes concealed hand and single wait); half flush 6 = 30
		[ '11p 33p 55p 77p 99p EE SS', 'ws', {}, 30,
			{ seven_pairs => 1, half_flush => 1 } ],
		# triple pung 16 (implies its three double pungs); three concealed pungs
		# 16; concealed 2; single 1; no honours 1 = 36
		[ '555m 555p 555s 123m 99p', 'p9', {}, 36,
			{ triple_pung => 1, three_concealed_pungs => 1, concealed_hand => 1, single_wait => 1, no_honours => 1 } ],
		# lesser honours and knitted 12 (excludes all types, concealed hand); fully
		# concealed 4; NO single wait: the thirteen waited on any of the three
		# missing dragons = 16
		[ '147m 258p 369s ESWN R', 'dr', { by => 'self' }, 16,
			{ lesser_honours_and_knitted_tiles => 1, fully_concealed_hand => 1 } ],
		# mixed shifted pungs (1m 2p 3s) 8; two melded kongs at the mixed six
		# (implies the single kong fans); two concealed pungs (333s and the
		# concealed kong) 2; pung of terminals (1111m) 1; single 1; no honours 1 = 19
		[ 'kong(1111m) ckong(2222p) 333s 456s 99p', 'p9', {}, 19,
			{ mixed_shifted_pungs => 1, two_melded_kongs => 1, two_concealed_pungs => 1, pung_of_terminals_or_honours => 1, single_wait => 1, no_honours => 1 } ],
		# four concealed pungs 64 (excludes all pungs and concealed hand); mixed
		# shifted pungs (1m 2p 3s) 8; dragon pung 2; pung of terminals 111m 1;
		# single 1 = 76
		[ '111m 222p 333s RRR 55m', 'm5', {}, 76,
			{ four_concealed_pungs => 1, mixed_shifted_pungs => 1, dragon_pung => 1, pung_of_terminals_or_honours => 1, single_wait => 1 } ],
		# four concealed pungs 64; prevalent and seat wind on one pung (east seat,
		# east round) 2 + 2; pung of terminals 111m 1; single 1; one voided (m, p)
		# 1 = 71
		[ 'EEE 111m 222p 333p 55m', 'm5', { seat => 0 }, 71,
			{ four_concealed_pungs => 1, prevalent_wind => 1, seat_wind => 1, pung_of_terminals_or_honours => 1, single_wait => 1, one_voided_suit => 1 } ],
	);
	for my $row (@rows) {
		my ($n, $w, $ctx, $want, $fans) = @$row;
		my $t = tally($n, $w, %$ctx);
		is($t->points, $want, "$n: $want");
		is_deeply(fans_of($t), $fans, "$n: the fans") or diag $t->describe;
	}
};

subtest 'nine gates on every wait' => sub {
	for my $r (1 .. 9) {
		my $h = hand('1112345678999m');
		$h->add(id("m$r"));
		my $t = Game::Mahjong::Score::score($h, id("m$r"), { by => 'self', prevailing => 0, seat => 1 });
		ok($t && $t->has_fan('nine_gates'), "won on the $r: nine gates");
		ok(!$t->has_fan('full_flush'), 'without full flush');
		cmp_ok($t->points, '>=', 88 + 4, 'at least 88 and the fully concealed 4');
	}
};

# THE MINIMUM IS READ WITHOUT FLOWERS. 234m 567p 456s 888s 33m self-drawn on
# the 3: all simples 2 (implies no honours), fully concealed 4, single 1 (the
# thirteen 2 3 3 4 waited on the 3 alone; with 22m instead the 5 would also
# have completed 22 345, two waits and no wait fan, which the first draft of
# this test learned) = 7. Seven is refused, seven and a flower is still
# refused, and the tally says so; a hand that reaches eight is accepted.
subtest 'the eight-point minimum, without flowers' => sub {
	my $seven = tally('234m 567p 456s 888s 33m', 'm3', by => 'self');
	is($seven->basic, 7, 'seven points');
	ok(!$seven->minimum_met, 'refused at seven');
	my $flower = tally('234m 567p 456s 888s 33m', 'm3', by => 'self', flowers => 1);
	is($flower->basic, 7, 'still seven without the flower');
	is($flower->points, 8, 'eight with it');
	ok(!$flower->minimum_met, 'and still refused: a flower does not count toward the eight');
	is($flower->has_fan('flower_tiles'), 1, 'the flower is listed');
	my $eight = tally('234m 567p 456s 888s 33m', 'm3', by => 'self', last_tile => 1);
	is($eight->basic, 11, 'the last tile makes eleven');
	ok($eight->minimum_met, 'accepted');
};

# CHICKEN HAND: nothing else scores, so it scores eight. A melded pung so
# the hand is not concealed, an honour pair so no No Honours, a two-sided
# wait so no wait fan, won by discard so no self-draw.
subtest 'chicken hand' => sub {
	my $t = tally('234m 567p 456s EE pung(888s)', 'm4');
	is($t->points, 8, 'eight');
	is_deeply(fans_of($t), { chicken_hand => 1 }, 'chicken hand alone');
	ok($t->minimum_met, 'and it wins');
	my $u = tally('234m 567p 456s EE pung(888s)', 'm4', flowers => 2);
	is_deeply(fans_of($u), { chicken_hand => 1, flower_tiles => 2 }, 'flowers do not stop a chicken hand');
	is($u->points, 10, 'ten');
};

subtest 'the wait fans need the tile to be the only wait' => sub {
	my $t = tally('123m 456p 789s 111s 55m', 'm3');
	is($t->has_fan('edge_wait'), 1, 'the edge');
	my $u = tally('123m 456p 789s 111s 55m', 'm3', waits => [ id('m3'), id('m6') ]);
	ok(!$u->has_fan('edge_wait'), 'told the hand also waited on a 6: no edge fan');
	my $v = tally('19m 19p 19s ESWN RGB E', 'm1', by => 'self');
	is($v->has_fan('single_wait'), 0, 'thirteen orphans excludes the single wait');
	ok($v->has_fan('thirteen_orphans') && $v->has_fan('fully_concealed_hand'), '88 and the fully concealed 4');
	is($v->points, 92, 'ninety-two');
};

subtest 'not complete, and not fourteen' => sub {
	my $h = hand('123m 456p 789s 111s 56m');
	is(Game::Mahjong::Score::score($h, 0, {}), undef, 'an incomplete hand scores undef');
	ok(!eval { Game::Mahjong::Score::score(hand('123m'), 0, {}); 1 }, 'three tiles dies');
	is(Game::Mahjong::Score::minimum_met(undef), 0, 'minimum_met of undef is false');
};

subtest 'the floor from the melds' => sub {
	is(Game::Mahjong::Score::floor(hand('123m 456p 789s 111s 5m'), {}), 0, 'no melds, no floor');
	my $h = hand('12m 5p pung(RRR) pung(GGG) pung(EEE)');
	# two dragon pungs 6 (implies dragon pung) + the east pung: prevalent wind
	# 2 in the east round; the pung of terminals or honours does not count the
	# prevalent wind
	is(Game::Mahjong::Score::floor($h, { prevailing => 0, seat => 1 }), 8, 'two dragon pungs and the prevalent wind: 8');
	my $k = hand('12m 5p kong(1111s) kong(9999s) pung(NNN)');
	# two melded kongs 4 (implies melded kong); pungs of terminals or honours:
	# 1111s, 9999s, NNN = 3
	is(Game::Mahjong::Score::floor($k, { prevailing => 0, seat => 1 }), 7, 'two melded kongs and three pungs of terminals or honours: 7');
	cmp_ok(Game::Mahjong::Score::floor($k, { prevailing => 0, seat => 1 }), '<=',
		tally('12m 3m 5p 5p kong(1111s) kong(9999s) pung(NNN)', 'm3')->basic, 'the floor is below the score');
};
