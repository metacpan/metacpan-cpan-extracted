use Test2::V0;
use Game::TileMap::Pathfinding;
use Game::TileMap;

################################################################################
# This tests whether more complex paths are found, and if the shortest path is
# always taken
################################################################################

my $legend = Game::TileMap->new_legend;
$legend
	->add_wall('#')
	->add_void('.')
	->add_terrain('_' => 'pavement')
	->add_object(tests => '1' => 'first test')
	->add_object(tests => '2' => 'second test')
	->add_object(tests => '3' => 'third test')
	;

my $map_str = <<MAP;
	#_#####3
	2_______
	#_#####_
	#___.2__
	#___###_
	##______
	##_#####
	1#1____3
MAP

my $map = Game::TileMap->new(
	legend => $legend,
	map => $map_str
);

subtest 'should return undef if the destination is unreachable' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(0, 0, 2, 0);

	ok !defined $path, 'path not found ok';
};

subtest 'should find the quickest path when two paths are available' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(0, 6, 5, 4);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		1, 6,
		2, 6,
		3, 6,
		4, 6,
		5, 6,
		6, 6,
		7, 6,
		7, 5,
		7, 4,
		6, 4,
		5, 4,
		],
		'step list ok';
};

subtest 'should find a long path (reverse order)' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(7, 0, 7, 7);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		6, 0,
		5, 0,
		4, 0,
		3, 0,
		2, 0,
		2, 1,
		2, 2,
		3, 2,
		4, 2,
		5, 2,
		6, 2,
		7, 2,
		7, 3,
		7, 4,
		7, 5,
		7, 6,
		7, 7,
		],
		'step list ok';
};

done_testing;

