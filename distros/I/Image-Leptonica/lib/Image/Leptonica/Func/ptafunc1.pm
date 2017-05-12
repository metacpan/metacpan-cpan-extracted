package Image::Leptonica::Func::ptafunc1;
$Image::Leptonica::Func::ptafunc1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ptafunc1

=head1 VERSION

version 0.04

=head1 C<ptafunc1.c>

   ptafunc1.c

      Pta and Ptaa rearrangements
           PTA      *ptaSubsample()
           l_int32   ptaJoin()
           l_int32   ptaaJoin()
           PTA      *ptaReverse()
           PTA      *ptaTranspose()
           PTA      *ptaCyclicPerm()
           PTA      *ptaSort()
           l_int32   ptaGetSortIndex()
           PTA      *ptaSortByIndex()
           PTA      *ptaRemoveDuplicates()
           PTAA     *ptaaSortByIndex()

      Geometric
           BOX      *ptaGetBoundingRegion()
           l_int32  *ptaGetRange()
           PTA      *ptaGetInsideBox()
           PTA      *pixFindCornerPixels()
           l_int32   ptaContainsPt()
           l_int32   ptaTestIntersection()
           PTA      *ptaTransform()
           l_int32   ptaPtInsidePolygon()
           l_float32 l_angleBetweenVectors()

      Least Squares Fit
           l_int32   ptaGetLinearLSF()
           l_int32   ptaGetQuadraticLSF()
           l_int32   ptaGetCubicLSF()
           l_int32   ptaGetQuarticLSF()
           l_int32   ptaNoisyLinearLSF()
           l_int32   ptaNoisyQuadraticLSF()
           l_int32   applyLinearFit()
           l_int32   applyQuadraticFit()
           l_int32   applyCubicFit()
           l_int32   applyQuarticFit()

      Interconversions with Pix
           l_int32   pixPlotAlongPta()
           PTA      *ptaGetPixelsFromPix()
           PIX      *pixGenerateFromPta()
           PTA      *ptaGetBoundaryPixels()
           PTAA     *ptaaGetBoundaryPixels()

      Display Pta and Ptaa
           PIX      *pixDisplayPta()
           PIX      *pixDisplayPtaaPattern()
           PIX      *pixDisplayPtaPattern()
           PTA      *ptaReplicatePattern()
           PIX      *pixDisplayPtaa()

=head1 FUNCTIONS

=head2 applyCubicFit

l_int32 applyCubicFit ( l_float32 a, l_float32 b, l_float32 c, l_float32 d, l_float32 x, l_float32 *py )

  applyCubicFit()

      Input: a, b, c, d (cubic fit coefficients)
             x
             &y (<return> y = a * x^3 + b * x^2  + c * x + d)
      Return: 0 if OK, 1 on error

=head2 applyLinearFit

l_int32 applyLinearFit ( l_float32 a, l_float32 b, l_float32 x, l_float32 *py )

  applyLinearFit()

      Input: a, b (linear fit coefficients)
             x
             &y (<return> y = a * x + b)
      Return: 0 if OK, 1 on error

=head2 applyQuadraticFit

l_int32 applyQuadraticFit ( l_float32 a, l_float32 b, l_float32 c, l_float32 x, l_float32 *py )

  applyQuadraticFit()

      Input: a, b, c (quadratic fit coefficients)
             x
             &y (<return> y = a * x^2 + b * x + c)
      Return: 0 if OK, 1 on error

=head2 applyQuarticFit

l_int32 applyQuarticFit ( l_float32 a, l_float32 b, l_float32 c, l_float32 d, l_float32 e, l_float32 x, l_float32 *py )

  applyQuarticFit()

      Input: a, b, c, d, e (quartic fit coefficients)
             x
             &y (<return> y = a * x^4 + b * x^3  + c * x^2 + d * x + e)
      Return: 0 if OK, 1 on error

=head2 l_angleBetweenVectors

l_float32 l_angleBetweenVectors ( l_float32 x1, l_float32 y1, l_float32 x2, l_float32 y2 )

  l_angleBetweenVectors()

      Input:  x1, y1 (end point of first vector)
              x2, y2 (end point of second vector)
      Return: angle (radians), or 0.0 on error

  Notes:
      (1) This gives the angle between two vectors, going between
          vector1 (x1,y1) and vector2 (x2,y2).  The angle is swept
          out from 1 --> 2.  If this is clockwise, the angle is
          positive, but the result is folded into the interval [-pi, pi].

=head2 pixDisplayPta

PIX * pixDisplayPta ( PIX *pixd, PIX *pixs, PTA *pta )

  pixDisplayPta()

      Input:  pixd (can be same as pixs or null; 32 bpp if in-place)
              pixs (1, 2, 4, 8, 16 or 32 bpp)
              pta (of path to be plotted)
      Return: pixd (32 bpp RGB version of pixs, with path in green).

  Notes:
      (1) To write on an existing pixs, pixs must be 32 bpp and
          call with pixd == pixs:
             pixDisplayPta(pixs, pixs, pta);
          To write to a new pix, use pixd == NULL and call:
             pixd = pixDisplayPta(NULL, pixs, pta);
      (2) On error, returns pixd to avoid losing pixs if called as
             pixs = pixDisplayPta(pixs, pixs, pta);

=head2 pixDisplayPtaPattern

PIX * pixDisplayPtaPattern ( PIX *pixd, PIX *pixs, PTA *pta, PIX *pixp, l_int32 cx, l_int32 cy, l_uint32 color )

  pixDisplayPtaPattern()

      Input:  pixd (can be same as pixs or null; 32 bpp if in-place)
              pixs (1, 2, 4, 8, 16 or 32 bpp)
              pta (giving locations at which the pattern is displayed)
              pixp (1 bpp pattern to be placed such that its reference
                    point co-locates with each point in pta)
              cx, cy (reference point in pattern)
              color (in 0xrrggbb00 format)
      Return: pixd (32 bpp RGB version of pixs).

  Notes:
      (1) To write on an existing pixs, pixs must be 32 bpp and
          call with pixd == pixs:
             pixDisplayPtaPattern(pixs, pixs, pta, ...);
          To write to a new pix, use pixd == NULL and call:
             pixd = pixDisplayPtaPattern(NULL, pixs, pta, ...);
      (2) On error, returns pixd to avoid losing pixs if called as
             pixs = pixDisplayPtaPattern(pixs, pixs, pta, ...);
      (3) A typical pattern to be used is a circle, generated with
             generatePtaFilledCircle()

=head2 pixDisplayPtaa

PIX * pixDisplayPtaa ( PIX *pixs, PTAA *ptaa )

  pixDisplayPtaa()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              ptaa (array of paths to be plotted)
      Return: pixd (32 bpp RGB version of pixs, with paths plotted
                    in different colors), or null on error

=head2 pixDisplayPtaaPattern

PIX * pixDisplayPtaaPattern ( PIX *pixd, PIX *pixs, PTAA *ptaa, PIX *pixp, l_int32 cx, l_int32 cy )

  pixDisplayPtaaPattern()

      Input:  pixd (32 bpp)
              pixs (1, 2, 4, 8, 16 or 32 bpp; 32 bpp if in place)
              ptaa (giving locations at which the pattern is displayed)
              pixp (1 bpp pattern to be placed such that its reference
                    point co-locates with each point in pta)
              cx, cy (reference point in pattern)
      Return: pixd (32 bpp RGB version of pixs).

  Notes:
      (1) To write on an existing pixs, pixs must be 32 bpp and
          call with pixd == pixs:
             pixDisplayPtaPattern(pixs, pixs, pta, ...);
          To write to a new pix, use pixd == NULL and call:
             pixd = pixDisplayPtaPattern(NULL, pixs, pta, ...);
      (2) Puts a random color on each pattern associated with a pta.
      (3) On error, returns pixd to avoid losing pixs if called as
             pixs = pixDisplayPtaPattern(pixs, pixs, pta, ...);
      (4) A typical pattern to be used is a circle, generated with
             generatePtaFilledCircle()

=head2 pixFindCornerPixels

PTA * pixFindCornerPixels ( PIX *pixs )

  pixFindCornerPixels()

      Input:  pixs (1 bpp)
      Return: pta, or null on error

  Notes:
      (1) Finds the 4 corner-most pixels, as defined by a search
          inward from each corner, using a 45 degree line.

=head2 pixGenerateFromPta

PIX * pixGenerateFromPta ( PTA *pta, l_int32 w, l_int32 h )

  pixGenerateFromPta()

      Input:  pta
              w, h (of pix)
      Return: pix (1 bpp), or null on error

  Notes:
      (1) Points are rounded to nearest ints.
      (2) Any points outside (w,h) are silently discarded.
      (3) Output 1 bpp pix has values 1 for each point in the pta.

=head2 pixPlotAlongPta

l_int32 pixPlotAlongPta ( PIX *pixs, PTA *pta, l_int32 outformat, const char *title )

  pixPlotAlongPta()

      Input: pixs (any depth)
             pta (set of points on which to plot)
             outformat (GPLOT_PNG, GPLOT_PS, GPLOT_EPS, GPLOT_X11,
                        GPLOT_LATEX)
             title (<optional> for plot; can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We remove any existing colormap and clip the pta to the input pixs.
      (2) This is a debugging function, and does not remove temporary
          plotting files that it generates.
      (3) If the image is RGB, three separate plots are generated.

=head2 ptaContainsPt

l_int32 ptaContainsPt ( PTA *pta, l_int32 x, l_int32 y )

  ptaContainsPt()

      Input:  pta
              x, y  (point)
      Return: 1 if contained, 0 otherwise or on error

=head2 ptaCyclicPerm

PTA * ptaCyclicPerm ( PTA *ptas, l_int32 xs, l_int32 ys )

  ptaCyclicPerm()

      Input:  ptas
              xs, ys  (start point; must be in ptas)
      Return: ptad (cyclic permutation, starting and ending at (xs, ys),
              or null on error

  Notes:
      (1) Check to insure that (a) ptas is a closed path where
          the first and last points are identical, and (b) the
          resulting pta also starts and ends on the same point
          (which in this case is (xs, ys).

=head2 ptaGetBoundaryPixels

PTA * ptaGetBoundaryPixels ( PIX *pixs, l_int32 type )

  ptaGetBoundaryPixels()

      Input:  pixs (1 bpp)
              type (L_BOUNDARY_FG, L_BOUNDARY_BG)
      Return: pta, or null on error

  Notes:
      (1) This generates a pta of either fg or bg boundary pixels.

=head2 ptaGetBoundingRegion

BOX * ptaGetBoundingRegion ( PTA *pta )

  ptaGetBoundingRegion()

      Input:  pta
      Return: box, or null on error

  Notes:
      (1) This is used when the pta represents a set of points in
          a two-dimensional image.  It returns the box of minimum
          size containing the pts in the pta.

=head2 ptaGetCubicLSF

l_int32 ptaGetCubicLSF ( PTA *pta, l_float32 *pa, l_float32 *pb, l_float32 *pc, l_float32 *pd, NUMA **pnafit )

  ptaGetCubicLSF()

      Input:  pta
              &a  (<optional return> coeff a of LSF: y = ax^3 + bx^2 + cx + d)
              &b  (<optional return> coeff b of LSF)
              &c  (<optional return> coeff c of LSF)
              &d  (<optional return> coeff d of LSF)
              &nafit (<optional return> numa of least square fit)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a cubic least square fit to the set of points
          in @pta.  That is, it finds coefficients a, b, c and d
          that minimize:

              sum (yi - a*xi*xi*xi -b*xi*xi -c*xi - d)^2
               i

          Differentiate this expression w/rt a, b, c and d, and solve
          the resulting four equations for these coefficients in
          terms of various sums over the input data (xi, yi).
          The four equations are in the form:
             f[0][0]a + f[0][1]b + f[0][2]c + f[0][3] = g[0]
             f[1][0]a + f[1][1]b + f[1][2]c + f[1][3] = g[1]
             f[2][0]a + f[2][1]b + f[2][2]c + f[2][3] = g[2]
             f[3][0]a + f[3][1]b + f[3][2]c + f[3][3] = g[3]
      (2) If @nafit is defined, this returns an array of fitted values,
          corresponding to the two implicit Numa arrays (nax and nay) in pta.
          Thus, just as you can plot the data in pta as nay vs. nax,
          you can plot the linear least square fit as nafit vs. nax.

=head2 ptaGetInsideBox

PTA * ptaGetInsideBox ( PTA *ptas, BOX *box )

  ptaGetInsideBox()

      Input:  ptas (input pts)
              box
      Return: ptad (of pts in ptas that are inside the box), or null on error

=head2 ptaGetLinearLSF

l_int32 ptaGetLinearLSF ( PTA *pta, l_float32 *pa, l_float32 *pb, NUMA **pnafit )

  ptaGetLinearLSF()

      Input:  pta
              &a  (<optional return> slope a of least square fit: y = ax + b)
              &b  (<optional return> intercept b of least square fit)
              &nafit (<optional return> numa of least square fit)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Either or both &a and &b must be input.  They determine the
          type of line that is fit.
      (2) If both &a and &b are defined, this returns a and b that minimize:

              sum (yi - axi -b)^2
               i

          The method is simple: differentiate this expression w/rt a and b,
          and solve the resulting two equations for a and b in terms of
          various sums over the input data (xi, yi).
      (3) We also allow two special cases, where either a = 0 or b = 0:
           (a) If &a is given and &b = null, find the linear LSF that
               goes through the origin (b = 0).
           (b) If &b is given and &a = null, find the linear LSF with
               zero slope (a = 0).
      (4) If @nafit is defined, this returns an array of fitted values,
          corresponding to the two implicit Numa arrays (nax and nay) in pta.
          Thus, just as you can plot the data in pta as nay vs. nax,
          you can plot the linear least square fit as nafit vs. nax.

=head2 ptaGetPixelsFromPix

PTA * ptaGetPixelsFromPix ( PIX *pixs, BOX *box )

  ptaGetPixelsFromPix()

      Input:  pixs (1 bpp)
              box (<optional> can be null)
      Return: pta, or null on error

  Notes:
      (1) Generates a pta of fg pixels in the pix, within the box.
          If box == NULL, it uses the entire pix.

=head2 ptaGetQuadraticLSF

l_int32 ptaGetQuadraticLSF ( PTA *pta, l_float32 *pa, l_float32 *pb, l_float32 *pc, NUMA **pnafit )

  ptaGetQuadraticLSF()

      Input:  pta
              &a  (<optional return> coeff a of LSF: y = ax^2 + bx + c)
              &b  (<optional return> coeff b of LSF: y = ax^2 + bx + c)
              &c  (<optional return> coeff c of LSF: y = ax^2 + bx + c)
              &nafit (<optional return> numa of least square fit)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a quadratic least square fit to the set of points
          in @pta.  That is, it finds coefficients a, b and c that minimize:

              sum (yi - a*xi*xi -b*xi -c)^2
               i

          The method is simple: differentiate this expression w/rt
          a, b and c, and solve the resulting three equations for these
          coefficients in terms of various sums over the input data (xi, yi).
          The three equations are in the form:
             f[0][0]a + f[0][1]b + f[0][2]c = g[0]
             f[1][0]a + f[1][1]b + f[1][2]c = g[1]
             f[2][0]a + f[2][1]b + f[2][2]c = g[2]
      (2) If @nafit is defined, this returns an array of fitted values,
          corresponding to the two implicit Numa arrays (nax and nay) in pta.
          Thus, just as you can plot the data in pta as nay vs. nax,
          you can plot the linear least square fit as nafit vs. nax.

=head2 ptaGetQuarticLSF

l_int32 ptaGetQuarticLSF ( PTA *pta, l_float32 *pa, l_float32 *pb, l_float32 *pc, l_float32 *pd, l_float32 *pe, NUMA **pnafit )

  ptaGetQuarticLSF()

      Input:  pta
              &a  (<optional return> coeff a of LSF:
                        y = ax^4 + bx^3 + cx^2 + dx + e)
              &b  (<optional return> coeff b of LSF)
              &c  (<optional return> coeff c of LSF)
              &d  (<optional return> coeff d of LSF)
              &e  (<optional return> coeff e of LSF)
              &nafit (<optional return> numa of least square fit)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a quartic least square fit to the set of points
          in @pta.  That is, it finds coefficients a, b, c, d and 3
          that minimize:

              sum (yi - a*xi*xi*xi*xi -b*xi*xi*xi -c*xi*xi - d*xi - e)^2
               i

          Differentiate this expression w/rt a, b, c, d and e, and solve
          the resulting five equations for these coefficients in
          terms of various sums over the input data (xi, yi).
          The five equations are in the form:
             f[0][0]a + f[0][1]b + f[0][2]c + f[0][3] + f[0][4] = g[0]
             f[1][0]a + f[1][1]b + f[1][2]c + f[1][3] + f[1][4] = g[1]
             f[2][0]a + f[2][1]b + f[2][2]c + f[2][3] + f[2][4] = g[2]
             f[3][0]a + f[3][1]b + f[3][2]c + f[3][3] + f[3][4] = g[3]
             f[4][0]a + f[4][1]b + f[4][2]c + f[4][3] + f[4][4] = g[4]
      (2) If @nafit is defined, this returns an array of fitted values,
          corresponding to the two implicit Numa arrays (nax and nay) in pta.
          Thus, just as you can plot the data in pta as nay vs. nax,
          you can plot the linear least square fit as nafit vs. nax.

=head2 ptaGetRange

l_int32 ptaGetRange ( PTA *pta, l_float32 *pminx, l_float32 *pmaxx, l_float32 *pminy, l_float32 *pmaxy )

  ptaGetRange()

      Input:  pta
              &minx (<optional return> min value of x)
              &maxx (<optional return> max value of x)
              &miny (<optional return> min value of y)
              &maxy (<optional return> max value of y)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We can use pts to represent pairs of floating values, that
          are not necessarily tied to a two-dimension region.  For
          example, the pts can represent a general function y(x).

=head2 ptaGetSortIndex

l_int32 ptaGetSortIndex ( PTA *ptas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex )

  ptaGetSortIndex()

      Input:  ptas
              sorttype (L_SORT_BY_X, L_SORT_BY_Y)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<return> index of sorted order into
                        original array)
      Return: 0 if OK, 1 on error

=head2 ptaJoin

l_int32 ptaJoin ( PTA *ptad, PTA *ptas, l_int32 istart, l_int32 iend )

  ptaJoin()

      Input:  ptad  (dest pta; add to this one)
              ptas  (source pta; add from this one)
              istart  (starting index in ptas)
              iend  (ending index in ptas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (2) iend < 0 means 'read to the end'
      (3) if ptas == NULL, this is a no-op

=head2 ptaNoisyLinearLSF

l_int32 ptaNoisyLinearLSF ( PTA *pta, l_float32 factor, PTA **pptad, l_float32 *pa, l_float32 *pb, l_float32 *pmederr, NUMA **pnafit )

  ptaNoisyLinearLSF()

      Input:  pta
              factor (reject outliers with error greater than this
                      number of medians; typically ~ 3)
              &ptad (<optional return> with outliers removed)
              &a  (<optional return> slope a of least square fit: y = ax + b)
              &b  (<optional return> intercept b of least square fit)
              &mederr (<optional return> median error)
              &nafit (<optional return> numa of least square fit to ptad)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a linear least square fit to the set of points
          in @pta.  It then evaluates the errors and removes points
          whose error is >= factor * median_error.  It then re-runs
          the linear LSF on the resulting points.
      (2) Either or both &a and &b must be input.  They determine the
          type of line that is fit.
      (3) The median error can give an indication of how good the fit
          is likely to be.

=head2 ptaNoisyQuadraticLSF

l_int32 ptaNoisyQuadraticLSF ( PTA *pta, l_float32 factor, PTA **pptad, l_float32 *pa, l_float32 *pb, l_float32 *pc, l_float32 *pmederr, NUMA **pnafit )

  ptaNoisyQuadraticLSF()

      Input:  pta
              factor (reject outliers with error greater than this
                      number of medians; typically ~ 3)
              &ptad (<optional return> with outliers removed)
              &a  (<optional return> coeff a of LSF: y = ax^2 + bx + c)
              &b  (<optional return> coeff b of LSF: y = ax^2 + bx + c)
              &c  (<optional return> coeff c of LSF: y = ax^2 + bx + c)
              &mederr (<optional return> median error)
              &nafit (<optional return> numa of least square fit to ptad)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a quadratic least square fit to the set of points
          in @pta.  It then evaluates the errors and removes points
          whose error is >= factor * median_error.  It then re-runs
          a quadratic LSF on the resulting points.

=head2 ptaPtInsidePolygon

l_int32 ptaPtInsidePolygon ( PTA *pta, l_float32 x, l_float32 y, l_int32 *pinside )

  ptaPtInsidePolygon()

      Input:  pta (vertices of a polygon)
              x, y (point to be tested)
              &inside (<return> 1 if inside; 0 if outside or on boundary)
      Return: 1 if OK, 0 on error

  The abs value of the sum of the angles subtended from a point by
  the sides of a polygon, when taken in order traversing the polygon,
  is 0 if the point is outside the polygon and 2*pi if inside.
  The sign will be positive if traversed cw and negative if ccw.

=head2 ptaRemoveDuplicates

PTA * ptaRemoveDuplicates ( PTA *ptas, l_uint32 factor )

  ptaRemoveDuplicates()

      Input:  ptas (assumed to be integer values)
              factor (should be larger than the largest point value;
                      use 0 for default)
      Return: ptad (with duplicates removed), or null on error

=head2 ptaReplicatePattern

PTA * ptaReplicatePattern ( PTA *ptas, PIX *pixp, PTA *ptap, l_int32 cx, l_int32 cy, l_int32 w, l_int32 h )

  ptaReplicatePattern()

      Input:  ptas ("sparse" input pta)
              pixp (<optional> 1 bpp pattern, to be replicated in output pta)
              ptap (<optional> set of pts, to be replicated in output pta)
              cx, cy (reference point in pattern)
              w, h (clipping sizes for output pta)
      Return: ptad (with all points of replicated pattern), or null on error

  Notes:
      (1) You can use either the image @pixp or the set of pts @ptap.
      (2) The pattern is placed with its reference point at each point
          in ptas, and all the fg pixels are colleced into ptad.
          For @pixp, this is equivalent to blitting pixp at each point
          in ptas, and then converting the resulting pix to a pta.

=head2 ptaReverse

PTA * ptaReverse ( PTA *ptas, l_int32 type )

  ptaReverse()

      Input:  ptas
              type  (0 for float values; 1 for integer values)
      Return: ptad (reversed pta), or null on error

=head2 ptaSort

PTA * ptaSort ( PTA *ptas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex )

  ptaSort()

      Input:  ptas
              sorttype (L_SORT_BY_X, L_SORT_BY_Y)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<optional return> index of sorted order into
                        original array)
      Return: ptad (sorted version of ptas), or null on error

=head2 ptaSortByIndex

PTA * ptaSortByIndex ( PTA *ptas, NUMA *naindex )

  ptaSortByIndex()

      Input:  ptas
              naindex (na that maps from the new pta to the input pta)
      Return: ptad (sorted), or null on  error

=head2 ptaSubsample

PTA * ptaSubsample ( PTA *ptas, l_int32 subfactor )

  ptaSubsample()

      Input:  ptas
              subfactor (subsample factor, >= 1)
      Return: ptad (evenly sampled pt values from ptas, or null on error

=head2 ptaTestIntersection

l_int32 ptaTestIntersection ( PTA *pta1, PTA *pta2 )

  ptaTestIntersection()

      Input:  pta1, pta2
      Return: bval which is 1 if they have any elements in common;
              0 otherwise or on error.

=head2 ptaTransform

PTA * ptaTransform ( PTA *ptas, l_int32 shiftx, l_int32 shifty, l_float32 scalex, l_float32 scaley )

  ptaTransform()

      Input:  pta
              shiftx, shifty
              scalex, scaley
      Return: pta, or null on error

  Notes:
      (1) Shift first, then scale.

=head2 ptaTranspose

PTA * ptaTranspose ( PTA *ptas )

  ptaTranspose()

      Input:  ptas
      Return: ptad (with x and y values swapped), or null on error

=head2 ptaaGetBoundaryPixels

PTAA * ptaaGetBoundaryPixels ( PIX *pixs, l_int32 type, l_int32 connectivity, BOXA **pboxa, PIXA **ppixa )

  ptaaGetBoundaryPixels()

      Input:  pixs (1 bpp)
              type (L_BOUNDARY_FG, L_BOUNDARY_BG)
              connectivity (4 or 8)
              &boxa (<optional return> bounding boxes of the c.c.)
              &pixa (<optional return> pixa of the c.c.)
      Return: ptaa, or null on error

  Notes:
      (1) This generates a ptaa of either fg or bg boundary pixels,
          where each pta has the boundary pixels for a connected
          component.
      (2) We can't simply find all the boundary pixels and then select
          those within the bounding box of each component, because
          bounding boxes can overlap.  It is necessary to extract and
          dilate or erode each component separately.  Note also that
          special handling is required for bg pixels when the
          component touches the pix boundary.

=head2 ptaaJoin

l_int32 ptaaJoin ( PTAA *ptaad, PTAA *ptaas, l_int32 istart, l_int32 iend )

  ptaaJoin()

      Input:  ptaad  (dest ptaa; add to this one)
              ptaas  (source ptaa; add from this one)
              istart  (starting index in ptaas)
              iend  (ending index in ptaas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (2) iend < 0 means 'read to the end'
      (3) if ptas == NULL, this is a no-op

=head2 ptaaSortByIndex

PTAA * ptaaSortByIndex ( PTAA *ptaas, NUMA *naindex )

  ptaaSortByIndex()

      Input:  ptaas
              naindex (na that maps from the new ptaa to the input ptaa)
      Return: ptaad (sorted), or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
