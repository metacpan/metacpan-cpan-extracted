package Geo::Geos::IntersectionMatrix;

use Geo::Geos;

use overload
    '""' => \&Geo::Geos::IntersectionMatrix::toString,
    'fallback' => 1;

1;
