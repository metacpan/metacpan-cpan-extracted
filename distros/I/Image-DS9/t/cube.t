#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'CUBE_CONTROLS', 'CUBE_COORD_SYSTEMS', 'CUBE_ORDERS', 'WCS';

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        cube => [
            'open'             => {},
            'close'            => {},
            [ 'axes', 'lock' ] => !!1,
            [ 'axes', 'lock' ] => !!0,

            # this doesn't work; not sure what it should do.
            # ( map { ( axis => $_ ) } 1..3 ),

            ['interval'] => 0.2,
            ['interval'] => 3,

            ( map { ( lock => $_ ) } CUBE_COORD_SYSTEMS, 'none' ),

            ( map { ( match => { out => $_ } ) } CUBE_COORD_SYSTEMS ),

            ( map { ( order => $_ ) } CUBE_ORDERS ),

            ( map { ( $_ => {} ) } CUBE_CONTROLS ),

            # just make sure this works; don't care about the result
            ( map { ( $_ => { recv_only => 1 } ) } 'wcs', WCS ),
        ],
    ) );

$ds9->frame( delete => 'all' );
$ds9->cube( order => '123' );
$ds9->frame( 'new' );
$ds9->cube( 'close' );

done_testing;
