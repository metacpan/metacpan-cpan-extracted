package Image::Leptonica::Func::pix3;
$Image::Leptonica::Func::pix3::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pix3

=head1 VERSION

version 0.04

=head1 C<pix3.c>

  pix3.c

    This file has these operations:

      (1) Mask-directed operations
      (2) Full-image bit-logical operations
      (3) Foreground pixel counting operations on 1 bpp images
      (4) Average and variance of pixel values
      (5) Mirrored tiling of a smaller image


    Masked operations
           l_int32     pixSetMasked()
           l_int32     pixSetMaskedGeneral()
           l_int32     pixCombineMasked()
           l_int32     pixCombineMaskedGeneral()
           l_int32     pixPaintThroughMask()
           PIX        *pixPaintSelfThroughMask()
           PIX        *pixMakeMaskFromLUT()
           PIX        *pixSetUnderTransparency()

    One and two-image boolean operations on arbitrary depth images
           PIX        *pixInvert()
           PIX        *pixOr()
           PIX        *pixAnd()
           PIX        *pixXor()
           PIX        *pixSubtract()

    Foreground pixel counting in 1 bpp images
           l_int32     pixZero()
           l_int32     pixForegroundFraction()
           NUMA       *pixaCountPixels()
           l_int32     pixCountPixels()
           NUMA       *pixCountByRow()
           NUMA       *pixCountByColumn()
           NUMA       *pixCountPixelsByRow()
           NUMA       *pixCountPixelsByColumn()
           l_int32     pixCountPixelsInRow()
           NUMA       *pixGetMomentByColumn()
           l_int32     pixThresholdPixelSum()
           l_int32    *makePixelSumTab8()
           l_int32    *makePixelCentroidTab8()

    Average of pixel values in gray images
           NUMA       *pixAverageByRow()
           NUMA       *pixAverageByColumn()
           l_int32     pixAverageInRect()

    Variance of pixel values in gray images
           NUMA       *pixVarianceByRow()
           NUMA       *pixVarianceByColumn()
           l_int32     pixVarianceInRect()

    Average of absolute value of pixel differences in gray images
           NUMA       *pixAbsDiffByRow()
           NUMA       *pixAbsDiffByColumn()
           l_int32     pixAbsDiffInRect()
           l_int32     pixAbsDiffOnLine()

    Count of pixels with specific value            *
           l_int32     pixCountArbInRect()

    Mirrored tiling
           PIX        *pixMirroredTiling()

    Static helper function
           static l_int32  findTilePatchCenter()

=head1 FUNCTIONS

=head2 makePixelCentroidTab8

l_int32 * makePixelCentroidTab8 ( void )

  makePixelCentroidTab8()

      Input:  void
      Return: table of 256 l_int32, or null on error

  Notes:
      (1) This table of integers gives the centroid weight of the 1 bits
          in the 8 bit index.  In other words, if sumtab is obtained by
          makePixelSumTab8, and centroidtab is obtained by
          makePixelCentroidTab8, then, for 1 <= i <= 255,
          centroidtab[i] / (float)sumtab[i]
          is the centroid of the 1 bits in the 8-bit index i, where the
          MSB is considered to have position 0 and the LSB is considered
          to have position 7.

=head2 makePixelSumTab8

l_int32 * makePixelSumTab8 ( void )

  makePixelSumTab8()

      Input:  void
      Return: table of 256 l_int32, or null on error

  Notes:
      (1) This table of integers gives the number of 1 bits
          in the 8 bit index.

=head2 pixAbsDiffByColumn

NUMA * pixAbsDiffByColumn ( PIX *pix, BOX *box )

  pixAbsDiffByColumn()

      Input:  pix (8 bpp; no colormap)
              box (<optional> clipping box for region; can be null)
      Return: na of abs val pixel difference averages by column,
              or null on error

  Notes:
      (1) This is an average over differences of adjacent pixels along
          each column.
      (2) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.

=head2 pixAbsDiffByRow

NUMA * pixAbsDiffByRow ( PIX *pix, BOX *box )

  pixAbsDiffByRow()

      Input:  pix (8 bpp; no colormap)
              box (<optional> clipping box for region; can be null)
      Return: na of abs val pixel difference averages by row, or null on error

  Notes:
      (1) This is an average over differences of adjacent pixels along
          each row.
      (2) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.

=head2 pixAbsDiffInRect

l_int32 pixAbsDiffInRect ( PIX *pix, BOX *box, l_int32 dir, l_float32 *pabsdiff )

  pixAbsDiffInRect()

      Input:  pix (8 bpp; not cmapped)
              box (<optional> if null, use entire image)
              dir (differences along L_HORIZONTAL_LINE or L_VERTICAL_LINE)
              &absdiff (<return> average of abs diff pixel values in region)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This gives the average over the abs val of differences of
          adjacent pixels values, along either each
             row:     dir == L_HORIZONTAL_LINE
             column:  dir == L_VERTICAL_LINE

=head2 pixAbsDiffOnLine

l_int32 pixAbsDiffOnLine ( PIX *pix, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_float32 *pabsdiff )

  pixAbsDiffOnLine()

      Input:  pix (8 bpp; not cmapped)
              x1, y1 (first point; x1 <= x2, y1 <= y2)
              x2, y2 (first point)
              &absdiff (<return> average of abs diff pixel values on line)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This gives the average over the abs val of differences of
          adjacent pixels values, along a line that is either horizontal
          or vertical.
      (2) If horizontal, require x1 < x2; if vertical, require y1 < y2.

=head2 pixAnd

PIX * pixAnd ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixAnd()

      Input:  pixd  (<optional>; this can be null, equal to pixs1,
                     different from pixs1)
              pixs1 (can be == pixd)
              pixs2 (must be != pixd)
      Return: pixd always

  Notes:
      (1) This gives the intersection of two images with equal depth,
          aligning them to the the UL corner.  pixs1 and pixs2
          need not have the same width and height.
      (2) There are 3 cases:
            (a) pixd == null,   (src1 & src2) --> new pixd
            (b) pixd == pixs1,  (src1 & src2) --> src1  (in-place)
            (c) pixd != pixs1,  (src1 & src2) --> input pixd
      (3) For clarity, if the case is known, use these patterns:
            (a) pixd = pixAnd(NULL, pixs1, pixs2);
            (b) pixAnd(pixs1, pixs1, pixs2);
            (c) pixAnd(pixd, pixs1, pixs2);
      (4) The size of the result is determined by pixs1.
      (5) The depths of pixs1 and pixs2 must be equal.
      (6) Note carefully that the order of pixs1 and pixs2 only matters
          for the in-place case.  For in-place, you must have
          pixd == pixs1.  Setting pixd == pixs2 gives an incorrect
          result: the copy puts pixs1 image data in pixs2, and
          the rasterop is then between pixs2 and pixs2 (a no-op).

=head2 pixAverageByColumn

NUMA * pixAverageByColumn ( PIX *pix, BOX *box, l_int32 type )

  pixAverageByColumn()

      Input:  pix (8 or 16 bpp; no colormap)
              box (<optional> clipping box for sum; can be null)
              type (L_WHITE_IS_MAX, L_BLACK_IS_MAX)
      Return: na of pixel averages by column, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.
      (2) If type == L_BLACK_IS_MAX, black pixels get the maximum
          value (0xff for 8 bpp, 0xffff for 16 bpp) and white get 0.

=head2 pixAverageByRow

NUMA * pixAverageByRow ( PIX *pix, BOX *box, l_int32 type )

  pixAverageByRow()

      Input:  pix (8 or 16 bpp; no colormap)
              box (<optional> clipping box for sum; can be null)
              type (L_WHITE_IS_MAX, L_BLACK_IS_MAX)
      Return: na of pixel averages by row, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.
      (2) If type == L_BLACK_IS_MAX, black pixels get the maximum
          value (0xff for 8 bpp, 0xffff for 16 bpp) and white get 0.

=head2 pixAverageInRect

l_int32 pixAverageInRect ( PIX *pix, BOX *box, l_float32 *pave )

  pixAverageInRect()

      Input:  pix (1, 2, 4, 8 bpp; not cmapped)
              box (<optional> if null, use entire image)
              &ave (<return> average of pixel values in region)
      Return: 0 if OK; 1 on error

=head2 pixCombineMasked

l_int32 pixCombineMasked ( PIX *pixd, PIX *pixs, PIX *pixm )

  pixCombineMasked()

      Input:  pixd (1 bpp, 8 bpp gray or 32 bpp rgb; no cmap)
              pixs (1 bpp, 8 bpp gray or 32 bpp rgb; no cmap)
              pixm (<optional> 1 bpp mask; no operation if NULL)
      Return: 0 if OK; 1 on error

  Notes:
      (1) In-place operation; pixd is changed.
      (2) This sets each pixel in pixd that co-locates with an ON
          pixel in pixm to the corresponding value of pixs.
      (3) pixs and pixd must be the same depth and not colormapped.
      (4) All three input pix are aligned at the UL corner, and the
          operation is clipped to the intersection of all three images.
      (5) If pixm == NULL, it's a no-op.
      (6) Implementation: see notes in pixCombineMaskedGeneral().
          For 8 bpp selective masking, you might guess that it
          would be faster to generate an 8 bpp version of pixm,
          using pixConvert1To8(pixm, 0, 255), and then use a
          general combine operation
               d = (d & ~m) | (s & m)
          on a word-by-word basis.  Not always.  The word-by-word
          combine takes a time that is independent of the mask data.
          If the mask is relatively sparse, the byte-check method
          is actually faster!

=head2 pixCombineMaskedGeneral

l_int32 pixCombineMaskedGeneral ( PIX *pixd, PIX *pixs, PIX *pixm, l_int32 x, l_int32 y )

  pixCombineMaskedGeneral()

      Input:  pixd (1 bpp, 8 bpp gray or 32 bpp rgb)
              pixs (1 bpp, 8 bpp gray or 32 bpp rgb)
              pixm (<optional> 1 bpp mask)
              x, y (origin of pixs and pixm relative to pixd; can be negative)
      Return: 0 if OK; 1 on error

  Notes:
      (1) In-place operation; pixd is changed.
      (2) This is a generalized version of pixCombinedMasked(), where
          the source and mask can be placed at the same (arbitrary)
          location relative to pixd.
      (3) pixs and pixd must be the same depth and not colormapped.
      (4) The UL corners of both pixs and pixm are aligned with
          the point (x, y) of pixd, and the operation is clipped to
          the intersection of all three images.
      (5) If pixm == NULL, it's a no-op.
      (6) Implementation.  There are two ways to do these.  In the first,
          we use rasterop, ORing the part of pixs under the mask
          with pixd (which has been appropriately cleared there first).
          In the second, the mask is used one pixel at a time to
          selectively replace pixels of pixd with those of pixs.
          Here, we use rasterop for 1 bpp and pixel-wise replacement
          for 8 and 32 bpp.  To use rasterop for 8 bpp, for example,
          we must first generate an 8 bpp version of the mask.
          The code is simple:

             Pix *pixm8 = pixConvert1To8(NULL, pixm, 0, 255);
             Pix *pixt = pixAnd(NULL, pixs, pixm8);
             pixRasterop(pixd, x, y, wmin, hmin, PIX_DST & PIX_NOT(PIX_SRC),
                         pixm8, 0, 0);
             pixRasterop(pixd, x, y, wmin, hmin, PIX_SRC | PIX_DST,
                         pixt, 0, 0);
             pixDestroy(&pixt);
             pixDestroy(&pixm8);

=head2 pixCountArbInRect

l_int32 pixCountArbInRect ( PIX *pixs, BOX *box, l_int32 val, l_int32 factor, l_int32 *pcount )

  pixCountArbInRect()

      Input:  pixs (8 bpp, or colormapped)
              box (<optional>) over which count is made;
                   use entire image null)
              val (pixel value to count)
              factor (subsampling factor; integer >= 1)
              &count (<return> count; estimate it if factor > 1)
      Return: na (histogram), or null on error

  Notes:
      (1) If pixs is cmapped, @val is compared to the colormap index;
          otherwise, @val is compared to the grayscale value.
      (2) Set the subsampling @factor > 1 to reduce the amount of computation.
          If @factor > 1, multiply the count by @factor * @factor.

=head2 pixCountByColumn

NUMA * pixCountByColumn ( PIX *pix, BOX *box )

  pixCountByColumn()

      Input:  pix (1 bpp)
              box (<optional> clipping box for count; can be null)
      Return: na of number of ON pixels by column, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.

=head2 pixCountByRow

NUMA * pixCountByRow ( PIX *pix, BOX *box )

  pixCountByRow()

      Input:  pix (1 bpp)
              box (<optional> clipping box for count; can be null)
      Return: na of number of ON pixels by row, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.

=head2 pixCountPixels

l_int32 pixCountPixels ( PIX *pix, l_int32 *pcount, l_int32 *tab8 )

  pixCountPixels()

      Input:  pix (1 bpp)
              &count (<return> count of ON pixels)
              tab8  (<optional> 8-bit pixel lookup table)
      Return: 0 if OK; 1 on error

=head2 pixCountPixelsByColumn

NUMA * pixCountPixelsByColumn ( PIX *pix )

  pixCountPixelsByColumn()

      Input:  pix (1 bpp)
      Return: na of counts in each column, or null on error

=head2 pixCountPixelsByRow

NUMA * pixCountPixelsByRow ( PIX *pix, l_int32 *tab8 )

  pixCountPixelsByRow()

      Input:  pix (1 bpp)
              tab8  (<optional> 8-bit pixel lookup table)
      Return: na of counts, or null on error

=head2 pixCountPixelsInRow

l_int32 pixCountPixelsInRow ( PIX *pix, l_int32 row, l_int32 *pcount, l_int32 *tab8 )

  pixCountPixelsInRow()

      Input:  pix (1 bpp)
              row number
              &count (<return> sum of ON pixels in raster line)
              tab8  (<optional> 8-bit pixel lookup table)
      Return: 0 if OK; 1 on error

=head2 pixForegroundFraction

l_int32 pixForegroundFraction ( PIX *pix, l_float32 *pfract )

  pixForegroundFraction()

      Input:  pix (1 bpp)
              &fract (<return> fraction of ON pixels)
      Return: 0 if OK; 1 on error

=head2 pixGetMomentByColumn

NUMA * pixGetMomentByColumn ( PIX *pix, l_int32 order )

  pixGetMomentByColumn()

      Input:  pix (1 bpp)
              order (of moment, either 1 or 2)
      Return: na of first moment of fg pixels, by column, or null on error

=head2 pixInvert

PIX * pixInvert ( PIX *pixd, PIX *pixs )

  pixInvert()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs
      Return: pixd, or null on error

  Notes:
      (1) This inverts pixs, for all pixel depths.
      (2) There are 3 cases:
           (a) pixd == null,   ~src --> new pixd
           (b) pixd == pixs,   ~src --> src  (in-place)
           (c) pixd != pixs,   ~src --> input pixd
      (3) For clarity, if the case is known, use these patterns:
           (a) pixd = pixInvert(NULL, pixs);
           (b) pixInvert(pixs, pixs);
           (c) pixInvert(pixd, pixs);

=head2 pixMakeMaskFromLUT

PIX * pixMakeMaskFromLUT ( PIX *pixs, l_int32 *tab )

  pixMakeMaskFromLUT()

      Input:  pixs (2, 4 or 8 bpp; can be colormapped)
              tab (256-entry LUT; 1 means to write to mask)
      Return: pixd (1 bpp mask), or null on error

  Notes:
      (1) This generates a 1 bpp mask image, where a 1 is written in
          the mask for each pixel in pixs that has a value corresponding
          to a 1 in the LUT.
      (2) The LUT should be of size 256.

=head2 pixMirroredTiling

PIX * pixMirroredTiling ( PIX *pixs, l_int32 w, l_int32 h )

  pixMirroredTiling()

      Input:  pixs (8 or 32 bpp, small tile; to be replicated)
              w, h (dimensions of output pix)
      Return: pixd (usually larger pix, mirror-tiled with pixs),
              or null on error

  Notes:
      (1) This uses mirrored tiling, where each row alternates
          with LR flips and every column alternates with TB
          flips, such that the result is a tiling with identical
          2 x 2 tiles, each of which is composed of these transforms:
                  -----------------
                  | 1    |  LR    |
                  -----------------
                  | TB   |  LR/TB |
                  -----------------

=head2 pixOr

PIX * pixOr ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixOr()

      Input:  pixd  (<optional>; this can be null, equal to pixs1,
                     different from pixs1)
              pixs1 (can be == pixd)
              pixs2 (must be != pixd)
      Return: pixd always

  Notes:
      (1) This gives the union of two images with equal depth,
          aligning them to the the UL corner.  pixs1 and pixs2
          need not have the same width and height.
      (2) There are 3 cases:
            (a) pixd == null,   (src1 | src2) --> new pixd
            (b) pixd == pixs1,  (src1 | src2) --> src1  (in-place)
            (c) pixd != pixs1,  (src1 | src2) --> input pixd
      (3) For clarity, if the case is known, use these patterns:
            (a) pixd = pixOr(NULL, pixs1, pixs2);
            (b) pixOr(pixs1, pixs1, pixs2);
            (c) pixOr(pixd, pixs1, pixs2);
      (4) The size of the result is determined by pixs1.
      (5) The depths of pixs1 and pixs2 must be equal.
      (6) Note carefully that the order of pixs1 and pixs2 only matters
          for the in-place case.  For in-place, you must have
          pixd == pixs1.  Setting pixd == pixs2 gives an incorrect
          result: the copy puts pixs1 image data in pixs2, and
          the rasterop is then between pixs2 and pixs2 (a no-op).

=head2 pixPaintSelfThroughMask

l_int32 pixPaintSelfThroughMask ( PIX *pixd, PIX *pixm, l_int32 x, l_int32 y, l_int32 tilesize, l_int32 searchdir )

  pixPaintSelfThroughMask()

      Input:  pixd (8 bpp gray or 32 bpp rgb; not colormapped)
              pixm (1 bpp mask)
              x, y (origin of pixm relative to pixd; must not be negative)
              tilesize (requested size for tiling)
              searchdir (L_HORIZ, L_VERT)
      Return: 0 if OK; 1 on error

  Notes:
      (1) In-place operation; pixd is changed.
      (2) If pixm == NULL, it's a no-op.
      (3) The mask origin is placed at (x,y) on pixd, and the
          operation is clipped to the intersection of pixd and the
          fg of the mask.
      (4) The tilesize is the the requested size for tiling.  The
          actual size for each c.c. will be bounded by the minimum
          dimension of the c.c. and the distance at which the tile
          center is located.
      (5) searchdir is the direction with respect to the b.b. of each
          mask component, from which the square patch is chosen and
          tiled onto the image, clipped by the mask component.
      (6) Specifically, a mirrored tiling, generated from pixd,
          is used to construct the pixels that are painted onto
          pixd through pixm.

=head2 pixPaintThroughMask

l_int32 pixPaintThroughMask ( PIX *pixd, PIX *pixm, l_int32 x, l_int32 y, l_uint32 val )

  pixPaintThroughMask()

      Input:  pixd (1, 2, 4, 8, 16 or 32 bpp; or colormapped)
              pixm (<optional> 1 bpp mask)
              x, y (origin of pixm relative to pixd; can be negative)
              val (pixel value to set at each masked pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) In-place operation.  Calls pixSetMaskedCmap() for colormapped
          images.
      (2) For 1, 2, 4, 8 and 16 bpp gray, we take the appropriate
          number of least significant bits of val.
      (3) If pixm == NULL, it's a no-op.
      (4) The mask origin is placed at (x,y) on pixd, and the
          operation is clipped to the intersection of rectangles.
      (5) For rgb, the components in val are in the canonical locations,
          with red in location COLOR_RED, etc.
      (6) Implementation detail 1:
          For painting with val == 0 or val == maxval, you can use rasterop.
          If val == 0, invert the mask so that it's 0 over the region
          into which you want to write, and use PIX_SRC & PIX_DST to
          clear those pixels.  To write with val = maxval (all 1's),
          use PIX_SRC | PIX_DST to set all bits under the mask.
      (7) Implementation detail 2:
          The rasterop trick can be used for depth > 1 as well.
          For val == 0, generate the mask for depth d from the binary
          mask using
              pixmd = pixUnpackBinary(pixm, d, 1);
          and use pixRasterop() with PIX_MASK.  For val == maxval,
              pixmd = pixUnpackBinary(pixm, d, 0);
          and use pixRasterop() with PIX_PAINT.
          But note that if d == 32 bpp, it is about 3x faster to use
          the general implementation (not pixRasterop()).
      (8) Implementation detail 3:
          It might be expected that the switch in the inner loop will
          cause large branching delays and should be avoided.
          This is not the case, because the entrance is always the
          same and the compiler can correctly predict the jump.

=head2 pixSetMasked

l_int32 pixSetMasked ( PIX *pixd, PIX *pixm, l_uint32 val )

  pixSetMasked()

      Input:  pixd (1, 2, 4, 8, 16 or 32 bpp; or colormapped)
              pixm (<optional> 1 bpp mask; no operation if NULL)
              val (value to set at each masked pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) In-place operation.
      (2) NOTE: For cmapped images, this calls pixSetMaskedCmap().
          @val must be the 32-bit color representation of the RGB pixel.
          It is not the index into the colormap!
      (2) If pixm == NULL, a warning is given.
      (3) This is an implicitly aligned operation, where the UL
          corners of pixd and pixm coincide.  A warning is
          issued if the two image sizes differ significantly,
          but the operation proceeds.
      (4) Each pixel in pixd that co-locates with an ON pixel
          in pixm is set to the specified input value.
          Other pixels in pixd are not changed.
      (5) You can visualize this as painting the color through
          the mask, as a stencil.
      (6) If you do not want to have the UL corners aligned,
          use the function pixSetMaskedGeneral(), which requires
          you to input the UL corner of pixm relative to pixd.
      (7) Implementation details: see comments in pixPaintThroughMask()
          for when we use rasterop to do the painting.

=head2 pixSetMaskedGeneral

l_int32 pixSetMaskedGeneral ( PIX *pixd, PIX *pixm, l_uint32 val, l_int32 x, l_int32 y )

  pixSetMaskedGeneral()

      Input:  pixd (8, 16 or 32 bpp)
              pixm (<optional> 1 bpp mask; no operation if null)
              val (value to set at each masked pixel)
              x, y (location of UL corner of pixm relative to pixd;
                    can be negative)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) Alignment is explicit.  If you want the UL corners of
          the two images to be aligned, use pixSetMasked().
      (3) A typical use would be painting through the foreground
          of a small binary mask pixm, located somewhere on a
          larger pixd.  Other pixels in pixd are not changed.
      (4) You can visualize this as painting the color through
          the mask, as a stencil.
      (5) This uses rasterop to handle clipping and different depths of pixd.
      (6) If pixd has a colormap, you should call pixPaintThroughMask().
      (7) Why is this function here, if pixPaintThroughMask() does the
          same thing, and does it more generally?  I've retained it here
          to show how one can paint through a mask using only full
          image rasterops, rather than pixel peeking in pixm and poking
          in pixd.  It's somewhat baroque, but I found it amusing.

=head2 pixSetUnderTransparency

PIX * pixSetUnderTransparency ( PIX *pixs, l_uint32 val, l_int32 debug )

  pixSetUnderTransparency()

      Input:  pixs (32 bpp rgba)
              val (32 bit unsigned color to use where alpha == 0)
              debug (displays layers of pixs)
      Return: pixd (32 bpp rgba), or null on error

  Notes:
      (1) This sets the r, g and b components under every fully
          transparent alpha component to @val.  The alpha components
          are unchanged.
      (2) Full transparency is denoted by alpha == 0.  Setting
          all pixels to a constant @val where alpha is transparent
          can improve compressibility by reducing the entropy.
      (3) The visual result depends on how the image is displayed.
          (a) For display devices that respect the use of the alpha
              layer, this will not affect the appearance.
          (b) For typical leptonica operations, alpha is ignored,
              so there will be a change in appearance because this
              resets the rgb values in the fully transparent region.
      (4) pixRead() and pixWrite() will, by default, read and write
          4-component (rgba) pix in png format.  To ignore the alpha
          component after reading, or omit it on writing, pixSetSpp(..., 3).
      (5) Here are some examples:
          * To convert all fully transparent pixels in a 4 component
            (rgba) png file to white:
              pixs = pixRead(<infile>);
              pixd = pixSetUnderTransparency(pixs, 0xffffff00, 0);
          * To write pixd with the alpha component:
              pixWrite(<outfile>, pixd, IFF_PNG);
          * To write and rgba image without the alpha component, first do:
              pixSetSpp(pixd, 3);
            If you later want to use the alpha, spp must be reset to 4.
          * (fancier) To remove the alpha by blending the image over
            a white background:
              pixRemoveAlpha()
            This changes all pixel values where the alpha component is
            not opaque (255).
      (6) Caution.  rgb images in leptonica typically have value 0 in
          the alpha channel, which is fully transparent.  If spp for
          such an image were changed from 3 to 4, the image becomes
          fully transparent, and this function will set each pixel to @val.
          If you really want to set every pixel to the same value,
          use pixSetAllArbitrary().
      (7) This is useful for compressing an RGBA image where the part
          of the image that is fully transparent is random junk; compression
          is typically improved by setting that region to a constant.
          For rendering as a 3 component RGB image over a uniform
          background of arbitrary color, use pixAlphaBlendUniform().

=head2 pixSubtract

PIX * pixSubtract ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixSubtract()

      Input:  pixd  (<optional>; this can be null, equal to pixs1,
                     equal to pixs2, or different from both pixs1 and pixs2)
              pixs1 (can be == pixd)
              pixs2 (can be == pixd)
      Return: pixd always

  Notes:
      (1) This gives the set subtraction of two images with equal depth,
          aligning them to the the UL corner.  pixs1 and pixs2
          need not have the same width and height.
      (2) Source pixs2 is always subtracted from source pixs1.
          The result is
                  pixs1 \ pixs2 = pixs1 & (~pixs2)
      (3) There are 4 cases:
            (a) pixd == null,   (src1 - src2) --> new pixd
            (b) pixd == pixs1,  (src1 - src2) --> src1  (in-place)
            (c) pixd == pixs2,  (src1 - src2) --> src2  (in-place)
            (d) pixd != pixs1 && pixd != pixs2),
                                 (src1 - src2) --> input pixd
      (4) For clarity, if the case is known, use these patterns:
            (a) pixd = pixSubtract(NULL, pixs1, pixs2);
            (b) pixSubtract(pixs1, pixs1, pixs2);
            (c) pixSubtract(pixs2, pixs1, pixs2);
            (d) pixSubtract(pixd, pixs1, pixs2);
      (5) The size of the result is determined by pixs1.
      (6) The depths of pixs1 and pixs2 must be equal.

=head2 pixThresholdPixelSum

l_int32 pixThresholdPixelSum ( PIX *pix, l_int32 thresh, l_int32 *pabove, l_int32 *tab8 )

  pixThresholdPixelSum()

      Input:  pix (1 bpp)
              threshold
              &above (<return> 1 if above threshold;
                               0 if equal to or less than threshold)
              tab8  (<optional> 8-bit pixel lookup table)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This sums the ON pixels and returns immediately if the count
          goes above threshold.  It is therefore more efficient
          for matching images (by running this function on the xor of
          the 2 images) than using pixCountPixels(), which counts all
          pixels before returning.

=head2 pixVarianceByColumn

NUMA * pixVarianceByColumn ( PIX *pix, BOX *box )

  pixVarianceByColumn()

      Input:  pix (8 or 16 bpp; no colormap)
              box (<optional> clipping box for variance; can be null)
      Return: na of rmsdev by column, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.
      (2) We are actually computing the RMS deviation in each row.
          This is the square root of the variance.

=head2 pixVarianceByRow

NUMA * pixVarianceByRow ( PIX *pix, BOX *box )

  pixVarianceByRow()

      Input:  pix (8 or 16 bpp; no colormap)
              box (<optional> clipping box for variance; can be null)
      Return: na of rmsdev by row, or null on error

  Notes:
      (1) To resample for a bin size different from 1, use
          numaUniformSampling() on the result of this function.
      (2) We are actually computing the RMS deviation in each row.
          This is the square root of the variance.

=head2 pixVarianceInRect

l_int32 pixVarianceInRect ( PIX *pix, BOX *box, l_float32 *prootvar )

  pixVarianceInRect()

      Input:  pix (1, 2, 4, 8 bpp; not cmapped)
              box (<optional> if null, use entire image)
              &rootvar (<return> sqrt variance of pixel values in region)
      Return: 0 if OK; 1 on error

=head2 pixXor

PIX * pixXor ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixXor()

      Input:  pixd  (<optional>; this can be null, equal to pixs1,
                     different from pixs1)
              pixs1 (can be == pixd)
              pixs2 (must be != pixd)
      Return: pixd always

  Notes:
      (1) This gives the XOR of two images with equal depth,
          aligning them to the the UL corner.  pixs1 and pixs2
          need not have the same width and height.
      (2) There are 3 cases:
            (a) pixd == null,   (src1 ^ src2) --> new pixd
            (b) pixd == pixs1,  (src1 ^ src2) --> src1  (in-place)
            (c) pixd != pixs1,  (src1 ^ src2) --> input pixd
      (3) For clarity, if the case is known, use these patterns:
            (a) pixd = pixXor(NULL, pixs1, pixs2);
            (b) pixXor(pixs1, pixs1, pixs2);
            (c) pixXor(pixd, pixs1, pixs2);
      (4) The size of the result is determined by pixs1.
      (5) The depths of pixs1 and pixs2 must be equal.
      (6) Note carefully that the order of pixs1 and pixs2 only matters
          for the in-place case.  For in-place, you must have
          pixd == pixs1.  Setting pixd == pixs2 gives an incorrect
          result: the copy puts pixs1 image data in pixs2, and
          the rasterop is then between pixs2 and pixs2 (a no-op).

=head2 pixZero

l_int32 pixZero ( PIX *pix, l_int32 *pempty )

  pixZero()

      Input:  pix (all depths; not colormapped)
              &empty  (<return> 1 if all bits in image are 0; 0 otherwise)
      Return: 0 if OK; 1 on error

  Notes:
      (1) For a binary image, if there are no fg (black) pixels, empty = 1.
      (2) For a grayscale image, if all pixels are black (0), empty = 1.
      (3) For an RGB image, if all 4 components in every pixel is 0,
          empty = 1.

=head2 pixaCountPixels

NUMA * pixaCountPixels ( PIXA *pixa )

  pixaCountPixels()

      Input:  pixa (array of 1 bpp pix)
      Return: na of ON pixels in each pix, or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
