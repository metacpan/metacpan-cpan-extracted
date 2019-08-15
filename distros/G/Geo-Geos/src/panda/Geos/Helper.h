#include "xs/geos.h"
#include <vector>
#include <geos/geom/Geometry.h>
#include <geos/geom/GeometryFactory.h>
#include <geos/geom/CoordinateSequence.h>
#include <geos/geom/CoordinateArraySequence.h>
#include <geos/geom/CoordinateSequenceFactory.h>


namespace Geo{ namespace Geos {

class Helper {
public:
    using CoordinateSequence = ::geos::geom::CoordinateSequence;
    using CoordinateArraySequence = ::geos::geom::CoordinateArraySequence;
    using GeometryFactory = ::geos::geom::GeometryFactory;
    using Geometries = ::std::vector<::geos::geom::Geometry*>;
    using Array = xs::Array;
    using lookup_map_t = xs::Hash;

    static CoordinateSequence* convert_copy(GeometryFactory& factory, Array coords, size_t dims);

    static Array convert_copy(const CoordinateSequence* seq);

    static CoordinateArraySequence convert_coords(Array coords);

    static Geometries convert_geometries(xs::Array geometries);

    static Array wrap_inc_SVs(std::vector<void*>* v, lookup_map_t& lookup_map);
    static SV* store_sv(SV* item, lookup_map_t& lookup_map);

    static xs::Sv uplift(::geos::geom::Geometry*);
};

}}
