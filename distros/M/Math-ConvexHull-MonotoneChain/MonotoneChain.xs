#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
  double x;
  double y;
} point_t;

typedef point_t* point_ptr_t;

/* Three points are a counter-clockwise turn if ccw > 0, clockwise if
 * ccw < 0, and collinear if ccw = 0 because ccw is a determinant that
 * gives the signed area of the triangle formed by p1, p2 and p3.
 */
STATIC double
ccw(point_t* p1, point_t* p2, point_t* p3)
{
  return (p2->x - p1->x)*(p3->y - p1->y) - (p2->y - p1->y)*(p3->x - p1->x);
}

/* Returns a list of points on the convex hull in counter-clockwise order.
 * Note: the last point in the returned list is the same as the first one.
 */
STATIC void
convex_hull(point_t* points, SSize_t npoints, point_ptr_t** out_hull, SSize_t* out_hullsize)
{
  point_ptr_t* hull;
  SSize_t i, t, k = 0;

  hull = *out_hull;

  /* lower hull */
  for (i = 0; i < npoints; ++i) {
    while (k >= 2 && ccw(hull[k-2], hull[k-1], &points[i]) <= 0) --k;
    hull[k++] = &points[i];
  }

  /* upper hull */
  for (i = npoints-2, t = k+1; i >= 0; --i) {
    while (k >= t && ccw(hull[k-2], hull[k-1], &points[i]) <= 0) --k;
    hull[k++] = &points[i];
  }

  *out_hull = hull;
  *out_hullsize = k;
}

MODULE = Math::ConvexHull::MonotoneChain	PACKAGE = Math::ConvexHull::MonotoneChain
PROTOTYPES: DISABLE

void
convex_hull_sorted(points)
    AV* points
  PREINIT:
    AV* hull_points;
    SSize_t out_hullsize, npoints, arylen, i;
    point_t* cpoints;
    point_ptr_t* out_hull;
    AV* inner_av;
    AV* out_av;
    SV** elemptr;
    SV* elem;
  PPCODE:
    npoints = av_len(points)+1;
    if (npoints <= 2) {
      out_av = newAV();
      av_fill(out_av, npoints-1);
      for (i = 0; i < npoints; ++i) {
        elemptr = av_fetch(points, i, 0);
        av_store(out_av, i, newSVsv(*elemptr));
      }
      XPUSHs(sv_2mortal(newRV_noinc((SV*)out_av)));
      XSRETURN(1);
    }
    else {
      cpoints = (point_t*)malloc(npoints * sizeof(point_t));
      for (i = 0; i < npoints; ++i) {
        if (NULL == (elemptr = av_fetch(points, i, 0))) {
          free(cpoints);
          croak("Could not fetch element from array");
        }

        elem = *elemptr;
        if (SvROK(elem) && SvTYPE(SvRV(elem)) == SVt_PVAV) {
          inner_av = (AV*)SvRV(elem);
          arylen = av_len(inner_av)+1;
          if (arylen < 2) {
            free(cpoints);
            croak("Input array does not only contain point-like structures with at least two coordinates? At point %i.", i);
          }
          else if (NULL == (elemptr = av_fetch(inner_av, 0, 0))) {
            free(cpoints);
            croak("Could not fetch element from array");
          }
          cpoints[i].x = SvNV(*elemptr);

          if (NULL == (elemptr = av_fetch(inner_av, 1, 0))) {
            free(cpoints);
            croak("Could not fetch element from array");
          }
          cpoints[i].y = SvNV(*elemptr);

        }
        else {
          free(cpoints);
          croak("Input array does not only contain point-like structures?");
        }
      }
    } /* end for i in 0..npoints */

    out_hull = malloc(npoints*2 * sizeof(point_ptr_t));
    convex_hull(cpoints, npoints, &out_hull, &out_hullsize);
    out_av = newAV();
    av_fill(out_av, out_hullsize-2);
    for (i = 0; i < out_hullsize-1; ++i) {
      inner_av = newAV();
      av_fill(inner_av, 1);
      av_store(inner_av, 0, newSVnv(out_hull[i]->x));
      av_store(inner_av, 1, newSVnv(out_hull[i]->y));
      elem = newRV_noinc((SV*)inner_av);
      av_store(out_av, i, elem);
    }
    free(out_hull);
    free(cpoints);
    XPUSHs(sv_2mortal(newRV_noinc((SV*)out_av)));
    XSRETURN(1);

