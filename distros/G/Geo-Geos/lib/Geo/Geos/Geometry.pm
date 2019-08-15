package Geo::Geos::Geometry;

use Geo::Geos;
use Geo::Geos::Coordinate;
use Geo::Geos::IntersectionMatrix;
use Geo::Geos::Point;
use Geo::Geos::PrecisionModel;

use overload
    '""' => \&Geo::Geos::Geometry::toString,
    'fallback' => 1;

1;
