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
        preserve => [
            pan     => !!0,
            pan     => !!1,
            regions => !!0,
            regions => !!1,
        ],
    ),
);


done_testing;
