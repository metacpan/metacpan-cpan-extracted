#!perl -T

use Test::More tests => 1;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = eval { Games::Maze::SVG->new( 'InvalidShape' ); };
like( $@, qr/Unrecognized maze shape 'InvalidShape'\.\n/, "Bad shape fails" );
