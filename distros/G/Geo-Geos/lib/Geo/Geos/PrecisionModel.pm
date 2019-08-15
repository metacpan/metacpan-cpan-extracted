package Geo::Geos::PrecisionModel;

use Geo::Geos;

use overload
    '""'  => \&Geo::Geos::PrecisionModel::toString,
    'fallback' => 1;

1;
