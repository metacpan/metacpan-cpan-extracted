#include "mh_axis.h"

#include <stdlib.h>
#include <string.h>
#include <float.h>

mh_axis_t *
mh_axis_create(unsigned int nbins, unsigned short have_varbins)
{
  mh_axis_t *axis;
  axis = (mh_axis_t *)malloc(sizeof(mh_axis_t));
  if (axis == NULL)
    return NULL;
  axis->nbins = nbins;

  if (have_varbins != MH_AXIS_OPT_FIXEDBINS) {
    axis->bins = (double *)malloc(sizeof(double) * (nbins+1));
    if (axis->bins == NULL) {
      free(axis);
      return NULL;
    }
  }
  else {
    axis->bins = NULL;
  }

  axis->userdata = NULL;

  return axis;
}


mh_axis_t *
mh_axis_clone(mh_axis_t *axis_proto)
{
  mh_axis_t *axis_out = (mh_axis_t *)malloc(sizeof(mh_axis_t));
  if (axis_out == NULL)
    return NULL;

  axis_out->nbins = axis_proto->nbins;
  if (!MH_AXIS_ISFIXBIN(axis_proto)) {
    axis_out->bins = (double *)malloc(sizeof(double) * (axis_proto->nbins+1));
    if (axis_out->bins == NULL) {
      free(axis_out);
      return NULL;
    }
    memcpy(axis_out->bins, axis_proto->bins, sizeof(double) * (axis_proto->nbins+1));
  }
  else {
    axis_out->bins = NULL;
  }

  axis_out->binsize = axis_proto->binsize;
  axis_out->width = axis_proto->width;
  axis_out->min = axis_proto->min;
  axis_out->max = axis_proto->max;
  axis_out->userdata = axis_proto->userdata;

  return axis_out;
}


void
mh_axis_init(mh_axis_t *axis, double min, double max)
{
  axis->min = min;
  axis->max = max;
  axis->width = max-min;
  if (MH_AXIS_ISFIXBIN(axis))
    axis->binsize = axis->width / (double)MH_AXIS_NBINS(axis);
}


void
mh_axis_free(mh_axis_t *axis)
{
  if (! MH_AXIS_ISFIXBIN(axis))
    free(axis->bins);
  free(axis);
}


unsigned int
mh_axis_find_bin(mh_axis_t *axis, double x)
{
  if (MH_AXIS_ISFIXBIN(axis)) {
    unsigned int bin;
    const double min = MH_AXIS_MIN(axis);

    if (x < min)
      bin = 0;
    else if (x >= MH_AXIS_MAX(axis))
      bin = MH_AXIS_NBINS(axis)+1;
    else
      bin = 1 + (unsigned int)((x + DBL_EPSILON - min) / MH_AXIS_BINSIZE_FIX(axis));
    return bin;
  }
  else
    return mh_axis_find_bin_var(axis, x);
}


unsigned int
mh_axis_find_bin_var(mh_axis_t *axis, double x)
{
  /* TODO optimize */
  unsigned int mid;
  double mid_val;
  unsigned int imin = 0;
  unsigned int imax = MH_AXIS_NBINS(axis);
  double *bins = axis->bins;
  x += DBL_EPSILON; /* FIXME */

  if (x < MH_AXIS_MIN(axis))
    return 0;
  else if (x >= MH_AXIS_MAX(axis))
    return imax+1;

  /* This algorithm is based on 0-based bin indices, we switch to 1-based
   * only in the very return statements! */
  while (1) {
    mid = imin + (imax-imin)/2;
    mid_val = bins[mid];
    if (mid_val == x)
      return mid+1;
    else if (mid_val > x) {
      if (mid == 0)
        return 1;
      imax = mid-1;
      if (imin > imax)
        return mid;
    }
    else {
      imin = mid+1;
      if (imin > imax)
        return imin;
    }
  }
}

