use Test2::V0;
use Game::TileMap::Pathfinding;
use Game::TileMap;

################################################################################
# This tests whether interface works and very basic paths are found
################################################################################

my $legend = Game::TileMap->new_legend;
$legend
	->add_wall('#')
	->add_void('.')
	->add_terrain('_' => 'pavement')
	;

my $map_str = <<MAP;
	____
	____
	____
	____
MAP

my $map = Game::TileMap->new(
	legend => $legend,
	map => $map_str
);

subtest 'should have a working interface' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(0, 3, 1, 2);

	isa_ok $path, 'Game::TileMap::Pathfinding::Result';
	is $path->step_count, 2, 'step count ok';
	is [$path->steps], [
		[0, 2],
		[1, 2],
		],
		'step list ok';

	is [$path->next_step], [0, 2], 'next step (1) ok';
	is [$path->next_step], [1, 2], 'next step (2) ok';
};

# test whether the doc-suggested use case with while loop works
subtest 'while loop should be convenient to use' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(0, 3, 1, 2);

	my $counter = 0;
	while (my ($x, $y) = $path->next_step) {
		$counter += 1;
	}

	pass 'loop ended ok';
	is $counter, 2, 'counter ok';
};

subtest 'should return undef if coordinates are beyond map' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	ok !defined $pf->find_path(-1, 1, 1, 1), 'too small start coordinate ok';
	ok !defined $pf->find_path(1, 4, 1, 1), 'too big start coordinate ok';
	ok !defined $pf->find_path(1, 1, 1, -1), 'too small end coordinate ok';
	ok !defined $pf->find_path(1, 1, 4, 1), 'too big end coordinate ok';
};

subtest 'should return an empty path if start equals destination' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(1, 1, 1, 1);

	ok defined $path, 'pathfinding result ok';
	is $path->step_count, 0, 'result step count ok';
};

subtest 'should find a path on the other side of the map' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(0, 0, 3, 3);

	ok defined $path, 'pathfinding result ok';
	is $path->step_count, 6, 'step count ok';
	is [$path->steps], [
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 3],
		[2, 3],
		[3, 3],
		],
		'step list ok';
};

subtest 'should find a path on the other side of the map (reverse direction)' => sub {
	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path = $pf->find_path(3, 3, 0, 0);

	ok defined $path, 'pathfinding result ok';
	is $path->step_count, 6, 'step count ok';
	is [$path->steps], [
		[3, 2],
		[3, 1],
		[3, 0],
		[2, 0],
		[1, 0],
		[0, 0],
		],
		'step list ok';
};

done_testing;

