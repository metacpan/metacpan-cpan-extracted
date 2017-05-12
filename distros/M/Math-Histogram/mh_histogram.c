#include "mh_histogram.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <math.h>
#include <limits.h>

static unsigned int
_mh_hist_compute_total_nbins(mh_histogram_t *hist)
{
  unsigned int i;
  unsigned int bins = 1;
  unsigned int ndim = MH_HIST_NDIM(hist);
  mh_axis_t **axises = hist->axises;

  for (i = 0; i < ndim; ++i)
    bins *= MH_AXIS_NBINS(axises[i])+2;
  /* printf("Total number of bins: %u\n", bins); */
  return bins;
}

static void
_mh_hist_populate_overflow_bin_bitfield(mh_histogram_t *hist)
{
  const unsigned int ndims = MH_HIST_NDIM(hist);
  const unsigned int nlinearbins = hist->nbins_total;
  unsigned int ilinear, i;
  mh_axis_t **axises = hist->axises;
  unsigned int *bin_buffer = hist->bin_buffer;
  mh_bitfield_t bitfield = hist->overflow_bin_bitfield;

  for (i = 0; i < ndims; ++i)
    bin_buffer[i] = 0;

  for (ilinear = 0; ilinear < nlinearbins;) {
    /*
     * printf("L=%u", ilinear);
     * for (i = 0; i < ndims; ++i)
     *   printf(" %u", bin_buffer[i]);
     * printf("\n");
     */
    /* FIXME there must be a better algorithm than a full iteration! */
    for (i = 0; i < ndims; ++i) {
      if (bin_buffer[i] == 0
          || bin_buffer[i] > MH_AXIS_NBINS(axises[i])) {
        MH_BITFIELD_SET(bitfield, ilinear);
        break;
      }
    }

    /* Iterate both linear bin and bin vector */
    ++ilinear;
    i = 0;
    ++bin_buffer[i];
    while (i < ndims && bin_buffer[i] >= MH_AXIS_NBINS(axises[i])+2) {
      bin_buffer[i] = 0;
      ++i;
      ++bin_buffer[i];
    }
  }

  /* printf("\n"); */
}

mh_histogram_t *
mh_hist_create(unsigned short ndim, mh_axis_t **axises)
{
  unsigned int nbins, i;
  mh_histogram_t *hist = malloc(sizeof(mh_histogram_t));
  if (hist == NULL)
    return NULL;
  hist->ndim = ndim;

  hist->bin_buffer = malloc(sizeof(unsigned int) * ndim * 2);
  if (hist->bin_buffer == NULL) {
    free(hist);
    return NULL;
  }

  /* share the alloc/free */
  hist->arg_bin_buffer = &hist->bin_buffer[ndim];

  hist->arg_coord_buffer = malloc(sizeof(double) * ndim);
  if (hist->arg_coord_buffer == NULL) {
    free(hist);
    free(hist->bin_buffer);
    return NULL;
  }


  hist->axises = malloc(sizeof(mh_axis_t *) * ndim);
  if (hist->axises == NULL) {
    free(hist->bin_buffer);
    free(hist->arg_coord_buffer);
    free(hist);
    return NULL;
  }
  for (i = 0; i < ndim; ++i)
    hist->axises[i] = axises[i];

  nbins = _mh_hist_compute_total_nbins(hist);
  hist->nbins_total = nbins;
  hist->data = (double *)calloc(nbins, sizeof(double));
  if (hist->data == NULL) {
    free(hist->bin_buffer);
    free(hist->axises);
    free(hist->arg_coord_buffer);
    free(hist);
    return NULL;
  }

  hist->overflow_bin_bitfield = MH_BITFIELD_CALLOC(nbins);
  if (hist->overflow_bin_bitfield == NULL) {
    free(hist->data);
    free(hist->bin_buffer);
    free(hist->axises);
    free(hist->arg_coord_buffer);
    free(hist);
    return NULL;
  }

  _mh_hist_populate_overflow_bin_bitfield(hist);

  /* TODO should initialization live elsewhere? */
  hist->total = 0.;
  hist->nfills = 0;

  return hist;
}

mh_histogram_t *
mh_hist_clone(mh_histogram_t *hist_proto, int do_copy_data)
{
  unsigned int nbins, i;
  mh_histogram_t *hist = malloc(sizeof(mh_histogram_t));
  if (hist == NULL)
    return NULL;
  hist->ndim = MH_HIST_NDIM(hist_proto);

  hist->bin_buffer = malloc(sizeof(unsigned int) * MH_HIST_NDIM(hist) * 2);
  if (hist->bin_buffer == NULL) {
    free(hist);
    return NULL;
  }

  /* share the alloc/free */
  hist->arg_bin_buffer = &(hist->bin_buffer[MH_HIST_NDIM(hist)]);

  hist->arg_coord_buffer = malloc(sizeof(double) * hist->ndim);
  if (hist->arg_coord_buffer == NULL) {
    free(hist->bin_buffer);
    free(hist->arg_coord_buffer);
    free(hist);
    return NULL;
  }

  hist->axises = malloc(sizeof(mh_axis_t *) * MH_HIST_NDIM(hist));
  if (hist->axises == NULL) {
    free(hist->bin_buffer);
    free(hist->arg_coord_buffer);
    free(hist);
    return NULL;
  }
  for (i = 0; i < hist->ndim; ++i)
    hist->axises[i] = mh_axis_clone(hist_proto->axises[i]);

  hist->nbins_total = hist_proto->nbins_total;
  nbins = hist->nbins_total;

  if (do_copy_data != 0) {
    hist->data = (double *)malloc(nbins * sizeof(double));
    if (hist->data == NULL) {
      free(hist->bin_buffer);
      free(hist->arg_coord_buffer);
      free(hist->axises);
      free(hist);
      return NULL;
    }
    memcpy(hist->data, hist_proto->data, nbins * sizeof(double));

    /* TODO should initialization live elsewhere? */
    hist->total = MH_HIST_TOTAL(hist_proto);
    hist->nfills = MH_HIST_NFILLS(hist_proto);
  }
  else {
    hist->data = (double *)calloc(nbins, sizeof(double));
    if (hist->data == NULL) {
      free(hist->bin_buffer);
      free(hist->arg_coord_buffer);
      free(hist->axises);
      free(hist);
      return NULL;
    }
    /* TODO should initialization live elsewhere? */
    hist->total = 0.;
    hist->nfills = 0;
  }

  i = (unsigned int)(ceilf((float)nbins/32));
  hist->overflow_bin_bitfield = MH_BITFIELD_MALLOC(nbins);
  if (hist->overflow_bin_bitfield == NULL) {
    free(hist->data);
    free(hist->bin_buffer);
    free(hist->arg_coord_buffer);
    free(hist->axises);
    free(hist);
    return NULL;
  }
  MH_BITFIELD_COPY(hist->overflow_bin_bitfield, hist_proto->overflow_bin_bitfield, nbins);

  return hist;
}


void
mh_hist_free(mh_histogram_t *hist)
{
  unsigned int i, ndim = MH_HIST_NDIM(hist);
  mh_axis_t **axises = hist->axises;
  for (i = 0; i < ndim; ++i)
    mh_axis_free(axises[i]);

  free(hist->bin_buffer); /* frees arg_bin_buffer as well */
  free(hist->arg_coord_buffer);
  free(hist->axises);
  free(hist->data);
  MH_BITFIELD_FREE(hist->overflow_bin_bitfield);
  free(hist);
}


unsigned int
mh_hist_flat_bin_number(mh_histogram_t *hist, unsigned int dim_bins[])
{
  const unsigned short ndim = MH_HIST_NDIM(hist);
  if (ndim == 1)
    return dim_bins[0];
  else {
    register unsigned int bin_index;
    register int i;
    mh_axis_t **axises = hist->axises;

    /* Suppose we have dim_bins = {5, 3, 4};
     * Then the index into the 1D data array is
     *   4 * (dim_bins[2]+2)*(dim_bins[1]+2) + 3 * (dim_bins[1]+2) + 5
     * which can be done more efficiently as
     *   ((4)*(dim_bins[2]+2) + 3)*(dim_bins[1]+2) + 5;
     * parenthesis hint at the execution order.
     */

    bin_index = dim_bins[ndim-1];
    /* printf("%u %u\n", bin_index, ndim); */
    for (i = (int)ndim-2; i >= 0; --i)
      bin_index = bin_index*(MH_AXIS_NBINS(axises[i])+2) + dim_bins[i];

    return bin_index;
  }
}


/* just as an API */
unsigned int
mh_hist_total_nbins(mh_histogram_t *hist)
{
  return hist->nbins_total;
}


void
mh_hist_find_bin_numbers(mh_histogram_t *hist, double coord[], unsigned int bin[])
{
  const unsigned int ndim = MH_HIST_NDIM(hist);
  unsigned int i;
  mh_axis_t **axises = hist->axises;
  for (i = 0; i < ndim; ++i) {
    bin[i] = mh_axis_find_bin(axises[i], coord[i]);
  }
}


unsigned int
mh_hist_find_bin(mh_histogram_t *hist, double coord[])
{
  mh_hist_find_bin_numbers(hist, coord, hist->bin_buffer);
  return mh_hist_flat_bin_number(hist, hist->bin_buffer);
}


unsigned int
mh_hist_find_bin_buf(mh_histogram_t *hist, double coord[], unsigned int bin_number_buffer[])
{
  mh_hist_find_bin_numbers(hist, coord, bin_number_buffer);
  return mh_hist_flat_bin_number(hist, bin_number_buffer);
}


void
mh_hist_flat_bin_number_to_dim_bins(mh_histogram_t *hist,
                                    unsigned int flat_bin,
                                    unsigned int dim_bins[])
{
  const unsigned short ndim = MH_HIST_NDIM(hist);
  if (ndim == 1)
    dim_bins[0] = flat_bin;
  else {
    register int i, nbins;
    register mh_axis_t **axises = hist->axises;

    for (i = 0; i < ndim; ++i) {
      nbins = MH_AXIS_NBINS(axises[i])+2;
      dim_bins[i] = flat_bin % nbins;
      flat_bin = (flat_bin - dim_bins[i]) / nbins;
    }
  }
}


unsigned int
mh_hist_fill(mh_histogram_t *hist, double x[])
{
  const unsigned int flat_bin = mh_hist_find_bin(hist, x);
  if (flat_bin >= hist->nbins_total)
    return UINT_MAX;
  hist->data[flat_bin] += 1;
  hist->total += 1;
  hist->nfills++;
  return flat_bin;
}


unsigned int
mh_hist_fill_bin(mh_histogram_t *hist, unsigned int dim_bins[])
{
  const unsigned int flat_bin = mh_hist_flat_bin_number(hist, dim_bins);
  if (flat_bin >= hist->nbins_total)
    return UINT_MAX;
  hist->data[flat_bin] += 1;
  hist->total += 1;
  hist->nfills++;
  return flat_bin;
}


unsigned int
mh_hist_fill_w(mh_histogram_t *hist, double x[], double weight)
{
  const unsigned int flat_bin = mh_hist_find_bin(hist, x);
  if (flat_bin >= hist->nbins_total)
    return UINT_MAX;
  hist->data[flat_bin] += weight;
  hist->total += weight;
  hist->nfills++;
  return flat_bin;
}


unsigned int
mh_hist_fill_bin_w(mh_histogram_t *hist, unsigned int dim_bins[], double weight)
{
  const unsigned int flat_bin = mh_hist_flat_bin_number(hist, dim_bins);
  if (flat_bin >= hist->nbins_total)
    return UINT_MAX;
  hist->data[flat_bin] += weight;
  hist->total += weight;
  hist->nfills++;
  return flat_bin;
}


void
mh_hist_fill_n(mh_histogram_t *hist, unsigned int n, double **xs)
{
  register unsigned int flat_bin;
  register unsigned int i;
  for (i = 0; i < n; ++i) {
    flat_bin = mh_hist_find_bin(hist, xs[i]);
    if (flat_bin >= hist->nbins_total)
      continue;
    hist->data[flat_bin] += 1;
  }
  hist->nfills += n;
  hist->total += n;
}


void
mh_hist_fill_bin_n(mh_histogram_t *hist, unsigned int n, unsigned int **dim_bins)
{
  register unsigned int flat_bin;
  register unsigned int i;
  for (i = 0; i < n; ++i) {
    flat_bin = mh_hist_flat_bin_number(hist, dim_bins[i]);
    if (flat_bin >= hist->nbins_total)
      continue;
    hist->data[flat_bin] += 1;
  }
  hist->nfills += n;
  hist->total += n;
}


void
mh_hist_fill_nw(mh_histogram_t *hist, unsigned int n, double **xs, double weights[])
{
  register unsigned int flat_bin;
  register unsigned int i;
  double w;
  for (i = 0; i < n; ++i) {
    w = weights[i];
    flat_bin = mh_hist_find_bin(hist, xs[i]);
    if (flat_bin >= hist->nbins_total)
      continue;
    hist->data[flat_bin] += w;
    hist->nfills += w;
    hist->total += w;
  }
}


void
mh_hist_fill_bin_nw(mh_histogram_t *hist, unsigned int n, unsigned int **dim_bins, double weights[])
{
  register unsigned int flat_bin;
  register unsigned int i;
  double w;
  for (i = 0; i < n; ++i) {
    w = weights[i];
    flat_bin = mh_hist_flat_bin_number(hist, dim_bins[i]);
    if (flat_bin >= hist->nbins_total)
      continue;
    hist->data[flat_bin] += w;
    hist->nfills += w;
    hist->total += w;
  }
}


int
mh_hist_set_bin_content(mh_histogram_t *hist, unsigned int dim_bins[], double content)
{
  const unsigned int flat_bin = mh_hist_flat_bin_number(hist, dim_bins);
  double old;
  if (flat_bin >= hist->nbins_total)
    return -1;
  old = hist->data[flat_bin];
  hist->data[flat_bin] = content;
  hist->total += content - old;
  return 0;
}


int
mh_hist_get_bin_content(mh_histogram_t *hist, unsigned int dim_bins[], double *content)
{
  const unsigned int flat_bin = mh_hist_flat_bin_number(hist, dim_bins);
  if (flat_bin >= hist->nbins_total) {
    content = NULL;
    return -1;
  }
  else {
    *content = hist->data[flat_bin];
    return 0;
  }
}


mh_histogram_t *
mh_hist_contract_dimension(mh_histogram_t *hist, unsigned int contracted_dimension)
{
  mh_axis_t **axises;
  mh_axis_t **new_hist_axises;
  mh_histogram_t *outhist;
  unsigned int i, j, linear_nbins, ilinear, flat_bin;
  unsigned int *dimension_map;
  unsigned int *dim_bin_buffer;
  unsigned int *reduced_dim_bin_buffer;
  unsigned int ndims = MH_HIST_NDIM(hist);

  if (ndims == 1 || contracted_dimension >= ndims)
    return NULL;

  axises = hist->axises;

  /* Mapping from reduced dimension number to original
   * dimension number, so from destination to source. */
  dimension_map = malloc(sizeof(unsigned int) * (ndims-1));
  /* Setup array of cloned axises for the new histogram. */
  new_hist_axises = malloc(sizeof(mh_axis_t *) * (ndims-1));
  j = 0;
  for (i = 0; i < ndims; ++i) {
    if (i == contracted_dimension) { /* FIXME there must be a better way */
      j = 1;
      continue;
    }
    dimension_map[i-j] = i;
    new_hist_axises[i-j] = mh_axis_clone(axises[i]);
    if (new_hist_axises[i-j] == NULL) {
      ndims = i-j; /* abuse for emergency cleanup */
      for (i = 0; i < ndims; ++i)
        free(new_hist_axises[i]);
      free(new_hist_axises);
      free(dimension_map);
      return NULL;
    }
  }

  /* Create output N-1 dimensional histogram. */
  outhist = mh_hist_create(ndims-1, new_hist_axises);
  free(new_hist_axises);

  dim_bin_buffer = malloc(ndims * sizeof(unsigned int));
  reduced_dim_bin_buffer = malloc((ndims-1) * sizeof(unsigned int));

  /* - Iterate over all bins in the source histogram.
   *   - Find the vector of bin indexes in each dimension.
   *   - Copy the bin indexes over to the N-1 dimensional vector.
   *   - Use that vector to write the original bin's content to the
   *     right bin in the output histogram.
   *
   * This isn't hugely efficient but nicely abstracts away the problem
   * with N/N-1 dimensionality by having the dimension mapping in a data
   * structure (dimension_map) and simply skipping a dimension to contract.
   */
  /* TODO allow skipping of overflow/underflow in contraction somehow?
   * TODO generic mechanism for contracting only a range of bins?
   */
  linear_nbins = hist->nbins_total;
  for (ilinear = 0; ilinear < linear_nbins; ++ilinear) {
    /* Get the [ix, iy, iz, ...] N-dim bin numbers from the linear bin. */
    mh_hist_flat_bin_number_to_dim_bins(hist, ilinear, dim_bin_buffer);

    /* Copy all dimension indexes but the one we're contracting. */
    for (i = 0; i < ndims-1; ++i)
      reduced_dim_bin_buffer[i] = dim_bin_buffer[ dimension_map[i] ];

    /* unrolled fill_w without updating total and nfills */
    flat_bin = mh_hist_flat_bin_number(outhist, reduced_dim_bin_buffer);
    /* direct access to hist->data since we're iterating in linearized bins already */
    outhist->data[flat_bin] += hist->data[ilinear];
  }

  free(dim_bin_buffer);
  free(reduced_dim_bin_buffer);

  /* fix the number of fills and total*/
  outhist->nfills = hist->nfills;
  outhist->total = hist->total;

  return outhist;
}


int
mh_hist_data_equal_eps(mh_histogram_t *left, mh_histogram_t *right, double epsilon)
{
  const unsigned int total_nbins_left = left->nbins_total;
  const unsigned int total_nbins_right = right->nbins_total;
  unsigned int i;
  double *data_left = left->data;
  double *data_right = right->data;

  if (total_nbins_left != total_nbins_right)
    return 0;

  for (i = 0; i < total_nbins_left; ++i) {
    if (   data_left[i] + epsilon < data_right[i]
        || data_left[i] - epsilon > data_right[i]) {
      /* printf("NOT EQUAL: at %u: left=%.10f right=%.10f\n", i, data_left[i], data_right[i]); */
      return 0;
    }
  }

  return 1;
}

int
mh_hist_data_equal(mh_histogram_t *left, mh_histogram_t *right)
{
  return mh_hist_data_equal_eps(left, right, DBL_EPSILON);
}


int
mh_hist_cumulate(mh_histogram_t *hist, unsigned int cumulation_dimension)
{
  const unsigned int ndims = MH_HIST_NDIM(hist);
  unsigned int ilinear;
  const unsigned int nlinearbins = hist->nbins_total;
  unsigned int *bin_buffer;

  if (cumulation_dimension >= ndims)
    return -1;

  /* In a single dimension, the content of the i-th bin of the cumulative
   * histogram is the content of the i-1-th bin of the cumulative histogram
   * PLUS the content of the i-th bin of the ORIGINAL histogram.
   *
   * So if we have an N-dimensional histogram, we simply apply that same
   * bit of logic to each bin in the dimension to cumulate.
   * Since there's not an easy facility yet to iterate over a single dimension,
   * we use the fact that due to the way we store data, the bin numbers increase
   * in such a way along each dimension as we iterate over the flattened
   * representation in memory, that C[i-1] has always been calculated.
   * This means that when we visit any given bin, we know we've visited all
   * other bins that precede the current bin in any dimension. In other words,
   * we can use the C[i] = C[i-1] + H[i] relation.
   * With this property and doing the same in-place, we get: H[i] += H[i-1]
   */
  bin_buffer = hist->bin_buffer;
  for (ilinear = 0; ilinear < nlinearbins; ++ilinear) {
    mh_hist_flat_bin_number_to_dim_bins(hist, ilinear, bin_buffer);
    if (bin_buffer[cumulation_dimension] > 0) {
      /* printf("%u = %f, ", ilinear, hist->data[ilinear]); */
      bin_buffer[cumulation_dimension]--; /* one step back in the cumulation dimension */
      hist->data[ilinear] += hist->data[ mh_hist_flat_bin_number(hist, bin_buffer) ];
      /* printf("after = %f (prevbin: %i, %f)\n", hist->data[ilinear], mh_hist_flat_bin_number(hist, bin_buffer), hist->data[mh_hist_flat_bin_number(hist, bin_buffer)]); */
    }
  }

  return 0;
}


void
mh_hist_debug_bin_iter_print(mh_histogram_t *hist)
{
  unsigned int i, j;
  const unsigned int ndim = MH_HIST_NDIM(hist);
  const unsigned int n = hist->nbins_total;

  for (i = 0; i < n; ++i) {
    mh_hist_flat_bin_number_to_dim_bins(hist, i, MH_HIST_ARG_BIN_BUFFER(hist));
    printf("[%u", MH_HIST_ARG_BIN_BUFFER(hist)[0]);
    for(j = 1; j < ndim; ++j) {
      printf(",%u", MH_HIST_ARG_BIN_BUFFER(hist)[j]);
    }
    printf("]\n");
  }
}

void
mh_hist_debug_dump_data(mh_histogram_t *hist)
{
  unsigned int i, j;
  unsigned int ndims = MH_HIST_NDIM(hist);
  unsigned int n = hist->nbins_total;
  for (i = 0; i < n; ++i) {
    mh_hist_flat_bin_number_to_dim_bins(hist, i, MH_HIST_ARG_BIN_BUFFER(hist));
    for (j = 0; j < ndims; ++j) {
      printf("%u ", (MH_HIST_ARG_BIN_BUFFER(hist))[j]);
    }
    printf("(%u) => %.10f\n", i, hist->data[i]);
  }
}

int
mh_hist_is_overflow_bin(mh_histogram_t *hist, unsigned int dim_bins[])
{
  const unsigned int flat_bin = mh_hist_flat_bin_number(hist, dim_bins);
  if (flat_bin >= hist->nbins_total)
    return 0;
  return MH_BITFIELD_GET(hist->overflow_bin_bitfield, flat_bin);
}

int
mh_hist_is_overflow_bin_linear(mh_histogram_t *hist, unsigned int linear_bin_num)
{
  if (linear_bin_num >= hist->nbins_total)
    return 0;
  return MH_BITFIELD_GET(hist->overflow_bin_bitfield, linear_bin_num);
}

