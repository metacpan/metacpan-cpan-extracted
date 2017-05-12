package Image::Leptonica::Func::pix5;
$Image::Leptonica::Func::pix5::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pix5

=head1 VERSION

version 0.04

=head1 C<pix5.c>

  pix5.c

    This file has these operations:

      (1) Measurement of 1 bpp image properties
      (2) Extract rectangular regions
      (3) Clip to foreground
      (4) Extract pixel averages, reversals and variance along lines
      (5) Rank row and column transforms

    Measurement of properties
           l_int32     pixaFindDimensions()
           l_int32     pixFindAreaPerimRatio()
           NUMA       *pixaFindPerimToAreaRatio()
           l_int32     pixFindPerimToAreaRatio()
           NUMA       *pixaFindPerimSizeRatio()
           l_int32     pixFindPerimSizeRatio()
           NUMA       *pixaFindAreaFraction()
           l_int32     pixFindAreaFraction()
           NUMA       *pixaFindAreaFractionMasked()
           l_int32     pixFindAreaFractionMasked()
           NUMA       *pixaFindWidthHeightRatio()
           NUMA       *pixaFindWidthHeightProduct()
           l_int32     pixFindOverlapFraction()
           BOXA       *pixFindRectangleComps()
           l_int32     pixConformsToRectangle()

    Extract rectangular region
           PIXA       *pixClipRectangles()
           PIX        *pixClipRectangle()
           PIX        *pixClipMasked()
           l_int32     pixCropToMatch()
           PIX        *pixCropToSize()
           PIX        *pixResizeToMatch()

    Clip to foreground
           PIX        *pixClipToForeground()
           l_int32     pixTestClipToForeground()
           l_int32     pixClipBoxToForeground()
           l_int32     pixScanForForeground()
           l_int32     pixClipBoxToEdges()
           l_int32     pixScanForEdge()

    Extract pixel averages and reversals along lines
           NUMA       *pixExtractOnLine()
           l_float32   pixAverageOnLine()
           NUMA       *pixAverageIntensityProfile()
           NUMA       *pixReversalProfile()

    Extract windowed variance along a line
           NUMA       *pixWindowedVarianceOnLine()

    Extract min/max of pixel values near lines
           l_int32     pixMinMaxNearLine()

    Rank row and column transforms
           PIX        *pixRankRowTransform()
           PIX        *pixRankColumnTransform()

=head1 FUNCTIONS

=head2 pixAverageIntensityProfile

NUMA * pixAverageIntensityProfile ( PIX *pixs, l_float32 fract, l_int32 dir, l_int32 first, l_int32 last, l_int32 factor1, l_int32 factor2 )

  pixAverageIntensityProfile()

      Input:  pixs (any depth; colormap OK)
              fract (fraction of image width or height to be used)
              dir (averaging direction: L_HORIZONTAL_LINE or L_VERTICAL_LINE)
              first, last (span of rows or columns to measure)
              factor1 (sampling along fast scan direction; >= 1)
              factor2 (sampling along slow scan direction; >= 1)
      Return: na (of reversal profile), or null on error.

  Notes:
      (1) If d != 1 bpp, colormaps are removed and the result
          is converted to 8 bpp.
      (2) If @dir == L_HORIZONTAL_LINE, the intensity is averaged
          along each horizontal raster line (sampled by @factor1),
          and the profile is the array of these averages in the
          vertical direction between @first and @last raster lines,
          and sampled by @factor2.
      (3) If @dir == L_VERTICAL_LINE, the intensity is averaged
          along each vertical line (sampled by @factor1),
          and the profile is the array of these averages in the
          horizontal direction between @first and @last columns,
          and sampled by @factor2.
      (4) The averages are measured over the central @fract of the image.
          Use @fract == 1.0 to average across the entire width or height.

=head2 pixAverageOnLine

l_float32 pixAverageOnLine ( PIX *pixs, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 factor )

  pixAverageOnLine()

      Input:  pixs (1 bpp or 8 bpp; no colormap)
              x1, y1 (starting pt for line)
              x2, y2 (end pt for line)
              factor (sampling; >= 1)
      Return: average of pixel values along line, or null on error.

  Notes:
      (1) The line must be either horizontal or vertical, so either
          y1 == y2 (horizontal) or x1 == x2 (vertical).
      (2) If horizontal, x1 must be <= x2.
          If vertical, y1 must be <= y2.
          characterize the intensity smoothness along a line.
      (3) Input end points are clipped to the pix.

=head2 pixClipBoxToEdges

l_int32 pixClipBoxToEdges ( PIX *pixs, BOX *boxs, l_int32 lowthresh, l_int32 highthresh, l_int32 maxwidth, l_int32 factor, PIX **ppixd, BOX **pboxd )

  pixClipBoxToEdges()

      Input:  pixs (1 bpp)
              boxs  (<optional> ; use full image if null)
              lowthresh (threshold to choose clipping location)
              highthresh (threshold required to find an edge)
              maxwidth (max allowed width between low and high thresh locs)
              factor (sampling factor along pixel counting direction)
              &pixd  (<optional return> clipped pix returned)
              &boxd  (<optional return> bounding box)
      Return: 0 if OK; 1 on error or if a fg edge is not found from
              all four sides.

  Notes:
      (1) At least one of {&pixd, &boxd} must be specified.
      (2) If there are no fg pixels, the returned ptrs are null.
      (3) This function attempts to locate rectangular "image" regions
          of high-density fg pixels, that have well-defined edges
          on the four sides.
      (4) Edges are searched for on each side, iterating in order
          from left, right, top and bottom.  As each new edge is
          found, the search box is resized to use that location.
          Once an edge is found, it is held.  If no more edges
          are found in one iteration, the search fails.
      (5) See pixScanForEdge() for usage of the thresholds and @maxwidth.
      (6) The thresholds must be at least 1, and the low threshold
          cannot be larger than the high threshold.
      (7) If the low and high thresholds are both 1, this is equivalent
          to pixClipBoxToForeground().

=head2 pixClipBoxToForeground

l_int32 pixClipBoxToForeground ( PIX *pixs, BOX *boxs, PIX **ppixd, BOX **pboxd )

  pixClipBoxToForeground()

      Input:  pixs (1 bpp)
              boxs  (<optional> ; use full image if null)
              &pixd  (<optional return> clipped pix returned)
              &boxd  (<optional return> bounding box)
      Return: 0 if OK; 1 on error or if there are no fg pixels

  Notes:
      (1) At least one of {&pixd, &boxd} must be specified.
      (2) If there are no fg pixels, the returned ptrs are null.
      (3) Do not use &pixs for the 3rd arg or &boxs for the 4th arg;
          this will leak memory.

=head2 pixClipMasked

PIX * pixClipMasked ( PIX *pixs, PIX *pixm, l_int32 x, l_int32 y, l_uint32 outval )

  pixClipMasked()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp; colormap ok)
              pixm  (clipping mask, 1 bpp)
              x, y (origin of clipping mask relative to pixs)
              outval (val to use for pixels that are outside the mask)
      Return: pixd, (clipped pix) or null on error or if pixm doesn't
              intersect pixs

  Notes:
      (1) If pixs has a colormap, it is preserved in pixd.
      (2) The depth of pixd is the same as that of pixs.
      (3) If the depth of pixs is 1, use @outval = 0 for white background
          and 1 for black; otherwise, use the max value for white
          and 0 for black.  If pixs has a colormap, the max value for
          @outval is 0xffffffff; otherwise, it is 2^d - 1.
      (4) When using 1 bpp pixs, this is a simple clip and
          blend operation.  For example, if both pix1 and pix2 are
          black text on white background, and you want to OR the
          fg on the two images, let pixm be the inverse of pix2.
          Then the operation takes all of pix1 that's in the bg of
          pix2, and for the remainder (which are the pixels
          corresponding to the fg of the pix2), paint them black
          (1) in pix1.  The function call looks like
             pixClipMasked(pix2, pixInvert(pix1, pix1), x, y, 1);

=head2 pixClipRectangle

PIX * pixClipRectangle ( PIX *pixs, BOX *box, BOX **pboxc )

  pixClipRectangle()

      Input:  pixs
              box  (requested clipping region; const)
              &boxc (<optional return> actual box of clipped region)
      Return: clipped pix, or null on error or if rectangle
              doesn't intersect pixs

  Notes:

  This should be simple, but there are choices to be made.
  The box is defined relative to the pix coordinates.  However,
  if the box is not contained within the pix, we have two choices:

      (1) clip the box to the pix
      (2) make a new pix equal to the full box dimensions,
          but let rasterop do the clipping and positioning
          of the src with respect to the dest

  Choice (2) immediately brings up the problem of what pixel values
  to use that were not taken from the src.  For example, on a grayscale
  image, do you want the pixels not taken from the src to be black
  or white or something else?  To implement choice 2, one needs to
  specify the color of these extra pixels.

  So we adopt (1), and clip the box first, if necessary,
  before making the dest pix and doing the rasterop.  But there
  is another issue to consider.  If you want to paste the
  clipped pix back into pixs, it must be properly aligned, and
  it is necessary to use the clipped box for alignment.
  Accordingly, this function has a third (optional) argument, which is
  the input box clipped to the src pix.

=head2 pixClipRectangles

PIXA * pixClipRectangles ( PIX *pixs, BOXA *boxa )

  pixClipRectangles()

      Input:  pixs
              boxa (requested clipping regions)
      Return: pixa (consisting of requested regions), or null on error

  Notes:
     (1) The returned pixa includes the actual regions clipped out from
         the input pixs.

=head2 pixClipToForeground

l_int32 pixClipToForeground ( PIX *pixs, PIX **ppixd, BOX **pbox )

  pixClipToForeground()

      Input:  pixs (1 bpp)
              &pixd  (<optional return> clipped pix returned)
              &box   (<optional return> bounding box)
      Return: 0 if OK; 1 on error or if there are no fg pixels

  Notes:
      (1) At least one of {&pixd, &box} must be specified.
      (2) If there are no fg pixels, the returned ptrs are null.

=head2 pixConformsToRectangle

l_int32 pixConformsToRectangle ( PIX *pixs, BOX *box, l_int32 dist, l_int32 *pconforms )

  pixConformsToRectangle()

      Input:  pixs (1 bpp)
              box (<optional> if null, use the entire pixs)
              dist (max distance allowed between bounding box and nearest
                    foreground pixel within it)
              &conforms (<return> 0 (false) if not conforming;
                        1 (true) if conforming)
      Return: 0 if OK, 1 on error

  Notes:
      (1) There are several ways to test if a connected component has
          an essentially rectangular boundary, such as:
           a. Fraction of fill into the bounding box
           b. Max-min distance of fg pixel from periphery of bounding box
           c. Max depth of bg intrusions into component within bounding box
          The weakness of (a) is that it is highly sensitive to holes
          within the c.c.  The weakness of (b) is that it can have
          arbitrarily large intrusions into the c.c.  Method (c) tests
          the integrity of the outer boundary of the c.c., with respect
          to the enclosing bounding box, so we use it.
      (2) This tests if the connected component within the box conforms
          to the box at all points on the periphery within @dist.
          Inside, at a distance from the box boundary that is greater
          than @dist, we don't care about the pixels in the c.c.
      (3) We can think of the conforming condition as follows:
          No pixel inside a distance @dist from the boundary
          can connect to the boundary through a path through the bg.
          To implement this, we need to do a flood fill.  We can go
          either from inside toward the boundary, or the other direction.
          It's easiest to fill from the boundary, and then verify that
          there are no filled pixels farther than @dist from the boundary.

=head2 pixCropToMatch

l_int32 pixCropToMatch ( PIX *pixs1, PIX *pixs2, PIX **ppixd1, PIX **ppixd2 )

  pixCropToMatch()

      Input:  pixs1 (any depth, colormap OK)
              pixs2 (any depth, colormap OK)
              &pixd1 (<return> may be a clone)
              &pixd2 (<return> may be a clone)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This resizes pixs1 and/or pixs2 by cropping at the right
          and bottom, so that they're the same size.
      (2) If a pix doesn't need to be cropped, a clone is returned.
      (3) Note: the images are implicitly aligned to the UL corner.

=head2 pixCropToSize

PIX * pixCropToSize ( PIX *pixs, l_int32 w, l_int32 h )

  pixCropToSize()

      Input:  pixs (any depth, colormap OK)
              w, h (max dimensions of cropped image)
      Return: pixd (cropped if necessary) or null on error.

  Notes:
      (1) If either w or h is smaller than the corresponding dimension
          of pixs, this returns a cropped image; otherwise it returns
          a clone of pixs.

=head2 pixExtractOnLine

NUMA * pixExtractOnLine ( PIX *pixs, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 factor )

  pixExtractOnLine()

      Input:  pixs (1 bpp or 8 bpp; no colormap)
              x1, y1 (one end point for line)
              x2, y2 (another end pt for line)
              factor (sampling; >= 1)
      Return: na (of pixel values along line), or null on error.

  Notes:
      (1) Input end points are clipped to the pix.
      (2) If the line is either horizontal, or closer to horizontal
          than to vertical, the points will be extracted from left
          to right in the pix.  Likewise, if the line is vertical,
          or closer to vertical than to horizontal, the points will
          be extracted from top to bottom.
      (3) Can be used with numaCountReverals(), for example, to
          characterize the intensity smoothness along a line.

=head2 pixFindAreaFraction

l_int32 pixFindAreaFraction ( PIX *pixs, l_int32 *tab, l_float32 *pfract )

  pixFindAreaFraction()

      Input:  pixs (1 bpp)
              tab (<optional> pixel sum table, can be NULL)
              &fract (<return> fg area/size ratio)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This finds the ratio of the number of fg pixels to the
          size of the pix (w * h).  It is typically used for a
          single connected component.

=head2 pixFindAreaFractionMasked

l_int32 pixFindAreaFractionMasked ( PIX *pixs, BOX *box, PIX *pixm, l_int32 *tab, l_float32 *pfract )

  pixFindAreaFractionMasked()

      Input:  pixs (1 bpp, typically a single component)
              box (<optional> for pixs relative to pixm)
              pixm (1 bpp mask, typically over the entire image from
                    which the component pixs was extracted)
              tab (<optional> pixel sum table, can be NULL)
              &fract (<return> fg area/size ratio)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This finds the ratio of the number of masked fg pixels
          in pixs to the total number of fg pixels in pixs.
          It is typically used for a single connected component.
          If there are no fg pixels, this returns a ratio of 0.0.
      (2) The box gives the location of the pix relative to that
          of the UL corner of the mask.  Therefore, the rasterop
          is performed with the pix translated to its location
          (x, y) in the mask before ANDing.
          If box == NULL, the UL corners of pixs and pixm are aligned.

=head2 pixFindAreaPerimRatio

l_int32 pixFindAreaPerimRatio ( PIX *pixs, l_int32 *tab, l_float32 *pfract )

  pixFindAreaPerimRatio()

      Input:  pixs (1 bpp)
              tab (<optional> pixel sum table, can be NULL)
              &fract (<return> area/perimeter ratio)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The area is the number of fg pixels that are not on the
          boundary (i.e., are not 8-connected to a bg pixel), and the
          perimeter is the number of fg boundary pixels.  Returns
          0.0 if there are no fg pixels.
      (2) This function is retained because clients are using it.

=head2 pixFindOverlapFraction

l_int32 pixFindOverlapFraction ( PIX *pixs1, PIX *pixs2, l_int32 x2, l_int32 y2, l_int32 *tab, l_float32 *pratio, l_int32 *pnoverlap )

  pixFindOverlapFraction()

      Input:  pixs1, pixs2 (1 bpp)
              x2, y2 (location in pixs1 of UL corner of pixs2)
              tab (<optional> pixel sum table, can be null)
              &ratio (<return> ratio fg intersection to fg union)
              &noverlap (<optional return> number of overlapping pixels)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The UL corner of pixs2 is placed at (x2, y2) in pixs1.
      (2) This measure is similar to the correlation.

=head2 pixFindPerimSizeRatio

l_int32 pixFindPerimSizeRatio ( PIX *pixs, l_int32 *tab, l_float32 *pratio )

  pixFindPerimSizeRatio()

      Input:  pixs (1 bpp)
              tab (<optional> pixel sum table, can be NULL)
              &ratio (<return> perimeter/size ratio)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We take the 'size' as twice the sum of the width and
          height of pixs, and the perimeter is the number of fg
          boundary pixels.  We use the fg pixels of the boundary
          because the pix may be clipped to the boundary, so an
          erosion is required to count all boundary pixels.
      (2) This has a large value for dendritic, fractal-like components
          with highly irregular boundaries.
      (3) This is typically used for a single connected component.
          It has a value of about 1.0 for rectangular components with
          relatively smooth boundaries.

=head2 pixFindPerimToAreaRatio

l_int32 pixFindPerimToAreaRatio ( PIX *pixs, l_int32 *tab, l_float32 *pfract )

  pixFindPerimToAreaRatio()

      Input:  pixs (1 bpp)
              tab (<optional> pixel sum table, can be NULL)
              &fract (<return> perimeter/area ratio)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The perimeter is the number of fg boundary pixels, and the
          area is the number of fg pixels.  This returns 0.0 if
          there are no fg pixels.
      (2) Unlike pixFindAreaPerimRatio(), this uses the full set of
          fg pixels for the area, and the ratio is taken in the opposite
          order.
      (3) This is typically used for a single connected component.
          This always has a value <= 1.0, and if the average distance
          of a fg pixel from the nearest bg pixel is d, this has
          a value ~1/d.

=head2 pixFindRectangleComps

BOXA * pixFindRectangleComps ( PIX *pixs, l_int32 dist, l_int32 minw, l_int32 minh )

  pixFindRectangleComps()

      Input:  pixs (1 bpp)
              dist (max distance allowed between bounding box and nearest
                    foreground pixel within it)
              minw, minh (minimum size in each direction as a requirement
                          for a conforming rectangle)
      Return: boxa (of components that conform), or null on error

  Notes:
      (1) This applies the function pixConformsToRectangle() to
          each 8-c.c. in pixs, and returns a boxa containing the
          regions of all components that are conforming.
      (2) Conforming components must satisfy both the size constraint
          given by @minsize and the slop in conforming to a rectangle
          determined by @dist.

=head2 pixMinMaxNearLine

l_int32 pixMinMaxNearLine ( PIX *pixs, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 dist, l_int32 direction, NUMA **pnamin, NUMA **pnamax, l_float32 *pminave, l_float32 *pmaxave )

  pixMinMaxNearLine()

      Input:  pixs (8 bpp; no colormap)
              x1, y1 (starting pt for line)
              x2, y2 (end pt for line)
              dist (distance to search from line in each direction)
              direction (L_SCAN_NEGATIVE, L_SCAN_POSITIVE, L_SCAN_BOTH)
              &namin (<optional return> minimum values)
              &namax (<optional return> maximum values)
              &minave (<optional return> average of minimum values)
              &maxave (<optional return> average of maximum values)
      Return: 0 if OK; 1 on error or if there are no sampled points
              within the image.

  Notes:
      (1) If the line is more horizontal than vertical, the values
          are computed for [x1, x2], and the pixels are taken
          below and/or above the local y-value.  Otherwise, the
          values are computed for [y1, y2] and the pixels are taken
          to the left and/or right of the local x value.
      (2) @direction specifies which side (or both sides) of the
          line are scanned for min and max values.
      (3) There are two ways to tell if the returned values of min
          and max averages are valid: the returned values cannot be
          negative and the function must return 0.
      (4) All accessed pixels are clipped to the pix.

=head2 pixRankColumnTransform

PIX * pixRankColumnTransform ( PIX *pixs )

  pixRankColumnTransform()

      Input:  pixs (8 bpp; no colormap)
      Return: pixd (with pixels sorted in each column, from
                    min to max value)

 Notes:
     (1) The time is O(n) in the number of pixels and runs about
         50 Mpixels/sec on a 3 GHz machine.

=head2 pixRankRowTransform

PIX * pixRankRowTransform ( PIX *pixs )

  pixRankRowTransform()

      Input:  pixs (8 bpp; no colormap)
      Return: pixd (with pixels sorted in each row, from
                    min to max value)

 Notes:
     (1) The time is O(n) in the number of pixels and runs about
         100 Mpixels/sec on a 3 GHz machine.

=head2 pixResizeToMatch

PIX * pixResizeToMatch ( PIX *pixs, PIX *pixt, l_int32 w, l_int32 h )

  pixResizeToMatch()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp; colormap ok)
              pixt  (can be null; we use only the size)
              w, h (ignored if pixt is defined)
      Return: pixd (resized to match) or null on error

  Notes:
      (1) This resizes pixs to make pixd, without scaling, by either
          cropping or extending separately in both width and height.
          Extension is done by replicating the last row or column.
          This is useful in a situation where, due to scaling
          operations, two images that are expected to be the
          same size can differ slightly in each dimension.
      (2) You can use either an existing pixt or specify
          both @w and @h.  If pixt is defined, the values
          in @w and @h are ignored.
      (3) If pixt is larger than pixs (or if w and/or d is larger
          than the dimension of pixs, replicate the outer row and
          column of pixels in pixs into pixd.

=head2 pixReversalProfile

NUMA * pixReversalProfile ( PIX *pixs, l_float32 fract, l_int32 dir, l_int32 first, l_int32 last, l_int32 minreversal, l_int32 factor1, l_int32 factor2 )

  pixReversalProfile()

      Input:  pixs (any depth; colormap OK)
              fract (fraction of image width or height to be used)
              dir (profile direction: L_HORIZONTAL_LINE or L_VERTICAL_LINE)
              first, last (span of rows or columns to measure)
              minreversal (minimum change in intensity to trigger a reversal)
              factor1 (sampling along raster line (fast scan); >= 1)
              factor2 (sampling of raster lines (slow scan); >= 1)
      Return: na (of reversal profile), or null on error.

  Notes:
      (1) If d != 1 bpp, colormaps are removed and the result
          is converted to 8 bpp.
      (2) If @dir == L_HORIZONTAL_LINE, the the reversals are counted
          along each horizontal raster line (sampled by @factor1),
          and the profile is the array of these sums in the
          vertical direction between @first and @last raster lines,
          and sampled by @factor2.
      (3) If @dir == L_VERTICAL_LINE, the the reversals are counted
          along each vertical column (sampled by @factor1),
          and the profile is the array of these sums in the
          horizontal direction between @first and @last columns,
          and sampled by @factor2.
      (4) For each row or column, the reversals are summed over the
          central @fract of the image.  Use @fract == 1.0 to sum
          across the entire width (of row) or height (of column).
      (5) @minreversal is the relative change in intensity that is
          required to resolve peaks and valleys.  A typical number for
          locating text in 8 bpp might be 50.  For 1 bpp, minreversal
          must be 1.
      (6) The reversal profile is simply the number of reversals
          in a row or column, vs the row or column index.

=head2 pixScanForEdge

l_int32 pixScanForEdge ( PIX *pixs, BOX *box, l_int32 lowthresh, l_int32 highthresh, l_int32 maxwidth, l_int32 factor, l_int32 scanflag, l_int32 *ploc )

  pixScanForEdge()

      Input:  pixs (1 bpp)
              box  (<optional> within which the search is conducted)
              lowthresh (threshold to choose clipping location)
              highthresh (threshold required to find an edge)
              maxwidth (max allowed width between low and high thresh locs)
              factor (sampling factor along pixel counting direction)
              scanflag (direction of scan; e.g., L_FROM_LEFT)
              &loc (location in scan direction of first black pixel)
      Return: 0 if OK; 1 on error or if the edge is not found

  Notes:
      (1) If there are no fg pixels, the position is set to 0.
          Caller must check the return value!
      (2) Use @box == NULL to scan from edge of pixs
      (3) As the scan progresses, the location where the sum of
          pixels equals or excees @lowthresh is noted (loc).  The
          scan is stopped when the sum of pixels equals or exceeds
          @highthresh.  If the scan distance between loc and that
          point does not exceed @maxwidth, an edge is found and
          its position is taken to be loc.  @maxwidth implicitly
          sets a minimum on the required gradient of the edge.
      (4) The thresholds must be at least 1, and the low threshold
          cannot be larger than the high threshold.

=head2 pixScanForForeground

l_int32 pixScanForForeground ( PIX *pixs, BOX *box, l_int32 scanflag, l_int32 *ploc )

  pixScanForForeground()

      Input:  pixs (1 bpp)
              box  (<optional> within which the search is conducted)
              scanflag (direction of scan; e.g., L_FROM_LEFT)
              &loc (location in scan direction of first black pixel)
      Return: 0 if OK; 1 on error or if no fg pixels are found

  Notes:
      (1) If there are no fg pixels, the position is set to 0.
          Caller must check the return value!
      (2) Use @box == NULL to scan from edge of pixs

=head2 pixTestClipToForeground

l_int32 pixTestClipToForeground ( PIX *pixs, l_int32 *pcanclip )

  pixTestClipToForeground()

      Input:  pixs (1 bpp)
              &canclip (<return> 1 if fg does not extend to all four edges)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is a lightweight test to determine if a 1 bpp image
          can be further cropped without loss of fg pixels.
          If it cannot, canclip is set to 0.

=head2 pixWindowedVarianceOnLine

l_int32 pixWindowedVarianceOnLine ( PIX *pixs, l_int32 dir, l_int32 loc, l_int32 c1, l_int32 c2, l_int32 size, NUMA **pnad )

  pixWindowedVarianceOnLine()

      Input:  pixs (8 bpp; no colormap)
              dir (L_HORIZONTAL_LINE or L_VERTICAL_LINE)
              loc (location of the constant coordinate for the line)
              c1, c2 (end point coordinates for the line)
              size (window size; must be > 1)
              &nad (<return> windowed square root of variance)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The returned variance array traverses the line starting
          from the smallest coordinate, min(c1,c2).
      (2) Line end points are clipped to pixs.
      (3) The reference point for the variance calculation is the center of
          the window.  Therefore, the numa start parameter from
          pixExtractOnLine() is incremented by @size/2,
          to align the variance values with the pixel coordinate.
      (4) The square root of the variance is the RMS deviation from the mean.

=head2 pixaFindAreaFraction

NUMA * pixaFindAreaFraction ( PIXA *pixa )

  pixaFindAreaFraction()

      Input:  pixa (of 1 bpp pix)
      Return: na (of area fractions for each pix), or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components.

=head2 pixaFindAreaFractionMasked

NUMA * pixaFindAreaFractionMasked ( PIXA *pixa, PIX *pixm, l_int32 debug )

  pixaFindAreaFractionMasked()

      Input:  pixa (of 1 bpp pix)
              pixm (mask image)
              debug (1 for output, 0 to suppress)
      Return: na (of ratio masked/total fractions for each pix),
                  or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components, which has an associated
          boxa giving the location of the components relative
          to the mask origin.
      (2) The debug flag displays in green and red the masked and
          unmasked parts of the image from which pixa was derived.

=head2 pixaFindDimensions

l_int32 pixaFindDimensions ( PIXA *pixa, NUMA **pnaw, NUMA **pnah )

  pixaFindDimensions()

      Input:  pixa
              &naw (<optional return> numa of pix widths)
              &nah (<optional return> numa of pix heights)
      Return: 0 if OK, 1 on error

=head2 pixaFindPerimSizeRatio

NUMA * pixaFindPerimSizeRatio ( PIXA *pixa )

  pixaFindPerimSizeRatio()

      Input:  pixa (of 1 bpp pix)
      Return: na (of fg perimeter/(2*(w+h)) ratio for each pix),
                  or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components.
      (2) This has a minimum value for a circle of pi/4; a value for
          a rectangle component of approx. 1.0; and a value much larger
          than 1.0 for a component with a highly irregular boundary.

=head2 pixaFindPerimToAreaRatio

NUMA * pixaFindPerimToAreaRatio ( PIXA *pixa )

  pixaFindPerimToAreaRatio()

      Input:  pixa (of 1 bpp pix)
      Return: na (of perimeter/arear ratio for each pix), or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components.

=head2 pixaFindWidthHeightProduct

NUMA * pixaFindWidthHeightProduct ( PIXA *pixa )

  pixaFindWidthHeightProduct()

      Input:  pixa (of 1 bpp pix)
      Return: na (of width*height products for each pix), or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components.

=head2 pixaFindWidthHeightRatio

NUMA * pixaFindWidthHeightRatio ( PIXA *pixa )

  pixaFindWidthHeightRatio()

      Input:  pixa (of 1 bpp pix)
      Return: na (of width/height ratios for each pix), or null on error

  Notes:
      (1) This is typically used for a pixa consisting of
          1 bpp connected components.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
