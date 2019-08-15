#include "xs/geos.h"
#include "panda/Geos/Helper.h"
#include "panda/Geos/tesselate.h"
#include "xsi/private_typemaps.h"

using xs::my_perl;
using xs::Sv;
using namespace geos::geom;
using namespace geos::geom::prep;
using namespace geos::algorithm;
using namespace geos::noding;
using namespace geos::noding::snapround;
using namespace geos::io;
using namespace geos::index::chain;
using namespace geos::index;
using namespace geos::precision;
using namespace geos::operation::buffer;
using namespace geos::operation::distance;
using namespace geos::operation::overlay;
using namespace geos::operation::valid;
using namespace geos::operation::relate;
using namespace geos::operation::linemerge;
using namespace geos::triangulate;
using namespace xs;
using namespace Geo::Geos;
using namespace panda;

struct IntersectionFinderAdder_payload {
    using vector_t = std::vector<::geos::geom::Coordinate>;

    xs::Object lineIntersector;
    vector_t coords;
};

struct Noder_payload {
    using vector_t = std::vector<::geos::noding::SegmentString*>;

    xs::Ref array_ref;
    vector_t segments;
};


struct MonotoneChain_payload {
    std::unique_ptr<CoordinateSequence> seq;
};

struct SubItemVisitor: public geos::index::ItemVisitor {
    xs::Sub sub;
    Helper::lookup_map_t& lookup_map;

    SubItemVisitor(Sub sub_, Helper::lookup_map_t& lookup_map_):sub{sub_}, lookup_map{lookup_map_} {};
    void visitItem (void *data) {
        SV* key = static_cast<SV*>(data);
        HE* he = hv_fetch_ent(lookup_map, key, 0, 0);
        if (!he) throw ("Cannot lookup key in map");
        Scalar arg {HeVAL(he)};
        sub(arg);
    }
};

struct SVs_map_payload {
    Helper::lookup_map_t map;
    SVs_map_payload(): map{Hash::create()} {}
};

static xs::Sv::payload_marker_t payload_marker{};
static xs::Sv::payload_marker_t payload_marker_IntersectionFinderAdder{};
static xs::Sv::payload_marker_t payload_marker_Noder{};
static xs::Sv::payload_marker_t payload_marker_MonotoneChain{};
static xs::Sv::payload_marker_t payload_marker_SVs_map{};

static int payload_marker_IntersectionFinderAdder_free(pTHX_ SV*, MAGIC* mg) {
    if (mg->mg_virtual == &payload_marker_IntersectionFinderAdder) {
        auto* payload = static_cast<IntersectionFinderAdder_payload*>((void*)mg->mg_ptr);
        delete payload;
    }
    return 0;
}

static int payload_marker_Noder_free(pTHX_ SV*, MAGIC* mg) {
    if (mg->mg_virtual == &payload_marker_Noder) {
        auto* payload = static_cast<Noder_payload*>((void*)mg->mg_ptr);
        delete payload;
    }
    return 0;
}

static int payload_marker_MonotoneChain_free(pTHX_ SV*, MAGIC* mg) {
    if (mg->mg_virtual == &payload_marker_MonotoneChain) {
        auto* payload = static_cast<MonotoneChain_payload*>((void*)mg->mg_ptr);
        delete payload;
    }
    return 0;
}

static int payload_marker_SVs_map_free(pTHX_ SV*, MAGIC* mg) {
    if (mg->mg_virtual == &payload_marker_SVs_map) {
        auto* payload = static_cast<SVs_map_payload*>((void*)mg->mg_ptr);
        delete payload;
    }
    return 0;
}


static Sv coordinate_create_null () {
    Sv ret = xs::out<const Coordinate*>(aTHX_ new Coordinate());
    return ret;
}

static Sv coordinate_get_null () {
    static thread_local Sv obj = coordinate_create_null();
    return obj;
}

//static Sv::payload_marker_t payload_marker;

MODULE = Geo::Geos                PACKAGE = Geo::Geos
PROTOTYPES: DISABLE


INCLUDE: xsi/Coordinate.xsi

INCLUDE: xsi/Dimension.xsi

INCLUDE: xsi/Envelope.xsi

INCLUDE: xsi/PrecisionModel.xsi

INCLUDE: xsi/IntersectionMatrix.xsi

INCLUDE: xsi/Triangle.xsi

INCLUDE: xsi/LineSegment.xsi

INCLUDE: xsi/GeometryFactory.xsi

INCLUDE: xsi/Geometry.xsi

INCLUDE: xsi/GeometryCollection.xsi

INCLUDE: xsi/Point.xsi

INCLUDE: xsi/MultiPoint.xsi

INCLUDE: xsi/LineString.xsi

INCLUDE: xsi/MultiLineString.xsi

INCLUDE: xsi/LinearRing.xsi

INCLUDE: xsi/Polygon.xsi

INCLUDE: xsi/MultiPolygon.xsi

INCLUDE: xsi/WKBConstants.xsi

INCLUDE: xsi/WKBWriter.xsi

INCLUDE: xsi/WKBReader.xsi

INCLUDE: xsi/WKTWriter.xsi

INCLUDE: xsi/WKTReader.xsi

INCLUDE: xsi/PrepGeometry.xsi

INCLUDE: xsi/PrepGeometryFactory.xsi

INCLUDE: xsi/algorithm.xsi

INCLUDE: xsi/algorithm/HCoordinate.xsi

INCLUDE: xsi/algorithm/MinimumDiameter.xsi

INCLUDE: xsi/algorithm/LineIntersector.xsi

INCLUDE: xsi/noding.xsi

INCLUDE: xsi/noding/SegmentString.xsi

INCLUDE: xsi/noding/SegmentNode.xsi

INCLUDE: xsi/noding/NodedSegmentString.xsi

INCLUDE: xsi/noding/BasicSegmentString.xsi

INCLUDE: xsi/noding/SegmentIntersector.xsi

INCLUDE: xsi/noding/SegmentIntersectionDetector.xsi

INCLUDE: xsi/noding/SingleInteriorIntersectionFinder.xsi

INCLUDE: xsi/noding/IntersectionAdder.xsi

INCLUDE: xsi/noding/IntersectionFinderAdder.xsi

INCLUDE: xsi/noding/Noder.xsi

INCLUDE: xsi/noding/IteratedNoder.xsi

INCLUDE: xsi/noding/ScaledNoder.xsi

INCLUDE: xsi/noding/SinglePassNoder.xsi

INCLUDE: xsi/noding/SimpleNoder.xsi

INCLUDE: xsi/noding/SimpleSnapRounder.xsi

INCLUDE: xsi/index/MonotoneChain.xsi

INCLUDE: xsi/index/MonotoneChainOverlapAction.xsi

INCLUDE: xsi/index/SpatialIndex.xsi

INCLUDE: xsi/index/Quadtree.xsi

INCLUDE: xsi/index/STRtree.xsi

INCLUDE: xsi/precision.xsi

INCLUDE: xsi/precision/GeometryPrecisionReducer.xsi

INCLUDE: xsi/precision/SimpleGeometryPrecisionReducer.xsi

INCLUDE: xsi/operation.xsi

INCLUDE: xsi/triangulate/DelaunayTriangulationBuilder.xsi

INCLUDE: xsi/triangulate/VoronoiDiagramBuilder.xsi
