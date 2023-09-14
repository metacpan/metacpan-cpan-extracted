#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

my $width;

ok( lives { $width = $ds9->width }, 'get width' )
  or note_res_error( $ds9 );


test_stuff(
    $ds9,
    (
        width => [
            [] => { out => [ $width - 5 ], in => [ $width - 5 ], sleep => 0.25 },
        ],
    ) );


ok( lives { $ds9->width( $width ) }, 'restore width' )
  or note_res_error( $ds9 );


done_testing;
