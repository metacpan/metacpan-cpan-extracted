use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use_ok('Geo::Geos::Coordinate');
use_ok('Geo::Geos::Dimension');
use_ok('Geo::Geos::Envelope');
use_ok('Geo::Geos::PrecisionModel');
use_ok('Geo::Geos::IntersectionMatrix');
use_ok('Geo::Geos::Triangle');
use_ok('Geo::Geos::LineSegment');
use_ok('Geo::Geos::GeometryFactory');
use_ok('Geo::Geos::Geometry');
use_ok('Geo::Geos::GeometryCollection');
use_ok('Geo::Geos::Point');
use_ok('Geo::Geos::MultiPoint');
use_ok('Geo::Geos::LineString');
use_ok('Geo::Geos::MultiLineString');
use_ok('Geo::Geos::LinearRing');
use_ok('Geo::Geos::Polygon');
use_ok('Geo::Geos::MultiPolygon');

use_ok('Geo::Geos::WKBConstants');
use_ok('Geo::Geos::WKBReader');
use_ok('Geo::Geos::WKBWriter');
use_ok('Geo::Geos::WKTReader');
use_ok('Geo::Geos::WKTWriter');

use_ok('Geo::Geos::Prep::Geometry');
use_ok('Geo::Geos::Prep::GeometryFactory');

use_ok('Geo::Geos::Algorithm');
use_ok('Geo::Geos::Algorithm::HCoordinate');
use_ok('Geo::Geos::Algorithm::MinimumDiameter');
use_ok('Geo::Geos::Algorithm::LineIntersector');

use_ok('Geo::Geos::Noding');
use_ok('Geo::Geos::Noding::SegmentNode');
use_ok('Geo::Geos::Noding::SegmentString');
use_ok('Geo::Geos::Noding::NodedSegmentString');
use_ok('Geo::Geos::Noding::BasicSegmentString');

use_ok('Geo::Geos::Noding::SegmentIntersector');
use_ok('Geo::Geos::Noding::SegmentIntersectionDetector');
use_ok('Geo::Geos::Noding::SingleInteriorIntersectionFinder');
use_ok('Geo::Geos::Noding::IntersectionAdder');
use_ok('Geo::Geos::Noding::IntersectionFinderAdder');

use_ok('Geo::Geos::Noding::Noder');
use_ok('Geo::Geos::Noding::IteratedNoder');
use_ok('Geo::Geos::Noding::ScaledNoder');
use_ok('Geo::Geos::Noding::SinglePassNoder');
use_ok('Geo::Geos::Noding::SimpleNoder');
use_ok('Geo::Geos::Noding::SimpleSnapRounder');

use_ok('Geo::Geos::Index::MonotoneChain');
use_ok('Geo::Geos::Index::MonotoneChainOverlapAction');
use_ok('Geo::Geos::Index::SpatialIndex');
use_ok('Geo::Geos::Index::Quadtree');
use_ok('Geo::Geos::Index::STRtree');

use_ok('Geo::Geos::Precision');
use_ok('Geo::Geos::Precision::GeometryPrecisionReducer');
use_ok('Geo::Geos::Precision::SimpleGeometryPrecisionReducer');

use_ok('Geo::Geos::Operation');

use_ok('Geo::Geos::Triangulate::DelaunayTriangulationBuilder');
use_ok('Geo::Geos::Triangulate::VoronoiDiagramBuilder');

done_testing;
