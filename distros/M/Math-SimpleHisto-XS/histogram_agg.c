#include "histogram_agg.h"
#include "histogram.h"

double
histo_mean(pTHX_ simple_histo_1d* self)
{
  double x;
  double* data;
  unsigned int i, n;
  double retval = 0.;

  data = self->data;
  n = self->nbins;
  if (self->bins == NULL) {
    const double binsize = self->binsize;
    x = self->min + 0.5*binsize;
    for (i = 0; i < n; ++i) {
      retval += data[i] * x;
      x += binsize;
    }
  }
  else { /* non-constant binsize */
    const double* bins = self->bins;
    for (i = 0; i < n; ++i) {
      x = 0.5*(bins[i] + bins[i+1]);
      retval += data[i] * x;
    }
  }
  retval /= self->total;

  return retval;
}

double
histo_median(pTHX_ simple_histo_1d* self)
{
  simple_histo_1d* cum_hist;
  double* data;
  unsigned int i, n, median_bin;
  double sum_below, sum_above, x;

  HS_ASSERT_CUMULATIVE(self);
  cum_hist = self->cumulative_hist;
  data = self->data;
  n = self->nbins;
  /* The bin which is >= 0.5, thus the +1 */
  if (cum_hist->data[0] >= 0.5)
    median_bin = 0;
  else
    median_bin = 1+find_bin_nonconstant(0.5, cum_hist->nbins, cum_hist->data);

  sum_below = 0.;
  for (i = 0; i < median_bin; ++i)
    sum_below += data[i];
  sum_above = 0.;
  for (i = median_bin+1; i < n; ++i)
    sum_above += data[i];
  /* The fraction of the median bin that is below the estimated median */
  x = 0.5 * ( (sum_above-sum_below)/data[median_bin] + 1 );

  /* median estimate = lower boundary of median bin + x * median bin size */
  if (self->bins == 0)
    return self->min + ( (double)median_bin + x ) * self->binsize;
  else /* variable bin sizes */
    return self->bins[median_bin] + (self->bins[median_bin+1] - self->bins[median_bin]) * x;
}

double
histo_standard_deviation(pTHX_ simple_histo_1d* self)
{
  const double mean = histo_mean(aTHX_ self);
  return histo_standard_deviation_with_mean(aTHX_ self, mean);
}

double
histo_standard_deviation_with_mean(pTHX_ simple_histo_1d* self, double mean)
{
  /* sqrt( (1/n) * sum( x_i - x_mean )^2 ) */

  double x;
  double* data;
  unsigned int i, n;
  double retval = 0.;

  data = self->data;
  n = self->nbins;
  if (self->bins == NULL) {
    const double binsize = self->binsize;
    x = self->min + 0.5*binsize;
    for (i = 0; i < n; ++i) {
      retval += data[i] * (x - mean) * (x - mean);
      x += binsize;
    }
  }
  else { /* non-constant binsize */
    const double* bins = self->bins;
    for (i = 0; i < n; ++i) {
      x = 0.5*(bins[i] + bins[i+1]);
      retval += data[i] * (x - mean) * (x - mean);
    }
  }

  return sqrt(retval/(double)self->total);
}
