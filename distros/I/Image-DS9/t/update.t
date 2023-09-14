#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use My::Util;

my $ds9 = start_up();

test_stuff(
    $ds9,
    (
        update => [
            ['now'] => {},
            ['now'] => { out => [ 1, 100, 100, 300, 400, ] },
            []      => {},
            []      => { out => [ 1, 100, 100, 300, 400, ] },
        ],
    ),
);


done_testing;
