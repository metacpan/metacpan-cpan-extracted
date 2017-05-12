# feature_collection.t

use Test::Most;

use lib 't/lib';
use GeoJSONTests;

use Geo::JSON::FeatureCollection;

my $pkg = 'Geo::JSON::FeatureCollection';

my %properties = ( property_1 => 'foo', property_2 => 'bar' );

my @features =    #
    map {
    GeoJSONTests->object(
        'Feature' => { geometry => $_, properties => {%properties} } )
    }             #
    map { GeoJSONTests->object($_) }    #
    GeoJSONTests->geometry_types;

ok my $feature_collection = $pkg->new(
    {   features   => \@features,
        properties => {%properties},
    }
);

isa_ok $feature_collection, $pkg;

is_deeply $feature_collection->compute_bbox, [ 1, 2, 9, 8 ], "compute_bbox";

done_testing();

