package Geo::Geos::Coordinate;

use Geo::Geos;

use overload
    '""' => \&Geo::Geos::Coordinate::toString,
    'eq' => \&Geo::Geos::Coordinate::eq,
    'fallback' => 1;

1;
