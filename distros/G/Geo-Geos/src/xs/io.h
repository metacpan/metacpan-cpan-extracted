#pragma once

#include <geos/io/WKBWriter.h>
#include <geos/io/WKBReader.h>
#include <geos/io/WKTWriter.h>
#include <geos/io/WKTReader.h>
#include <geos/io/WKBConstants.h>

namespace xs {

template <>
struct Typemap<geos::io::WKBWriter*>: TypemapObject<geos::io::WKBWriter*, geos::io::WKBWriter*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::WKBWriter"; }
};

template <>
struct Typemap<geos::io::WKTWriter*>: TypemapObject<geos::io::WKTWriter*, geos::io::WKTWriter*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::WKTWriter"; }
};


}
