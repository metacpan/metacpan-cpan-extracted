#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 5;

subtest 'lesser honours and knitted tiles' => sub {
	FanCheck::has_fan('147m 258p 369s ESWN R', 'lesser_honours_and_knitted_tiles', 'five honours and nine knitted singles', %C);
	FanCheck::has_fan('147m 36p 25s ESWN RGB', 'lesser_honours_and_knitted_tiles', 'the greater hand has the lesser too, until implies drops it', %C);
	FanCheck::lacks_fan('123m 456p 789s 111s 55m', 'lesser_honours_and_knitted_tiles', 'a standard hand', %C);
};

subtest 'knitted straight' => sub {
	FanCheck::has_fan('147m 258p 369s 111m 55p', 'knitted_straight', 'three knitted sequences, a pung and a pair', %C);
	FanCheck::has_fan('147m 258p 369s 55m pung(EEE)', 'knitted_straight', 'with a melded pung', %C);
	FanCheck::lacks_fan('123m 456p 789s 111s 55m', 'knitted_straight', 'a real straight', %C);
};

subtest 'upper four' => sub {
	FanCheck::has_fan('678m 789p 666s 999s 77m', 'upper_four', 'sixes to nines', %C);
	FanCheck::lacks_fan('678m 789p 666s 999s 55m', 'upper_four', 'a pair of fives', %C);
};

subtest 'lower four' => sub {
	FanCheck::has_fan('123m 234p 111s 444s 22m', 'lower_four', 'ones to fours', %C);
	FanCheck::lacks_fan('123m 234p 111s 444s 55m', 'lower_four', 'a pair of fives', %C);
};

subtest 'big three winds' => sub {
	FanCheck::has_fan('EEE SSS WWW 123m 55p', 'big_three_winds', 'three wind pungs', %C);
	FanCheck::lacks_fan('EEE SSS 123m 456p 55p', 'big_three_winds', 'two wind pungs', %C);
};
