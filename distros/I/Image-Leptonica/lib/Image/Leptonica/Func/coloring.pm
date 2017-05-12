package Image::Leptonica::Func::coloring;
$Image::Leptonica::Func::coloring::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::coloring

=head1 VERSION

version 0.04

=head1 C<coloring.c>

  coloring.c

      Coloring "gray" pixels
           PIX             *pixColorGrayRegions()
           l_int32          pixColorGray()

      Adjusting one or more colors to a target color
           PIX             *pixSnapColor()
           PIX             *pixSnapColorCmap()

      Piecewise linear color mapping based on a source/target pair
           PIX             *pixLinearMapToTargetColor()
           l_int32          pixelLinearMapToTargetColor()

      Fractional shift of RGB towards black or white
           PIX             *pixShiftByComponent()
           l_int32          pixelShiftByComponent()
           l_int32          pixelFractionalShift()

  There are several "coloring" functions in leptonica.
  You can find them in these files:
       coloring.c
       paintcmap.c
       pix2.c
       blend.c
       enhance.c

  They fall into the following categories:

  (1) Moving either the light or dark pixels toward a
      specified color. (pixColorGray)
  (2) Forcing all pixels whose color is within some delta of a
      specified color to move to that color. (pixSnapColor)
  (3) Doing a piecewise linear color shift specified by a source
      and a target color.  Each component shifts independently.
      (pixLinearMapToTargetColor)
  (4) Shifting all colors by a given fraction of their distance
      from 0 (if shifting down) or from 255 (if shifting up).
      This is useful for colorizing either the background or
      the foreground of a grayscale image. (pixShiftByComponent)
  (5) Shifting all colors by a component-dependent fraction of
      their distance from 0 (if shifting down) or from 255 (if
      shifting up).  This is useful for modifying the color to
      compensate for color shifts in acquisition, for example
      (enhance.c: pixColorShiftRGB).
  (6) Repainting selected pixels. (paintcmap.c: pixSetSelectMaskedCmap)
  (7) Blending a fraction of a specific color with the existing RGB
      color.  (pix2.c: pixBlendInRect())
  (8) Changing selected colors in a colormap.
      (paintcmap.c: pixSetSelectCmap, pixSetSelectMaskedCmap)
  (9) Shifting all the pixels towards black or white depending on
      the gray value of a second image.  (blend.c: pixFadeWithGray)
  (10) Changing the hue, saturation or brightness, by changing the
      appropriate parameter in HSV color space by a fraction of
      the distance toward its end-point.  For example, you can change
      the brightness by moving each pixel's v-parameter a specified
      fraction of the distance toward 0 (darkening) or toward 255
      (brightening).  (enhance.c: pixModifySaturation,
      pixModifyHue, pixModifyBrightness)

=head1 FUNCTIONS

=head2 pixColorGray

l_int32 pixColorGray ( PIX *pixs, BOX *box, l_int32 type, l_int32 thresh, l_int32 rval, l_int32 gval, l_int32 bval )

  pixColorGray()

      Input:  pixs (8 bpp gray, rgb or colormapped image)
              box (<optional> region in which to apply color; can be NULL)
              type (L_PAINT_LIGHT, L_PAINT_DARK)
              thresh (average value below/above which pixel is unchanged)
              rval, gval, bval (new color to paint)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place operation; pixs is modified.
          If pixs is colormapped, the operation will add colors to the
          colormap.  Otherwise, pixs will be converted to 32 bpp rgb if
          it is initially 8 bpp gray.
      (2) If type == L_PAINT_LIGHT, it colorizes non-black pixels,
          preserving antialiasing.
          If type == L_PAINT_DARK, it colorizes non-white pixels,
          preserving antialiasing.
      (3) If box is NULL, applies function to the entire image; otherwise,
          clips the operation to the intersection of the box and pix.
      (4) If colormapped, calls pixColorGrayCmap(), which applies the
          coloring algorithm only to pixels that are strictly gray.
      (5) For RGB, determines a "gray" value by averaging; then uses this
          value, plus the input rgb target, to generate the output
          pixel values.
      (6) thresh is only used for rgb; it is ignored for colormapped pix.
          If type == L_PAINT_LIGHT, use thresh = 0 if all pixels are to
          be colored (black pixels will be unaltered).
          In situations where there are a lot of black pixels,
          setting thresh > 0 will make the function considerably
          more efficient without affecting the final result.
          If type == L_PAINT_DARK, use thresh = 255 if all pixels
          are to be colored (white pixels will be unaltered).
          In situations where there are a lot of white pixels,
          setting thresh < 255 will make the function considerably
          more efficient without affecting the final result.

=head2 pixColorGrayRegions

PIX * pixColorGrayRegions ( PIX *pixs, BOXA *boxa, l_int32 type, l_int32 thresh, l_int32 rval, l_int32 gval, l_int32 bval )

  pixColorGrayRegions()

      Input:  pixs (2, 4 or 8 bpp gray, rgb, or colormapped)
              boxa (of regions in which to apply color)
              type (L_PAINT_LIGHT, L_PAINT_DARK)
              thresh (average value below/above which pixel is unchanged)
              rval, gval, bval (new color to paint)
      Return: pixd, or null on error

  Notes:
      (1) This generates a new image, where some of the pixels in each
          box in the boxa are colorized.  See pixColorGray() for usage
          with @type and @thresh.  Note that @thresh is only used for
          rgb; it is ignored for colormapped images.
      (2) If the input image is colormapped, the new image will be 8 bpp
          colormapped if possible; otherwise, it will be converted
          to 32 bpp rgb.  Only pixels that are strictly gray will be
          colorized.
      (3) If the input image is not colormapped, it is converted to rgb.
          A "gray" value for a pixel is determined by averaging the
          components, and the output rgb value is determined from this.
      (4) This can be used in conjunction with pixFindColorRegions() to
          add highlight color to a grayscale image.

=head2 pixLinearMapToTargetColor

PIX * pixLinearMapToTargetColor ( PIX *pixd, PIX *pixs, l_uint32 srcval, l_uint32 dstval )

  pixLinearMapToTargetColor()

      Input:  pixd (<optional>; either NULL or equal to pixs for in-place)
              pixs (32 bpp rgb)
              srcval (source color: 0xrrggbb00)
              dstval (target color: 0xrrggbb00)
      Return: pixd (with all pixels mapped based on the srcval/destval
                    mapping), or pixd on error

  Notes:
      (1) For each component (r, b, g) separately, this does a piecewise
          linear mapping of the colors in pixs to colors in pixd.
          If rs and rd are the red src and dest components in @srcval and
          @dstval, then the range [0 ... rs] in pixs is mapped to
          [0 ... rd] in pixd.  Likewise, the range [rs ... 255] in pixs
          is mapped to [rd ... 255] in pixd.  And similarly for green
          and blue.
      (2) The mapping will in general change the hue of the pixels.
          However, if the src and dst targets are related by
          a transformation given by pixelFractionalShift(), the hue
          is invariant.
      (3) For inplace operation, call it this way:
            pixLinearMapToTargetColor(pixs, pixs, ... )
      (4) For generating a new pixd:
            pixd = pixLinearMapToTargetColor(NULL, pixs, ...)

=head2 pixShiftByComponent

PIX * pixShiftByComponent ( PIX *pixd, PIX *pixs, l_uint32 srcval, l_uint32 dstval )

  pixShiftByComponent()

      Input:  pixd (<optional>; either NULL or equal to pixs for in-place)
              pixs (32 bpp rgb)
              srcval (source color: 0xrrggbb00)
              dstval (target color: 0xrrggbb00)
      Return: pixd (with all pixels mapped based on the srcval/destval
                    mapping), or pixd on error

  Notes:
      (1) For each component (r, b, g) separately, this does a linear
          mapping of the colors in pixs to colors in pixd.
          Let rs and rd be the red src and dest components in @srcval and
          @dstval, and rval is the red component of the src pixel.
          Then for all pixels in pixs, the mapping for the red
          component from pixs to pixd is:
             if (rd <= rs)   (shift toward black)
                 rval --> (rd/rs) * rval
             if (rd > rs)    (shift toward white)
                (255 - rval) --> ((255 - rs)/(255 - rd)) * (255 - rval)
          Thus if rd <= rs, the red component of all pixels is
          mapped by the same fraction toward white, and if rd > rs,
          they are mapped by the same fraction toward black.
          This is essentially a different linear TRC (gamma = 1)
          for each component.  The source and target color inputs are
          just used to generate the three fractions.
      (2) Note that this mapping differs from that in
          pixLinearMapToTargetColor(), which maps rs --> rd and does
          a piecewise stretching in between.
      (3) For inplace operation, call it this way:
            pixFractionalShiftByComponent(pixs, pixs, ... )
      (4) For generating a new pixd:
            pixd = pixLinearMapToTargetColor(NULL, pixs, ...)
      (5) A simple application is to color a grayscale image.
          A light background can be colored using srcval = 0xffffff00
          and picking a target background color for dstval.
          A dark foreground can be colored by using srcval = 0x0
          and choosing a target foreground color for dstval.

=head2 pixSnapColor

PIX * pixSnapColor ( PIX *pixd, PIX *pixs, l_uint32 srcval, l_uint32 dstval, l_int32 diff )

  pixSnapColor()

      Input:  pixd (<optional>; either NULL or equal to pixs for in-place)
              pixs (colormapped or 8 bpp gray or 32 bpp rgb)
              srcval (color center to be selected for change: 0xrrggbb00)
              dstval (target color for pixels: 0xrrggbb00)
              diff (max absolute difference, applied to all components)
      Return: pixd (with all pixels within diff of pixval set to pixval),
                    or pixd on error

  Notes:
      (1) For inplace operation, call it this way:
           pixSnapColor(pixs, pixs, ... )
      (2) For generating a new pixd:
           pixd = pixSnapColor(NULL, pixs, ...)
      (3) If pixs has a colormap, it is handled by pixSnapColorCmap().
      (4) All pixels within 'diff' of 'srcval', componentwise,
          will be changed to 'dstval'.

=head2 pixSnapColorCmap

PIX * pixSnapColorCmap ( PIX *pixd, PIX *pixs, l_uint32 srcval, l_uint32 dstval, l_int32 diff )

  pixSnapColorCmap()

      Input:  pixd (<optional>; either NULL or equal to pixs for in-place)
              pixs (colormapped)
              srcval (color center to be selected for change: 0xrrggbb00)
              dstval (target color for pixels: 0xrrggbb00)
              diff (max absolute difference, applied to all components)
      Return: pixd (with all pixels within diff of srcval set to dstval),
                    or pixd on error

  Notes:
      (1) For inplace operation, call it this way:
           pixSnapCcmap(pixs, pixs, ... )
      (2) For generating a new pixd:
           pixd = pixSnapCmap(NULL, pixs, ...)
      (3) pixs must have a colormap.
      (4) All colors within 'diff' of 'srcval', componentwise,
          will be changed to 'dstval'.

=head2 pixelFractionalShift

l_int32 pixelFractionalShift ( l_int32 rval, l_int32 gval, l_int32 bval, l_float32 fraction, l_uint32 *ppixel )

  pixelFractionalShift()

      Input:  rval, gval, bval
              fraction (negative toward black; positive toward white)
              &ppixel (<return> rgb value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This transformation leaves the hue invariant, while changing
          the saturation and intensity.  It can be used for that
          purpose in pixLinearMapToTargetColor().
      (2) @fraction is in the range [-1 .... +1].  If @fraction < 0,
          saturation is increased and brightness is reduced.  The
          opposite results if @fraction > 0.  If @fraction == -1,
          the resulting pixel is black; @fraction == 1 results in white.

=head2 pixelLinearMapToTargetColor

l_int32 pixelLinearMapToTargetColor ( l_uint32 scolor, l_uint32 srcmap, l_uint32 dstmap, l_uint32 *pdcolor )

  pixelLinearMapToTargetColor()

      Input:  scolor (rgb source color: 0xrrggbb00)
              srcmap (source mapping color: 0xrrggbb00)
              dstmap (target mapping color: 0xrrggbb00)
              &pdcolor (<return> rgb dest color: 0xrrggbb00)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does this does a piecewise linear mapping of each
          component of @scolor to @dcolor, based on the relation
          between the components of @srcmap and @dstmap.  It is the
          same transformation, performed on a single color, as mapped
          on every pixel in a pix by pixLinearMapToTargetColor().
      (2) For each component, if the sval is larger than the smap,
          the dval will be pushed up from dmap towards white.
          Otherwise, dval will be pushed down from dmap towards black.
          This is because you can visualize the transformation as
          a linear stretching where smap moves to dmap, and everything
          else follows linearly with 0 and 255 fixed.
      (3) The mapping will in general change the hue of @scolor.
          However, if the @srcmap and @dstmap targets are related by
          a transformation given by pixelFractionalShift(), the hue
          will be invariant.

=head2 pixelShiftByComponent

l_int32 pixelShiftByComponent ( l_int32 rval, l_int32 gval, l_int32 bval, l_uint32 srcval, l_uint32 dstval, l_uint32 *ppixel )

  pixelShiftByComponent()

      Input:  rval, gval, bval
              srcval (source color: 0xrrggbb00)
              dstval (target color: 0xrrggbb00)
              &ppixel (<return> rgb value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a linear transformation that gives the same result
          on a single pixel as pixShiftByComponent() gives
          on a pix.  Each component is handled separately.  If
          the dest component is larger than the src, then the
          component is pushed toward 255 by the same fraction as
          the src --> dest shift.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
