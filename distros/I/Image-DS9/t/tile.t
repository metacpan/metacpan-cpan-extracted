#! perl

use v5.10;

use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up();
$ds9->file( M31_FITS );
$ds9->file( M31_FITS, { new => 1 } );


test_stuff(
    $ds9,
    (
        tile => [
            []                => 1,
            mode              => 'column',
            mode              => 'row',
            mode              => 'grid',
            [qw( grid mode )] => 'manual',
            [qw( grid mode )] => 'automatic',

            # bug in version 8.4.1; returns the wrong # of dims
            ( $ds9->version != v8.4.1 ? ( [qw( grid layout )] => [ 5, 5 ] ) : () ),

            [qw( grid gap )] => 3,
            []               => !!0,
        ],
    ) );

done_testing;
