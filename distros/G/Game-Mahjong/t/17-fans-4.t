#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);
my $PLAIN = '123m 456p 789s 111s 55m';

plan tests => 4;

subtest 'outside hand' => sub {
	FanCheck::has_fan('123m 789p 111s EEE 99m', 'outside_hand', 'a terminal or honour in every set and the pair', %C);
	FanCheck::lacks_fan('123m 789p 111s EEE 55m', 'outside_hand', 'a pair of fives', %C);
	FanCheck::lacks_fan('234m 789p 111s EEE 99m', 'outside_hand', 'a 2-3-4', %C);
};

subtest 'fully concealed hand' => sub {
	FanCheck::has_fan($PLAIN, 'fully_concealed_hand', 'no melds, self-drawn', %C, by => 'self');
	FanCheck::lacks_fan($PLAIN, 'fully_concealed_hand', 'won by discard is concealed hand instead', %C, by => 'discard');
	FanCheck::lacks_fan('123m 456p 789s 55m pung(111s)', 'fully_concealed_hand', 'a claimed pung', %C, by => 'self');
	FanCheck::has_fan('123m 456p 789s 55m ckong(1111s)', 'fully_concealed_hand', 'a concealed kong keeps it concealed', %C, by => 'self');
};

subtest 'two melded kongs' => sub {
	my $f = FanCheck::has_fan('kong(1111m) kong(2222p) 333s 456s 99p', 'two_melded_kongs', 'two melded kongs', %C);
	my $h = FanCheck::hand('kong(1111m) ckong(2222p) 333s 456s 99p');
	my ($split) = Game::Mahjong::Decompose::decompose($h);
	my $found = Game::Mahjong::Fans::check_all($split, \%C);
	ok($found->{two_melded_kongs}, 'one melded and one concealed is the fan too');
	is($found->{two_melded_kongs}[0]{points}, 6, 'at six points, the sentence in the parentheses');
	FanCheck::lacks_fan('kong(1111m) 222p 333s 456s 99p', 'two_melded_kongs', 'one kong', %C);
	FanCheck::lacks_fan('ckong(1111m) ckong(2222p) 333s 456s 99p', 'two_melded_kongs', 'two concealed is its own fan', %C);
};

subtest 'last tile' => sub {
	FanCheck::has_fan($PLAIN, 'last_tile', 'the last of its kind, visible to all', %C, last_tile => 1);
	FanCheck::lacks_fan($PLAIN, 'last_tile', 'not the last', %C);
};
