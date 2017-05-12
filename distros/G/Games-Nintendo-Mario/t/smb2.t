#!/usr/bin/perl

use Games::Nintendo::Mario::SMB2;
use Test::More 'no_plan';

my $fungus = Games::Nintendo::Mario::SMB2->new( name => 'Toad' );

isa_ok($fungus, 'Games::Nintendo::Mario::SMB2');

is($fungus->name, 'Toad', "Eeew, it's Toad!");

is($fungus->state,'normal',"we started Toad normal (no choice!)");

is($fungus->max_hearts,3, "three heart containers");
is($fungus->hearts,	1, "one heart at start");

is(
	$fungus->powerup('heart')->hearts,
	2,
	"two hearts after powerup"
);

is($fungus->state, 'super', "two hearts means super!");

is(
	$fungus->damage()->hearts,
	1,
	"one heart after damage"
);

is(
	$fungus->damage()->hearts,
	0,
	"zero heart after more damage"
);

is($fungus->state,'dead',"...and he's dead");

my $liege = Games::Nintendo::Mario::SMB2->new( name => 'Peach' );

$liege->powerup('mushroom');

is( $liege->hearts,     1, "two hearts after mushroom powerup (unchanged)" );
is( $liege->max_hearts, 4, "four heart containers after mushroom powerup" );

$liege->powerup('mushroom');
is( $liege->max_hearts, 5, "five heart containers after mushroom powerup" );

$liege->powerup('mushroom');
is( $liege->max_hearts, 5, "five heart containers after mushroom powerup" );

