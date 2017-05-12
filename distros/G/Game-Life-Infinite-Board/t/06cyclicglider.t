#!/usr/bin/perl -w

use Test::More tests => 6;

use Game::Life::Infinite::Board;

my $board = new_ok(Game::Life::Infinite::Board);

my $fn = 't/testInput/cyclicglider.cells';
cmp_ok($board->loadInit($fn), 'eq', 't/testInput/cyclicglider.cells', 'Load cyclic glider') ;
my $stats = $board->statistics;
my $expectedstats = {
		'size'		=> 16,
		'generation'	=> 0,
		'minx'		=> -1,
		'maxx'		=> 3,
		'miny'		=> -1,
		'maxy'		=> 3,
		'liveCells'	=> 5,
		'delta'		=> -1,
		'oscilator'	=> 0,
		'totalTime'	=> 0,
		'usedCells'	=> 22,
		'factor2'	=> 1,
		'lastTI'	=> undef,
};

is_deeply($stats, $expectedstats, 'Initial Statistics');

my $snapshot = $board->snapshot;
my $expectedSnapshot = join('',
	".....\n",
	"..2..\n",
	"...2.\n",
	".OO2.\n",
	".....\n"
);
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Snapshot' );
for (1..10) {
	$board->tick(0);
};
$board->shrinkBoard;
$stats = $board->statistics;
delete $stats->{'totalTime'};
delete $stats->{'lastTI'};
delete $stats->{'factor2'};
$expectedstats = {
		'size'		=> 16,
		'generation'	=> 10,
		'minx'		=> 1,
		'maxx'		=> 5,
		'miny'		=> 2,
		'maxy'		=> 6,
		'liveCells'	=> 5,
		'delta'		=> 4,
		'oscilator'	=> 0,
		'usedCells'	=> 22,
};

$snapshot = $board->snapshot;
$expectedSnapshot = join('',
	".....\n",
	"...2.\n",
	".O.2.\n",
	"..OO.\n",
	".....\n"
);

is_deeply($stats, $expectedstats, 'Generation 10 Statistics') || diag explain { stats => $stats, 
										stats2 => $expectedstats,
										sn1 => $snapshot, 
										sn2 => $expectedSnapshot };
cmp_ok( $snapshot->{'snapshot'}, 'eq', $expectedSnapshot, 'Generation 10 Snapshot' );
