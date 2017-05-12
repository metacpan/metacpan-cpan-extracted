#!perl

use Test::More tests => 6;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestString;
use MazeTestUtils;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'Rect' );

is_deeply( $maze->{mazeparms}->{dimensions}, [ 12, 12, 1 ],
           "default params are okay." );

$maze = Games::Maze::SVG->new( 'Rect', cols => 10 );

is_deeply( $maze->{mazeparms}->{dimensions}, [ 10, 12, 1 ],
           "Setting columns works" );

$maze = Games::Maze::SVG->new( 'Rect', rows => 10 );

is_deeply( $maze->{mazeparms}->{dimensions}, [ 12, 10, 1 ],
           "Setting rows works" );

$maze = Games::Maze::SVG->new( 'Rect', cols => 11, rows => 10 );

is_deeply( $maze->{mazeparms}->{dimensions}, [ 11, 10, 1 ],
           "Setting both works" );

$maze = Games::Maze::SVG->new( 'Rect', startcol => 11 );

is_deeply( $maze->{mazeparms}->{entry}, [ 11, 1, 1 ],
           "Setting entry works" );

$maze = Games::Maze::SVG->new( 'Rect', endcol => 10 );

is_deeply( $maze->{mazeparms}->{exit}, [ 10, 12, 1 ],
           "Setting exit works" );

