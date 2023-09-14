#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'MINMAX_MODES';

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        minmax => [
            ( map { ( mode => $_ ) } MINMAX_MODES ), ( map { ( [] => $_ ) } MINMAX_MODES ), rescan => {},
        ],
    ),
);


done_testing;
