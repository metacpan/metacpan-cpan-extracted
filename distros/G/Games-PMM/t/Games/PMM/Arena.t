#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 83;

use Games::PMM::Monster;

my $module = 'Games::PMM::Arena';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
my $arena = $module->new();
isa_ok( $arena, $module );

can_ok( $module, 'x_limit' );
is( $arena->x_limit(), 9, 'x_limit() should return 9' );

can_ok( $module, 'y_limit' );
is( $arena->y_limit(), 9, 'y_limit() should return 9' );

can_ok( $module, 'add_monster' );
my $m1 = Games::PMM::Monster->new();
my $m2 = Games::PMM::Monster->new();

$arena->add_monster( $m1, x => 5, y => 5 );
$arena->add_monster( $m2, x => 7, y => 7 );

can_ok( $module, 'coordinates' );
my $coords = $arena->coordinates();
is( $coords->[ 5 ][ 5 ], $m1,      'add_monster() should update coordinates' );
is( $coords->[ 7 ][ 7 ], $m2,      '... for each added monster' );

can_ok( $module, 'monsters' );
my $monsters = $arena->monsters();
is_deeply( $monsters->{1}, [5, 5], 'add_monster() should update monster list' );
is_deeply( $monsters->{2}, [7, 7], '... for each added monster' );

can_ok( $module, 'validate_position' );
ok( ! $arena->validate_position( x => 10, y =>  1 ),
	'validate_position() should return false if an axis exceeds upper bound' );
ok( ! $arena->validate_position( x =>  1, y => 10 ),
	'... either axis' );

ok( ! $arena->validate_position( x => -1, y =>  1 ),
	'... or if an axis exceeds lower bound' );
ok( ! $arena->validate_position( x =>  1, y => -1 ),
	'... either axis' );

ok( ! $arena->validate_position( x =>  5, y =>  5 ),
	'... or if there is something at that position already' );

ok(   $arena->validate_position( x =>  3, y =>  3 ),
	'... but true if there is nothing there' );

can_ok( $module, 'get_position' );
is_deeply( $arena->get_position( $m1 ), { x => 5, y => 5 },
	'get_position() should return position of given monster' );
is_deeply( $arena->get_position( $m2 ), { x => 7, y => 7 },
	'... for each monster' );

my $m3 = Games::PMM::Monster->new();
ok( ! $arena->get_position( $m3 ), '... or false if monster is not in arena' );

can_ok( $module, 'update_position' );

$arena->update_position( $m1, x => 4, y => 8 );
is_deeply( $arena->get_position( $m1 ), { x => 4, y => 8 },
	'update_position() should change monster position' );

$monsters = $arena->monsters();
$coords   = $arena->coordinates();

is( $coords->[4][8],            $m1, '... in coordinate list' );
is_deeply( $monsters->{1}, [ 4, 8 ], '... and in monster list' );

can_ok( $module, 'get_monster' );
is( $arena->get_monster( x =>  4, y =>   8 ), $m1,
	'get_monster() should return monster at given coordinates' );

is( $arena->get_monster( x =>  9, y =>   9 ), undef,
	'... or undef if no monster is there' );

$arena->update_position( $m2, x => 9, y => 9 );
is( $arena->get_monster( x => 12, y => -99 ), undef,
	'... or if coordinates are out of range' );

$coords = $arena->coordinates();
is( @$coords,           10, '... not stretching x axis' );
is( @{ $coords->[-1] }, 10, '... or y axis' );

can_ok( $module, 'forward' );
my $result = $arena->forward( $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 4, y => 9 },
	'forward() should move monster forward' );
ok( $result, '... returning true if monster could move' );

$m2->facing( 'west' );
$result = $arena->forward( $m2 );
is_deeply( $arena->get_position( $m2 ), { x => 8, y => 9 },
	'... respecting facing' );

$m2->facing( 'north' );

ok( ! $arena->forward( $m2 ), '... returning false if monster cannot move' );;

can_ok( $module, 'reverse' );
$m1->facing( 'east' );
$result = $arena->reverse( $m1 );
is_deeply( $arena->get_position( $m1 ), { x => 3, y => 9 },
	'reverse() should move monster backwards' );
ok( $result, '... returning true if monster can move' );

$m2->facing( 'south' );
$arena->set_position( monster => $m2,     x => 2, y => 8 );
$result = $arena->reverse( $m2 );
is_deeply( $arena->get_position( $m2 ), { x => 2, y => 9 },
	'... respecting facing' );

ok( ! $arena->reverse( $m2 ), '... returning false if monster cannot move' );

can_ok( $module, 'is_wall' );
ok( $arena->is_wall( x => -1, y =>  1 ), 'is_wall() should be true if x < 0' );
ok( $arena->is_wall( x =>  1, y => -1 ), '... or if y < 0' );
ok( $arena->is_wall( x => 10, y =>  1 ), '... or if x > x limit' ); 
ok( $arena->is_wall( x =>  1, y => 10 ), '... or if y > y limit' ); 

ok( ! $arena->is_wall( x => 0, y => 0 ), '... but not if x or y is 0' );
ok( ! $arena->is_wall( x => 9, y => 9 ), '... and not if x or y is limit' );

can_ok( $module, 'get_distance' );
is( $arena->get_distance( { x =>  0, y => 0 }, x => 10, y =>  0 ), 10,
	'get_distance() should calculate straight line distances correctly' );

is( $arena->get_distance( { x =>  0, y => 0 }, x =>  0, y => 10 ), 10,
	'... along both axes' );

is( $arena->get_distance( { x => 10, y => 0 }, x =>  0, y =>  0 ), 10,
	'... calculating absolute distance correctly' );

is( $arena->get_distance( { x =>  0, y => 0 }, x =>  9, y =>  9 ), 18,
	'... counting moves, not diagonal motion' );

can_ok( $module, 'behind' );
$m1->facing( 'north' );
ok( $arena->behind( $m1, { x => 1, y => 1 }, x => 1, y => 0 ),
	'behind() should return true if monster is south of north-facer' );

$m1->facing( 'east' );
ok( $arena->behind( $m1, { x => 1, y => 1 }, x => 0, y => 1 ),
	'... or if monster is west of east-facer' );

$m1->facing( 'south' );
ok( $arena->behind( $m1, { x => 1, y => 1 }, x => 1, y => 2 ),
	'... or if monster is north of south-facer' );

$m1->facing( 'west' );
ok( $arena->behind( $m1, { x => 1, y => 1 }, x => 2, y => 1 ),
	'... or if monster is east of west-facer' );

can_ok( $module, 'scan' );

$arena = $module->new();
$arena->set_position( monster => $m1, x => 0, y => 0 );
$m1->facing( 'north' );
$arena->set_position( monster => $m2, x => 9, y => 9 );
$m2->facing( 'south' );

my @result = $arena->scan( $m1 );
is( @result, 1, 'scan() should return results for all monsters seen' );
is_deeply( $result[0], { id => 2, x => 9, y => 9, distance => 18 },
	'... returning monster id, coordinates, and distance' );

@result = $arena->scan( $m2 );
is( @result, 1, '... respecting monster facing' );
is_deeply( $result[0], { id => 1, x => 0, y => 0, distance => 18 },
	'... and ignoring the monster itself' );

$arena->update_position( $m1, x => 0, y => 9 );
$arena->update_position( $m2, x => 9, y => 9 );
@result = $arena->scan( $m1 );
is( @result, 0,
	'... monster should not see monsters on axis perpendicular to facing' );

$arena->update_position( $m1, x => 8, y => 9 );
my $c = $arena->coordinates();

@result = $arena->scan( $m1 );
is( @result, 1, '... unless one square away' );

$arena->update_position( $m2, x => 0, y => 0 );
$m2->facing( 'west' );
@result = $arena->scan( $m2 );
is( @result, 0, '... respecting facing' );

can_ok( $module, 'move_monster' );
$arena->move_monster( $m2, x => 1, y => 1 );
is_deeply( $arena->get_position( $m2 ), { x => 1, y => 1 },
	'move_monster() should move monster per coordinates' );

$arena->move_monster( $m2, x => 2, y => -1 );
is_deeply( $arena->get_position( $m2 ), { x => 3, y => 0 },
	'... handling coordinates as deltas, not absolute positions' );

$result = $arena->move_monster( $m2, x => 5, y => 9 );
ok( ! $result, '... not moving monster onto another monster' );

$result = $arena->move_monster( $m2, x => -4, y => 0 );
ok( ! $result, '... or moving monster past lower bounds' );

$result = $arena->move_monster( $m2, x => 0, y => -1 );
ok( ! $result, '... on either axis' );

$result = $arena->move_monster( $m2, x => 10, y => 0 );
ok( ! $result, '... or upper bound' );

$result = $arena->move_monster( $m2, x => 10, y => 0 );
ok( ! $result, '... on either axis' );

can_ok( $module, 'attack' );

$arena->update_position( $m1, x => 0, y => 0 );
$arena->update_position( $m2, x => 0, y => 1 );
$m1->facing( 'south' );
$m2->facing( 'south' );

$result = $arena->attack( $m1 );
ok( ! $result,
	'attack() should fail unless victim is ahead of or beside attacker' );
is( $m2->health(), 3, '... not damaging intended victim' );
$result = $arena->attack( $m2 );
ok(   $result,        '... succeeding otherwise' );
is( $m1->health(), 2, '... damaging victim' );
