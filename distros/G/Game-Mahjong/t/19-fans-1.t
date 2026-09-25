#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);
my $PLAIN = '123m 456p 789s 111s 55m';

plan tests => 13;

subtest 'pure double chow' => sub {
	FanCheck::times_of('123m 123m 456p 789s 99p', 'pure_double_chow', 1, 'two identical chows', %C);
	FanCheck::times_of('123m 123m 456p 456p 99s', 'pure_double_chow', 2, 'two pairs of them', %C);
	FanCheck::lacks_fan('123m 234m 456p 789s 99p', 'pure_double_chow', 'shifted', %C);
};

subtest 'mixed double chow' => sub {
	FanCheck::times_of('123m 123p 456s 789s 99p', 'mixed_double_chow', 1, 'the same chow in two suits', %C);
	FanCheck::lacks_fan('123m 234p 456s 789s 99p', 'mixed_double_chow', 'different chows', %C);
};

subtest 'short straight' => sub {
	FanCheck::times_of('123m 456m 789p 111s 99p', 'short_straight', 1, '1-2-3 and 4-5-6 of one suit', %C);
	FanCheck::lacks_fan('123m 567m 789p 111s 99p', 'short_straight', 'a gap', %C);
	FanCheck::lacks_fan('123m 456p 789s 111s 99p', 'short_straight', 'different suits', %C);
};

subtest 'two terminal chows' => sub {
	FanCheck::times_of('123m 789m 456p 111s 99p', 'two_terminal_chows', 1, '1-2-3 and 7-8-9 of one suit', %C);
	FanCheck::lacks_fan('123m 678m 456p 111s 99p', 'two_terminal_chows', '6-7-8 is not terminal', %C);
	FanCheck::lacks_fan('123m 789p 456p 111s 99s', 'two_terminal_chows', 'different suits', %C);
};

subtest 'pung of terminals or honours' => sub {
	FanCheck::times_of('111m 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 1, 'a pung of ones', %C);
	FanCheck::times_of('111m 999p 456s 789s 22p', 'pung_of_terminals_or_honours', 2, 'ones and nines', %C);
	FanCheck::times_of('NNN 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 1, 'a pung of north, neither prevalent nor seat', %C);
	FanCheck::lacks_fan('EEE 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 'east in the east round scores prevalent wind instead', %C, prevailing => 0);
	FanCheck::lacks_fan('SSS 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 'south for the south seat scores seat wind instead', %C, seat => 1);
	FanCheck::lacks_fan('RRR 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 'a dragon pung is two points, not this', %C);
	FanCheck::lacks_fan('555m 234p 456s 789s 99p', 'pung_of_terminals_or_honours', 'a pung of fives', %C);
};

subtest 'melded kong' => sub {
	FanCheck::times_of('kong(1111m) 234p 456s 789s 99p', 'melded_kong', 1, 'a claimed kong', %C);
	FanCheck::lacks_fan('ckong(1111m) 234p 456s 789s 99p', 'melded_kong', 'a concealed kong', %C);
};

subtest 'one voided suit' => sub {
	FanCheck::has_fan('123m 456m 789p 111p 99p', 'one_voided_suit', 'characters and dots, no bamboo', %C);
	FanCheck::lacks_fan($PLAIN, 'one_voided_suit', 'three suits', %C);
	FanCheck::lacks_fan('123m 456m 789m 111m 55m', 'one_voided_suit', 'one suit is a full flush, which implies it', %C);
};

subtest 'no honours' => sub {
	FanCheck::has_fan($PLAIN, 'no_honours', 'suit tiles only', %C);
	FanCheck::lacks_fan('123m 456p 789s EEE 55m', 'no_honours', 'a pung of east', %C);
};

subtest 'edge wait' => sub {
	FanCheck::has_fan($PLAIN, 'edge_wait', 'the 3 of 1-2-3, the only wait', %C, winning => 'm3', waits => ['m3']);
	FanCheck::has_fan($PLAIN, 'edge_wait', 'the 7 of 7-8-9', %C, winning => 's7', waits => ['s7']);
	FanCheck::lacks_fan($PLAIN, 'edge_wait', 'the 3 when the 6 was also a wait', %C, winning => 'm3', waits => ['m3', 'm6']);
	FanCheck::lacks_fan($PLAIN, 'edge_wait', 'the 1 of 1-2-3 is two-sided', %C, winning => 'm1', waits => ['m1']);
};

subtest 'closed wait' => sub {
	FanCheck::has_fan($PLAIN, 'closed_wait', 'the 2 of 1-2-3, the only wait', %C, winning => 'm2', waits => ['m2']);
	FanCheck::lacks_fan($PLAIN, 'closed_wait', 'the 2 with another wait', %C, winning => 'm2', waits => ['m2', 'm5']);
	FanCheck::lacks_fan($PLAIN, 'closed_wait', 'the 5 of 4-5-6 when the hand waited on it alone', %C, winning => 'p5', waits => ['p5']) if 0;
	FanCheck::has_fan($PLAIN, 'closed_wait', 'the 5 of 4-5-6', %C, winning => 'p5', waits => ['p5']);
};

subtest 'single wait' => sub {
	FanCheck::has_fan($PLAIN, 'single_wait', 'the second 5 to pair, the only wait', %C, winning => 'm5', waits => ['m5']);
	FanCheck::lacks_fan($PLAIN, 'single_wait', 'the 5 when the 2 was a wait too', %C, winning => 'm5', waits => ['m5', 'm2']);
	FanCheck::has_fan('19m 19p 19s ESWN RGB E', 'single_wait', 'thirteen orphans won on a single', %C, winning => 'm1', waits => ['m1']);
};

subtest 'self-drawn' => sub {
	FanCheck::has_fan($PLAIN, 'self_drawn', 'drawn from the wall', %C, by => 'self');
	FanCheck::lacks_fan($PLAIN, 'self_drawn', 'claimed', %C, by => 'discard');
	FanCheck::lacks_fan($PLAIN, 'self_drawn', 'robbed', %C, by => 'rob');
};

subtest 'flower tiles' => sub {
	FanCheck::times_of($PLAIN, 'flower_tiles', 3, 'three flowers exposed', %C, flowers => 3);
	FanCheck::lacks_fan($PLAIN, 'flower_tiles', 'none', %C);
};
