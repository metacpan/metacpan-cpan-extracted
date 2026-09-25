#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 6;

subtest 'all pungs' => sub {
	FanCheck::has_fan('111m 222p 333s EEE 55m', 'all_pungs', 'four pungs and a pair', %C);
	FanCheck::has_fan('111m 222p 55m kong(3333s) pung(EEE)', 'all_pungs', 'kongs count', %C);
	FanCheck::lacks_fan('123m 222p 333s EEE 55m', 'all_pungs', 'a chow', %C);
};

subtest 'half flush' => sub {
	FanCheck::has_fan('123m 456m 789m EEE 55m', 'half_flush', 'one suit and honours', %C);
	FanCheck::lacks_fan('123m 456m 789m 111m 55m', 'half_flush', 'one suit and no honours is a full flush', %C);
	FanCheck::lacks_fan('123m 456p 789m EEE 55m', 'half_flush', 'two suits', %C);
};

subtest 'mixed shifted chows' => sub {
	FanCheck::has_fan('123m 234p 345s 111m 55p', 'mixed_shifted_chows', '1-2-3, 2-3-4, 3-4-5 in three suits', %C);
	FanCheck::lacks_fan('123m 234p 456s 111m 55p', 'mixed_shifted_chows', 'a gap', %C);
	FanCheck::lacks_fan('123m 234m 345s 111p 55p', 'mixed_shifted_chows', 'two in one suit', %C);
};

subtest 'all types' => sub {
	FanCheck::has_fan('123m 456p 789s EEE RR', 'all_types', 'characters, dots, bamboo, a wind and a dragon', %C);
	FanCheck::has_fan('11m 22p 33s EE RR SS GG', 'all_types', 'seven pairs covering the five types', %C);
	FanCheck::lacks_fan('123m 456p 789s EEE 55m', 'all_types', 'no dragon', %C);
	FanCheck::lacks_fan('147m 36p 25s ESWN RGB', 'all_types', 'not for the honours and knitted hand', %C);
};

subtest 'melded hand' => sub {
	my $h = '55m chow(123m) pung(444p) pung(777s) kong(EEEE)';
	FanCheck::has_fan($h, 'melded_hand', 'four melds and the pair completed by a discard', %C, winning => 'm5', waits => ['m5']);
	FanCheck::lacks_fan($h, 'melded_hand', 'self-drawn', %C, by => 'self', winning => 'm5');
	FanCheck::lacks_fan('55m chow(123m) pung(444p) pung(777s) ckong(EEEE)', 'melded_hand', 'a concealed kong was not completed by a discard', %C, winning => 'm5');
};

subtest 'two dragon pungs' => sub {
	FanCheck::has_fan('RRR GGG 123m 456p 55s', 'two_dragon_pungs', 'two dragon pungs', %C);
	FanCheck::lacks_fan('RRR 123m 456p 789s 55s', 'two_dragon_pungs', 'one', %C);
	FanCheck::lacks_fan('RRR GGG BBB 123m 55p', 'two_dragon_pungs', 'three is big three dragons', %C);
};
