#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        orient => [
            ( map { ( [] => $_ ) } qw( x y xy none ) ),
            open  => {},
            close => {},
        ],
    ) );

done_testing;
