#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub hand { return Game::Mahjong::Hand->from_notation($_[0]) }

# A split as a string the tests can name: sets sorted, in notation, then the
# pair. The order the walk found them in is not part of the contract.
sub shape {
	my ($split) = @_;
	my @sets = sort map {
		my $k = $_->{kind};
		my $t = Game::Mahjong::Notation::print(@{ $_->{tiles} });
		($_->{melded} ? '[' : '') . "$k($t)" . ($_->{melded} ? ']' : '');
	} @{ $split->{sets} };
	my $pair = defined $split->{pair} ? ' pair ' . Game::Mahjong::Notation::print(($split->{pair}) x 2) : '';
	return $split->{form} . ': ' . join(' ', @sets) . $pair;
}

sub shapes {
	my ($hand, $winning) = @_;
	my %seen;
	return [ sort grep { !$seen{$_}++ } map { shape($_) } Game::Mahjong::Decompose::decompose($hand, $winning) ];
}

plan tests => 9;

subtest 'a plain hand splits one way' => sub {
	my $h = hand('123m 456p 789s 111s 55m');
	is($h->total, 14, 'fourteen tiles');
	ok(Game::Mahjong::Decompose::is_complete($h), 'complete');
	is_deeply(shapes($h), [ 'standard: chow(123m) chow(456p) chow(789s) pung(111s) pair 55m' ], 'one split');
};

# THE MULTI-SPLIT TABLE, computed by hand (the reasoning is in the plan's 03):
# 1 1 1 2 2 2 3 3 3 4 4 4 5 5 of characters is complete four ways.
subtest 'a hand that splits four ways' => sub {
	my $h = hand('11122233344455m');
	# sets sorted within a shape, shapes sorted: chows before pungs
	is_deeply(shapes($h), [
		'standard: chow(123m) chow(123m) chow(123m) pung(444m) pair 55m',
		'standard: chow(234m) chow(234m) chow(234m) pung(111m) pair 55m',
		'standard: chow(234m) chow(345m) chow(345m) pung(111m) pair 22m',
		'standard: pung(111m) pung(222m) pung(333m) pung(444m) pair 55m',
	], 'the four splits, and no fifth');
};

subtest '111222333 is three pungs or three chows' => sub {
	my $h = hand('111222333m 44p 555s');
	is_deeply(shapes($h), [
		'standard: chow(123m) chow(123m) chow(123m) pung(555s) pair 44p',
		'standard: pung(111m) pung(222m) pung(333m) pung(555s) pair 44p',
	], 'two splits');
};

subtest 'the pair can be a kind a chow uses too' => sub {
	my $h = hand('22234m 456p 789s EEE');
	is_deeply(shapes($h), [ 'standard: chow(234m) chow(456p) chow(789s) pung(EEE) pair 22m' ],
		'22 is the pair and the third 2 starts the chow');
};

subtest 'a hand with melds' => sub {
	my $h = hand('123m 55p 456s pung(EEE) ckong(9999s)');
	is($h->total, 14, 'fourteen: eight concealed and two melds');
	is($h->meld_count, 2, 'two melds');
	is_deeply(shapes($h), [ 'standard: [kong(9999s)] [pung(EEE)] chow(123m) chow(456s) pair 55p' ],
		'the concealed split plus the melds, the kong four tiles');
	my ($split) = Game::Mahjong::Decompose::decompose($h);
	is(scalar @{ $split->{sets} }, 4, 'four sets in all');
	is($split->{sets}[0]{concealed}, 1, 'the concealed chow first');
	ok($split->{sets}[0]{tiles} && !$split->{sets}[0]{melded}, 'and not melded');
	is($split->{sets}[3]{kind}, 'kong', 'the kong keeps its kind');
	is($split->{sets}[3]{concealed}, 1, 'and its concealment');
	is($split->{sets}[2]{concealed}, 0, 'the claimed pung is exposed');
	my $four = hand('55p pung(EEE) pung(SSS) chow(123m) kong(9999s)');
	is_deeply(shapes($four), [ 'standard: [chow(123m)] [kong(9999s)] [pung(EEE)] [pung(SSS)] pair 55p' ],
		'four melds and a concealed pair');
};

subtest 'not complete' => sub {
	for my $case (
		[ '123m 456p 789s 111s 5m',   'thirteen tiles' ],
		[ '123m 456p 789s 111s 56m',  'a pair short' ],
		[ '123m 456p 789s 112s 55m',  'a set short' ],
		[ '19m 19p 19s ESWN RG 5m',   'twelve orphans and a five' ],
		[ '11p 22p 33p 44p 55p 66p 7p 8p', 'six pairs and two singles' ],
		[ '123m 456p 789s 111s 55m pung(EEE)', 'fourteen concealed with a meld is seventeen' ],
	) {
		my ($n, $why) = @$case;
		my $h = hand($n);
		ok(!Game::Mahjong::Decompose::is_complete($h), "$why: not complete");
		is_deeply([ Game::Mahjong::Decompose::decompose($h) ], [], 'and no splits');
	}
};

subtest 'the placement of the winning tile' => sub {
	# 1-2-3 won on the 3: an edge wait in this split
	my $h = hand('123m 456p 789s 111s 55m');
	my @splits = Game::Mahjong::Decompose::decompose($h, id('m3'));
	is(scalar @splits, 1, 'one placement: the 3 is only in the chow');
	is_deeply($splits[0]{placement}, { in => 'set', index => 0, wait => 'edge' }, 'the 3 of 1-2-3 is an edge wait');
	# won on the 2: closed
	@splits = Game::Mahjong::Decompose::decompose($h, id('m2'));
	is($splits[0]{placement}{wait}, 'closed', 'the 2 of 1-2-3 is a closed wait');
	# won on the 1: two-sided (not the 3, so not an edge)
	@splits = Game::Mahjong::Decompose::decompose($h, id('m1'));
	is($splits[0]{placement}{wait}, 'two_sided', 'the 1 of 1-2-3 is two-sided');
	# 7-8-9 won on the 7: edge; on the 9: two-sided
	@splits = Game::Mahjong::Decompose::decompose($h, id('s7'));
	is($splits[0]{placement}{wait}, 'edge', 'the 7 of 7-8-9 is an edge wait');
	@splits = Game::Mahjong::Decompose::decompose($h, id('s9'));
	is($splits[0]{placement}{wait}, 'two_sided', 'the 9 of 7-8-9 is two-sided');
	# 4-5-6 won on the 4: two-sided
	@splits = Game::Mahjong::Decompose::decompose($h, id('p4'));
	is($splits[0]{placement}{wait}, 'two_sided', 'the 4 of 4-5-6 is two-sided');
	# the pung
	@splits = Game::Mahjong::Decompose::decompose($h, id('s1'));
	# the walk finds sets from the lowest kind: 123m, 456p, 111s, 789s, so the pung is index 2
	is_deeply($splits[0]{placement}, { in => 'set', index => 2, wait => 'pung' }, 'the third 1 of bamboo is a pung wait');
	# the pair
	@splits = Game::Mahjong::Decompose::decompose($h, id('m5'));
	is_deeply($splits[0]{placement}, { in => 'pair', index => 0, wait => 'pair' }, 'the second 5 is a pair wait');
	# a tile in two places of one split: 22234m won on the 2 sits in the pair or in the chow
	my $two = hand('22234m 456p 789s EEE');
	@splits = Game::Mahjong::Decompose::decompose($two, id('m2'));
	is(scalar @splits, 2, 'one split, two placements');
	is_deeply([ sort map { $_->{placement}{wait} } @splits ], [ 'pair', 'two_sided' ], 'a pair wait and a two-sided one');
	# no winning tile: no placement
	@splits = Game::Mahjong::Decompose::decompose($h);
	is_deeply($splits[0]{placement}, { in => undef, index => 0, wait => undef }, 'no placement without a winning tile');
	# the winning tile in a meld: the split comes back unplaced rather than not at all
	my $m = hand('123m 55p 456s pung(EEE) ckong(9999s)');
	@splits = Game::Mahjong::Decompose::decompose($m, id('we'));
	is(scalar @splits, 1, 'still one split');
	is($splits[0]{placement}{in}, undef, 'unplaced');
};

subtest 'waits' => sub {
	my @cases = (
		[ '123m 456p 789s 111s 5m',  [qw(m5)],              'a single wait on the pair' ],
		[ '123m 456p 789s 11s 55m',  [qw(s1 m5)],           'two pairs: either pung completes' ],
		[ '12m 456p 789s 111s 55m',  [qw(m3)],              '1-2: the edge, the 3 only' ],
		[ '23m 456p 789s 111s 55m',  [qw(m1 m4)],           '2-3: two-sided, 1 or 4' ],
		[ '13m 456p 789s 111s 55m',  [qw(m2)],              '1-3: the closed 2' ],
		[ '1234m 456p 789s 111s',    [qw(m1 m4)],           '1-2-3-4: fan 79 example, waiting on the 1 and the 4' ],
		[ '1112345678999m',          [ map { "m$_" } 1 .. 9 ], 'nine gates waits on all nine' ],
		[ '19m 19p 19s ESWN RGB',    [qw(m1 m9 p1 p9 s1 s9 we ws ww wn dr dg dw)], 'thirteen orphans with no pair waits on all thirteen' ],
		[ '19m 19p 19s ESWN R BB',   [qw(dg)],              'twelve orphans with a pair of white: waiting on the green alone' ],
		[ '11p 33p 55p 77p 99p EE S', [qw(ws)],             'seven pairs less one, pairs that make no chow' ],
		[ '5555m 678p 234s 99s 6m',  [qw(m4 m7)],           'four fives held: 555 and 5-6 wait on the 4 or the 7, never on a fifth 5' ],
		[ '22m 456p 789s 55s pung(EEE)', [qw(m2 s5)],        'with a meld: the 2 to pung or the 5 to pung, the other the pair' ],
	);
	for my $case (@cases) {
		my ($n, $want, $why) = @$case;
		my $h = hand($n);
		is($h->total, 13, "$why: thirteen");
		is_deeply([ map { Game::Mahjong::Tiles::code_of($_) } Game::Mahjong::Decompose::waits($h) ],
			[ sort { Game::Mahjong::Tiles::id_of($a) <=> Game::Mahjong::Tiles::id_of($b) } @$want ], $why);
	}
	is_deeply([ Game::Mahjong::Decompose::waits(hand('19m 19p 19s ESWN 5m 5p 5s')) ], [], 'a hand with no wait');
	ok(!eval { Game::Mahjong::Decompose::waits(hand('123m 456p 789s 111s 55m')); 1 }, 'waits of fourteen dies');
};

subtest 'what the door refuses' => sub {
	my $h = hand('123m');
	ok(!eval { Game::Mahjong::Decompose::_decompose([ (0) x 10, 5 ], 0, 0); 1 }, 'a count of five croaks');
	like($@, qr/0 to 4/, 'with the reason');
	ok(!eval { Game::Mahjong::Decompose::_decompose($h->counts, 5, 0); 1 }, 'five melds croaks');
	ok(!eval { Game::Mahjong::Decompose::_decompose($h->counts, 0, 35); 1 }, 'a winning kind off the kinds croaks');
	is_deeply(Game::Mahjong::Decompose::_decompose([], 0, 0), [], 'an empty arrayref is an empty hand: no splits');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   drop the chow branch after the pung in walk_sets  -> 'the four splits' counts two
#   let a chow run across suits (drop IS_SUIT/RANK<=7) -> '9m 1p 2p' would split; see t/07
#   drop the placement                                 -> 'the 3 of 1-2-3 is an edge wait' fails
#   stop at the first split (max 1 in _decompose)      -> 'two splits' counts one
