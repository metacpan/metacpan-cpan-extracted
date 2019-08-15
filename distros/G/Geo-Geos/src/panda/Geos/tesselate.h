#pragma once

#include <vector>
#include <geos/geom/Geometry.h>
#include <geos/geom/GeometryFactory.h>
#include <geos/geom/GeometryCollection.h>
#include <geos/geom/Polygon.h>
#include <geos/geom/LineString.h>
#include <geos/geom/CoordinateSequenceFactory.h>

namespace panda { namespace Geos {

geos::geom::GeometryCollection* tesselate(geos::geom::Polygon& poly);

}}
