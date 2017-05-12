#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/101.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/101.cells', 'Load 101 (p5)') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 247,
		'generation'	=> 0,
		'minx'		=> -1,
		'maxx'		=> 18,
		'miny'		=> -1,
		'maxy'		=> 12,
		'liveCells'	=> 64,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 209,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join ('',
	"....................\n",
	".....OO......OO.....\n",
	"....O.O......O.O....\n",
	"....O..........O....\n",
	".OO.O..........O.OO.\n",
	".OO.O.O..OO..O.O.OO.\n",
	"....O.O.O..O.O.O....\n",
	"....O.O.O..O.O.O....\n",
	".OO.O.O..OO..O.O.OO.\n",
	".OO.O..........O.OO.\n",
	"....O..........O....\n",
	"....O.O......O.O....\n",
	".....OO......OO.....\n",
	"....................\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..10) {
	$board->tick(10);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 247,
		'generation'	=> 10,
		'minx'		=> -1,
		'maxx'		=> 18,
		'miny'		=> -1,
		'maxy'		=> 12,
		'liveCells'	=> 64,
		'delta'		=> 16,
		'oscilator'	=> 5,
		'usedCells'	=> 208,
};

$snapshot = $board->snapshot;
is_deeply($stats, $expectedstats, 'Generation 10 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot };
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 10 Snapshot' );


