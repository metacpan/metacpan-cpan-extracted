#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "vdefs.h"

MODULE = Math::Geometry::Voronoi PACKAGE = Math::Geometry::Voronoi		

SV *
compute_voronoi_xs(points_ref, xmin, xmax, ymin, ymax)
  SV *points_ref
  double xmin
  double xmax
  double ymin
  double ymax
PREINIT:
  Site *sites;
  SV *ref, *sv, *sv_x, *sv_y;
  AV *av;
  AV *points;
  I32 i;
  int debug = 0;
  I32 num_points;
  SV **svp;
  AV *lines, *edges, *vertices;
  HV *result;
CODE:
{
  points = (AV *) SvRV(points_ref);
  num_points = av_len(points) + 1;

  // translate points AV into Sites array for use by voronoi C code
  sites = (Site *) myalloc(num_points * sizeof(Site));

  for (i = 0; i < num_points; i++) {
    svp = av_fetch(points, i, 0);
    if (!svp)
      croak("Failed to fetch points[%d]!", i);
    ref = *svp;

    if (!SvROK(ref))
      croak("Points array must be an array of arrays!");
    sv = SvRV(ref);

    if (SvTYPE(sv) != SVt_PVAV)
      croak("Points array must be an array of arrays!");
    av = (AV *) sv;

    if (av_len(av) < 1)
      croak("Points array must be an array of arrays with 2 values not %d!", av_len(av));

    svp = av_fetch(av, 0, 0);
    if (!svp)
      croak("Failed to fetch points[%d][0]!", i);
    sv_x = *svp;

    svp = av_fetch(av, 1, 0);
    if (!svp)
      croak("Failed to fetch points[%d][1]!", i);
    sv_y = *svp;

    sites[i].coord.x = SvNV(sv_x);
    sites[i].coord.y = SvNV(sv_y);
    sites[i].sitenbr = i;
    sites[i].refcnt = 0 ;
  }

  // setup arrays to hold results
  lines    = newAV();
  edges    = newAV();
  vertices = newAV();

  compute_voronoi(sites, num_points, xmin, xmax, ymin, ymax, debug, lines, edges, vertices);

  result = newHV();
  hv_store(result, "lines",    strlen("lines"),    newRV_noinc((SV*) lines), 0);
  hv_store(result, "edges",    strlen("edges"),    newRV_noinc((SV*) edges), 0);
  hv_store(result, "vertices", strlen("vertices"), newRV_noinc((SV*) vertices), 0);
}

  RETVAL = newRV_noinc((SV*) result);
OUTPUT:
  RETVAL
