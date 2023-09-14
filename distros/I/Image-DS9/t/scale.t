#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'SCALE_FUNCTIONS';

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        scale => [
            ( map { ( [] => $_ ) } SCALE_FUNCTIONS ),

            [ 'log', 'exp' ] => 10,

            datasec => !!1,
            datasec => !!0,

            limits => [ -5, 22.33 ],

            ( map { ( mode => $_ ) } 'minmax', 'zscale', 'zmax', 33 ),

            [], { out => ['match'] },
            [], { out => [ 'match', 'limits' ] },
            [ 'lock', 'limits' ] => !!1,
            [ 'lock', 'limits' ] => !!0,

            scope => 'local',
            scope => 'global',
            open  => {},
            close => {},
        ],
    ) );

done_testing;
