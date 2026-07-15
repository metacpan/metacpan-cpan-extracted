use Test2::V0;
use Game::TileMap::Pathfinding;
use Game::TileMap;

################################################################################
# This tests whether different paths are taken when diagonal movement is
# enabled.
################################################################################

my $legend = Game::TileMap->new_legend;
$legend
	->add_wall('#')
	->add_void('.')
	->add_terrain('_' => 'pavement')
	->add_object(tests => '1' => 'first test')
	->add_object(tests => '2' => 'second test')
	->add_object(tests => '3' => 'third test')
	->add_object(tests => '4' => 'fourth test')
	;

my $map_str = <<MAP;
	_______3
	_1______
	________
	4_2_____
	_##_____
	_##___1_
	2___####
	3______4
MAP

my $map = Game::TileMap->new(
	legend => $legend,
	map => $map_str
);

subtest 'should prefer moving diagonally rather than orthogonally' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map, diagonal_movement => !!1);
	my $path = $pf->find_path(1, 6, 6, 2);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		2, 5,
		3, 4,
		4, 4,
		5, 3,
		6, 2
		],
		'step list ok';
};

subtest 'should not move diagonally to bypass obstacles' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map, diagonal_movement => !!1);
	my $path = $pf->find_path(0, 1, 2, 4);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		0, 2,
		0, 3,
		0, 4,
		1, 4,
		2, 4
		],
		'step list ok';
};

subtest 'should bypass obstacles smoothly on long paths' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map, diagonal_movement => !!1);
	my $path = $pf->find_path(7, 7, 0, 0);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		6, 6,
		5, 5,
		5, 4,
		4, 3,
		3, 2,
		3, 1,
		2, 1,
		1, 1,
		0, 0,
		],
		'step list ok';
};

subtest 'should not get lost in a maze forcing orthogonal movements' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map, diagonal_movement => !!1);
	my $path = $pf->find_path(0, 4, 7, 0);

	ok defined $path, 'path found ok';
	is [@{$path}], [
		0, 3,
		0, 2,
		0, 1,
		1, 1,
		2, 1,
		3, 0,
		4, 0,
		5, 0,
		6, 0,
		7, 0,
		],
		'step list ok';
};

done_testing;

