package Image::Leptonica::Func::selgen;
$Image::Leptonica::Func::selgen::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::selgen

=head1 VERSION

version 0.04

=head1 C<selgen.c>

  selgen.c

      This file contains functions that generate hit-miss Sels
      for doing a loose match to a small bitmap.  The hit-miss
      Sel is made from a given bitmap.  Several "knobs"
      are available to control the looseness of the match.
      In general, a tight match will have fewer false positives
      (bad matches) but more false negatives (missed patterns).
      The values to be used depend on the quality and variation
      of the image in which the pattern is to be searched,
      and the relative penalties of false positives and
      false negatives.  Default values for the three knobs --
      minimum distance to boundary pixels, number of extra pixels
      added to selected sides, and minimum acceptable runlength
      in eroded version -- are provided.

      The generated hit-miss Sels can always be used in the
      rasterop implementation of binary morphology (in morph.h).
      If they are small enough (not more than 31 pixels extending
      in any direction from the Sel origin), they can also be used
      to auto-generate dwa code (fmorphauto.c).


      Generate a subsampled structuring element
            SEL     *pixGenerateSelWithRuns()
            SEL     *pixGenerateSelRandom()
            SEL     *pixGenerateSelBoundary()

      Accumulate data on runs along lines
            NUMA    *pixGetRunCentersOnLine()
            NUMA    *pixGetRunsOnLine()

      Subsample boundary pixels in relatively ordered way
            PTA     *pixSubsampleBoundaryPixels()
            PTA     *adjacentOnPixelInRaster()

      Display generated sel with originating image
            PIX     *pixDisplayHitMissSel()

=head1 FUNCTIONS

=head2 adjacentOnPixelInRaster

l_int32 adjacentOnPixelInRaster ( PIX *pixs, l_int32 x, l_int32 y, l_int32 *pxa, l_int32 *pya )

  adjacentOnPixelInRaster()

      Input:  pixs (1 bpp)
              x, y (current pixel)
              xa, ya (adjacent ON pixel, found by simple CCW search)
      Return: 1 if a pixel is found; 0 otherwise or on error

  Notes:
      (1) Search is in 4-connected directions first; then on diagonals.
          This allows traversal along a 4-connected boundary.

=head2 pixDisplayHitMissSel

PIX * pixDisplayHitMissSel ( PIX *pixs, SEL *sel, l_int32 scalefactor, l_uint32 hitcolor, l_uint32 misscolor )

  pixDisplayHitMissSel()

      Input:  pixs (1 bpp)
              sel (hit-miss in general)
              scalefactor (an integer >= 1; use 0 for default)
              hitcolor (RGB0 color for center of hit pixels)
              misscolor (RGB0 color for center of miss pixels)
      Return: pixd (RGB showing both pixs and sel), or null on error
  Notes:
    (1) We don't allow scalefactor to be larger than MAX_SEL_SCALEFACTOR
    (2) The colors are conveniently given as 4 bytes in hex format,
        such as 0xff008800.  The least significant byte is ignored.

=head2 pixGenerateSelBoundary

SEL * pixGenerateSelBoundary ( PIX *pixs, l_int32 hitdist, l_int32 missdist, l_int32 hitskip, l_int32 missskip, l_int32 topflag, l_int32 botflag, l_int32 leftflag, l_int32 rightflag, PIX **ppixe )

  pixGenerateSelBoundary()

      Input:  pix (1 bpp, typically small, to be used as a pattern)
              hitdist (min distance from fg boundary pixel)
              missdist (min distance from bg boundary pixel)
              hitskip (number of boundary pixels skipped between hits)
              missskip (number of boundary pixels skipped between misses)
              topflag (flag for extra pixels of bg added above)
              botflag (flag for extra pixels of bg added below)
              leftflag (flag for extra pixels of bg added to left)
              rightflag (flag for extra pixels of bg added to right)
              &pixe (<optional return> input pix expanded by extra pixels)
      Return: sel (hit-miss for input pattern), or null on error

  Notes:
    (1) All fg elements selected are exactly hitdist pixels away from
        the nearest fg boundary pixel, and ditto for bg elements.
        Valid inputs of hitdist and missdist are 0, 1, 2, 3 and 4.
        For example, a hitdist of 0 puts the hits at the fg boundary.
        Usually, the distances should be > 0 avoid the effect of
        noise at the boundary.
    (2) Set hitskip < 0 if no hits are to be used.  Ditto for missskip.
        If both hitskip and missskip are < 0, the sel would be empty,
        and NULL is returned.
    (3) The 4 flags determine whether the sel is increased on that side
        to allow bg misses to be placed all along that boundary.
        The increase in sel size on that side is the minimum necessary
        to allow the misses to be placed at mindist.  For text characters,
        the topflag and botflag are typically set to 1, and the leftflag
        and rightflag to 0.
    (4) The input pix, as extended by the extra pixels on selected sides,
        can optionally be returned.  For debugging, call
        pixDisplayHitMissSel() to visualize the hit-miss sel superimposed
        on the generating bitmap.
    (5) This is probably the best of the three sel generators, in the
        sense that you have the most flexibility with the smallest number
        of hits and misses.

=head2 pixGenerateSelRandom

SEL * pixGenerateSelRandom ( PIX *pixs, l_float32 hitfract, l_float32 missfract, l_int32 distance, l_int32 toppix, l_int32 botpix, l_int32 leftpix, l_int32 rightpix, PIX **ppixe )

  pixGenerateSelRandom()

      Input:  pix (1 bpp, typically small, to be used as a pattern)
              hitfract (fraction of allowable fg pixels that are hits)
              missfract (fraction of allowable bg pixels that are misses)
              distance (min distance from boundary pixel; use 0 for default)
              toppix (number of extra pixels of bg added above)
              botpix (number of extra pixels of bg added below)
              leftpix (number of extra pixels of bg added to left)
              rightpix (number of extra pixels of bg added to right)
              &pixe (<optional return> input pix expanded by extra pixels)
      Return: sel (hit-miss for input pattern), or null on error

  Notes:
    (1) Either of hitfract and missfract can be zero.  If both are zero,
        the sel would be empty, and NULL is returned.
    (2) No elements are selected that are less than 'distance' pixels away
        from a boundary pixel of the same color.  This makes the
        match much more robust to edge noise.  Valid inputs of
        'distance' are 0, 1, 2, 3 and 4.  If distance is either 0 or
        greater than 4, we reset it to the default value.
    (3) The 4 numbers for adding rectangles of pixels outside the fg
        can be use if the pattern is expected to be surrounded by bg
        (white) pixels.  On the other hand, if the pattern may be near
        other fg (black) components on some sides, use 0 for those sides.
    (4) The input pix, as extended by the extra pixels on selected sides,
        can optionally be returned.  For debugging, call
        pixDisplayHitMissSel() to visualize the hit-miss sel superimposed
        on the generating bitmap.

=head2 pixGenerateSelWithRuns

SEL * pixGenerateSelWithRuns ( PIX *pixs, l_int32 nhlines, l_int32 nvlines, l_int32 distance, l_int32 minlength, l_int32 toppix, l_int32 botpix, l_int32 leftpix, l_int32 rightpix, PIX **ppixe )

  pixGenerateSelWithRuns()

      Input:  pix (1 bpp, typically small, to be used as a pattern)
              nhlines (number of hor lines along which elements are found)
              nvlines (number of vert lines along which elements are found)
              distance (min distance from boundary pixel; use 0 for default)
              minlength (min runlength to set hit or miss; use 0 for default)
              toppix (number of extra pixels of bg added above)
              botpix (number of extra pixels of bg added below)
              leftpix (number of extra pixels of bg added to left)
              rightpix (number of extra pixels of bg added to right)
              &pixe (<optional return> input pix expanded by extra pixels)
      Return: sel (hit-miss for input pattern), or null on error

  Notes:
    (1) The horizontal and vertical lines along which elements are
        selected are roughly equally spaced.  The actual locations of
        the hits and misses are the centers of respective run-lengths.
    (2) No elements are selected that are less than 'distance' pixels away
        from a boundary pixel of the same color.  This makes the
        match much more robust to edge noise.  Valid inputs of
        'distance' are 0, 1, 2, 3 and 4.  If distance is either 0 or
        greater than 4, we reset it to the default value.
    (3) The 4 numbers for adding rectangles of pixels outside the fg
        can be use if the pattern is expected to be surrounded by bg
        (white) pixels.  On the other hand, if the pattern may be near
        other fg (black) components on some sides, use 0 for those sides.
    (4) The pixels added to a side allow you to have miss elements there.
        There is a constraint between distance, minlength, and
        the added pixels for this to work.  We illustrate using the
        default values.  If you add 5 pixels to the top, and use a
        distance of 1, then you end up with a vertical run of at least
        4 bg pixels along the top edge of the image.  If you use a
        minimum runlength of 3, each vertical line will always find
        a miss near the center of its run.  However, if you use a
        minimum runlength of 5, you will not get a miss on every vertical
        line.  As another example, if you have 7 added pixels and a
        distance of 2, you can use a runlength up to 5 to guarantee
        that the miss element is recorded.  We give a warning if the
        contraint does not guarantee a miss element outside the
        image proper.
    (5) The input pix, as extended by the extra pixels on selected sides,
        can optionally be returned.  For debugging, call
        pixDisplayHitMissSel() to visualize the hit-miss sel superimposed
        on the generating bitmap.

=head2 pixGetRunCentersOnLine

NUMA * pixGetRunCentersOnLine ( PIX *pixs, l_int32 x, l_int32 y, l_int32 minlength )

  pixGetRunCentersOnLine()

      Input:  pixs (1 bpp)
              x, y (set one of these to -1; see notes)
              minlength (minimum length of acceptable run)
      Return: numa of fg runs, or null on error

  Notes:
      (1) Action: this function computes the fg (black) and bg (white)
          pixel runlengths along the specified horizontal or vertical line,
          and returns a Numa of the "center" pixels of each fg run
          whose length equals or exceeds the minimum length.
      (2) This only works on horizontal and vertical lines.
      (3) For horizontal runs, set x = -1 and y to the value
          for all points along the raster line.  For vertical runs,
          set y = -1 and x to the value for all points along the
          pixel column.
      (4) For horizontal runs, the points in the Numa are the x
          values in the center of fg runs that are of length at
          least 'minlength'.  For vertical runs, the points in the
          Numa are the y values in the center of fg runs, again
          of length 'minlength' or greater.
      (5) If there are no fg runs along the line that satisfy the
          minlength constraint, the returned Numa is empty.  This
          is not an error.

=head2 pixGetRunsOnLine

NUMA * pixGetRunsOnLine ( PIX *pixs, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2 )

  pixGetRunsOnLine()

      Input:  pixs (1 bpp)
              x1, y1, x2, y2
      Return: numa, or null on error

  Notes:
      (1) Action: this function uses the bresenham algorithm to compute
          the pixels along the specified line.  It returns a Numa of the
          runlengths of the fg (black) and bg (white) runs, always
          starting with a white run.
      (2) If the first pixel on the line is black, the length of the
          first returned run (which is white) is 0.

=head2 pixSubsampleBoundaryPixels

PTA * pixSubsampleBoundaryPixels ( PIX *pixs, l_int32 skip )

  pixSubsampleBoundaryPixels()

      Input:  pixs (1 bpp, with only boundary pixels in fg)
              skip (number to skip between samples as you traverse boundary)
      Return: pta, or null on error

  Notes:
      (1) If skip = 0, we take all the fg pixels.
      (2) We try to traverse the boundaries in a regular way.
          Some pixels may be missed, and these are then subsampled
          randomly with a fraction determined by 'skip'.
      (3) The most natural approach is to use a depth first (stack-based)
          method to find the fg pixels.  However, the pixel runs are
          4-connected and there are relatively few branches.  So
          instead of doing a proper depth-first search, we get nearly
          the same result using two nested while loops: the outer
          one continues a raster-based search for the next fg pixel,
          and the inner one does a reasonable job running along
          each 4-connected coutour.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
