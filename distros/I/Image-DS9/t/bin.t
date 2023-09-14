#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'BIN_FUNCTIONS', -bin_functions;

use Test::Lib;
use My::Util;

my $ds9 = start_up( events => 1 );

test_stuff(
    $ds9,
    (
        bin => [
            about      => [ 0.023, 0.023 ],
            buffersize => 256,
            cols       => [qw (rt_x rt_y )],
            factor     => [ 0.050, 0.01 ],
            factor     => { out => 9, in => [ 9, 9 ] },
            depth      => 1,
            filter     => 'rt_time > 0.5',
            ( map { ( function => $_ ) } BIN_FUNCTIONS ),
            lock => !!1,
            lock => !!0,
        ],
    ) );

ok( lives { $ds9->bin( about => 'center' ) }, 'about center' );

ok( lives { $ds9->bin( 'in' ) }, 'in' );

ok( lives { $ds9->bin( 'out' ) }, 'out' );

ok( lives { $ds9->bin( 'tofit' ) }, 'tofit' );

ok( lives { $ds9->bin( 'to fit' ) }, 'to fit' );

ok( lives { $ds9->bin( 'match' ) }, 'match' );

done_testing;
