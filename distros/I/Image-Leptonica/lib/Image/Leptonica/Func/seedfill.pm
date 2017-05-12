package Image::Leptonica::Func::seedfill;
$Image::Leptonica::Func::seedfill::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::seedfill

=head1 VERSION

version 0.04

=head1 C<seedfill.c>

  seedfill.c

      Binary seedfill (source: Luc Vincent)
               PIX      *pixSeedfillBinary()
               PIX      *pixSeedfillBinaryRestricted()

      Applications of binary seedfill to find and fill holes,
      remove c.c. touching the border and fill bg from border:
               PIX      *pixHolesByFilling()
               PIX      *pixFillClosedBorders()
               PIX      *pixExtractBorderConnComps()
               PIX      *pixRemoveBorderConnComps()
               PIX      *pixFillBgFromBorder()

      Hole-filling of components to bounding rectangle
               PIX      *pixFillHolesToBoundingRect()

      Gray seedfill (source: Luc Vincent:fast-hybrid-grayscale-reconstruction)
               l_int32   pixSeedfillGray()
               l_int32   pixSeedfillGrayInv()

      Gray seedfill (source: Luc Vincent: sequential-reconstruction algorithm)
               l_int32   pixSeedfillGraySimple()
               l_int32   pixSeedfillGrayInvSimple()

      Gray seedfill variations
               PIX      *pixSeedfillGrayBasin()

      Distance function (source: Luc Vincent)
               PIX      *pixDistanceFunction()

      Seed spread (based on distance function)
               PIX      *pixSeedspread()

      Local extrema:
               l_int32   pixLocalExtrema()
        static l_int32   pixQualifyLocalMinima()
               l_int32   pixSelectedLocalExtrema()
               PIX      *pixFindEqualValues()

      Selection of minima in mask of connected components
               PTA      *pixSelectMinInConnComp()

      Removal of seeded connected components from a mask
               PIX      *pixRemoveSeededComponents()


           ITERATIVE RASTER-ORDER SEEDFILL

      The basic method in the Vincent seedfill (aka reconstruction)
      algorithm is simple.  We describe here the situation for
      binary seedfill.  Pixels are sampled in raster order in
      the seed image.  If they are 4-connected to ON pixels
      either directly above or to the left, and are not masked
      out by the mask image, they are turned on (or remain on).
      (Ditto for 8-connected, except you need to check 3 pixels
      on the previous line as well as the pixel to the left
      on the current line.  This is extra computational work
      for relatively little gain, so it is preferable
      in most situations to use the 4-connected version.)
      The algorithm proceeds from UR to LL of the image, and
      then reverses and sweeps up from LL to UR.
      These double sweeps are iterated until there is no change.
      At this point, the seed has entirely filled the region it
      is allowed to, as delimited by the mask image.

      The grayscale seedfill is a straightforward generalization
      of the binary seedfill, and is described in seedfillLowGray().

      For some applications, the filled seed will later be OR'd
      with the negative of the mask.   This is used, for example,
      when you flood fill into a 4-connected region of OFF pixels
      and you want the result after those pixels are turned ON.

      Note carefully that the mask we use delineates which pixels
      are allowed to be ON as the seed is filled.  We will call this
      a "filling mask".  As the seed expands, it is repeatedly
      ANDed with the filling mask: s & fm.  The process can equivalently
      be formulated using the inverse of the filling mask, which
      we will call a "blocking mask": bm = ~fm.   As the seed
      expands, the blocking mask is repeatedly used to prevent
      the seed from expanding into the blocking mask.  This is done
      by set subtracting the blocking mask from the expanded seed:
      s - bm.  Set subtraction of the blocking mask is equivalent
      to ANDing with the inverse of the blocking mask: s & (~bm).
      But from the inverse relation between blocking and filling
      masks, this is equal to s & fm, which proves the equivalence.

      For efficiency, the pixels can be taken in larger units
      for processing, but still in raster order.  It is natural
      to take them in 32-bit words.  The outline of the work
      to be done for 4-cc (not including special cases for boundary
      words, such as the first line or the last word in each line)
      is as follows.  Let the filling mask be m.  The
      seed is to fill "under" the mask; i.e., limited by an AND
      with the mask.  Let the current word be w, the word
      in the line above be wa, and the previous word in the
      current line be wp.   Let t be a temporary word that
      is used in computation.  Note that masking is performed by
      w & m.  (If we had instead used a "blocking" mask, we
      would perform masking by the set subtraction operation,
      w - m, which is defined to be w & ~m.)

      The entire operation can be implemented with shifts,
      logical operations and tests.  For each word in the seed image
      there are two steps.  The first step is to OR the word with
      the word above and with the rightmost pixel in wp (call it "x").
      Because wp is shifted one pixel to its right, "x" is ORed
      to the leftmost pixel of w.  We then clip to the ON pixels in
      the mask.  The result is
               t  <--  (w | wa | x000... ) & m
      We've now finished taking data from above and to the left.
      The second step is to allow filling to propagate horizontally
      in t, always making sure that it is properly masked at each
      step.  So if filling can be done (i.e., t is neither all 0s
      nor all 1s), iteratively take:
           t  <--  (t | (t >> 1) | (t << 1)) & m
      until t stops changing.  Then write t back into w.

      Finally, the boundary conditions require we note that in doing
      the above steps:
          (a) The words in the first row have no wa
          (b) The first word in each row has no wp in that row
          (c) The last word in each row must be masked so that
              pixels don't propagate beyond the right edge of the
              actual image.  (This is easily accomplished by
              setting the out-of-bound pixels in m to OFF.)

=head1 FUNCTIONS

=head2 pixDistanceFunction

PIX * pixDistanceFunction ( PIX *pixs, l_int32 connectivity, l_int32 outdepth, l_int32 boundcond )

  pixDistanceFunction()

      Input:  pixs  (1 bpp source)
              connectivity  (4 or 8)
              outdepth (8 or 16 bits for pixd)
              boundcond (L_BOUNDARY_BG, L_BOUNDARY_FG)
      Return: pixd, or null on error

  Notes:
      (1) This computes the distance of each pixel from the nearest
          background pixel.  All bg pixels therefore have a distance of 0,
          and the fg pixel distances increase linearly from 1 at the
          boundary.  It can also be used to compute the distance of
          each pixel from the nearest fg pixel, by inverting the input
          image before calling this function.  Then all fg pixels have
          a distance 0 and the bg pixel distances increase linearly
          from 1 at the boundary.
      (2) The algorithm, described in Leptonica on the page on seed
          filling and connected components, is due to Luc Vincent.
          In brief, we generate an 8 or 16 bpp image, initialized
          with the fg pixels of the input pix set to 1 and the
          1-boundary pixels (i.e., the boundary pixels of width 1 on
          the four sides set as either:
            * L_BOUNDARY_BG: 0
            * L_BOUNDARY_FG:  max
          where max = 0xff for 8 bpp and 0xffff for 16 bpp.
          Then do raster/anti-raster sweeps over all pixels interior
          to the 1-boundary, where the value of each new pixel is
          taken to be 1 more than the minimum of the previously-seen
          connected pixels (using either 4 or 8 connectivity).
          Finally, set the 1-boundary pixels using the mirrored method;
          this removes the max values there.
      (3) Using L_BOUNDARY_BG clamps the distance to 0 at the
          boundary.  Using L_BOUNDARY_FG allows the distance
          at the image boundary to "float".
      (4) For 4-connected, one could initialize only the left and top
          1-boundary pixels, and go all the way to the right
          and bottom; then coming back reset left and top.  But we
          instead use a method that works for both 4- and 8-connected.

=head2 pixExtractBorderConnComps

PIX * pixExtractBorderConnComps ( PIX *pixs, l_int32 connectivity )

  pixExtractBorderConnComps()

      Input:  pixs (1 bpp)
              filling connectivity (4 or 8)
      Return: pixd  (all pixels in the src that are in connected
                     components touching the border), or null on error

=head2 pixFillBgFromBorder

PIX * pixFillBgFromBorder ( PIX *pixs, l_int32 connectivity )

  pixFillBgFromBorder()

      Input:  pixs (1 bpp)
              filling connectivity (4 or 8)
      Return: pixd (with the background c.c. touching the border
                    filled to foreground), or null on error

  Notes:
      (1) This fills all bg components touching the border to fg.
          It is the photometric inverse of pixRemoveBorderConnComps().
      (2) Invert the result to get the "holes" left after this fill.
          This can be done multiple times, extracting holes within
          holes after each pair of fillings.  Specifically, this code
          peels away n successive embeddings of components:
              pix1 = <initial image>
              for (i = 0; i < 2 * n; i++) {
                   pix2 = pixFillBgFromBorder(pix1, 8);
                   pixInvert(pix2, pix2);
                   pixDestroy(&pix1);
                   pix1 = pix2;
              }

=head2 pixFillClosedBorders

PIX * pixFillClosedBorders ( PIX *pixs, l_int32 connectivity )

  pixFillClosedBorders()

      Input:  pixs (1 bpp)
              filling connectivity (4 or 8)
      Return: pixd  (all topologically outer closed borders are filled
                     as connected comonents), or null on error

  Notes:
      (1) Start with 1-pixel black border on otherwise white pixd
      (2) Subtract input pixs to remove border pixels that were
          also on the closed border
      (3) Use the inverted pixs as the filling mask to fill in
          all the pixels from the outer border to the closed border
          on pixs
      (4) Invert the result to get the filled component, including
          the input border
      (5) If the borders are 4-c.c., use 8-c.c. filling, and v.v.
      (6) Closed borders within c.c. that represent holes, etc., are filled.

=head2 pixFillHolesToBoundingRect

PIX * pixFillHolesToBoundingRect ( PIX *pixs, l_int32 minsize, l_float32 maxhfract, l_float32 minfgfract )

  pixFillHolesToBoundingRect()

      Input:  pixs (1 bpp)
              minsize (min number of pixels in the hole)
              maxhfract (max hole area as fraction of fg pixels in the cc)
              minfgfract (min fg area as fraction of bounding rectangle)
      Return: pixd (pixs, with some holes possibly filled and some c.c.
                    possibly expanded to their bounding rects),
                    or null on error

  Notes:
      (1) This does not fill holes that are smaller in area than 'minsize'.
      (2) This does not fill holes with an area larger than
          'maxhfract' times the fg area of the c.c.
      (3) This does not expand the fg of the c.c. to bounding rect if
          the fg area is less than 'minfgfract' times the area of the
          bounding rect.
      (4) The decisions are made as follows:
           - Decide if we are filling the holes; if so, when using
             the fg area, include the filled holes.
           - Decide based on the fg area if we are filling to a bounding rect.
             If so, do it.
             If not, fill the holes if the condition is satisfied.
      (5) The choice of minsize depends on the resolution.
      (6) For solidifying image mask regions on printed materials,
          which tend to be rectangular, values for maxhfract
          and minfgfract around 0.5 are reasonable.

=head2 pixFindEqualValues

PIX * pixFindEqualValues ( PIX *pixs1, PIX *pixs2 )

  pixFindEqualValues()

      Input:  pixs1 (8 bpp)
              pixs2 (8 bpp)
      Return: pixd (1 bpp mask), or null on error

  Notes:
      (1) The two images are aligned at the UL corner, and the returned
          image has ON pixels where the pixels in pixs1 and pixs2
          have equal values.

=head2 pixHolesByFilling

PIX * pixHolesByFilling ( PIX *pixs, l_int32 connectivity )

  pixHolesByFilling()

      Input:  pixs (1 bpp)
              connectivity (4 or 8)
      Return: pixd  (inverted image of all holes), or null on error

 Action:
     (1) Start with 1-pixel black border on otherwise white pixd
     (2) Use the inverted pixs as the filling mask to fill in
         all the pixels from the border to the pixs foreground
     (3) OR the result with pixs to have an image with all
         ON pixels except for the holes.
     (4) Invert the result to get the holes as foreground

 Notes:
     (1) To get 4-c.c. holes of the 8-c.c. as foreground, use
         4-connected filling; to get 8-c.c. holes of the 4-c.c.
         as foreground, use 8-connected filling.

=head2 pixLocalExtrema

l_int32 pixLocalExtrema ( PIX *pixs, l_int32 maxmin, l_int32 minmax, PIX **ppixmin, PIX **ppixmax )

  pixLocalExtrema()

      Input:  pixs  (8 bpp)
              maxmin (max allowed for the min in a 3x3 neighborhood;
                      use 0 for default which is to have no upper bound)
              minmax (min allowed for the max in a 3x3 neighborhood;
                      use 0 for default which is to have no lower bound)
              &ppixmin (<optional return> mask of local minima)
              &ppixmax (<optional return> mask of local maxima)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives the actual local minima and maxima.
          A local minimum is a pixel whose surrounding pixels all
          have values at least as large, and likewise for a local
          maximum.  For the local minima, @maxmin is the upper
          bound for the value of pixs.  Likewise, for the local maxima,
          @minmax is the lower bound for the value of pixs.
      (2) The minima are found by starting with the erosion-and-equality
          approach of pixSelectedLocalExtrema().  This is followed
          by a qualification step, where each c.c. in the resulting
          minimum mask is extracted, the pixels bordering it are
          located, and they are queried.  If all of those pixels
          are larger than the value of that minimum, it is a true
          minimum and its c.c. is saved; otherwise the c.c. is
          rejected.  Note that if a bordering pixel has the
          same value as the minimum, it must then have a
          neighbor that is smaller, so the component is not a
          true minimum.
      (3) The maxima are found by inverting the image and looking
          for the minima there.
      (4) The generated masks can be used as markers for
          further operations.

=head2 pixRemoveBorderConnComps

PIX * pixRemoveBorderConnComps ( PIX *pixs, l_int32 connectivity )

  pixRemoveBorderConnComps()

      Input:  pixs (1 bpp)
              filling connectivity (4 or 8)
      Return: pixd  (all pixels in the src that are not touching the
                     border) or null on error

  Notes:
      (1) This removes all fg components touching the border.

=head2 pixRemoveSeededComponents

PIX * pixRemoveSeededComponents ( PIX *pixd, PIX *pixs, PIX *pixm, l_int32 connectivity, l_int32 bordersize )

  pixRemoveSeededComponents()

      Input:  pixd  (<optional>; this can be null or equal to pixm; 1 bpp)
              pixs  (1 bpp seed)
              pixm  (1 bpp filling mask)
              connectivity  (4 or 8)
              bordersize (amount of border clearing)
      Return: pixd, or null on error

  Notes:
      (1) This removes each component in pixm for which there is
          at least one seed in pixs.  If pixd == NULL, this returns
          the result in a new pixd.  Otherwise, it is an in-place
          operation on pixm.  In no situation is pixs altered,
          because we do the filling with a copy of pixs.
      (2) If bordersize > 0, it also clears all pixels within a
          distance @bordersize of the edge of pixd.  This is here
          because pixLocalExtrema() typically finds local minima
          at the border.  Use @bordersize >= 2 to remove these.

=head2 pixSeedfillBinary

PIX * pixSeedfillBinary ( PIX *pixd, PIX *pixs, PIX *pixm, l_int32 connectivity )

  pixSeedfillBinary()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs; 1 bpp)
              pixs  (1 bpp seed)
              pixm  (1 bpp filling mask)
              connectivity  (4 or 8)
      Return: pixd always

  Notes:
      (1) This is for binary seedfill (aka "binary reconstruction").
      (2) There are 3 cases:
            (a) pixd == null (make a new pixd)
            (b) pixd == pixs (in-place)
            (c) pixd != pixs
      (3) If you know the case, use these patterns for clarity:
            (a) pixd = pixSeedfillBinary(NULL, pixs, ...);
            (b) pixSeedfillBinary(pixs, pixs, ...);
            (c) pixSeedfillBinary(pixd, pixs, ...);
      (4) The resulting pixd contains the filled seed.  For some
          applications you want to OR it with the inverse of
          the filling mask.
      (5) The input seed and mask images can be different sizes, but
          in typical use the difference, if any, would be only
          a few pixels in each direction.  If the sizes differ,
          the clipping is handled by the low-level function
          seedfillBinaryLow().

=head2 pixSeedfillBinaryRestricted

PIX * pixSeedfillBinaryRestricted ( PIX *pixd, PIX *pixs, PIX *pixm, l_int32 connectivity, l_int32 xmax, l_int32 ymax )

  pixSeedfillBinaryRestricted()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs; 1 bpp)
              pixs  (1 bpp seed)
              pixm  (1 bpp filling mask)
              connectivity  (4 or 8)
              xmax (max distance in x direction of fill into the mask)
              ymax (max distance in y direction of fill into the mask)
      Return: pixd always

  Notes:
      (1) See usage for pixSeedfillBinary(), which has unrestricted fill.
          In pixSeedfillBinary(), the filling distance is unrestricted
          and can be larger than pixs, depending on the topology of
          th mask.
      (2) There are occasions where it is useful not to permit the
          fill to go more than a certain distance into the mask.
          @xmax specifies the maximum horizontal distance allowed
          in the fill; @ymax does likewise in the vertical direction.
      (3) Operationally, the max "distance" allowed for the fill
          is a linear distance from the original seed, independent
          of the actual mask topology.
      (4) Another formulation of this problem, not implemented,
          would use the manhattan distance from the seed, as
          determined by a breadth-first search starting at the seed
          boundaries and working outward where the mask fg allows.
          How this might use the constraints of separate xmax and ymax
          is not clear.

=head2 pixSeedfillGray

l_int32 pixSeedfillGray ( PIX *pixs, PIX *pixm, l_int32 connectivity )

  pixSeedfillGray()

      Input:  pixs  (8 bpp seed; filled in place)
              pixm  (8 bpp filling mask)
              connectivity  (4 or 8)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place filling operation on the seed, pixs,
          where the clipping mask is always above or at the level
          of the seed as it is filled.
      (2) For details of the operation, see the description in
          seedfillGrayLow() and the code there.
      (3) As an example of use, see the description in pixHDome().
          There, the seed is an image where each pixel is a fixed
          amount smaller than the corresponding mask pixel.
      (4) Reference paper :
            L. Vincent, Morphological grayscale reconstruction in image
            analysis: applications and efficient algorithms, IEEE Transactions
            on  Image Processing, vol. 2, no. 2, pp. 176-201, 1993.

=head2 pixSeedfillGrayBasin

PIX * pixSeedfillGrayBasin ( PIX *pixb, PIX *pixm, l_int32 delta, l_int32 connectivity )

  pixSeedfillGrayBasin()

      Input:  pixb  (binary mask giving seed locations)
              pixm  (8 bpp basin-type filling mask)
              delta (amount of seed value above mask)
              connectivity  (4 or 8)
      Return: pixd (filled seed) if OK, null on error

  Notes:
      (1) This fills from a seed within basins defined by a filling mask.
          The seed value(s) are greater than the corresponding
          filling mask value, and the result has the bottoms of
          the basins raised by the initial seed value.
      (2) The seed has value 255 except where pixb has fg (1), which
          are the seed 'locations'.  At the seed locations, the seed
          value is the corresponding value of the mask pixel in pixm
          plus @delta.  If @delta == 0, we return a copy of pixm.
      (3) The actual filling is done using the standard grayscale filling
          operation on the inverse of the mask and using the inverse
          of the seed image.  After filling, we return the inverse of
          the filled seed.
      (4) As an example of use: pixm can describe a grayscale image
          of text, where the (dark) text pixels are basins of
          low values; pixb can identify the local minima in pixm (say, at
          the bottom of the basins); and delta is the amount that we wish
          to raise (lighten) the basins.  We construct the seed
          (a.k.a marker) image from pixb, pixm and @delta.

=head2 pixSeedfillGrayInv

l_int32 pixSeedfillGrayInv ( PIX *pixs, PIX *pixm, l_int32 connectivity )

  pixSeedfillGrayInv()

      Input:  pixs  (8 bpp seed; filled in place)
              pixm  (8 bpp filling mask)
              connectivity  (4 or 8)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place filling operation on the seed, pixs,
          where the clipping mask is always below or at the level
          of the seed as it is filled.  Think of filling up a basin
          to a particular level, given by the maximum seed value
          in the basin.  Outside the filled region, the mask
          is above the filling level.
      (2) Contrast this with pixSeedfillGray(), where the clipping mask
          is always above or at the level of the fill.  An example
          of its use is the hdome fill, where the seed is an image
          where each pixel is a fixed amount smaller than the
          corresponding mask pixel.
      (3) The basin fill, pixSeedfillGrayBasin(), is a special case
          where the seed pixel values are generated from the mask,
          and where the implementation uses pixSeedfillGray() by
          inverting both the seed and mask.

=head2 pixSeedfillGrayInvSimple

l_int32 pixSeedfillGrayInvSimple ( PIX *pixs, PIX *pixm, l_int32 connectivity )

  pixSeedfillGrayInvSimple()

      Input:  pixs  (8 bpp seed; filled in place)
              pixm  (8 bpp filling mask)
              connectivity  (4 or 8)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place filling operation on the seed, pixs,
          where the clipping mask is always below or at the level
          of the seed as it is filled.  Think of filling up a basin
          to a particular level, given by the maximum seed value
          in the basin.  Outside the filled region, the mask
          is above the filling level.
      (2) Contrast this with pixSeedfillGraySimple(), where the clipping mask
          is always above or at the level of the fill.  An example
          of its use is the hdome fill, where the seed is an image
          where each pixel is a fixed amount smaller than the
          corresponding mask pixel.

=head2 pixSeedfillGraySimple

l_int32 pixSeedfillGraySimple ( PIX *pixs, PIX *pixm, l_int32 connectivity )

  pixSeedfillGraySimple()

      Input:  pixs  (8 bpp seed; filled in place)
              pixm  (8 bpp filling mask)
              connectivity  (4 or 8)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place filling operation on the seed, pixs,
          where the clipping mask is always above or at the level
          of the seed as it is filled.
      (2) For details of the operation, see the description in
          seedfillGrayLowSimple() and the code there.
      (3) As an example of use, see the description in pixHDome().
          There, the seed is an image where each pixel is a fixed
          amount smaller than the corresponding mask pixel.
      (4) Reference paper :
            L. Vincent, Morphological grayscale reconstruction in image
            analysis: applications and efficient algorithms, IEEE Transactions
            on  Image Processing, vol. 2, no. 2, pp. 176-201, 1993.

=head2 pixSeedspread

PIX * pixSeedspread ( PIX *pixs, l_int32 connectivity )

  pixSeedspread()

      Input:  pixs  (8 bpp source)
              connectivity  (4 or 8)
      Return: pixd, or null on error

  Notes:
      (1) The raster/anti-raster method for implementing this filling
          operation was suggested by Ray Smith.
      (2) This takes an arbitrary set of nonzero pixels in pixs, which
          can be sparse, and spreads (extrapolates) the values to
          fill all the pixels in pixd with the nonzero value it is
          closest to in pixs.  This is similar (though not completely
          equivalent) to doing a Voronoi tiling of the image, with a
          tile surrounding each pixel that has a nonzero value.
          All pixels within a tile are then closer to its "central"
          pixel than to any others.  Then assign the value of the
          "central" pixel to each pixel in the tile.
      (3) This is implemented by computing a distance function in parallel
          with the fill.  The distance function uses free boundary
          conditions (assumed maxval outside), and it controls the
          propagation of the pixels in pixd away from the nonzero
          (seed) values.  This is done in 2 traversals (raster/antiraster).
          In the raster direction, whenever the distance function
          is nonzero, the spread pixel takes on the value of its
          predecessor that has the minimum distance value.  In the
          antiraster direction, whenever the distance function is nonzero
          and its value is replaced by a smaller value, the spread
          pixel takes the value of the predecessor with the minimum
          distance value.
      (4) At boundaries where a pixel is equidistant from two
          nearest nonzero (seed) pixels, the decision of which value
          to use is arbitrary (greedy in search for minimum distance).
          This can give rise to strange-looking results, particularly
          for 4-connectivity where the L1 distance is computed from
          steps in N,S,E and W directions (no diagonals).

=head2 pixSelectMinInConnComp

l_int32 pixSelectMinInConnComp ( PIX *pixs, PIX *pixm, PTA **ppta, NUMA **pnav )

  pixSelectMinInConnComp()

      Input:  pixs (8 bpp)
              pixm (1 bpp)
              &pta (<return> pta of min pixel locations)
              &nav (<optional return> numa of minima values)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) For each 8 connected component in pixm, this finds
          a pixel in pixs that has the lowest value, and saves
          it in a Pta.  If several pixels in pixs have the same
          minimum value, it picks the first one found.
      (2) For a mask pixm of true local minima, all pixels in each
          connected component have the same value in pixs, so it is
          fastest to select one of them using a special seedfill
          operation.  Not yet implemented.

=head2 pixSelectedLocalExtrema

l_int32 pixSelectedLocalExtrema ( PIX *pixs, l_int32 mindist, PIX **ppixmin, PIX **ppixmax )

  pixSelectedLocalExtrema()

      Input:  pixs  (8 bpp)
              mindist (-1 for keeping all pixels; >= 0 specifies distance)
              &ppixmin (<return> mask of local minima)
              &ppixmax (<return> mask of local maxima)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This selects those local 3x3 minima that are at least a
          specified distance from the nearest local 3x3 maxima, and v.v.
          for the selected set of local 3x3 maxima.
          The local 3x3 minima is the set of pixels whose value equals
          the value after a 3x3 brick erosion, and the local 3x3 maxima
          is the set of pixels whose value equals the value after
          a 3x3 brick dilation.
      (2) mindist is the minimum distance allowed between
          local 3x3 minima and local 3x3 maxima, in an 8-connected sense.
          mindist == 1 keeps all pixels found in step 1.
          mindist == 0 removes all pixels from each mask that are
          both a local 3x3 minimum and a local 3x3 maximum.
          mindist == 1 removes any local 3x3 minimum pixel that touches a
          local 3x3 maximum pixel, and likewise for the local maxima.
          To make the decision, visualize each local 3x3 minimum pixel
          as being surrounded by a square of size (2 * mindist + 1)
          on each side, such that no local 3x3 maximum pixel is within
          that square; and v.v.
      (3) The generated masks can be used as markers for further operations.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
