package Geo::Geos::Algorithm::HCoordinate;

use Geo::Geos;
use Geo::Geos::Coordinate;

use overload
    '""' => \&Geo::Geos::Algorithm::HCoordinate::toString,
    'fallback' => 1;


1;
