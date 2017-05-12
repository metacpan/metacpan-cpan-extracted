#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/colorgliderscrush.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/colorgliderscrush.cells', 'Load four colored gliders') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 540,
		'generation'	=> 0,
		'minx'		=> 0,
		'maxx'		=> 30,
		'miny'		=> -1,
		'maxy'		=> 17,
		'liveCells'	=> 20,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 89,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join('',
"...............................\n",
".......2....................3..\n",
"........2..................3...\n",
"......222..................333.\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...............................\n",
"...OOO..................444....\n",
".....O..................4......\n",
"....O....................4.....\n",
"...............................\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..26) {
	$board->tick(0);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 60,
		'generation'	=> 26,
		'minx'		=> 11,
		'maxx'		=> 21,
		'miny'		=> 5,
		'maxy'		=> 11,
		'liveCells'	=> 12,
		'delta'		=> 0,
		'oscilator'	=> 0,
		'usedCells'	=> 52,
};

$snapshot = $board->snapshot;
$expectedSnapshot = join('',
"...........\n",
"..2........\n",
".2.2....4..\n",
".2.2...4.4.\n",
"..2....4.4.\n",
"........4..\n",
"...........\n"
);

is_deeply($stats, $expectedstats, 'Generation 26 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot };
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 26 Snapshot' );
