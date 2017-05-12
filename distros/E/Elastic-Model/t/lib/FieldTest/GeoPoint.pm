package FieldTest::GeoPoint;

use Elastic::Doc;
use Elastic::Model::Types qw(GeoPoint);

#===================================
has 'basic_attr' => (
#===================================
    is  => 'ro',
    isa => GeoPoint,
);

#===================================
has 'options_attr' => (
#===================================
    is                  => 'ro',
    isa                 => GeoPoint,
    'lat_lon'           => 1,
    'geohash'           => 1,
    'geohash_precision' => 8,
    'index_name'        => 'foo',
    store               => 1,
);

#===================================
has 'multi_attr' => (
#===================================
    is    => 'ro',
    isa   => GeoPoint,
    multi => { one => { geohash_precision => 2 } }
);

#===================================
has 'bad_opt_attr' => (
#===================================
    is       => 'ro',
    isa      => GeoPoint,
    analyzer => 'standard',
);

#===================================
has 'bad_multi_attr' => (
#===================================
    is    => 'ro',
    isa   => GeoPoint,
    multi => { one => { analyzer => 'standard' } }
);

1;
