
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;
use Game::TileMap::Pathfinding;
use Game::TileMap;

use constant HAS_TEST_MEMORYGROWTH => eval { require Test::MemoryGrowth; 1 };
plan skip_all => 'This test requires Test::MemoryGrowth module'
	unless HAS_TEST_MEMORYGROWTH;

################################################################################
# This tests whether Game::TileMap::Pathfinding leaks memory
################################################################################

my $map_str = <<MAP;
	____
	_##_
	_##_
	____
MAP

Test::MemoryGrowth::no_growth {
	my $legend = Game::TileMap->new_legend;
	$legend
		->add_wall('#')
		->add_void('.')
		->add_terrain('_' => 'pavement')
		;

	my $map = Game::TileMap->new(
		legend => $legend,
		map => $map_str
	);

	my $pf = Game::TileMap::Pathfinding->new(map => $map);
	my $path;

	$path = $pf->find_path(0, 0, 4, 4);
	$path = $pf->find_path(4, 4, 0, 0);
	$path = $pf->find_path(2, 2, 3, 3);

	$path = $pf->find_path(-1, 0, 0, 0);
	$path = $pf->find_path(0, -1, 0, 0);
	$path = $pf->find_path(0, 0, -1, 0);
	$path = $pf->find_path(0, 0, 0, -1);
}
calls => 100, 'pathfinding operations do not leak';

done_testing;
