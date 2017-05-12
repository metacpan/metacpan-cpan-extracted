#include <stdio.h>
#include <stdlib.h>
#include <mh_histogram.h>
#include <mh_axis.h>

#include "mytap.h"


void test_flat_bin_number();
mh_histogram_t *make_cubything_hist(unsigned int ndim, unsigned int base_nbins, int varbins);
mh_histogram_t *histogram_clone_dance(mh_histogram_t *input);

int
main (int argc, char **argv)
{
  unsigned int i, j;
  UNUSED(argc);
  UNUSED(argv);
  pass();

  for (i = 0; i <= 1; ++i) {
    for (j = 2; j < 4; ++j) {
      /* without (0) and with (1) cloning */
      test_flat_bin_number(i, MH_AXIS_OPT_FIXEDBINS, j);
      test_flat_bin_number(i, MH_AXIS_OPT_VARBINS, j);
    }
  }

  done_testing();
  return 0;
}


void test_flat_bin_number(int do_clone, int varbins, unsigned int base_nbins)
{
  unsigned int i, x, y, z, prev_bin_no;
  mh_histogram_t *h1;
  mh_histogram_t *h2;
  mh_histogram_t *h3;
  unsigned int dim_bins1[1];
  unsigned int dim_bins2[2];
  unsigned int dim_bins3[3];
  unsigned int dim_bins_buf[3];
  unsigned int flat_bin;
  double coord1[1];
  double coord2[2];
  double coord3[3];
  char buf[2048];
  char dimbuf[2048];

  h1 = make_cubything_hist(1, base_nbins, varbins);
  if (do_clone != 0)
    h1 = histogram_clone_dance(h1);
  for (i = 0; i <= base_nbins+1; ++i) {
    dim_bins1[0] = i;
    coord1[0] = (double)i/(double)base_nbins - 1e-5;
    flat_bin = mh_hist_flat_bin_number(h1, dim_bins1);

    is_int_m(flat_bin, i, "1d cubything, from bin no");
    is_int_m(mh_hist_find_bin(h1, coord1), i, "1d cubything, from coord");
    mh_hist_find_bin_numbers(h1, coord1, dim_bins_buf);
    is_int_m(dim_bins_buf[0], i, "1d cubything finding bin nums. from coords");
    is_int_m(mh_hist_find_bin_buf(h1, coord1, dim_bins_buf), i, "1d cubything, from coord buf");

    mh_hist_flat_bin_number_to_dim_bins(h1, flat_bin, dim_bins_buf);
    is_int_m(dim_bins_buf[0], i, "1d cubything, reverse");

    /* Check overflow bin detection */
    if (i == 0 || i == base_nbins+1) {
      ok_m(mh_hist_is_overflow_bin(h1, dim_bins1), "1d cubything, overflow check");
      ok_m(mh_hist_is_overflow_bin_linear(h1, i), "1d cubything, linear overflow check");
    }
    else {
      ok_m(!mh_hist_is_overflow_bin(h1, dim_bins1), "1d cubything, overflow check");
      ok_m(!mh_hist_is_overflow_bin_linear(h1, i), "1d cubything, linear overflow check");
    }
  }

  h2 = make_cubything_hist(2, base_nbins, varbins);
  if (do_clone != 0)
    h2 = histogram_clone_dance(h2);
  sprintf(dimbuf, "with o/u: xbins=%u, ybins=%u", 2+MH_AXIS_NBINS(h2->axises[0]), 2+MH_AXIS_NBINS(h2->axises[1]));
  prev_bin_no = 0;
  for (y = 0; y <= base_nbins+2; ++y) {
    dim_bins2[1] = y;
    for (x = 0; x <= base_nbins+1; ++x) {
      const unsigned int exp = x + y*(base_nbins+2);
      if (x != 0 || y != 0)
        is_int_m(exp, prev_bin_no+1, "contiguous bins");
      prev_bin_no = exp;
      dim_bins2[0] = x;
      coord2[0] = (double)x/(double)base_nbins - 1e-5;
      coord2[1] = (double)y/(double)(base_nbins+1.) - 1e-5;
      flat_bin = mh_hist_flat_bin_number(h2, dim_bins2);

      sprintf(buf, "2d cubything, x=%u y=%u, res=%u exp=%u, (%s)", x, y, mh_hist_flat_bin_number(h2, dim_bins2), exp, dimbuf);
      is_int_m(flat_bin, exp, buf);
      is_int_m(mh_hist_find_bin(h2, coord2), exp, buf);
      mh_hist_find_bin_numbers(h2, coord2, dim_bins_buf);
      is_int(dim_bins_buf[0], x);
      is_int(dim_bins_buf[1], y);
      is_int_m(mh_hist_find_bin_buf(h2, coord2, dim_bins_buf), exp, buf);

      sprintf(buf, "2d cubything, reverse: flat_bin=%u x=%u y=%u, res=%u exp=%u, (%s)", flat_bin, x, y, mh_hist_flat_bin_number(h2, dim_bins2), exp, dimbuf);
      mh_hist_flat_bin_number_to_dim_bins(h2, flat_bin, dim_bins_buf);
      is_int_m(dim_bins_buf[0], dim_bins2[0], buf);
      is_int_m(dim_bins_buf[1], dim_bins2[1], buf);

      /* check overflow bin detection */
      if (x == 0 || x == base_nbins+1 || y == 0 || y == base_nbins+2) {
        sprintf(buf, "2d cubything, check overflow (yes): flat_bin=%u x=%u y=%u (%s)", flat_bin, x, y, dimbuf);
        ok_m(mh_hist_is_overflow_bin(h2, dim_bins2), buf);
        ok_m(mh_hist_is_overflow_bin_linear(h2, flat_bin), buf);
      }
      else {
        sprintf(buf, "2d cubything, check overflow (no): flat_bin=%u x=%u y=%u (%s)", flat_bin, x, y, dimbuf);
        ok_m(!mh_hist_is_overflow_bin(h2, dim_bins2), buf);
        ok_m(!mh_hist_is_overflow_bin_linear(h2, flat_bin), buf);
      }
    }
  }

  h3 = make_cubything_hist(3, base_nbins, varbins);
  if (do_clone != 0)
    h3 = histogram_clone_dance(h3);
  sprintf(dimbuf, "with o/u: xbins=%u, ybins=%u, zbins=%u", 2+MH_AXIS_NBINS(h3->axises[0]), 2+MH_AXIS_NBINS(h3->axises[1]), 2+MH_AXIS_NBINS(h3->axises[2]));
  for (z = 0; z <= base_nbins + 3; ++z) {
    dim_bins3[2] = z;
    for (y = 0; y <= base_nbins + 2; ++y) {
      dim_bins3[1] = y;
      for (x = 0; x <= base_nbins + 1; ++x) {
        const unsigned int exp = x + y*(base_nbins+2) + z*(base_nbins+1+2)*(base_nbins+2);
        if (x != 0 || y != 0 || z != 0)
          is_int_m(exp, prev_bin_no+1, "contiguous bins");
        prev_bin_no = exp;
        dim_bins3[0] = x;
        coord3[0] = (double)x/(double)base_nbins - 1e-5;
        coord3[1] = (double)y/(double)(base_nbins+1) - 1e-5;
        coord3[2] = (double)z/(double)(base_nbins+2) - 1e-5;
        sprintf(buf, "3d cubything, x=%u y=%u z=%u, res=%u exp=%u, (%s)", x, y, z, mh_hist_flat_bin_number(h3, dim_bins3), exp, dimbuf);

        flat_bin = mh_hist_flat_bin_number(h3, dim_bins3);
        is_int_m(flat_bin, exp, buf);

        is_int_m(mh_hist_find_bin(h3, coord3), exp, buf);
        mh_hist_find_bin_numbers(h3, coord3, dim_bins_buf);
        is_int(dim_bins_buf[0], x);
        is_int(dim_bins_buf[1], y);
        is_int(dim_bins_buf[2], z);
        is_int_m(mh_hist_find_bin_buf(h3, coord3, dim_bins_buf), exp, buf);

        sprintf(buf, "3d cubything, reverse: flat_bin=%u x=%u y=%u z=%u, res=%u exp=%u, (%s)", flat_bin, x, y, z, mh_hist_flat_bin_number(h3, dim_bins3), exp, dimbuf);
        mh_hist_flat_bin_number_to_dim_bins(h3, flat_bin, dim_bins_buf);
        is_int_m(dim_bins_buf[0], dim_bins3[0], buf);
        is_int_m(dim_bins_buf[1], dim_bins3[1], buf);
        is_int_m(dim_bins_buf[2], dim_bins3[2], buf);

        /* check overflow */
        if (   x == 0 || x == base_nbins+1
            || y == 0 || y == base_nbins+2
            || z == 0 || z == base_nbins+3)
        {
          sprintf(buf, "3d cubything, check overflow (yes): flat_bin=%u x=%u y=%u z=%u (%s)", flat_bin, x, y, z, dimbuf);
          ok_m(mh_hist_is_overflow_bin(h3, dim_bins3), buf);
          ok_m(mh_hist_is_overflow_bin_linear(h3, flat_bin), buf);
        }
        else {
          sprintf(buf, "3d cubything, check overflow (no): flat_bin=%u x=%u y=%u z=%u (%s)", flat_bin, x, y, z, dimbuf);
          ok_m(!mh_hist_is_overflow_bin(h3, dim_bins3), buf);
          ok_m(!mh_hist_is_overflow_bin_linear(h3, flat_bin), buf);
        }
      }
    }
  }

  mh_hist_free(h1);
  mh_hist_free(h2);
  mh_hist_free(h3);
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


mh_histogram_t *
make_cubything_hist(unsigned int ndim, unsigned int base_nbins, int varbins)
{
  unsigned int i, j;
  mh_histogram_t *h;
  mh_axis_t **axises = malloc(ndim * sizeof(mh_axis_t *));
  for (i = 0; i < ndim; ++i) {
    axises[i] = mh_axis_create(base_nbins+i, varbins);
    if (axises[i] == NULL) {
      fail("Failed to malloc axis!");
      return NULL;
    }
    mh_axis_init(axises[i], 0., 1.);
    if (varbins == MH_AXIS_OPT_VARBINS) {
      double *b = axises[i]->bins;
      for (j = 0; j <= base_nbins+i; ++j) {
        b[j] = 0. + (double)j/(base_nbins+i);
        /* printf("  i = %u   j = %u   =>   %f\n", i, j, b[j]); */
      }
    }
  }

  h = mh_hist_create(ndim, axises);
  free(axises);
  return h;
}
