#!/usr/bin/perl -w

use Test::More tests => 14;

use Game::Life::Infinite::Board;

# Cells:
my $boardCells = new_ok(Game::Life::Infinite::Board);
my $fnCells = 't/testInput/13enginecordership.cells';
cmp_ok($boardCells->loadInit($fnCells), 'eq', 't/testInput/13enginecordership.cells', 'Load cells') ;
# RLE:
my $boardRLE = new_ok(Game::Life::Infinite::Board);
my $fnRLE = 't/testInput/13enginecordership.rle';
cmp_ok($boardRLE->loadInit($fnRLE), 'eq', 't/testInput/13enginecordership.rle', 'Load rle') ;
# Life 1.05:
my $boardL105 = new_ok(Game::Life::Infinite::Board);
my $fnL105 = 't/testInput/13enginecordership_105.lif';
cmp_ok($boardL105->loadInit($fnL105), 'eq', 't/testInput/13enginecordership_105.lif', 'Load lif (1.05)') ;
# Life 1.06:
my $boardL106 = new_ok(Game::Life::Infinite::Board);
my $fnL106 = 't/testInput/13enginecordership_106.lif';
cmp_ok($boardL106->loadInit($fnL106), 'eq', 't/testInput/13enginecordership_106.lif', 'Load lif (1.06)') ;

delete $boardCells->{'currentFn'};
delete $boardCells->{'description'};
delete $boardRLE->{'currentFn'};
delete $boardL105->{'currentFn'};
delete $boardL105->{'description'};

is_deeply($boardCells, $boardRLE, 'Compare .cells to .rle load.');
is_deeply($boardCells, $boardL105, 'Compare .cells to .lif (1.05) load.');
is_deeply($boardRLE, $boardL105, 'Compare .rle to .lif (1.05) load.');

# Delete name to compare with Life 1.06:
delete $boardCells->{'name'};
delete $boardRLE->{'name'};
delete $boardL105->{'name'};
delete $boardL106->{'name'};
delete $boardL106->{'currentFn'};
delete $boardL106->{'description'};
is_deeply($boardCells, $boardL106, 'Compare .cells to .lif (1.06) load.');
is_deeply($boardRLE, $boardL106, 'Compare .rle to .lif (1.06) load.');
is_deeply($boardL105, $boardL106, 'Compare .lif (1.05) to .lif (1.06) load.');



