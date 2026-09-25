#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 9;

subtest 'seven pairs' => sub {
	FanCheck::has_fan('11p 33p 55p 77p 99p EE SS', 'seven_pairs', 'seven pairs', %C);
	FanCheck::lacks_fan('EEE SSS WWW NNN 55m', 'seven_pairs', 'a pung hand', %C);
};

subtest 'greater honours and knitted tiles' => sub {
	FanCheck::has_fan('147m 36p 25s ESWN RGB', 'greater_honours_and_knitted_tiles', 'all seven honours and seven knitted singles', %C);
	FanCheck::lacks_fan('147m 258p 369s ESWN R', 'greater_honours_and_knitted_tiles', 'five honours is the lesser hand', %C);
};

subtest 'all even pungs' => sub {
	FanCheck::has_fan('222m 444p 666s 888m 22p', 'all_even_pungs', 'pungs of 2 4 6 8 and a pair of twos', %C);
	FanCheck::lacks_fan('222m 444p 666s 888m 33p', 'all_even_pungs', 'a pair of threes', %C);
	FanCheck::lacks_fan('222m 444p 666s 88m 888p', 'all_even_pungs', 'still even: yes, this one has it too, four pungs and an even pair') if 0;
	FanCheck::lacks_fan('222m 444p 666s EEE 88m', 'all_even_pungs', 'a pung of winds', %C);
};

subtest 'full flush' => sub {
	FanCheck::has_fan('123m 456m 789m 111m 55m', 'full_flush', 'one suit', %C);
	FanCheck::has_fan('11m 33m 55m 77m 99m 22m 88m', 'full_flush', 'seven pairs of one suit', %C);
	FanCheck::lacks_fan('123m 456m 789m EEE 55m', 'full_flush', 'honours make it a half flush', %C);
};

subtest 'pure triple chow' => sub {
	FanCheck::has_fan('123m 123m 123m 456p 99s', 'pure_triple_chow', 'three identical chows', %C);
	FanCheck::lacks_fan('123m 123m 234m 456p 99s', 'pure_triple_chow', 'two identical and one shifted', %C);
};

subtest 'pure shifted pungs' => sub {
	FanCheck::has_fan('111m 222m 333m 456p 99s', 'pure_shifted_pungs', 'pungs of 1 2 3 of characters', %C);
	FanCheck::lacks_fan('111m 222m 444m 456p 99s', 'pure_shifted_pungs', 'a gap', %C);
	FanCheck::lacks_fan('111m 222m 333p 456p 99s', 'pure_shifted_pungs', 'the third in another suit', %C);
};

subtest 'upper tiles' => sub {
	FanCheck::has_fan('789m 789p 777s 999s 88m', 'upper_tiles', 'sevens, eights and nines only', %C);
	FanCheck::lacks_fan('789m 789p 777s 999s 66m', 'upper_tiles', 'a pair of sixes', %C);
};

subtest 'middle tiles' => sub {
	FanCheck::has_fan('456m 456p 444s 666s 55m', 'middle_tiles', 'fours, fives and sixes only', %C);
	FanCheck::lacks_fan('456m 456p 444s 666s 77m', 'middle_tiles', 'a pair of sevens', %C);
};

subtest 'lower tiles' => sub {
	FanCheck::has_fan('123m 123p 111s 333s 22m', 'lower_tiles', 'ones, twos and threes only', %C);
	FanCheck::lacks_fan('123m 123p 111s 333s 44m', 'lower_tiles', 'a pair of fours', %C);
};
