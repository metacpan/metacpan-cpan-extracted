use v5.10;
use strict;
use warnings;

use Test::More;
use Game::TileMap;

my $legend = Game::TileMap->new_legend(characters_per_tile => 2);

$legend
	->add_wall('##')
	->add_void('..')
	->add_terrain('__' => 'pavement')
	->add_object('monster_spawns', 'm1' => 'spawn_1')
	->add_object('monster_spawns', 'm2' => 'spawn_2')
	->add_object('surroundings', '=1' => 'chest_1')
	;

my $map_str = <<MAP;
################
______________##
............__##
############__##
##=1______##__##
##__m1________##
############__##
________m2____##
################
MAP

my $map = Game::TileMap->new(legend => $legend, map => $map_str);

subtest 'testing basic map data' => sub {
	is $map->size_x, 8, 'size_x ok';
	is $map->size_y, 9, 'size_y ok';

	is scalar @{$map->coordinates}, $map->size_x, 'size_x on coordinates ok';
	is scalar @{$map->coordinates->[0]}, $map->size_y, 'size_y on coordinates[0] ok';

	isa_ok $map->coordinates->[1][4], 'Game::TileMap::Tile';
	is $map->coordinates->[1][4]->x, 1, '1;4 tile pos x ok';
	is $map->coordinates->[1][4]->y, 4, '1;4 tile pos y ok';
	is $map->coordinates->[1][4]->type, 'chest_1', '1;4 tile type ok';
	is $map->coordinates->[1][4]->contents, 'chest_1', '1;4 tile contents ok';
};

subtest 'testing to_string' => sub {

	# get rid of trailing newline
	$map_str =~ s/\v\z//;

	is $map->to_string, $map_str, 'to_string ok';

	my $map_str2 = $map_str;
	substr $map_str2, 0, 2, '@@';

	is $map->to_string_and_mark([[0, 8]]), $map_str2, 'to_string_and_mark ok';
};

done_testing;

