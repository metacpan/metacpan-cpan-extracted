package TypeTest::ES;

use Elastic::Doc;
use Elastic::Model::Types qw(Keyword GeoPoint Binary Timestamp);

# UID and Timestamp tested in Objects

#===================================
has 'keyword_attr' => (
#===================================
    is  => 'ro',
    isa => Keyword,
);

#===================================
has 'geopoint_attr' => (
#===================================
    is  => 'ro',
    isa => GeoPoint,
);

#===================================
has 'binary_attr' => (
#===================================
    is  => 'ro',
    isa => Binary,
);

#===================================
has 'timestamp_attr' => (
#===================================
    is  => 'ro',
    isa => Timestamp,
);

no Elastic::Doc;

1;
