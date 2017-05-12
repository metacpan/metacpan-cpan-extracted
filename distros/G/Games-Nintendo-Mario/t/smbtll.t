#!/usr/bin/perl

use Games::Nintendo::Mario::SMBTLL;
use Test::More 'no_plan';

my $plumber = Games::Nintendo::Mario::SMBTLL->new;

isa_ok($plumber, 'Games::Nintendo::Mario::SMBTLL');

is($plumber->name, 'Mario', "It's-a him, Mario!");

is($plumber->state,'normal',"Mario starts life normal");

is($plumber->powerup('mushroom')->state,'super',"after a mushroom, he's super");

################ STARTING NORMAL

is(
	Games::Nintendo::Mario::SMBTLL->new->damage->state,
	'dead',
	'damage in normal is death'
);

is(
	Games::Nintendo::Mario::SMBTLL->new->powerup('mushroom')->state,
	'super',
	'mushroom in normal is super'
);

is(
	Games::Nintendo::Mario::SMBTLL->new->powerup('flower')->state,
	'super',
	'flower in normal is super'
);

is(
	Games::Nintendo::Mario::SMBTLL->new->powerup('mushroom')->powerup('poison_mushroom')->state,
	'normal',
	'poison mushroom in super is normal'
);

