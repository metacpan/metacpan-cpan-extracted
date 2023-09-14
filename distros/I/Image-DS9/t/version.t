#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Scalar::Util 'isvstring';
use Ref::Util 'is_ref';
use Image::DS9;
use Image::DS9::Util 'parse_version';
use version;

use Test::Lib;
use My::Util;

my $ds9 = start_up();

subtest parse_version => sub {

    my @cmp = ( q{<}, q{=}, q{>} );

    for my $cmp (

        [ \'2.2a1',  v2.1,     1 ],
        [ \'2.2',    v2.2,     0 ],
        [ \'2.2a1',  2.2,      -1 ],
        [ \'2.2b1',  \'2.2a1', 1 ],
        [ \'2.2rc1', \'2.2a1', 1 ],

      )
    {
        my ( $v1, $v2, $res ) = @{$cmp};

        my ( $cv1, $cv2 ) = map { is_ref( $_ ) ? parse_version( $$_ ) : $_ } $v1, $v2;

        ( $v1, $v2 ) = map { is_ref( $_ ) ? $$_ : isvstring( $_ ) ? version->declare( $_ ) : $_ } $v1, $v2;

        is( $cv1 <=> $cv2, $res, sprintf( '%s %s %s', $v1, $cmp[ $res + 1 ], $v2 ), );
    }


};



ok( lives { $ds9->version(); }, 'version' ) or note $@;

done_testing;
