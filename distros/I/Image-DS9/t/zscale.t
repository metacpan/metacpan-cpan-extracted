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
        zscale => [
            sample   => 22,
            line     => 33,
            contrast => 0.5,
            []       => {},
        ],
    ) );

done_testing;
