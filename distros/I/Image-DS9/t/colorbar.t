#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;

use Image::DS9;
use Image::DS9::Constants::V1
  'COLORBAR_ORIENTATIONS',
  'FONTS',
  'FONTWEIGHTS',
  'FONTSLANTS',
  ;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

test_stuff(
    $ds9,
    (
        colorbar => [
            []       => !!0,
            []       => !11,
            numerics => !!0,
            numerics => !!1,
            space    => 'value',
            space    => 'distance',
            ( map { ( font => $_ ) } FONTS ),
            fontsize => 22,
            ( map { ( fontweight  => $_ ) } FONTWEIGHTS ),
            ( map { ( fontslant   => $_ ) } FONTSLANTS ),
            ( map { ( orientation => $_ ) } COLORBAR_ORIENTATIONS ),
            ( map { ( $_          => {} ) } COLORBAR_ORIENTATIONS ),
            size  => 3,
            ticks => 10,
            lock  => { out => !!0 },
            lock  => { out => !!1 },
        ],
    ),
);

subtest 'lock state' => sub {

    my $test = sub {
        my $in;
        my $out = shift;
        ok( lives { $ds9->colorbar( lock => $out ) },          'lock' );
        ok( lives { $in = $ds9->colorbar( lock => 'state' ) }, 'get' );
        is( $in, $out, 'value' );
    };

    subtest 'locked',   $test, !!1;
    subtest 'unlocked', $test, !!0;

};

done_testing;
