use v5.10;
use strict;
use warnings;

use Test::More;
use Game::TileMap;

my $legend = Game::TileMap->new_legend;

$legend
	->add_wall('#')
	->add_void('.')
	->add_terrain('_' => 'pavement')
	->add_object('entrances', '1' => 'door1')
	->add_object('entrances', '2' => 'door2')
	->add_object('entrances', '3' => 'door3')
	->add_object('monster_spawns', 'a' => 'spawn_a')
	->add_object('monster_spawns', 'b' => 'spawn_b')
	->add_object('monster_spawns', 'c' => 'spawn_c')
	->add_object('surroundings', '=' => 'chest')
	->add_object('surroundings', 'x' => 'trap')
	;

my $map_str = <<MAP;
########2#
1_#=__a__#
#_#_a____#
#_#___b__#
#_######_#
#________#
#...__...#
#...c_...#
#...__...#
#_____x__3
##########
MAP

my $map = Game::TileMap->new(legend => $legend, map => $map_str);

foreach my $item ($map->get_all_of_type('spawn_c')) {
	$item->set_contents('boss_spawn');
}

foreach my $item ($map->get_all_of_class('entrances')) {
	$item->set_contents($item->contents . '_open');
}

subtest 'testing basic map data' => sub {
	is $map->size_x, 10, 'size_x ok';
	is $map->size_y, 11, 'size_y ok';

	is scalar @{$map->coordinates}, $map->size_x, 'size_x on coordinates ok';
	is scalar @{$map->coordinates->[0]}, $map->size_y, 'size_y on coordinates[0] ok';

	isa_ok $map->coordinates->[4][3], 'Game::TileMap::Tile';
	is $map->coordinates->[4][3]->x, 4, '4;3 tile pos x ok';
	is $map->coordinates->[4][3]->y, 3, '4;3 tile pos y ok';
	is $map->coordinates->[4][3]->type, 'spawn_c', '4;3 tile type ok';
	is $map->coordinates->[4][3]->contents, 'boss_spawn', '4;3 tile contents ok';
};

subtest 'testing check_within_map' => sub {

	# out of bounds
	ok !$map->check_within_map(-1, 0), 'check 1 ok';
	ok !$map->check_within_map(0, -1), 'check 2 ok';
	ok !$map->check_within_map(10, 0), 'check 3 ok';
	ok !$map->check_within_map(0, 11), 'check 4 ok';

	# wall / void
	ok !$map->check_within_map(0, 0), 'check 5 ok';
	ok $map->check_within_map(1, 2), 'check 6 ok';

	# pavement
	ok $map->check_within_map(1, 1), 'check 7 ok';
	ok $map->check_within_map(8.9, 9.9), 'check 8 ok';

	# entrance
	ok $map->check_within_map(0.5, 9.3), 'check 9 ok';
};

subtest 'testing check_can_be_accessed' => sub {

	# out of bounds
	ok !$map->check_can_be_accessed(-1, 0), 'check 1 ok';
	ok !$map->check_can_be_accessed(0, -1), 'check 2 ok';
	ok !$map->check_can_be_accessed(10, 0), 'check 3 ok';
	ok !$map->check_can_be_accessed(0, 11), 'check 4 ok';

	# wall / void
	ok !$map->check_can_be_accessed(0, 0), 'check 5 ok';
	ok !$map->check_can_be_accessed(1, 2), 'check 6 ok';

	# pavement
	ok $map->check_can_be_accessed(1, 1), 'check 7 ok';
	ok $map->check_can_be_accessed(8.9, 9.9), 'check 8 ok';

	# entrance
	ok $map->check_can_be_accessed(0.5, 9.3), 'check 9 ok';
};

subtest 'testing get_all_of_class' => sub {
	is scalar $map->get_all_of_class('terrain'), 11 * 10 - 9, 'terrain count ok';

	my @entrances = $map->get_all_of_class('entrances');

	is $entrances[0]->type, 'door3', 'entrance 1 type ok';
	is $entrances[0]->contents, 'door3_open', 'entrance 1 content ok';
	is $entrances[0]->x, 9, 'entrance 1 x ok';
	is $entrances[0]->y, 1, 'entrance 1 y ok';

	is $entrances[1]->type, 'door1', 'entrance 2 type ok';
	is $entrances[1]->contents, 'door1_open', 'entrance 2 content ok';
	is $entrances[1]->x, 0, 'entrance 2 x ok';
	is $entrances[1]->y, 9, 'entrance 2 y ok';

	is $entrances[2]->type, 'door2', 'entrance 3 type ok';
	is $entrances[2]->contents, 'door2_open', 'entrance 3 content ok';
	is $entrances[2]->x, 8, 'entrance 3 x ok';
	is $entrances[2]->y, 10, 'entrance 3 y ok';

	is scalar @entrances, 3, 'entrances count ok';
};

subtest 'testing get_all_of_type' => sub {
	my @bosses = $map->get_all_of_type('spawn_c');

	is $bosses[0]->type, 'spawn_c', 'boss type ok';
	is $bosses[0]->contents, 'boss_spawn', 'boss content ok';
	is $bosses[0]->x, 4, 'boss x ok';
	is $bosses[0]->y, 3, 'boss y ok';

	is scalar @bosses, 1, 'boss count ok';

	my @minions = $map->get_all_of_type('spawn_a');

	is scalar @minions, 2, 'minions count ok';
};

subtest 'testing get_class_of_object' => sub {
	is($map->get_class_of_object(($map->get_all_of_class('terrain'))[0]), 'terrain', 'terrain class ok');
	is($map->get_class_of_object(($map->get_all_of_class('monster_spawns'))[0]), 'monster_spawns', 'monster_spawns class ok');
};

subtest 'testing to_string' => sub {

	# get rid of trailing newline
	$map_str =~ s/\v\z//;

	is $map->to_string, $map_str, 'to_string ok';

	my $map_str2 = $map_str;
	$map_str2 =~ s/a/!/g;

	is $map->to_string_and_mark([[4, 8], [6, 9]]), $map_str2, 'to_string_and_mark ok';

	$map_str2 =~ s/!/O/g;
	is $map->to_string_and_mark([[4, 8], [6, 9]], 'O'), $map_str2, 'to_string_and_mark with an O ok';
};

done_testing;

