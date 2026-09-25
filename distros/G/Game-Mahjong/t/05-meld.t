#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub ids { return [ map { id($_) } @_ ] }
sub meld { return Game::Mahjong::Meld->new(@_) }

plan tests => 6;

subtest 'the three kinds' => sub {
	my $chow = meld(kind => 'chow', tiles => ids(qw(m4 m2 m3)));
	ok($chow->is_chow, 'a chow');
	ok(!$chow->is_pung, 'is not a pung');
	ok(!$chow->is_kong, 'nor a kong');
	is_deeply($chow->tiles, ids(qw(m2 m3 m4)), 'tiles sorted');
	is($chow->tile, id('m2'), 'the lowest is the tile');
	is($chow->suit, 'm', 'suit');
	is($chow->rank, 2, 'rank');
	is($chow->size, 3, 'three');
	is($chow->counts_as, 3, 'counts three');
	ok($chow->is_exposed, 'exposed by default');

	my $pung = meld(kind => 'pung', tiles => ids(qw(we we we)), claimed_from => 2, claimed_tile => id('we'));
	ok($pung->is_pung, 'a pung');
	ok(!$pung->is_kong, 'not a kong');
	ok($pung->is_honour, 'of honours');
	is($pung->suit, undef, 'no suit');
	is($pung->rank, undef, 'no rank');
	is($pung->claimed_from, 2, 'from seat 2');

	my $kong = meld(kind => 'kong', tiles => ids(qw(p9 p9 p9 p9)), concealed => 1);
	ok($kong->is_kong, 'a kong');
	ok($kong->is_pung, 'and a kong is a pung wherever a pung counts');
	is($kong->size, 4, 'four tiles');
	is($kong->counts_as, 3, 'but counts three');
	ok(!$kong->is_exposed, 'concealed');
};

subtest 'terminals, honours, outside' => sub {
	ok(meld(kind => 'chow', tiles => ids(qw(m1 m2 m3)))->has_terminal, '1-2-3 has a terminal');
	ok(meld(kind => 'chow', tiles => ids(qw(m7 m8 m9)))->has_terminal, '7-8-9 too');
	ok(!meld(kind => 'chow', tiles => ids(qw(m2 m3 m4)))->has_terminal, '2-3-4 has not');
	ok(meld(kind => 'chow', tiles => ids(qw(m1 m2 m3)))->is_outside, '1-2-3 is outside');
	ok(meld(kind => 'pung', tiles => ids(qw(dr dr dr)))->is_outside, 'a dragon pung is outside');
	ok(meld(kind => 'pung', tiles => ids(qw(s9 s9 s9)))->is_outside, 'a nine pung is outside');
	ok(!meld(kind => 'pung', tiles => ids(qw(s5 s5 s5)))->is_outside, 'a five pung is not');
	ok(!meld(kind => 'chow', tiles => ids(qw(m1 m2 m3)))->is_honour, 'a chow is never honours');
};

subtest 'what it refuses' => sub {
	my @bad = (
		[ [ kind => 'chow', tiles => ids(qw(m1 m3 m5)) ],       qr/consecutive/,   'a chow with gaps' ],
		[ [ kind => 'chow', tiles => ids(qw(m8 m9 p1)) ],       qr/consecutive/,   'a chow across suits' ],
		[ [ kind => 'chow', tiles => ids(qw(we ws ww)) ],       qr/consecutive/,   'a chow of winds' ],
		[ [ kind => 'chow', tiles => ids(qw(m1 m2)) ],          qr/chow is 3/,     'a chow of two' ],
		[ [ kind => 'pung', tiles => ids(qw(we we ws)) ],       qr/identical/,     'a pung of different tiles' ],
		[ [ kind => 'pung', tiles => ids(qw(we we we we)) ],    qr/pung is 3/,     'a pung of four' ],
		[ [ kind => 'kong', tiles => ids(qw(we we we)) ],       qr/kong is 4/,     'a kong of three' ],
		[ [ kind => 'pung', tiles => ids(qw(f1 f1 f1)) ],       qr/bonus/,         'a pung of flowers' ],
		[ [ kind => 'bogus', tiles => ids(qw(m1 m2 m3)) ],      qr/no such kind/,  'an unknown kind' ],
		[ [ kind => 'pung', tiles => ids(qw(we we we)), claimed_from => 1 ], qr/names the tile/, 'claimed from somebody but no tile named' ],
		[ [ kind => 'pung', tiles => ids(qw(we we we)), claimed_from => 1, claimed_tile => id('ws') ], qr/not in the meld/, 'a claimed tile not in the meld' ],
		[ [ kind => 'kong', tiles => ids(qw(we we we we)), concealed => 1, claimed_from => 1, claimed_tile => id('we') ], qr/nobody/, 'a concealed meld claimed from somebody' ],
		[ [ kind => 'pung', tiles => ids(qw(we we we)), promoted => 1 ], qr/only a kong/, 'a promoted pung' ],
		[ [ kind => 'pung', tiles => [ 43, 43, 43 ] ],           qr/no tile 43/,    'a kind off the table' ],
	);
	for my $case (@bad) {
		my ($args, $re, $why) = @$case;
		ok(!eval { meld(@$args); 1 }, "$why dies");
		like($@, $re, 'with the reason');
	}
};

subtest 'promote' => sub {
	my $pung = meld(kind => 'pung', tiles => ids(qw(dg dg dg)), claimed_from => 1, claimed_tile => id('dg'));
	my $kong = $pung->promote;
	ok($kong->is_kong, 'a kong');
	ok($kong->promoted, 'promoted');
	ok(!$kong->concealed, 'exposed');
	is($kong->claimed_from, 1, 'keeps where the pung came from');
	is_deeply($kong->tiles, ids(qw(dg dg dg dg)), 'four green dragons');
	is_deeply($pung->tiles, ids(qw(dg dg dg)), 'the pung is unchanged: a meld is a value');
	ok(!eval { $kong->promote; 1 }, 'a kong is not promoted again');
	ok(!eval { meld(kind => 'chow', tiles => ids(qw(m1 m2 m3)))->promote; 1 }, 'a chow is not promoted');
	ok(!eval { meld(kind => 'pung', tiles => ids(qw(dg dg dg)), concealed => 1)->promote; 1 },
		'a concealed pung is not promoted: it was never on the table');
};

subtest 'equals, to_hash, to_notation' => sub {
	my $a = meld(kind => 'chow', tiles => ids(qw(s2 s3 s4)), claimed_from => 0, claimed_tile => id('s3'));
	my $b = meld(kind => 'chow', tiles => ids(qw(s4 s3 s2)));
	ok($a->equals($b), 'the same tiles and kind are equal whoever claimed them');
	ok(!$a->equals(meld(kind => 'chow', tiles => ids(qw(s3 s4 s5)))), 'other tiles are not');
	ok(!meld(kind => 'kong', tiles => ids(qw(we we we we)))->equals(meld(kind => 'kong', tiles => ids(qw(we we we we)), concealed => 1)),
		'a concealed kong is not equal to an exposed one');
	ok(!$a->equals('chow'), 'nor is a string');
	is_deeply($a->to_hash, { kind => 'chow', tiles => ids(qw(s2 s3 s4)), concealed => 0 }, 'to_hash');
	is($a->to_notation, 'chow(234s)', 'to_notation');
	is(meld(kind => 'kong', tiles => ids(qw(we we we we)), concealed => 1)->to_notation, 'ckong(EEEE)', 'a concealed kong prints ckong');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   return 0 from is_pung for a kong        -> 'a kong is a pung wherever a pung counts' fails
#   drop the rank <= 7 check in BUILD       -> nothing here fails, and that is why 'a chow across
#                                              suits' exists: m8 m9 p1 are consecutive ids and only
#                                              the suit test refuses them
#   return 4 from counts_as                 -> 'but counts three' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};
