package Geo::Geos::Algorithm::LineIntersector;

use Geo::Geos;
use Geo::Geos::Coordinate;

# no overload to string, as it leads to segfault if there is no coordinate?

=x
use overload
   '""' => \&Geo::Geos::Algorithm::LineIntersector::toString,
    'fallback' => 1;
=cut


1;
