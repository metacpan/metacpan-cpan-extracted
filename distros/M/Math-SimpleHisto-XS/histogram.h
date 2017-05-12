#ifndef histogram_h_
#define histogram_h_

/* These are currently necessary for the malloc wrappers that perl defines.
 * TODO: It probably warrants understanding to what extent they are important
 * and useful in this code. */
#include "EXTERN.h"
#include "perl.h"
#include "hist_constants.h"

struct simple_histo_1d_struct {
  /* parameters */
  double min;
  double max;
  unsigned int nbins;

  /* derived */
  double width;
  double binsize;

  /* content */
  unsigned int nfills;
  double overflow;
  double underflow;
  /* derived content */
  double total;

  /* main data store */
  double* data;
  /* Exists with nbins+1 elements if we do not have constant binsize */
  double* bins;

  /* Optional ptr to cumulative histo.
   * If this isn't 0, we need to deallocate in the parent
   * object's DESTROY. This isn't serialized nor cloned
   * ever since it can be recalculated.
   * Needs to be invalidated using HS_INVALIDATE_CUMULATIVE
   * on almost every operation on the histogram!
   * Not currently invalidated when setting the under-/overflow.
   */
  /* The stored cumulative hist MUST be normalized in such a way
   * that the last bin content is == 1. This is like ->cumulative(1) */
  struct simple_histo_1d_struct* cumulative_hist;
};

typedef struct simple_histo_1d_struct simple_histo_1d;

/* deallocates a histogram. Requires a THX */
#define HS_DEALLOCATE(hist)               \
    STMT_START {                          \
      simple_histo_1d* histptr = (hist);  \
      Safefree( (void*)histptr->data );   \
      if (histptr->bins != NULL)          \
        Safefree(histptr->bins);          \
      Safefree( (void*)histptr );         \
    } STMT_END


/* deallocates the cumulative histogram of the given histogram
 * IF NECESSARY. Requires a THX */
#define HS_INVALIDATE_CUMULATIVE(self)          \
    STMT_START {                                \
      if ((self)->cumulative_hist) {            \
        HS_DEALLOCATE((self)->cumulative_hist); \
        (self)->cumulative_hist = 0;            \
      }                                         \
    } STMT_END

/* allocates the cumulative histogram of the given histogram
 * IF NECESSARY. Requires a THX */
#define HS_ASSERT_CUMULATIVE(self)                                \
    STMT_START {                                                  \
      simple_histo_1d* selfptr = (self);                          \
      if (!(selfptr->cumulative_hist))                            \
        self->cumulative_hist = histo_cumulative(aTHX_ self, 1.); \
    } STMT_END

/* Fetch the center of the given bin without range checking. */
#define HS_BIN_CENTER(self, ibin)                                 \
      ((self)->bins == NULL)                                      \
        ? (self)->min + ((double)(ibin) + 0.5) * (self)->binsize  \
        : 0.5*((self)->bins[ibin] + (self)->bins[(ibin)+1])

/* Fetch the lower boundary of the given bin without range checking. */
#define HS_BIN_LOWER_BOUNDARY(self, ibin)                         \
      ((self)->bins == NULL)                                      \
        ? (self)->min + (double)(ibin) * (self)->binsize          \
        : (self)->bins[ibin]

/* Fetch the upper boundary of the given bin without range checking. */
#define HS_BIN_UPPER_BOUNDARY(self, ibin)                         \
      ((self)->bins == NULL)                                      \
        ?  (self)->min + ((double)((ibin) + 1)) * (self)->binsize \
        : (self)->bins[(ibin)+1]

/* creates a new fixed-bin histogram */
simple_histo_1d*
histo_alloc_new_fixed_bins(pTHX_ unsigned int nbins, double min, double max);

/* Clones the given histogram, 'empty' indicates that the clone should
 * be alike the original, but not contain the data. */
simple_histo_1d*
histo_clone(pTHX_ simple_histo_1d* src, bool empty);

/* Clones a given histogram while stripping off all bins below the input
 * histogram's bin 'bin_start' and beyond bin 'bin_end'. */
simple_histo_1d*
histo_clone_from_bin_range(pTHX_ simple_histo_1d* src, bool empty,
                           unsigned int bin_start, unsigned int bin_end);

/* Returns the bin number where x would be filled into the given
 * histogram abstracts away whether the given histogram uses
 * constant or non-constant bin sizes. */
unsigned int
histo_find_bin(simple_histo_1d* self, double x);

/* Fill n values x_in into the histogram. If the weights array w_in is
 * NULL, a weight of 1 will be used for all x. */
void
histo_fill(simple_histo_1d* self, const unsigned int n, const double* x_in, const double* w_in);

/* Same as histo_fill, but expects bin numbers instead of coordinates */
void
histo_fill_by_bin(simple_histo_1d* self, const unsigned int n, const int* ibin_in, const double* w_in);

/* Calculates the cumulative histogram of the source histogram.
 * If the prenormalization is > 0, the output histogram will be
 * normalized to that value before calculating the cumulative. */
simple_histo_1d*
histo_cumulative(pTHX_ simple_histo_1d* src, double prenormalization);

void
histo_multiply_constant(simple_histo_1d* self, double constant);

/* Add the contents of one histogram (to_add) to another (target).
 * Works only if the histograms have exactly the same binning and
 * are otherwise compatible. Returns whether the addition has been
 * performed or not. */
bool
histo_add_histogram(simple_histo_1d* target, simple_histo_1d* to_add);

/* Symmetric to histo_add_histogram: h1_i -= h2_i. */
bool
histo_subtract_histogram(simple_histo_1d* target, simple_histo_1d* to_subtract);

/* Symmetric to histo_add_histogram: h1_i *= h2_i. */
bool
histo_multiply_histogram(simple_histo_1d* target, simple_histo_1d* to_multiply);

/* Symmetric to histo_add_histogram: h1_i /= h2_i. */
bool
histo_divide_histogram(simple_histo_1d* target, simple_histo_1d* to_divide);

/* Rebin a given histogram to have 1/Nth as many bins.
 * rebin_factor must divide the number of bins in the histogram without
 * remainder. Returns a modified clone of the input histogram or NULL if
 * the rebin_factor does not divide the number of bins in the input
 * histogram. */
simple_histo_1d*
histo_rebin(pTHX_ simple_histo_1d* self, unsigned int rebin_factor);

/* Implements the binary search logic for locating the bin that a given
 * value falls into */
unsigned int
find_bin_nonconstant(double x, unsigned int nbins, double* bins);

#include "histogram_agg.h"

#endif
