#!perl

use Test::More tests => 7;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new();
can_ok( $maze, "make_board_array" );

my $rectangle = [
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

my $rect_board = [
   [ qw/1  1  1  0  1  1  1  1  1/ ],
   [ qw/1  0  1  0  0  0  0  0  1/ ],
   [ qw/1  0  1  0  1  1  1  0  1/ ],
   [ qw/1  0  0  0  1  0  0  0  1/ ],
   [ qw/1  0  1  1  1  1  1  1  1/ ],
   [ qw/1  0  1  0  0  0  0  0  1/ ],
   [ qw/1  0  1  1  1  1  1  0  1/ ],
   [ qw/1  0  0  0  0  0  0  0  1/ ],
   [ qw/1  1  1  0  1  1  1  1  1/ ],
];

is_deeply( $maze->make_board_array( $rectangle ),
           $rect_board,
	   "straight rectangle" );

my $rectanglebevel = [
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

my $rectbevel_board = [
   [ qw/1  1  1  0  1  1  1  1  1/ ],
   [ qw/1  0  1  0  0  0  0  0  1/ ],
   [ qw/1  0  1  0  1  1  1  0  1/ ],
   [ qw/1  0  0  0  1  0  0  0  1/ ],
   [ qw/1  0  1  1  1  1  1  1  1/ ],
   [ qw/1  0  1  0  0  0  0  0  1/ ],
   [ qw/1  0  1  1  1  1  1  0  1/ ],
   [ qw/1  0  0  0  0  0  0  0  1/ ],
   [ qw/1  1  1  0  1  1  1  1  1/ ],
];

is_deeply( $maze->make_board_array( $rectanglebevel ),
           $rectbevel_board,
	   "beveled rectangle" );

$maze = Games::Maze::SVG->new( 'RectHex' );
can_ok( $maze, "make_board_array" );

my $recthex = [
   [ qw/ 0 tl hz tr  0  0   0  tl hz tr  0  0  0   0  0/ ],
   [ qw/sr $  0  sl  $  0   sr $  0  sl  $  0  0   0  0/ ],
   [ qw/cl 0  0  0   yr hz  br 0  0  0  slb 0 slt  0  0/ ],
   [ qw/sl $  0  sr  $  0   0  0  0  0   0  0  sl  $  0/ ],
   [ qw/ 0 cr 0  cl  0  0   0  tl hz hzl 0  0  0   cr 0/ ],
   [ qw/sr $  0  sl  $  0   sr $  0  0   0  0  sr  $  0/ ],
   [ qw/cl 0  0  0   cr 0   cl 0  0  0  hzr hz yl  0  0/ ],
   [ qw/sl $  0  sr  $  0   sl $  0  0   0  0  sl  $  0/ ],
   [ qw/ 0 cr 0  cl  0  0   0  bl hz tr  0  0  0   cr 0/ ],
   [ qw/sr $  0  sl  $  0   0  0  0  sl  $  0  sr  $  0/ ],
   [ qw/cl 0  0  0   yr hz hzl 0  0  0   cr 0  cl  0  0/ ],
   [ qw/sl $  0  sr  $  0   0  0  0  sr  $  0  sl  $  0/ ],
   [ qw/ 0 cr 0  cl  0  0   0  tl hz yl  0  0  0   cr 0/ ],
   [ qw/sr $  0  sl  $  0   sr $  0  sl  $  0  sr  $  0/ ],
   [ qw/cl 0  0  0  slb 0   cl 0  0  0  slb 0  cl  0  0/ ],
   [ qw/sl $  0  0   0  0   sl $  0  0   0  0  sl  $  0/ ],
   [ qw/ 0 bl hz tr  0  0   0  yr hz tr  0  0  0   cr 0/ ],
   [ qw/ 0 0  0  sl  $  0   sr $  0  sl  $  0  sr  $  0/ ],
   [ qw/ 0 0  0  0   bl hz  br 0  0  0  slb 0 srb  0  0/ ],
];

my $recthex_board = [
   [ qw/ 0 1  1  1   0  0   0  1  1  1   0  0  0   0  0/ ],
   [ qw/ 1 1  0  1   1  0   1  1  0  1   1  0  0   0  0/ ],
   [ qw/ 1 0  0  0   1  1   1  0  0  0   1  0  1   0  0/ ],
   [ qw/ 1 1  0  1   1  0   0  0  0  0   0  0  1   1  0/ ],
   [ qw/ 0 1  0  1   0  0   0  1  1   1  0  0  0   1  0/ ],
   [ qw/ 1 1  0  1   1  0   1  1  0  0   0  0  1   1  0/ ],
   [ qw/ 1 0  0  0   1  0   1  0  0  0   1  1  1   0  0/ ],
   [ qw/ 1 1  0  1   1  0   1  1  0  0   0  0  1   1  0/ ],
   [ qw/ 0 1  0  1   0  0   0  1  1  1   0  0  0   1  0/ ],
   [ qw/ 1 1  0  1   1  0   0  0  0  1   1  0  1   1  0/ ],
   [ qw/ 1 0  0  0   1  1   1  0  0  0   1  0  1   0  0/ ],
   [ qw/ 1 1  0  1   1  0   0  0  0  1   1  0  1   1  0/ ],
   [ qw/ 0 1  0  1   0  0   0  1  1  1   0  0  0   1  0/ ],
   [ qw/ 1 1  0  1   1  0   1  1  0  1   1  0  1   1  0/ ],
   [ qw/ 1 0  0  0   1  0   1  0  0  0   1  0  1   0  0/ ],
   [ qw/ 1 1  0  0   0  0   1  1  0  0   0  0  1   1  0/ ],
   [ qw/ 0 1  1  1   0  0   0  1  1  1   0  0  0   1  0/ ],
   [ qw/ 0 0  0  1   1  0   1  1  0  1   1  0  1   1  0/ ],
   [ qw/ 0 0  0  0   1  1   1  0  0  0   1  0  1   0  0/ ],
];

is_deeply( $maze->make_board_array( $recthex ),
           $recthex_board,
	   "rectangle, hex cells" );

$maze = Games::Maze::SVG->new( 'Hex' );
can_ok( $maze, "make_board_array" );

my $hexagon = [
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

my $hexagon_board = [
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

is_deeply( $maze->make_board_array( $hexagon ),
           $hexagon_board,
	   "hexagonal maze" );

