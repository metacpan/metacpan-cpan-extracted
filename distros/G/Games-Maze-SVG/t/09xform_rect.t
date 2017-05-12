#!perl

use Test::More tests => 16;

use Games::Maze::SVG;
use FindBin;
use lib "$FindBin::Bin/lib";
use MazeTestUtils;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'Rect' );
can_ok( $maze, "transform_grid", "make_board_array" );

my $simplegrid = <<EOM;
:--:
|  |
:--:
EOM

my $simpleout = [
   [ qw/ul h ur/ ],
   [ qw/v 0 v/ ],
   [ qw/ll h lr/ ],
];
my $simplebevelout = [
   [ qw/oul oh our/ ],
   [ qw/ov 0 ov/ ],
   [ qw/oll oh olr/ ],
];

my $simpleboard = [
   [ qw/1 1 1/ ],
   [ qw/1 0 1/ ],
   [ qw/1 1 1/ ],
];


grid_ok( $simplegrid, 'straight', $simpleout, 'Simple Square grid' );
grid_ok( $simplegrid, 'bevel', $simplebevelout, 'Simple Bevel Square grid' );
grid_ok( $simplegrid, '', $simpleout, 'Empty wallform grid' );
board_ok( $simplegrid, 'straight', $simpleboard, 'Simple Square board' );
board_ok( $simplegrid, 'bevel', $simpleboard, 'Simple Bevel Square board' );


my $rectgrid = <<EOM;
:--:  :--:--:
|  |        |
:  :  :--:  :
|     |     |
:  :--:--:--:
|  |        |
:  :--:--:  :
|           |
:--:  :--:--:
EOM

my $rectout = [
   [ qw/ul  h ur  0  r  h  h  h ur/ ],
   [ qw/ v  0  v  0  0  0  0  0  v/ ],
   [ qw/ v  0  t  0 ul  h  l  0  v/ ],
   [ qw/ v  0  0  0  v  0  0  0  v/ ],
   [ qw/ v  0 ul  h tu  h  h  h tl/ ],
   [ qw/ v  0  v  0  0  0  0  0  v/ ],
   [ qw/ v  0 ll  h  h  h  l  0  v/ ],
   [ qw/ v  0  0  0  0  0  0  0  v/ ],
   [ qw/ll  h  l  0  r  h  h  h lr/ ],
];

my $rectbevelout = [
   [ qw/oul oh our  0 or oh oh oh our/ ],
   [ qw/ ov  0   v  0  0  0  0  0  ov/ ],
   [ qw/ ov  0   t  0 ul  h  l  0  ov/ ],
   [ qw/ ov  0   0  0  v  0  0  0  ov/ ],
   [ qw/ ov  0  ul  h tu  h  h  h otl/ ],
   [ qw/ ov  0   v  0  0  0  0  0  ov/ ],
   [ qw/ ov  0  ll  h  h  h  l  0  ov/ ],
   [ qw/ ov  0   0  0  0  0  0  0  ov/ ],
   [ qw/oll oh  ol  0 or oh oh oh olr/ ],
];

my $rectboard = [
   [ qw/1  1  1  0  1  1  1  1 1/ ],
   [ qw/1  0  1  0  0  0  0  0 1/ ],
   [ qw/1  0  1  0  1  1  1  0 1/ ],
   [ qw/1  0  0  0  1  0  0  0 1/ ],
   [ qw/1  0  1  1  1  1  1  1 1/ ],
   [ qw/1  0  1  0  0  0  0  0 1/ ],
   [ qw/1  0  1  1  1  1  1  0 1/ ],
   [ qw/1  0  0  0  0  0  0  0 1/ ],
   [ qw/1  1  1  0  1  1  1  1 1/ ],
];

grid_ok( $rectgrid, 'straight', $rectout, 'Small Rectangle grid' );
grid_ok( $rectgrid, 'bevel', $rectbevelout, 'Small Beveled Rectangle grid' );
board_ok( $rectgrid, 'straight', $rectboard, 'Small Rectangle board' );
board_ok( $rectgrid, 'bevel', $rectboard, 'Small Beveled Rectangle board' );

my $rectgrid2 = <<EOM;
:--:  :--:--:
|     |     |
:  :--:--:  :
|     |     |
:--:  :  :  :
|     |  |  |
:  :--:  :  :
|        |  |
:--:  :--:--:
EOM

my $rectout2 = [
   [ qw/ul  h  l  0   ul  h  h  h ur/ ],
   [ qw/ v  0  0  0    v  0  0  0  v/ ],
   [ qw/ v  0  r  h cross h  l  0  v/ ],
   [ qw/ v  0  0  0    v  0  0  0  v/ ],
   [ qw/tr  h  l  0    v  0  d  0  v/ ],
   [ qw/ v  0  0  0    v  0  v  0  v/ ],
   [ qw/ v  0  r  h   lr  0  v  0  v/ ],
   [ qw/ v  0  0  0    0  0  v  0  v/ ],
   [ qw/ll  h  l  0    r  h tu  h lr/ ],
];

my $rectbevelout2 = [
   [ qw/oul oh ol  0  oul oh  oh oh our/ ],
   [ qw/ ov  0  0  0    v  0   0  0  ov/ ],
   [ qw/ ov  0  r  h cross h   l  0  ov/ ],
   [ qw/ ov  0  0  0    v  0   0  0  ov/ ],
   [ qw/otr  h  l  0    v  0   d  0  ov/ ],
   [ qw/ ov  0  0  0    v  0   v  0  ov/ ],
   [ qw/ ov  0  r  h   lr  0   v  0  ov/ ],
   [ qw/ ov  0  0  0    0  0   v  0  ov/ ],
   [ qw/oll oh ol  0   or oh otu oh olr/ ],
];

my $rectboard2 = [
   [ qw/ 1  1  1  0    1  1  1  1  1/ ],
   [ qw/ 1  0  0  0    1  0  0  0  1/ ],
   [ qw/ 1  0  1  1    1  1  1  0  1/ ],
   [ qw/ 1  0  0  0    1  0  0  0  1/ ],
   [ qw/ 1  1  1  0    1  0  1  0  1/ ],
   [ qw/ 1  0  0  0    1  0  1  0  1/ ],
   [ qw/ 1  0  1  1    1  0  1  0  1/ ],
   [ qw/ 1  0  0  0    0  0  1  0  1/ ],
   [ qw/ 1  1  1  0    1  1  1  1  1/ ],
];

grid_ok( $rectgrid2, 'straight', $rectout2, 'Small Rectangle 2 grid' );
grid_ok( $rectgrid2, 'bevel', $rectbevelout2, 'Small Beveled Rectangle 2 grid' );
board_ok( $rectgrid2, 'straight', $rectboard2, 'Small Rectangle 2 board' );
board_ok( $rectgrid2, 'bevel', $rectboard2, 'Small Beveled Rectangle 2 board' );

eval { $maze->transform_grid( [ [ qw/| | | |/ ] ], 'straight' ) };
like( $@, qr/Missing block for '/, "Test non-xform of invalid grid." );

eval { $maze->transform_grid( [ [ qw/| | | |/ ] ], 'bevel' ) };
like( $@, qr/Missing block for '/, "Test non-xform of invalid grid." );

# Need more examples to be certain that I've covered all transforms.

# -----------------
# Subroutines

sub grid_ok
{
    my $grid = split_maze( shift );
    my $wall = shift;
    my $out = shift;
    my $msg = shift;

    is_deeply( [$maze->transform_grid( $grid, $wall )],
         $out, $msg );
}


sub board_ok
{
    my $grid = split_maze( shift );
    my $wall = shift;
    my $board = shift;
    my $msg = shift;

    my $rows = [$maze->transform_grid( $grid, $wall )];

    is_deeply( $maze->make_board_array( $rows), $board, $msg );
}
