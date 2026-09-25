#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 6;

subtest 'pure straight' => sub {
	FanCheck::has_fan('123m 456m 789m 111p 55s', 'pure_straight', '1 to 9 in three chows of one suit', %C);
	FanCheck::lacks_fan('123m 456m 789p 111p 55s', 'pure_straight', 'the third chow in another suit', %C);
};

subtest 'three-suited terminal chows' => sub {
	FanCheck::has_fan('123m 789m 123p 789p 55s', 'three_suited_terminal_chows', 'terminal chows in two suits and a pair of fives in the third', %C);
	FanCheck::lacks_fan('123m 789m 123p 789p 55m', 'three_suited_terminal_chows', 'the pair in a chow suit', %C);
	FanCheck::lacks_fan('123m 789m 123p 789p 66s', 'three_suited_terminal_chows', 'a pair of sixes', %C);
};

subtest 'pure shifted chows' => sub {
	FanCheck::has_fan('123m 234m 345m 111p 55s', 'pure_shifted_chows', 'shifted by one', %C);
	FanCheck::has_fan('123m 345m 567m 111p 55s', 'pure_shifted_chows', 'shifted by two', %C);
	FanCheck::lacks_fan('123m 234m 456m 111p 55s', 'pure_shifted_chows', 'a combination of both', %C);
};

subtest 'all fives' => sub {
	FanCheck::has_fan('345m 456p 567s 555m 55p', 'all_fives', 'every set and the pair hold a five', %C);
	FanCheck::lacks_fan('345m 456p 567s 555m 66p', 'all_fives', 'a pair of sixes', %C);
	FanCheck::lacks_fan('345m 456p 678s 555m 55p', 'all_fives', 'a 6-7-8 has no five', %C);
};

subtest 'triple pung' => sub {
	FanCheck::has_fan('555m 555p 555s 123m 99p', 'triple_pung', 'pungs of five in every suit', %C);
	FanCheck::lacks_fan('555m 555p 666s 123m 99p', 'triple_pung', 'two of a rank is a double pung', %C);
};

subtest 'three concealed pungs' => sub {
	FanCheck::has_fan('111m 222p 333s 456s 99p', 'three_concealed_pungs', 'three pungs never melded', %C);
	FanCheck::lacks_fan('111m 222p 456s 99p pung(333s)', 'three_concealed_pungs', 'one claimed leaves two', %C);
	FanCheck::lacks_fan('111m 222p 333s EEE 99p', 'three_concealed_pungs', 'four concealed is its own fan', %C);
};
