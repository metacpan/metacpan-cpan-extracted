package Geo::Geos::Prep::Geometry;

use Geo::Geos;
use Geo::Geos::Geometry;


use overload
    '""' => \&Geo::Geos::Prep::Geometry::toString,
    'fallback' => 1;

1;
