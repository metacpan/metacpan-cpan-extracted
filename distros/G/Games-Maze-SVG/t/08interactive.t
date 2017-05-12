#!perl -T

use Test::More tests => 4;

use Games::Maze::SVG;

use strict;
use warnings;

# Default constructor.
my $maze = Games::Maze::SVG->new();

can_ok( $maze, "set_interactive" );

ok( !$maze->{interactive}, "Not interactive, by default." );
is( $maze->set_interactive(), $maze, "Set interactive" );
ok( $maze->{interactive}, "Now interactive." );

