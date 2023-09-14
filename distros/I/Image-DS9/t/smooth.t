#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'SMOOTH_FUNCTIONS';
use Cwd;

use Test::Lib;
use My::Util;

my $ds9 = start_up();
load_events( $ds9 );

my $integer = 1;
my $float   = 0.25;

test_stuff(
    $ds9,
    (
        smooth => [
            [] => 1,
            ( map { ( function => $_ ) } SMOOTH_FUNCTIONS ),
            ( map { ( $_       => ++$integer ) } 'radius', 'radiusminor' ),
            ( map { ( $_       => ++$float ) } 'sigma',    'sigmaminor', 'angle' ),
            lock  => !!0,
            lock  => !!1,
            []    => { out => ['match'] },
            open  => {},
            close => {},
        ],
    ) );

done_testing;
