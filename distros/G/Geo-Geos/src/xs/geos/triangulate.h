#pragma once

#include <geos/triangulate/DelaunayTriangulationBuilder.h>
#include <geos/triangulate/VoronoiDiagramBuilder.h>

namespace xs {

template <>
struct Typemap<geos::triangulate::VoronoiDiagramBuilder*>: TypemapObject<geos::triangulate::VoronoiDiagramBuilder*, geos::triangulate::VoronoiDiagramBuilder*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() { return "Geo::Geos::Triangulate::VoronoiDiagramBuilder"; }
};

template <>
struct Typemap<geos::triangulate::DelaunayTriangulationBuilder*>: TypemapObject<geos::triangulate::DelaunayTriangulationBuilder*, geos::triangulate::DelaunayTriangulationBuilder*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() { return "Geo::Geos::Triangulate::DelaunayTriangulationBuilder"; }
};

}
