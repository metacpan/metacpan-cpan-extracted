#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 32;

use Games::PMM::Arena;
use Games::PMM::Monster;

my $module = 'Games::PMM::Actions';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
my $actions = $module->new();
isa_ok( $actions, $module );

can_ok( $module, 'should_turn' );

my $m1    = Games::PMM::Monster->new();
my $m2    = Games::PMM::Monster->new();
my $arena = Games::PMM::Arena->new();

$m1->facing( 'north' );
$m2->facing( 'south' );

$arena->add_monster( $m1, x => 0, y => 0 );
$arena->add_monster( $m2, x => 8, y => 8 );

$m1->seen( [ $arena->scan( $m1 ) ] );

ok( ! $actions->should_turn( $m1, $arena, 'charge' ),
	'should_turn() should return false if monster can move ahead or back' );

$arena->move_monster( $m1, x => 0, y => 8 );
is( $actions->should_turn( $m1, $arena, 'charge' ), 'right',
	'... and should return direction monster should turn' );

$arena->move_monster( $m1, x => 9, y => 0 );
is( $actions->should_turn( $m1, $arena, 'charge' ), 'left',
	'... appropriate for position relative to other monster' );

$arena->move_monster( $m1, x => -9, y => -8 );
is( $actions->should_turn( $m1, $arena, 'retreat' ), 'left',
	'... whether charging or retreating' );

can_ok( $module, 'action_charge' );
$arena->set_position( monster => $m1, x => 0, y => 0 );
$actions->action_charge( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 0, y => 1 },
	'action_charge() should move monster toward other monster' );

$m1->turn( 'right' );

$actions->action_charge( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 1, y => 1 },
	'... preferring direction of facing' );

can_ok( $module, 'action_retreat' );
$actions->action_retreat( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 0, y => 1 },
	'action_retreat() should move monster away from seen monster' );

$m1->turn( 'left' );
$actions->action_retreat( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 0, y => 0 },
	'... preferring direction of facing' );

can_ok( $module, 'action_forward' );

$m1->facing( 'north' );
$actions->action_forward( $arena, $m1);

is_deeply( $arena->get_position( $m1 ), { x => 0, y => 1 },
	'action_forward() should move monster forward' );

$m1->turn( 'right' );
$actions->action_forward( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 1, y => 1 },
	'... respecting facing' );

can_ok( $module, 'action_reverse' );
$m1->turn( 'right' );
$actions->action_reverse( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 1, y => 2 },
	'action_reverse() should move monster backwards' );

$m1->turn( 'right' );
$actions->action_reverse( $arena, $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 2, y => 2 },
	'... respecting facing' );

can_ok( $module, 'action_turn' );
$m1->facing( 'north' );
$actions->action_turn( $arena, $m1, 'right' );
is( $m1->facing(), 'east',  'action_turn() should turn monster' );

$m1->facing( 'west' );
$actions->action_turn( $arena, $m1, 'left' );
is( $m1->facing(), 'south', '... updating facing appropriately' );

can_ok( $module, 'action_scan' );
$actions->action_scan( $arena, $m2 );
my @seen = @{ $m2->seen() };
is( @seen, 1, 'action_scan() should update monster with all seen monsters' );
is_deeply( $seen[0], { id => 1, x => 2, y => 2, distance => 12 },
	          '... with coordinates and distance' );

can_ok( $module, 'action_attack' );
my $result = $actions->action_attack( $arena, $m1 );
ok( ! $result,
	'action_attack() should fail unless victim is adjacent to attacker' );

$m1->facing( 'north' );
$m2->facing( 'north' );
$arena->update_position( $m1, x => 0, y => 0 );
$arena->update_position( $m2, x => 0, y => 1 );

$result = $actions->action_attack( $arena, $m2 );
ok( ! $result, '... and should fail if victim is behind attacker' );

$result = $actions->action_attack( $arena, $m1 );
ok(   $result,        '... succeeding if victim is adjacent, not behind' );
is( $m2->health(), 2, '... damaging the victim one point' );
is( $m1->health(), 3, '... and leaving attacker alone' );
