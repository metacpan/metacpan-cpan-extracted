#include <stdio.h>
#include <stdlib.h>
#include <mh_histogram.h>
#include <mh_axis.h>

#include "mytap.h"


mh_histogram_t *histogram_clone_dance(mh_histogram_t *input);
void run_tests();

int
main (int argc, char **argv)
{
  UNUSED(argc);
  UNUSED(argv);
  pass();

  run_tests(0);
  run_tests(1);

  done_testing();
  return 0;
}

void
run_tests(int do_clone)
{
  mh_histogram_t *h, *htmp;
  mh_axis_t *axises[4];
  double *w;
  double *c;
  unsigned int dim_bins[4];
  const unsigned int ndim = 4;
  double content;
  
  axises[0] = mh_axis_create(3, MH_AXIS_OPT_FIXEDBINS);
  mh_axis_init(axises[0], -10., 0.);

  axises[1] = mh_axis_create(4, MH_AXIS_OPT_VARBINS);
  mh_axis_init(axises[1], -13., 10000.);
  axises[1]->bins[0] = -13.;
  axises[1]->bins[1] = 130.;
  axises[1]->bins[2] = 1300.;
  axises[1]->bins[3] = 1500.;
  axises[1]->bins[4] = 10000.;

  axises[2] = mh_axis_create(2, MH_AXIS_OPT_FIXEDBINS);
  mh_axis_init(axises[2], 0., 1.);

  axises[3] = mh_axis_create(3, MH_AXIS_OPT_FIXEDBINS);
  mh_axis_init(axises[3], 0.1, 1.1);

  h = mh_hist_create(ndim, axises);
  if (do_clone) {
    htmp = mh_hist_clone(h, 1);
    mh_hist_free(h);
    h = htmp;
  }

  /* choose coords, check bin content == 0, then fill and recheck */
  c = malloc(sizeof(double) * 4);
  w = malloc(sizeof(double) * 1);
  c[0] = 0.; c[1] = 0.; c[2] = 0.; c[3] = 1.;
  mh_hist_find_bin_numbers(h, c, dim_bins);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, 0., "bin is zero to boot");
  mh_hist_fill(h, c);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, 1., "bin after fill");
  mh_hist_fill_w(h, c, 0.1);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, 1.1, "bin after wfill");
  mh_hist_fill_n(h, 1, &c);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, 2.1, "bin after nfill");
  *w = 12.3;
  mh_hist_fill_nw(h, 1, &c, w);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, 14.4, "bin after nwfill");
  is_int(mh_hist_set_bin_content(h, dim_bins, -1.2), 0);
  is_int(mh_hist_get_bin_content(h, dim_bins, &content), 0);
  is_double_m(1.e-9, content, -1.2, "bin after explicit set");

  /* test filling with bin coords */
  mh_hist_find_bin_numbers(h, c, h->arg_bin_buffer);

  mh_hist_fill_bin(h, h->arg_bin_buffer);
  is_int(mh_hist_get_bin_content(h, h->arg_bin_buffer, &content), 0);
  is_double_m(1.e-9, content, -.2, "bin after bin-num fill");
  mh_hist_fill_bin_w(h, h->arg_bin_buffer, 0.3);
  is_int(mh_hist_get_bin_content(h, h->arg_bin_buffer, &content), 0);
  is_double_m(1.e-9, content, .1, "bin after wfill");
  mh_hist_fill_bin_n(h, 1, &(h->arg_bin_buffer));
  is_int(mh_hist_get_bin_content(h, h->arg_bin_buffer, &content), 0);
  is_double_m(1.e-9, content, 1.1, "bin after nfill");
  mh_hist_fill_bin_nw(h, 1, &(h->arg_bin_buffer), w);
  is_int(mh_hist_get_bin_content(h, h->arg_bin_buffer, &content), 0);
  is_double_m(1.e-9, content, 1.1+12.3, "bin after nwfill");

  free(c);
  free(w);
  mh_hist_free(h);
}



mh_histogram_t *
histogram_clone_dance(mh_histogram_t *input)
{
  mh_histogram_t *cl = mh_hist_clone(input, 0);
  mh_hist_free(input);
  input = mh_hist_clone(cl, 1);
  mh_hist_free(cl);
  return input;
}


