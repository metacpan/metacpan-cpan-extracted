#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

my $height;

ok( lives { $height = $ds9->height }, 'get height' )
  or note_res_error( $ds9 );


test_stuff(
    $ds9,
    (
        height => [
            [] => { out => [ $height - 5 ], in => [ $height - 5 ], sleep => 0.25 },
        ],
    ) );


ok( lives { $ds9->height( $height ) }, 'restore height' )
  or note_res_error( $ds9 );


done_testing;
