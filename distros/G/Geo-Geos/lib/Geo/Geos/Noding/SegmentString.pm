package Geo::Geos::Noding::SegmentString;

use Geo::Geos;
use Geo::Geos::Coordinate;

use overload
    '""' => \&Geo::Geos::Noding::SegmentString::toString,
    'fallback' => 1;


1;
