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

# fiducial values
my @fiducial = $ds9->crop->@*;

test_stuff(
    $ds9,
    (
        crop => [
            'reset' => {},
            ( map { ( match => { out => [$_] } ) } FRAME_COORD_SYSTEMS ),
            ( map { ( lock  => $_ ) } FRAME_COORD_SYSTEMS, 'none' ),
            []      => [ 20, 20, 9, 9 ],
            'reset' => {},
            []      => { recv_only => 1, in => \@fiducial },
            []      => { out       => [ 30, 30, 20, 20, 'wcs', 'arcsec' ], },
            []      => { recv_only => 1, in => [ 0.5, 0.5, 0, 0 ] },
            'reset' => {},
            []      => { out => [ 20, 20, 9, 9, 'wcs', 'galactic' ], },
            []      => {
                recv_only => 1,
                out       => ['galactic'],
                in        => [ map { float $_ } 121.1752667, -21.5746430, 0.0108567, 0.0108567 ]
            },
            [] => {
                recv_only => 1,
                out       => [ 'galactic', 'sexagesimal' ],
                in        => [ '+121:10:30.960', '-21:34:28.715', float( 0.0108567 ), float( 0.0108567 ) ],
            },
            [] => {
                recv_only => 1,
                out       => [ 'galactic', 'sexagesimal', 'arcsec' ],
                in        => [ '+121:10:30.960', '-21:34:28.715', float( 39.084 ), float( 39.084 ) ],
            },
            [] => {
                recv_only => 1,
                out       => [ 'galactic', 'sexagesimal', 'degrees' ],
                in        => [ '+121:10:30.960', '-21:34:28.715', float( 0.0108567 ), float( 0.0108567 ) ],
            },
        ],
    ),
);

done_testing;
