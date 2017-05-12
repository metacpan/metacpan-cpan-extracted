use Test::More tests => 6;

BEGIN { use_ok('Geo::Cache'); }

my $wpt = Geo::Cache->new(
    lat  => '37',
    lon  => '-85',
    name => 'GC1234',
    desc => 'Sample waypoint',
    sym  => 'Geocache',
    type => 'Geocache|Traditional Cache',
    time => '2004-06-12T20:48:32.0000000-07:00',
);

isa_ok( $wpt, 'Geo::Cache' );
is( $wpt->lat,  37,                'Lat' );
is( $wpt->lon,  -85,               'Lon' );
is( $wpt->name, 'GC1234',          'Name' );
is( $wpt->desc, 'Sample waypoint', 'Description' );

