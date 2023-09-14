#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up();

test_stuff(
    $ds9,
    (
        align => [
            [] => { out => !!1 },
            [] => { out => !!0 },
        ],
    ) );

done_testing;
