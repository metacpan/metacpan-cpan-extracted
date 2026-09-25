#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 6;

subtest 'all terminals' => sub {
	FanCheck::has_fan('111m 999m 111p 999s 99p', 'all_terminals', 'pungs and a pair of ones and nines', %C);
	FanCheck::lacks_fan('111m 999m 111p 999s EE', 'all_terminals', 'a pair of east is all terminals and honours instead', %C);
};

subtest 'little four winds' => sub {
	FanCheck::has_fan('EEE SSS WWW NN 555m', 'little_four_winds', 'three wind pungs and the fourth as the pair', %C);
	FanCheck::lacks_fan('EEE SSS WWW NNN 55m', 'little_four_winds', 'four pungs is big four winds', %C);
	FanCheck::lacks_fan('EEE SSS WWW 55m 555p', 'little_four_winds', 'three pungs with a suit pair is big three winds', %C);
};

subtest 'little three dragons' => sub {
	FanCheck::has_fan('RRR GGG BB 123m 555p', 'little_three_dragons', 'two dragon pungs and the third as the pair', %C);
	FanCheck::lacks_fan('RRR GGG 123m 555p 55s', 'little_three_dragons', 'two dragon pungs with a suit pair', %C);
};

subtest 'all honours' => sub {
	FanCheck::has_fan('EEE SSS RRR GGG NN', 'all_honours', 'winds and dragons only', %C);
	FanCheck::lacks_fan('EEE SSS RRR GGG 11m', 'all_honours', 'a pair of ones', %C);
};

subtest 'four concealed pungs' => sub {
	FanCheck::has_fan('111m 222p 333s EEE 55m', 'four_concealed_pungs', 'four pungs never melded', %C);
	FanCheck::lacks_fan('111m 222p 333s 55m pung(EEE)', 'four_concealed_pungs', 'one claimed pung leaves three concealed', %C);
	FanCheck::has_fan('111m 222p 333s 55m ckong(EEEE)', 'four_concealed_pungs', 'a concealed kong is a concealed pung', %C);
};

subtest 'pure terminal chows' => sub {
	FanCheck::has_fan('123m 123m 789m 789m 55m', 'pure_terminal_chows', 'two each of the terminal chows and a pair of fives, one suit', %C);
	FanCheck::lacks_fan('123m 123m 789m 789m 55p', 'pure_terminal_chows', 'the pair in another suit', %C);
	FanCheck::lacks_fan('123m 123m 789m 789m 66m', 'pure_terminal_chows', 'a pair of sixes', %C);
};
