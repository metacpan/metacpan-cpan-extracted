package Geo::Geos::Index::Quadtree;

use Geo::Geos;

use overload
    '""' => \&Geo::Geos::Index::Quadtree::toString,
    'fallback' => 1;


1;
