#ifndef clipper_offset_h_
#define clipper_offset_h_

#include "myinit.h"

void
_scale_polygons(ClipperLib::Polygons* polygons, const double scale)
{
    for (ClipperLib::Polygons::size_type i = 0; i != (*polygons).size(); i++) {
        ClipperLib::Polygon* mypoly = &(*polygons)[i];
        for (ClipperLib::Polygon::size_type j = 0; j != (*mypoly).size(); j++) {
            (*mypoly)[j].X *= scale;
            (*mypoly)[j].Y *= scale;
        }
    }
}

ClipperLib::Polygons*
_int_offset(ClipperLib::Polygons* polygons, const float delta, const double scale, ClipperLib::JoinType jointype, const double MiterLimit)
{
    // scale
    _scale_polygons(polygons, scale);
    
    // perform offset
    ClipperLib::Polygons* retval = new ClipperLib::Polygons();
    ClipperLib::OffsetPolygons(*polygons, *retval, (delta*scale), jointype, MiterLimit);
    
    // unscale
    _scale_polygons(retval, 1/scale);
    
    return retval;
}

#endif
