#pragma once

#include <geos/algorithm/Angle.h>
#include <geos/algorithm/Centroid.h>
#include <geos/algorithm/CentroidArea.h>
#include <geos/algorithm/CentroidLine.h>
#include <geos/algorithm/CentroidPoint.h>
#include <geos/algorithm/CGAlgorithms.h>
#include <geos/algorithm/CentralEndpointIntersector.h>
#include <geos/algorithm/ConvexHull.h>
#include <geos/algorithm/InteriorPointArea.h>
#include <geos/algorithm/InteriorPointLine.h>
#include <geos/algorithm/InteriorPointPoint.h>
#include <geos/algorithm/PointLocator.h>
#include <geos/algorithm/RobustDeterminant.h>

#include <geos/algorithm/HCoordinate.h>
#include <geos/algorithm/MinimumDiameter.h>
#include <geos/algorithm/LineIntersector.h>

#include <geos/algorithm/locate/SimplePointInAreaLocator.h>
#include <geos/algorithm/locate/IndexedPointInAreaLocator.h>

namespace xs {

template <>
struct Typemap<geos::algorithm::HCoordinate*>: TypemapObject<geos::algorithm::HCoordinate*, geos::algorithm::HCoordinate*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() { return "Geo::Geos::Algorithm::HCoordinate"; }
};

template <>
struct Typemap<geos::algorithm::MinimumDiameter*>: TypemapObject<geos::algorithm::MinimumDiameter*, geos::algorithm::MinimumDiameter*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() { return "Geo::Geos::Algorithm::MinimumDiameter"; }
};

template <>
struct Typemap<geos::algorithm::LineIntersector*>: TypemapObject<geos::algorithm::LineIntersector*, geos::algorithm::LineIntersector*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() { return "Geo::Geos::Algorithm::LineIntersector"; }
};


}
