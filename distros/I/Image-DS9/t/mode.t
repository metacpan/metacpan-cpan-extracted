#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'MOUSE_BUTTON_MODES';

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        mode => [ map { [] => $_ } MOUSE_BUTTON_MODES ],
    ) );

done_testing;
