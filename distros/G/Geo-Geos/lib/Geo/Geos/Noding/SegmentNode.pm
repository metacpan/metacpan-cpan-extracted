package Geo::Geos::Noding::SegmentNode;

use Geo::Geos;
use Geo::Geos::Coordinate;

use overload
    '""' => \&Geo::Geos::Noding::SegmentNode::toString,
    'fallback' => 1;


1;
