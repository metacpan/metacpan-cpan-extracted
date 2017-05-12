#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 35;

my $module = 'Games::PMM::Monster';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
my $monster = $module->new( commands => [ 'foo', 'bar' ] );
isa_ok( $monster, $module );

can_ok( $module, 'id' );
is( $monster->id(),     1, 'new monster should have an id' );
is( $module->new->id(), 2, '... unique to each new monster' );

can_ok( $module, 'health' );
is( $monster->health(), 3, 'health() should be full on a new monster' );

can_ok( $module, 'damage' );
my $result = $monster->damage();
is( $result,            2,
	'damage() should damage monster and return its health' );
is( $monster->health(), 2, '... removing a point of health' );

can_ok( $module, 'commands' );
isa_ok( $monster->commands(), 'Games::PMM::Monster::Commands',
	'commands() should return an object that' );

can_ok( $module, 'next_command' );
is_deeply( [ $monster->next_command() ], [ 'foo' ],
	'next_command() should start with first command' );
is_deeply( [ $monster->next_command() ], [ 'bar' ],
	'... continuing with next command' );
is( $monster->next_command(), undef, '... returning undef at end of commands' );
is_deeply( [ $monster->next_command() ], [ 'foo' ],
	'... looping back to start as needed' );

can_ok( $module, 'facing' );
is( $monster->facing(), 'north', 'facing() should default to north' );
$monster->facing( 'south' );
is( $monster->facing(), 'south', '... but should be settable' );

can_ok( $module, 'seen' );
$monster->seen( 'seen monsters' );
is( $monster->seen(), 'seen monsters',
	'seen() should be gettable and settable' );

can_ok( $module, 'turn' );
for my $turn
(
	{ direction => 'right', facings   => [qw( west north east south )] },
	{ direction => 'left',  facings   => [qw( east north west south )] },
)
{
	my $faced = $monster->facing();

	for my $facing (@{ $turn->{facings} })
	{
		$monster->turn( $turn->{direction} );
		is( $monster->facing(), $facing, "... turning $turn->{direction} " .
			"from $faced should face monster $facing" );
		$faced = $facing;
	}
}

can_ok( $module, 'closest' );
my @seen = (
	{ id => 'boo', distance => 1 },
	{ id => 'foo', distance => 7 },
	{ id => 'zoo', distance => 9 },
);
$monster->seen( \@seen );
is( $monster->closest()->{id}, 'boo',
	'closest() should return closest seen monster' );

is( $module->new->closest(), undef,
	'... or undef if no monsters have been seen' );
