#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/colorstoplights.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/colorstoplights.cells', 'Load color stop lights') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 210,
		'generation'	=> 0,
		'minx'		=> 0,
		'maxx'		=> 15,
		'miny'		=> 0,
		'maxy'		=> 14,
		'liveCells'	=> 12,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 61,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join('',
	"................\n",
	"...2O2..........\n",
	"................\n",
	"................\n",
	"................\n",
	"................\n",
	".3O3........323.\n",
	"................\n",
	"................\n",
	"................\n",
	"................\n",
	"..4.............\n",
	"..2.............\n",
	"..O.............\n",
	"................\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..5) {
	$board->tick(0);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 196,
		'generation'	=> 5,
		'minx'		=> 0,
		'maxx'		=> 14,
		'miny'		=> -1,
		'maxy'		=> 13,
		'liveCells'	=> 12,
		'delta'		=> 16,
		'oscilator'	=> 0,
		'usedCells'	=> 60,
};

$snapshot = $board->snapshot;
$expectedSnapshot = join('',
	"...............\n",
	"....2..........\n",
	"....O..........\n",
	"....2..........\n",
	"...............\n",
	"...............\n",
	"..3..........3.\n",
	"..O..........2.\n",
	"..3..........3.\n",
	"...............\n",
	"...............\n",
	"...............\n",
	"...............\n",
	".323...........\n",
	"...............\n"
);

is_deeply($stats, $expectedstats, 'Generation 5 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot };
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 5 Snapshot' );
