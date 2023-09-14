#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Test::TempDir::Tiny;
use My::Util;
use Path::Tiny;

my $ds9 = start_up( clear => 1, image => 1 );


# grab a gif to play with

in_tempdir 'gif' => sub {

    my $cwd = path( shift );

    my $file = $cwd->child( 'full.gif' );

    my $gif;
    # create a gif to reuse
    ok( lives { $gif = $ds9->gif() }, 'get gif' )
      or note_res_error( $ds9 );

    $file->spew_raw( $gif );

    subtest 'send file' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->gif( $file ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->gif( new => $file ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->gif( slice => $file ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

    subtest 'send buffer' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->gif( \$gif ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->gif( new => \$gif ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->gif( slice => \$gif ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

};

done_testing;
