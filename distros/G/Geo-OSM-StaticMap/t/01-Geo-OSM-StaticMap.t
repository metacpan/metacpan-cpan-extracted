#!/usr/bin/env perl

use Test::More tests => 6;

use Config;

BEGIN {
    use_ok( 'Geo::OSM::StaticMap' );
}

my $staticmap = Geo::OSM::StaticMap->new(
    center  => [ 48.213950, 16.336290 ], # lat, lon
    zoom    => 17,
    size    => [ 756, 476 ], # width, height
    markers => [ [ 48.213950, 16.336290, 'red-pushpin' ] ], # lat, lon, marker
    maptype => 'mapnik',
);
is( $staticmap->url(), 'http://staticmap.openstreetmap.de/staticmap.php?center=48.21395,16.33629&zoom=17&size=756x476&markers=48.21395,16.33629,red-pushpin&maptype=mapnik', 'Got expected URL with explicit center and zoom');

# Test center and zoom calculation from markers
my $staticmap_url = Geo::OSM::StaticMap->new(
    size    => [ 756, 476 ],
    markers => [ [ 51.8785011494, -0.3767887732, 'ol-marker' ],
                 [ 51.455313, -2.591902, 'ol-marker' ], ])->url();

# Precision of the calculated center depends on Perl having uselongdouble defined or not
if ( defined $Config::Config{uselongdouble} ) {
    is( $staticmap_url, 'http://staticmap.openstreetmap.de/staticmap.php?center=51.6721152964046982,-1.48951902731528178&zoom=8&size=756x476&markers=51.8785011494,-0.3767887732,ol-marker|51.455313,-2.591902,ol-marker&maptype=mapnik', 'Got expected URL with center and zoom calculated from markers (uselongdouble');
}
else {
    is( $staticmap_url, 'http://staticmap.openstreetmap.de/staticmap.php?center=51.6721152964047,-1.48951902731528&zoom=8&size=756x476&markers=51.8785011494,-0.3767887732,ol-marker|51.455313,-2.591902,ol-marker&maptype=mapnik', 'Got expected URL with center and zoom calculated from markers (no uselongdouble)');
}

my $staticmap_defaults_test = Geo::OSM::StaticMap->new();
is_deeply( $staticmap_defaults_test->center, [0,0], 'Got expected default center');
is( $staticmap_defaults_test->zoom, 17, 'Got expected default zoom');
is_deeply( $staticmap_defaults_test->size, [500,350], 'Got expected default size');


