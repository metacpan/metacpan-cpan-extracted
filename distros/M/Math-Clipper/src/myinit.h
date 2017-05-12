#ifndef __clipper_myinit_h_
#define __clipper_myinit_h_

#include "clipper.hpp"

using namespace ClipperLib;

//-----------------------------------------------------------
// legacy code from Clipper documentation
struct ExPolygon {
  ClipperLib::Polygon outer;
  ClipperLib::Polygons holes;
};
 
typedef std::vector< ExPolygon > ExPolygons;
 
void AddOuterPolyNodeToExPolygons(ClipperLib::PolyNode& polynode, ExPolygons& expolygons)
{  
  size_t cnt = expolygons.size();
  expolygons.resize(cnt + 1);
  expolygons[cnt].outer = polynode.Contour;
  expolygons[cnt].holes.resize(polynode.ChildCount());
  for (int i = 0; i < polynode.ChildCount(); ++i)
  {
    expolygons[cnt].holes[i] = polynode.Childs[i]->Contour;
    //Add outer polygons contained by (nested within) holes ...
    for (int j = 0; j < polynode.Childs[i]->ChildCount(); ++j)
      AddOuterPolyNodeToExPolygons(*polynode.Childs[i]->Childs[j], expolygons);
  }
}
 
void PolyTreeToExPolygons(ClipperLib::PolyTree& polytree, ExPolygons& expolygons)
{
  expolygons.clear();
  for (int i = 0; i < polytree.ChildCount(); ++i)
    AddOuterPolyNodeToExPolygons(*polytree.Childs[i], expolygons);
}
//-----------------------------------------------------------

#include "poly2av.h"
#include "offset.h"

#endif
