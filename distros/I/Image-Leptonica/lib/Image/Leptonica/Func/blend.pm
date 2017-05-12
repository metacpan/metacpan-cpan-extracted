package Image::Leptonica::Func::blend;
$Image::Leptonica::Func::blend::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::blend

=head1 VERSION

version 0.04

=head1 C<blend.c>

  blend.c

      Blending two images that are not colormapped
           PIX             *pixBlend()
           PIX             *pixBlendMask()
           PIX             *pixBlendGray()
           PIX             *pixBlendGrayInverse()
           PIX             *pixBlendColor()
           PIX             *pixBlendColorByChannel()
           PIX             *pixBlendGrayAdapt()
           static l_int32   blendComponents()
           PIX             *pixFadeWithGray()
           PIX             *pixBlendHardLight()
           static l_int32   blendHardLightComponents()

      Blending two colormapped images
           l_int32          pixBlendCmap()

      Blending two images using a third (alpha mask)
           PIX             *pixBlendWithGrayMask()

      Blending background to a specific color
           PIX             *pixBlendBackgroundToColor()

      Multiplying by a specific color
           PIX             *pixMultiplyByColor()

      Rendering with alpha blending over a uniform background
           PIX             *pixAlphaBlendUniform()

      Adding an alpha layer for blending
           PIX             *pixAddAlphaToBlend()

      Setting a transparent alpha component over a white background
           PIX             *pixSetAlphaOverWhite()

  In blending operations a new pix is produced where typically
  a subset of pixels in src1 are changed by the set of pixels
  in src2, when src2 is located in a given position relative
  to src1.  This is similar to rasterop, except that the
  blending operations we allow are more complex, and typically
  result in dest pixels that are a linear combination of two
  pixels, such as src1 and its inverse.  I find it convenient
  to think of src2 as the "blender" (the one that takes the action)
  and src1 as the "blendee" (the one that changes).

  Blending works best when src1 is 8 or 32 bpp.  We also allow
  src1 to be colormapped, but the colormap is removed before blending,
  so if src1 is colormapped, we can't allow in-place blending.

  Because src2 is typically smaller than src1, we can implement by
  clipping src2 to src1 and then transforming some of the dest
  pixels that are under the support of src2.  In practice, we
  do the clipping in the inner pixel loop.  For grayscale and
  color src2, we also allow a simple form of transparency, where
  pixels of a particular value in src2 are transparent; for those pixels,
  no blending is done.

  The blending functions are categorized by the depth of src2,
  the blender, and not that of src1, the blendee.

   - If src2 is 1 bpp, we can do one of three things:
     (1) L_BLEND_WITH_INVERSE: Blend a given fraction of src1 with its
         inverse color for those pixels in src2 that are fg (ON),
         and leave the dest pixels unchanged for pixels in src2 that
         are bg (OFF).
     (2) L_BLEND_TO_WHITE: Fade the src1 pixels toward white by a
         given fraction for those pixels in src2 that are fg (ON),
         and leave the dest pixels unchanged for pixels in src2 that
         are bg (OFF).
     (3) L_BLEND_TO_BLACK: Fade the src1 pixels toward black by a
         given fraction for those pixels in src2 that are fg (ON),
         and leave the dest pixels unchanged for pixels in src2 that
         are bg (OFF).
     The blending function is pixBlendMask().

   - If src2 is 8 bpp grayscale, we can do one of two things
     (but see pixFadeWithGray() below):
     (1) L_BLEND_GRAY: If src1 is 8 bpp, mix the two values, using
         a fraction of src2 and (1 - fraction) of src1.
         If src1 is 32 bpp (rgb), mix the fraction of src2 with
         each of the color components in src1.
     (2) L_BLEND_GRAY_WITH_INVERSE: Use the grayscale value in src2
         to determine how much of the inverse of a src1 pixel is
         to be combined with the pixel value.  The input fraction
         further acts to scale the change in the src1 pixel.
     The blending function is pixBlendGray().

   - If src2 is color, we blend a given fraction of src2 with
     src1.  If src1 is 8 bpp, the resulting image is 32 bpp.
     The blending function is pixBlendColor().

   - For all three blending functions -- pixBlendMask(), pixBlendGray()
     and pixBlendColor() -- you can apply the blender to the blendee
     either in-place or generating a new pix.  For the in-place
     operation, this requires that the depth of the resulting pix
     must equal that of the input pixs1.

   - We remove colormaps from src1 and src2 before blending.
     Any quantization would have to be done after blending.

  We include another function, pixFadeWithGray(), that blends
  a gray or color src1 with a gray src2.  It does one of these things:
     (1) L_BLEND_TO_WHITE: Fade the src1 pixels toward white by
         a number times the value in src2.
     (2) L_BLEND_TO_BLACK: Fade the src1 pixels toward black by
         a number times the value in src2.

  Also included is a generalization of the so-called "hard light"
  blending: pixBlendHardLight().  We generalize by allowing a fraction < 1.0
  of the blender to be admixed with the blendee.  The standard function
  does full mixing.

=head1 FUNCTIONS

=head2 pixAddAlphaToBlend

PIX * pixAddAlphaToBlend ( PIX *pixs, l_float32 fract, l_int32 invert )

  pixAddAlphaToBlend()

      Input:  pixs (any depth)
              fract (fade fraction in the alpha component)
              invert (1 to photometrically invert pixs)
      Return: pixd (32 bpp with alpha), or null on error

  Notes:
      (1) This is a simple alpha layer generator, where typically white has
          maximum transparency and black has minimum.
      (2) If @invert == 1, generate the same alpha layer but invert
          the input image photometrically.  This is useful for blending
          over dark images, where you want dark regions in pixs, such
          as text, to be lighter in the blended image.
      (3) The fade @fract gives the minimum transparency (i.e.,
          maximum opacity).  A small fraction is useful for adding
          a watermark to an image.
      (4) If pixs has a colormap, it is removed to rgb.
      (5) If pixs already has an alpha layer, it is overwritten.

=head2 pixAlphaBlendUniform

PIX * pixAlphaBlendUniform ( PIX *pixs, l_uint32 color )

  pixAlphaBlendUniform()

      Input:  pixs (32 bpp rgba, with alpha)
              color (32 bit color in 0xrrggbb00 format)
      Return: pixd (32 bpp rgb: pixs blended over uniform color @color),
                    a clone of pixs if no alpha, and null on error

  Notes:
      (1) This is a convenience function that renders 32 bpp RGBA images
          (with an alpha channel) over a uniform background of
          value @color.  To render over a white background,
          use @color = 0xffffff00.  The result is an RGB image.
      (2) If pixs does not have an alpha channel, it returns a clone
          of pixs.

=head2 pixBlend

PIX * pixBlend ( PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract )

  pixBlend()

      Input:  pixs1 (blendee)
              pixs2 (blender; typ. smaller)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1; can be < 0)
              fract (blending fraction)
      Return: pixd (blended image), or null on error

  Notes:
      (1) This is a simple top-level interface.  For more flexibility,
          call directly into pixBlendMask(), etc.

=head2 pixBlendBackgroundToColor

PIX * pixBlendBackgroundToColor ( PIX *pixd, PIX *pixs, BOX *box, l_uint32 color, l_float32 gamma, l_int32 minval, l_int32 maxval )

  pixBlendBackgroundToColor()

      Input:  pixd (can be NULL or pixs)
              pixs (32 bpp rgb)
              box (region for blending; can be NULL))
              color (32 bit color in 0xrrggbb00 format)
              gamma, minval, maxval (args for grayscale TRC mapping)
      Return: pixd always

  Notes:
      (1) This in effect replaces light background pixels in pixs
          by the input color.  It does it by alpha blending so that
          there are no visible artifacts from hard cutoffs.
      (2) If pixd == pixs, this is done in-place.
      (3) If box == NULL, this is performed on all of pixs.
      (4) The alpha component for blending is derived from pixs,
          by converting to grayscale and enhancing with a TRC.
      (5) The last three arguments specify the TRC operation.
          Suggested values are: @gamma = 0.3, @minval = 50, @maxval = 200.
          To skip the TRC, use @gamma == 1, @minval = 0, @maxval = 255.
          See pixGammaTRC() for details.

=head2 pixBlendCmap

l_int32 pixBlendCmap ( PIX *pixs, PIX *pixb, l_int32 x, l_int32 y, l_int32 sindex )

  pixBlendCmap()

      Input:  pixs (2, 4 or 8 bpp, with colormap)
              pixb (colormapped blender)
              x, y (UL corner of blender relative to pixs)
              sindex (colormap index of pixels in pixs to be changed)
      Return: 0 if OK, 1 on error

  Note:
      (1) This function combines two colormaps, and replaces the pixels
          in pixs that have a specified color value with those in pixb.
      (2) sindex must be in the existing colormap; otherwise an
          error is returned.  In use, sindex will typically be the index
          for white (255, 255, 255).
      (3) Blender colors that already exist in the colormap are used;
          others are added.  If any blender colors cannot be
          stored in the colormap, an error is returned.
      (4) In the implementation, a mapping is generated from each
          original blender colormap index to the corresponding index
          in the expanded colormap for pixs.  Then for each pixel in
          pixs with value sindex, and which is covered by a blender pixel,
          the new index corresponding to the blender pixel is substituted
          for sindex.

=head2 pixBlendColor

PIX * pixBlendColor ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract, l_int32 transparent, l_uint32 transpix )

  pixBlendColor()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee; depth > 1)
              pixs2 (blender, any depth;; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1)
              fract (blending fraction)
              transparent (1 to use transparency; 0 otherwise)
              transpix (pixel color in pixs2 that is to be transparent)
      Return: pixd, or null on error

  Notes:
      (1) For inplace operation (pixs1 must be 32 bpp), call it this way:
            pixBlendColor(pixs1, pixs1, pixs2, ...)
      (2) For generating a new pixd:
            pixd = pixBlendColor(NULL, pixs1, pixs2, ...)
      (3) If pixs2 is not 32 bpp rgb, it is converted.
      (4) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (5) If pixs1 has a colormap, it is removed to generate a 32 bpp pix.
      (6) If pixs1 has depth < 32, it is unpacked to generate a 32 bpp pix.
      (7) If transparent = 0, the blending fraction (fract) is
          applied equally to all pixels.
      (8) If transparent = 1, all pixels of value transpix (typically
          either 0 or 0xffffff00) in pixs2 are transparent in the blend.

=head2 pixBlendColorByChannel

PIX * pixBlendColorByChannel ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 rfract, l_float32 gfract, l_float32 bfract, l_int32 transparent, l_uint32 transpix )

  pixBlendColorByChannel()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee; depth > 1)
              pixs2 (blender, any depth; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1)
              rfract, gfract, bfract (blending fractions by channel)
              transparent (1 to use transparency; 0 otherwise)
              transpix (pixel color in pixs2 that is to be transparent)
      Return: pixd if OK; pixs1 on error

 Notes:
     (1) This generalizes pixBlendColor() in two ways:
         (a) The mixing fraction is specified per channel.
         (b) The mixing fraction may be < 0 or > 1, in which case,
             the min or max of two images are taken, respectively.
     (2) Specifically,
         for p = pixs1[i], c = pixs2[i], f = fract[i], i = 1, 2, 3:
             f < 0.0:          p --> min(p, c)
             0.0 <= f <= 1.0:  p --> (1 - f) * p + f * c
             f > 1.0:          p --> max(a, c)
         Special cases:
             f = 0:   p --> p
             f = 1:   p --> c
     (3) See usage notes in pixBlendColor()
     (4) pixBlendColor() would be equivalent to
           pixBlendColorChannel(..., fract, fract, fract, ...);
         at a small cost of efficiency.

=head2 pixBlendGray

PIX * pixBlendGray ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract, l_int32 type, l_int32 transparent, l_uint32 transpix )

  pixBlendGray()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee, depth > 1)
              pixs2 (blender, any depth; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1; can be < 0)
              fract (blending fraction)
              type (L_BLEND_GRAY, L_BLEND_GRAY_WITH_INVERSE)
              transparent (1 to use transparency; 0 otherwise)
              transpix (pixel grayval in pixs2 that is to be transparent)
      Return: pixd if OK; pixs1 on error

  Notes:
      (1) For inplace operation (pixs1 not cmapped), call it this way:
            pixBlendGray(pixs1, pixs1, pixs2, ...)
      (2) For generating a new pixd:
            pixd = pixBlendGray(NULL, pixs1, pixs2, ...)
      (3) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (4) If pixs1 has a colormap, it is removed; otherwise, if pixs1
          has depth < 8, it is unpacked to generate a 8 bpp pix.
      (5) If transparent = 0, the blending fraction (fract) is
          applied equally to all pixels.
      (6) If transparent = 1, all pixels of value transpix (typically
          either 0 or 0xff) in pixs2 are transparent in the blend.
      (7) After processing pixs1, it is either 8 bpp or 32 bpp:
          - if 8 bpp, the fraction of pixs2 is mixed with pixs1.
          - if 32 bpp, each component of pixs1 is mixed with
            the same fraction of pixs2.
      (8) For L_BLEND_GRAY_WITH_INVERSE, the white values of the blendee
          (cval == 255 in the code below) result in a delta of 0.
          Thus, these pixels are intrinsically transparent!
          The "pivot" value of the src, at which no blending occurs, is
          128.  Compare with the adaptive pivot in pixBlendGrayAdapt().
      (9) Invalid @fract defaults to 0.5 with a warning.
          Invalid @type defaults to L_BLEND_GRAY with a warning.

=head2 pixBlendGrayAdapt

PIX * pixBlendGrayAdapt ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract, l_int32 shift )

  pixBlendGrayAdapt()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee, depth > 1)
              pixs2 (blender, any depth; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1; can be < 0)
              fract (blending fraction)
              shift (>= 0 but <= 128: shift of zero blend value from
                     median source; use -1 for default value; )
      Return: pixd if OK; pixs1 on error

  Notes:
      (1) For inplace operation (pixs1 not cmapped), call it this way:
            pixBlendGrayAdapt(pixs1, pixs1, pixs2, ...)
          For generating a new pixd:
            pixd = pixBlendGrayAdapt(NULL, pixs1, pixs2, ...)
      (2) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (3) If pixs1 has a colormap, it is removed.
      (4) If pixs1 has depth < 8, it is unpacked to generate a 8 bpp pix.
      (5) This does a blend with inverse.  Whereas in pixGlendGray(), the
          zero blend point is where the blendee pixel is 128, here
          the zero blend point is found adaptively, with respect to the
          median of the blendee region.  If the median is < 128,
          the zero blend point is found from
              median + shift.
          Otherwise, if the median >= 128, the zero blend point is
              median - shift.
          The purpose of shifting the zero blend point away from the
          median is to prevent a situation in pixBlendGray() where
          the median is 128 and the blender is not visible.
          The default value of shift is 64.
      (6) After processing pixs1, it is either 8 bpp or 32 bpp:
          - if 8 bpp, the fraction of pixs2 is mixed with pixs1.
          - if 32 bpp, each component of pixs1 is mixed with
            the same fraction of pixs2.
      (7) The darker the blender, the more it mixes with the blendee.
          A blender value of 0 has maximum mixing; a value of 255
          has no mixing and hence is transparent.

=head2 pixBlendGrayInverse

PIX * pixBlendGrayInverse ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract )

  pixBlendGrayInverse()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee, depth > 1)
              pixs2 (blender, any depth; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1; can be < 0)
              fract (blending fraction)
      Return: pixd if OK; pixs1 on error

  Notes:
      (1) For inplace operation (pixs1 not cmapped), call it this way:
            pixBlendGrayInverse(pixs1, pixs1, pixs2, ...)
      (2) For generating a new pixd:
            pixd = pixBlendGrayInverse(NULL, pixs1, pixs2, ...)
      (3) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (4) If pixs1 has a colormap, it is removed; otherwise if pixs1
          has depth < 8, it is unpacked to generate a 8 bpp pix.
      (5) This is a no-nonsense blender.  It changes the src1 pixel except
          when the src1 pixel is midlevel gray.  Use fract == 1 for the most
          aggressive blending, where, if the gray pixel in pixs2 is 0,
          we get a complete inversion of the color of the src pixel in pixs1.
      (6) The basic logic is that each component transforms by:
                 d  -->  c * d + (1 - c ) * (f * (1 - d) + d * (1 - f))
          where c is the blender pixel from pixs2,
                f is @fract,
                c and d are normalized to [0...1]
          This has the property that for f == 0 (no blend) or c == 1 (white):
               d  -->  d
          For c == 0 (black) we get maximum inversion:
               d  -->  f * (1 - d) + d * (1 - f)   [inversion by fraction f]

=head2 pixBlendHardLight

PIX * pixBlendHardLight ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract )

  pixBlendHardLight()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee; depth > 1, may be cmapped)
              pixs2 (blender, 8 or 32 bpp; may be colormapped;
                     typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1)
              fract (blending fraction, or 'opacity factor')
      Return: pixd if OK; pixs1 on error

  Notes:
      (1) pixs2 must be 8 or 32 bpp; either may have a colormap.
      (2) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (3) Only call in-place if pixs1 is not colormapped.
      (4) If pixs1 has a colormap, it is removed to generate either an
          8 or 32 bpp pix, depending on the colormap.
      (5) For inplace operation, call it this way:
            pixBlendHardLight(pixs1, pixs1, pixs2, ...)
      (6) For generating a new pixd:
            pixd = pixBlendHardLight(NULL, pixs1, pixs2, ...)
      (7) This is a generalization of the usual hard light blending,
          where fract == 1.0.
      (8) "Overlay" blending is the same as hard light blending, with
          fract == 1.0, except that the components are switched
          in the test.  (Note that the result is symmetric in the
          two components.)
      (9) See, e.g.:
           http://www.pegtop.net/delphi/articles/blendmodes/hardlight.htm
           http://www.digitalartform.com/imageArithmetic.htm
      (10) This function was built by Paco Galanes.

=head2 pixBlendMask

PIX * pixBlendMask ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 x, l_int32 y, l_float32 fract, l_int32 type )

  pixBlendMask()

      Input:  pixd (<optional>; either NULL or equal to pixs1 for in-place)
              pixs1 (blendee, depth > 1)
              pixs2 (blender, 1 bpp; typ. smaller in size than pixs1)
              x,y  (origin (UL corner) of pixs2 relative to
                    the origin of pixs1; can be < 0)
              fract (blending fraction)
              type (L_BLEND_WITH_INVERSE, L_BLEND_TO_WHITE, L_BLEND_TO_BLACK)
      Return: pixd if OK; null on error

  Notes:
      (1) Clipping of pixs2 to pixs1 is done in the inner pixel loop.
      (2) If pixs1 has a colormap, it is removed.
      (3) For inplace operation (pixs1 not cmapped), call it this way:
            pixBlendMask(pixs1, pixs1, pixs2, ...)
      (4) For generating a new pixd:
            pixd = pixBlendMask(NULL, pixs1, pixs2, ...)
      (5) Only call in-place if pixs1 does not have a colormap.
      (6) Invalid @fract defaults to 0.5 with a warning.
          Invalid @type defaults to L_BLEND_WITH_INVERSE with a warning.

=head2 pixBlendWithGrayMask

PIX * pixBlendWithGrayMask ( PIX *pixs1, PIX *pixs2, PIX *pixg, l_int32 x, l_int32 y )

  pixBlendWithGrayMask()

      Input:  pixs1 (8 bpp gray, rgb, rgba or colormapped)
              pixs2 (8 bpp gray, rgb, rgba or colormapped)
              pixg (<optional> 8 bpp gray, for transparency of pixs2;
                    can be null)
              x, y (UL corner of pixs2 and pixg with respect to pixs1)
      Return: pixd (blended image), or null on error

  Notes:
      (1) The result is 8 bpp grayscale if both pixs1 and pixs2 are
          8 bpp gray.  Otherwise, the result is 32 bpp rgb.
      (2) pixg is an 8 bpp transparency image, where 0 is transparent
          and 255 is opaque.  It determines the transparency of pixs2
          when applied over pixs1.  It can be null if pixs2 is rgba,
          in which case we use the alpha component of pixs2.
      (3) If pixg exists, it need not be the same size as pixs2.
          However, we assume their UL corners are aligned with each other,
          and placed at the location (x, y) in pixs1.
      (4) The pixels in pixd are a combination of those in pixs1
          and pixs2, where the amount from pixs2 is proportional to
          the value of the pixel (p) in pixg, and the amount from pixs1
          is proportional to (255 - p).  Thus pixg is a transparency
          image (usually called an alpha blender) where each pixel
          can be associated with a pixel in pixs2, and determines
          the amount of the pixs2 pixel in the final result.
          For example, if pixg is all 0, pixs2 is transparent and
          the result in pixd is simply pixs1.
      (5) A typical use is for the pixs2/pixg combination to be
          a small watermark that is applied to pixs1.

=head2 pixFadeWithGray

PIX * pixFadeWithGray ( PIX *pixs, PIX *pixb, l_float32 factor, l_int32 type )

  pixFadeWithGray()

      Input:  pixs (colormapped or 8 bpp or 32 bpp)
              pixb (8 bpp blender)
              factor (multiplicative factor to apply to blender value)
              type (L_BLEND_TO_WHITE, L_BLEND_TO_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) This function combines two pix aligned to the UL corner; they
          need not be the same size.
      (2) Each pixel in pixb is multiplied by 'factor' divided by 255, and
          clipped to the range [0 ... 1].  This gives the fade fraction
          to be appied to pixs.  Fade either to white (L_BLEND_TO_WHITE)
          or to black (L_BLEND_TO_BLACK).

=head2 pixMultiplyByColor

PIX * pixMultiplyByColor ( PIX *pixd, PIX *pixs, BOX *box, l_uint32 color )

  pixMultiplyByColor()

      Input:  pixd (can be NULL or pixs)
              pixs (32 bpp rgb)
              box (region for filtering; can be NULL))
              color (32 bit color in 0xrrggbb00 format)
      Return: pixd always

  Notes:
      (1) This filters all pixels in the specified region by
          multiplying each component by the input color.
          This leaves black invariant and transforms white to the
          input color.
      (2) If pixd == pixs, this is done in-place.
      (3) If box == NULL, this is performed on all of pixs.

=head2 pixSetAlphaOverWhite

PIX * pixSetAlphaOverWhite ( PIX *pixs )

  pixSetAlphaOverWhite()

      Input:  pixs (colormapped or 32 bpp rgb; no alpha)
      Return: pixd (new pix with meaningful alpha component),
                   or null on error

  Notes:
      (1) The generated alpha component is transparent over white
          (background) pixels in pixs, and quickly grades to opaque
          away from the transparent parts.  This is a cheap and
          dirty alpha generator.  The 2 pixel gradation is useful
          to blur the boundary between the transparent region
          (that will render entirely from a backing image) and
          the remainder which renders from pixs.
      (2) All alpha component bits in pixs are overwritten.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
