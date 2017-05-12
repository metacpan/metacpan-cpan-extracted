package Image::Leptonica::Func::warper;
$Image::Leptonica::Func::warper::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::warper

=head1 VERSION

version 0.04

=head1 C<warper.c>

  warper.c

      High-level captcha interface
          PIX               *pixSimpleCaptcha()

      Random sinusoidal warping
          PIX               *pixRandomHarmonicWarp()

      Helper functions
          static l_float64  *generateRandomNumberArray()
          static l_int32     applyWarpTransform()

      Version using a LUT for sin
          PIX               *pixRandomHarmonicWarpLUT()
          static l_int32     applyWarpTransformLUT()
          static l_int32     makeSinLUT()
          static l_float32   getSinFromLUT()

      Stereoscopic warping
          PIX               *pixWarpStereoscopic()

      Linear and quadratic horizontal stretching
          PIX               *pixStretchHorizontal()
          PIX               *pixStretchHorizontalSampled()
          PIX               *pixStretchHorizontalLI()

      Quadratic vertical shear
          PIX               *pixQuadraticVShear()
          PIX               *pixQuadraticVShearSampled()
          PIX               *pixQuadraticVShearLI()

      Stereo from a pair of images
          PIX               *pixStereoFromPair()

=head1 FUNCTIONS

=head2 pixQuadraticVShear

PIX * pixQuadraticVShear ( PIX *pixs, l_int32 dir, l_int32 vmaxt, l_int32 vmaxb, l_int32 operation, l_int32 incolor )

  pixQuadraticVShear()

      Input:  pixs (1, 8 or 32 bpp)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              vmaxt (max vertical displacement at edge and at top)
              vmaxb (max vertical displacement at edge and at bottom)
              operation (L_SAMPLED or L_INTERPOLATED)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched), or null on error

  Notes:
      (1) This gives a quadratic bending, upward or downward, as you
          move to the left or right.
      (2) If @dir == L_WARP_TO_LEFT, the right edge is unchanged, and
          the left edge pixels are moved maximally up or down.
      (3) Parameters @vmaxt and @vmaxb control the maximum amount of
          vertical pixel shear at the top and bottom, respectively.
          If @vmaxt > 0, the vertical displacement of pixels at the
          top is downward.  Likewise, if @vmaxb > 0, the vertical
          displacement of pixels at the bottom is downward.
      (4) If @operation == L_SAMPLED, the dest pixels are taken from
          the nearest src pixel.  Otherwise, we use linear interpolation
          between pairs of sampled pixels.
      (5) This is for quadratic shear.  For uniform (linear) shear,
          use the standard shear operators.

=head2 pixQuadraticVShearLI

PIX * pixQuadraticVShearLI ( PIX *pixs, l_int32 dir, l_int32 vmaxt, l_int32 vmaxb, l_int32 incolor )

  pixQuadraticVShearLI()

      Input:  pixs (8 or 32 bpp, or colormapped)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              vmaxt (max vertical displacement at edge and at top)
              vmaxb (max vertical displacement at edge and at bottom)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched), or null on error

  Notes:
      (1) See pixQuadraticVShear() for details.

=head2 pixQuadraticVShearSampled

PIX * pixQuadraticVShearSampled ( PIX *pixs, l_int32 dir, l_int32 vmaxt, l_int32 vmaxb, l_int32 incolor )

  pixQuadraticVShearSampled()

      Input:  pixs (1, 8 or 32 bpp)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              vmaxt (max vertical displacement at edge and at top)
              vmaxb (max vertical displacement at edge and at bottom)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched), or null on error

  Notes:
      (1) See pixQuadraticVShear() for details.

=head2 pixRandomHarmonicWarp

PIX * pixRandomHarmonicWarp ( PIX *pixs, l_float32 xmag, l_float32 ymag, l_float32 xfreq, l_float32 yfreq, l_int32 nx, l_int32 ny, l_uint32 seed, l_int32 grayval )

  pixRandomHarmonicWarp()

      Input:  pixs (8 bpp; no colormap)
              xmag, ymag (maximum magnitude of x and y distortion)
              xfreq, yfreq (maximum magnitude of x and y frequency)
              nx, ny (number of x and y harmonic terms)
              seed (of random number generator)
              grayval (color brought in from the outside;
                       0 for black, 255 for white)
      Return: pixd (8 bpp; no colormap), or null on error

  Notes:
      (1) To generate the warped image p(x',y'), set up the transforms
          that are in getWarpTransform().  For each (x',y') in the
          dest, the warp function computes the originating location
          (x, y) in the src.  The differences (x - x') and (y - y')
          are given as a sum of products of sinusoidal terms.  Each
          term is multiplied by a maximum amplitude (in pixels), and the
          angle is determined by a frequency and phase, and depends
          on the (x', y') value of the dest.  Random numbers with
          a variable input seed are used to allow the warping to be
          unpredictable.  A linear interpolation is used to find
          the value for the source at (x, y); this value is written
          into the dest.
      (2) This can be used to generate 'captcha's, which are somewhat
          randomly distorted images of text.  A typical set of parameters
          for a captcha are:
                    xmag = 4.0     ymag = 6.0
                    xfreq = 0.10   yfreq = 0.13
                    nx = 3         ny = 3
          Other examples can be found in prog/warptest.c.

=head2 pixSimpleCaptcha

PIX * pixSimpleCaptcha ( PIX *pixs, l_int32 border, l_int32 nterms, l_uint32 seed, l_uint32 color, l_int32 cmapflag )

  pixSimpleCaptcha()

      Input:  pixs (8 bpp; no colormap)
              border (added white pixels on each side)
              nterms (number of x and y harmonic terms)
              seed (of random number generator)
              color (for colorizing; in 0xrrggbb00 format; use 0 for black)
              cmapflag (1 for colormap output; 0 for rgb)
      Return: pixd (8 bpp cmap or 32 bpp rgb), or null on error

  Notes:
      (1) This uses typical default values for generating captchas.
          The magnitudes of the harmonic warp are typically to be
          smaller when more terms are used, even though the phases
          are random.  See, for example, prog/warptest.c.

=head2 pixStereoFromPair

PIX * pixStereoFromPair ( PIX *pix1, PIX *pix2, l_float32 rwt, l_float32 gwt, l_float32 bwt )

  pixStereoFromPair()

      Input:  pix1 (32 bpp rgb)
              pix2 (32 bpp rgb)
              rwt, gwt, bwt (weighting factors used for each component in
                               pix1 to determine the output red channel)
      Return: pixd (stereo enhanced), or null on error

  Notes:
      (1) pix1 and pix2 are a pair of stereo images, ideally taken
          concurrently in the same plane, with some lateral translation.
      (2) The output red channel is determined from @pix1.
          The output green and blue channels are taken from the green
          and blue channels, respectively, of @pix2.
      (3) The weights determine how much of each component in @pix1
          goes into the output red channel.  The sum of weights
          must be 1.0.  If it's not, we scale the weights to
          satisfy this criterion.
      (4) The most general pixel mapping allowed here is:
            rval = rwt * r1 + gwt * g1 + bwt * b1  (from pix1)
            gval = g2   (from pix2)
            bval = b2   (from pix2)
      (5) The simplest method is to use rwt = 1.0, gwt = 0.0, bwt = 0.0,
          but this causes unpleasant visual artifacts with red in the image.
          Use of green and blue from @pix1 in the red channel,
          instead of red, tends to fix that problem.

=head2 pixStretchHorizontal

PIX * pixStretchHorizontal ( PIX *pixs, l_int32 dir, l_int32 type, l_int32 hmax, l_int32 operation, l_int32 incolor )

  pixStretchHorizontal()

      Input:  pixs (1, 8 or 32 bpp)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              type (L_LINEAR_WARP or L_QUADRATIC_WARP)
              hmax (horizontal displacement at edge)
              operation (L_SAMPLED or L_INTERPOLATED)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched/compressed), or null on error

  Notes:
      (1) If @hmax > 0, this is an increase in the coordinate value of
          pixels in pixd, relative to the same pixel in pixs.
      (2) If @dir == L_WARP_TO_LEFT, the pixels on the right edge of
          the image are not moved. So, for example, if @hmax > 0
          and @dir == L_WARP_TO_LEFT, the pixels in pixd are
          contracted toward the right edge of the image, relative
          to those in pixs.
      (3) If @type == L_LINEAR_WARP, the pixel positions are moved
          to the left or right by an amount that varies linearly with
          the horizontal location.
      (4) If @operation == L_SAMPLED, the dest pixels are taken from
          the nearest src pixel.  Otherwise, we use linear interpolation
          between pairs of sampled pixels.

=head2 pixStretchHorizontalLI

PIX * pixStretchHorizontalLI ( PIX *pixs, l_int32 dir, l_int32 type, l_int32 hmax, l_int32 incolor )

  pixStretchHorizontalLI()

      Input:  pixs (1, 8 or 32 bpp)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              type (L_LINEAR_WARP or L_QUADRATIC_WARP)
              hmax (horizontal displacement at edge)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched/compressed), or null on error

  Notes:
      (1) See pixStretchHorizontal() for details.

=head2 pixStretchHorizontalSampled

PIX * pixStretchHorizontalSampled ( PIX *pixs, l_int32 dir, l_int32 type, l_int32 hmax, l_int32 incolor )

  pixStretchHorizontalSampled()

      Input:  pixs (1, 8 or 32 bpp)
              dir (L_WARP_TO_LEFT or L_WARP_TO_RIGHT)
              type (L_LINEAR_WARP or L_QUADRATIC_WARP)
              hmax (horizontal displacement at edge)
              incolor (L_BRING_IN_WHITE or L_BRING_IN_BLACK)
      Return: pixd (stretched/compressed), or null on error

  Notes:
      (1) See pixStretchHorizontal() for details.

=head2 pixWarpStereoscopic

PIX * pixWarpStereoscopic ( PIX *pixs, l_int32 zbend, l_int32 zshiftt, l_int32 zshiftb, l_int32 ybendt, l_int32 ybendb, l_int32 redleft )

  pixWarpStereoscopic()

      Input:  pixs (any depth, colormap ok)
              zbend (horizontal separation in pixels of red and cyan
                    at the left and right sides, that gives rise to
                    quadratic curvature out of the image plane)
              zshiftt (uniform pixel translation difference between
                      red and cyan, that pushes the top of the image
                      plane away from the viewer (zshiftt > 0) or
                      towards the viewer (zshiftt < 0))
              zshiftb (uniform pixel translation difference between
                      red and cyan, that pushes the bottom of the image
                      plane away from the viewer (zshiftb > 0) or
                      towards the viewer (zshiftb < 0))
              ybendt (multiplicative parameter for in-plane vertical
                      displacement at the left or right edge at the top:
                        y = ybendt * (2x/w - 1)^2 )
              ybendb (same as ybendt, except at the left or right edge
                      at the bottom)
              redleft (1 if the red filter is on the left; 0 otherwise)
      Return: pixd (32 bpp), or null on error

  Notes:
      (1) This function splits out the red channel, mucks around with
          it, then recombines with the unmolested cyan channel.
      (2) By using a quadratically increasing shift of the red
          pixels horizontally and away from the vertical centerline,
          the image appears to bend quadratically out of the image
          plane, symmetrically with respect to the vertical center
          line.  A positive value of @zbend causes the plane to be
          curved away from the viewer.  We use linearly interpolated
          stretching to avoid the appearance of kinks in the curve.
      (3) The parameters @zshiftt and @zshiftb tilt the image plane
          about a horizontal line through the center, and at the
          same time move that line either in toward the viewer or away.
          This is implemented by a combination of horizontal shear
          about the center line (for the tilt) and horizontal
          translation (to move the entire plane in or out).
          A positive value of @zshiftt moves the top of the plane
          away from the viewer, and a positive value of @zshiftb
          moves the bottom of the plane away.  We use linear interpolated
          shear to avoid visible vertical steps in the tilted image.
      (4) The image can be bent in the plane and about the vertical
          centerline.  The centerline does not shift, and the
          parameter @ybend gives the relative shift at left and right
          edges, with a downward shift for positive values of @ybend.
      (6) When writing out a steroscopic (red/cyan) image in jpeg,
          first call pixSetChromaSampling(pix, 0) to get sufficient
          resolution in the red channel.
      (7) Typical values are:
             zbend = 20
             zshiftt = 15
             zshiftb = -15
             ybendt = 30
             ybendb = 0
          If the disparity z-values are too large, it is difficult for
          the brain to register the two images.
      (8) This function has been cleverly reimplemented by Jeff Breidenbach.
          The original implementation used two 32 bpp rgb images,
          and merged them at the end.  The result is somewhat faded,
          and has a parameter "thresh" that controls the amount of
          color in the result.  (The present implementation avoids these
          two problems, skipping both the colorization and the alpha
          blending at the end, and is about 3x faster)
          The basic operations with 32 bpp are as follows:
               // Immediate conversion to 32 bpp
            Pix *pixt1 = pixConvertTo32(pixs);
               // Do vertical shear
            Pix *pixr = pixQuadraticVerticalShear(pixt1, L_WARP_TO_RIGHT,
                                                  ybendt, ybendb,
                                                  L_BRING_IN_WHITE);
               // Colorize two versions, toward red and cyan
            Pix *pixc = pixCopy(NULL, pixr);
            l_int32 thresh = 150;  // if higher, get less original color
            pixColorGray(pixr, NULL, L_PAINT_DARK, thresh, 255, 0, 0);
            pixColorGray(pixc, NULL, L_PAINT_DARK, thresh, 0, 255, 255);
               // Shift the red pixels; e.g., by stretching
            Pix *pixrs = pixStretchHorizontal(pixr, L_WARP_TO_RIGHT,
                                              L_QUADRATIC_WARP, zbend,
                                              L_INTERPOLATED,
                                              L_BRING_IN_WHITE);
               // Blend the shifted red and unshifted cyan 50:50
            Pix *pixg = pixCreate(w, h, 8);
            pixSetAllArbitrary(pixg, 128);
            pixd = pixBlendWithGrayMask(pixrs, pixc, pixg, 0, 0);

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
