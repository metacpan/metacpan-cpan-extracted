#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 3;

subtest 'four pure shifted chows' => sub {
	FanCheck::has_fan('123m 234m 345m 456m 99p', 'four_pure_shifted_chows', 'shifted by one', %C);
	FanCheck::has_fan('123m 345m 567m 789m 99p', 'four_pure_shifted_chows', 'shifted by two', %C);
	FanCheck::lacks_fan('123m 234m 456m 567m 99p', 'four_pure_shifted_chows', 'a combination of both', %C);
	FanCheck::lacks_fan('123m 234m 345m 456p 99p', 'four_pure_shifted_chows', 'one in another suit', %C);
};

subtest 'three kongs' => sub {
	FanCheck::has_fan('kong(1111m) kong(2222p) ckong(3333s) 444s 55m', 'three_kongs', 'three kongs', %C);
	FanCheck::lacks_fan('kong(1111m) kong(2222p) 333s 444s 55m', 'three_kongs', 'two kongs', %C);
	FanCheck::lacks_fan('kong(1111m) kong(2222p) ckong(3333s) kong(EEEE) 55m', 'three_kongs', 'four kongs is its own fan', %C);
};

subtest 'all terminals and honours' => sub {
	FanCheck::has_fan('111m 999p EEE RRR 11s', 'all_terminals_and_honours', 'ones, nines, winds and dragons', %C);
	FanCheck::lacks_fan('111m 999p EEE RRR 55s', 'all_terminals_and_honours', 'a pair of fives', %C);
	FanCheck::lacks_fan('19m 19p 19s ESWN RGB E', 'all_terminals_and_honours', 'thirteen orphans is its own fan', %C);
};
