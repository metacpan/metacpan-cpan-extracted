#ifndef histogram_agg_h_
#define histogram_agg_h_

#include "histogram.h"

/* Calculate (an estimate of) the median of a histogram. */
double
histo_median(pTHX_ simple_histo_1d* self);

/* Calculate the mean of a histogram. */
double
histo_mean(pTHX_ simple_histo_1d* self);

/* Calculate (an estimate of) the standard deviation of a histogram. */
double
histo_standard_deviation(pTHX_ simple_histo_1d* self);
double
histo_standard_deviation_with_mean(pTHX_ simple_histo_1d* self, double mean);

#endif

