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
        block => [
            to    => { out => 4 },
            to    => { out => [ 4, 4 ] },
            to    => { out => 'fit' },
            abs   => { out => 4 },
            abs   => { out => [ 4, 4 ] },
            rel   => { out => 4 },
            rel   => { out => [ 4, 4 ] },
            tofit => {},
            open  => {},
            close => {},
            lock  => !!0,
            lock  => !!1,
            match => {},
            # need this to reset so get expected values
            to => { out => [ 1, 1 ] },
            [] => [ 3, 4 ],
            # need this to reset so get expected values
            0 => {},
            # if blocking is the same, only returns a single value
            [] => { out => [ 3, 3 ], in => 3 },
        ],
    ),
);

done_testing;
