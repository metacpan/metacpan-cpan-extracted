package Image::Leptonica::Func::numafunc2;
$Image::Leptonica::Func::numafunc2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::numafunc2

=head1 VERSION

version 0.04

=head1 C<numafunc2.c>

   numafunc2.c

      Morphological (min/max) operations
          NUMA        *numaErode()
          NUMA        *numaDilate()
          NUMA        *numaOpen()
          NUMA        *numaClose()

      Other transforms
          NUMA        *numaTransform()
          l_int32      numaWindowedStats()
          NUMA        *numaWindowedMean()
          NUMA        *numaWindowedMeanSquare()
          l_int32      numaWindowedVariance()
          NUMA        *numaConvertToInt()

      Histogram generation and statistics
          NUMA        *numaMakeHistogram()
          NUMA        *numaMakeHistogramAuto()
          NUMA        *numaMakeHistogramClipped()
          NUMA        *numaRebinHistogram()
          NUMA        *numaNormalizeHistogram()
          l_int32      numaGetStatsUsingHistogram()
          l_int32      numaGetHistogramStats()
          l_int32      numaGetHistogramStatsOnInterval()
          l_int32      numaMakeRankFromHistogram()
          l_int32      numaHistogramGetRankFromVal()
          l_int32      numaHistogramGetValFromRank()
          l_int32      numaDiscretizeRankAndIntensity()
          l_int32      numaGetRankBinValues()

      Splitting a distribution
          l_int32      numaSplitDistribution()

      Comparing two histograms
          l_int32      numaEarthMoverDistance()

      Extrema finding
          NUMA        *numaFindPeaks()
          NUMA        *numaFindExtrema()
          l_int32     *numaCountReversals()

      Threshold crossings and frequency analysis
          l_int32      numaSelectCrossingThreshold()
          NUMA        *numaCrossingsByThreshold()
          NUMA        *numaCrossingsByPeaks()
          NUMA        *numaEvalBestHaarParameters()
          l_int32      numaEvalHaarSum()

    Things to remember when using the Numa:

    (1) The numa is a struct, not an array.  Always use accessors
        (see numabasic.c), never the fields directly.

    (2) The number array holds l_float32 values.  It can also
        be used to store l_int32 values.  See numabasic.c for
        details on using the accessors.

    (3) Occasionally, in the comments we denote the i-th element of a
        numa by na[i].  This is conceptual only -- the numa is not an array!

    Some general comments on histograms:

    (1) Histograms are the generic statistical representation of
        the data about some attribute.  Typically they're not
        normalized -- they simply give the number of occurrences
        within each range of values of the attribute.  This range
        of values is referred to as a 'bucket'.  For example,
        the histogram could specify how many connected components
        are found for each value of their width; in that case,
        the bucket size is 1.

    (2) In leptonica, all buckets have the same size.  Histograms
        are therefore specified by a numa of occurrences, along
        with two other numbers: the 'value' associated with the
        occupants of the first bucket and the size (i.e., 'width')
        of each bucket.  These two numbers then allow us to calculate
        the value associated with the occupants of each bucket.
        These numbers are fields in the numa, initialized to
        a startx value of 0.0 and a binsize of 1.0.  Accessors for
        these fields are functions numa*Parameters().  All histograms
        must have these two numbers properly set.

=head1 FUNCTIONS

=head2 numaClose

NUMA * numaClose ( NUMA *nas, l_int32 size )

  numaClose()

      Input:  nas
              size (of sel; greater than 0, odd; origin implicitly in center)
      Return: nad (opened), or null on error

  Notes:
      (1) The structuring element (sel) is linear, all "hits"
      (2) If size == 1, this returns a copy
      (3) We add a border before doing this operation, for the same
          reason that we add a border to a pix before doing a safe closing.
          Without the border, a small component near the border gets
          clipped at the border on dilation, and can be entirely removed
          by the following erosion, violating the basic extensivity
          property of closing.

=head2 numaConvertToInt

NUMA * numaConvertToInt ( NUMA *nas )

  numaConvertToInt()

      Input:  na
      Return: na with all values rounded to nearest integer, or
              null on error

=head2 numaCountReversals

l_int32 numaCountReversals ( NUMA *nas, l_float32 minreversal, l_int32 *pnr, l_float32 *pnrpl )

  numaCountReversals()

      Input:  nas (input values)
              minreversal (relative amount to resolve peaks and valleys)
              &nr (<optional return> number of reversals
              &nrpl (<optional return> reversal density: reversals/length)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The input numa is can be generated from pixExtractAlongLine().
          If so, the x parameters can be used to find the reversal
          frequency along a line.

=head2 numaCrossingsByPeaks

NUMA * numaCrossingsByPeaks ( NUMA *nax, NUMA *nay, l_float32 delta )

  numaCrossingsByPeaks()

      Input:  nax (<optional> numa of abscissa values)
              nay (numa of ordinate values, corresponding to nax)
              delta (parameter used to identify when a new peak can be found)
      Return: nad (abscissa pts at threshold), or null on error

  Notes:
      (1) If nax == NULL, we use startx and delx from nay to compute
          the crossing values in nad.

=head2 numaCrossingsByThreshold

NUMA * numaCrossingsByThreshold ( NUMA *nax, NUMA *nay, l_float32 thresh )

  numaCrossingsByThreshold()

      Input:  nax (<optional> numa of abscissa values; can be NULL)
              nay (numa of ordinate values, corresponding to nax)
              thresh (threshold value for nay)
      Return: nad (abscissa pts at threshold), or null on error

  Notes:
      (1) If nax == NULL, we use startx and delx from nay to compute
          the crossing values in nad.

=head2 numaDilate

NUMA * numaDilate ( NUMA *nas, l_int32 size )

  numaDilate()

      Input:  nas
              size (of sel; greater than 0, odd; origin implicitly in center)
      Return: nad (dilated), or null on error

  Notes:
      (1) The structuring element (sel) is linear, all "hits"
      (2) If size == 1, this returns a copy

=head2 numaDiscretizeRankAndIntensity

l_int32 numaDiscretizeRankAndIntensity ( NUMA *na, l_int32 nbins, NUMA **pnarbin, NUMA **pnam, NUMA **pnar, NUMA **pnabb )

  numaDiscretizeRankAndIntensity()

      Input:  na (normalized histogram of probability density vs intensity)
              nbins (number of bins at which the rank is divided)
              &pnarbin (<optional return> rank bin value vs intensity)
              &pnam (<optional return> median intensity in a bin vs
                     rank bin value, with @nbins of discretized rank values)
              &pnar (<optional return> rank vs intensity; this is
                     a cumulative norm histogram)
              &pnabb (<optional return> intensity at the right bin boundary
                      vs rank bin)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We are inverting the rank(intensity) function to get
          the intensity(rank) function at @nbins equally spaced
          values of rank between 0.0 and 1.0.  We save integer values
          for the intensity.
      (2) We are using the word "intensity" to describe the type of
          array values, but any array of non-negative numbers will work.
      (3) The output arrays give the following mappings, where the
          input is a normalized histogram of array values:
             array values     -->  rank bin number  (narbin)
             rank bin number  -->  median array value in bin (nam)
             array values     -->  cumulative norm = rank  (nar)
             rank bin number  -->  array value at right bin edge (nabb)

=head2 numaEarthMoverDistance

l_int32 numaEarthMoverDistance ( NUMA *na1, NUMA *na2, l_float32 *pdist )

  numaEarthMoverDistance()

      Input:  na1, na2 (two numas of the same size, typically histograms)
              &dist (<return> EM distance)
      Return: 0 if OK, 1 on error

 Notes:
     (1) The two numas must have the same size.  They do not need to be
         normalized to the same sum before applying the function.
     (2) For a 1D discrete function, the implementation of the EMD
         is trivial.  Just keep filling or emptying buckets in one numa
         to match the amount in the other, moving sequentially along
         both arrays.
     (3) We divide the sum of the absolute value of everything moved
         (by 1 unit at a time) by the sum of the numa (amount of "earth")
         to get the average distance that the "earth" was moved.
         Further normalization, by the number of buckets (minus 1),
         gives the distance as a fraction of the maximum possible
         distance, which is n-1.  This fraction is 1.0 for the situation
         where all the 'earth' in the first array is at one end, and
         all in the second array is at the other end.

=head2 numaErode

NUMA * numaErode ( NUMA *nas, l_int32 size )

  numaErode()

      Input:  nas
              size (of sel; greater than 0, odd; origin implicitly in center)
      Return: nad (eroded), or null on error

  Notes:
      (1) The structuring element (sel) is linear, all "hits"
      (2) If size == 1, this returns a copy
      (3) General comment.  The morphological operations are equivalent
          to those that would be performed on a 1-dimensional fpix.
          However, because we have not implemented morphological
          operations on fpix, we do this here.  Because it is only
          1 dimensional, there is no reason to use the more
          complicated van Herk/Gil-Werman algorithm, and we do it
          by brute force.

=head2 numaEvalBestHaarParameters

l_int32 numaEvalBestHaarParameters ( NUMA *nas, l_float32 relweight, l_int32 nwidth, l_int32 nshift, l_float32 minwidth, l_float32 maxwidth, l_float32 *pbestwidth, l_float32 *pbestshift, l_float32 *pbestscore )

  numaEvalBestHaarParameters()

      Input:  nas (numa of non-negative signal values)
              relweight (relative weight of (-1 comb) / (+1 comb)
                         contributions to the 'convolution'.  In effect,
                         the convolution kernel is a comb consisting of
                         alternating +1 and -weight.)
              nwidth (number of widths to consider)
              nshift (number of shifts to consider for each width)
              minwidth (smallest width to consider)
              maxwidth (largest width to consider)
              &bestwidth (<return> width giving largest score)
              &bestshift (<return> shift giving largest score)
              &bestscore (<optional return> convolution with
                          "Haar"-like comb)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a linear sweep of widths, evaluating at @nshift
          shifts for each width, computing the score from a convolution
          with a long comb, and finding the (width, shift) pair that
          gives the maximum score.  The best width is the "half-wavelength"
          of the signal.
      (2) The convolving function is a comb of alternating values
          +1 and -1 * relweight, separated by the width and phased by
          the shift.  This is similar to a Haar transform, except
          there the convolution is performed with a square wave.
      (3) The function is useful for finding the line spacing
          and strength of line signal from pixel sum projections.
      (4) The score is normalized to the size of nas divided by
          the number of half-widths.  For image applications, the input is
          typically an array of pixel projections, so one should
          normalize by dividing the score by the image width in the
          pixel projection direction.

=head2 numaEvalHaarSum

l_int32 numaEvalHaarSum ( NUMA *nas, l_float32 width, l_float32 shift, l_float32 relweight, l_float32 *pscore )

  numaEvalHaarSum()

      Input:  nas (numa of non-negative signal values)
              width (distance between +1 and -1 in convolution comb)
              shift (phase of the comb: location of first +1)
              relweight (relative weight of (-1 comb) / (+1 comb)
                         contributions to the 'convolution'.  In effect,
                         the convolution kernel is a comb consisting of
                         alternating +1 and -weight.)
              &score (<return> convolution with "Haar"-like comb)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a convolution with a comb of alternating values
          +1 and -relweight, separated by the width and phased by the shift.
          This is similar to a Haar transform, except that for Haar,
            (1) the convolution kernel is symmetric about 0, so the
                relweight is 1.0, and
            (2) the convolution is performed with a square wave.
      (2) The score is normalized to the size of nas divided by
          twice the "width".  For image applications, the input is
          typically an array of pixel projections, so one should
          normalize by dividing the score by the image width in the
          pixel projection direction.
      (3) To get a Haar-like result, use relweight = 1.0.  For detecting
          signals where you expect every other sample to be close to
          zero, as with barcodes or filtered text lines, you can
          use relweight > 1.0.

=head2 numaFindExtrema

NUMA * numaFindExtrema ( NUMA *nas, l_float32 delta )

  numaFindExtrema()

      Input:  nas (input values)
              delta (relative amount to resolve peaks and valleys)
      Return: nad (locations of extrema), or null on error

  Notes:
      (1) This returns a sequence of extrema (peaks and valleys).
      (2) The algorithm is analogous to that for determining
          mountain peaks.  Suppose we have a local peak, with
          bumps on the side.  Under what conditions can we consider
          those 'bumps' to be actual peaks?  The answer: if the
          bump is separated from the peak by a saddle that is at
          least 500 feet below the bump.
      (3) Operationally, suppose we are looking for a peak.
          We are keeping the largest value we've seen since the
          last valley, and are looking for a value that is delta
          BELOW our current peak.  When we find such a value,
          we label the peak, use the current value to label the
          valley, and then do the same operation in reverse (looking
          for a valley).

=head2 numaFindPeaks

NUMA * numaFindPeaks ( NUMA *nas, l_int32 nmax, l_float32 fract1, l_float32 fract2 )

  numaFindPeaks()

      Input:  source na
              max number of peaks to be found
              fract1  (min fraction of peak value)
              fract2  (min slope)
      Return: peak na, or null on error.

 Notes:
     (1) The returned na consists of sets of four numbers representing
         the peak, in the following order:
            left edge; peak center; right edge; normalized peak area

=head2 numaGetHistogramStats

l_int32 numaGetHistogramStats ( NUMA *nahisto, l_float32 startx, l_float32 deltax, l_float32 *pxmean, l_float32 *pxmedian, l_float32 *pxmode, l_float32 *pxvariance )

  numaGetHistogramStats()

      Input:  nahisto (histogram: y(x(i)), i = 0 ... nbins - 1)
              startx (x value of first bin: x(0))
              deltax (x increment between bins; the bin size; x(1) - x(0))
              &xmean (<optional return> mean value of histogram)
              &xmedian (<optional return> median value of histogram)
              &xmode (<optional return> mode value of histogram:
                     xmode = x(imode), where y(xmode) >= y(x(i)) for
                     all i != imode)
              &xvariance (<optional return> variance of x)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If the histogram represents the relation y(x), the
          computed values that are returned are the x values.
          These are NOT the bucket indices i; they are related to the
          bucket indices by
                x(i) = startx + i * deltax

=head2 numaGetHistogramStatsOnInterval

l_int32 numaGetHistogramStatsOnInterval ( NUMA *nahisto, l_float32 startx, l_float32 deltax, l_int32 ifirst, l_int32 ilast, l_float32 *pxmean, l_float32 *pxmedian, l_float32 *pxmode, l_float32 *pxvariance )

  numaGetHistogramStatsOnInterval()

      Input:  nahisto (histogram: y(x(i)), i = 0 ... nbins - 1)
              startx (x value of first bin: x(0))
              deltax (x increment between bins; the bin size; x(1) - x(0))
              ifirst (first bin to use for collecting stats)
              ilast (last bin for collecting stats; use 0 to go to the end)
              &xmean (<optional return> mean value of histogram)
              &xmedian (<optional return> median value of histogram)
              &xmode (<optional return> mode value of histogram:
                     xmode = x(imode), where y(xmode) >= y(x(i)) for
                     all i != imode)
              &xvariance (<optional return> variance of x)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If the histogram represents the relation y(x), the
          computed values that are returned are the x values.
          These are NOT the bucket indices i; they are related to the
          bucket indices by
                x(i) = startx + i * deltax

=head2 numaGetRankBinValues

l_int32 numaGetRankBinValues ( NUMA *na, l_int32 nbins, NUMA **pnarbin, NUMA **pnam )

  numaGetRankBinValues()

      Input:  na (just an array of values)
              nbins (number of bins at which the rank is divided)
              &pnarbin (<optional return> rank bin value vs array value)
              &pnam (<optional return> median intensity in a bin vs
                     rank bin value, with @nbins of discretized rank values)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Simple interface for getting a binned rank representation
          of an input array of values.  This returns two mappings:
             array value     -->  rank bin number  (narbin)
             rank bin number -->  median array value in each rank bin (nam)

=head2 numaGetStatsUsingHistogram

l_int32 numaGetStatsUsingHistogram ( NUMA *na, l_int32 maxbins, l_float32 *pmin, l_float32 *pmax, l_float32 *pmean, l_float32 *pvariance, l_float32 *pmedian, l_float32 rank, l_float32 *prval, NUMA **phisto )

  numaGetStatsUsingHistogram()

      Input:  na (an arbitrary set of numbers; not ordered and not
                  a histogram)
              maxbins (the maximum number of bins to be allowed in
                       the histogram; use 0 for consecutive integer bins)
              &min (<optional return> min value of set)
              &max (<optional return> max value of set)
              &mean (<optional return> mean value of set)
              &variance (<optional return> variance)
              &median (<optional return> median value of set)
              rank (in [0.0 ... 1.0]; median has a rank 0.5; ignored
                    if &rval == NULL)
              &rval (<optional return> value in na corresponding to @rank)
              &histo (<optional return> Numa histogram; use NULL to prevent)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a simple interface for gathering statistics
          from a numa, where a histogram is used 'under the covers'
          to avoid sorting if a rank value is requested.  In that case,
          by using a histogram we are trading speed for accuracy, because
          the values in @na are quantized to the center of a set of bins.
      (2) If the median, other rank value, or histogram are not requested,
          the calculation is all performed on the input Numa.
      (3) The variance is the average of the square of the
          difference from the mean.  The median is the value in na
          with rank 0.5.
      (4) There are two situations where this gives rank results with
          accuracy comparable to computing stastics directly on the input
          data, without binning into a histogram:
           (a) the data is integers and the range of data is less than
               @maxbins, and
           (b) the data is floats and the range is small compared to
               @maxbins, so that the binsize is much less than 1.
      (5) If a histogram is used and the numbers in the Numa extend
          over a large range, you can limit the required storage by
          specifying the maximum number of bins in the histogram.
          Use @maxbins == 0 to force the bin size to be 1.
      (6) This optionally returns the median and one arbitrary rank value.
          If you need several rank values, return the histogram and use
               numaHistogramGetValFromRank(nah, rank, &rval)
          multiple times.

=head2 numaHistogramGetRankFromVal

l_int32 numaHistogramGetRankFromVal ( NUMA *na, l_float32 rval, l_float32 *prank )

  numaHistogramGetRankFromVal()

      Input:  na (histogram)
              rval (value of input sample for which we want the rank)
              &rank (<return> fraction of total samples below rval)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If we think of the histogram as a function y(x), normalized
          to 1, for a given input value of x, this computes the
          rank of x, which is the integral of y(x) from the start
          value of x to the input value.
      (2) This function only makes sense when applied to a Numa that
          is a histogram.  The values in the histogram can be ints and
          floats, and are computed as floats.  The rank is returned
          as a float between 0.0 and 1.0.
      (3) The numa parameters startx and binsize are used to
          compute x from the Numa index i.

=head2 numaHistogramGetValFromRank

l_int32 numaHistogramGetValFromRank ( NUMA *na, l_float32 rank, l_float32 *prval )

  numaHistogramGetValFromRank()

      Input:  na (histogram)
              rank (fraction of total samples)
              &rval (<return> approx. to the bin value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If we think of the histogram as a function y(x), this returns
          the value x such that the integral of y(x) from the start
          value to x gives the fraction 'rank' of the integral
          of y(x) over all bins.
      (2) This function only makes sense when applied to a Numa that
          is a histogram.  The values in the histogram can be ints and
          floats, and are computed as floats.  The val is returned
          as a float, even though the buckets are of integer width.
      (3) The numa parameters startx and binsize are used to
          compute x from the Numa index i.

=head2 numaMakeHistogram

NUMA * numaMakeHistogram ( NUMA *na, l_int32 maxbins, l_int32 *pbinsize, l_int32 *pbinstart )

  numaMakeHistogram()

      Input:  na
              maxbins (max number of histogram bins)
              &binsize  (<return> size of histogram bins)
              &binstart (<optional return> start val of minimum bin;
                         input NULL to force start at 0)
      Return: na consisiting of histogram of integerized values,
              or null on error.

  Note:
      (1) This simple interface is designed for integer data.
          The bins are of integer width and start on integer boundaries,
          so the results on float data will not have high precision.
      (2) Specify the max number of input bins.   Then @binsize,
          the size of bins necessary to accommodate the input data,
          is returned.  It is one of the sequence:
                {1, 2, 5, 10, 20, 50, ...}.
      (3) If &binstart is given, all values are accommodated,
          and the min value of the starting bin is returned.
          Otherwise, all negative values are discarded and
          the histogram bins start at 0.

=head2 numaMakeHistogramAuto

NUMA * numaMakeHistogramAuto ( NUMA *na, l_int32 maxbins )

  numaMakeHistogramAuto()

      Input:  na (numa of floats; these may be integers)
              maxbins (max number of histogram bins; >= 1)
      Return: na consisiting of histogram of quantized float values,
              or null on error.

  Notes:
      (1) This simple interface is designed for accurate binning
          of both integer and float data.
      (2) If the array data is integers, and the range of integers
          is smaller than @maxbins, they are binned as they fall,
          with binsize = 1.
      (3) If the range of data, (maxval - minval), is larger than
          @maxbins, or if the data is floats, they are binned into
          exactly @maxbins bins.
      (4) Unlike numaMakeHistogram(), these bins in general have
          non-integer location and width, even for integer data.

=head2 numaMakeHistogramClipped

NUMA * numaMakeHistogramClipped ( NUMA *na, l_float32 binsize, l_float32 maxsize )

  numaMakeHistogramClipped()

      Input:  na
              binsize (typically 1.0)
              maxsize (of histogram ordinate)
      Return: na (histogram of bins of size @binsize, starting with
                  the na[0] (x = 0.0) and going up to a maximum of
                  x = @maxsize, by increments of @binsize), or null on error

  Notes:
      (1) This simple function generates a histogram of values
          from na, discarding all values < 0.0 or greater than
          min(@maxsize, maxval), where maxval is the maximum value in na.
          The histogram data is put in bins of size delx = @binsize,
          starting at x = 0.0.  We use as many bins as are
          needed to hold the data.

=head2 numaMakeRankFromHistogram

l_int32 numaMakeRankFromHistogram ( l_float32 startx, l_float32 deltax, NUMA *nasy, l_int32 npts, NUMA **pnax, NUMA **pnay )

  numaMakeRankFromHistogram()

      Input:  startx (xval corresponding to first element in nay)
              deltax (x increment between array elements in nay)
              nasy (input histogram, assumed equally spaced)
              npts (number of points to evaluate rank function)
              &nax (<optional return> array of x values in range)
              &nay (<return> rank array of specified npts)
      Return: 0 if OK, 1 on error

=head2 numaNormalizeHistogram

NUMA * numaNormalizeHistogram ( NUMA *nas, l_float32 tsum )

  numaNormalizeHistogram()

      Input:  nas (input histogram)
              tsum (target sum of all numbers in dest histogram;
                    e.g., use @tsum= 1.0 if this represents a
                    probability distribution)
      Return: nad (normalized histogram), or null on error

=head2 numaOpen

NUMA * numaOpen ( NUMA *nas, l_int32 size )

  numaOpen()

      Input:  nas
              size (of sel; greater than 0, odd; origin implicitly in center)
      Return: nad (opened), or null on error

  Notes:
      (1) The structuring element (sel) is linear, all "hits"
      (2) If size == 1, this returns a copy

=head2 numaRebinHistogram

NUMA * numaRebinHistogram ( NUMA *nas, l_int32 newsize )

  numaRebinHistogram()

      Input:  nas (input histogram)
              newsize (number of old bins contained in each new bin)
      Return: nad (more coarsely re-binned histogram), or null on error

=head2 numaSelectCrossingThreshold

l_int32 numaSelectCrossingThreshold ( NUMA *nax, NUMA *nay, l_float32 estthresh, l_float32 *pbestthresh )

  numaSelectCrossingThreshold()

      Input:  nax (<optional> numa of abscissa values; can be NULL)
              nay (signal)
              estthresh (estimated pixel threshold for crossing: e.g., for
                         images, white <--> black; typ. ~120)
              &bestthresh (<return> robust estimate of threshold to use)
      Return: 0 if OK, 1 on error

  Note:
     (1) When a valid threshold is used, the number of crossings is
         a maximum, because none are missed.  If no threshold intersects
         all the crossings, the crossings must be determined with
         numaCrossingsByPeaks().
     (2) @estthresh is an input estimate of the threshold that should
         be used.  We compute the crossings with 41 thresholds
         (20 below and 20 above).  There is a range in which the
         number of crossings is a maximum.  Return a threshold
         in the center of this stable plateau of crossings.
         This can then be used with numaCrossingsByThreshold()
         to get a good estimate of crossing locations.

=head2 numaSplitDistribution

l_int32 numaSplitDistribution ( NUMA *na, l_float32 scorefract, l_int32 *psplitindex, l_float32 *pave1, l_float32 *pave2, l_float32 *pnum1, l_float32 *pnum2, NUMA **pnascore )

  numaSplitDistribution()

      Input:  na (histogram)
              scorefract (fraction of the max score, used to determine
                          the range over which the histogram min is searched)
              &splitindex (<optional return> index for splitting)
              &ave1 (<optional return> average of lower distribution)
              &ave2 (<optional return> average of upper distribution)
              &num1 (<optional return> population of lower distribution)
              &num2 (<optional return> population of upper distribution)
              &nascore (<optional return> for debugging; otherwise use null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function is intended to be used on a distribution of
          values that represent two sets, such as a histogram of
          pixel values for an image with a fg and bg, and the goal
          is to determine the averages of the two sets and the
          best splitting point.
      (2) The Otsu method finds a split point that divides the distribution
          into two parts by maximizing a score function that is the
          product of two terms:
            (a) the square of the difference of centroids, (ave1 - ave2)^2
            (b) fract1 * (1 - fract1)
          where fract1 is the fraction in the lower distribution.
      (3) This works well for images where the fg and bg are
          each relatively homogeneous and well-separated in color.
          However, if the actual fg and bg sets are very different
          in size, and the bg is highly varied, as can occur in some
          scanned document images, this will bias the split point
          into the larger "bump" (i.e., toward the point where the
          (b) term reaches its maximum of 0.25 at fract1 = 0.5.
          To avoid this, we define a range of values near the
          maximum of the score function, and choose the value within
          this range such that the histogram itself has a minimum value.
          The range is determined by scorefract: we include all abscissa
          values to the left and right of the value that maximizes the
          score, such that the score stays above (1 - scorefract) * maxscore.
          The intuition behind this modification is to try to find
          a split point that both has a high variance score and is
          at or near a minimum in the histogram, so that the histogram
          slope is small at the split point.
      (4) We normalize the score so that if the two distributions
          were of equal size and at opposite ends of the numa, the
          score would be 1.0.

=head2 numaTransform

NUMA * numaTransform ( NUMA *nas, l_float32 shift, l_float32 scale )

  numaTransform()

      Input:  nas
              shift (add this to each number)
              scale (multiply each number by this)
      Return: nad (with all values shifted and scaled, or null on error)

  Notes:
      (1) Each number is shifted before scaling.
      (2) The operation sequence is opposite to that for Box and Pta:
          scale first, then shift.

=head2 numaWindowedMean

NUMA * numaWindowedMean ( NUMA *nas, l_int32 wc )

  numaWindowedMean()

      Input:  nas
              wc (half width of the convolution window)
      Return: nad (after low-pass filtering), or null on error

  Notes:
      (1) This is a convolution.  The window has width = 2 * @wc + 1.
      (2) We add a mirrored border of size @wc to each end of the array.

=head2 numaWindowedMeanSquare

NUMA * numaWindowedMeanSquare ( NUMA *nas, l_int32 wc )

  numaWindowedMeanSquare()

      Input:  nas
              wc (half width of the window)
      Return: nad (containing windowed mean square values), or null on error

  Notes:
      (1) The window has width = 2 * @wc + 1.
      (2) We add a mirrored border of size @wc to each end of the array.

=head2 numaWindowedStats

l_int32 numaWindowedStats ( NUMA *nas, l_int32 wc, NUMA **pnam, NUMA **pnams, NUMA **pnav, NUMA **pnarv )

  numaWindowedStats()

      Input:  nas (input numa)
              wc (half width of the window)
              &nam (<optional return> mean value in window)
              &nams (<optional return> mean square value in window)
              &pnav (<optional return> variance in window)
              &pnarv (<optional return> rms deviation from the mean)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a high-level convenience function for calculating
          any or all of these derived arrays.
      (2) These statistical measures over the values in the
          rectangular window are:
            - average value: <x>  (nam)
            - average squared value: <x*x> (nams)
            - variance: <(x - <x>)*(x - <x>)> = <x*x> - <x>*<x>  (nav)
            - square-root of variance: (narv)
          where the brackets < .. > indicate that the average value is
          to be taken over the window.
      (3) Note that the variance is just the mean square difference from
          the mean value; and the square root of the variance is the
          root mean square difference from the mean, sometimes also
          called the 'standard deviation'.
      (4) Internally, use mirrored borders to handle values near the
          end of each array.

=head2 numaWindowedVariance

l_int32 numaWindowedVariance ( NUMA *nam, NUMA *nams, NUMA **pnav, NUMA **pnarv )

  numaWindowedVariance()

      Input:  nam (windowed mean values)
              nams (windowed mean square values)
              &pnav (<optional return> numa of variance -- the ms deviation
                     from the mean)
              &pnarv (<optional return> numa of rms deviation from the mean)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The numas of windowed mean and mean square are precomputed,
          using numaWindowedMean() and numaWindowedMeanSquare().
      (2) Either or both of the variance and square-root of variance
          are returned, where the variance is the average over the
          window of the mean square difference of the pixel value
          from the mean:
                <(x - <x>)*(x - <x>)> = <x*x> - <x>*<x>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
