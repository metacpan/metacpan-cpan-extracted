package Image::Leptonica::Func::boxfunc3;
$Image::Leptonica::Func::boxfunc3::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::boxfunc3

=head1 VERSION

version 0.04

=head1 C<boxfunc3.c>

   boxfunc3.c

      Boxa/Boxaa painting into pix
           PIX             *pixMaskConnComp()
           PIX             *pixMaskBoxa()
           PIX             *pixPaintBoxa()
           PIX             *pixSetBlackOrWhiteBoxa()
           PIX             *pixPaintBoxaRandom()
           PIX             *pixBlendBoxaRandom()
           PIX             *pixDrawBoxa()
           PIX             *pixDrawBoxaRandom()
           PIX             *boxaaDisplay()

      Split mask components into Boxa
           BOXA            *pixSplitIntoBoxa()
           BOXA            *pixSplitComponentIntoBoxa()
           static l_int32   pixSearchForRectangle()

      Comparison between boxa
           l_int32          boxaCompareRegions()

  See summary in pixPaintBoxa() of various ways to paint and draw
  boxes on images.

=head1 FUNCTIONS

=head2 boxaCompareRegions

l_int32 boxaCompareRegions ( BOXA *boxa1, BOXA *boxa2, l_int32 areathresh, l_int32 *pnsame, l_float32 *pdiffarea, l_float32 *pdiffxor, PIX **ppixdb )

  boxaCompareRegions()

      Input:  boxa1, boxa2
              areathresh (minimum area of boxes to be considered)
              &pnsame  (<return> true if same number of boxes)
              &pdiffarea (<return> fractional difference in total area)
              &pdiffxor (<optional return> fractional difference
                         in xor of regions)
              &pixdb (<optional return> debug pix showing two boxa)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This takes 2 boxa, removes all boxes smaller than a given area,
          and compares the remaining boxes between the boxa.
      (2) The area threshold is introduced to help remove noise from
          small components.  Any box with a smaller value of w * h
          will be removed from consideration.
      (3) The xor difference is the most stringent test, requiring alignment
          of the corresponding boxes.  It is also more computationally
          intensive and is optionally returned.  Alignment is to the
          UL corner of each region containing all boxes, as given by
          boxaGetExtent().
      (4) Both fractional differences are with respect to the total
          area in the two boxa.  They range from 0.0 to 1.0.
          A perfect match has value 0.0.  If both boxa are empty,
          we return 0.0; if one is empty we return 1.0.
      (5) An example input might be the rectangular regions of a
          segmentation mask for text or images from two pages.

=head2 boxaaDisplay

PIX * boxaaDisplay ( BOXAA *baa, l_int32 linewba, l_int32 linewb, l_uint32 colorba, l_uint32 colorb, l_int32 w, l_int32 h )

  boxaaDisplay()

      Input:  baa
              linewba (line width to display boxa)
              linewb (line width to display box)
              colorba (color to display boxa)
              colorb (color to display box)
              w (of pix; use 0 if determined by baa)
              h (of pix; use 0 if determined by baa)
      Return: 0 if OK, 1 on error

=head2 pixBlendBoxaRandom

PIX * pixBlendBoxaRandom ( PIX *pixs, BOXA *boxa, l_float32 fract )

  pixBlendBoxaRandom()

      Input:  pixs (any depth; can be cmapped)
              boxa (of boxes, to blend/paint)
              fract (of box color to use)
      Return: pixd (32 bpp, with blend/painted boxes), or null on error

  Notes:
      (1) pixs is converted to 32 bpp.
      (2) This differs from pixPaintBoxaRandom(), in that the
          colors here are blended with the color of pixs.
      (3) We use up to 254 different colors for painting the regions.
      (4) If boxes overlap, the final color depends only on the last
          rect that is used.

=head2 pixDrawBoxa

PIX * pixDrawBoxa ( PIX *pixs, BOXA *boxa, l_int32 width, l_uint32 val )

  pixDrawBoxa()

      Input:  pixs (any depth; can be cmapped)
              boxa (of boxes, to draw)
              width (of lines)
              val (rgba color to draw)
      Return: pixd (with outlines of boxes added), or null on error

  Notes:
      (1) If pixs is 1 bpp or is colormapped, it is converted to 8 bpp
          and the boxa is drawn using a colormap; otherwise,
          it is converted to 32 bpp rgb.

=head2 pixDrawBoxaRandom

PIX * pixDrawBoxaRandom ( PIX *pixs, BOXA *boxa, l_int32 width )

  pixDrawBoxaRandom()

      Input:  pixs (any depth, can be cmapped)
              boxa (of boxes, to draw)
              width (thickness of line)
      Return: pixd (with box outlines drawn), or null on error

  Notes:
      (1) If pixs is 1 bpp, we draw the boxa using a colormap;
          otherwise, we convert to 32 bpp.
      (2) We use up to 254 different colors for drawing the boxes.
      (3) If boxes overlap, the later ones draw over earlier ones.

=head2 pixMaskBoxa

PIX * pixMaskBoxa ( PIX *pixd, PIX *pixs, BOXA *boxa, l_int32 op )

  pixMaskBoxa()

      Input:  pixd (<optional> may be null)
              pixs (any depth; not cmapped)
              boxa (of boxes, to paint)
              op (L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: pixd (with masking op over the boxes), or null on error

  Notes:
      (1) This can be used with:
              pixd = NULL  (makes a new pixd)
              pixd = pixs  (in-place)
      (2) If pixd == NULL, this first makes a copy of pixs, and then
          bit-twiddles over the boxes.  Otherwise, it operates directly
          on pixs.
      (3) This simple function is typically used with 1 bpp images.
          It uses the 1-image rasterop function, rasteropUniLow(),
          to set, clear or flip the pixels in pixd.
      (4) If you want to generate a 1 bpp mask of ON pixels from the boxes
          in a Boxa, in a pix of size (w,h):
              pix = pixCreate(w, h, 1);
              pixMaskBoxa(pix, pix, boxa, L_SET_PIXELS);

=head2 pixMaskConnComp

PIX * pixMaskConnComp ( PIX *pixs, l_int32 connectivity, BOXA **pboxa )

  pixMaskConnComp()

      Input:  pixs (1 bpp)
              connectivity (4 or 8)
              &boxa (<optional return> bounding boxes of c.c.)
      Return: pixd (1 bpp mask over the c.c.), or null on error

  Notes:
      (1) This generates a mask image with ON pixels over the
          b.b. of the c.c. in pixs.  If there are no ON pixels in pixs,
          pixd will also have no ON pixels.

=head2 pixPaintBoxa

PIX * pixPaintBoxa ( PIX *pixs, BOXA *boxa, l_uint32 val )

  pixPaintBoxa()

      Input:  pixs (any depth, can be cmapped)
              boxa (of boxes, to paint)
              val (rgba color to paint)
      Return: pixd (with painted boxes), or null on error

  Notes:
      (1) If pixs is 1 bpp or is colormapped, it is converted to 8 bpp
          and the boxa is painted using a colormap; otherwise,
          it is converted to 32 bpp rgb.
      (2) There are several ways to display a box on an image:
            * Paint it as a solid color
            * Draw the outline
            * Blend the outline or region with the existing image
          We provide painting and drawing here; blending is in blend.c.
          When painting or drawing, the result can be either a
          cmapped image or an rgb image.  The dest will be cmapped
          if the src is either 1 bpp or has a cmap that is not full.
          To force RGB output, use pixConvertTo8(pixs, FALSE)
          before calling any of these paint and draw functions.

=head2 pixPaintBoxaRandom

PIX * pixPaintBoxaRandom ( PIX *pixs, BOXA *boxa )

  pixPaintBoxaRandom()

      Input:  pixs (any depth, can be cmapped)
              boxa (of boxes, to paint)
      Return: pixd (with painted boxes), or null on error

  Notes:
      (1) If pixs is 1 bpp, we paint the boxa using a colormap;
          otherwise, we convert to 32 bpp.
      (2) We use up to 254 different colors for painting the regions.
      (3) If boxes overlap, the later ones paint over earlier ones.

=head2 pixSetBlackOrWhiteBoxa

PIX * pixSetBlackOrWhiteBoxa ( PIX *pixs, BOXA *boxa, l_int32 op )

  pixSetBlackOrWhiteBoxa()

      Input:  pixs (any depth, can be cmapped)
              boxa (<optional> of boxes, to clear or set)
              op (L_SET_BLACK, L_SET_WHITE)
      Return: pixd (with boxes filled with white or black), or null on error

=head2 pixSplitComponentIntoBoxa

BOXA * pixSplitComponentIntoBoxa ( PIX *pix, BOX *box, l_int32 minsum, l_int32 skipdist, l_int32 delta, l_int32 maxbg, l_int32 maxcomps, l_int32 remainder )

  pixSplitComponentIntoBoxa()

      Input:  pixs (1 bpp)
              box (<optional> location of pixs w/rt an origin)
              minsum  (minimum pixels to trigger propagation)
              skipdist (distance before computing sum for propagation)
              delta (difference required to stop propagation)
              maxbg (maximum number of allowed bg pixels in ref scan)
              maxcomps (use 0 for unlimited number of subdivided components)
              remainder (set to 1 to get b.b. of remaining stuff)
      Return: boxa (of rectangles covering the fg of pixs), or null on error

  Notes:
      (1) This generates a boxa of rectangles that covers
          the fg of a mask.  It does so by a greedy partitioning of
          the mask, choosing the largest rectangle found from
          each of the four directions at each step.
      (2) The input parameters give some flexibility for boundary
          noise.  The resulting set of rectangles must cover all
          the fg pixels and, in addition, may cover some bg pixels.
          Using small input parameters on a noiseless mask (i.e., one
          that has only large vertical and horizontal edges) will
          result in a proper covering of only the fg pixels of the mask.
      (3) The input is assumed to be a single connected component, that
          may have holes.  From each side, sweep inward, counting
          the pixels.  If the count becomes greater than @minsum,
          and we have moved forward a further amount @skipdist,
          record that count ('countref'), but don't accept if the scan
          contains more than @maxbg bg pixels.  Continue the scan
          until we reach a count that differs from countref by at
          least @delta, at which point the propagation stops.  The box
          swept out gets a score, which is the sum of fg pixels
          minus a penalty.  The penalty is the number of bg pixels
          in the box.  This is done from all four sides, and the
          side with the largest score is saved as a rectangle.
          The process repeats until there is either no rectangle
          left, or there is one that can't be captured from any
          direction.  For the latter case, we simply accept the
          last rectangle.
      (4) The input box is only used to specify the location of
          the UL corner of pixs, with respect to an origin that
          typically represents the UL corner of an underlying image,
          of which pixs is one component.  If @box is null,
          the UL corner is taken to be (0, 0).
      (5) The parameter @maxcomps gives the maximum number of allowed
          rectangles extracted from any single connected component.
          Use 0 if no limit is to be applied.
      (6) The flag @remainder specifies whether we take a final bounding
          box for anything left after the maximum number of allowed
          rectangle is extracted.
      (7) So if @maxcomps > 0, it specifies that we want no more than
          the first @maxcomps rectangles that satisfy the input
          criteria.  After this, we can get a final rectangle that
          bounds everything left over by setting @remainder == 1.
          If @remainder == 0, we only get rectangles that satisfy
          the input criteria.
      (8) It should be noted that the removal of rectangles can
          break the original c.c. into several c.c.
      (9) Summing up:
            * If @maxcomp == 0, the splitting proceeds as far as possible.
            * If @maxcomp > 0, the splitting stops when @maxcomps are
                found, or earlier if no more components can be selected.
            * If @remainder == 1 and components remain that cannot be
                selected, they are returned as a single final rectangle;
                otherwise, they are ignored.

=head2 pixSplitIntoBoxa

BOXA * pixSplitIntoBoxa ( PIX *pixs, l_int32 minsum, l_int32 skipdist, l_int32 delta, l_int32 maxbg, l_int32 maxcomps, l_int32 remainder )

  pixSplitIntoBoxa()

      Input:  pixs (1 bpp)
              minsum  (minimum pixels to trigger propagation)
              skipdist (distance before computing sum for propagation)
              delta (difference required to stop propagation)
              maxbg (maximum number of allowed bg pixels in ref scan)
              maxcomps (use 0 for unlimited number of subdivided components)
              remainder (set to 1 to get b.b. of remaining stuff)
      Return: boxa (of rectangles covering the fg of pixs), or null on error

  Notes:
      (1) This generates a boxa of rectangles that covers
          the fg of a mask.  For each 8-connected component in pixs,
          it does a greedy partitioning, choosing the largest
          rectangle found from each of the four directions at each iter.
          See pixSplitComponentIntoBoxa() for details.
      (2) The input parameters give some flexibility for boundary
          noise.  The resulting set of rectangles may cover some
          bg pixels.
      (3) This should be used when there are a small number of
          mask components, each of which has sides that are close
          to horizontal and vertical.  The input parameters @delta
          and @maxbg determine whether or not holes in the mask are covered.
      (4) The parameter @maxcomps gives the maximum number of allowed
          rectangles extracted from any single connected component.
          Use 0 if no limit is to be applied.
      (5) The flag @remainder specifies whether we take a final bounding
          box for anything left after the maximum number of allowed
          rectangle is extracted.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
