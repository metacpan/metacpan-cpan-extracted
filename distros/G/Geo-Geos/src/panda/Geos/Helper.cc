#include "Helper.h"

using namespace Geo::Geos;
using namespace xs;
using namespace geos::geom;


static double get_ordinate(const ::geos::geom::Coordinate* c, size_t idx) {
    if (idx == 0) return c->x;
    if (idx == 1) return c->y;
    if (idx == 2) return c->z;
    throw "unknown ordinate";
}

Helper::CoordinateSequence* Helper::convert_copy(Helper::GeometryFactory& factory, Helper::Array coords, size_t dims) {
    if (!coords) throw("wrong argument");
    auto size = coords.size();
    Helper::CoordinateSequence* seq = factory.getCoordinateSequenceFactory()->create(size, dims);
    for(size_t i = 0; i < size; ++i)  {
        auto& coord = xs::in<Coordinate&>(coords[i]);
        for(size_t j = 0; j < dims; ++j) {
            seq->setOrdinate(i, j, get_ordinate(&coord, j));
        }
    }
    return seq;
}

Helper::Array Helper::convert_copy(const Helper::CoordinateSequence* seq) {
    auto size = seq->size();
    auto arr = xs::Array::create(size);
    for(size_t idx = 0; idx < size; ++idx) {
        Coordinate native_coord;
        seq->getAt(idx, native_coord);
        Coordinate* copy_coord = new Coordinate(native_coord);
        auto coord = xs::out<Coordinate*>(copy_coord);
        arr.push(coord);
    }
    return arr;
}

Helper::CoordinateArraySequence Helper::convert_coords(Helper::Array coords) {
    CoordinateArraySequence seq;
    for(const auto& c: coords) {
        seq.add( xs::in<Coordinate&>(c) );
    }
    return seq;
}


Helper::Geometries Helper::convert_geometries(Helper::Array geometries) {
    Geometries result;
    result.reserve(geometries.size());
    for(const auto& item: geometries) {
        auto& g = xs::in<Geometry&>(item);
        result.push_back(&g);
    }
    return result;
}

xs::Array Helper::wrap_inc_SVs(std::vector<void*>* v, Helper::lookup_map_t& lookup_map) {
    if (v) {
        Array result = Array::create(v->size());
        for(auto it: *v) {
            SV* key = static_cast<SV*>(it);
            HE* he = hv_fetch_ent(lookup_map, key, 0, 0);
            if (!he) throw ("Cannot lookup key in map");
            result.push(Sv(HeVAL(he)));
        }
        return result;
    }
    return Array{};
}

SV* Helper::store_sv(SV* item, lookup_map_t& lookup_map) {
    SV* value;
    HE* he = hv_fetch_ent(lookup_map, item, 0, 0);
    if (he) {
       value = HeVAL(he);
    }
    else  {
       value = newSVsv(item);
       auto result = hv_store_ent(lookup_map, value, value, 0);
       if (!result) {
            SvREFCNT_dec(value);
            throw "cannot store value in hash";
        }
   }
    return value;
}

Sv Helper::uplift(::geos::geom::Geometry* g) {
    using namespace panda;
    switch (g->getGeometryTypeId()) {
        case GEOS_POINT: return xs::out<>(dyn_cast<geos::geom::Point*>(g));
        case GEOS_LINESTRING: return xs::out<>(dyn_cast<geos::geom::LineString*>(g));
        case GEOS_LINEARRING: return xs::out<>(dyn_cast<geos::geom::LinearRing*>(g));
        case GEOS_POLYGON: return xs::out<>(dyn_cast<geos::geom::Polygon*>(g));
        case GEOS_MULTIPOINT: return xs::out<>(dyn_cast<geos::geom::MultiPoint*>(g));
        case GEOS_MULTILINESTRING: return xs::out<>(dyn_cast<geos::geom::MultiLineString*>(g));
        case GEOS_MULTIPOLYGON: return xs::out<>(dyn_cast<geos::geom::MultiPolygon*>(g));
        case GEOS_GEOMETRYCOLLECTION: return xs::out<>(dyn_cast<geos::geom::GeometryCollection*>(g));
    default:
        throw "unknown geometry type";
    }
}
