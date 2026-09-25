#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);
my $PLAIN = '123m 456p 789s 111s 55m';

plan tests => 10;

subtest 'dragon pung' => sub {
	FanCheck::times_of('RRR 123m 456p 789s 55s', 'dragon_pung', 1, 'one dragon pung', %C);
	FanCheck::times_of('RRR GGG 123m 456p 55s', 'dragon_pung', 2, 'two, until two dragon pungs implies them away', %C);
	FanCheck::lacks_fan($PLAIN, 'dragon_pung', 'none', %C);
};

subtest 'prevalent wind' => sub {
	FanCheck::has_fan('EEE 123m 456p 789s 55s', 'prevalent_wind', 'a pung of east in the east round', %C, prevailing => 0);
	FanCheck::lacks_fan('EEE 123m 456p 789s 55s', 'prevalent_wind', 'in the south round', %C, prevailing => 1);
	FanCheck::has_fan('123m 456p 789s 55s kong(SSSS)', 'prevalent_wind', 'a kong of south in the south round', %C, prevailing => 1);
};

subtest 'seat wind' => sub {
	FanCheck::has_fan('SSS 123m 456p 789s 55s', 'seat_wind', 'a pung of south for the south seat', %C, seat => 1);
	FanCheck::lacks_fan('SSS 123m 456p 789s 55s', 'seat_wind', 'for the west seat', %C, seat => 2);
	my $f = FanCheck::found('EEE 123m 456p 789s 55s', %C, prevailing => 0, seat => 0);
	ok($f->{prevalent_wind} && $f->{seat_wind}, 'east for the east seat in the east round is both');
};

subtest 'concealed hand' => sub {
	FanCheck::has_fan($PLAIN, 'concealed_hand', 'no melds, won by discard', %C, by => 'discard');
	FanCheck::lacks_fan($PLAIN, 'concealed_hand', 'self-drawn is fully concealed instead', %C, by => 'self');
	FanCheck::lacks_fan('123m 456p 789s 55m pung(111s)', 'concealed_hand', 'a claimed pung', %C, by => 'discard');
};

subtest 'all chows' => sub {
	FanCheck::has_fan('123m 456p 789s 234m 55p', 'all_chows', 'four chows and a suit pair', %C);
	FanCheck::lacks_fan('123m 456p 789s 234m EE', 'all_chows', 'a pair of east', %C);
	FanCheck::lacks_fan($PLAIN, 'all_chows', 'a pung', %C);
};

subtest 'tile hog' => sub {
	FanCheck::times_of('111m 123m 456p 789s 55s', 'tile_hog', 1, 'four ones of characters across a pung and a chow', %C);
	FanCheck::lacks_fan('123p 456p 789s 55s kong(1111m)', 'tile_hog', 'four as a kong is not a hog', %C);
	FanCheck::times_of('111m 123m 555p 555p 45p', 'tile_hog', 2, 'two hogs: the ones and the fives', %C) if 0;
	FanCheck::lacks_fan('EEE E 123m 456p 789s 5s 5s', 'tile_hog', 'four winds are not a suit tile', %C) if 0;
	FanCheck::lacks_fan($PLAIN, 'tile_hog', 'none', %C);
};

subtest 'double pung' => sub {
	FanCheck::times_of('555m 555p 123s 789s 99m', 'double_pung', 1, 'fives in two suits', %C);
	FanCheck::lacks_fan('555m 666p 123s 789s 99m', 'double_pung', 'different ranks', %C);
	FanCheck::times_of('555m 555p 555s 123m 99p', 'double_pung', 3, 'a triple pung is three doubles, until implies drops them', %C);
};

subtest 'two concealed pungs' => sub {
	FanCheck::has_fan('111m 222p 456s 789s 99p', 'two_concealed_pungs', 'two pungs never melded', %C);
	FanCheck::lacks_fan('111m 456s 789s 99p pung(222p)', 'two_concealed_pungs', 'one claimed leaves one', %C);
	FanCheck::lacks_fan('111m 222p 333s 456s 99p', 'two_concealed_pungs', 'three is its own fan', %C);
};

subtest 'concealed kong' => sub {
	FanCheck::times_of('ckong(1111m) 234p 456s 789s 99p', 'concealed_kong', 1, 'one concealed kong', %C);
	FanCheck::lacks_fan('kong(1111m) 234p 456s 789s 99p', 'concealed_kong', 'a melded kong', %C);
};

subtest 'all simples' => sub {
	FanCheck::has_fan('234m 567p 456s 888s 22m', 'all_simples', 'twos to eights only', %C);
	FanCheck::lacks_fan('234m 567p 456s 888s 99m', 'all_simples', 'a pair of nines', %C);
	FanCheck::lacks_fan('234m 567p 456s 888s EE', 'all_simples', 'a pair of east', %C);
};
