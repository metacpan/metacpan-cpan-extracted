package Image::Leptonica::Func::boxfunc4;
$Image::Leptonica::Func::boxfunc4::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::boxfunc4

=head1 VERSION

version 0.04

=head1 C<boxfunc4.c>

   boxfunc4.c

      Boxa and Boxaa range selection
           BOXA     *boxaSelectRange()
           BOXAA    *boxaaSelectRange()

      Boxa size selection
           BOXA     *boxaSelectBySize()
           NUMA     *boxaMakeSizeIndicator()
           BOXA     *boxaSelectByArea()
           NUMA     *boxaMakeAreaIndicator()
           BOXA     *boxaSelectWithIndicator()

      Boxa permutation
           BOXA     *boxaPermutePseudorandom()
           BOXA     *boxaPermuteRandom()
           l_int32   boxaSwapBoxes()

      Boxa conversions
           PTA      *boxaConvertToPta()
           BOXA     *ptaConvertToBoxa()

      Boxa sequence fitting
           BOXA     *boxaSmoothSequence()
           BOXA     *boxaLinearFit()
           BOXA     *boxaConstrainSize()
           BOXA     *boxaReconcileEvenOddHeight()
           l_int32   boxaPlotSides()    [for debugging]

      Miscellaneous boxa functions
           l_int32   boxaGetExtent()
           l_int32   boxaGetCoverage()
           l_int32   boxaaSizeRange()
           l_int32   boxaSizeRange()
           l_int32   boxaLocationRange()
           l_int32   boxaGetArea()
           PIX      *boxaDisplayTiled()

=head1 FUNCTIONS

=head2 boxaConstrainSize

BOXA * boxaConstrainSize ( BOXA *boxas, l_int32 width, l_int32 widthflag, l_int32 height, l_int32 heightflag )

  boxaConstrainSize()

      Input:  boxas
              width (force width of all boxes to this size;
                     input 0 to use the median width)
              widthflag (L_ADJUST_SKIP, L_ADJUST_LEFT, L_ADJUST_RIGHT,
                         or L_ADJUST_LEFT_AND_RIGHT)
              height (force height of all boxes to this size;
                      input 0 to use the median height)
              heightflag (L_ADJUST_SKIP, L_ADJUST_TOP, L_ADJUST_BOT,
                          or L_ADJUST_TOP_AND_BOT)
      Return: boxad (adjusted so all boxes are the same size)

  Notes:
      (1) Forces either width or height (or both) of every box in
          the boxa to a specified size, by moving the indicated sides.
      (2) All input boxes should be valid.  Median values will be
          used with invalid boxes.
      (3) Typical input might be the output of boxaLinearFit(),
          where each side has been fit.
      (4) Unlike boxaAdjustWidthToTarget() and boxaAdjustHeightToTarget(),
          this is not dependent on a difference threshold to change the size.

=head2 boxaConvertToPta

PTA * boxaConvertToPta ( BOXA *boxa, l_int32 ncorners )

  boxaConvertToPta()

      Input:  boxa
              ncorners (2 or 4 for the representation of each box)
      Return: pta (with @ncorners points for each box in the boxa),
                   or null on error

  Notes:
      (1) If ncorners == 2, we select the UL and LR corners.
          Otherwise we save all 4 corners in this order: UL, UR, LL, LR.

=head2 boxaDisplayTiled

PIX * boxaDisplayTiled ( BOXA *boxa, PIXA *pixa, l_int32 maxwidth, l_int32 linewidth, l_float32 scalefactor, l_int32 background, l_int32 spacing, l_int32 border, const char *fontdir )

  boxaDisplayTiled()

      Input:  boxa
              pixa (<optional> background for each box)
              maxwidth (of output image)
              linewidth (width of box outlines, before scaling)
              scalefactor (applied to every box; use 1.0 for no scaling)
              background (0 for white, 1 for black; this is the color
                          of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of black border added to each image;
                      use 0 for no border)
              fontdir (<optional> can be NULL; use to number the boxes)
      Return: pixd (of tiled images of boxes), or null on error

  Notes:
      (1) Displays each box separately in a tiled 32 bpp image.
      (2) If pixa is defined, it must have the same count as the boxa,
          and it will be a background over with each box is rendered.
          If pixa is not defined, the boxes will be rendered over
          blank images of identical size.
      (3) See pixaDisplayTiledInRows() for other parameters.

=head2 boxaGetArea

l_int32 boxaGetArea ( BOXA *boxa, l_int32 *parea )

  boxaGetArea()

      Input:  boxa
              &area (<return> total area of all boxes)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Measures the total area of the boxes, without regard to overlaps.

=head2 boxaGetCoverage

l_int32 boxaGetCoverage ( BOXA *boxa, l_int32 wc, l_int32 hc, l_int32 exactflag, l_float32 *pfract )

  boxaGetCoverage()

      Input:  boxa
              wc, hc (dimensions of overall clipping rectangle with UL
                      corner at (0, 0) that is covered by the boxes.
              exactflag (1 for guaranteeing an exact result; 0 for getting
                         an exact result only if the boxes do not overlap)
              &fract (<return> sum of box area as fraction of w * h)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The boxes in boxa are clipped to the input rectangle.
      (2) * When @exactflag == 1, we generate a 1 bpp pix of size
            wc x hc, paint all the boxes black, and count the fg pixels.
            This can take 1 msec on a large page with many boxes.
          * When @exactflag == 0, we clip each box to the wc x hc region
            and sum the resulting areas.  This is faster.
          * The results are the same when none of the boxes overlap
            within the wc x hc region.

=head2 boxaGetExtent

l_int32 boxaGetExtent ( BOXA *boxa, l_int32 *pw, l_int32 *ph, BOX **pbox )

  boxaGetExtent()

      Input:  boxa
              &w  (<optional return> width)
              &h  (<optional return> height)
              &box (<optional return>, minimum box containing all boxes
                    in boxa)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The returned w and h are the minimum size image
          that would contain all boxes untranslated.
      (2) If there are no valid boxes, returned w and h are 0 and
          all parameters in the returned box are 0.  This
          is not an error, because an empty boxa is valid and
          boxaGetExtent() is required for serialization.

=head2 boxaLinearFit

BOXA * boxaLinearFit ( BOXA *boxas, l_float32 factor, l_int32 max_error, l_int32 debug )

  boxaLinearFit()

      Input:  boxas (source boxa)
              factor (reject outliers with error greater than this
                      number of median errors; typically ~3)
              max_error (maximum difference in pixels between fitted
                         and original location to allow using the
                         original value instead of the fitted value)
              debug (1 for debug output)
      Return: boxad (fitted boxa), or null on error

  Notes:
      (1) Suppose you have a boxa where the box edges are expected
          to vary slowly and linearly across the set.  These could
          be, for example, noisy measurements of similar regions
          on successive scanned pages.
      (2) Method: there are 2 basic steps:
          (a) Find outliers, separately based on the deviation
              from the median of the width and height of the box.
              After the width- and height-based outliers are removed,
              do a linear LSF for each of the four sides.  Use
              @factor to specify tolerance to outliers; use a very large
              value of @factor to avoid rejecting points.
          (b) Using the LSF of (a), make the final determination of
              the four edge locations.  See (3) for details.
      (3) The parameter @max_error makes the input values somewhat sticky.
          Use the fitted values only when the difference between input
          and fitted value is greater than @max_error.  Two special cases:
          (a) set @max_error == 0 to use only fitted values in boxad.
          (b) set @max_error == 10000 to ignore all fitted values; then
              boxad will be the same as boxas.
      (4) Invalid input boxes are not used in computation of the LSF,
          and the output boxes are found from the LSF.
      (5) To enforce additional constraints on the size of each box,
          follow this operation with boxaConstrainSize(), taking boxad
          as input.

=head2 boxaLocationRange

l_int32 boxaLocationRange ( BOXA *boxa, l_int32 *pminx, l_int32 *pminy, l_int32 *pmaxx, l_int32 *pmaxy )

  boxaLocationRange()

      Input:  boxa
              &minx, &miny, &maxx, &maxy (<optional return> range of
                                          UL corner positions)
      Return: 0 if OK, 1 on error

=head2 boxaMakeAreaIndicator

NUMA * boxaMakeAreaIndicator ( BOXA *boxa, l_int32 area, l_int32 relation )

  boxaMakeAreaIndicator()

      Input:  boxa
              area (threshold value of width * height)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
      Return: na (indicator array), or null on error

  Notes:
      (1) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 boxaMakeSizeIndicator

NUMA * boxaMakeSizeIndicator ( BOXA *boxa, l_int32 width, l_int32 height, l_int32 type, l_int32 relation )

  boxaMakeSizeIndicator()

      Input:  boxa
              width, height (threshold dimensions)
              type (L_SELECT_WIDTH, L_SELECT_HEIGHT,
                    L_SELECT_IF_EITHER, L_SELECT_IF_BOTH)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
      Return: na (indicator array), or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) If the selection type is L_SELECT_WIDTH, the input
          height is ignored, and v.v.
      (3) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 boxaPermutePseudorandom

BOXA * boxaPermutePseudorandom ( BOXA *boxas )

  boxaPermutePseudorandom()

      Input:  boxas (input boxa)
      Return: boxad (with boxes permuted), or null on error

  Notes:
      (1) This does a pseudorandom in-place permutation of the boxes.
      (2) The result is guaranteed not to have any boxes in their
          original position, but it is not very random.  If you
          need randomness, use boxaPermuteRandom().

=head2 boxaPermuteRandom

BOXA * boxaPermuteRandom ( BOXA *boxad, BOXA *boxas )

  boxaPermuteRandom()

      Input:  boxad (<optional> can be null or equal to boxas)
              boxas (input boxa)
      Return: boxad (with boxes permuted), or null on error

  Notes:
      (1) If boxad is null, make a copy of boxas and permute the copy.
          Otherwise, boxad must be equal to boxas, and the operation
          is done in-place.
      (2) This does a random in-place permutation of the boxes,
          by swapping each box in turn with a random box.  The
          result is almost guaranteed not to have any boxes in their
          original position.
      (3) MSVC rand() has MAX_RAND = 2^15 - 1, so it will not do
          a proper permutation is the number of boxes exceeds this.

=head2 boxaPlotSides

l_int32 boxaPlotSides ( BOXA *boxa, const char *plotname, NUMA **pnal, NUMA **pnat, NUMA **pnar, NUMA **pnab, l_int32 outformat )

  boxaPlotSides()

      Input:  boxas (source boxa)
              plotname (<optional>, can be NULL)
              &nal (<optional return> na of left sides)
              &nat (<optional return> na of top sides)
              &nar (<optional return> na of right sides)
              &nab (<optional return> na of bottom sides)
              outformat (GPLOT_NONE for no output; GPLOT_PNG for png, etc)
               ut
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a debugging function to show the progression of
          the four sides in the boxes.  There must be at least 2 boxes.
      (2) One of three conditions holds:
          (a) only the even indices have valid boxes
          (b) only the odd indices have valid boxes
          (c) all indices have valid boxes
          This condition is determined by looking at the first 2 boxes.
      (3) The plotfiles are put in /tmp, and are named either with
          @plotname or, if NULL, a default name.

=head2 boxaReconcileEvenOddHeight

BOXA * boxaReconcileEvenOddHeight ( BOXA *boxas, l_int32 sides, l_int32 delh, l_int32 op, l_float32 factor )

  boxaReconcileEvenOddHeight()

      Input:  boxas (containing at least 3 valid boxes in even and odd)
              sides (L_ADJUST_TOP, L_ADJUST_BOT, L_ADJUST_TOP_AND_BOT)
              delh (threshold on median height difference)
              op (L_ADJUST_CHOOSE_MIN, L_ADJUST_CHOOSE_MAX)
              factor (> 0.0, typically near 1.0)
      Return: boxad (adjusted)

  Notes:
      (1) The basic idea is to reconcile differences in box height
          in the even and odd boxes, by moving the top and/or bottom
          edges in the even and odd boxes.  Choose the edge or edges
          to be moved, whether to adjust the boxes with the min
          or the max of the medians, and the threshold on the median
          difference between even and odd box heights for the operations
          to take place.  The same threshold is also used to
          determine if each individual box edge is to be adjusted.
      (2) Boxes are conditionally reset with either the same top (y)
          value or the same bottom value, or both.  The value is
          determined by the greater or lesser of the medians of the
          even and odd boxes, with the choice depending on the value
          of @op, which selects for either min or max median height.
          If the median difference between even and odd boxes is
          greater than @dely, then any individual box edge that differs
          from the selected median by more than @dely is set to
          the selected median times a factor typically near 1.0.
      (3) Note that if selecting for minimum height, you will choose
          the largest y-value for the top and the smallest y-value for
          the bottom of the box.
      (4) Typical input might be the output of boxaSmoothSequence(),
          where even and odd boxa have been independently regulated.
      (5) Require at least 3 valid even boxes and 3 valid odd boxes.
          Median values will be used for invalid boxes.

=head2 boxaSelectByArea

BOXA * boxaSelectByArea ( BOXA *boxas, l_int32 area, l_int32 relation, l_int32 *pchanged )

  boxaSelectByArea()

      Input:  boxas
              area (threshold value of width * height)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: boxad (filtered set), or null on error

  Notes:
      (1) Uses box clones in the new boxa.
      (2) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 boxaSelectBySize

BOXA * boxaSelectBySize ( BOXA *boxas, l_int32 width, l_int32 height, l_int32 type, l_int32 relation, l_int32 *pchanged )

  boxaSelectBySize()

      Input:  boxas
              width, height (threshold dimensions)
              type (L_SELECT_WIDTH, L_SELECT_HEIGHT,
                    L_SELECT_IF_EITHER, L_SELECT_IF_BOTH)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: boxad (filtered set), or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) Uses box clones in the new boxa.
      (3) If the selection type is L_SELECT_WIDTH, the input
          height is ignored, and v.v.
      (4) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 boxaSelectRange

BOXA * boxaSelectRange ( BOXA *boxas, l_int32 first, l_int32 last, l_int32 copyflag )

  boxaSelectRange()

      Input:  boxas
              first (use 0 to select from the beginning)
              last (use 0 to select to the end)
              copyflag (L_COPY, L_CLONE)
      Return: boxad, or null on error

  Notes:
      (1) The copyflag specifies what we do with each box from boxas.
          Specifically, L_CLONE inserts a clone into boxad of each
          selected box from boxas.

=head2 boxaSelectWithIndicator

BOXA * boxaSelectWithIndicator ( BOXA *boxas, NUMA *na, l_int32 *pchanged )

  boxaSelectWithIndicator()

      Input:  boxas
              na (indicator numa)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: boxad, or null on error

  Notes:
      (1) Returns a boxa clone if no components are removed.
      (2) Uses box clones in the new boxa.
      (3) The indicator numa has values 0 (ignore) and 1 (accept).

=head2 boxaSizeRange

l_int32 boxaSizeRange ( BOXA *boxa, l_int32 *pminw, l_int32 *pminh, l_int32 *pmaxw, l_int32 *pmaxh )

  boxaSizeRange()

      Input:  boxa
              &minw, &minh, &maxw, &maxh (<optional return> range of
                                          dimensions of box in the array)
      Return: 0 if OK, 1 on error

=head2 boxaSmoothSequence

BOXA * boxaSmoothSequence ( BOXA *boxas, l_float32 factor, l_int32 max_error, l_int32 debug )

  boxaSmoothSequence()

      Input:  boxas (source boxa)
              factor (reject outliers with error greater than this
                      number of median errors; typically ~3)
              max_error (maximum difference in pixels between fitted
                         and original location to allow using the
                         original value instead of the fitted value)
              debug (1 for debug output)
      Return: boxad (fitted boxa), or null on error

  Notes:
      (1) This does linear fitting separately to the sequences of
          even and odd boxes.  It is assumed that in both the even and
          odd sets, the box edges vary slowly and linearly across each set.

=head2 boxaSwapBoxes

l_int32 boxaSwapBoxes ( BOXA *boxa, l_int32 i, l_int32 j )

  boxaSwapBoxes()

      Input:  boxa
              i, j (two indices of boxes, that are to be swapped)
      Return: 0 if OK, 1 on error

=head2 boxaaSelectRange

BOXAA * boxaaSelectRange ( BOXAA *baas, l_int32 first, l_int32 last, l_int32 copyflag )

  boxaaSelectRange()

      Input:  baas
              first (use 0 to select from the beginning)
              last (use 0 to select to the end)
              copyflag (L_COPY, L_CLONE)
      Return: baad, or null on error

  Notes:
      (1) The copyflag specifies what we do with each boxa from baas.
          Specifically, L_CLONE inserts a clone into baad of each
          selected boxa from baas.

=head2 boxaaSizeRange

l_int32 boxaaSizeRange ( BOXAA *baa, l_int32 *pminw, l_int32 *pminh, l_int32 *pmaxw, l_int32 *pmaxh )

  boxaaSizeRange()

      Input:  baa
              &minw, &minh, &maxw, &maxh (<optional return> range of
                                          dimensions of all boxes)
      Return: 0 if OK, 1 on error

=head2 ptaConvertToBoxa

BOXA * ptaConvertToBoxa ( PTA *pta, l_int32 ncorners )

  ptaConvertToBoxa()

      Input:  pta
              ncorners (2 or 4 for the representation of each box)
      Return: boxa (with one box for each 2 or 4 points in the pta),
                    or null on error

  Notes:
      (1) For 2 corners, the order of the 2 points is UL, LR.
          For 4 corners, the order of points is UL, UR, LL, LR.
      (2) Each derived box is the minimum szie containing all corners.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
