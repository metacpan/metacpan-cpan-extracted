#!perl

use Test::More tests => 6;

use Games::Maze::SVG;
use FindBin;
use lib "$FindBin::Bin/lib";
use MazeTestUtils;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'Hex' );
can_ok( $maze, "transform_grid", "make_board_array" );

my $simplegrid = normalize_maze( <<'EOM' );
 __ 
/  \
\__/
EOM

my $simpleout = [
   [ qw/ 0 tl hz tr  0 0/ ],
   [ qw/sr  $  0 sl  $ 0/ ],
   [ qw/cl  0  0  0 cr 0/ ],
   [ qw/sl  $  0 sr  $ 0/ ],
   [ qw/ 0 bl hz br  0 0/ ],
];

my $simpleboard = [
   [ qw/ 0  1  1  1  0 0/ ],
   [ qw/ 1  1  0  1  1 0/ ],
   [ qw/ 1  0  0  0  1 0/ ],
   [ qw/ 1  1  0  1  1 0/ ],
   [ qw/ 0  1  1  1  0 0/ ],
];

grid_ok( $simplegrid, $simpleout, 'Simple Hex grid' );
board_ok( $simplegrid, $simpleboard, 'Simple Hex board' );

my $hexgrid = normalize_maze( <<'EOM' );
          __
         /  \__
    __/  \     \__
 __/  \     \__   \__ 
/     /  \__/   __/  \
\  /  \  /  \__      /
/  \__   \__   \__/  \
\     \__/  \  /   __/
/  \__      /  \__   \
\  /  \__/  \  /  \  /
/  \  /   __/     /  \
\__   \  /  \__/  \  /
   \__/  \      __/
      \__   \__/  
         \__/
EOM

my $hexout = [
   [ qw/0  0  0  0   0  0  0   0  0  0   tl hz  tr 0  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  sr  $  0   sl $  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0  srt 0  cl  0  0   0  bl hz  tr  0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  sr  0  0  sl  $  0   0  0  0   sl  $   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   tl hz yl  0  0  0  slb 0  slt 0  0   0   bl  hz  tr  0   0   0   0   0/ ],
   [ qw/0  0  0  sr  $  0  sl  $  0  0   0  0   sl $  0   0   0   0   sl  $   0   0   0   0/ ],
   [ qw/0  tl hz br  0  0  0   cr 0 slt  0  0   0  yr hz hzl  0   0   0   yr  hz  tr  0   0/ ],
   [ qw/sr $  0  0   0  0  sr  $  0  sl  $  0   sr $  0   0   0   0   sr  $   0   sl  $   0/ ],
   [ qw/cl 0  0  0  srt 0  cl  0  0  0   yr hz  yl 0  0   0  hzr  hz  br  0   0   0   cr  0/ ],
   [ qw/sl $  0  sr  0  0  sl  $  0  sr  $  0   sl $  0   0   0   0   0   0   0   sr  $   0/ ],
   [ qw/0  cr 0  cl  0  0  0  slb 0  cl  0  0   0  bl hz  tr  0   0   0  srt  0   cl  0   0/ ],
   [ qw/sr $  0  sl  $  0  0   0  0  sl  $  0   0  0  0   sl  $   0   sr  0   0   sl  $   0/ ],
   [ qw/cl 0  0  0   bl hz tr  0  0  0   yr hz  tr 0  0   0   yr  hz  br  0   0   0   cr  0/ ],
   [ qw/sl $  0  0   0  0  sl  $  0  sr  $  0   sl $  0   sr  $   0   0   0   0   sr  $   0/ ],
   [ qw/0  cr 0 slt  0  0  0   bl hz br  0  0   0  cr 0   cl  0   0   0  hzr  hz  yl  0   0/ ],
   [ qw/sr $  0  sl  $  0  0   0  0  0   0  0   sr $  0   sl  $   0   0   0   0   sl  $   0/ ],
   [ qw/cl 0  0  0   yr hz tr  0  0  0  srt 0   cl 0  0   0   yr  hz  tr  0   0   0   cr  0/ ],
   [ qw/sl $  0  sr  $  0  sl  $  0  sr  0  0   sl $  0   sr  $   0   sl  $   0   sr  $   0/ ],
   [ qw/0  cr 0  cl  0  0  0   yr hz br  0  0   0  cr 0  srb  0   0   0   cr  0   cl  0   0/ ],
   [ qw/sr $  0  sl  $  0  sr  $  0  0   0  0   sr $  0   0   0   0   sr  $   0   sl  $   0/ ],
   [ qw/cl 0  0  0  slb 0  cl  0  0  0   tl hz  yl 0  0   0  srt  0   cl  0   0   0   cr  0/ ],
   [ qw/sl $  0  0   0  0  sl  $  0  sr  $  0   sl $  0   sr  0   0   sl  $   0   sr  $   0/ ],
   [ qw/0  bl hz tr  0  0  0   cr 0  cl  0  0   0  bl hz  br  0   0   0   cr  0  srb  0   0/ ],
   [ qw/0  0  0  sl  $  0  sr  $  0  sl  $  0   0  0  0   0   0   0   sr  $   0   0   0   0/ ],
   [ qw/0  0  0  0   bl hz yl  0  0  0  slb 0  slt 0  0   0   tl  hz  br  0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  sl  $  0  0   0  0   sl $  0   sr  $   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   bl hz tr  0  0   0  yr hz  br  0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  sl  $  0   sr $  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  0   bl hz  br 0  0   0   0   0   0   0   0   0   0   0/ ]
];

my $hexboard = [
   [ qw/0  0  0  0   0  0  0   0  0  0   1  1   1  0  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  1   1  0   1  1  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   1  0  1   0  0   0  1  1   1   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  1   0  0  1   1  0   0  0  0   1   1   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   1  1  1   0  0  0   1  0   1  0  0   0   1   1   1   0   0   0   0   0/ ],
   [ qw/0  0  0  1   1  0  1   1  0  0   0  0   1  1  0   0   0   0   1   1   0   0   0   0/ ],
   [ qw/0  1  1  1   0  0  0   1  0  1   0  0   0  1  1   1   0   0   0   1   1   1   0   0/ ],
   [ qw/1  1  0  0   0  0  1   1  0  1   1  0   1  1  0   0   0   0   1   1   0   1   1   0/ ],
   [ qw/1  0  0  0   1  0  1   0  0  0   1  1   1  0  0   0   1   1   1   0   0   0   1   0/ ],
   [ qw/1  1  0  1   0  0  1   1  0  1   1  0   1  1  0   0   0   0   0   0   0   1   1   0/ ],
   [ qw/0  1  0  1   0  0  0   1  0  1   0  0   0  1  1   1   0   0   0   1   0   1   0   0/ ],
   [ qw/1  1  0  1   1  0  0   0  0  1   1  0   0  0  0   1   1   0   1   0   0   1   1   0/ ],
   [ qw/1  0  0  0   1  1  1   0  0  0   1  1   1  0  0   0   1   1   1   0   0   0   1   0/ ],
   [ qw/1  1  0  0   0  0  1   1  0  1   1  0   1  1  0   1   1   0   0   0   0   1   1   0/ ],
   [ qw/0  1  0  1   0  0  0   1  1  1   0  0   0  1  0   1   0   0   0   1   1   1   0   0/ ],
   [ qw/1  1  0  1   1  0  0   0  0  0   0  0   1  1  0   1   1   0   0   0   0   1   1   0/ ],
   [ qw/1  0  0  0   1  1  1   0  0  0   1  0   1  0  0   0   1   1   1   0   0   0   1   0/ ],
   [ qw/1  1  0  1   1  0  1   1  0  1   0  0   1  1  0   1   1   0   1   1   0   1   1   0/ ],
   [ qw/0  1  0  1   0  0  0   1  1  1   0  0   0  1  0   1   0   0   0   1   0   1   0   0/ ],
   [ qw/1  1  0  1   1  0  1   1  0  0   0  0   1  1  0   0   0   0   1   1   0   1   1   0/ ],
   [ qw/1  0  0  0   1  0  1   0  0  0   1  1   1  0  0   0   1   0   1   0   0   0   1   0/ ],
   [ qw/1  1  0  0   0  0  1   1  0  1   1  0   1  1  0   1   0   0   1   1   0   1   1   0/ ],
   [ qw/0  1  1  1   0  0  0   1  0  1   0  0   0  1  1   1   0   0   0   1   0   1   0   0/ ],
   [ qw/0  0  0  1   1  0  1   1  0  1   1  0   0  0  0   0   0   0   1   1   0   0   0   0/ ],
   [ qw/0  0  0  0   1  1  1   0  0  0   1  0   1  0  0   0   1   1   1   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  1   1  0  0   0  0   1  1  0   1   1   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   1  1  1   0  0   0  1  1   1   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  1   1  0   1  1  0   0   0   0   0   0   0   0   0   0/ ],
   [ qw/0  0  0  0   0  0  0   0  0  0   1  1   1  0  0   0   0   0   0   0   0   0   0   0/ ]
];

grid_ok( $hexgrid, $hexout, 'Hexagon maze grid' );
board_ok( $hexgrid, $hexboard, 'Hexagon maze board' );

eval { $maze->transform_grid( [ [ qw/| | | |/ ] ], 'straight' ) };
like( $@, qr/Missing block for '/, "Test non-xform of invalid grid." );

# Need more examples to be certain that I've covered all transforms.

# -----------------
# Subroutines

sub grid_ok
{
    my $grid = split_maze( shift );
    my $out = shift;
    my $msg = shift;
    is_deeply( [$maze->transform_grid( $grid, 'straight' )],
         $out, $msg );
}


sub board_ok
{
    my $grid = split_maze( shift );
    my $board = shift;
    my $msg = shift;

    my $rows = [$maze->transform_grid( $grid, 'straight' )];

    is_deeply( $maze->make_board_array( $rows), $board, $msg );
}
