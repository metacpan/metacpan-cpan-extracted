#! perl

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
        pixeltable => [
            []    => { out => !!1 },
            []    => { out => !!0 },
            open  => {},
            close => {},
        ],
    ),
);

done_testing;
