#!perl

use Test::More tests => 17;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'Rect' );

can_ok( $maze, qw/convert_start_position convert_end_position convert_sign_position/);

my ($x, $y) = $maze->convert_start_position( 1, 1 );
is( $x, 1, "start origin x is correct" );
is( $y, 0, "start origin y is correct" );

($x, $y) = $maze->convert_start_position( 10, 10 );
is( $x, 19, "start calc x is correct" );
is( $y, 18, "start calc y is correct" );

($x, $y) = $maze->convert_end_position( 1, 1 );
is( $x, 1, "end origin x is correct" );
is( $y, 2, "end origin y is correct" );

($x, $y) = $maze->convert_end_position( 10, 10 );
is( $x, 19, "end calc x is correct" );
is( $y, 20, "end calc y is correct" );

$maze->{height} = 10*$maze->dy();

($x, $y) = $maze->convert_sign_position( 1, 1 );
is( $x, 15, "entry sign x is correct" );
is( $y, 0, "entry sign y is correct" );

($x, $y) = $maze->convert_sign_position( 10, 10 );
is( $x, 105, "exit sign x is correct" );
is( $y, 120, "exit sign y is correct" );

# check edge conditions
($x, $y) = $maze->convert_sign_position( 10, 5 );
is( $x, 105, "exit sign below middle x is correct" );
is( $y, 40, "exit sign below middle y is correct" );

($x, $y) = $maze->convert_sign_position( 10, 6 );
is( $x, 105, "exit sign below middle x is correct" );
is( $y, 80, "exit sign below middle y is correct" );
