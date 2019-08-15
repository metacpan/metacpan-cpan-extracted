#pragma once

#include <geos/geom/prep/PreparedGeometry.h>
#include <geos/geom/prep/PreparedGeometryFactory.h>
#include <geos/geom/prep/PreparedLineString.h>
#include <geos/geom/prep/PreparedPoint.h>
#include <geos/geom/prep/PreparedPolygon.h>

namespace xs {

template <class TYPE>
struct Typemap<geos::geom::prep::BasicPreparedGeometry*, TYPE> : TypemapObject<geos::geom::prep::BasicPreparedGeometry*, TYPE, ObjectTypePtr, ObjectStorageMG, StaticCast> {
    static panda::string_view package() {return "Geo::Geos::Prep::Geometry"; }
};

}
