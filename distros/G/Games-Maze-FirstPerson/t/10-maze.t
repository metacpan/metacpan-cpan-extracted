#!/usr/bin/perl
use warnings;
use strict;
#use Test::More qw/no_plan/;
use Test::More tests => 53;
use Test::Exception;

my $MAZE;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
    $MAZE = 'Games::Maze::FirstPerson';
    use_ok $MAZE or die;
}

my ( $rows, $columns ) = ( 3, 5 );

can_ok $MAZE, 'new';

throws_ok { $MAZE->new( dimensions => [ $rows, $columns, 2 ] ) }
    qr/multi-level mazes not \(yet\) supported/,
    '... and it should die if we try to create a multi-level maze';

throws_ok { $MAZE->new( dimensions => [ $rows, $columns, 1 ], cell => 'Hex' ) }
    qr/'cell' attribute must be 'Quad'/,
    '... or a non-rectangule (Quad) one';

throws_ok { $MAZE->new( dimensions => $rows ) }
    qr/dimensions must be an array ref/,
    '... or if we specify dimensions incorrectly';

ok my $maze = $MAZE->new( dimensions => [ $rows, $columns ] ),
  'Calling new() with valid arguments should succeed';

isa_ok $maze, $MAZE, '... and the object it returns';

can_ok $maze, 'rows';
is $maze->rows, $rows, '... and it should return the correct number of rows';

can_ok $maze, 'cols';
is $maze->cols, $columns,
  '... and it should return the correct number of columns';

can_ok $maze, 'columns';
is $maze->columns, $columns,
  '... and it should return the correct number of columns';

can_ok $maze, 'y';
is $maze->y, 0, '... and it should always start in the first row';

can_ok $maze, 'x';
ok defined $maze->x, '... and it should have a value';

can_ok $maze, 'facing';
is $maze->facing, 'south', '... and we should start out facing south';

can_ok $maze, 'north';
ok !$maze->north, '... and the north opening should be closed at the beginning';

can_ok $maze, 'location';

throws_ok { $maze->location( -1, 0 ) }
  qr/Arguments to location must be positive integers/,
  '... and we should not be able to set the x value too low';

throws_ok { $maze->location( $columns + 1, 0 ) } qr/x value out of range/,
  '... or too high';

throws_ok { $maze->location( 0, -1 ) }
  qr/Arguments to location must be positive integers/,
  '... and we should not be able to set the y value too low';

throws_ok { $maze->location( 0, $rows + 1 ) } qr/y value out of range/,
  '... or too high';

ok $maze->location( 0, 0 ),
  '... and we should be able to set it to valid values';

my @grid = (
    [qw/ 0 0 0 0 0 0 0 /],    # ..........
    [qw/ 0 1 1 1 1 1 0 /],    # .        .
    [qw/ 0 0 0 0 0 1 0 /],    # .......  .
    [qw/ 0 1 1 1 1 1 0 /],    # .        .
    [qw/ 0 1 0 0 0 1 0 /],    # .  ....  .
    [qw/ 0 1 1 1 0 1 0 /],    # .     .  .
    [qw/ 0 0 0 1 0 1 0 /],    # ....  .  .
    [qw/ 0 1 0 1 0 1 0 /],    # .  .  .  .
    [qw/ 0 1 0 1 0 1 0 /],    # .  .  .  .
    [qw/ 0 1 1 1 0 1 0 /],    # .     .  .
    [qw/ 0 1 0 0 0 0 0 /],    # .  .......
);

$maze->{grid} = \@grid;

ok !$maze->north, 'The NW corner of our maze has no north exit';

can_ok $maze, 'south';
ok !$maze->south, '... nor should their be a south exit';

can_ok $maze, 'west';
ok !$maze->west, '... nor should their be a west exit';

can_ok $maze, 'east';
ok $maze->east, '... but we should be able to move east';

can_ok $maze, 'surroundings';
my $expected = "...\n.  \n...\n";

# ...
# .
# ...
is $maze->surroundings, $expected,
  '... and it should return a mini-map of your surroundings';

can_ok $maze, 'go_north';
ok !$maze->go_north, '... and going north into a wall should fail';

is $maze->facing, 'south',
  '... and this should not effect the direction we are facing';

can_ok $maze, 'go_south';
ok !$maze->go_south, '... and going south into a wall should fail';

can_ok $maze, 'go_west';
ok !$maze->go_west, '... and going west into a wall should fail';

can_ok $maze, 'go_east';
ok $maze->go_east, '... and going east into an opening should succeed';
is $maze->facing, 'east',
  '... and we should be facing the new direction';


$expected = "...\n   \n...\n";
is $maze->surroundings, $expected,
  '... and we should have the correct surroundings';

can_ok $maze, 'directions';
my @expected = qw/ east west /;
is_deeply [ $maze->directions ], \@expected,
  '... and it should return a list of allowable directions';

# .......
# .  X  . <-- the starting point
# ..... .
# .     .
# . ... .
# .   . .
# ... . .
# . . . .
# . . . .
# .   . .
# . .....

$maze->go_east;
$maze->go_south;
$maze->go_west;
$maze->go_west;
$maze->go_south;
$maze->go_east;
$maze->go_south;
$maze->go_south;
$maze->go_west;
$expected = ". .\n.  \n. .\n";
is $maze->surroundings, $expected, 'We should be able to travel to the exit';

can_ok $maze, 'has_won';
ok !$maze->has_won, '... but we should not have won';
$maze->go_south;
ok $maze->has_won, '... until we have stepped through the exit';
