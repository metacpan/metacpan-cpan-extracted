package Image::Leptonica::Func::morphapp;
$Image::Leptonica::Func::morphapp::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::morphapp

=head1 VERSION

version 0.04

=head1 C<morphapp.c>

  morphapp.c

      These are some useful and/or interesting composite
      image processing operations, of the type that are often
      useful in applications.  Most are morphological in
      nature.

      Extraction of boundary pixels
            PIX       *pixExtractBoundary()

      Selective morph sequence operation under mask
            PIX       *pixMorphSequenceMasked()

      Selective morph sequence operation on each component
            PIX       *pixMorphSequenceByComponent()
            PIXA      *pixaMorphSequenceByComponent()

      Selective morph sequence operation on each region
            PIX       *pixMorphSequenceByRegion()
            PIXA      *pixaMorphSequenceByRegion()

      Union and intersection of parallel composite operations
            PIX       *pixUnionOfMorphOps()
            PIX       *pixIntersectionOfMorphOps()

      Selective connected component filling
            PIX       *pixSelectiveConnCompFill()

      Removal of matched patterns
            PIX       *pixRemoveMatchedPattern()

      Display of matched patterns
            PIX       *pixDisplayMatchedPattern()

      Iterative morphological seed filling (don't use for real work)
            PIX       *pixSeedfillMorph()

      Granulometry on binary images
            NUMA      *pixRunHistogramMorph()

      Composite operations on grayscale images
            PIX       *pixTophat()
            PIX       *pixHDome()
            PIX       *pixFastTophat()
            PIX       *pixMorphGradient()

      Centroid of component
            PTA       *pixaCentroids()
            l_int32    pixCentroid()

=head1 FUNCTIONS

=head2 pixCentroid

l_int32 pixCentroid ( PIX *pix, l_int32 *centtab, l_int32 *sumtab, l_float32 *pxave, l_float32 *pyave )

  pixCentroid()

      Input:  pix (1 or 8 bpp)
              centtab (<optional> table for finding centroids; can be null)
              sumtab (<optional> table for finding pixel sums; can be null)
              &xave, &yave (<return> coordinates of centroid, relative to
                            the UL corner of the pix)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Any table not passed in will be made internally and destroyed
          after use.

=head2 pixDisplayMatchedPattern

PIX * pixDisplayMatchedPattern ( PIX *pixs, PIX *pixp, PIX *pixe, l_int32 x0, l_int32 y0, l_uint32 color, l_float32 scale, l_int32 nlevels )

  pixDisplayMatchedPattern()

      Input:  pixs (input image, 1 bpp)
              pixp (pattern to be removed from image, 1 bpp)
              pixe (image after erosion by Sel that approximates pixp, 1 bpp)
              x0, y0 (center of Sel)
              color (to paint the matched patterns; 0xrrggbb00)
              scale (reduction factor for output pixd)
              nlevels (if scale < 1.0, threshold to this number of levels)
      Return: pixd (8 bpp, colormapped), or null on error

  Notes:
    (1) A 4 bpp colormapped image is generated.
    (2) If scale <= 1.0, do scale to gray for the output, and threshold
        to nlevels of gray.
    (3) You can use various functions in selgen to create a Sel
        that will generate pixe from pixs.
    (4) This function is applied after pixe has been computed.
        It finds the centroid of each c.c., and colors the output
        pixels using pixp (appropriately aligned) as a stencil.
        Alignment is done using the origin of the Sel and the
        centroid of the eroded image to place the stencil pixp.

=head2 pixExtractBoundary

PIX * pixExtractBoundary ( PIX *pixs, l_int32 type )

  pixExtractBoundary()

      Input:  pixs (1 bpp)
              type (0 for background pixels; 1 for foreground pixels)
      Return: pixd, or null on error

  Notes:
      (1) Extracts the fg or bg boundary pixels for each component.
          Components are assumed to end at the boundary of pixs.

=head2 pixFastTophat

PIX * pixFastTophat ( PIX *pixs, l_int32 xsize, l_int32 ysize, l_int32 type )

  pixFastTophat()

      Input:  pixs
              xsize (width of max/min op, smoothing; any integer >= 1)
              ysize (height of max/min op, smoothing; any integer >= 1)
              type   (L_TOPHAT_WHITE: image - min
                      L_TOPHAT_BLACK: max - image)
      Return: pixd, or null on error

  Notes:
      (1) Don't be fooled. This is NOT a tophat.  It is a tophat-like
          operation, where the result is similar to what you'd get
          if you used an erosion instead of an opening, or a dilation
          instead of a closing.
      (2) Instead of opening or closing at full resolution, it does
          a fast downscale/minmax operation, then a quick small smoothing
          at low res, a replicative expansion of the "background"
          to full res, and finally a removal of the background level
          from the input image.  The smoothing step may not be important.
      (3) It does not remove noise as well as a tophat, but it is
          5 to 10 times faster.
          If you need the preciseness of the tophat, don't use this.
      (4) The L_TOPHAT_WHITE flag emphasizes small bright regions,
          whereas the L_TOPHAT_BLACK flag emphasizes small dark regions.

=head2 pixHDome

PIX * pixHDome ( PIX *pixs, l_int32 height, l_int32 connectivity )

  pixHDome()

      Input:  pixs (8 bpp, filling mask)
              height (of seed below the filling maskhdome; must be >= 0)
              connectivity (4 or 8)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) It is more efficient to use a connectivity of 4 for the fill.
      (2) This fills bumps to some level, and extracts the unfilled
          part of the bump.  To extract the troughs of basins, first
          invert pixs and then apply pixHDome().
      (3) It is useful to compare the HDome operation with the TopHat.
          The latter extracts peaks or valleys that have a width
          not exceeding the size of the structuring element used
          in the opening or closing, rsp.  The height of the peak is
          irrelevant.  By contrast, for the HDome, the gray seedfill
          is used to extract all peaks that have a height not exceeding
          a given value, regardless of their width!
      (4) Slightly more precisely, suppose you set 'height' = 40.
          Then all bumps in pixs with a height greater than or equal
          to 40 become, in pixd, bumps with a max value of exactly 40.
          All shorter bumps have a max value in pixd equal to the height
          of the bump.
      (5) The method: the filling mask, pixs, is the image whose peaks
          are to be extracted.  The height of a peak is the distance
          between the top of the peak and the highest "leak" to the
          outside -- think of a sombrero, where the leak occurs
          at the highest point on the rim.
            (a) Generate a seed, pixd, by subtracting some value, p, from
                each pixel in the filling mask, pixs.  The value p is
                the 'height' input to this function.
            (b) Fill in pixd starting with this seed, clipping by pixs,
                in the way described in seedfillGrayLow().  The filling
                stops before the peaks in pixs are filled.
                For peaks that have a height > p, pixd is filled to
                the level equal to the (top-of-the-peak - p).
                For peaks of height < p, the peak is left unfilled
                from its highest saddle point (the leak to the outside).
            (c) Subtract the filled seed (pixd) from the filling mask (pixs).
          Note that in this procedure, everything is done starting
          with the filling mask, pixs.
      (6) For segmentation, the resulting image, pixd, can be thresholded
          and used as a seed for another filling operation.

=head2 pixIntersectionOfMorphOps

PIX * pixIntersectionOfMorphOps ( PIX *pixs, SELA *sela, l_int32 type )

  pixIntersectionOfMorphOps()

      Input:  pixs (binary)
              sela
              type (L_MORPH_DILATE, etc.)
      Return: pixd (intersection of the specified morphological operation
                    on pixs for each Sel in the Sela), or null on error

=head2 pixMorphGradient

PIX * pixMorphGradient ( PIX *pixs, l_int32 hsize, l_int32 vsize, l_int32 smoothing )

  pixMorphGradient()

      Input:  pixs
              hsize (of Sel; must be odd; origin implicitly in center)
              vsize (ditto)
              smoothing  (half-width of convolution smoothing filter.
                          The width is (2 * smoothing + 1), so 0 is no-op.
      Return: pixd, or null on error

=head2 pixMorphSequenceByComponent

PIX * pixMorphSequenceByComponent ( PIX *pixs, const char *sequence, l_int32 connectivity, l_int32 minw, l_int32 minh, BOXA **pboxa )

  pixMorphSequenceByComponent()

      Input:  pixs (1 bpp)
              sequence (string specifying sequence)
              connectivity (4 or 8)
              minw  (minimum width to consider; use 0 or 1 for any width)
              minh  (minimum height to consider; use 0 or 1 for any height)
              &boxa (<optional> return boxa of c.c. in pixs)
      Return: pixd, or null on error

  Notes:
      (1) See pixMorphSequence() for composing operation sequences.
      (2) This operates separately on each c.c. in the input pix.
      (3) The dilation does NOT increase the c.c. size; it is clipped
          to the size of the original c.c.   This is necessary to
          keep the c.c. independent after the operation.
      (4) You can specify that the width and/or height must equal
          or exceed a minimum size for the operation to take place.
      (5) Use NULL for boxa to avoid returning the boxa.

=head2 pixMorphSequenceByRegion

PIX * pixMorphSequenceByRegion ( PIX *pixs, PIX *pixm, const char *sequence, l_int32 connectivity, l_int32 minw, l_int32 minh, BOXA **pboxa )

  pixMorphSequenceByRegion()

      Input:  pixs (1 bpp)
              pixm (mask specifying regions)
              sequence (string specifying sequence)
              connectivity (4 or 8, used on mask)
              minw  (minimum width to consider; use 0 or 1 for any width)
              minh  (minimum height to consider; use 0 or 1 for any height)
              &boxa (<optional> return boxa of c.c. in pixm)
      Return: pixd, or null on error

  Notes:
      (1) See pixMorphCompSequence() for composing operation sequences.
      (2) This operates separately on the region in pixs corresponding
          to each c.c. in the mask pixm.  It differs from
          pixMorphSequenceByComponent() in that the latter does not have
          a pixm (mask), but instead operates independently on each
          component in pixs.
      (3) Dilation will NOT increase the region size; the result
          is clipped to the size of the mask region.  This is necessary
          to make regions independent after the operation.
      (4) You can specify that the width and/or height of a region must
          equal or exceed a minimum size for the operation to take place.
      (5) Use NULL for @pboxa to avoid returning the boxa.

=head2 pixMorphSequenceMasked

PIX * pixMorphSequenceMasked ( PIX *pixs, PIX *pixm, const char *sequence, l_int32 dispsep )

  pixMorphSequenceMasked()

      Input:  pixs (1 bpp)
              pixm (<optional> 1 bpp mask)
              sequence (string specifying sequence of operations)
              dispsep (horizontal separation in pixels between
                       successive displays; use zero to suppress display)
      Return: pixd, or null on error

  Notes:
      (1) This applies the morph sequence to the image, but only allows
          changes in pixs for pixels under the background of pixm.
      (5) If pixm is NULL, this is just pixMorphSequence().

=head2 pixRemoveMatchedPattern

l_int32 pixRemoveMatchedPattern ( PIX *pixs, PIX *pixp, PIX *pixe, l_int32 x0, l_int32 y0, l_int32 dsize )

  pixRemoveMatchedPattern()

      Input:  pixs (input image, 1 bpp)
              pixp (pattern to be removed from image, 1 bpp)
              pixe (image after erosion by Sel that approximates pixp, 1 bpp)
              x0, y0 (center of Sel)
              dsize (number of pixels on each side by which pixp is
                     dilated before being subtracted from pixs;
                     valid values are {0, 1, 2, 3, 4})
      Return: 0 if OK, 1 on error

  Notes:
    (1) This is in-place.
    (2) You can use various functions in selgen to create a Sel
        that is used to generate pixe from pixs.
    (3) This function is applied after pixe has been computed.
        It finds the centroid of each c.c., and subtracts
        (the appropriately dilated version of) pixp, with the center
        of the Sel used to align pixp with pixs.

=head2 pixRunHistogramMorph

NUMA * pixRunHistogramMorph ( PIX *pixs, l_int32 runtype, l_int32 direction, l_int32 maxsize )

  pixRunHistogramMorph()

      Input:  pixs
              runtype (L_RUN_OFF, L_RUN_ON)
              direction (L_HORIZ, L_VERT)
              maxsize  (size of largest runlength counted)
      Return: numa of run-lengths

=head2 pixSeedfillMorph

PIX * pixSeedfillMorph ( PIX *pixs, PIX *pixm, l_int32 maxiters, l_int32 connectivity )

  pixSeedfillMorph()

      Input:  pixs (seed)
              pixm (mask)
              maxiters (use 0 to go to completion)
              connectivity (4 or 8)
      Return: pixd (after filling into the mask) or null on error

  Notes:
    (1) This is in general a very inefficient method for filling
        from a seed into a mask.  Use it for a small number of iterations,
        but if you expect more than a few iterations, use
        pixSeedfillBinary().
    (2) We use a 3x3 brick SEL for 8-cc filling and a 3x3 plus SEL for 4-cc.

=head2 pixSelectiveConnCompFill

PIX * pixSelectiveConnCompFill ( PIX *pixs, l_int32 connectivity, l_int32 minw, l_int32 minh )

  pixSelectiveConnCompFill()

      Input:  pixs (binary)
              connectivity (4 or 8)
              minw  (minimum width to consider; use 0 or 1 for any width)
              minh  (minimum height to consider; use 0 or 1 for any height)
      Return: pix (with holes filled in selected c.c.), or null on error

=head2 pixTophat

PIX * pixTophat ( PIX *pixs, l_int32 hsize, l_int32 vsize, l_int32 type )

  pixTophat()

      Input:  pixs
              hsize (of Sel; must be odd; origin implicitly in center)
              vsize (ditto)
              type   (L_TOPHAT_WHITE: image - opening
                      L_TOPHAT_BLACK: closing - image)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) If hsize = vsize = 1, returns an image with all 0 data.
      (3) The L_TOPHAT_WHITE flag emphasizes small bright regions,
          whereas the L_TOPHAT_BLACK flag emphasizes small dark regions.
          The L_TOPHAT_WHITE tophat can be accomplished by doing a
          L_TOPHAT_BLACK tophat on the inverse, or v.v.

=head2 pixUnionOfMorphOps

PIX * pixUnionOfMorphOps ( PIX *pixs, SELA *sela, l_int32 type )

  pixUnionOfMorphOps()

      Input:  pixs (binary)
              sela
              type (L_MORPH_DILATE, etc.)
      Return: pixd (union of the specified morphological operation
                    on pixs for each Sel in the Sela), or null on error

=head2 pixaCentroids

PTA * pixaCentroids ( PIXA *pixa )

  pixaCentroids()

      Input:  pixa of components (1 or 8 bpp)
      Return: pta of centroids relative to the UL corner of
              each pix, or null on error

  Notes:
      (1) An error message is returned if any pix has something other
          than 1 bpp or 8 bpp depth, and the centroid from that pix
          is saved as (0, 0).

=head2 pixaMorphSequenceByComponent

PIXA * pixaMorphSequenceByComponent ( PIXA *pixas, const char *sequence, l_int32 minw, l_int32 minh )

  pixaMorphSequenceByComponent()

      Input:  pixas (of 1 bpp pix)
              sequence (string specifying sequence)
              minw  (minimum width to consider; use 0 or 1 for any width)
              minh  (minimum height to consider; use 0 or 1 for any height)
      Return: pixad, or null on error

  Notes:
      (1) See pixMorphSequence() for composing operation sequences.
      (2) This operates separately on each c.c. in the input pixa.
      (3) You can specify that the width and/or height must equal
          or exceed a minimum size for the operation to take place.
      (4) The input pixa should have a boxa giving the locations
          of the pix components.

=head2 pixaMorphSequenceByRegion

PIXA * pixaMorphSequenceByRegion ( PIX *pixs, PIXA *pixam, const char *sequence, l_int32 minw, l_int32 minh )

  pixaMorphSequenceByRegion()

      Input:  pixs (1 bpp)
              pixam (of 1 bpp mask elements)
              sequence (string specifying sequence)
              minw  (minimum width to consider; use 0 or 1 for any width)
              minh  (minimum height to consider; use 0 or 1 for any height)
      Return: pixad, or null on error

  Notes:
      (1) See pixMorphSequence() for composing operation sequences.
      (2) This operates separately on each region in the input pixs
          defined by the components in pixam.
      (3) You can specify that the width and/or height of a mask
          component must equal or exceed a minimum size for the
          operation to take place.
      (4) The input pixam should have a boxa giving the locations
          of the regions in pixs.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
