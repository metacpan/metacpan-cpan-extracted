package Image::Leptonica::Func::colorquant2;
$Image::Leptonica::Func::colorquant2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::colorquant2

=head1 VERSION

version 0.04

=head1 C<colorquant2.c>

  colorquant2.c

  Modified median cut color quantization

      High level
          PIX              *pixMedianCutQuant()
          PIX              *pixMedianCutQuantGeneral()
          PIX              *pixMedianCutQuantMixed()
          PIX              *pixFewColorsMedianCutQuantMixed()

      Median cut indexed histogram
          l_int32          *pixMedianCutHisto()

      Static helpers
          static PIXCMAP   *pixcmapGenerateFromHisto()
          static PIX       *pixQuantizeWithColormap()
          static void       getColorIndexMedianCut()
          static L_BOX3D   *pixGetColorRegion()
          static l_int32    medianCutApply()
          static PIXCMAP   *pixcmapGenerateFromMedianCuts()
          static l_int32    vboxGetAverageColor()
          static l_int32    vboxGetCount()
          static l_int32    vboxGetVolume()
          static L_BOX3D   *box3dCreate();
          static L_BOX3D   *box3dCopy();

   Paul Heckbert published the median cut algorithm, "Color Image
   Quantization for Frame Buffer Display," in Proc. SIGGRAPH '82,
   Boston, July 1982, pp. 297-307.  A copy of the paper without
   figures can be found on the web.

   Median cut starts with either the full color space or the occupied
   region of color space.  If you're not dithering, the occupied region
   can be used, but with dithering, pixels can end up in any place
   in the color space, so you must represent the entire color space in
   the final colormap.

   Color components are quantized to typically 5 or 6 significant
   bits (for each of r, g and b).   Call a 3D region of color
   space a 'vbox'.  Any color in this quantized space is represented
   by an element of a linear histogram array, indexed by rgb value.
   The initial region is then divided into two regions that have roughly
   equal pixel occupancy (hence the name "median cut").  Subdivision
   continues until the requisite number of vboxes has been generated.

   But the devil is in the details of the subdivision process.
   Here are some choices that you must make:
     (1) Along which axis to subdivide?
     (2) Which box to put the bin with the median pixel?
     (3) How to order the boxes for subdivision?
     (4) How to adequately handle boxes with very small numbers of pixels?
     (5) How to prevent a little-represented but highly visible color
         from being masked out by other colors in its vbox.

   Taking these in order:
     (1) Heckbert suggests using either the largest vbox side, or the vbox
         side with the largest variance in pixel occupancy.  We choose
         to divide based on the largest vbox side.
     (2) Suppose you've chosen a side.  Then you have a histogram
         of pixel occupancy in 2D slices of the vbox.  One of those
         slices includes the median pixel.  Suppose there are L bins
         to the left (smaller index) and R bins to the right.  Then
         this slice (or bin) should be assigned to the box containing
         the smaller of L and R.  This both shortens the larger
         of the subdivided dimensions and helps a low-count color
         far from the subdivision boundary to better express itself.
     (2a) One can also ask if the boundary should be moved even
         farther into the longer side.  This is feasable if we have
         a method for doing extra subdivisions on the high count
         vboxes.  And we do (see (3)).
     (3) To make sure that the boxes are subdivided toward equal
         occupancy, use an occupancy-sorted priority queue, rather
         than a simple queue.
     (4) With a priority queue, boxes with small number of pixels
         won't be repeatedly subdivided.  This is good.
     (5) Use of a priority queue allows tricks such as in (2a) to let
         small occupancy clusters be better expressed.  In addition,
         rather than splitting near the median, small occupancy colors
         are best reproduced by cutting half-way into the longer side.

   However, serious problems can arise with dithering if a priority
   queue is used based on population alone.  If the picture has
   large regions of nearly constant color, some vboxes can be very
   large and have a sizeable population (but not big enough to get to
   the head of the queue).  If one of these large, occupied vboxes
   is near in color to a nearly constant color region of the
   image, dithering can inject pixels from the large vbox into
   the nearly uniform region.  These pixels can be very far away
   in color, and the oscillations are highly visible.  To prevent
   this, we can take either or both of these actions:

     (1) Subdivide a fraction (< 1.0) based on population, and
         do the rest of the subdivision based on the product of
         the vbox volume and its population.  By using the product,
         we avoid further subdivision of nearly empty vboxes, and
         directly target large vboxes with significant population.

     (2) Threshold the excess color transferred in dithering to
         neighboring pixels.

   Doing either of these will stop the most annoying oscillations
   in dithering.  Furthermore, by doing (1), we also improve the
   rendering of regions of nearly constant color, both with and
   without dithering.  It turns out that the image quality is
   not sensitive to the value of the parameter in (1); values
   between 0.3 and 0.9 give very good results.

   Here's the lesson: subdivide the color space into vboxes such
   that (1) the most populated vboxes that can be further
   subdivided (i.e., that occupy more than one quantum volume
   in color space) all have approximately the same population,
   and (2) all large vboxes have no significant population.
   If these conditions are met, the quantization will be excellent.

   Once the subdivision has been made, the colormap is generated,
   with one color for each vbox and using the average color in the vbox.
   At the same time, the histogram array is converted to an inverse
   colormap table, storing the colormap index in every cell in the
   vbox.  Finally, using both the colormap and the inverse colormap,
   a colormapped pix is quickly generated from the original rgb pix.

   In the present implementation, subdivided regions of colorspace
   that are not occupied are retained, but not further subdivided.
   This is required for our inverse colormap lookup table for
   dithering, because dithered pixels may fall into these unoccupied
   regions.  For such empty regions, we use the center as the rgb
   colormap value.

   This variation on median cut can be referred to as "Modified Median
   Cut" quantization, or MMCQ.  Overall, the undithered MMCQ gives
   comparable results to the two-pass Octcube Quantizer (OQ).
   Comparing the two methods on the test24.jpg painting, we see:

     (1) For rendering spot color (the various reds and pinks in
         the image), MMCQ is not as good as OQ.

     (2) For rendering majority color regions, MMCQ does a better
         job of avoiding posterization.  That is, it does better
         dividing the color space up in the most heavily populated regions.

=head1 FUNCTIONS

=head2 pixFewColorsMedianCutQuantMixed

PIX * pixFewColorsMedianCutQuantMixed ( PIX *pixs, l_int32 ncolor, l_int32 ngray, l_int32 maxncolors, l_int32 darkthresh, l_int32 lightthresh, l_int32 diffthresh )

  pixFewColorsMedianCutQuantMixed()

      Input:  pixs (32 bpp rgb)
              ncolor (number of colors to be assigned to pixels with
                       significant color)
              ngray (number of gray colors to be used; must be >= 2)
              maxncolors (maximum number of colors to be returned
                         from pixColorsForQuantization(); use 0 for default)
              darkthresh (threshold near black; if the lightest component
                          is below this, the pixel is not considered to
                          be gray or color; use 0 for default)
              lightthresh (threshold near white; if the darkest component
                           is above this, the pixel is not considered to
                           be gray or color; use 0 for default)
              diffthresh (thresh for the max difference between component
                          values; for differences below this, the pixel
                          is considered to be gray; use 0 for default)
                          considered gray; use 0 for default)
      Return: pixd (8 bpp, median cut quantized for pixels that are
                    not gray; gray pixels are quantized separately
                    over the full gray range); null if too many colors
                    or on error

  Notes:
      (1) This is the "few colors" version of pixMedianCutQuantMixed().
          It fails (returns NULL) if it finds more than maxncolors, but
          otherwise it gives the same result.
      (2) Recommended input parameters are:
              @maxncolors:  20
              @darkthresh:  20
              @lightthresh: 244
              @diffthresh:  15  (any higher can miss colors differing
                                 slightly from gray)
      (3) Both ncolor and ngray should be at least equal to maxncolors.
          If they're not, they are automatically increased, and a
          warning is given.
      (4) If very little color content is found, the input is
          converted to gray and quantized in equal intervals.
      (5) This can be useful for quantizing orthographically generated
          images such as color maps, where there may be more than 256 colors
          because of aliasing or jpeg artifacts on text or lines, but
          there are a relatively small number of solid colors.
      (6) Example of usage:
             // Try to quantize, using default values for mixed med cut
             Pix *pixq = pixFewColorsMedianCutQuantMixed(pixs, 100, 20,
                             0, 0, 0, 0);
             if (!pixq)  // too many colors; don't quantize
                 pixq = pixClone(pixs);

=head2 pixMedianCutHisto

l_int32 * pixMedianCutHisto ( PIX *pixs, l_int32 sigbits, l_int32 subsample )

  pixMedianCutHisto()

      Input:  pixs  (32 bpp; rgb color)
              sigbits (valid: 5 or 6)
              subsample (integer > 0)
      Return: histo (1-d array, giving the number of pixels in
                     each quantized region of color space), or null on error

  Notes:
      (1) Array is indexed by (3 * sigbits) bits.  The array size
          is 2^(3 * sigbits).
      (2) Indexing into the array from rgb uses red sigbits as
          most significant and blue as least.

=head2 pixMedianCutQuant

PIX * pixMedianCutQuant ( PIX *pixs, l_int32 ditherflag )

  pixMedianCutQuant()

      Input:  pixs  (32 bpp; rgb color)
              ditherflag (1 for dither; 0 for no dither)
      Return: pixd (8 bit with colormap), or null on error

  Notes:
      (1) Simple interface.  See pixMedianCutQuantGeneral() for
          use of defaulted parameters.

=head2 pixMedianCutQuantGeneral

PIX * pixMedianCutQuantGeneral ( PIX *pixs, l_int32 ditherflag, l_int32 outdepth, l_int32 maxcolors, l_int32 sigbits, l_int32 maxsub, l_int32 checkbw )

  pixMedianCutQuantGeneral()

      Input:  pixs  (32 bpp; rgb color)
              ditherflag (1 for dither; 0 for no dither)
              outdepth (output depth; valid: 0, 1, 2, 4, 8)
              maxcolors (between 2 and 256)
              sigbits (valid: 5 or 6; use 0 for default)
              maxsub (max subsampling, integer; use 0 for default;
                      1 for no subsampling)
              checkbw (1 to check if color content is very small,
                       0 to assume there is sufficient color)
      Return: pixd (8 bit with colormap), or null on error

  Notes:
      (1) @maxcolors must be in the range [2 ... 256].
      (2) Use @outdepth = 0 to have the output depth computed as the
          minimum required to hold the actual colors found, given
          the @maxcolors constraint.
      (3) Use @outdepth = 1, 2, 4 or 8 to specify the output depth.
          In that case, @maxcolors must not exceed 2^(outdepth).
      (4) If there are fewer quantized colors in the image than @maxcolors,
          the colormap is simply generated from those colors.
      (5) @maxsub is the maximum allowed subsampling to be used in the
          computation of the color histogram and region of occupied
          color space.  The subsampling is chosen internally for
          efficiency, based on the image size, but this parameter
          limits it.  Use @maxsub = 0 for the internal default, which is the
          maximum allowed subsampling.  Use @maxsub = 1 to prevent
          subsampling.  In general use @maxsub >= 1 to specify the
          maximum subsampling to be allowed, where the actual subsampling
          will be the minimum of this value and the internally
          determined default value.
      (6) If the image appears gray because either most of the pixels
          are gray or most of the pixels are essentially black or white,
          the image is trivially quantized with a grayscale colormap.  The
          reason is that median cut divides the color space into rectangular
          regions, and it does a very poor job if all the pixels are
          near the diagonal of the color space cube.

=head2 pixMedianCutQuantMixed

PIX * pixMedianCutQuantMixed ( PIX *pixs, l_int32 ncolor, l_int32 ngray, l_int32 darkthresh, l_int32 lightthresh, l_int32 diffthresh )

  pixMedianCutQuantMixed()

      Input:  pixs  (32 bpp; rgb color)
              ncolor (maximum number of colors assigned to pixels with
                      significant color)
              ngray (number of gray colors to be used; must be >= 2)
              darkthresh (threshold near black; if the lightest component
                          is below this, the pixel is not considered to
                          be gray or color; uses 0 for default)
              lightthresh (threshold near white; if the darkest component
                           is above this, the pixel is not considered to
                           be gray or color; use 0 for default)
              diffthresh (thresh for the max difference between component
                          values; for differences below this, the pixel
                          is considered to be gray; use 0 for default)
      Return: pixd (8 bpp cmapped), or null on error

  Notes:
      (1) ncolor + ngray must not exceed 255.
      (2) The method makes use of pixMedianCutQuantGeneral() with
          minimal addition.
          (a) Preprocess the image, setting all pixels with little color
              to black, and populating an auxiliary 8 bpp image with the
              expected colormap values corresponding to the set of
              quantized gray values.
          (b) Color quantize the altered input image to n + 1 colors.
          (c) Augment the colormap with the gray indices, and
              substitute the gray quantized values from the auxiliary
              image for those in the color quantized output that had
              been quantized as black.
      (3) Median cut color quantization is relatively poor for grayscale
          images with many colors, when compared to octcube quantization.
          Thus, for images with both gray and color, it is important
          to quantize the gray pixels by another method.  Here, we
          are conservative in detecting color, preferring to use
          a few extra bits to encode colorful pixels that push them
          to gray.  This is particularly reasonable with this function,
          because it handles the gray and color pixels separately,
          using median cut color quantization for the color pixels
          and equal-bin grayscale quantization for the non-color pixels.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
