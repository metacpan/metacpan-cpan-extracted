#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'NAMESERVERS', 'ANGULAR_FORMATS';

use Test::Lib;
use My::Util;

my $ds9 = start_up();

test_stuff(
    $ds9,
    (
        nameserver => [
            ( map { ( server    => $_ ) } NAMESERVERS ),
            ( map { ( skyformat => $_ ) } ANGULAR_FORMATS ),
            name      => 'm31',
            []        => 'NGC5846',
            open      => {},
            close     => {},
            pan       => {},
            crosshair => {},
        ],
    ),
);



$ds9->nameserver( 'close' );

done_testing;
