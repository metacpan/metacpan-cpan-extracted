#pragma once

#include <geos/noding/SegmentString.h>
#include <geos/noding/SegmentNode.h>
#include <geos/noding/NodedSegmentString.h>
#include <geos/noding/BasicSegmentString.h>
#include <geos/noding/SegmentIntersector.h>
#include <geos/noding/SegmentIntersectionDetector.h>
#include <geos/noding/SingleInteriorIntersectionFinder.h>
#include <geos/noding/IntersectionAdder.h>
#include <geos/noding/IntersectionFinderAdder.h>
#include <geos/noding/Noder.h>
#include <geos/noding/IteratedNoder.h>
#include <geos/noding/ScaledNoder.h>
#include <geos/noding/SinglePassNoder.h>
#include <geos/noding/SimpleNoder.h>
#include <geos/noding/snapround/SimpleSnapRounder.h>
#include <geos/noding/OrientedCoordinateArray.h>
#include <geos/noding/Octant.h>
#include <geos/noding/NodingValidator.h>
#include <geos/noding/FastNodingValidator.h>
#include <geos/noding/FastSegmentSetIntersectionFinder.h>
#include <geos/noding/SegmentPointComparator.h>
#include <geos/noding/SegmentStringUtil.h>
#include <geos/noding/FastSegmentSetIntersectionFinder.h>

namespace xs {

template <class TYPE>
struct Typemap<geos::noding::SegmentString*, TYPE> : TypemapObject<geos::noding::SegmentString*, TYPE, ObjectTypePtr, ObjectStorageMG, StaticCast> {
    static panda::string_view package() {return "Geo::Geos::Noding::SegmentString"; }
};

template <>
struct Typemap<geos::noding::NodedSegmentString*>: Typemap<geos::noding::SegmentString*, geos::noding::NodedSegmentString*>{
    static panda::string_view package() {return "Geo::Geos::Noding::NodedSegmentString"; }
};

template <>
struct Typemap<geos::noding::BasicSegmentString*>: Typemap<geos::noding::SegmentString*, geos::noding::BasicSegmentString*>{
    static panda::string_view package() {return "Geo::Geos::Noding::BasicSegmentString"; }
};

template <class TYPE>
struct Typemap<geos::noding::SegmentIntersector*, TYPE> : TypemapObject<geos::noding::SegmentIntersector*, TYPE, ObjectTypePtr, ObjectStorageMG, StaticCast> {
    static panda::string_view package() {return "Geo::Geos::Noding::SegmentIntersector"; }
};

template <>
struct Typemap<geos::noding::SegmentIntersectionDetector*>: Typemap<geos::noding::SegmentIntersector*, geos::noding::SegmentIntersectionDetector*>{
    static panda::string_view package() {return "Geo::Geos::Noding::SegmentIntersectionDetector"; }
};

template <>
struct Typemap<geos::noding::SingleInteriorIntersectionFinder*>: Typemap<geos::noding::SegmentIntersector*, geos::noding::SingleInteriorIntersectionFinder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::SingleInteriorIntersectionFinder"; }
};

template <>
struct Typemap<geos::noding::IntersectionAdder*>: Typemap<geos::noding::SegmentIntersector*, geos::noding::IntersectionAdder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::IntersectionAdder"; }
};


template <>
struct Typemap<geos::noding::IntersectionFinderAdder*>: Typemap<geos::noding::SegmentIntersector*, geos::noding::IntersectionFinderAdder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::IntersectionFinderAdder"; }
};

template <class TYPE>
struct Typemap<geos::noding::Noder*, TYPE> : TypemapObject<geos::noding::Noder*, TYPE, ObjectTypePtr, ObjectStorageMG, StaticCast> {
    static panda::string_view package() {return "Geo::Geos::Noding::Noder"; }
};

template <>
struct Typemap<geos::noding::IteratedNoder*>: Typemap<geos::noding::Noder*, geos::noding::IteratedNoder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::IteratedNoder"; }
};

template <>
struct Typemap<geos::noding::ScaledNoder*>: Typemap<geos::noding::Noder*, geos::noding::ScaledNoder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::ScaledNoder"; }
};

template <>
struct Typemap<geos::noding::SinglePassNoder*>: Typemap<geos::noding::Noder*, geos::noding::SinglePassNoder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::SinglePassNoder"; }
};

template <>
struct Typemap<geos::noding::SimpleNoder*>: Typemap<geos::noding::Noder*, geos::noding::SimpleNoder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::SimpleNoder"; }
};

template <>
struct Typemap<geos::noding::snapround::SimpleSnapRounder*>: Typemap<geos::noding::Noder*, geos::noding::snapround::SimpleSnapRounder*>{
    static panda::string_view package() {return "Geo::Geos::Noding::SimpleSnapRounder"; }
};

}
