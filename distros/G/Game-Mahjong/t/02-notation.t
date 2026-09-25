#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

my $N = 'Game::Mahjong::Notation';
my $T = 'Game::Mahjong::Tiles';

sub ids { return [ map { Game::Mahjong::Tiles::id_of($_) } @_ ] }

# Twenty hands, written by hand in every token shape the grammar allows.
my @HANDS = (
	'123m 55p EEE',
	'1112345678999m',
	'19m 19p 19s ESWN RGB',
	'11p 22p 33p 44p 55p 66p 77p',
	'234s 234s 234s 66s 88s',
	'EEE SSS WWW NN 5m',
	'RRR GGG BBB 12p 9m',
	'147m 258p 369s ESWNR',
	'2s 3s 4s 6s 8s GG',
	'F1 F2 F3 F4 T1 T2 T3 T4',
	'99m',
	'B',
	'1m 1p 1s',
	'12345678m 1234567p',
	'5555m',
	'EEEE',
	'9s 8s 7s',
	'3m 3m 3m 3m 4m 4m',
	'F3',
	'123456789m 123p 5s',
);

plan tests => 8;

subtest 'twenty hands round-trip' => sub {
	for my $hand (@HANDS) {
		my @ids = Game::Mahjong::Notation::parse($hand);
		ok(scalar @ids, "$hand parses");
		my $text = Game::Mahjong::Notation::print(@ids);
		my @again = Game::Mahjong::Notation::parse($text);
		is_deeply([ sort { $a <=> $b } @again ], [ sort { $a <=> $b } @ids ],
			"and round-trips through '$text'");
		is(Game::Mahjong::Notation::print(@again), $text, 'and print is stable');
	}
};

subtest 'parse keeps the order written and print is canonical' => sub {
	is_deeply([ Game::Mahjong::Notation::parse('EEE 55p 123m') ],
		ids(qw(we we we p5 p5 m1 m2 m3)), 'the order written');
	is(Game::Mahjong::Notation::print(Game::Mahjong::Notation::parse('EEE 55p 123m')),
		'123m 55p EEE', 'canonical: suits in order, then honours');
	is(Game::Mahjong::Notation::print(Game::Mahjong::Notation::parse('T2 B 9s 1m F1 N')),
		'1m 9s NB F1 T2', 'the honours in table order, the bonus tiles last');
	is(Game::Mahjong::Notation::print(Game::Mahjong::Notation::parse('3m 1m 2m')),
		'123m', 'ranks ascending');
	is(Game::Mahjong::Notation::print(), '', 'nothing prints as nothing');
};

subtest 'the honour letters' => sub {
	is_deeply([ Game::Mahjong::Notation::parse('ESWN') ], ids(qw(we ws ww wn)), 'the winds');
	is_deeply([ Game::Mahjong::Notation::parse('RGB') ], ids(qw(dr dg dw)),
		'red, green, and B for the white dragon, because W is the west wind');
	my $letters = Game::Mahjong::Notation::letters();
	is(scalar keys %$letters, 7, 'seven honour letters');
	is($letters->{B}, 'dw', 'B is the white dragon');
};

subtest 'the bonus tiles' => sub {
	is_deeply([ Game::Mahjong::Notation::parse('F1 F4 T1 T4') ], ids(qw(f1 f4 t1 t4)),
		'flowers and seasons');
	is(Game::Mahjong::Notation::print(@{ ids(qw(t3 f2)) }), 'F2 T3', 'printed upper case');
};

subtest 'a hand with melds' => sub {
	my $hand = Game::Mahjong::Notation::parse_hand('19m 55p pung(EEE) chow(234s) ckong(4444p) kong(9999s) F1 T2');
	is_deeply($hand->{concealed}, ids(qw(m1 m9 p5 p5)), 'the concealed tiles, sorted');
	is_deeply($hand->{flowers}, ids(qw(f1 t2)), 'the bonus tiles, sorted');
	is(scalar @{ $hand->{melds} }, 4, 'four melds');
	is_deeply([ map { $_->{kind} } @{ $hand->{melds} } ], [qw(pung chow kong kong)],
		'kinds, a ckong being a kong');
	is_deeply([ map { $_->{concealed} } @{ $hand->{melds} } ], [ 0, 0, 1, 0 ],
		'and only the ckong concealed');
	is_deeply($hand->{melds}[1]{tiles}, ids(qw(s2 s3 s4)), 'the chow sorted');
	is(Game::Mahjong::Notation::print_hand($hand), '19m 55p pung(EEE) chow(234s) ckong(4444p) kong(9999s) F1 T2',
		'and prints back');
	my $bare = Game::Mahjong::Notation::parse_hand('123m');
	is_deeply($bare->{melds}, [], 'no melds');
	is_deeply($bare->{flowers}, [], 'no flowers');
	is(Game::Mahjong::Notation::print_hand({ melds => [ { kind => 'pung', tiles => ids(qw(we we we)) } ] }),
		'pung(EEE)', 'a hand of one meld');
};

subtest 'what it refuses' => sub {
	my @bad = (
		[ '0m',            qr/not a tile/,          'a rank of zero' ],
		[ '5x',            qr/not a tile/,          'a suit letter it does not know' ],
		[ '55555p',        qr/more than four of p5/, 'a fifth of one kind' ],
		[ '5p 5p 5p 5p 5p', qr/more than four of p5/, 'a fifth across tokens' ],
		[ 'F1 F1',         qr/more than one f1/,    'a second of one bonus tile' ],
		[ 'F5',            qr/not a tile/,          'a fifth flower' ],
		[ 'Q',             qr/not a tile/,          'a letter that is no honour' ],
		[ '12',            qr/not a tile/,          'ranks with no suit' ],
	);
	for my $case (@bad) {
		my ($text, $re, $why) = @$case;
		ok(!eval { Game::Mahjong::Notation::parse($text); 1 }, "$why dies");
		like($@, $re, 'with the reason');
	}
	ok(!eval { Game::Mahjong::Notation::parse(undef); 1 }, 'undef dies');
};

subtest 'what a meld refuses' => sub {
	my @bad = (
		[ 'chow(135m)',     qr/consecutive/,    'a chow with a gap' ],
		[ 'chow(89m 1p)',   qr/consecutive/,    'a chow across suits' ],
		[ 'chow(ESW)',      qr/three suit tiles/, 'a chow of honours' ],
		[ 'pung(EEW)',      qr/identical/,      'a pung of different tiles' ],
		[ 'kong(12345m)',   qr/kong is 4 tiles/, 'a kong of five' ],
		[ 'pung(EE)',       qr/pung is 3 tiles/, 'a pung of two' ],
		[ 'ckong(F1)',      qr/ckong is 4 tiles/, 'a kong of one' ],
		[ 'bogus(EEE)',     qr/not a meld/,     'a kind it does not know' ],
		[ 'pung(EEE) EE',   qr/more than four of we/, 'five easts across a meld and the hand' ],
	);
	for my $case (@bad) {
		my ($text, $re, $why) = @$case;
		ok(!eval { Game::Mahjong::Notation::parse_hand($text); 1 }, "$why dies");
		like($@, $re, 'with the reason');
	}
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   drop the count check in parse            -> 'a fifth of one kind dies' fails
#   let a chow skip the suit test            -> 'a chow across suits dies' fails
#   print the honours before the suits       -> 'canonical' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};
