#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FanCheck;

my %C = (by => 'discard', prevailing => 0, seat => 1);

plan tests => 2;

subtest 'quadruple chow' => sub {
	FanCheck::has_fan('123m 123m 123m 123m 55p', 'quadruple_chow', 'four identical chows', %C);
	FanCheck::lacks_fan('123m 123m 123m 234m 55p', 'quadruple_chow', 'three identical and one shifted', %C);
};

subtest 'four pure shifted pungs' => sub {
	FanCheck::has_fan('111m 222m 333m 444m 55p', 'four_pure_shifted_pungs', 'pungs of 1 2 3 4 of characters', %C);
	FanCheck::lacks_fan('111m 222m 333m 555m 55p', 'four_pure_shifted_pungs', 'a gap at the four', %C);
	FanCheck::lacks_fan('111m 222m 333m 444p 55p', 'four_pure_shifted_pungs', 'the fourth in another suit', %C);
};
