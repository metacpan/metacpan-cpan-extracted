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

subtest 'mixed straight' => sub {
	FanCheck::has_fan('123m 456p 789s 111m 55p', 'mixed_straight', '1-2-3, 4-5-6, 7-8-9 in three suits', %C);
	FanCheck::lacks_fan('123m 456p 789p 111m 55p', 'mixed_straight', 'two of them in one suit', %C);
};

subtest 'reversible tiles' => sub {
	FanCheck::has_fan('123p 345p 888p 456s BB', 'reversible_tiles', 'dots, the symmetric bamboo and the white dragon', %C);
	FanCheck::lacks_fan('123p 345p 888p 456s EE', 'reversible_tiles', 'an east wind is not reversible', %C);
	FanCheck::lacks_fan('123p 345p 888p 456s 66p', 'reversible_tiles', 'a six of dots is not', %C);
};

subtest 'mixed triple chow' => sub {
	FanCheck::has_fan('123m 123p 123s 999m 55p', 'mixed_triple_chow', 'the same chow in three suits', %C);
	FanCheck::lacks_fan('123m 123p 234s 999m 55p', 'mixed_triple_chow', 'one shifted', %C);
};

subtest 'mixed shifted pungs' => sub {
	FanCheck::has_fan('111m 222p 333s 456m 99p', 'mixed_shifted_pungs', 'pungs of 1 2 3 in three suits', %C);
	FanCheck::lacks_fan('111m 222p 444s 456m 99p', 'mixed_shifted_pungs', 'a gap', %C);
};

subtest 'chicken hand has no checker' => sub {
	my $f = FanCheck::found($PLAIN, %C);
	ok(!$f->{chicken_hand}, 'the checker never fires; the scorer applies it');
};

subtest 'last tile draw and last tile claim' => sub {
	FanCheck::has_fan($PLAIN, 'last_tile_draw', 'self-drawn on the last tile of the wall', %C, by => 'self', last_of_wall => 1);
	FanCheck::lacks_fan($PLAIN, 'last_tile_draw', 'not on the last tile', %C, by => 'self');
	FanCheck::lacks_fan($PLAIN, 'last_tile_draw', 'claimed, not drawn', %C, by => 'discard', last_of_wall => 1);
	FanCheck::has_fan($PLAIN, 'last_tile_claim', 'the last tile of the wall, discarded', %C, by => 'discard', last_of_wall => 1);
	FanCheck::lacks_fan($PLAIN, 'last_tile_claim', 'drawn, not claimed', %C, by => 'self', last_of_wall => 1);
};

subtest 'out with replacement tile' => sub {
	FanCheck::has_fan($PLAIN, 'out_with_replacement_tile', 'on the replacement after a kong', %C, by => 'self', replacement => 'kong');
	FanCheck::lacks_fan($PLAIN, 'out_with_replacement_tile', 'a flower replacement is self-drawn only', %C, by => 'self', replacement => 'flower');
};

subtest 'robbing the kong' => sub {
	FanCheck::has_fan($PLAIN, 'robbing_the_kong', 'won off a promoted kong', %C, by => 'rob');
	FanCheck::lacks_fan($PLAIN, 'robbing_the_kong', 'won off a discard', %C, by => 'discard');
};

subtest 'two concealed kongs' => sub {
	FanCheck::has_fan('ckong(1111m) ckong(2222p) 333s 456s 99p', 'two_concealed_kongs', 'two concealed kongs', %C);
	FanCheck::lacks_fan('ckong(1111m) kong(2222p) 333s 456s 99p', 'two_concealed_kongs', 'one concealed and one melded', %C);
};

subtest 'the pairwise fans at eight' => sub {
	my $f = FanCheck::found('123m 456p 789s 111m 55p', %C);
	ok($f->{mixed_straight} && !$f->{pure_straight}, 'a mixed straight is not a pure one');
};
