#!/usr/bin/perl

use Games::Nintendo::Mario::NSMB;
use Test::More 'no_plan';

my $plumber = Games::Nintendo::Mario::NSMB->new;

isa_ok($plumber, 'Games::Nintendo::Mario::NSMB');

is($plumber->name, 'Mario', "It's-a him, Mario!");

is($plumber->state,'normal',"Mario starts life normal");

is($plumber->powerup('mushroom')->state,'super',"after a mushroom, he's super");

################ STARTING NORMAL

is(
	Games::Nintendo::Mario::NSMB->new->damage->state,
	'dead',
	'damage in normal is death'
);

is(
	Games::Nintendo::Mario::NSMB->new->powerup('mushroom')->state,
	'super',
	'mushroom in normal is super'
);

is(
	Games::Nintendo::Mario::NSMB->new->powerup('flower')->state,
	'fire',
	'flower in normal is fire'
);

################ STARTING SUPER

is(
	Games::Nintendo::Mario::NSMB->new(state => 'super')->damage->state,
	'normal',
	'damage in super is normal'
);

is(
	Games::Nintendo::Mario::NSMB->new(state => 'super')->powerup('mushroom')->state,
	'super',
	'mushroom in super is still super'
);

is(
	Games::Nintendo::Mario::NSMB->new(state => 'super')->powerup('flower')->state,
	'fire',
	'flower in super is firey'
);

################ STARTING FIREY

is(
	Games::Nintendo::Mario::NSMB->new(state => 'fire')->damage->state,
	'normal',
	'damage in fire is normal'
);

is(
	Games::Nintendo::Mario::NSMB->new(state => 'fire')->powerup('mushroom')->state,
	'fire',
	'mushroom in fire is still fire'
);

is(
	Games::Nintendo::Mario::NSMB->new(state => 'fire')->powerup('flower')->state,
	'fire',
	'flower in fire mode changes nothing'
);
