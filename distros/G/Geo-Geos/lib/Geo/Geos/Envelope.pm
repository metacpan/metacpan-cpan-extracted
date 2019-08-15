package Geo::Geos::Envelope;

use Geo::Geos;
use Geo::Geos::Coordinate;

use overload
    '""' => \&Geo::Geos::Envelope::toString,
    'eq' => \&Geo::Geos::Envelope::eq,
    'fallback' => 1;

1;
