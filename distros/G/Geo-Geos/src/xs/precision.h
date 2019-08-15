#pragma once

#include <geos/precision/CommonBits.h>
#include <geos/precision/CommonBitsOp.h>
#include <geos/precision/CommonBitsRemover.h>
#include <geos/precision/EnhancedPrecisionOp.h>
#include <geos/precision/GeometryPrecisionReducer.h>
#include <geos/precision/SimpleGeometryPrecisionReducer.h>

namespace xs {

template <>
struct Typemap<geos::precision::GeometryPrecisionReducer*>: TypemapObject<geos::precision::GeometryPrecisionReducer*, geos::precision::GeometryPrecisionReducer*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Precision::GeometryPrecisionReducer"; }
};

template <>
struct Typemap<geos::precision::SimpleGeometryPrecisionReducer*>: TypemapObject<geos::precision::SimpleGeometryPrecisionReducer*, geos::precision::SimpleGeometryPrecisionReducer*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Precision::SimpleGeometryPrecisionReducer"; }
};


}
