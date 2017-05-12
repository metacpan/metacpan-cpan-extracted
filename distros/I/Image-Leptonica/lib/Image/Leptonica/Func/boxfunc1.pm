package Image::Leptonica::Func::boxfunc1;
$Image::Leptonica::Func::boxfunc1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::boxfunc1

=head1 VERSION

version 0.04

=head1 C<boxfunc1.c>

   boxfunc1.c

      Box geometry
           l_int32   boxContains()
           l_int32   boxIntersects()
           BOXA     *boxaContainedInBox()
           BOXA     *boxaIntersectsBox()
           BOXA     *boxaClipToBox()
           BOXA     *boxaCombineOverlaps()
           BOX      *boxOverlapRegion()
           BOX      *boxBoundingRegion()
           l_int32   boxOverlapFraction()
           l_int32   boxOverlapArea()
           BOXA     *boxaHandleOverlaps()
           l_int32   boxSeparationDistance()
           l_int32   boxContainsPt()
           BOX      *boxaGetNearestToPt()
           l_int32   boxIntersectByLine()
           l_int32   boxGetCenter()
           BOX      *boxClipToRectangle()
           l_int32   boxClipToRectangleParams()
           BOX      *boxRelocateOneSide()
           BOX      *boxAdjustSides()
           BOXA     *boxaSetSide()
           BOXA     *boxaAdjustWidthToTarget()
           BOXA     *boxaAdjustHeightToTarget()
           l_int32   boxEqual()
           l_int32   boxaEqual()
           l_int32   boxSimilar()
           l_int32   boxaSimilar()

      Boxa combine and split
           l_int32   boxaJoin()
           l_int32   boxaaJoin()
           l_int32   boxaSplitEvenOdd()
           BOXA     *boxaMergeEvenOdd()

=head1 FUNCTIONS

=head2 boxAdjustSides

BOX * boxAdjustSides ( BOX *boxd, BOX *boxs, l_int32 delleft, l_int32 delright, l_int32 deltop, l_int32 delbot )

  boxAdjustSides()

      Input:  boxd  (<optional>; this can be null, equal to boxs,
                     or different from boxs)
              boxs  (starting box; to have sides adjusted)
              delleft, delright, deltop, delbot (changes in location of
                                                 each side)
      Return: boxd, or null on error or if the computed boxd has
              width or height <= 0.

  Notes:
      (1) Set boxd == NULL to get new box; boxd == boxs for in-place;
          or otherwise to resize existing boxd.
      (2) For usage, suggest one of these:
               boxd = boxAdjustSides(NULL, boxs, ...);   // new
               boxAdjustSides(boxs, boxs, ...);          // in-place
               boxAdjustSides(boxd, boxs, ...);          // other
      (1) New box dimensions are cropped at left and top to x >= 0 and y >= 0.
      (2) For example, to expand in-place by 20 pixels on each side, use
             boxAdjustSides(box, box, -20, 20, -20, 20);

=head2 boxBoundingRegion

BOX * boxBoundingRegion ( BOX *box1, BOX *box2 )

  boxBoundingRegion()

      Input:  box1, box2 (two boxes)
      Return: box (of bounding region containing the input boxes),
              or null on error

=head2 boxClipToRectangle

BOX * boxClipToRectangle ( BOX *box, l_int32 wi, l_int32 hi )

  boxClipToRectangle()

      Input:  box
              wi, hi (rectangle representing image)
      Return: part of box within given rectangle, or NULL on error
              or if box is entirely outside the rectangle

  Notes:
      (1) This can be used to clip a rectangle to an image.
          The clipping rectangle is assumed to have a UL corner at (0, 0),
          and a LR corner at (wi - 1, hi - 1).

=head2 boxClipToRectangleParams

l_int32 boxClipToRectangleParams ( BOX *box, l_int32 w, l_int32 h, l_int32 *pxstart, l_int32 *pystart, l_int32 *pxend, l_int32 *pyend, l_int32 *pbw, l_int32 *pbh )

  boxClipToRectangleParams()

      Input:  box (<optional> requested box; can be null)
              w, h (clipping box size; typ. the size of an image)
              &xstart (<return>)
              &ystart (<return>)
              &xend (<return> one pixel beyond clipping box)
              &yend (<return> one pixel beyond clipping box)
              &bw (<optional return> clipped width)
              &bh (<optional return> clipped height)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The return value should be checked.  If it is 1, the
          returned parameter values are bogus.
      (2) This simplifies the selection of pixel locations within
          a given rectangle:
             for (i = ystart; i < yend; i++ {
                 ...
                 for (j = xstart; j < xend; j++ {
                     ....

=head2 boxContains

l_int32 boxContains ( BOX *box1, BOX *box2, l_int32 *presult )

  boxContains()

      Input:  box1, box2
              &result (<return> 1 if box2 is entirely contained within
                       box1, and 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 boxContainsPt

l_int32 boxContainsPt ( BOX *box, l_float32 x, l_float32 y, l_int32 *pcontains )

  boxContainsPt()

      Input:  box
              x, y (a point)
              &contains (<return> 1 if box contains point; 0 otherwise)
      Return: 0 if OK, 1 on error.

=head2 boxEqual

l_int32 boxEqual ( BOX *box1, BOX *box2, l_int32 *psame )

  boxEqual()

      Input:  box1
              box2
              &same (<return> 1 if equal; 0 otherwise)
      Return  0 if OK, 1 on error

=head2 boxGetCenter

l_int32 boxGetCenter ( BOX *box, l_float32 *pcx, l_float32 *pcy )

  boxGetCenter()

      Input:  box
              &cx, &cy (<return> location of center of box)
      Return  0 if OK, 1 on error

=head2 boxIntersectByLine

l_int32 boxIntersectByLine ( BOX *box, l_int32 x, l_int32 y, l_float32 slope, l_int32 *px1, l_int32 *py1, l_int32 *px2, l_int32 *py2, l_int32 *pn )

  boxIntersectByLine()

      Input:  box
              x, y (point that line goes through)
              slope (of line)
              (&x1, &y1) (<return> 1st point of intersection with box)
              (&x2, &y2) (<return> 2nd point of intersection with box)
              &n (<return> number of points of intersection)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If the intersection is at only one point (a corner), the
          coordinates are returned in (x1, y1).
      (2) Represent a vertical line by one with a large but finite slope.

=head2 boxIntersects

l_int32 boxIntersects ( BOX *box1, BOX *box2, l_int32 *presult )

  boxIntersects()

      Input:  box1, box2
              &result (<return> 1 if any part of box2 is contained
                      in box1, and 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 boxOverlapArea

l_int32 boxOverlapArea ( BOX *box1, BOX *box2, l_int32 *parea )

  boxOverlapArea()

      Input:  box1, box2 (two boxes)
              &area (<return> the number of pixels in the overlap)
      Return: 0 if OK, 1 on error.

=head2 boxOverlapFraction

l_int32 boxOverlapFraction ( BOX *box1, BOX *box2, l_float32 *pfract )

  boxOverlapFraction()

      Input:  box1, box2 (two boxes)
              &fract (<return> the fraction of box2 overlapped by box1)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) The result depends on the order of the input boxes,
          because the overlap is taken as a fraction of box2.

=head2 boxOverlapRegion

BOX * boxOverlapRegion ( BOX *box1, BOX *box2 )

  boxOverlapRegion()

      Input:  box1, box2 (two boxes)
      Return: box (of overlap region between input boxes),
              or null if no overlap or on error

=head2 boxRelocateOneSide

BOX * boxRelocateOneSide ( BOX *boxd, BOX *boxs, l_int32 loc, l_int32 sideflag )

  boxRelocateOneSide()

      Input:  boxd (<optional>; this can be null, equal to boxs,
                    or different from boxs);
              boxs (starting box; to have one side relocated)
              loc (new location of the side that is changing)
              sideflag (L_FROM_LEFT, etc., indicating the side that moves)
      Return: boxd, or null on error or if the computed boxd has
              width or height <= 0.

  Notes:
      (1) Set boxd == NULL to get new box; boxd == boxs for in-place;
          or otherwise to resize existing boxd.
      (2) For usage, suggest one of these:
               boxd = boxRelocateOneSide(NULL, boxs, ...);   // new
               boxRelocateOneSide(boxs, boxs, ...);          // in-place
               boxRelocateOneSide(boxd, boxs, ...);          // other

=head2 boxSeparationDistance

l_int32 boxSeparationDistance ( BOX *box1, BOX *box2, l_int32 *ph_sep, l_int32 *pv_sep )

  boxSeparationDistance()

      Input:  box1, box2 (two boxes, in any order)
              &h_sep (<optional return> horizontal separation)
              &v_sep (<optional return> vertical separation)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This measures horizontal and vertical separation of the
          two boxes.  If the boxes are touching but have no pixels
          in common, the separation is 0.  If the boxes overlap by
          a distance d, the returned separation is -d.

=head2 boxSimilar

l_int32 boxSimilar ( BOX *box1, BOX *box2, l_int32 leftdiff, l_int32 rightdiff, l_int32 topdiff, l_int32 botdiff, l_int32 *psimilar )

  boxSimilar()

      Input:  box1
              box2
              leftdiff, rightdiff, topdiff, botdiff
              &similar (<return> 1 if similar; 0 otherwise)
      Return  0 if OK, 1 on error

  Notes:
      (1) The values of leftdiff (etc) are the maximum allowed deviations
          between the locations of the left (etc) sides.  If any side
          pairs differ by more than this amount, the boxes are not similar.

=head2 boxaAdjustHeightToTarget

BOXA * boxaAdjustHeightToTarget ( BOXA *boxad, BOXA *boxas, l_int32 sides, l_int32 target, l_int32 thresh )

  boxaAdjustHeightToTarget()

      Input:  boxad (use null to get a new one)
              boxas
              sides (L_ADJUST_TOP, L_ADJUST_BOT, L_ADJUST_TOP_AND_BOT)
              target (target height if differs by more than thresh)
              thresh (min abs difference in height to cause adjustment)
      Return: boxad, or null on error

  Notes:
      (1) Conditionally adjusts the height of each box, by moving
          the indicated edges (top and/or bot) if the height differs
          by @thresh or more from @target.
      (2) Use boxad == NULL for a new boxa, and boxad == boxas for in-place.
          Use one of these:
               boxad = boxaAdjustHeightToTarget(NULL, boxas, ...);   // new
               boxaAdjustHeightToTarget(boxas, boxas, ...);  // in-place

=head2 boxaAdjustWidthToTarget

BOXA * boxaAdjustWidthToTarget ( BOXA *boxad, BOXA *boxas, l_int32 sides, l_int32 target, l_int32 thresh )

  boxaAdjustWidthToTarget()

      Input:  boxad (use null to get a new one; same as boxas for in-place)
              boxas
              sides (L_ADJUST_LEFT, L_ADJUST_RIGHT, L_ADJUST_LEFTL_AND_RIGHT)
              target (target width if differs by more than thresh)
              thresh (min abs difference in width to cause adjustment)
      Return: boxad, or null on error

  Notes:
      (1) Conditionally adjusts the width of each box, by moving
          the indicated edges (left and/or right) if the width differs
          by @thresh or more from @target.
      (2) Use boxad == NULL for a new boxa, and boxad == boxas for in-place.
          Use one of these:
               boxad = boxaAdjustWidthToTarget(NULL, boxas, ...);   // new
               boxaAdjustWidthToTarget(boxas, boxas, ...);  // in-place

=head2 boxaClipToBox

BOXA * boxaClipToBox ( BOXA *boxas, BOX *box )

  boxaClipToBox()

      Input:  boxas
              box (for clipping)
      Return  boxad (boxa with boxes in boxas clipped to box),
                     or null on error

  Notes:
      (1) All boxes in boxa not intersecting with box are removed, and
          the remaining boxes are clipped to box.

=head2 boxaCombineOverlaps

BOXA * boxaCombineOverlaps ( BOXA *boxas )

  boxaCombineOverlaps()

      Input:  boxas
      Return: boxad (where each set of boxes in boxas that overlap are
                     combined into a single bounding box in boxad), or
                     null on error.

  Notes:
      (1) If there are no overlapping boxes, it simply returns a copy
          of @boxas.
      (2) The alternative method of painting each rectanle and finding
          the 4-connected components gives the wrong result, because
          two non-overlapping rectangles, when rendered, can still
          be 4-connected, and hence they will be joined.
      (3) A bad case is to have n boxes, none of which overlap.
          Then you have one iteration with O(n^2) compares.  This
          is still faster than painting each rectangle and finding
          the connected components, even for thousands of rectangles.

=head2 boxaContainedInBox

BOXA * boxaContainedInBox ( BOXA *boxas, BOX *box )

  boxaContainedInBox()

      Input:  boxas
              box (for containment)
      Return: boxad (boxa with all boxes in boxas that are
                     entirely contained in box), or null on error

  Notes:
      (1) All boxes in boxa that are entirely outside box are removed.

=head2 boxaEqual

l_int32 boxaEqual ( BOXA *boxa1, BOXA *boxa2, l_int32 maxdist, NUMA **pnaindex, l_int32 *psame )

  boxaEqual()

      Input:  boxa1
              boxa2
              maxdist
              &naindex (<optional return> index array of correspondences
              &same (<return> 1 if equal; 0 otherwise)
      Return  0 if OK, 1 on error

  Notes:
      (1) The two boxa are the "same" if they contain the same
          boxes and each box is within @maxdist of its counterpart
          in their positions within the boxa.  This allows for
          small rearrangements.  Use 0 for maxdist if the boxa
          must be identical.
      (2) This applies only to geometry and ordering; refcounts
          are not considered.
      (3) @maxdist allows some latitude in the ordering of the boxes.
          For the boxa to be the "same", corresponding boxes must
          be within @maxdist of each other.  Note that for large
          @maxdist, we should use a hash function for efficiency.
      (4) naindex[i] gives the position of the box in boxa2 that
          corresponds to box i in boxa1.  It is only returned if the
          boxa are equal.

=head2 boxaGetNearestToPt

BOX * boxaGetNearestToPt ( BOXA *boxa, l_int32 x, l_int32 y )

  boxaGetNearestToPt()

      Input:  boxa
              x, y  (point)
      Return  box (box with centroid closest to the given point [x,y]),
              or NULL if no boxes in boxa)

  Notes:
      (1) Uses euclidean distance between centroid and point.

=head2 boxaHandleOverlaps

BOXA * boxaHandleOverlaps ( BOXA *boxas, l_int32 op, l_int32 range, l_float32 min_overlap, l_float32 max_ratio, NUMA **pnamap )

  boxaHandleOverlaps()

      Input:  boxas
              op (L_COMBINE, L_REMOVE_SMALL)
              range (> 0, forward distance over which overlaps are checked)
              min_overlap (minimum fraction of smaller box required for
                           overlap to count; 0.0 to ignore)
              max_ratio (maximum fraction of small/large areas for
                         overlap to count; 1.0 to ignore)
              &namap (<optional return> combining map)
      Return: boxad, or null on error.

  Notes:
      (1) For all n(n-1)/2 box pairings, if two boxes overlap, either:
          (a) op == L_COMBINE: get the bounding region for the two,
              replace the larger with the bounding region, and remove
              the smaller of the two, or
          (b) op == L_REMOVE_SMALL: just remove the smaller.
      (2) If boxas is 2D sorted, range can be small, but if it is
          not spatially sorted, range should be large to allow all
          pairwise comparisons to be made.
      (3) The @min_overlap parameter allows ignoring small overlaps.
          If @min_overlap == 1.0, only boxes fully contained in larger
          boxes can be considered for removal; if @min_overlap == 0.0,
          this constraint is ignored.
      (4) The @max_ratio parameter allows ignoring overlaps between
          boxes that are not too different in size.  If @max_ratio == 0.0,
          no boxes can be removed; if @max_ratio == 1.0, this constraint
          is ignored.

=head2 boxaIntersectsBox

BOXA * boxaIntersectsBox ( BOXA *boxas, BOX *box )

  boxaIntersectsBox()

      Input:  boxas
              box (for intersecting)
      Return  boxad (boxa with all boxes in boxas that intersect box),
                     or null on error

  Notes:
      (1) All boxes in boxa that intersect with box (i.e., are completely
          or partially contained in box) are retained.

=head2 boxaJoin

l_int32 boxaJoin ( BOXA *boxad, BOXA *boxas, l_int32 istart, l_int32 iend )

  boxaJoin()

      Input:  boxad  (dest boxa; add to this one)
              boxas  (source boxa; add from this one)
              istart  (starting index in boxas)
              iend  (ending index in boxas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This appends a clone of each indicated box in boxas to boxad
      (2) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (3) iend < 0 means 'read to the end'
      (4) if boxas == NULL or has no boxes, this is a no-op.

=head2 boxaMergeEvenOdd

BOXA * boxaMergeEvenOdd ( BOXA *boxae, BOXA *boxao, l_int32 fillflag )

  boxaMergeEvenOdd()

      Input:  boxae (boxes to go in even positions in merged boxa)
              boxao (boxes to go in odd positions in merged boxa)
              fillflag (1 if there are invalid boxes in placeholders)
      Return: boxad (merged), or null on error

  Notes:
      (1) This is essentially the inverse of boxaSplitEvenOdd().
          Typically, boxae and boxao were generated by boxaSplitEvenOdd(),
          and the value of @fillflag needs to be the same in both calls.
      (2) If @fillflag == 1, both boxae and boxao are of the same size;
          otherwise boxae may have one more box than boxao.

=head2 boxaSetSide

BOXA * boxaSetSide ( BOXA *boxad, BOXA *boxas, l_int32 side, l_int32 val, l_int32 thresh )

  boxaSetSide()

      Input:  boxad (use null to get a new one; same as boxas for in-place)
              boxas
              side (L_SET_LEFT, L_SET_RIGHT, L_SET_TOP, L_SET_BOT)
              val (location to set for given side, for each box)
              thresh (min abs difference to cause resetting to @val)
      Return: boxad, or null on error

  Notes:
      (1) Sets the given side of each box.  Use boxad == NULL for a new
          boxa, and boxad == boxas for in-place.
      (2) Use one of these:
               boxad = boxaSetSide(NULL, boxas, ...);   // new
               boxaSetSide(boxas, boxas, ...);  // in-place

=head2 boxaSimilar

l_int32 boxaSimilar ( BOXA *boxa1, BOXA *boxa2, l_int32 leftdiff, l_int32 rightdiff, l_int32 topdiff, l_int32 botdiff, l_int32 debugflag, l_int32 *psimilar )

  boxaSimilar()

      Input:  boxa1
              boxa2
              leftdiff, rightdiff, topdiff, botdiff
              debugflag (output details of non-similar boxes)
              &similar (<return> 1 if similar; 0 otherwise)
      Return  0 if OK, 1 on error

  Notes:
      (1) See boxSimilar() for parameter usage.
      (2) Corresponding boxes are taken in order in the two boxa.
      (3) With debugflag == 1, boxes continue to be tested after failure.

=head2 boxaSplitEvenOdd

l_int32 boxaSplitEvenOdd ( BOXA *boxa, l_int32 fillflag, BOXA **pboxae, BOXA **pboxao )

  boxaSplitEvenOdd()

      Input:  boxa
              fillflag (1 to put invalid boxes in place; 0 to omit)
              &boxae, &boxao (<return> save even and odd boxes in their
                 separate boxa, setting the other type to invalid boxes.)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @fillflag == 1, boxae has copies of the even boxes
          in their original location, and nvalid boxes are placed
          in the odd array locations.  And v.v.
      (2) If @fillflag == 0, boxae has only copies of the even boxes.

=head2 boxaaJoin

l_int32 boxaaJoin ( BOXAA *baad, BOXAA *baas, l_int32 istart, l_int32 iend )

  boxaaJoin()

      Input:  baad  (dest boxaa; add to this one)
              baas  (source boxaa; add from this one)
              istart  (starting index in baas)
              iend  (ending index in baas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This appends a clone of each indicated boxa in baas to baad
      (2) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (3) iend < 0 means 'read to the end'
      (4) if baas == NULL, this is a no-op.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
