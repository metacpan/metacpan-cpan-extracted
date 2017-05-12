#ifndef mh_histogram_h_
#define mh_histogram_h_

#include "mh_bitfield.h"
#include "mh_axis.h"

typedef struct mh_histogram {
  /* The number of dimensions in the histogram, starting from 0 */
  unsigned short ndim;
  /* The array of axises with ndim elements */
  mh_axis_t **axises;
  /* The actual bins */
  double *data;
  /* Bit field indicating whether a given bin is an
   * overflow (or underflow) bin */
  mh_bitfield_t overflow_bin_bitfield;
  unsigned int nbins_total;

  /* content */
  unsigned int nfills;

  /* derived content */
  double total;

  /* scratch space */
  unsigned int *bin_buffer; /* purely internal! */
  /* May be used for passing ndim arguments to mh_hist_ functions only, see MH_HIST_ARG_BIN_BUFFER */
  unsigned int *arg_bin_buffer;
  double *arg_coord_buffer;
} mh_histogram_t;

#define MH_HIST_NDIM(h) ((h)->ndim)

#define MH_HIST_TOTAL(h) ((h)->total)
#define MH_HIST_NFILLS(h) ((h)->nfills)
#define MH_HIST_AXIS(h, idim) ((h)->axises[idim])

/* A pre-allocated array of unsigned ints with "ndim" entries. That is,
 * you are free to use this to pass a set of "ndim" unsigned ints to
 * one of the API functions. Use it locally only! Do not use it in any other
 * way then to save a malloc/free pair (due to the dynamic nature of the
 * number of dimensions in a histogram) when calling an API function! */
#define MH_HIST_ARG_BIN_BUFFER(h) ((h)->arg_bin_buffer)
/* Same as MH_HIST_ARG_BIN_BUFFER, but for coordinates (IOW doubles) */
#define MH_HIST_ARG_COORD_BUFFER(h) ((h)->arg_coord_buffer)

/*
 *
 * Allocation/deallocation related functions
 */

/* Creates a new histogram with the specified dimensionality and axises.
 * Takes ownership of the (presumably individually allocated) mh_axis_t objects!
 * Does not take ownership of the outer array of pointers.
 */
mh_histogram_t *mh_hist_create(unsigned short ndim, mh_axis_t **axises);

/* Clones a full histogram. If do_copy_data isn't set, zeroes the data array,
 * creating an empty clone.. */
mh_histogram_t *mh_hist_clone(mh_histogram_t *hist_proto, int do_copy_data);

/* Free a histogram */
void mh_hist_free(mh_histogram_t *hist);


/*
 *
 * Bin/coordinate calculation related functions
 */

/* Given a vector of bin numbers in each dimension, returns the index into
 * the 1D data array. The 1D array includes under- and overflow bins,
 * so the bin numbers are 1-based as usual and include nbins+1 as an
 * overflow. */
unsigned int mh_hist_flat_bin_number(mh_histogram_t *hist, unsigned int dim_bins[]);

/* Reverse of mh_hist_flat_bin_number: flat number to unsigned int[ndims].
 * Output array needs to be allocated by the caller. Doesn't do bounds checking. */
void mh_hist_flat_bin_number_to_dim_bins(mh_histogram_t *hist, unsigned int flat_bin, unsigned int dim_bins[]);

/* Calculate and return the total number of bins in a histogram
 * including over- and underflow. */
unsigned int mh_hist_total_nbins(mh_histogram_t *hist);

/* Finds the set of bin numbers from a set of coordinates. Allocations are resp. of caller. */
void mh_hist_find_bin_numbers(mh_histogram_t *hist, double coord[], unsigned int bin[]);

/* Given an array of ndim coordinates, finds the internal bin id in the histogram.
 * mh_hist_find_bin_buf does the same but also exposes the ndim bin numbers. */
unsigned int mh_hist_find_bin(mh_histogram_t *hist, double coord[]);
unsigned int mh_hist_find_bin_buf(mh_histogram_t *hist, double coord[], unsigned int bin_number_buffer[]);

/* Given array of bin numbers or a linear bin index, return whether or not
 * the bin is an overflow bin. Efficient for linear bin indices.
 * "Overflow bin" means "underflow or overflow" or "not a normal bin". */
int mh_hist_is_overflow_bin(mh_histogram_t *hist, unsigned int dim_bins[]);
int mh_hist_is_overflow_bin_linear(mh_histogram_t *hist, unsigned int linear_bin_num);

/*
 *
 * Histogram data operations
 */

/* Adds 1 to the bin at the coordinates x, returns flat bin number
 * or UINT_MAX if out of bounds. */
unsigned int mh_hist_fill(mh_histogram_t *hist, double x[]);

/* Adds 1 to each bin at each of the coordinates in xs.
 * This is to mean that xs is an array of n coordinate sets:
 * xs[1][0] would be the first coordinate of the second coordinate set. */
void mh_hist_fill_n(mh_histogram_t *hist, unsigned int n, double **xs);

/* Adds "weight" to the bin at the coordinates x. Returns flat bin number
 * or UINT_MAX if out of bounds. */
unsigned int mh_hist_fill_w(mh_histogram_t *hist, double x[], double weight);

/* Adds weights[i] to each of the bins at the coordinates in xs (see mh_hist_fill_n) */
void mh_hist_fill_nw(mh_histogram_t *hist, unsigned int n, double **xs, double weights[]);

/* The follwing four functions are the respective same as the
 * above mh_hist_fill_* functions, except that they operate on ndim bin indexes
 * instead of user coordinates.
 */
unsigned int mh_hist_fill_bin(mh_histogram_t *hist, unsigned int dim_bins[]);
unsigned int mh_hist_fill_bin_w(mh_histogram_t *hist, unsigned int dim_bins[], double weight);
void mh_hist_fill_bin_n(mh_histogram_t *hist, unsigned int n, unsigned int **dim_bins);
void mh_hist_fill_bin_nw(mh_histogram_t *hist, unsigned int n, unsigned int **dim_bins, double weights[]);

/* Sets the bin content of the bin defined by the provided per-dimension bin numbers.
 * Returns -1 when out of range, 0 on success. */
int mh_hist_set_bin_content(mh_histogram_t *hist, unsigned int dim_bins[], double content);

/* Gets the content of the bin identified by dim_bins bin numbers.
 * Returns -1 when out of range, 0 on success. */
int mh_hist_get_bin_content(mh_histogram_t *hist, unsigned int dim_bins[], double *content);


/*
 *
 * Histogram data/dimensionality operations
 */

/* Returns a new histogram that contains the same data as the input, except it is N-1 dimensional
 * where the "contracted_dimension"th dimension has been summed over (counting dimensions from 0).
 */
mh_histogram_t *mh_hist_contract_dimension(mh_histogram_t *hist, unsigned int contracted_dimension);

/* Transforms the given histogram into a cumulative histogram in the provided dimension
 * by summing over the values in that dimension as H[i] = sum(j=0..i, H[j]).
 * Returns 0 if successful, -1 otherwise (cumulation_dimension out of range).
 */
int mh_hist_cumulate(mh_histogram_t *hist, unsigned int cumulation_dimension);

/*
 *
 * Test/comparison operations
 */

/* Returns 1 if the data in both histograms is equal within epsilon. epsilon defaults
 * to the machine epsilon (DBL_EPSILON). Checks that the total number of bins is
 * equal, but does not check whether the axises are equivalent nor the number of fills
 * or total content.
 */
int mh_hist_data_equal(mh_histogram_t *left, mh_histogram_t *right);
int mh_hist_data_equal_eps(mh_histogram_t *left, mh_histogram_t *right, double epsilon);



/*
 *
 * Debugging functions. Not proper API.
 */
void mh_hist_debug_bin_iter_print(mh_histogram_t *hist);
void mh_hist_debug_dump_data(mh_histogram_t *hist);



#endif
