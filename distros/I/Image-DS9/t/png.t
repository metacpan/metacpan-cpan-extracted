#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Test::TempDir::Tiny;
use My::Util;
use Path::Tiny;

my $ds9 = start_up( clear => 1, image => 1 );


# grab a png to play with

in_tempdir 'png' => sub {

    my $cwd = path( shift );

    my $file = $cwd->child( 'full.png' );

    my $png;
    # create a png to reuse
    ok( lives { $png = $ds9->png() }, 'get png' )
      or note_res_error( $ds9 );

    $file->spew_raw( $png );

    subtest 'send file' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->png( $file ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->png( new => $file ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->png( slice => $file ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

    subtest 'send buffer' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->png( \$png ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->png( new => \$png ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->png( slice => \$png ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

};

done_testing;
