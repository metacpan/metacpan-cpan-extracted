package Geo::Geos::LineSegment;

use Geo::Geos;
use Geo::Geos::Coordinate;

use overload
    '""' => \&Geo::Geos::LineSegment::toString,
    'fallback' => 1;

1;
