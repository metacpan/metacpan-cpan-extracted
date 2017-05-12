package Image::Leptonica::Func::paintcmap;
$Image::Leptonica::Func::paintcmap::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::paintcmap

=head1 VERSION

version 0.04

=head1 C<paintcmap.c>

  paintcmap.c

      These in-place functions paint onto colormap images.

      Repaint selected pixels in region
           l_int32     pixSetSelectCmap()

      Repaint non-white pixels in region
           l_int32     pixColorGrayRegionsCmap()
           l_int32     pixColorGrayCmap()
           l_int32     addColorizedGrayToCmap()

      Repaint selected pixels through mask
           l_int32     pixSetSelectMaskedCmap()

      Repaint all pixels through mask
           l_int32     pixSetMaskedCmap()


  The 'set select' functions condition the setting on a specific
  pixel value (i.e., index into the colormap) of the underyling
  Pix that is being modified.  The same conditioning is used in
  pixBlendCmap().

  The pixColorGrayCmap() function sets all truly gray (r = g = b) pixels,
  with the exception of either black or white pixels, to a new color.

  The pixSetSelectMaskedCmap() function conditions pixel painting
  on both a specific pixel value and location within the fg mask.
  By contrast, pixSetMaskedCmap() sets all pixels under the
  mask foreground, without considering the initial pixel values.

=head1 FUNCTIONS

=head2 addColorizedGrayToCmap

l_int32 addColorizedGrayToCmap ( PIXCMAP *cmap, l_int32 type, l_int32 rval, l_int32 gval, l_int32 bval, NUMA **pna )

  addColorizedGrayToCmap()

      Input:  cmap (from 2 or 4 bpp pix)
              type (L_PAINT_LIGHT, L_PAINT_DARK)
              rval, gval, bval (target color)
              &na (<optional return> table for mapping new cmap entries)
      Return: 0 if OK; 1 on error; 2 if new colors will not fit in cmap.

  Notes:
      (1) If type == L_PAINT_LIGHT, it colorizes non-black pixels,
          preserving antialiasing.
          If type == L_PAINT_DARK, it colorizes non-white pixels,
          preserving antialiasing.
      (2) This increases the colormap size by the number of
          different gray (non-black or non-white) colors in the
          input colormap.  If there is not enough room in the colormap
          for this expansion, it returns 1 (treated as a warning);
          the caller should check the return value.
      (3) This can be used to determine if the new colors will fit in
          the cmap, using null for &na.  Returns 0 if they fit; 2 if
          they don't fit.
      (4) The mapping table contains, for each gray color found, the
          index of the corresponding colorized pixel.  Non-gray
          pixels are assigned the invalid index 256.
      (5) See pixColorGrayCmap() for usage.

=head2 pixColorGrayCmap

l_int32 pixColorGrayCmap ( PIX *pixs, BOX *box, l_int32 type, l_int32 rval, l_int32 gval, l_int32 bval )

  pixColorGrayCmap()

      Input:  pixs (2, 4 or 8 bpp, with colormap)
              box (<optional> region to set color; can be NULL)
              type (L_PAINT_LIGHT, L_PAINT_DARK)
              rval, gval, bval (target color)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) If type == L_PAINT_LIGHT, it colorizes non-black pixels,
          preserving antialiasing.
          If type == L_PAINT_DARK, it colorizes non-white pixels,
          preserving antialiasing.
      (3) If box is NULL, applies function to the entire image; otherwise,
          clips the operation to the intersection of the box and pix.
      (4) This can also be called through pixColorGray().
      (5) This increases the colormap size by the number of
          different gray (non-black or non-white) colors in the
          input colormap.  If there is not enough room in the colormap
          for this expansion, it returns 1 (error), and the caller
          should check the return value.  If an error is returned
          and the cmap is only 2 or 4 bpp, the pix can be converted
          to 8 bpp and this function will succeed if run again on
          a larger colormap.
      (6) Using the darkness of each original pixel in the rect,
          it generates a new color (based on the input rgb values).
          If type == L_PAINT_LIGHT, the new color is a (generally)
          darken-to-black version of the  input rgb color, where the
          amount of darkening increases with the darkness of the
          original pixel color.
          If type == L_PAINT_DARK, the new color is a (generally)
          faded-to-white version of the  input rgb color, where the
          amount of fading increases with the brightness of the
          original pixel color.

=head2 pixColorGrayRegionsCmap

l_int32 pixColorGrayRegionsCmap ( PIX *pixs, BOXA *boxa, l_int32 type, l_int32 rval, l_int32 gval, l_int32 bval )

  pixColorGrayRegionsCmap()

      Input:  pixs (8 bpp, with colormap)
              boxa (of regions in which to apply color)
              type (L_PAINT_LIGHT, L_PAINT_DARK)
              rval, gval, bval (target color)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) If type == L_PAINT_LIGHT, it colorizes non-black pixels,
          preserving antialiasing.
          If type == L_PAINT_DARK, it colorizes non-white pixels,
          preserving antialiasing.  See pixColorGrayCmap() for details.
      (3) This can also be called through pixColorGrayRegions().
      (4) This increases the colormap size by the number of
          different gray (non-black or non-white) colors in the
          selected regions of pixs.  If there is not enough room in
          the colormap for this expansion, it returns 1 (error),
          and the caller should check the return value.
      (5) Because two boxes in the boxa can overlap, pixels that
          are colorized in the first box must be excluded in the
          second because their value exceeds the size of the map.

=head2 pixSetMaskedCmap

l_int32 pixSetMaskedCmap ( PIX *pixs, PIX *pixm, l_int32 x, l_int32 y, l_int32 rval, l_int32 gval, l_int32 bval )

  pixSetMaskedCmap()

      Input:  pixs (2, 4 or 8 bpp, colormapped)
              pixm (<optional> 1 bpp mask; no-op if NULL)
              x, y (origin of pixm relative to pixs; can be negative)
              rval, gval, bval (new color to set at each masked pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) It paints a single color through the mask (as a stencil).
      (3) The mask origin is placed at (x,y) on pixs, and the
          operation is clipped to the intersection of the mask and pixs.
      (4) If pixm == NULL, a warning is given.
      (5) Typically, pixm is a small binary mask located somewhere
          on the larger pixs.
      (6) If the color is in the colormap, it is used.  Otherwise,
          it is added if possible; an error is returned if the
          colormap is already full.

=head2 pixSetSelectCmap

l_int32 pixSetSelectCmap ( PIX *pixs, BOX *box, l_int32 sindex, l_int32 rval, l_int32 gval, l_int32 bval )

  pixSetSelectCmap()

      Input:  pixs (1, 2, 4 or 8 bpp, with colormap)
              box (<optional> region to set color; can be NULL)
              sindex (colormap index of pixels to be changed)
              rval, gval, bval (new color to paint)
      Return: 0 if OK, 1 on error

  Note:
      (1) This is an in-place operation.
      (2) It sets all pixels in region that have the color specified
          by the colormap index 'sindex' to the new color.
      (3) sindex must be in the existing colormap; otherwise an
          error is returned.
      (4) If the new color exists in the colormap, it is used;
          otherwise, it is added to the colormap.  If it cannot be
          added because the colormap is full, an error is returned.
      (5) If box is NULL, applies function to the entire image; otherwise,
          clips the operation to the intersection of the box and pix.
      (6) An example of use would be to set to a specific color all
          the light (background) pixels within a certain region of
          a 3-level 2 bpp image, while leaving light pixels outside
          this region unchanged.

=head2 pixSetSelectMaskedCmap

l_int32 pixSetSelectMaskedCmap ( PIX *pixs, PIX *pixm, l_int32 x, l_int32 y, l_int32 sindex, l_int32 rval, l_int32 gval, l_int32 bval )

  pixSetSelectMaskedCmap()

      Input:  pixs (2, 4 or 8 bpp, with colormap)
              pixm (<optional> 1 bpp mask; no-op if NULL)
              x, y (UL corner of mask relative to pixs)
              sindex (colormap index of pixels in pixs to be changed)
              rval, gval, bval (new color to substitute)
      Return: 0 if OK, 1 on error

  Note:
      (1) This is an in-place operation.
      (2) This paints through the fg of pixm and replaces all pixels
          in pixs that have a particular value (sindex) with the new color.
      (3) If pixm == NULL, a warning is given.
      (4) sindex must be in the existing colormap; otherwise an
          error is returned.
      (5) If the new color exists in the colormap, it is used;
          otherwise, it is added to the colormap.  If the colormap
          is full, an error is returned.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
