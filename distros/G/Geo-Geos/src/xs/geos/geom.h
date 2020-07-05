#pragma once

#include <vector>
#include <sstream>

#include <geos/geom/Coordinate.h>
#include <geos/geom/Triangle.h>
#include <geos/triangulate/quadedge/TrianglePredicate.h>
#include <geos/geom/LineSegment.h>
#include <geos/geom/Dimension.h>
#include <geos/geom/Envelope.h>
#include <geos/geom/PrecisionModel.h>
#include <geos/geom/GeometryFactory.h>
#include <geos/geom/Puntal.h>
#include <geos/geom/Point.h>
#include <geos/geom/MultiPoint.h>
#include <geos/geom/LineString.h>
#include <geos/geom/LinearRing.h>
#include <geos/geom/MultiLineString.h>
#include <geos/geom/Polygon.h>
#include <geos/geom/MultiPolygon.h>
#include <geos/geom/IntersectionMatrix.h>
#include <geos/operation/buffer/BufferParameters.h>

namespace xs {

template <class TYPE>
struct Typemap<geos::geom::Coordinate*, TYPE*>: TypemapObject<geos::geom::Coordinate*, TYPE*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Coordinate"; }
};

template <>
struct Typemap<geos::geom::Triangle*>: TypemapObject<geos::geom::Triangle*, geos::geom::Triangle*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Triangle"; }
};

template <>
struct Typemap<geos::geom::LineSegment*>: TypemapObject<geos::geom::LineSegment*, geos::geom::LineSegment*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::LineSegment"; }
};

template <>
struct Typemap<geos::geom::Envelope*>: TypemapObject<geos::geom::Envelope*, geos::geom::Envelope*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Envelope"; }
};

template <>
struct Typemap<geos::geom::PrecisionModel*>: TypemapObject<geos::geom::PrecisionModel*, geos::geom::PrecisionModel*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::PrecisionModel"; }
};

template <>
struct Typemap<geos::geom::IntersectionMatrix*>: TypemapObject<geos::geom::IntersectionMatrix*, geos::geom::IntersectionMatrix*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::IntersectionMatrix"; }
};


template <>
struct Typemap<geos::geom::GeometryFactory*>: TypemapObject<geos::geom::GeometryFactory*, geos::geom::GeometryFactory*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::GeometryFactory"; }
    static void dispose (geos::geom::GeometryFactory* obj,SV*) { obj->destroy(); }
};

template <class TYPE>
struct Typemap<geos::geom::Geometry*, TYPE> : TypemapObject<geos::geom::Geometry*, TYPE, ObjectTypePtr, ObjectStorageMG, DynamicCast> {
    static panda::string_view package() {return "Geo::Geos::Geometry"; }
};

template <>
struct Typemap<geos::geom::GeometryCollection*>: Typemap<geos::geom::Geometry*, geos::geom::GeometryCollection*>{
    static panda::string_view package() {return "Geo::Geos::GeometryCollection"; }
};

template <>
struct Typemap<geos::geom::Point*>: Typemap<geos::geom::Geometry*, geos::geom::Point*>{
    static panda::string_view package() {return "Geo::Geos::Point"; }
};

template <>
struct Typemap<geos::geom::MultiPoint*>: Typemap<geos::geom::Geometry*, geos::geom::MultiPoint*>{
    static panda::string_view package() {return "Geo::Geos::MultiPoint"; }
};

template <>
struct Typemap<geos::geom::LineString*>: Typemap<geos::geom::Geometry*, geos::geom::LineString*>{
    static panda::string_view package() {return "Geo::Geos::LineString"; }
};

template <>
struct Typemap<geos::geom::MultiLineString*>: Typemap<geos::geom::Geometry*, geos::geom::MultiLineString*>{
    static panda::string_view package() {return "Geo::Geos::MultiLineString"; }
};

template <>
struct Typemap<geos::geom::LinearRing*>: Typemap<geos::geom::Geometry*, geos::geom::LinearRing*>{
    static panda::string_view package() {return "Geo::Geos::LinearRing"; }
};

template <>
struct Typemap<geos::geom::Polygon*>: Typemap<geos::geom::Geometry*, geos::geom::Polygon*>{
    static panda::string_view package() {return "Geo::Geos::Polygon"; }
};

template <>
struct Typemap<geos::geom::MultiPolygon*>: Typemap<geos::geom::Geometry*, geos::geom::MultiPolygon*>{
    static panda::string_view package() {return "Geo::Geos::MultiPolygon"; }
};

}
