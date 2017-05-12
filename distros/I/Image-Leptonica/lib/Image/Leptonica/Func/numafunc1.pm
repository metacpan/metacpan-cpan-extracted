package Image::Leptonica::Func::numafunc1;
$Image::Leptonica::Func::numafunc1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::numafunc1

=head1 VERSION

version 0.04

=head1 C<numafunc1.c>

   numafunc1.c

      Arithmetic and logic
          NUMA        *numaArithOp()
          NUMA        *numaLogicalOp()
          NUMA        *numaInvert()
          l_int32      numaSimilar()
          l_int32      numaAddToNumber()

      Simple extractions
          l_int32      numaGetMin()
          l_int32      numaGetMax()
          l_int32      numaGetSum()
          NUMA        *numaGetPartialSums()
          l_int32      numaGetSumOnInterval()
          l_int32      numaHasOnlyIntegers()
          NUMA        *numaSubsample()
          NUMA        *numaMakeDelta()
          NUMA        *numaMakeSequence()
          NUMA        *numaMakeConstant()
          NUMA        *numaMakeAbsValue()
          NUMA        *numaAddBorder()
          NUMA        *numaAddSpecifiedBorder()
          NUMA        *numaRemoveBorder()
          l_int32      numaGetNonzeroRange()
          l_int32      numaGetCountRelativeToZero()
          NUMA        *numaClipToInterval()
          NUMA        *numaMakeThresholdIndicator()
          NUMA        *numaUniformSampling()
          NUMA        *numaReverse()

      Signal feature extraction
          NUMA        *numaLowPassIntervals()
          NUMA        *numaThresholdEdges()
          NUMA        *numaGetSpanValues()
          NUMA        *numaGetEdgeValues()

      Interpolation
          l_int32      numaInterpolateEqxVal()
          l_int32      numaInterpolateEqxInterval()
          l_int32      numaInterpolateArbxVal()
          l_int32      numaInterpolateArbxInterval()

      Functions requiring interpolation
          l_int32      numaFitMax()
          l_int32      numaDifferentiateInterval()
          l_int32      numaIntegrateInterval()

      Sorting
          NUMA        *numaSortGeneral()
          NUMA        *numaSortAutoSelect()
          NUMA        *numaSortIndexAutoSelect()
          l_int32      numaChooseSortType()
          NUMA        *numaSort()
          NUMA        *numaBinSort()
          NUMA        *numaGetSortIndex()
          NUMA        *numaGetBinSortIndex()
          NUMA        *numaSortByIndex()
          l_int32      numaIsSorted()
          l_int32      numaSortPair()
          NUMA        *numaInvertMap()

      Random permutation
          NUMA        *numaPseudorandomSequence()
          NUMA        *numaRandomPermutation()

      Functions requiring sorting
          l_int32      numaGetRankValue()
          l_int32      numaGetMedian()
          l_int32      numaGetBinnedMedian()
          l_int32      numaGetMode()
          l_int32      numaGetMedianVariation()

      Numa combination
          l_int32      numaJoin()
          l_int32      numaaJoin()
          NUMA        *numaaFlattenToNuma()


    Things to remember when using the Numa:

    (1) The numa is a struct, not an array.  Always use accessors
        (see numabasic.c), never the fields directly.

    (2) The number array holds l_float32 values.  It can also
        be used to store l_int32 values.  See numabasic.c for
        details on using the accessors.

    (3) If you use numaCreate(), no numbers are stored and the size is 0.
        You have to add numbers to increase the size.
        If you want to start with a numa of a fixed size, with each
        entry initialized to the same value, use numaMakeConstant().

    (4) Occasionally, in the comments we denote the i-th element of a
        numa by na[i].  This is conceptual only -- the numa is not an array!

=head1 FUNCTIONS

=head2 numaAddBorder

NUMA * numaAddBorder ( NUMA *nas, l_int32 left, l_int32 right, l_float32 val )

  numaAddBorder()

      Input:  nas
              left, right (number of elements to add on each side)
              val (initialize border elements)
      Return: nad (with added elements at left and right), or null on error

=head2 numaAddSpecifiedBorder

NUMA * numaAddSpecifiedBorder ( NUMA *nas, l_int32 left, l_int32 right, l_int32 type )

  numaAddSpecifiedBorder()

      Input:  nas
              left, right (number of elements to add on each side)
              type (L_CONTINUED_BORDER, L_MIRRORED_BORDER)
      Return: nad (with added elements at left and right), or null on error

=head2 numaAddToNumber

l_int32 numaAddToNumber ( NUMA *na, l_int32 index, l_float32 val )

  numaAddToNumber()

      Input:  na
              index (element to be changed)
              val (new value to be added)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is useful for accumulating sums, regardless of the index
          order in which the values are made available.
      (2) Before use, the numa has to be filled up to @index.  This would
          typically be used by creating the numa with the full sized
          array, initialized to 0.0, using numaMakeConstant().

=head2 numaArithOp

NUMA * numaArithOp ( NUMA *nad, NUMA *na1, NUMA *na2, l_int32 op )

  numaArithOp()

      Input:  nad (<optional> can be null or equal to na1 (in-place)
              na1
              na2
              op (L_ARITH_ADD, L_ARITH_SUBTRACT,
                  L_ARITH_MULTIPLY, L_ARITH_DIVIDE)
      Return: nad (always: operation applied to na1 and na2)

  Notes:
      (1) The sizes of na1 and na2 must be equal.
      (2) nad can only null or equal to na1.
      (3) To add a constant to a numa, or to multipy a numa by
          a constant, use numaTransform().

=head2 numaBinSort

NUMA * numaBinSort ( NUMA *nas, l_int32 sortorder )

  numaBinSort()

      Input:  nas (of non-negative integers with a max that is
                   typically less than 50,000)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: na (sorted), or null on error

  Notes:
      (1) Because this uses a bin sort with buckets of size 1, it
          is not appropriate for sorting either small arrays or
          arrays containing very large integer values.  For such
          arrays, use a standard general sort function like
          numaSort().

=head2 numaChooseSortType

l_int32 numaChooseSortType ( NUMA *nas )

  numaChooseSortType()

      Input:  na (to be sorted)
      Return: sorttype (L_SHELL_SORT or L_BIN_SORT), or UNDEF on error.

  Notes:
      (1) This selects either a shell sort or a bin sort, depending on
          the number of elements in nas and the dynamic range.
      (2) If there are negative values in nas, it selects shell sort.

=head2 numaClipToInterval

NUMA * numaClipToInterval ( NUMA *nas, l_int32 first, l_int32 last )

  numaClipToInterval()

      Input:  numa
              first, last (clipping interval)
      Return: numa with the same values as the input, but clipped
              to the specified interval

  Note: If you want the indices of the array values to be unchanged,
        use first = 0.
  Usage: This is useful to clip a histogram that has a few nonzero
         values to its nonzero range.

=head2 numaDifferentiateInterval

l_int32 numaDifferentiateInterval ( NUMA *nax, NUMA *nay, l_float32 x0, l_float32 x1, l_int32 npts, NUMA **pnadx, NUMA **pnady )

  numaDifferentiateInterval()

      Input:  nax (numa of abscissa values)
              nay (numa of ordinate values, corresponding to nax)
              x0 (start value of interval)
              x1 (end value of interval)
              npts (number of points to evaluate function in interval)
              &nadx (<optional return> array of x values in interval)
              &nady (<return> array of derivatives in interval)
      Return: 0 if OK, 1 on error (e.g., if x0 or x1 is outside range)

  Notes:
      (1) The values in nax must be sorted in increasing order.
          If they are not sorted, it is done in the interpolation
          step, and a warning is issued.
      (2) Caller should check for valid return.

=head2 numaFitMax

l_int32 numaFitMax ( NUMA *na, l_float32 *pmaxval, NUMA *naloc, l_float32 *pmaxloc )

  numaFitMax()

      Input:  na  (numa of ordinate values, to fit a max to)
              &maxval (<return> max value)
              naloc (<optional> associated numa of abscissa values)
              &maxloc (<return> abscissa value that gives max value in na;
                   if naloc == null, this is given as an interpolated
                   index value)
      Return: 0 if OK; 1 on error

  Note: if naloc is given, there is no requirement that the
        data points are evenly spaced.  Lagrangian interpolation
        handles that.  The only requirement is that the
        data points are ordered so that the values in naloc
        are either increasing or decreasing.  We test to make
        sure that the sizes of na and naloc are equal, and it
        is assumed that the correspondences na[i] as a function
        of naloc[i] are properly arranged for all i.

  The formula for Lagrangian interpolation through 3 data pts is:
       y(x) = y1(x-x2)(x-x3)/((x1-x2)(x1-x3)) +
              y2(x-x1)(x-x3)/((x2-x1)(x2-x3)) +
              y3(x-x1)(x-x2)/((x3-x1)(x3-x2))

  Then the derivative, using the constants (c1,c2,c3) defined below,
  is set to 0:
       y'(x) = 2x(c1+c2+c3) - c1(x2+x3) - c2(x1+x3) - c3(x1+x2) = 0

=head2 numaGetBinSortIndex

NUMA * numaGetBinSortIndex ( NUMA *nas, l_int32 sortorder )

  numaGetBinSortIndex()

      Input:  na (of non-negative integers with a max that is typically
                  less than 1,000,000)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: na (sorted), or null on error

  Notes:
      (1) This creates an array (or lookup table) that contains
          the sorted position of the elements in the input Numa.
      (2) Because it uses a bin sort with buckets of size 1, it
          is not appropriate for sorting either small arrays or
          arrays containing very large integer values.  For such
          arrays, use a standard general sort function like
          numaGetSortIndex().

=head2 numaGetBinnedMedian

l_int32 numaGetBinnedMedian ( NUMA *na, l_int32 *pval )

  numaGetBinnedMedian()

      Input:  na
              &val  (<return> integer median value)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Computes the median value of the numbers in the numa,
          using bin sort and finding the middle value in the sorted array.
      (2) See numaGetRankValue() for conditions on na for which
          this should be used.  Otherwise, use numaGetMedian().

=head2 numaGetCountRelativeToZero

l_int32 numaGetCountRelativeToZero ( NUMA *na, l_int32 type, l_int32 *pcount )

  numaGetCountRelativeToZero()

      Input:  numa
              type (L_LESS_THAN_ZERO, L_EQUAL_TO_ZERO, L_GREATER_THAN_ZERO)
              &count (<return> count of values of given type)
      Return: 0 if OK, 1 on error

=head2 numaGetEdgeValues

l_int32 numaGetEdgeValues ( NUMA *na, l_int32 edge, l_int32 *pstart, l_int32 *pend, l_int32 *psign )

  numaGetEdgeValues()

      Input:  na (numa that is output of numaThresholdEdges())
              edge (edge number, zero-based)
              &start (<optional return> location of start of transition)
              &end (<optional return> location of end of transition)
              &sign (<optional return> transition sign: +1 is rising,
                     -1 is falling)
      Output: 0 if OK, 1 on error

=head2 numaGetMax

l_int32 numaGetMax ( NUMA *na, l_float32 *pmaxval, l_int32 *pimaxloc )

  numaGetMax()

      Input:  na
              &maxval (<optional return> max value)
              &imaxloc (<optional return> index of max location)
      Return: 0 if OK; 1 on error

=head2 numaGetMedian

l_int32 numaGetMedian ( NUMA *na, l_float32 *pval )

  numaGetMedian()

      Input:  na
              &val  (<return> median value)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Computes the median value of the numbers in the numa, by
          sorting and finding the middle value in the sorted array.

=head2 numaGetMedianVariation

l_int32 numaGetMedianVariation ( NUMA *na, l_float32 *pmedval, l_float32 *pmedvar )

  numaGetMedianVariation()

      Input:  na
              &medval  (<optional return> median value)
              &medvar  (<return> median variation from median val)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Finds the median of the absolute value of the variation from
          the median value in the array.  Why take the absolute value?
          Consider the case where you have values equally distributed
          about both sides of a median value.  Without taking the absolute
          value of the differences, you will get 0 for the variation,
          and this is not useful.

=head2 numaGetMin

l_int32 numaGetMin ( NUMA *na, l_float32 *pminval, l_int32 *piminloc )

  numaGetMin()

      Input:  na
              &minval (<optional return> min value)
              &iminloc (<optional return> index of min location)
      Return: 0 if OK; 1 on error

=head2 numaGetMode

l_int32 numaGetMode ( NUMA *na, l_float32 *pval, l_int32 *pcount )

  numaGetMode()

      Input:  na
              &val  (<return> mode val)
              &count  (<optional return> mode count)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Computes the mode value of the numbers in the numa, by
          sorting and finding the value of the number with the
          largest count.
      (2) Optionally, also returns that count.

=head2 numaGetNonzeroRange

l_int32 numaGetNonzeroRange ( NUMA *na, l_float32 eps, l_int32 *pfirst, l_int32 *plast )

  numaGetNonzeroRange()

      Input:  numa
              eps (largest value considered to be zero)
              &first, &last (<return> interval of array indices
                             where values are nonzero)
      Return: 0 if OK, 1 on error or if no nonzero range is found.

=head2 numaGetPartialSums

NUMA * numaGetPartialSums ( NUMA *na )

  numaGetPartialSums()

      Input:  na
      Return: nasum, or null on error

  Notes:
      (1) nasum[i] is the sum for all j <= i of na[j].
          So nasum[0] = na[0].
      (2) If you want to generate a rank function, where rank[0] - 0.0,
          insert a 0.0 at the beginning of the nasum array.

=head2 numaGetRankValue

l_int32 numaGetRankValue ( NUMA *na, l_float32 fract, NUMA *nasort, l_int32 usebins, l_float32 *pval )

  numaGetRankValue()

      Input:  na
              fract (use 0.0 for smallest, 1.0 for largest)
              nasort (<optional> increasing sorted version of na)
              usebins (0 for general sort; 1 for bin sort)
              &val  (<return> rank val)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Computes the rank value of a number in the @na, which is
          the number that is a fraction @fract from the small
          end of the sorted version of @na.
      (2) If you do this multiple times for different rank values,
          sort the array in advance and use that for @nasort;
          if you're only calling this once, input @nasort == NULL.
      (3) If @usebins == 1, this uses a bin sorting method.
          Use this only where:
           * the numbers are non-negative integers
           * there are over 100 numbers
           * the maximum value is less than about 50,000
      (4) The advantage of using a bin sort is that it is O(n),
          instead of O(nlogn) for general sort routines.

=head2 numaGetSortIndex

NUMA * numaGetSortIndex ( NUMA *na, l_int32 sortorder )

  numaGetSortIndex()

      Input:  na
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: na giving an array of indices that would sort
              the input array, or null on error

=head2 numaGetSpanValues

l_int32 numaGetSpanValues ( NUMA *na, l_int32 span, l_int32 *pstart, l_int32 *pend )

  numaGetSpanValues()

      Input:  na (numa that is output of numaLowPassIntervals())
              span (span number, zero-based)
              &start (<optional return> location of start of transition)
              &end (<optional return> location of end of transition)
      Output: 0 if OK, 1 on error

=head2 numaGetSum

l_int32 numaGetSum ( NUMA *na, l_float32 *psum )

  numaGetSum()

      Input:  na
              &sum (<return> sum of values)
      Return: 0 if OK, 1 on error

=head2 numaGetSumOnInterval

l_int32 numaGetSumOnInterval ( NUMA *na, l_int32 first, l_int32 last, l_float32 *psum )

  numaGetSumOnInterval()

      Input:  na
              first (beginning index)
              last (final index)
              &sum (<return> sum of values in the index interval range)
      Return: 0 if OK, 1 on error

=head2 numaHasOnlyIntegers

l_int32 numaHasOnlyIntegers ( NUMA *na, l_int32 maxsamples, l_int32 *pallints )

  numaHasOnlyIntegers()

      Input:  na
              maxsamples (maximum number of samples to check)
              &allints (<return> 1 if all sampled values are ints; else 0)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Set @maxsamples == 0 to check every integer in na.  Otherwise,
          this samples no more than @maxsamples.

=head2 numaIntegrateInterval

l_int32 numaIntegrateInterval ( NUMA *nax, NUMA *nay, l_float32 x0, l_float32 x1, l_int32 npts, l_float32 *psum )

  numaIntegrateInterval()

      Input:  nax (numa of abscissa values)
              nay (numa of ordinate values, corresponding to nax)
              x0 (start value of interval)
              x1 (end value of interval)
              npts (number of points to evaluate function in interval)
              &sum (<return> integral of function over interval)
      Return: 0 if OK, 1 on error (e.g., if x0 or x1 is outside range)

  Notes:
      (1) The values in nax must be sorted in increasing order.
          If they are not sorted, it is done in the interpolation
          step, and a warning is issued.
      (2) Caller should check for valid return.

=head2 numaInterpolateArbxInterval

l_int32 numaInterpolateArbxInterval ( NUMA *nax, NUMA *nay, l_int32 type, l_float32 x0, l_float32 x1, l_int32 npts, NUMA **pnadx, NUMA **pnady )

  numaInterpolateArbxInterval()

      Input:  nax (numa of abscissa values)
              nay (numa of ordinate values, corresponding to nax)
              type (L_LINEAR_INTERP, L_QUADRATIC_INTERP)
              x0 (start value of interval)
              x1 (end value of interval)
              npts (number of points to evaluate function in interval)
              &nadx (<optional return> array of x values in interval)
              &nady (<return> array of y values in interval)
      Return: 0 if OK, 1 on error (e.g., if x0 or x1 is outside range)

  Notes:
      (1) The values in nax must be sorted in increasing order.
          If they are not sorted, we do it here, and complain.
      (2) If the values in nax are equally spaced, you can use
          numaInterpolateEqxInterval().
      (3) Caller should check for valid return.
      (4) We don't call numaInterpolateArbxVal() for each output
          point, because that requires an O(n) search for
          each point.  Instead, we do a single O(n) pass through
          nax, saving the indices to be used for each output yval.
      (5) Uses lagrangian interpolation.  See numaInterpolateEqxVal()
          for formulas.

=head2 numaInterpolateArbxVal

l_int32 numaInterpolateArbxVal ( NUMA *nax, NUMA *nay, l_int32 type, l_float32 xval, l_float32 *pyval )

  numaInterpolateArbxVal()

      Input:  nax (numa of abscissa values)
              nay (numa of ordinate values, corresponding to nax)
              type (L_LINEAR_INTERP, L_QUADRATIC_INTERP)
              xval
              &yval (<return> interpolated value)
      Return: 0 if OK, 1 on error (e.g., if xval is outside range)

  Notes:
      (1) The values in nax must be sorted in increasing order.
          If, additionally, they are equally spaced, you can use
          numaInterpolateEqxVal().
      (2) Caller should check for valid return.
      (3) Uses lagrangian interpolation.  See numaInterpolateEqxVal()
          for formulas.

=head2 numaInterpolateEqxInterval

l_int32 numaInterpolateEqxInterval ( l_float32 startx, l_float32 deltax, NUMA *nasy, l_int32 type, l_float32 x0, l_float32 x1, l_int32 npts, NUMA **pnax, NUMA **pnay )

  numaInterpolateEqxInterval()

      Input:  startx (xval corresponding to first element in nas)
              deltax (x increment between array elements in nas)
              nasy  (numa of ordinate values, assumed equally spaced)
              type (L_LINEAR_INTERP, L_QUADRATIC_INTERP)
              x0 (start value of interval)
              x1 (end value of interval)
              npts (number of points to evaluate function in interval)
              &nax (<optional return> array of x values in interval)
              &nay (<return> array of y values in interval)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Considering nasy as a function of x, the x values
          are equally spaced.
      (2) This creates nay (and optionally nax) of interpolated
          values over the specified interval (x0, x1).
      (3) If the interval (x0, x1) lies partially outside the array
          nasy (as interpreted by startx and deltax), it is an
          error and returns 1.
      (4) Note that deltax is the intrinsic x-increment for the input
          array nasy, whereas delx is the intrinsic x-increment for the
          output interpolated array nay.

=head2 numaInterpolateEqxVal

l_int32 numaInterpolateEqxVal ( l_float32 startx, l_float32 deltax, NUMA *nay, l_int32 type, l_float32 xval, l_float32 *pyval )

  numaInterpolateEqxVal()

      Input:  startx (xval corresponding to first element in array)
              deltax (x increment between array elements)
              nay  (numa of ordinate values, assumed equally spaced)
              type (L_LINEAR_INTERP, L_QUADRATIC_INTERP)
              xval
              &yval (<return> interpolated value)
      Return: 0 if OK, 1 on error (e.g., if xval is outside range)

  Notes:
      (1) Considering nay as a function of x, the x values
          are equally spaced
      (2) Caller should check for valid return.

  For linear Lagrangian interpolation (through 2 data pts):
         y(x) = y1(x-x2)/(x1-x2) + y2(x-x1)/(x2-x1)

  For quadratic Lagrangian interpolation (through 3 data pts):
         y(x) = y1(x-x2)(x-x3)/((x1-x2)(x1-x3)) +
                y2(x-x1)(x-x3)/((x2-x1)(x2-x3)) +
                y3(x-x1)(x-x2)/((x3-x1)(x3-x2))

=head2 numaInvert

NUMA * numaInvert ( NUMA *nad, NUMA *nas )

  numaInvert()

      Input:  nad (<optional> can be null or equal to nas (in-place)
              nas
      Return: nad (always: 'inverts' nas)

  Notes:
      (1) This is intended for use with indicator arrays (0s and 1s).
          It gives a boolean-type output, taking the input as
          an integer and inverting it:
              0              -->  1
              anything else  -->   0

=head2 numaInvertMap

NUMA * numaInvertMap ( NUMA *nas )

  numaInvertMap()

      Input:  nas
      Return: nad (the inverted map), or null on error or if not invertible

  Notes:
      (1) This requires that nas contain each integer from 0 to n-1.
          The array is typically an index array into a sort or permutation
          of another array.

=head2 numaIsSorted

l_int32 numaIsSorted ( NUMA *nas, l_int32 sortorder, l_int32 *psorted )

  numaIsSorted()

      Input:  nas
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
              &sorted (<return> 1 if sorted; 0 if not)
      Return: 1 if OK; 0 on error

  Notes:
      (1) This is a quick O(n) test if nas is sorted.  It is useful
          in situations where the array is likely to be already
          sorted, and a sort operation can be avoided.

=head2 numaJoin

l_int32 numaJoin ( NUMA *nad, NUMA *nas, l_int32 istart, l_int32 iend )

  numaJoin()

      Input:  nad  (dest numa; add to this one)
              nas  (<optional> source numa; add from this one)
              istart  (starting index in nas)
              iend  (ending index in nas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (2) iend < 0 means 'read to the end'
      (3) if nas == NULL, this is a no-op

=head2 numaLogicalOp

NUMA * numaLogicalOp ( NUMA *nad, NUMA *na1, NUMA *na2, l_int32 op )

  numaLogicalOp()

      Input:  nad (<optional> can be null or equal to na1 (in-place)
              na1
              na2
              op (L_UNION, L_INTERSECTION, L_SUBTRACTION, L_EXCLUSIVE_OR)
      Return: nad (always: operation applied to na1 and na2)

  Notes:
      (1) The sizes of na1 and na2 must be equal.
      (2) nad can only null or equal to na1.
      (3) This is intended for use with indicator arrays (0s and 1s).
          Input data is extracted as integers (0 == false, anything
          else == true); output results are 0 and 1.
      (4) L_SUBTRACTION is subtraction of val2 from val1.  For bit logical
          arithmetic this is (val1 & ~val2), but because these values
          are integers, we use (val1 && !val2).

=head2 numaLowPassIntervals

NUMA * numaLowPassIntervals ( NUMA *nas, l_float32 thresh, l_float32 maxn )

  numaLowPassIntervals()

      Input:  nas (input numa)
              thresh (threshold fraction of max; in [0.0 ... 1.0])
              maxn (for normalizing; set maxn = 0.0 to use the max in nas)
      Output: nad (interval abscissa pairs), or null on error

  Notes:
      (1) For each interval where the value is less than a specified
          fraction of the maximum, this records the left and right "x"
          value.

=head2 numaMakeAbsValue

NUMA * numaMakeAbsValue ( NUMA *nad, NUMA *nas )

  numaMakeAbsValue()

      Input:  nad (can be null for new array, or the same as nas for inplace)
              nas (input numa)
      Return: nad (with all numbers being the absval of the input),
              or null on error

=head2 numaMakeConstant

NUMA * numaMakeConstant ( l_float32 val, l_int32 size )

  numaMakeConstant()

      Input:  val
              size (of numa)
      Return: numa (of given size with all entries equal to 'val'),
              or null on error

=head2 numaMakeDelta

NUMA * numaMakeDelta ( NUMA *nas )

  numaMakeDelta()

      Input:  nas (input numa)
      Return: numa (of difference values val[i+1] - val[i]),
                    or null on error

=head2 numaMakeSequence

NUMA * numaMakeSequence ( l_float32 startval, l_float32 increment, l_int32 size )

  numaMakeSequence()

      Input:  startval
              increment
              size (of sequence)
      Return: numa of sequence of evenly spaced values, or null on error

=head2 numaMakeThresholdIndicator

NUMA * numaMakeThresholdIndicator ( NUMA *nas, l_float32 thresh, l_int32 type )

  numaMakeThresholdIndicator()

      Input:  nas (input numa)
              thresh (threshold value)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
      Output: nad (indicator array: values are 0 and 1)

  Notes:
      (1) For each element in nas, if the constraint given by 'type'
          correctly specifies its relation to thresh, a value of 1
          is recorded in nad.

=head2 numaPseudorandomSequence

NUMA * numaPseudorandomSequence ( l_int32 size, l_int32 seed )

  numaPseudorandomSequence()

      Input:  size (of sequence)
              seed (for random number generation)
      Return: na (pseudorandom on {0,...,size - 1}), or null on error

  Notes:
      (1) This uses the Durstenfeld shuffle.
          See: http://en.wikipedia.org/wiki/Fisher–Yates_shuffle.
          Result is a pseudorandom permutation of the sequence of integers
          from 0 to size - 1.

=head2 numaRandomPermutation

NUMA * numaRandomPermutation ( NUMA *nas, l_int32 seed )

  numaRandomPermutation()

      Input:  nas (input array)
              seed (for random number generation)
      Return: nas (randomly shuffled array), or null on error

=head2 numaRemoveBorder

NUMA * numaRemoveBorder ( NUMA *nas, l_int32 left, l_int32 right )

  numaRemoveBorder()

      Input:  nas
              left, right (number of elements to remove from each side)
      Return: nad (with removed elements at left and right), or null on error

=head2 numaReverse

NUMA * numaReverse ( NUMA *nad, NUMA *nas )

  numaReverse()

      Input:  nad (<optional> can be null or equal to nas)
              nas (input numa)
      Output: nad (reversed), or null on error

  Notes:
      (1) Usage:
            numaReverse(nas, nas);   // in-place
            nad = numaReverse(NULL, nas);  // makes a new one

=head2 numaSimilar

l_int32 numaSimilar ( NUMA *na1, NUMA *na2, l_float32 maxdiff, l_int32 *psimilar )

  numaSimilar()

      Input:  na1
              na2
              maxdiff (use 0.0 for exact equality)
              &similar (<return> 1 if similar; 0 if different)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Float values can differ slightly due to roundoff and
          accumulated errors.  Using @maxdiff > 0.0 allows similar
          arrays to be identified.

=head2 numaSort

NUMA * numaSort ( NUMA *naout, NUMA *nain, l_int32 sortorder )

  numaSort()

      Input:  naout (output numa; can be NULL or equal to nain)
              nain (input numa)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: naout (output sorted numa), or null on error

  Notes:
      (1) Set naout = nain for in-place; otherwise, set naout = NULL.
      (2) Source: Shell sort, modified from K&R, 2nd edition, p.62.
          Slow but simple O(n logn) sort.

=head2 numaSortAutoSelect

NUMA * numaSortAutoSelect ( NUMA *nas, l_int32 sortorder )

  numaSortAutoSelect()

      Input:  nas (input numa)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: naout (output sorted numa), or null on error

  Notes:
      (1) This does either a shell sort or a bin sort, depending on
          the number of elements in nas and the dynamic range.

=head2 numaSortByIndex

NUMA * numaSortByIndex ( NUMA *nas, NUMA *naindex )

  numaSortByIndex()

      Input:  nas
              naindex (na that maps from the new numa to the input numa)
      Return: nad (sorted), or null on error

=head2 numaSortGeneral

l_int32 numaSortGeneral ( NUMA *na, NUMA **pnasort, NUMA **pnaindex, NUMA **pnainvert, l_int32 sortorder, l_int32 sorttype )

  numaSortGeneral()

      Input:  na (source numa)
              nasort (<optional> sorted numa)
              naindex (<optional> index of elements in na associated
                       with each element of nasort)
              nainvert (<optional> index of elements in nasort associated
                        with each element of na)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
              sorttype (L_SHELL_SORT or L_BIN_SORT)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Sorting can be confusing.  Here's an array of five values with
          the results shown for the 3 output arrays.

          na      nasort   naindex   nainvert
          -----------------------------------
          3         9         2         3
          4         6         3         2
          9         4         1         0
          6         3         0         1
          1         1         4         4

          Note that naindex is a LUT into na for the sorted array values,
          and nainvert directly gives the sorted index values for the
          input array.  It is useful to view naindex is as a map:
                 0  -->  2
                 1  -->  3
                 2  -->  1
                 3  -->  0
                 4  -->  4
          and nainvert, the inverse of this map:
                 0  -->  3
                 1  -->  2
                 2  -->  0
                 3  -->  1
                 4  -->  4

          We can write these relations symbolically as:
              nasort[i] = na[naindex[i]]
              na[i] = nasort[nainvert[i]]

=head2 numaSortIndexAutoSelect

NUMA * numaSortIndexAutoSelect ( NUMA *nas, l_int32 sortorder )

  numaSortIndexAutoSelect()

      Input:  nas
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: nad (indices of nas, sorted by value in nas), or null on error

  Notes:
      (1) This does either a shell sort or a bin sort, depending on
          the number of elements in nas and the dynamic range.

=head2 numaSortPair

l_int32 numaSortPair ( NUMA *nax, NUMA *nay, l_int32 sortorder, NUMA **pnasx, NUMA **pnasy )

  numaSortPair()

      Input:  nax, nay (input arrays)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
              &nasx (<return> sorted)
              &naxy (<return> sorted exactly in order of nasx)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function sorts the two input arrays, nax and nay,
          together, using nax as the key for sorting.

=head2 numaSubsample

NUMA * numaSubsample ( NUMA *nas, l_int32 subfactor )

  numaSubsample()

      Input:  nas
              subfactor (subsample factor, >= 1)
      Return: nad (evenly sampled values from nas), or null on error

=head2 numaThresholdEdges

NUMA * numaThresholdEdges ( NUMA *nas, l_float32 thresh1, l_float32 thresh2, l_float32 maxn )

  numaThresholdEdges()

      Input:  nas (input numa)
              thresh1 (low threshold as fraction of max; in [0.0 ... 1.0])
              thresh2 (high threshold as fraction of max; in [0.0 ... 1.0])
              maxn (for normalizing; set maxn = 0.0 to use the max in nas)
      Output: nad (edge interval triplets), or null on error

  Notes:
      (1) For each edge interval, where where the value is less
          than @thresh1 on one side, greater than @thresh2 on
          the other, and between these thresholds throughout the
          interval, this records a triplet of values: the
          'left' and 'right' edges, and either +1 or -1, depending
          on whether the edge is rising or falling.
      (2) No assumption is made about the value outside the array,
          so if the value at the array edge is between the threshold
          values, it is not considered part of an edge.  We start
          looking for edge intervals only after leaving the thresholded
          band.

=head2 numaUniformSampling

NUMA * numaUniformSampling ( NUMA *nas, l_int32 nsamp )

  numaUniformSampling()

      Input:  nas (input numa)
              nsamp (number of samples)
      Output: nad (resampled array), or null on error

  Notes:
      (1) This resamples the values in the array, using @nsamp
          equal divisions.

=head2 numaaFlattenToNuma

NUMA * numaaFlattenToNuma ( NUMAA *naa )

  numaaFlattenToNuma()

      Input:  numaa
      Return: numa, or null on error

  Notes:
      (1) This 'flattens' the Numaa to a Numa, by joining successively
          each Numa in the Numaa.
      (2) It doesn't make any assumptions about the location of the
          Numas in the Numaa array, unlike most Numaa functions.
      (3) It leaves the input Numaa unchanged.

=head2 numaaJoin

l_int32 numaaJoin ( NUMAA *naad, NUMAA *naas, l_int32 istart, l_int32 iend )

  numaaJoin()

      Input:  naad  (dest naa; add to this one)
              naas  (<optional> source naa; add from this one)
              istart  (starting index in nas)
              iend  (ending index in naas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (2) iend < 0 means 'read to the end'
      (3) if naas == NULL, this is a no-op

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
