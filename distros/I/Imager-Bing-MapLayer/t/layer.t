#!/usr/bin/env perl

use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use aliased 'Imager::Bing::MapLayer' => 'Layer';

use File::Find::Rule;
use File::Temp qw/ tempdir /;
use Path::Class qw/ file /;

use Image::Size;
use Imager::Fill;

my $cleanup = $ENV{TMP_NO_CLEANUP} ? 0 : 1;

my $layer;

lives_ok {
    $layer = Layer->new(
        base_dir => tempdir( CLEANUP => $cleanup ),    # FIXME
        overwrite => 1,
        min_level => 6,
        max_level => 16,
    );
}
"new";

my @latlon = ( 51.5171, 0.1062 );                      # London

lives_ok {
    $layer->setpixel( x => $latlon[1], 'y' => $latlon[0], color => 'blue' );
}
"setpixel";

my @tiles = File::Find::Rule->file()->name('*')->in( $layer->base_dir );
ok( $#tiles, "tiles generated" );

my ( $min, $max ) = ( $layer->min_level, $layer->max_level );

foreach my $tile (@tiles) {
    my $file = file($tile);
    like( $file->basename, qr/[0-3]{$min,$max}\.png$/, "expected filename" );

    my ( $width, $height ) = imgsize( $file->stringify );
    is( $width,  256, "tile width" );
    is( $height, 256, "tile height" );

}

done_testing;
