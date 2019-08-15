#pragma once

namespace xs {

template <>
struct Typemap<geos::noding::SegmentNode*>: TypemapObject<geos::noding::SegmentNode*, geos::noding::SegmentNode*, ObjectTypeForeignPtr, ObjectStorageMG, StaticCast>{
    static const panda::string_view package() { return "Geo::Geos::Noding::SegmentNode"; }
};

}
