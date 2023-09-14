#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Test::TempDir::Tiny;
use My::Util;
use Path::Tiny;

my $ds9 = start_up( clear => 1, image => 1 );

# grab a jpeg to play with

in_tempdir 'jpeg' => sub {

    my $cwd = path( shift );

    my $file = $cwd->child( 'full.jpeg' );

    my $jpeg;
    # create a jpeg to reuse
    ok( lives { $jpeg = $ds9->jpeg() }, 'get jpeg' )
      or note_res_error( $ds9 );

    # and for grins, change the lossyness
    ok( lives { $jpeg = $ds9->jpeg( 50 ) }, 'get lossy jpeg' )
      or note_res_error( $ds9 );

    $file->spew_raw( $jpeg );

    subtest 'send file' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->jpeg( $file ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->jpeg( new => $file ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->jpeg( slice => $file ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

    subtest 'send buffer' => sub {

        my $nframes = @{ $ds9->frame( 'all' ) };

        # reuse frame
        ok( lives { $ds9->jpeg( \$jpeg ) }, 'send file' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes, 'reused frame' );

        # new frame
        ok( lives { $ds9->jpeg( new => \$jpeg ) }, 'new frame' )
          or note_res_error( $ds9 );

        is( 0+ @{ $ds9->frame( 'all' ) }, $nframes + 1, 'opened new frame' );

        # this opens up the cube dialogue
        ok( lives { $ds9->jpeg( slice => \$jpeg ) }, 'slice' )
          or note_res_error( $ds9 );
        $ds9->cube( 'close' );

    };

};

done_testing;
