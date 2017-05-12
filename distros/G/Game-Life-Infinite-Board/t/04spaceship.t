#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/17c45_spaceship.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/17c45_spaceship.cells', 'Load 17c45_spaceship (p2 at 191)') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 119,
		'generation'	=> 0,
		'minx'		=> -1,
		'maxx'		=> 16,
		'miny'		=> 0,
		'maxy'		=> 7,
		'liveCells'	=> 11,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 45,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join('',
	"..................\n",
	"..................\n",
	"................O.\n",
	".O.............OO.\n",
	".O............OO..\n",
	".O.............OO.\n",
	"................O.\n",
	"..................\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..194) {
	$board->tick(2);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 240,
		'generation'	=> 194,
		'minx'		=> -15,
		'maxx'		=> 0,
		'miny'		=> -4,
		'maxy'		=> 12,
		'liveCells'	=> 17,
		'delta'		=> 12,
		'oscilator'	=> 2,
		'usedCells'	=> 77,
};

$expectedSnapshot = join('',
	"................\n",
	"..OO............\n",
	"..OO............\n",
	"..............O.\n",
	"..............O.\n",
	"..............O.\n",
	"................\n",
	"................\n",
	".OOO............\n",
	"................\n",
	"................\n",
	"..............O.\n",
	"..............O.\n",
	"..............O.\n",
	"..OO............\n",
	"..OO............\n",
	"................\n"
);
$snapshot = $board->snapshot;
is_deeply($stats, $expectedstats, 'Generation 194 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot };
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 194 Snapshot' );


