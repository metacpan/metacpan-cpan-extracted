#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

# Every vector is fourteen tiles' worth, written by hand from the rulebook's
# sentence; FanCheck dies on any other count. The context defaults to a win by
# discard with the prevalent wind east and the seat wind south.
my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 8;

subtest 'the table' => sub {
	my @fans = Game::Mahjong::Fans::all();
	is(scalar @fans, 81, 'eighty-one fans');
	is(Game::Mahjong::Fans::COUNT, 81, 'and COUNT says so');
	is_deeply([ map { $_->n } @fans ], [ 1 .. 81 ], 'numbered 1 to 81 in order');
	my %per;
	$per{ $_->points }++ for @fans;
	is_deeply(\%per, \%Game::Mahjong::Fans::PER_GRADE, 'the twelve grades hold what 3.8.1 says: 7 6 2 3 9 6 5 10 6 4 10 13');
	is_deeply([ sort { $b <=> $a } keys %per ], \@Game::Mahjong::Fans::GRADES, 'the grades are 88 to 1');
	my %key;
	$key{ $_->key }++ for @fans;
	is(scalar keys %key, 81, 'eighty-one distinct keys');
	my %name;
	$name{ $_->name }++ for @fans;
	is(scalar keys %name, 81, 'eighty-one distinct names');
	for my $fan (@fans) {
		for my $ref (@{ $fan->excludes }, @{ $fan->implies }) {
			ok($key{$ref}, $fan->key . " names $ref, which exists");
		}
		ok(length $fan->says > 20, $fan->key . ' has a sentence');
	}
	is(Game::Mahjong::Fans::by_key('all_pungs')->points, 6, 'by_key');
	is(Game::Mahjong::Fans::by_n(41)->key, 'mixed_triple_chow', 'by_n');
	ok(!eval { Game::Mahjong::Fans::by_key('bogus'); 1 }, 'an unknown key dies');
	is(Game::Mahjong::Fans::by_key('chicken_hand')->special, 'chicken', 'chicken hand is special');
};

subtest 'big four winds' => sub {
	FanCheck::has_fan('EEE SSS WWW NNN 55m', 'big_four_winds', 'pungs of all four winds', %C);
	FanCheck::lacks_fan('EEE SSS WWW NN 555m', 'big_four_winds', 'three pungs and a pair is little four winds', %C);
};

subtest 'big three dragons' => sub {
	FanCheck::has_fan('RRR GGG BBB 123m 55p', 'big_three_dragons', 'pungs of all three dragons', %C);
	FanCheck::lacks_fan('RRR GGG BB 123m 555p', 'big_three_dragons', 'two pungs and a pair is little three dragons', %C);
};

subtest 'all green' => sub {
	FanCheck::has_fan('222s 333s 444s GGG 66s', 'all_green', '2 3 4 6 of bamboo and the green dragon', %C);
	FanCheck::lacks_fan('222s 333s 444s GGG 55s', 'all_green', 'a five of bamboo is not green', %C);
};

subtest 'nine gates' => sub {
	FanCheck::has_fan('11123455678999m', 'nine_gates', '1112345678999 won on the 5', %C, winning => 'm5');
	FanCheck::has_fan('11112345678999m', 'nine_gates', 'and won on the 1', %C, winning => 'm1');
	FanCheck::lacks_fan('11123455678999m', 'nine_gates', 'the thirteen before a 1 were not the pattern', %C, winning => 'm1');
	FanCheck::lacks_fan('11123455678999m', 'nine_gates', 'no winning tile named, no nine gates', %C);
};

subtest 'four kongs' => sub {
	FanCheck::has_fan('kong(1111m) kong(2222p) ckong(3333s) kong(EEEE) 55m', 'four_kongs', 'four kongs, one concealed', %C);
	FanCheck::lacks_fan('kong(1111m) kong(2222p) ckong(3333s) 444s 55m', 'four_kongs', 'three kongs', %C);
};

subtest 'seven shifted pairs' => sub {
	FanCheck::has_fan('11223344556677m', 'seven_shifted_pairs', 'pairs of 1 to 7 of characters', %C);
	FanCheck::lacks_fan('11223344556688m', 'seven_shifted_pairs', 'a gap: seven pairs but not shifted', %C);
	FanCheck::lacks_fan('11m 22p 33s 44m 55p 66s 77m', 'seven_shifted_pairs', 'three suits', %C);
};

subtest 'thirteen orphans' => sub {
	FanCheck::has_fan('19m 19p 19s ESWN RGB E', 'thirteen_orphans', 'the thirteen with a second east', %C);
	FanCheck::lacks_fan('EEE SSS WWW NNN 11m', 'thirteen_orphans', 'a pung hand', %C);
};
