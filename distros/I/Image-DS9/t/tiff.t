#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Test::TempDir::Tiny;
use My::Util;
use Path::Tiny;
use Image::DS9::Constants::V1 'EXPORT_TIFF_ARGS';

my $ds9 = start_up( clear => 1, image => 1 );

# grab a tiff to play with

in_tempdir 'tiff' => sub {

    my $cwd = path( shift );

    my $file = $cwd->child( 'full.tiff' );

    my $tiff;
    # create a tiff to reuse
    ok( lives { $tiff = $ds9->tiff() }, 'get tiff' )
      or note_res_error( $ds9 );

    # and for grins, change the compression
    test_stuff(
        $ds9,
        (
            tiff => [ ( map { ( $_ => {} ) } EXPORT_TIFF_ARGS ), ],
        ),
    );

    $file->spew_raw( $tiff );

    subtest 'send file' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->tiff( $file ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->tiff( new => $file ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->tiff( slice => $file ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

    subtest 'send buffer' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->tiff( \$tiff ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->tiff( new => \$tiff ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->tiff( slice => \$tiff ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

};

done_testing;
