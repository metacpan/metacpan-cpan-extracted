#!/usr/bin/env perl

use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use aliased 'Imager::Bing::MapLayer::Level' => 'Level';

use File::Temp qw/ tempdir /;
use Imager::Fill;

my $cleanup = $ENV{TMP_NO_CLEANUP} ? 0 : 1;

my $level;

lives_ok {
    $level = Level->new(
        level     => 10,
        base_dir  => tempdir( CLEANUP => $cleanup ),
        overwrite => 1,
    );
}
"new";

note( $level->base_dir );

my @latlon = ( 51.5171, 0.1062 );    # London

lives_ok {
    $level->setpixel( x => $latlon[1], 'y' => $latlon[0], color => 'blue' );
}
"setpixel";

TODO: {

    local $TODO = "getpixel on levels";

    my $color;

    ok( $color = $level->getpixel( x => $latlon[1], 'y' => $latlon[0] ),
        "getpixel" );

    note( explain $color);

    lives_ok {

        is_deeply( [ $color->rgba ], [ 0, 0, 255, 255 ], "color" );

    }
    "defined color";

}

$level->_cleanup_tiles();

done_testing;

