#!perl

use Test::More tests => 17;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'RectHex' );

can_ok( $maze, qw/convert_start_position convert_end_position convert_sign_position/);

my ($x, $y) = $maze->convert_start_position( 1, 1 );
is( $x, 2, "start origin x is correct" );
is( $y, 0, "start origin y is correct" );

($x, $y) = $maze->convert_start_position( 10, 10 );
is( $x, 29, "start calc x is correct" );
is( $y, 36, "start calc y is correct" );

($x, $y) = $maze->convert_end_position( 1, 1 );
is( $x, 2, "end origin x is correct" );
is( $y, 6, "end origin y is correct" );

($x, $y) = $maze->convert_end_position( 10, 10 );
is( $x, 29, "end calc x is correct" );
is( $y, 42, "end calc y is correct" );

$maze->{height} = 10*$maze->dy();

($x, $y) = $maze->convert_sign_position( 1, 1 );
is( $x, 10, "entry sign x is correct" );
is( $y, 0, "entry sign y is correct" );

($x, $y) = $maze->convert_sign_position( 10, 10 );
is( $x, 100, "exit sign x is correct" );
is( $y, 120, "exit sign y is correct" );

# check edge conditions
($x, $y) = $maze->convert_sign_position( 10, 5 );
is( $x, 100, "exit sign below middle x is correct" );
is( $y, 40, "exit sign below middle y is correct" );

($x, $y) = $maze->convert_sign_position( 10, 6 );
is( $x, 100, "exit sign below middle x is correct" );
is( $y, 80, "exit sign below middle y is correct" );

