#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/stoplight.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/stoplight.cells', 'Load a stoplight') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 8,
		'generation'	=> 0,
		'minx'		=> -1,
		'maxx'		=> 3,
		'miny'		=> -1,
		'maxy'		=> 1,
		'liveCells'	=> 3,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 15,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join('',
	".....\n",
	".OOO.\n",
	".....\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..3) {
	$board->tick(2);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 8,
		'generation'	=> 3,
		'minx'		=> 0,
		'maxx'		=> 2,
		'miny'		=> -2,
		'maxy'		=> 2,
		'liveCells'	=> 3,
		'delta'		=> 4,
		'oscilator'	=> 2,
		'usedCells'	=> 15,
};

$snapshot = $board->snapshot;
$expectedSnapshot = join('',
	"...\n",
	".O.\n",
	".O.\n",
	".O.\n",
	"...\n"
);

is_deeply($stats, $expectedstats, 'Generation 3 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot,
										board => $board
									};
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 3 Snapshot' );

