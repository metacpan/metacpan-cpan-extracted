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
        iconify => [
            # [] => { out => !!1 }, On Wayland, iconifying can't be undone.
            [] => { out => !!0 },
        ],
    ),
);


done_testing;
