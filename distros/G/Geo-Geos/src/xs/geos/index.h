#pragma once

#include <geos/index/chain/MonotoneChain.h>
#include <geos/index/chain/MonotoneChainBuilder.h>
#include <geos/index/chain/MonotoneChainOverlapAction.h>
#include <geos/index/ItemVisitor.h>
#include <geos/index/quadtree/Quadtree.h>
#include <geos/index/strtree/STRtree.h>


namespace xs {

template <>
struct Typemap<geos::index::chain::MonotoneChain*>: TypemapObject<geos::index::chain::MonotoneChain*, geos::index::chain::MonotoneChain*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Index::MonotoneChain"; }
};

template <>
struct Typemap<geos::index::chain::MonotoneChainOverlapAction*>: TypemapObject<geos::index::chain::MonotoneChainOverlapAction*, geos::index::chain::MonotoneChainOverlapAction*, ObjectTypePtr, ObjectStorageMG, StaticCast>{
    static panda::string_view package() {return "Geo::Geos::Index::MonotoneChainOverlapAction"; }
};

// DynamicCast is needed for STRtree
template <class TYPE>
struct Typemap<geos::index::SpatialIndex*, TYPE> : TypemapObject<geos::index::SpatialIndex*, TYPE, ObjectTypePtr, ObjectStorageMG, DynamicCast> {
    static panda::string_view package() {return "Geo::Geos::Index::SpatialIndex"; }
};

template <>
struct Typemap<geos::index::quadtree::Quadtree*>: Typemap<geos::index::SpatialIndex*, geos::index::quadtree::Quadtree*>{
    static panda::string_view package() {return "Geo::Geos::Index::Quadtree"; }
};

template <>
struct Typemap<geos::index::strtree::STRtree*>: Typemap<geos::index::SpatialIndex*, geos::index::strtree::STRtree*>{
    static panda::string_view package() {return "Geo::Geos::Index::STRtree"; }
};

}
