#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Path::Tiny;

use Test::Lib;
use Test::TempDir::Tiny;
use My::Util;

my $ds9 = start_up();
load_events( $ds9 );

test_stuff(
    $ds9,
    (
        cmap => [
            []                  => 'heat',
            'file'              => { in => 'heat.sao' },
            invert              => 1,
            value               => [ 0.2, 0.3 ],
            open                => {},
            close               => {},
            [ 'tag', 'delete' ] => {},
        ],
    ) );

in_tempdir 'cmap' => sub {

    my $cwd = path( shift );

    # don't ask ds9 to chdir to the temp directory, as if we
    # forget/fail to ask it to chdir back and remove the tempdir from
    # underneath it, eventually (v8.4.1) it will segv

    subtest 'cmap' => sub {
        my $file = $cwd->child( 'my.cmap' );

        ok( lives { $ds9->cmap( save => $file ) }, 'save' )
          or bail_out $@;

        ok( $file->exists, 'saved file exists' );

        ok( lives { $ds9->cmap( load => $file ) }, 'load' )
          or bail_out $@;

        ok( scalar $ds9->cmap( 'file' ), $file, 'retrieve file name' );
        ok( scalar $ds9->cmap,           'my',  'retrieve cmap name' );
    };

    subtest 'tag' => sub {
        my $file = $cwd->child( 'my.tags' );

        ok( lives { $ds9->cmap( tag => save => $file ) }, 'save' )
          or bail_out $@;

        ok( -f $file, 'saved file exists' );

        ok( lives { $ds9->cmap( tag => load => $file ) }, 'load' )
          or bail_out $@;
    };

};

done_testing;
