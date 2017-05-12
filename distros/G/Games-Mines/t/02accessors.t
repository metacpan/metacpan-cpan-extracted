#! perl

use strict;
use Test::More tests => 7;

##################

use Games::Mines;

my $game = bless {
		  'field'  => [
			       [qw{00 01 02 03 04 05}],
			       [qw{10 11 12 13 14 15}],
			       [qw{20 21 22 23 24 25}],
			      ],
		  'count' => 7,
		  'flags' => 9,
		  'unknown' => 0,
       		  'why'            => 'foo',
		 },"Games::Mines";
		  
####################
is( $game->width,    2 );
is( $game->height,   5 );
is( $game->count,    7 );
is( $game->why,   'foo');
is( $game->flags,    9 );
ok( $game->_check_mine_placement );
ok( $game->_check_mine_field );
