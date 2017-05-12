package Image::Leptonica::Func::boxfunc2;
$Image::Leptonica::Func::boxfunc2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::boxfunc2

=head1 VERSION

version 0.04

=head1 C<boxfunc2.c>

   boxfunc2.c

      Boxa/Box transform (shift, scale) and orthogonal rotation
           BOXA            *boxaTransform()
           BOX             *boxTransform()
           BOXA            *boxaTransformOrdered()
           BOX             *boxTransformOrdered()
           BOXA            *boxaRotateOrth()
           BOX             *boxRotateOrth()

      Boxa sort
           BOXA            *boxaSort()
           BOXA            *boxaBinSort()
           BOXA            *boxaSortByIndex()
           BOXAA           *boxaSort2d()
           BOXAA           *boxaSort2dByIndex()

      Boxa statistics
           BOX             *boxaGetRankSize()
           BOX             *boxaGetMedian()

      Boxa array extraction
           l_int32          boxaExtractAsNuma()
           l_int32          boxaExtractAsPta()

      Other Boxaa functions
           l_int32          boxaaGetExtent()
           BOXA            *boxaaFlattenToBoxa()
           BOXA            *boxaaFlattenAligned()
           BOXAA           *boxaEncapsulateAligned()
           l_int32          boxaaAlignBox()

=head1 FUNCTIONS

=head2 boxRotateOrth

BOX * boxRotateOrth ( BOX *box, l_int32 w, l_int32 h, l_int32 rotation )

  boxRotateOrth()

      Input:  box
              w, h (of image in which the box is embedded)
              rotation (0 = noop, 1 = 90 deg, 2 = 180 deg, 3 = 270 deg;
                        all rotations are clockwise)
      Return: boxd, or null on error

  Notes:
      (1) Rotate the image with the embedded box by the specified amount.
      (2) After rotation, the rotated box is always measured with
          respect to the UL corner of the image.

=head2 boxTransform

BOX * boxTransform ( BOX *box, l_int32 shiftx, l_int32 shifty, l_float32 scalex, l_float32 scaley )

  boxTransform()

      Input:  box
              shiftx, shifty
              scalex, scaley
      Return: boxd, or null on error

  Notes:
      (1) This is a very simple function that first shifts, then scales.
      (2) If the box is invalid, a new invalid box is returned.

=head2 boxTransformOrdered

BOX * boxTransformOrdered ( BOX *boxs, l_int32 shiftx, l_int32 shifty, l_float32 scalex, l_float32 scaley, l_int32 xcen, l_int32 ycen, l_float32 angle, l_int32 order )

  boxTransformOrdered()

      Input:  boxs
              shiftx, shifty
              scalex, scaley
              xcen, ycen (center of rotation)
              angle (in radians; clockwise is positive)
              order (one of 6 combinations: L_TR_SC_RO, ...)
      Return: boxd, or null on error

  Notes:
      (1) This allows a sequence of linear transforms, composed of
          shift, scaling and rotation, where the order of the
          transforms is specified.
      (2) The rotation is taken about a point specified by (xcen, ycen).
          Let the components of the vector from the center of rotation
          to the box center be (xdif, ydif):
            xdif = (bx + 0.5 * bw) - xcen
            ydif = (by + 0.5 * bh) - ycen
          Then the box center after rotation has new components:
            bxcen = xcen + xdif * cosa + ydif * sina
            bycen = ycen + ydif * cosa - xdif * sina
          where cosa and sina are the cos and sin of the angle,
          and the enclosing box for the rotated box has size:
            rw = |bw * cosa| + |bh * sina|
            rh = |bh * cosa| + |bw * sina|
          where bw and bh are the unrotated width and height.
          Then the box UL corner (rx, ry) is
            rx = bxcen - 0.5 * rw
            ry = bycen - 0.5 * rh
      (3) The center of rotation specified by args @xcen and @ycen
          is the point BEFORE any translation or scaling.  If the
          rotation is not the first operation, this function finds
          the actual center at the time of rotation.  It does this
          by making the following assumptions:
             (1) Any scaling is with respect to the UL corner, so
                 that the center location scales accordingly.
             (2) A translation does not affect the center of
                 the image; it just moves the boxes.
          We always use assumption (1).  However, assumption (2)
          will be incorrect if the apparent translation is due
          to a clipping operation that, in effect, moves the
          origin of the image.  In that case, you should NOT use
          these simple functions.  Instead, use the functions
          in affinecompose.c, where the rotation center can be
          computed from the actual clipping due to translation
          of the image origin.

=head2 boxaBinSort

BOXA * boxaBinSort ( BOXA *boxas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex )

  boxaBinSort()

      Input:  boxa
              sorttype (L_SORT_BY_X, L_SORT_BY_Y, L_SORT_BY_WIDTH,
                        L_SORT_BY_HEIGHT, L_SORT_BY_PERIMETER)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<optional return> index of sorted order into
                        original array)
      Return: boxad (sorted version of boxas), or null on error

  Notes:
      (1) For a large number of boxes (say, greater than 1000), this
          O(n) binsort is much faster than the O(nlogn) shellsort.
          For 5000 components, this is over 20x faster than boxaSort().
      (2) Consequently, boxaSort() calls this function if it will
          likely go much faster.

=head2 boxaEncapsulateAligned

BOXAA * boxaEncapsulateAligned ( BOXA *boxa, l_int32 num, l_int32 copyflag )

  boxaEncapsulateAligned()

      Input:  boxa
              num (number put into each boxa in the baa)
              copyflag  (L_COPY or L_CLONE)
      Return: baa, or null on error

  Notes:
      (1) This puts @num boxes from the input @boxa into each of a
          set of boxa within an output baa.
      (2) This assumes that the boxes in @boxa are in sets of @num each.

=head2 boxaExtractAsNuma

l_int32 boxaExtractAsNuma ( BOXA *boxa, NUMA **pnax, NUMA **pnay, NUMA **pnaw, NUMA **pnah, l_int32 keepinvalid )

  boxaExtractAsNuma()

      Input:  boxa
              &nax (<optional return> array of x locations)
              &nay (<optional return> array of y locations)
              &naw (<optional return> array of w locations)
              &nah (<optional return> array of h locations)
              keepinvalid (1 to keep invalid boxes; 0 to remove them)
      Return: 0 if OK, 1 on error

=head2 boxaExtractAsPta

l_int32 boxaExtractAsPta ( BOXA *boxa, PTA **pptal, PTA **pptat, PTA **pptar, PTA **pptab, l_int32 keepinvalid )

  boxaExtractAsPta()

      Input:  boxa
              &ptal (<optional return> array of left locations vs. index)
              &ptat (<optional return> array of top locations vs. index)
              &ptar (<optional return> array of right locations vs. index)
              &ptab (<optional return> array of bottom locations vs. index)
              keepinvalid (1 to keep invalid boxes; 0 to remove them)
      Return: 0 if OK, 1 on error

=head2 boxaGetMedian

BOX * boxaGetMedian ( BOXA *boxa )

  boxaGetMedian()

      Input:  boxa
      Return: box (with median values for x, y, w, h), or null on error
              or if the boxa is empty.

  Notes:
      (1) See boxaGetRankSize()

=head2 boxaGetRankSize

BOX * boxaGetRankSize ( BOXA *boxa, l_float32 fract )

  boxaGetRankSize()

      Input:  boxa
              fract (use 0.0 for smallest, 1.0 for largest)
      Return: box (with rank values for x, y, w, h), or null on error
              or if the boxa is empty (has no valid boxes)

  Notes:
      (1) This function does not assume that all boxes in the boxa are valid
      (2) The four box parameters are sorted independently.
          For rank order, the width and height are sorted in increasing
          order.  But what does it mean to sort x and y in "rank order"?
          If the boxes are of comparable size and somewhat
          aligned (e.g., from multiple images), it makes some sense
          to give a "rank order" for x and y by sorting them in
          decreasing order.  But in general, the interpretation of a rank
          order on x and y is highly application dependent.  In summary:
             - x and y are sorted in decreasing order
             - w and h are sorted in increasing order

=head2 boxaRotateOrth

BOXA * boxaRotateOrth ( BOXA *boxas, l_int32 w, l_int32 h, l_int32 rotation )

  boxaRotateOrth()

      Input:  boxa
              w, h (of image in which the boxa is embedded)
              rotation (0 = noop, 1 = 90 deg, 2 = 180 deg, 3 = 270 deg;
                        all rotations are clockwise)
      Return: boxad, or null on error

  Notes:
      (1) See boxRotateOrth() for details.

=head2 boxaSort

BOXA * boxaSort ( BOXA *boxas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex )

  boxaSort()

      Input:  boxa
              sorttype (L_SORT_BY_X, L_SORT_BY_Y,
                        L_SORT_BY_RIGHT, L_SORT_BY_BOT,
                        L_SORT_BY_WIDTH, L_SORT_BY_HEIGHT,
                        L_SORT_BY_MIN_DIMENSION, L_SORT_BY_MAX_DIMENSION,
                        L_SORT_BY_PERIMETER, L_SORT_BY_AREA,
                        L_SORT_BY_ASPECT_RATIO)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<optional return> index of sorted order into
                        original array)
      Return: boxad (sorted version of boxas), or null on error

=head2 boxaSort2d

BOXAA * boxaSort2d ( BOXA *boxas, NUMAA **pnaad, l_int32 delta1, l_int32 delta2, l_int32 minh1 )

  boxaSort2d()

      Input:  boxas
              &naa (<optional return> numaa with sorted indices
                    whose values are the indices of the input array)
              delta1 (min overlap that permits aggregation of a box
                      onto a boxa of horizontally-aligned boxes; pass 1)
              delta2 (min overlap that permits aggregation of a box
                      onto a boxa of horizontally-aligned boxes; pass 2)
              minh1 (components less than this height either join an
                     existing boxa or are set aside for pass 2)
      Return: baa (2d sorted version of boxa), or null on error

  Notes:
      (1) The final result is a sort where the 'fast scan' direction is
          left to right, and the 'slow scan' direction is from top
          to bottom.  Each boxa in the baa represents a sorted set
          of boxes from left to right.
      (2) Three passes are used to aggregate the boxas, which can correspond
          to characters or words in a line of text.  In pass 1, only
          taller components, which correspond to xheight or larger,
          are permitted to start a new boxa.  In pass 2, the remaining
          vertically-challenged components are allowed to join an
          existing boxa or start a new one.  In pass 3, boxa whose extent
          is overlapping are joined.  After that, the boxes in each
          boxa are sorted horizontally, and finally the boxa are
          sorted vertically.
      (3) If delta1 < 0, the first pass allows aggregation when
          boxes in the same boxa do not overlap vertically.
          The distance by which they can miss and still be aggregated
          is the absolute value |delta1|.   Similar for delta2 on
          the second pass.
      (4) On the first pass, any component of height less than minh1
          cannot start a new boxa; it's put aside for later insertion.
      (5) On the second pass, any small component that doesn't align
          with an existing boxa can start a new one.
      (6) This can be used to identify lines of text from
          character or word bounding boxes.

=head2 boxaSort2dByIndex

BOXAA * boxaSort2dByIndex ( BOXA *boxas, NUMAA *naa )

  boxaSort2dByIndex()

      Input:  boxas
              naa (numaa that maps from the new baa to the input boxa)
      Return: baa (sorted boxaa), or null on error

=head2 boxaSortByIndex

BOXA * boxaSortByIndex ( BOXA *boxas, NUMA *naindex )

  boxaSortByIndex()

      Input:  boxas
              naindex (na that maps from the new boxa to the input boxa)
      Return: boxad (sorted), or null on error

=head2 boxaTransform

BOXA * boxaTransform ( BOXA *boxas, l_int32 shiftx, l_int32 shifty, l_float32 scalex, l_float32 scaley )

  boxaTransform()

      Input:  boxa
              shiftx, shifty
              scalex, scaley
      Return: boxad, or null on error

  Notes:
      (1) This is a very simple function that first shifts, then scales.

=head2 boxaTransformOrdered

BOXA * boxaTransformOrdered ( BOXA *boxas, l_int32 shiftx, l_int32 shifty, l_float32 scalex, l_float32 scaley, l_int32 xcen, l_int32 ycen, l_float32 angle, l_int32 order )

  boxaTransformOrdered()

      Input:  boxa
              shiftx, shifty
              scalex, scaley
              xcen, ycen (center of rotation)
              angle (in radians; clockwise is positive)
              order (one of 6 combinations: L_TR_SC_RO, ...)
      Return: boxd, or null on error

  Notes:
      (1) This allows a sequence of linear transforms on each box.
          the transforms are from the affine set, composed of
          shift, scaling and rotation, and the order of the
          transforms is specified.
      (2) Although these operations appear to be on an infinite
          2D plane, in practice the region of interest is clipped
          to a finite image.  The center of rotation is usually taken
          with respect to the image (either the UL corner or the
          center).  A translation can have two very different effects:
            (a) Moves the boxes across the fixed image region.
            (b) Moves the image origin, causing a change in the image
                region and an opposite effective translation of the boxes.
          This function should only be used for (a), where the image
          region is fixed on translation.  If the image region is
          changed by the translation, use instead the functions
          in affinecompose.c, where the image region and rotation
          center can be computed from the actual clipping due to
          translation of the image origin.
      (3) See boxTransformOrdered() for usage and implementation details.

=head2 boxaaAlignBox

l_int32 boxaaAlignBox ( BOXAA *baa, BOX *box, l_int32 delta, l_int32 *pindex )

  boxaaAlignBox()

      Input:  baa
              box (to be aligned with the bext boxa in the baa, if possible)
              delta (amount by which consecutive components can miss
                     in overlap and still be included in the array)
              &index (of boxa with best overlap, or if none match,
                      this is the index of the next boxa to be generated)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is not greedy.  It finds the boxa whose vertical
          extent has the closest overlap with the input box.

=head2 boxaaFlattenAligned

BOXA * boxaaFlattenAligned ( BOXAA *baa, l_int32 num, BOX *fillerbox, l_int32 copyflag )

  boxaaFlattenAligned()

      Input:  baa
              num (number extracted from each)
              fillerbox (<optional> that fills if necessary)
              copyflag  (L_COPY or L_CLONE)
      Return: boxa, or null on error

  Notes:
      (1) This 'flattens' the baa to a boxa, taking the first @num
          boxes from each boxa.
      (2) In each boxa, if there are less than @num boxes, we preserve
          the alignment between the input baa and the output boxa
          by inserting one or more fillerbox(es) or, if @fillerbox == NULL,
          one or more invalid placeholder boxes.

=head2 boxaaFlattenToBoxa

BOXA * boxaaFlattenToBoxa ( BOXAA *baa, NUMA **pnaindex, l_int32 copyflag )

  boxaaFlattenToBoxa()

      Input:  baa
              &naindex  (<optional return> the boxa index in the baa)
              copyflag  (L_COPY or L_CLONE)
      Return: boxa, or null on error

  Notes:
      (1) This 'flattens' the baa to a boxa, taking the boxes in
          order in the first boxa, then the second, etc.
      (2) If a boxa is empty, we generate an invalid, placeholder box
          of zero size.  This is useful when converting from a baa
          where each boxa has either 0 or 1 boxes, and it is necessary
          to maintain a 1:1 correspondence between the initial
          boxa array and the resulting box array.
      (3) If &naindex is defined, we generate a Numa that gives, for
          each box in the baa, the index of the boxa to which it belongs.

=head2 boxaaGetExtent

l_int32 boxaaGetExtent ( BOXAA *baa, l_int32 *pw, l_int32 *ph, BOX **pbox, BOXA **pboxa )

  boxaaGetExtent()

      Input:  baa
              &w  (<optional return> width)
              &h  (<optional return> height)
              &box (<optional return>, minimum box containing all boxa
                    in boxaa)
              &boxa (<optional return>, boxa containing all boxes in each
                     boxa in the boxaa)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The returned w and h are the minimum size image
          that would contain all boxes untranslated.
      (2) Each box in the returned boxa is the minimum box required to
          hold all the boxes in the respective boxa of baa.
      (3) If there are no valid boxes in a boxa, the box corresponding
          to its extent has all fields set to 0 (an invalid box).

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
