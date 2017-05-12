package Image::Leptonica::Func::convolve;
$Image::Leptonica::Func::convolve::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::convolve

=head1 VERSION

version 0.04

=head1 C<convolve.c>

  convolve.c

      Top level grayscale or color block convolution
          PIX       *pixBlockconv()

      Grayscale block convolution
          PIX       *pixBlockconvGray()

      Accumulator for 1, 8 and 32 bpp convolution
          PIX       *pixBlockconvAccum()

      Un-normalized grayscale block convolution
          PIX       *pixBlockconvGrayUnnormalized()

      Tiled grayscale or color block convolution
          PIX       *pixBlockconvTiled()
          PIX       *pixBlockconvGrayTile()

      Convolution for mean, mean square, variance and rms deviation
      in specified window
          l_int32    pixWindowedStats()
          PIX       *pixWindowedMean()
          PIX       *pixWindowedMeanSquare()
          l_int32    pixWindowedVariance()
          DPIX      *pixMeanSquareAccum()

      Binary block sum and rank filter
          PIX       *pixBlockrank()
          PIX       *pixBlocksum()

      Census transform
          PIX       *pixCensusTransform()

      Generic convolution (with Pix)
          PIX       *pixConvolve()
          PIX       *pixConvolveSep()
          PIX       *pixConvolveRGB()
          PIX       *pixConvolveRGBSep()

      Generic convolution (with float arrays)
          FPIX      *fpixConvolve()
          FPIX      *fpixConvolveSep()

      Convolution with bias (for non-negative output)
          PIX       *pixConvolveWithBias()

      Set parameter for convolution subsampling
          void       l_setConvolveSampling()

      Additive gaussian noise
          PIX       *pixAddGaussNoise()
          l_float32  gaussDistribSampling()

=head1 FUNCTIONS

=head2 fpixConvolve

FPIX * fpixConvolve ( FPIX *fpixs, L_KERNEL *kel, l_int32 normflag )

  fpixConvolve()

      Input:  fpixs (32 bit float array)
              kernel
              normflag (1 to normalize kernel to unit sum; 0 otherwise)
      Return: fpixd (32 bit float array)

  Notes:
      (1) This gives a float convolution with an arbitrary kernel.
      (2) If normflag == 1, the result is normalized by scaling all
          kernel values for a unit sum.  If the sum of kernel values
          is very close to zero, the kernel can not be normalized and
          the convolution will not be performed.  A warning is issued.
      (3) With the FPix, there are no issues about negative
          array or kernel values.  The convolution is performed
          with single precision arithmetic.
      (4) To get a subsampled output, call l_setConvolveSampling().
          The time to make a subsampled output is reduced by the
          product of the sampling factors.
      (5) This uses a mirrored border to avoid special casing on
          the boundaries.

=head2 fpixConvolveSep

FPIX * fpixConvolveSep ( FPIX *fpixs, L_KERNEL *kelx, L_KERNEL *kely, l_int32 normflag )

  fpixConvolveSep()

      Input:  fpixs (32 bit float array)
              kelx (x-dependent kernel)
              kely (y-dependent kernel)
              normflag (1 to normalize kernel to unit sum; 0 otherwise)
      Return: fpixd (32 bit float array)

  Notes:
      (1) This does a convolution with a separable kernel that is
          is a sequence of convolutions in x and y.  The two
          one-dimensional kernel components must be input separately;
          the full kernel is the product of these components.
          The support for the full kernel is thus a rectangular region.
      (2) The normflag parameter is used as in fpixConvolve().
      (3) Warning: if you use l_setConvolveSampling() to get a
          subsampled output, and the sampling factor is larger than
          the kernel half-width, it is faster to use the non-separable
          version pixConvolve().  This is because the first convolution
          here must be done on every raster line, regardless of the
          vertical sampling factor.  If the sampling factor is smaller
          than kernel half-width, it's faster to use the separable
          convolution.
      (4) This uses mirrored borders to avoid special casing on
          the boundaries.

=head2 gaussDistribSampling

l_float32 gaussDistribSampling (  )

  gaussDistribSampling()

      Return: gaussian distributed variable with zero mean and unit stdev

  Notes:
      (1) For an explanation of the Box-Muller method for generating
          a normally distributed random variable with zero mean and
          unit standard deviation, see Numerical Recipes in C,
          2nd edition, p. 288ff.
      (2) This can be called sequentially to get samples that can be
          used for adding noise to each pixel of an image, for example.

=head2 l_setConvolveSampling

void l_setConvolveSampling ( l_int32 xfact, l_int32 yfact )

  l_setConvolveSampling()

      Input:  xfact, yfact (integer >= 1)
      Return: void

  Notes:
      (1) This sets the x and y output subsampling factors for generic pix
          and fpix convolution.  The default values are 1 (no subsampling).

=head2 pixAddGaussianNoise

PIX * pixAddGaussianNoise ( PIX *pixs, l_float32 stdev )

  pixAddGaussianNoise()

      Input:  pixs (8 bpp gray or 32 bpp rgb; no colormap)
              stdev (of noise)
      Return: pixd (8 or 32 bpp), or null on error

  Notes:
      (1) This adds noise to each pixel, taken from a normal
          distribution with zero mean and specified standard deviation.

=head2 pixBlockconv

PIX * pixBlockconv ( PIX *pix, l_int32 wc, l_int32 hc )

  pixBlockconv()

      Input:  pix (8 or 32 bpp; or 2, 4 or 8 bpp with colormap)
              wc, hc   (half width/height of convolution kernel)
      Return: pixd, or null on error

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1)
      (2) Returns a copy if both wc and hc are 0
      (3) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.

=head2 pixBlockconvAccum

PIX * pixBlockconvAccum ( PIX *pixs )

  pixBlockconvAccum()

      Input:  pixs (1, 8 or 32 bpp)
      Return: accum pix (32 bpp), or null on error.

  Notes:
      (1) The general recursion relation is
            a(i,j) = v(i,j) + a(i-1, j) + a(i, j-1) - a(i-1, j-1)
          For the first line, this reduces to the special case
            a(i,j) = v(i,j) + a(i, j-1)
          For the first column, the special case is
            a(i,j) = v(i,j) + a(i-1, j)

=head2 pixBlockconvGray

PIX * pixBlockconvGray ( PIX *pixs, PIX *pixacc, l_int32 wc, l_int32 hc )

  pixBlockconvGray()

      Input:  pix (8 bpp)
              accum pix (32 bpp; can be null)
              wc, hc   (half width/height of convolution kernel)
      Return: pix (8 bpp), or null on error

  Notes:
      (1) If accum pix is null, make one and destroy it before
          returning; otherwise, just use the input accum pix.
      (2) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1).
      (3) Returns a copy if both wc and hc are 0.
      (4) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.

=head2 pixBlockconvGrayTile

PIX * pixBlockconvGrayTile ( PIX *pixs, PIX *pixacc, l_int32 wc, l_int32 hc )

  pixBlockconvGrayTile()

      Input:  pixs (8 bpp gray)
              pixacc (32 bpp accum pix)
              wc, hc   (half width/height of convolution kernel)
      Return: pixd, or null on error

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1)
      (2) Assumes that the input pixs is padded with (wc + 1) pixels on
          left and right, and with (hc + 1) pixels on top and bottom.
          The returned pix has these stripped off; they are only used
          for computation.
      (3) Returns a copy if both wc and hc are 0
      (4) Require that w > 2 * wc + 1 and h > 2 * hc + 1,
          where (w,h) are the dimensions of pixs.

=head2 pixBlockconvGrayUnnormalized

PIX * pixBlockconvGrayUnnormalized ( PIX *pixs, l_int32 wc, l_int32 hc )

  pixBlockconvGrayUnnormalized()

      Input:  pixs (8 bpp)
              wc, hc   (half width/height of convolution kernel)
      Return: pix (32 bpp; containing the convolution without normalizing
                   for the window size), or null on error

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1).
      (2) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.
      (3) Returns a copy if both wc and hc are 0.
      (3) Adds mirrored border to avoid treating the boundary pixels
          specially.  Note that we add wc + 1 pixels to the left
          and wc to the right.  The added width is 2 * wc + 1 pixels,
          and the particular choice simplifies the indexing in the loop.
          Likewise, add hc + 1 pixels to the top and hc to the bottom.
      (4) To get the normalized result, divide by the area of the
          convolution kernel: (2 * wc + 1) * (2 * hc + 1)
          Specifically, do this:
               pixc = pixBlockconvGrayUnnormalized(pixs, wc, hc);
               fract = 1. / ((2 * wc + 1) * (2 * hc + 1));
               pixMultConstantGray(pixc, fract);
               pixd = pixGetRGBComponent(pixc, L_ALPHA_CHANNEL);
      (5) Unlike pixBlockconvGray(), this always computes the accumulation
          pix because its size is tied to wc and hc.
      (6) Compare this implementation with pixBlockconvGray(), where
          most of the code in blockconvLow() is special casing for
          efficiently handling the boundary.  Here, the use of
          mirrored borders and destination indexing makes the
          implementation very simple.

=head2 pixBlockconvTiled

PIX * pixBlockconvTiled ( PIX *pix, l_int32 wc, l_int32 hc, l_int32 nx, l_int32 ny )

  pixBlockconvTiled()

      Input:  pix (8 or 32 bpp; or 2, 4 or 8 bpp with colormap)
              wc, hc   (half width/height of convolution kernel)
              nx, ny  (subdivision into tiles)
      Return: pixd, or null on error

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1)
      (2) Returns a copy if both wc and hc are 0
      (3) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.
      (4) For nx == ny == 1, this defaults to pixBlockconv(), which
          is typically about twice as fast, and gives nearly
          identical results as pixBlockconvGrayTile().
      (5) If the tiles are too small, nx and/or ny are reduced
          a minimum amount so that the tiles are expanded to the
          smallest workable size in the problematic direction(s).
      (6) Why a tiled version?  Three reasons:
          (a) Because the accumulator is a uint32, overflow can occur
              for an image with more than 16M pixels.
          (b) The accumulator array for 16M pixels is 64 MB; using
              tiles reduces the size of this array.
          (c) Each tile can be processed independently, in parallel,
              on a multicore processor.

=head2 pixBlockrank

PIX * pixBlockrank ( PIX *pixs, PIX *pixacc, l_int32 wc, l_int32 hc, l_float32 rank )

  pixBlockrank()

      Input:  pixs (1 bpp)
              accum pix (<optional> 32 bpp)
              wc, hc   (half width/height of block sum/rank kernel)
              rank   (between 0.0 and 1.0; 0.5 is median filter)
      Return: pixd (1 bpp)

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1)
      (2) This returns a pixd where each pixel is a 1 if the
          neighborhood (2 * wc + 1) x (2 * hc + 1)) pixels
          contains the rank fraction of 1 pixels.  Otherwise,
          the returned pixel is 0.  Note that the special case
          of rank = 0.0 is always satisfied, so the returned
          pixd has all pixels with value 1.
      (3) If accum pix is null, make one, use it, and destroy it
          before returning; otherwise, just use the input accum pix
      (4) If both wc and hc are 0, returns a copy unless rank == 0.0,
          in which case this returns an all-ones image.
      (5) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.

=head2 pixBlocksum

PIX * pixBlocksum ( PIX *pixs, PIX *pixacc, l_int32 wc, l_int32 hc )

  pixBlocksum()

      Input:  pixs (1 bpp)
              accum pix (<optional> 32 bpp)
              wc, hc   (half width/height of block sum/rank kernel)
      Return: pixd (8 bpp)

  Notes:
      (1) If accum pix is null, make one and destroy it before
          returning; otherwise, just use the input accum pix
      (2) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1)
      (3) Use of wc = hc = 1, followed by pixInvert() on the
          8 bpp result, gives a nice anti-aliased, and somewhat
          darkened, result on text.
      (4) Require that w >= 2 * wc + 1 and h >= 2 * hc + 1,
          where (w,h) are the dimensions of pixs.
      (5) Returns in each dest pixel the sum of all src pixels
          that are within a block of size of the kernel, centered
          on the dest pixel.  This sum is the number of src ON
          pixels in the block at each location, normalized to 255
          for a block containing all ON pixels.  For pixels near
          the boundary, where the block is not entirely contained
          within the image, we then multiply by a second normalization
          factor that is greater than one, so that all results
          are normalized by the number of participating pixels
          within the block.

=head2 pixCensusTransform

PIX * pixCensusTransform ( PIX *pixs, l_int32 halfsize, PIX *pixacc )

  pixCensusTransform()

      Input:  pixs (8 bpp)
              halfsize (of square over which neighbors are averaged)
              accum pix (<optional> 32 bpp)
      Return: pixd (1 bpp)

  Notes:
      (1) The Census transform was invented by Ramin Zabih and John Woodfill
          ("Non-parametric local transforms for computing visual
          correspondence", Third European Conference on Computer Vision,
          Stockholm, Sweden, May 1994); see publications at
             http://www.cs.cornell.edu/~rdz/index.htm
          This compares each pixel against the average of its neighbors,
          in a square of odd dimension centered on the pixel.
          If the pixel is greater than the average of its neighbors,
          the output pixel value is 1; otherwise it is 0.
      (2) This can be used as an encoding for an image that is
          fairly robust against slow illumination changes, with
          applications in image comparison and mosaicing.
      (3) The size of the convolution kernel is (2 * halfsize + 1)
          on a side.  The halfsize parameter must be >= 1.
      (4) If accum pix is null, make one, use it, and destroy it
          before returning; otherwise, just use the input accum pix

=head2 pixConvolve

PIX * pixConvolve ( PIX *pixs, L_KERNEL *kel, l_int32 outdepth, l_int32 normflag )

  pixConvolve()

      Input:  pixs (8, 16, 32 bpp; no colormap)
              kernel
              outdepth (of pixd: 8, 16 or 32)
              normflag (1 to normalize kernel to unit sum; 0 otherwise)
      Return: pixd (8, 16 or 32 bpp)

  Notes:
      (1) This gives a convolution with an arbitrary kernel.
      (2) The input pixs must have only one sample/pixel.
          To do a convolution on an RGB image, use pixConvolveRGB().
      (3) The parameter @outdepth determines the depth of the result.
          If the kernel is normalized to unit sum, the output values
          can never exceed 255, so an output depth of 8 bpp is sufficient.
          If the kernel is not normalized, it may be necessary to use
          16 or 32 bpp output to avoid overflow.
      (4) If normflag == 1, the result is normalized by scaling all
          kernel values for a unit sum.  If the sum of kernel values
          is very close to zero, the kernel can not be normalized and
          the convolution will not be performed.  A warning is issued.
      (5) The kernel values can be positive or negative, but the
          result for the convolution can only be stored as a positive
          number.  Consequently, if it goes negative, the choices are
          to clip to 0 or take the absolute value.  We're choosing
          to take the absolute value.  (Another possibility would be
          to output a second unsigned image for the negative values.)
          If you want to get a clipped result, or to keep the negative
          values in the result, use fpixConvolve(), with the
          converters in fpix2.c between pix and fpix.
      (6) This uses a mirrored border to avoid special casing on
          the boundaries.
      (7) To get a subsampled output, call l_setConvolveSampling().
          The time to make a subsampled output is reduced by the
          product of the sampling factors.
      (8) The function is slow, running at about 12 machine cycles for
          each pixel-op in the convolution.  For example, with a 3 GHz
          cpu, a 1 Mpixel grayscale image, and a kernel with
          (sx * sy) = 25 elements, the convolution takes about 100 msec.

=head2 pixConvolveRGB

PIX * pixConvolveRGB ( PIX *pixs, L_KERNEL *kel )

  pixConvolveRGB()

      Input:  pixs (32 bpp rgb)
              kernel
      Return: pixd (32 bpp rgb)

  Notes:
      (1) This gives a convolution on an RGB image using an
          arbitrary kernel (which we normalize to keep each
          component within the range [0 ... 255].
      (2) The input pixs must be RGB.
      (3) The kernel values can be positive or negative, but the
          result for the convolution can only be stored as a positive
          number.  Consequently, if it goes negative, we clip the
          result to 0.
      (4) To get a subsampled output, call l_setConvolveSampling().
          The time to make a subsampled output is reduced by the
          product of the sampling factors.
      (5) This uses a mirrored border to avoid special casing on
          the boundaries.

=head2 pixConvolveRGBSep

PIX * pixConvolveRGBSep ( PIX *pixs, L_KERNEL *kelx, L_KERNEL *kely )

  pixConvolveRGBSep()

      Input:  pixs (32 bpp rgb)
              kelx (x-dependent kernel)
              kely (y-dependent kernel)
      Return: pixd (32 bpp rgb)

  Notes:
      (1) This does a convolution on an RGB image using a separable
          kernel that is a sequence of convolutions in x and y.  The two
          one-dimensional kernel components must be input separately;
          the full kernel is the product of these components.
          The support for the full kernel is thus a rectangular region.
      (2) The kernel values can be positive or negative, but the
          result for the convolution can only be stored as a positive
          number.  Consequently, if it goes negative, we clip the
          result to 0.
      (3) To get a subsampled output, call l_setConvolveSampling().
          The time to make a subsampled output is reduced by the
          product of the sampling factors.
      (4) This uses a mirrored border to avoid special casing on
          the boundaries.

=head2 pixConvolveSep

PIX * pixConvolveSep ( PIX *pixs, L_KERNEL *kelx, L_KERNEL *kely, l_int32 outdepth, l_int32 normflag )

  pixConvolveSep()

      Input:  pixs (8, 16, 32 bpp; no colormap)
              kelx (x-dependent kernel)
              kely (y-dependent kernel)
              outdepth (of pixd: 8, 16 or 32)
              normflag (1 to normalize kernel to unit sum; 0 otherwise)
      Return: pixd (8, 16 or 32 bpp)

  Notes:
      (1) This does a convolution with a separable kernel that is
          is a sequence of convolutions in x and y.  The two
          one-dimensional kernel components must be input separately;
          the full kernel is the product of these components.
          The support for the full kernel is thus a rectangular region.
      (2) The input pixs must have only one sample/pixel.
          To do a convolution on an RGB image, use pixConvolveSepRGB().
      (3) The parameter @outdepth determines the depth of the result.
          If the kernel is normalized to unit sum, the output values
          can never exceed 255, so an output depth of 8 bpp is sufficient.
          If the kernel is not normalized, it may be necessary to use
          16 or 32 bpp output to avoid overflow.
      (2) The @normflag parameter is used as in pixConvolve().
      (4) The kernel values can be positive or negative, but the
          result for the convolution can only be stored as a positive
          number.  Consequently, if it goes negative, the choices are
          to clip to 0 or take the absolute value.  We're choosing
          the former for now.  Another possibility would be to output
          a second unsigned image for the negative values.
      (5) Warning: if you use l_setConvolveSampling() to get a
          subsampled output, and the sampling factor is larger than
          the kernel half-width, it is faster to use the non-separable
          version pixConvolve().  This is because the first convolution
          here must be done on every raster line, regardless of the
          vertical sampling factor.  If the sampling factor is smaller
          than kernel half-width, it's faster to use the separable
          convolution.
      (6) This uses mirrored borders to avoid special casing on
          the boundaries.

=head2 pixConvolveWithBias

PIX * pixConvolveWithBias ( PIX *pixs, L_KERNEL *kel1, L_KERNEL *kel2, l_int32 force8, l_int32 *pbias )

  pixConvolveWithBias()

      Input:  pixs (8 bpp; no colormap)
              kel1
              kel2  (can be null; use if separable)
              force8 (if 1, force output to 8 bpp; otherwise, determine
                      output depth by the dynamic range of pixel values)
              &bias (<return> applied bias)
      Return: pixd (8 or 16 bpp)

  Notes:
      (1) This does a convolution with either a single kernel or
          a pair of separable kernels, and automatically applies whatever
          bias (shift) is required so that the resulting pixel values
          are non-negative.
      (2) The kernel is always normalized.  If there are no negative
          values in the kernel, a standard normalized convolution is
          performed, with 8 bpp output.  If the sum of kernel values is
          very close to zero, the kernel can not be normalized and
          the convolution will not be performed.  An error message results.
      (3) If there are negative values in the kernel, the pix is
          converted to an fpix, the convolution is done on the fpix, and
          a bias (shift) may need to be applied.
      (4) If force8 == TRUE and the range of values after the convolution
          is > 255, the output values will be scaled to fit in [0 ... 255].
          If force8 == FALSE, the output will be either 8 or 16 bpp,
          to accommodate the dynamic range of output values without scaling.

=head2 pixMeanSquareAccum

DPIX * pixMeanSquareAccum ( PIX *pixs )

  pixMeanSquareAccum()

      Input:  pixs (8 bpp grayscale)
      Return: dpix (64 bit array), or null on error

  Notes:
      (1) Similar to pixBlockconvAccum(), this computes the
          sum of the squares of the pixel values in such a way
          that the value at (i,j) is the sum of all squares in
          the rectangle from the origin to (i,j).
      (2) The general recursion relation (v are squared pixel values) is
            a(i,j) = v(i,j) + a(i-1, j) + a(i, j-1) - a(i-1, j-1)
          For the first line, this reduces to the special case
            a(i,j) = v(i,j) + a(i, j-1)
          For the first column, the special case is
            a(i,j) = v(i,j) + a(i-1, j)

=head2 pixWindowedMean

PIX * pixWindowedMean ( PIX *pixs, l_int32 wc, l_int32 hc, l_int32 hasborder, l_int32 normflag )

  pixWindowedMean()

      Input:  pixs (8 or 32 bpp grayscale)
              wc, hc   (half width/height of convolution kernel)
              hasborder (use 1 if it already has (wc + 1) border pixels
                         on left and right, and (hc + 1) on top and bottom;
                         use 0 to add kernel-dependent border)
              normflag (1 for normalization to get average in window;
                        0 for the sum in the window (un-normalized))
      Return: pixd (8 or 32 bpp, average over kernel window)

  Notes:
      (1) The input and output depths are the same.
      (2) A set of border pixels of width (wc + 1) on left and right,
          and of height (hc + 1) on top and bottom, must be on the
          pix before the accumulator is found.  The output pixd
          (after convolution) has this border removed.
          If @hasborder = 0, the required border is added.
      (3) Typically, @normflag == 1.  However, if you want the sum
          within the window, rather than a normalized convolution,
          use @normflag == 0.
      (4) This builds a block accumulator pix, uses it here, and
          destroys it.
      (5) The added border, along with the use of an accumulator array,
          allows computation without special treatment of pixels near
          the image boundary, and runs in a time that is independent
          of the size of the convolution kernel.

=head2 pixWindowedMeanSquare

PIX * pixWindowedMeanSquare ( PIX *pixs, l_int32 wc, l_int32 hc, l_int32 hasborder )

  pixWindowedMeanSquare()

      Input:  pixs (8 bpp grayscale)
              wc, hc   (half width/height of convolution kernel)
              hasborder (use 1 if it already has (wc + 1) border pixels
                         on left and right, and (hc + 1) on top and bottom;
                         use 0 to add kernel-dependent border)
      Return: pixd (32 bpp, average over rectangular window of
                    width = 2 * wc + 1 and height = 2 * hc + 1)

  Notes:
      (1) A set of border pixels of width (wc + 1) on left and right,
          and of height (hc + 1) on top and bottom, must be on the
          pix before the accumulator is found.  The output pixd
          (after convolution) has this border removed.
          If @hasborder = 0, the required border is added.
      (2) The advantage is that we are unaffected by the boundary, and
          it is not necessary to treat pixels within @wc and @hc of the
          border differently.  This is because processing for pixd
          only takes place for pixels in pixs for which the
          kernel is entirely contained in pixs.
      (3) Why do we have an added border of width (@wc + 1) and
          height (@hc + 1), when we only need @wc and @hc pixels
          to satisfy this condition?  Answer: the accumulators
          are asymmetric, requiring an extra row and column of
          pixels at top and left to work accurately.
      (4) The added border, along with the use of an accumulator array,
          allows computation without special treatment of pixels near
          the image boundary, and runs in a time that is independent
          of the size of the convolution kernel.

=head2 pixWindowedStats

l_int32 pixWindowedStats ( PIX *pixs, l_int32 wc, l_int32 hc, l_int32 hasborder, PIX **ppixm, PIX **ppixms, FPIX **pfpixv, FPIX **pfpixrv )

  pixWindowedStats()

      Input:  pixs (8 bpp grayscale)
              wc, hc   (half width/height of convolution kernel)
              hasborder (use 1 if it already has (wc + 1) border pixels
                         on left and right, and (hc + 1) on top and bottom;
                         use 0 to add kernel-dependent border)
              &pixm (<optional return> 8 bpp mean value in window)
              &pixms (<optional return> 32 bpp mean square value in window)
              &fpixv (<optional return> float variance in window)
              &fpixrv (<optional return> float rms deviation from the mean)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a high-level convenience function for calculating
          any or all of these derived images.
      (2) If @hasborder = 0, a border is added and the result is
          computed over all pixels in pixs.  Otherwise, no border is
          added and the border pixels are removed from the output images.
      (3) These statistical measures over the pixels in the
          rectangular window are:
            - average value: <p>  (pixm)
            - average squared value: <p*p> (pixms)
            - variance: <(p - <p>)*(p - <p>)> = <p*p> - <p>*<p>  (pixv)
            - square-root of variance: (pixrv)
          where the brackets < .. > indicate that the average value is
          to be taken over the window.
      (4) Note that the variance is just the mean square difference from
          the mean value; and the square root of the variance is the
          root mean square difference from the mean, sometimes also
          called the 'standard deviation'.
      (5) The added border, along with the use of an accumulator array,
          allows computation without special treatment of pixels near
          the image boundary, and runs in a time that is independent
          of the size of the convolution kernel.

=head2 pixWindowedVariance

l_int32 pixWindowedVariance ( PIX *pixm, PIX *pixms, FPIX **pfpixv, FPIX **pfpixrv )

  pixWindowedVariance()

      Input:  pixm (mean over window; 8 or 32 bpp grayscale)
              pixms (mean square over window; 32 bpp)
              &fpixv (<optional return> float variance -- the ms deviation
                      from the mean)
              &fpixrv (<optional return> float rms deviation from the mean)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The mean and mean square values are precomputed, using
          pixWindowedMean() and pixWindowedMeanSquare().
      (2) Either or both of the variance and square-root of variance
          are returned as an fpix, where the variance is the
          average over the window of the mean square difference of
          the pixel value from the mean:
                <(p - <p>)*(p - <p>)> = <p*p> - <p>*<p>
      (3) To visualize the results:
            - for both, use fpixDisplayMaxDynamicRange().
            - for rms deviation, simply convert the output fpix to pix,

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
