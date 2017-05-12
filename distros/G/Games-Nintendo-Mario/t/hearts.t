#!/usr/bin/perl

use Games::Nintendo::Mario::Hearts;
use Test::More 'no_plan';

my $plumber = Games::Nintendo::Mario::Hearts->new(
	name => 'Luigi'
);

isa_ok($plumber, 'Games::Nintendo::Mario::Hearts');

is($plumber->name, 'Luigi', "It's-a him, Luigi!");

is($plumber->state,'normal',"we started Luigi normal");

is($plumber->max_hearts,3, "three heart containers");
is($plumber->hearts,	1, "one heart at start");

is(
	$plumber->powerup('heart')->hearts,
	2,
	"two hearts after powerup"
);

is(
	$plumber->damage()->hearts,
	1,
	"one heart after damage"
);

is(
	$plumber->damage()->hearts,
	0,
	"zero heart after more damage"
);

is($plumber->state,'dead',"...and he's dead");
