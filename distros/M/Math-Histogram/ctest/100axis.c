#include <stdio.h>
#include <stdlib.h>
#include <mh_axis.h>

#include "mytap.h"

/* because the one included in main() below is using fixed-width bins
 * in a variable-bin axis only, we need to test differing var-bins
 * separately. */
void real_varbins_test();

int
main (int argc, char **argv)
{
  mh_axis_t *axises[4];
  mh_axis_t *axis;
  double min, max, binsize;
  unsigned int nbins, i, iaxis, naxises;
  char buf[2048];

  UNUSED(argc);
  UNUSED(argv);

  ok(1);

  naxises = 4;
  nbins = 13;
  min = -0.3;
  max = 0.85;
  binsize = (max-min) / (double)nbins;

  /* we'll run the same set if initial tests on an axis and its clone */
  axises[0] = mh_axis_create(nbins, MH_AXIS_OPT_FIXEDBINS);
  mh_axis_init(axises[0], min, max);
  axises[1] = mh_axis_clone(axises[0]);

  axises[2] = mh_axis_create(nbins, MH_AXIS_OPT_VARBINS);
  mh_axis_init(axises[2], min, max);
  for (i = 0; i <= nbins; ++i) {
    axises[2]->bins[i] = min + binsize * (double)i;
    printf("# %u => %f\n", i, axises[2]->bins[i]);
  }
  is_double_m(1e-9, axises[2]->bins[nbins], max, "bin arithmetic leads to expected range");

  axises[3] = mh_axis_clone(axises[2]);

  for (iaxis = 0; iaxis < naxises; ++iaxis) {
    axis = axises[iaxis]; /* 0=orig axis, fix; 1=clone; 2=orig axis, var; 3=clone */
    sprintf(buf, "testing axis props for %s with %s bins",
            iaxis % 2 == 0 ? "original axis" : "cloned axis",
            iaxis < 2 ? "fixed" : "variable");
    note(buf);

    /* test per-axis properties first */
    if (iaxis < 2) {
      ok_m(MH_AXIS_ISFIXBIN(axis), "axis has fixed bins");
    }
    else {
      ok_m(! MH_AXIS_ISFIXBIN(axis), "axis has variable bins");
    }
    is_int_m(MH_AXIS_NBINS(axis), nbins, "axis has ten bins as expected");

    if (iaxis < 2)
      is_double_m(1e-9, MH_AXIS_BINSIZE_FIX(axis), binsize, "binsize (fix)");

    is_double_m(1e-9, MH_AXIS_MIN(axis), min, "min");
    is_double_m(1e-9, MH_AXIS_MAX(axis), max, "max");
    is_double_m(1e-9, MH_AXIS_WIDTH(axis), max-min, "width");

    /* test per-bin properties */
    for (i = 1; i <= nbins; ++i) {
      double binlower  = min + binsize * (double)(i-1);
      double binupper  = binlower + binsize;
      double bincenter = binlower + 0.5*binsize;

      sprintf(buf, "axis %u, binsize for bin %u", iaxis, i);
      is_double_m(1e-9, MH_AXIS_BINSIZE(axis, i), binsize, "binsize");

      sprintf(buf, "axis %u, lower bin edge for bin %u", iaxis, i);
      is_double_m(1e-9, MH_AXIS_BIN_LOWER(axis, i), binlower, buf);
      sprintf(buf, "axis %u, bin center for bin %u", iaxis, i);
      is_double_m(1e-9, MH_AXIS_BIN_CENTER(axis, i), bincenter, buf);
      sprintf(buf, "axis %u, upper bin edge for bin %u", iaxis, i);
      is_double_m(1e-9, MH_AXIS_BIN_UPPER(axis, i), binupper, buf);

      if (iaxis < 2) {
        sprintf(buf, "axis %u, lower bin edge for bin %u (fixed-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_LOWER_FIX(axis, i), binlower, buf);
        sprintf(buf, "axis %u, bin center for bin %u (fixed-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_CENTER_FIX(axis, i), bincenter, buf);
        sprintf(buf, "axis %u, upper bin edge for bin %u (fixed-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_UPPER_FIX(axis, i), binupper, buf);
      }
      else {
        sprintf(buf, "axis %u, lower bin edge for bin %u (variable-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_LOWER_VAR(axis, i), binlower, buf);
        sprintf(buf, "axis %u, bin center for bin %u (variable-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_CENTER_VAR(axis, i), bincenter, buf);
        sprintf(buf, "axis %u, upper bin edge for bin %u (variable-width bins assumed)", iaxis, i);
        is_double_m(1e-9, MH_AXIS_BIN_UPPER_VAR(axis, i), binupper, buf);
      }

      /* printf("# lower=%f => %u i=%u\n", binlower, mh_axis_find_bin(axis, binlower), i); */
      sprintf(buf, "axis %u, finding bin no for bin lower edge (%u)", iaxis, i);
      is_int_m(mh_axis_find_bin(axis, binlower), i, buf);

      /* printf("# center=%f => %u i=%u\n", bincenter, mh_axis_find_bin(axis, bincenter), i); */
      sprintf(buf, "axis %u, finding bin no for bin center (%u)", iaxis, i);
      is_int_m(mh_axis_find_bin(axis, bincenter), i, buf);

      /* printf("# upper=%f => %u i=%u\n", binupper, mh_axis_find_bin(axis, binupper), i); */
      sprintf(buf, "axis %u, finding bin no for upper edge (%u)", iaxis, i);
      is_int_m(mh_axis_find_bin(axis, binupper), i+1, buf);
    }
    is_int_m(mh_axis_find_bin(axis, min-1.), 0, "below-minimum x finds underflow bin");
    is_int_m(mh_axis_find_bin(axis, max+1.), nbins+1, "above-maximum x finds overflow bin");
  
    mh_axis_free(axis);
  } /* end foreach axis */

  real_varbins_test();

  done_testing();
  return 0;
}

void
real_varbins_test()
{
  mh_axis_t *axis;
  double min, max;
  unsigned int nbins, i;
  char buf[2048];

  double bins[] = {-.1, 0., 1.e-5, 1., 2., 2.1, 100., 113., 115., 120., 1000., 1001., 1002.2, 1002.3};

  nbins = 13;
  min = bins[0];
  max = bins[nbins];

  axis = mh_axis_create(nbins, MH_AXIS_OPT_VARBINS);
  mh_axis_init(axis, min, max);
  for (i = 0; i <= nbins; ++i) {
    axis->bins[i] = bins[i];
    printf("# %u => %f\n", i, axis->bins[i]);
  }
  is_double_m(1e-9, axis->bins[nbins], max, "bin arithmetic leads to expected range");
  is_double_m(1e-9, axis->bins[0], min, "bin arithmetic leads to expected range");

  for (i = 1; i <= nbins; ++i) {
    double binlower  = bins[i-1];
    double bincenter = 0.5 * (bins[i-1] + bins[i]);
    double binupper  = bins[i];
    double binsize = binupper - binlower;

    sprintf(buf, "varbins axis: binsize for bin %u", i);
    is_double_m(1e-9, MH_AXIS_BINSIZE(axis, i), binsize, "binsize");

    sprintf(buf, "varbins axis: lower bin edge for bin %u", i);
    is_double_m(1e-9, MH_AXIS_BIN_LOWER(axis, i), binlower, buf);
    sprintf(buf, "varbins axis: bin center for bin %u", i);
    is_double_m(1e-9, MH_AXIS_BIN_CENTER(axis, i), bincenter, buf);
    sprintf(buf, "varbins axis: upper bin edge for bin %u", i);
    is_double_m(1e-9, MH_AXIS_BIN_UPPER(axis, i), binupper, buf);

    sprintf(buf, "varbins axis: lower bin edge for bin %u (variable-width bins assumed)", i);
    is_double_m(1e-9, MH_AXIS_BIN_LOWER_VAR(axis, i), binlower, buf);
    sprintf(buf, "varbins axis: bin center for bin %u (variable-width bins assumed)", i);
    is_double_m(1e-9, MH_AXIS_BIN_CENTER_VAR(axis, i), bincenter, buf);
    sprintf(buf, "varbins axis: upper bin edge for bin %u (variable-width bins assumed)", i);
    is_double_m(1e-9, MH_AXIS_BIN_UPPER_VAR(axis, i), binupper, buf);

    /* printf("# lower=%f => %u i=%u\n", binlower, mh_axis_find_bin(axis, binlower), i); */
    sprintf(buf, "varbins axis: finding bin no for bin lower edge (%u)", i);
    is_int_m(mh_axis_find_bin(axis, binlower), i, buf);

    /* printf("# center=%f => %u i=%u\n", bincenter, mh_axis_find_bin(axis, bincenter), i); */
    sprintf(buf, "varbins axis: finding bin no for bin center (%u)", i);
    is_int_m(mh_axis_find_bin(axis, bincenter), i, buf);

    /* printf("# upper=%f => %u i=%u\n", binupper, mh_axis_find_bin(axis, binupper), i); */
    sprintf(buf, "varbins axis: finding bin no for upper edge (%u)", i);
    is_int_m(mh_axis_find_bin(axis, binupper), i+1, buf);
  }
  is_int_m(mh_axis_find_bin(axis, min-1.), 0, "below-minimum x finds underflow bin");
  is_int_m(mh_axis_find_bin(axis, max+1.), nbins+1, "above-maximum x finds overflow bin");

  mh_axis_free(axis);
}

