#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'DSS_ESO_SURVEYS', 'DSS_STSCI_SURVEYS';
use Cwd;

use Test::Lib;
use My::Util;
use Data::Dump 'pp';

my $ds9 = start_up();
clear( $ds9 );

# nameserver ned-sao seems to be broken
$ds9->nameserver( server => 'ned-cds' );

for my $server ( qw[ dsssao dsseso dssstsci ] ) {

    subtest $server => sub {
        test_stuff(
            $ds9,
            (
                $server => [
                    size => [ 10, 10, 'arcmin' ],
                    name => 'NGC5846',
                    save => !!0,
                    ( map { ( frame  => $_ ) } 'new',              'current' ),
                    ( map { ( update => { out => $_ } ) } 'frame', 'crosshair' ),
                ],
            ) );

        ok( lives { $ds9->$server( name => 'm31' ); }, 'set name' )
          or bail_out pp( $ds9->res ), $@;
        is( $ds9->$server, 'm31', 'get name' );

        my $coord;
        ok( lives { $coord = $ds9->$server( 'coord' ) }, 'get coord' )
          or note_res_error( $ds9 );

        is(
            $coord,
            # at present, can't set the skyformat, which could be
            # either degrees or sexagesimal
            in_set(
                # who knows why this keeps changing...
                [ match qr/00:42:44[.]\d{2}/, match qr/[+]41:16:0\d[.]\d/, 'sexagesimal', ],
                [ within( 10.684793, 1e-3 ),  within( 41.269065, 1e-3 ),   'degrees' ],
            ),
            'get coord',
        );

        $ds9->$server( 'close' );

    };
}

test_stuff(
    $ds9,
    (
        dsseso   => [ ( map { ( survey => $_ ) } DSS_ESO_SURVEYS ), ],
        dssstsci => [ ( map { ( survey => $_ ) } DSS_STSCI_SURVEYS ), ],
    ),
);

$ds9->$_( 'close' ) for qw( dsssao dsseso dssstsci );

$ds9->nameserver( 'close' );

done_testing;
