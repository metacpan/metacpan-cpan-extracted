#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;

use Image::DS9;
use Image::DS9::Constants::V1 -angular_formats, 'FRAME_COORD_SYSTEMS', 'SKY_COORD_SYSTEMS', 'WCS',;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        crosshair => [
            ( map { ( match => { out => [$_] } ) } FRAME_COORD_SYSTEMS ),
            ( map { ( lock  => $_ ) } FRAME_COORD_SYSTEMS, 'none' ),
        ],
    ) );

$ds9->frame( 'center' );

subtest 'retrieve' => sub {

    for my $wcs ( 'wcs', WCS ) {

        subtest $wcs => sub {
          SKIP: {
                skip "don't have $wcs" unless $ds9->frame( has => wcs => ( $wcs eq 'wcs' ? () : $wcs ) );
                my $coords = $ds9->pan( $wcs, ANGULAR_FORMAT_DEGREES );
                $ds9->crosshair( @$coords, $wcs );
                is( $coords, scalar $ds9->crosshair( $wcs, ANGULAR_FORMAT_DEGREES ), 'crosshair' );
            }
        };

    }
};

done_testing;
