#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up( events => 1, image => 1, clear => 1 );

test_stuff(
    $ds9,
    (
        blink => [
            ['interval'] => 0.2,
            ['interval'] => 3,
        ],
    ) );

subtest 'no args' => sub {
    ok( lives { $ds9->blink() }, 'blink' )
      or do { note( $@ ); return };
    is( $ds9->blink( 'state' ), T(), 'state' );
};

subtest 'false' => sub {
    ok( lives { $ds9->blink( !!0 ) }, 'blink' )
      or do { note( $@ ); return };
    is( $ds9->blink( 'state' ), F(), 'state' );
};

subtest 'on' => sub {
    ok( lives { $ds9->blink( !!1 ) }, 'blink' )
      or do { note( $@ ); return };

    is( $ds9->blink( 'state' ), T(), 'on' );
};

END {
    $ds9->single;    # return to sanity
}

done_testing;
