#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Test::TempDir::Tiny;
use Path::Tiny;
use Data::Dump 'pp';

# use Log::Any::Adapter Capture => structured => \&to_xpa, log_level => 'debug';
use Image::DS9;
use Image::DS9::Constants::V1 'CONTOUR_SCALES', 'CONTOUR_METHODS', 'COLORS';
use My::Util;



my $ds9 = start_up( clear => 1, image => 1 );
$ds9->minmax( 'scan' );    # just in case this has been set to something
                           # else, otherwise the contours may not be
                           # generated.

test_stuff(
    $ds9,
    (
        contour => [
            []       => !!0,
            []       => !!1,
            generate => {},
            copy     => {},
            clear    => {},
            convert  => {},
            scope    => 'global',
            scope    => 'local',
            width    => 3,
            ( map { ( scale  => $_ ) } CONTOUR_SCALES ),
            ( map { ( color  => $_ ) } COLORS ),
            ( map { ( method => $_ ) } CONTOUR_METHODS ),
            ( map { ( mode   => $_ ) } 'minmax', 'zscale', 'zmax', 3.33 ),
            limits => [ -5, 22.33 ],
            # the test_stuff machinery can't distinguish between a
            # single argument which is an array and an array of
            # arguments, so the out has to look like a single argument
            # which is an array, but ds9 sends back an array of
            # arguments.
            levels => { out => [ [ 20, 30, 40, 50 ] ], in => [ 20, 30, 40, 50 ] },

            # check that reading the contours back works with both
            # coordsys & skyframe and just coordsys
            [ 'wcs', 'fk5' ] => {},
            ['wcs']          => {},

            dash             => !!0,
            dash             => !!1,
            [ 'log', 'exp' ] => 10,
            nlevels          => 3,
            open             => {},
            close            => {},
        ],
    ) );

subtest 'load/save contours' => sub {

    in_tempdir 'contours' => sub {
        my $cwd = path( shift );

        my $file = $cwd->child( 'my.contours' );

        # turn contours on
        ok( lives { $ds9->contour( !!1 ) }, 'contour on' )
          or do { note( $@, pp( $ds9->res ) ); return; };

        is( $ds9->contour, T(), 'contour is on' )
          or do { note( $@, pp( $ds9->res ) ); return; };

        $ds9->contour( mode    => 'minmax' );
        $ds9->contour( nlevels => 10 );

        ok( lives { $ds9->contour( save => $file, 'wcs', 'fk5' ) }, 'save' )
          or bail_out $@;
        ok( $file->size > 0, 'saved file has contents' );
        chomp( my $file_contents = $file->slurp );

        my $contours1;
        ok( lives { $contours1 = $ds9->contour( 'wcs', 'fk5' ) }, 'retrieve contours' )
          or bail_out $@;

        ok( length( $contours1 ), 'retrieved contour data are not empty' );

        is( $contours1, $file_contents, 'saved and returned are the same' );

        # something seems always to open the contour parameter window.
        $ds9->contour( 'close' );
    };

};

subtest 'load/save levels' => sub {

    in_tempdir 'levels' => sub {
        my $cwd = path( shift );

        my $file = $cwd->child( 'my.levels' );

        # turn contours on
        ok( lives { $ds9->contour( !!1 ) }, 'contour on' )
          or do { note( $@, pp( $ds9->res ) ); return; };

        is( $ds9->contour, T(), 'contour is on' )
          or do { note( $@, pp( $ds9->res ) ); return; };

        # send some levels upstream so we know what they are
        ok( lives { $ds9->contour( levels => [ 2000, 4000, 9000 ] ) }, 'send levels' )
          or bail_out $@;

        ok( lives { $ds9->contour( save => levels => $file ) }, 'save' )
          or bail_out $@;

        my @levels1;
        ok( lives { @levels1 = $ds9->contour( 'levels' ) }, 'retrieve levels' )
          or bail_out $@;

        # now send some other levels upstream
        ok( lives { $ds9->contour( levels => [ 3000, 5000, 8000 ] ) }, 'send levels' )
          or bail_out $@;

        my @levels2;
        ok( lives { @levels2 = $ds9->contour( 'levels' ) }, 'retrieve levels' )
          or bail_out $@;

        isnt( \@levels1, \@levels2, 'replaced levels' );

        # now load previous levels
        ok( lives { $ds9->contour( load => levels => $file ) }, 'load' )
          or bail_out $@;

        my @levels3;
        ok( lives { @levels3 = $ds9->contour( 'levels' ) }, 'retrieve levels' )
          or bail_out $@;

        {
            my $todo = todo 'this seems to be broken in 8.4.1';
            is( \@levels1, \@levels3, 'loaded levels' );
        }

        # something seems always to
        $ds9->contour( 'close' );
    };

};

# just in case;
END { $ds9->contour( 'close' ); }

done_testing;
