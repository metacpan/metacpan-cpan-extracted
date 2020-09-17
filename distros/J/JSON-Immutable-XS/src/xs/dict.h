#pragma once
#include <xs.h>
#include <dict.hpp>
using namespace json_tree;

namespace xs {
    template <class T> struct Typemap<Dict*, T> : TypemapObject<Dict*, T, ObjectTypePtr, ObjectStorageMG> {
        static panda::string package () { return "JSON::Immutable::XS"; }
    };
    template <class T> struct Typemap<const Dict*, T> : TypemapObject<const Dict*, T, ObjectTypeForeignPtr, ObjectStorageMG> {
        static panda::string package () { return "JSON::Immutable::XS"; }
    };
}
