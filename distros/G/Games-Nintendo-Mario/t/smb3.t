#!/usr/bin/perl

use Games::Nintendo::Mario::SMB3;
use Test::More 'no_plan';

my $plumber = Games::Nintendo::Mario::SMB3->new(
	state => 'super', 
	name => 'Luigi'
);

isa_ok($plumber, 'Games::Nintendo::Mario::SMB3');

is($plumber->name, 'Super Luigi', "It's-a him, Super Luigi!");

is($plumber->state,'super',"we started Luigi super");

$plumber->powerup('mushroom');
is($plumber->state,'super',"mushroom has no effect on Super Luigi");

$plumber->powerup('flower');
is($plumber->state,'fire',"Fire Luigi is born of the Fire Flower");

$plumber->damage;
is($plumber->state,'super',"one hit and it's back to Super Luigi");
