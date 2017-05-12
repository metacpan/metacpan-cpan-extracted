package Image::Leptonica::Func::scale;
$Image::Leptonica::Func::scale::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::scale

=head1 VERSION

version 0.04

=head1 C<scale.c>

  scale.c

         Top-level scaling
               PIX      *pixScale()     ***
               PIX      *pixScaleToSize()     ***
               PIX      *pixScaleGeneral()     ***

         Linearly interpreted (usually up-) scaling
               PIX      *pixScaleLI()     ***
               PIX      *pixScaleColorLI()
               PIX      *pixScaleColor2xLI()   ***
               PIX      *pixScaleColor4xLI()   ***
               PIX      *pixScaleGrayLI()
               PIX      *pixScaleGray2xLI()
               PIX      *pixScaleGray4xLI()

         Scaling by closest pixel sampling
               PIX      *pixScaleBySampling()
               PIX      *pixScaleBySamplingToSize()
               PIX      *pixScaleByIntSubsampling()

         Fast integer factor subsampling RGB to gray and to binary
               PIX      *pixScaleRGBToGrayFast()
               PIX      *pixScaleRGBToBinaryFast()
               PIX      *pixScaleGrayToBinaryFast()

         Downscaling with (antialias) smoothing
               PIX      *pixScaleSmooth() ***
               PIX      *pixScaleRGBToGray2()   [special 2x reduction to gray]

         Downscaling with (antialias) area mapping
               PIX      *pixScaleAreaMap()     ***
               PIX      *pixScaleAreaMap2()

         Binary scaling by closest pixel sampling
               PIX      *pixScaleBinary()

         Scale-to-gray (1 bpp --> 8 bpp; arbitrary downscaling)
               PIX      *pixScaleToGray()
               PIX      *pixScaleToGrayFast()

         Scale-to-gray (1 bpp --> 8 bpp; integer downscaling)
               PIX      *pixScaleToGray2()
               PIX      *pixScaleToGray3()
               PIX      *pixScaleToGray4()
               PIX      *pixScaleToGray6()
               PIX      *pixScaleToGray8()
               PIX      *pixScaleToGray16()

         Scale-to-gray by mipmap(1 bpp --> 8 bpp, arbitrary reduction)
               PIX      *pixScaleToGrayMipmap()

         Grayscale scaling using mipmap
               PIX      *pixScaleMipmap()

         Replicated (integer) expansion (all depths)
               PIX      *pixExpandReplicate()

         Upscale 2x followed by binarization
               PIX      *pixScaleGray2xLIThresh()
               PIX      *pixScaleGray2xLIDither()

         Upscale 4x followed by binarization
               PIX      *pixScaleGray4xLIThresh()
               PIX      *pixScaleGray4xLIDither()

         Grayscale downscaling using min and max
               PIX      *pixScaleGrayMinMax()
               PIX      *pixScaleGrayMinMax2()

         Grayscale downscaling using rank value
               PIX      *pixScaleGrayRankCascade()
               PIX      *pixScaleGrayRank2()

         Helper function for transferring alpha with scaling
               l_int32   pixScaleAndTransferAlpha()

         RGB scaling including alpha (blend) component
               PIX      *pixScaleWithAlpha()   ***

  *** Note: these functions make an implicit assumption about RGB
            component ordering.

=head1 FUNCTIONS

=head2 pixExpandReplicate

PIX * pixExpandReplicate ( PIX *pixs, l_int32 factor )

  pixExpandReplicate()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp)
              factor (integer scale factor for replicative expansion)
      Return: pixd (scaled up), or null on error.

=head2 pixScale

PIX * pixScale ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScale()

      Input:  pixs (1, 2, 4, 8, 16 and 32 bpp)
              scalex, scaley
      Return: pixd, or null on error

  This function scales 32 bpp RGB; 2, 4 or 8 bpp palette color;
  2, 4, 8 or 16 bpp gray; and binary images.

  When the input has palette color, the colormap is removed and
  the result is either 8 bpp gray or 32 bpp RGB, depending on whether
  the colormap has color entries.  Images with 2, 4 or 16 bpp are
  converted to 8 bpp.

  Because pixScale() is meant to be a very simple interface to a
  number of scaling functions, including the use of unsharp masking,
  the type of scaling and the sharpening parameters are chosen
  by default.  Grayscale and color images are scaled using one
  of four methods, depending on the scale factors:
   (1) antialiased subsampling (lowpass filtering followed by
       subsampling, implemented here by area mapping), for scale factors
       less than 0.2
   (2) antialiased subsampling with sharpening, for scale factors
       between 0.2 and 0.7
   (3) linear interpolation with sharpening, for scale factors between
       0.7 and 1.4
   (4) linear interpolation without sharpening, for scale factors >= 1.4.

  One could use subsampling for scale factors very close to 1.0,
  because it preserves sharp edges.  Linear interpolation blurs
  edges because the dest pixels will typically straddle two src edge
  pixels.  Subsmpling removes entire columns and rows, so the edge is
  not blurred.  However, there are two reasons for not doing this.
  First, it moves edges, so that a straight line at a large angle to
  both horizontal and vertical will have noticable kinks where
  horizontal and vertical rasters are removed.  Second, although it
  is very fast, you get good results on sharp edges by applying
  a sharpening filter.

  For images with sharp edges, sharpening substantially improves the
  image quality for scale factors between about 0.2 and about 2.0.
  pixScale() uses a small amount of sharpening by default because
  it strengthens edge pixels that are weak due to anti-aliasing.
  The default sharpening factors are:
      * for scaling factors < 0.7:   sharpfract = 0.2    sharpwidth = 1
      * for scaling factors >= 0.7:  sharpfract = 0.4    sharpwidth = 2
  The cases where the sharpening halfwidth is 1 or 2 have special
  implementations and are about twice as fast as the general case.

  However, sharpening is computationally expensive, and one needs
  to consider the speed-quality tradeoff:
      * For upscaling of RGB images, linear interpolation plus default
        sharpening is about 5 times slower than upscaling alone.
      * For downscaling, area mapping plus default sharpening is
        about 10 times slower than downscaling alone.
  When the scale factor is larger than 1.4, the cost of sharpening,
  which is proportional to image area, is very large compared to the
  incremental quality improvement, so we cut off the default use of
  sharpening at 1.4.  Thus, for scale factors greater than 1.4,
  pixScale() only does linear interpolation.

  In many situations you will get a satisfactory result by scaling
  without sharpening: call pixScaleGeneral() with @sharpfract = 0.0.
  Alternatively, if you wish to sharpen but not use the default
  value, first call pixScaleGeneral() with @sharpfract = 0.0, and
  then sharpen explicitly using pixUnsharpMasking().

  Binary images are scaled to binary by sampling the closest pixel,
  without any low-pass filtering (averaging of neighboring pixels).
  This will introduce aliasing for reductions.  Aliasing can be
  prevented by using pixScaleToGray() instead.

  *** Warning: implicit assumption about RGB component order
               for LI color scaling

=head2 pixScaleAndTransferAlpha

l_int32 pixScaleAndTransferAlpha ( PIX *pixd, PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleAndTransferAlpha()

      Input:  pixd  (32 bpp, scaled image)
              pixs  (32 bpp, original unscaled image)
              scalex, scaley (both > 0.0)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This scales the alpha component of pixs and inserts into pixd.

=head2 pixScaleAreaMap

PIX * pixScaleAreaMap ( PIX *pix, l_float32 scalex, l_float32 scaley )

  pixScaleAreaMap()

      Input:  pixs (2, 4, 8 or 32 bpp; and 2, 4, 8 bpp with colormap)
              scalex, scaley (must both be <= 0.7)
      Return: pixd, or null on error

  Notes:
      (1) This function should only be used when the scale factors are less
          than or equal to 0.7 (i.e., more than about 1.42x reduction).
          If either scale factor is larger than 0.7, we issue a warning
          and invoke pixScale().
      (2) This works only on 2, 4, 8 and 32 bpp images.  If there is
          a colormap, it is removed by converting to RGB.  In other
          cases, we issue a warning and invoke pixScale().
      (3) It does a relatively expensive area mapping computation, to
          avoid antialiasing.  It is about 2x slower than pixScaleSmooth(),
          but the results are much better on fine text.
      (4) This is typically about 20% faster for the special cases of
          2x, 4x, 8x and 16x reduction.
      (5) Surprisingly, there is no speedup (and a slight quality
          impairment) if you do as many successive 2x reductions as
          possible, ending with a reduction with a scale factor larger
          than 0.5.

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixScaleAreaMap2

PIX * pixScaleAreaMap2 ( PIX *pix )

  pixScaleAreaMap2()

      Input:  pixs (2, 4, 8 or 32 bpp; and 2, 4, 8 bpp with colormap)
      Return: pixd, or null on error

  Notes:
      (1) This function does an area mapping (average) for 2x
          reduction.
      (2) This works only on 2, 4, 8 and 32 bpp images.  If there is
          a colormap, it is removed by converting to RGB.
      (3) Speed on 3 GHz processor:
             Color: 160 Mpix/sec
             Gray: 700 Mpix/sec
          This contrasts with the speed of the general pixScaleAreaMap():
             Color: 35 Mpix/sec
             Gray: 50 Mpix/sec
      (4) From (3), we see that this special function is about 4.5x
          faster for color and 14x faster for grayscale
      (5) Consequently, pixScaleAreaMap2() is incorporated into the
          general area map scaling function, for the special cases
          of 2x, 4x, 8x and 16x reduction.

=head2 pixScaleBinary

PIX * pixScaleBinary ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleBinary()

      Input:  pixs (1 bpp)
              scalex, scaley (both > 0.0)
      Return: pixd, or null on error

  Notes:
      (1) This function samples from the source without
          filtering.  As a result, aliasing will occur for
          subsampling (scalex and scaley < 1.0).

=head2 pixScaleByIntSubsampling

PIX * pixScaleByIntSubsampling ( PIX *pixs, l_int32 factor )

  pixScaleByIntSubsampling()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp)
              factor (integer subsampling)
      Return: pixd, or null on error

  Notes:
      (1) Simple interface to pixScaleBySampling(), for
          isotropic integer reduction.
      (2) If @factor == 1, returns a copy.

=head2 pixScaleBySampling

PIX * pixScaleBySampling ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleBySampling()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp)
              scalex, scaley (both > 0.0)
      Return: pixd, or null on error

  Notes:
      (1) This function samples from the source without
          filtering.  As a result, aliasing will occur for
          subsampling (@scalex and/or @scaley < 1.0).
      (2) If @scalex == 1.0 and @scaley == 1.0, returns a copy.

=head2 pixScaleBySamplingToSize

PIX * pixScaleBySamplingToSize ( PIX *pixs, l_int32 wd, l_int32 hd )

  pixScaleBySamplingToSize()

      Input:  pixs (1, 2, 4, 8, 16 and 32 bpp)
              wd  (target width; use 0 if using height as target)
              hd  (target height; use 0 if using width as target)
      Return: pixd, or null on error

  Notes:
      (1) This guarantees that the output scaled image has the
          dimension(s) you specify.
           - To specify the width with isotropic scaling, set @hd = 0.
           - To specify the height with isotropic scaling, set @wd = 0.
           - If both @wd and @hd are specified, the image is scaled
             (in general, anisotropically) to that size.
           - It is an error to set both @wd and @hd to 0.

=head2 pixScaleColor2xLI

PIX * pixScaleColor2xLI ( PIX *pixs )

  pixScaleColor2xLI()

      Input:  pixs  (32 bpp, representing rgb)
      Return: pixd, or null on error

  Notes:
      (1) This is a special case of linear interpolated scaling,
          for 2x upscaling.  It is about 8x faster than using
          the generic pixScaleColorLI(), and about 4x faster than
          using the special 2x scale function pixScaleGray2xLI()
          on each of the three components separately.
      (2) The speed on intel hardware is about
          80 * 10^6 dest-pixels/sec/GHz.

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixScaleColor4xLI

PIX * pixScaleColor4xLI ( PIX *pixs )

  pixScaleColor4xLI()

      Input:  pixs  (32 bpp, representing rgb)
      Return: pixd, or null on error

  Notes:
      (1) This is a special case of color linear interpolated scaling,
          for 4x upscaling.  It is about 3x faster than using
          the generic pixScaleColorLI().
      (2) The speed on intel hardware is about
          30 * 10^6 dest-pixels/sec/GHz
      (3) This scales each component separately, using pixScaleGray4xLI().
          It would be about 4x faster to inline the color code properly,
          in analogy to scaleColor4xLILow(), and I leave this as
          an exercise for someone who really needs it.

=head2 pixScaleColorLI

PIX * pixScaleColorLI ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleColorLI()

      Input:  pixs  (32 bpp, representing rgb)
              scalex, scaley (must both be >= 0.7)
      Return: pixd, or null on error

  Notes:
      (1) If this is used for scale factors less than 0.7,
          it will suffer from antialiasing.  A warning is issued.
          Particularly for document images with sharp edges,
          use pixScaleSmooth() or pixScaleAreaMap() instead.
      (2) For the general case, it's about 4x faster to manipulate
          the color pixels directly, rather than to make images
          out of each of the 3 components, scale each component
          using the pixScaleGrayLI(), and combine the results back
          into an rgb image.
      (3) The speed on intel hardware for the general case (not 2x)
          is about 10 * 10^6 dest-pixels/sec/GHz.  (The special 2x
          case runs at about 80 * 10^6 dest-pixels/sec/GHz.)

=head2 pixScaleGeneral

PIX * pixScaleGeneral ( PIX *pixs, l_float32 scalex, l_float32 scaley, l_float32 sharpfract, l_int32 sharpwidth )

  pixScaleGeneral()

      Input:  pixs (1, 2, 4, 8, 16 and 32 bpp)
              scalex, scaley (both > 0.0)
              sharpfract (use 0.0 to skip sharpening)
              sharpwidth (halfwidth of low-pass filter; typ. 1 or 2)
      Return: pixd, or null on error

  Notes:
      (1) See pixScale() for usage.
      (2) This interface may change in the future, as other special
          cases are added.
      (3) The actual sharpening factors used depend on the maximum
          of the two scale factors (maxscale):
            maxscale <= 0.2:        no sharpening
            0.2 < maxscale < 1.4:   uses the input parameters
            maxscale >= 1.4:        no sharpening
      (4) To avoid sharpening for grayscale and color images with
          scaling factors between 0.2 and 1.4, call this function
          with @sharpfract == 0.0.
      (5) To use arbitrary sharpening in conjunction with scaling,
          call this function with @sharpfract = 0.0, and follow this
          with a call to pixUnsharpMasking() with your chosen parameters.

=head2 pixScaleGray2xLI

PIX * pixScaleGray2xLI ( PIX *pixs )

  pixScaleGray2xLI()

      Input:  pixs (8 bpp grayscale, not cmapped)
      Return: pixd, or null on error

  Notes:
      (1) This is a special case of gray linear interpolated scaling,
          for 2x upscaling.  It is about 6x faster than using
          the generic pixScaleGrayLI().
      (2) The speed on intel hardware is about
          100 * 10^6 dest-pixels/sec/GHz

=head2 pixScaleGray2xLIDither

PIX * pixScaleGray2xLIDither ( PIX *pixs )

  pixScaleGray2xLIDither()

      Input:  pixs (8 bpp, not cmapped)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does 2x upscale on pixs, using linear interpolation,
          followed by Floyd-Steinberg dithering to binary.
      (2) Buffers are used to avoid making a large grayscale image.
          - Two line buffers are used for the src, required for the 2x
            LI upscale.
          - Three line buffers are used for the intermediate image.
            Two are filled with each 2xLI row operation; the third is
            needed because the upscale and dithering ops are out of sync.

=head2 pixScaleGray2xLIThresh

PIX * pixScaleGray2xLIThresh ( PIX *pixs, l_int32 thresh )

  pixScaleGray2xLIThresh()

      Input:  pixs (8 bpp, not cmapped)
              thresh  (between 0 and 256)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does 2x upscale on pixs, using linear interpolation,
          followed by thresholding to binary.
      (2) Buffers are used to avoid making a large grayscale image.

=head2 pixScaleGray4xLI

PIX * pixScaleGray4xLI ( PIX *pixs )

  pixScaleGray4xLI()

      Input:  pixs (8 bpp grayscale, not cmapped)
      Return: pixd, or null on error

  Notes:
      (1) This is a special case of gray linear interpolated scaling,
          for 4x upscaling.  It is about 12x faster than using
          the generic pixScaleGrayLI().
      (2) The speed on intel hardware is about
          160 * 10^6 dest-pixels/sec/GHz.

=head2 pixScaleGray4xLIDither

PIX * pixScaleGray4xLIDither ( PIX *pixs )

  pixScaleGray4xLIDither()

      Input:  pixs (8 bpp, not cmapped)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does 4x upscale on pixs, using linear interpolation,
          followed by Floyd-Steinberg dithering to binary.
      (2) Buffers are used to avoid making a large grayscale image.
          - Two line buffers are used for the src, required for the
            4xLI upscale.
          - Five line buffers are used for the intermediate image.
            Four are filled with each 4xLI row operation; the fifth
            is needed because the upscale and dithering ops are
            out of sync.
      (3) If a full 4x expanded grayscale image can be kept in memory,
          this function is only about 5% faster than separately doing
          a linear interpolation to a large grayscale image, followed
          by error-diffusion dithering to binary.

=head2 pixScaleGray4xLIThresh

PIX * pixScaleGray4xLIThresh ( PIX *pixs, l_int32 thresh )

  pixScaleGray4xLIThresh()

      Input:  pixs (8 bpp)
              thresh  (between 0 and 256)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does 4x upscale on pixs, using linear interpolation,
          followed by thresholding to binary.
      (2) Buffers are used to avoid making a large grayscale image.
      (3) If a full 4x expanded grayscale image can be kept in memory,
          this function is only about 10% faster than separately doing
          a linear interpolation to a large grayscale image, followed
          by thresholding to binary.

=head2 pixScaleGrayLI

PIX * pixScaleGrayLI ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleGrayLI()

      Input:  pixs (8 bpp grayscale, no cmap)
              scalex, scaley (must both be >= 0.7)
      Return: pixd, or null on error

  This function is appropriate for upscaling
  (magnification: scale factors > 1), and for a
  small amount of downscaling (reduction: scale
  factors > 0.5).   For scale factors less than 0.5,
  the best result is obtained by area mapping,
  but this is very expensive.  So for such large
  reductions, it is more appropriate to do low pass
  filtering followed by subsampling, a combination
  which is effectively a cheap form of area mapping.

  Some details follow.

  For each pixel in the dest, this does a linear
  interpolation of 4 neighboring pixels in the src.
  Specifically, consider the UL corner of src and
  dest pixels.  The UL corner of the dest falls within
  a src pixel, whose four corners are the UL corners
  of 4 adjacent src pixels.  The value of the dest
  is taken by linear interpolation using the values of
  the four src pixels and the distance of the UL corner
  of the dest from each corner.

  If the image is expanded so that the dest pixel is
  smaller than the src pixel, such interpolation
  is a reasonable approach.  This interpolation is
  also good for a small image reduction factor that
  is not more than a 2x reduction.

  Note that the linear interpolation algorithm for scaling
  is identical in form to the area-mapping algorithm
  for grayscale rotation.  The latter corresponds to a
  translation of each pixel without scaling.

  This function is NOT optimal if the scaling involves
  a large reduction.    If the image is significantly
  reduced, so that the dest pixel is much larger than
  the src pixels, this interpolation, which is over src
  pixels only near the UL corner of the dest pixel,
  is not going to give a good area-mapping average.
  Because area mapping for image scaling is considerably
  more computationally intensive than linear interpolation,
  we choose not to use it.   For large image reduction,
  linear interpolation over adjacent src pixels
  degenerates asymptotically to subsampling.  But
  subsampling without a low-pass pre-filter causes
  aliasing by the nyquist theorem.  To avoid aliasing,
  a low-pass filter (e.g., an averaging filter) of
  size roughly equal to the dest pixel (i.e., the
  reduction factor) should be applied to the src before
  subsampling.

  As an alternative to low-pass filtering and subsampling
  for large reduction factors, linear interpolation can
  also be done between the (widely separated) src pixels in
  which the corners of the dest pixel lie.  This also is
  not optimal, as it samples src pixels only near the
  corners of the dest pixel, and it is not implemented.

  Summary:
    (1) If this is used for scale factors less than 0.7,
        it will suffer from antialiasing.  A warning is issued.
        Particularly for document images with sharp edges,
        use pixScaleSmooth() or pixScaleAreaMap() instead.
    (2) The speed on intel hardware for the general case (not 2x)
        is about 13 * 10^6 dest-pixels/sec/GHz.  (The special 2x
        case runs at about 100 * 10^6 dest-pixels/sec/GHz.)

=head2 pixScaleGrayMinMax

PIX * pixScaleGrayMinMax ( PIX *pixs, l_int32 xfact, l_int32 yfact, l_int32 type )

  pixScaleGrayMinMax()

      Input:  pixs (8 bpp, not cmapped)
              xfact (x downscaling factor; integer)
              yfact (y downscaling factor; integer)
              type (L_CHOOSE_MIN, L_CHOOSE_MAX, L_CHOOSE_MAX_MIN_DIFF)
      Return: pixd (8 bpp)

  Notes:
      (1) The downscaled pixels in pixd are the min, max or (max - min)
          of the corresponding set of xfact * yfact pixels in pixs.
      (2) Using L_CHOOSE_MIN is equivalent to a grayscale erosion,
          using a brick Sel of size (xfact * yfact), followed by
          subsampling within each (xfact * yfact) cell.  Using
          L_CHOOSE_MAX is equivalent to the corresponding dilation.
      (3) Using L_CHOOSE_MAX_MIN_DIFF finds the difference between max
          and min values in each cell.
      (4) For the special case of downscaling by 2x in both directions,
          pixScaleGrayMinMax2() is about 2x more efficient.

=head2 pixScaleGrayMinMax2

PIX * pixScaleGrayMinMax2 ( PIX *pixs, l_int32 type )

  pixScaleGrayMinMax2()

      Input:  pixs (8 bpp, not cmapped)
              type (L_CHOOSE_MIN, L_CHOOSE_MAX, L_CHOOSE_MAX_MIN_DIFF)
      Return: pixd (8 bpp downscaled by 2x)

  Notes:
      (1) Special version for 2x reduction.  The downscaled pixels
          in pixd are the min, max or (max - min) of the corresponding
          set of 4 pixels in pixs.
      (2) The max and min operations are a special case (for levels 1
          and 4) of grayscale analog to the binary rank scaling operation
          pixReduceRankBinary2().  Note, however, that because of
          the photometric definition that higher gray values are
          lighter, the erosion-like L_CHOOSE_MIN will darken
          the resulting image, corresponding to a threshold level 1
          in the binary case.  Likewise, L_CHOOSE_MAX will lighten
          the pixd, corresponding to a threshold level of 4.
      (3) To choose any of the four rank levels in a 2x grayscale
          reduction, use pixScaleGrayRank2().
      (4) This runs at about 70 MPix/sec/GHz of source data for
          erosion and dilation.

=head2 pixScaleGrayRank2

PIX * pixScaleGrayRank2 ( PIX *pixs, l_int32 rank )

  pixScaleGrayRank2()

      Input:  pixs (8 bpp, no cmap)
              rank (1 (darkest), 2, 3, 4 (lightest))
      Return: pixd (8 bpp, downscaled by 2x)

  Notes:
      (1) Rank 2x reduction.  If rank == 1(4), the downscaled pixels
          in pixd are the min(max) of the corresponding set of
          4 pixels in pixs.  Values 2 and 3 are intermediate.
      (2) This is the grayscale analog to the binary rank scaling operation
          pixReduceRankBinary2().  Here, because of the photometric
          definition that higher gray values are lighter, rank 1 gives
          the darkest pixel, whereas rank 4 gives the lightest pixel.
          This is opposite to the binary rank operation.
      (3) For rank = 1 and 4, this calls pixScaleGrayMinMax2(),
          which runs at about 70 MPix/sec/GHz of source data.
          For rank 2 and 3, this runs 3x slower, at about 25 MPix/sec/GHz.

=head2 pixScaleGrayRankCascade

PIX * pixScaleGrayRankCascade ( PIX *pixs, l_int32 level1, l_int32 level2, l_int32 level3, l_int32 level4 )

  pixScaleGrayRankCascade()

      Input:  pixs (8 bpp, not cmapped)
              level1, ... level4 (rank thresholds, in set {0, 1, 2, 3, 4})
      Return: pixd (8 bpp, downscaled by up to 16x)

  Notes:
      (1) This performs up to four cascaded 2x rank reductions.
      (2) Use level = 0 to truncate the cascade.

=head2 pixScaleGrayToBinaryFast

PIX * pixScaleGrayToBinaryFast ( PIX *pixs, l_int32 factor, l_int32 thresh )

  pixScaleGrayToBinaryFast()

      Input:  pixs (8 bpp grayscale)
              factor (integer reduction factor >= 1)
              thresh (binarization threshold)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does simultaneous subsampling by an integer factor and
          thresholding from gray to binary.
      (2) It is designed for maximum speed, and is used for quickly
          generating a downsized binary image from a higher resolution
          gray image.  This would typically be used for image analysis.

=head2 pixScaleLI

PIX * pixScaleLI ( PIX *pixs, l_float32 scalex, l_float32 scaley )

  pixScaleLI()

      Input:  pixs (2, 4, 8 or 32 bpp; with or without colormap)
              scalex, scaley (must both be >= 0.7)
      Return: pixd, or null on error

  Notes:
      (1) This function should only be used when the scale factors are
          greater than or equal to 0.7, and typically greater than 1.
          If either scale factor is smaller than 0.7, we issue a warning
          and invoke pixScale().
      (2) This works on 2, 4, 8, 16 and 32 bpp images, as well as on
          2, 4 and 8 bpp images that have a colormap.  If there is a
          colormap, it is removed to either gray or RGB, depending
          on the colormap.
      (3) This does a linear interpolation on the src image.
      (4) It dispatches to much faster implementations for
          the special cases of 2x and 4x expansion.

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixScaleMipmap

PIX * pixScaleMipmap ( PIX *pixs1, PIX *pixs2, l_float32 scale )

  pixScaleMipmap()

      Input:  pixs1 (high res 8 bpp, no cmap)
              pixs2 (low res -- 2x reduced -- 8 bpp, no cmap)
              scale (reduction with respect to high res image, > 0.5)
      Return: 8 bpp pix, scaled down by reduction in each direction,
              or NULL on error.

  Notes:
      (1) See notes in pixScaleToGrayMipmap().
      (2) This function suffers from aliasing effects that are
          easily seen in document images.

=head2 pixScaleRGBToBinaryFast

PIX * pixScaleRGBToBinaryFast ( PIX *pixs, l_int32 factor, l_int32 thresh )

  pixScaleRGBToBinaryFast()

      Input:  pixs (32 bpp RGB)
              factor (integer reduction factor >= 1)
              thresh (binarization threshold)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This does simultaneous subsampling by an integer factor and
          conversion from RGB to gray to binary.
      (2) It is designed for maximum speed, and is used for quickly
          generating a downsized binary image from a higher resolution
          RGB image.  This would typically be used for image analysis.
      (3) It uses the green channel to represent the RGB pixel intensity.

=head2 pixScaleRGBToGray2

PIX * pixScaleRGBToGray2 ( PIX *pixs, l_float32 rwt, l_float32 gwt, l_float32 bwt )

  pixScaleRGBToGray2()

      Input:  pixs (32 bpp rgb)
              rwt, gwt, bwt (must sum to 1.0)
      Return: pixd, (8 bpp, 2x reduced), or null on error

=head2 pixScaleRGBToGrayFast

PIX * pixScaleRGBToGrayFast ( PIX *pixs, l_int32 factor, l_int32 color )

  pixScaleRGBToGrayFast()

      Input:  pixs (32 bpp rgb)
              factor (integer reduction factor >= 1)
              color (one of COLOR_RED, COLOR_GREEN, COLOR_BLUE)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) This does simultaneous subsampling by an integer factor and
          extraction of the color from the RGB pix.
      (2) It is designed for maximum speed, and is used for quickly
          generating a downsized grayscale image from a higher resolution
          RGB image.  This would typically be used for image analysis.
      (3) The standard color byte order (RGBA) is assumed.

=head2 pixScaleSmooth

PIX * pixScaleSmooth ( PIX *pix, l_float32 scalex, l_float32 scaley )

  pixScaleSmooth()

      Input:  pixs (2, 4, 8 or 32 bpp; and 2, 4, 8 bpp with colormap)
              scalex, scaley (must both be < 0.7)
      Return: pixd, or null on error

  Notes:
      (1) This function should only be used when the scale factors are less
          than or equal to 0.7 (i.e., more than about 1.42x reduction).
          If either scale factor is larger than 0.7, we issue a warning
          and invoke pixScale().
      (2) This works only on 2, 4, 8 and 32 bpp images, and if there is
          a colormap, it is removed by converting to RGB.  In other
          cases, we issue a warning and invoke pixScale().
      (3) It does simple (flat filter) convolution, with a filter size
          commensurate with the amount of reduction, to avoid antialiasing.
      (4) It does simple subsampling after smoothing, which is appropriate
          for this range of scaling.  Linear interpolation gives essentially
          the same result with more computation for these scale factors,
          so we don't use it.
      (5) The result is the same as doing a full block convolution followed by
          subsampling, but this is faster because the results of the block
          convolution are only computed at the subsampling locations.
          In fact, the computation time is approximately independent of
          the scale factor, because the convolution kernel is adjusted
          so that each source pixel is summed approximately once.

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixScaleToGray

PIX * pixScaleToGray ( PIX *pixs, l_float32 scalefactor )

  pixScaleToGray()

      Input:  pixs (1 bpp)
              scalefactor (reduction: must be > 0.0 and < 1.0)
      Return: pixd (8 bpp), scaled down by scalefactor in each direction,
              or NULL on error.

  Notes:

  For faster scaling in the range of scalefactors from 0.0625 to 0.5,
  with very little difference in quality, use pixScaleToGrayFast().

  Binary images have sharp edges, so they intrinsically have very
  high frequency content.  To avoid aliasing, they must be low-pass
  filtered, which tends to blur the edges.  How can we keep relatively
  crisp edges without aliasing?  The trick is to do binary upscaling
  followed by a power-of-2 scaleToGray.  For large reductions, where
  you don't end up with much detail, some corners can be cut.

  The intent here is to get high quality reduced grayscale
  images with relatively little computation.  We do binary
  pre-scaling followed by scaleToGrayN() for best results,
  esp. to avoid excess blur when the scale factor is near
  an inverse power of 2.  Where a low-pass filter is required,
  we use simple convolution kernels: either the hat filter for
  linear interpolation or a flat filter for larger downscaling.
  Other choices, such as a perfect bandpass filter with infinite extent
  (the sinc) or various approximations to it (e.g., lanczos), are
  unnecessarily expensive.

  The choices made are as follows:
      (1) Do binary upscaling before scaleToGrayN() for scalefactors > 1/8
      (2) Do binary downscaling before scaleToGray8() for scalefactors
          between 1/16 and 1/8.
      (3) Use scaleToGray16() before grayscale downscaling for
          scalefactors less than 1/16
  Another reasonable choice would be to start binary downscaling
  for scalefactors below 1/4, rather than below 1/8 as we do here.

  The general scaling rules, not all of which are used here, go as follows:
      (1) For grayscale upscaling, use pixScaleGrayLI().  However,
          note that edges will be visibly blurred for scalefactors
          near (but above) 1.0.  Replication will avoid edge blur,
          and should be considered for factors very near 1.0.
      (2) For grayscale downscaling with a scale factor larger than
          about 0.7, use pixScaleGrayLI().  For scalefactors near
          (but below) 1.0, you tread between Scylla and Charybdis.
          pixScaleGrayLI() again gives edge blurring, but
          pixScaleBySampling() gives visible aliasing.
      (3) For grayscale downscaling with a scale factor smaller than
          about 0.7, use pixScaleSmooth()
      (4) For binary input images, do as much scale to gray as possible
          using the special integer functions (2, 3, 4, 8 and 16).
      (5) It is better to upscale in binary, followed by scaleToGrayN()
          than to do scaleToGrayN() followed by an upscale using either
          LI or oversampling.
      (6) It may be better to downscale in binary, followed by
          scaleToGrayN() than to first use scaleToGrayN() followed by
          downscaling.  For downscaling between 8x and 16x, this is
          a reasonable option.
      (7) For reductions greater than 16x, it's reasonable to use
          scaleToGray16() followed by further grayscale downscaling.

=head2 pixScaleToGray16

PIX * pixScaleToGray16 ( PIX *pixs )

  pixScaleToGray16()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 16x in each direction,
              or null on error.

=head2 pixScaleToGray2

PIX * pixScaleToGray2 ( PIX *pixs )

  pixScaleToGray2()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 2x in each direction,
              or null on error.

=head2 pixScaleToGray3

PIX * pixScaleToGray3 ( PIX *pixs )

  pixScaleToGray3()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 3x in each direction,
              or null on error.

  Notes:
      (1) Speed is about 100 x 10^6 src-pixels/sec/GHz.
          Another way to express this is it processes 1 src pixel
          in about 10 cycles.
      (2) The width of pixd is truncated is truncated to a factor of 8.

=head2 pixScaleToGray4

PIX * pixScaleToGray4 ( PIX *pixs )

  pixScaleToGray4()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 4x in each direction,
              or null on error.

  Notes:
      (1) The width of pixd is truncated is truncated to a factor of 2.

=head2 pixScaleToGray6

PIX * pixScaleToGray6 ( PIX *pixs )

  pixScaleToGray6()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 6x in each direction,
              or null on error.

  Notes:
      (1) The width of pixd is truncated is truncated to a factor of 8.

=head2 pixScaleToGray8

PIX * pixScaleToGray8 ( PIX *pixs )

  pixScaleToGray8()

      Input:  pixs (1 bpp)
      Return: pixd (8 bpp), scaled down by 8x in each direction,
              or null on error

=head2 pixScaleToGrayFast

PIX * pixScaleToGrayFast ( PIX *pixs, l_float32 scalefactor )

  pixScaleToGrayFast()

      Input:  pixs (1 bpp)
              scalefactor (reduction: must be > 0.0 and < 1.0)
      Return: pixd (8 bpp), scaled down by scalefactor in each direction,
              or NULL on error.

  Notes:
      (1) See notes in pixScaleToGray() for the basic approach.
      (2) This function is considerably less expensive than pixScaleToGray()
          for scalefactor in the range (0.0625 ... 0.5), and the
          quality is nearly as good.
      (3) Unlike pixScaleToGray(), which does binary upscaling before
          downscaling for scale factors >= 0.0625, pixScaleToGrayFast()
          first downscales in binary for all scale factors < 0.5, and
          then does a 2x scale-to-gray as the final step.  For
          scale factors < 0.0625, both do a 16x scale-to-gray, followed
          by further grayscale reduction.

=head2 pixScaleToGrayMipmap

PIX * pixScaleToGrayMipmap ( PIX *pixs, l_float32 scalefactor )

  pixScaleToGrayMipmap()

      Input:  pixs (1 bpp)
              scalefactor (reduction: must be > 0.0 and < 1.0)
      Return: pixd (8 bpp), scaled down by scalefactor in each direction,
              or NULL on error.

  Notes:

  This function is here mainly for pedagogical reasons.
  Mip-mapping is widely used in graphics for texture mapping, because
  the texture changes smoothly with scale.  This is accomplished by
  constructing a multiresolution pyramid and, for each pixel,
  doing a linear interpolation between corresponding pixels in
  the two planes of the pyramid that bracket the desired resolution.
  The computation is very efficient, and is implemented in hardware
  in high-end graphics cards.

  We can use mip-mapping for scale-to-gray by using two scale-to-gray
  reduced images (we don't need the entire pyramid) selected from
  the set {2x, 4x, ... 16x}, and interpolating.  However, we get
  severe aliasing, probably because we are subsampling from the
  higher resolution image.  The method is very fast, but the result
  is very poor.  In fact, the results don't look any better than
  either subsampling off the higher-res grayscale image or oversampling
  on the lower-res image.  Consequently, this method should NOT be used
  for generating reduced images, scale-to-gray or otherwise.

=head2 pixScaleToSize

PIX * pixScaleToSize ( PIX *pixs, l_int32 wd, l_int32 hd )

  pixScaleToSize()

      Input:  pixs (1, 2, 4, 8, 16 and 32 bpp)
              wd  (target width; use 0 if using height as target)
              hd  (target height; use 0 if using width as target)
      Return: pixd, or null on error

  Notes:
      (1) This guarantees that the output scaled image has the
          dimension(s) you specify.
           - To specify the width with isotropic scaling, set @hd = 0.
           - To specify the height with isotropic scaling, set @wd = 0.
           - If both @wd and @hd are specified, the image is scaled
             (in general, anisotropically) to that size.
           - It is an error to set both @wd and @hd to 0.

=head2 pixScaleWithAlpha

PIX * pixScaleWithAlpha ( PIX *pixs, l_float32 scalex, l_float32 scaley, PIX *pixg, l_float32 fract )

  pixScaleWithAlpha()

      Input:  pixs (32 bpp rgb or cmapped)
              scalex, scaley (must be > 0.0)
              pixg (<optional> 8 bpp, can be null)
              fract (between 0.0 and 1.0, with 0.0 fully transparent
                     and 1.0 fully opaque)
      Return: pixd (32 bpp rgba), or null on error

  Notes:
      (1) The alpha channel is transformed separately from pixs,
          and aligns with it, being fully transparent outside the
          boundary of the transformed pixs.  For pixels that are fully
          transparent, a blending function like pixBlendWithGrayMask()
          will give zero weight to corresponding pixels in pixs.
      (2) Scaling is done with area mapping or linear interpolation,
          depending on the scale factors.  Default sharpening is done.
      (3) If pixg is NULL, it is generated as an alpha layer that is
          partially opaque, using @fract.  Otherwise, it is cropped
          to pixs if required, and @fract is ignored.  The alpha
          channel in pixs is never used.
      (4) Colormaps are removed to 32 bpp.
      (5) The default setting for the border values in the alpha channel
          is 0 (transparent) for the outermost ring of pixels and
          (0.5 * fract * 255) for the second ring.  When blended over
          a second image, this
          (a) shrinks the visible image to make a clean overlap edge
              with an image below, and
          (b) softens the edges by weakening the aliasing there.
          Use l_setAlphaMaskBorder() to change these values.
      (6) A subtle use of gamma correction is to remove gamma correction
          before scaling and restore it afterwards.  This is done
          by sandwiching this function between a gamma/inverse-gamma
          photometric transform:
              pixt = pixGammaTRCWithAlpha(NULL, pixs, 1.0 / gamma, 0, 255);
              pixd = pixScaleWithAlpha(pixt, scalex, scaley, NULL, fract);
              pixGammaTRCWithAlpha(pixd, pixd, gamma, 0, 255);
              pixDestroy(&pixt);
          This has the side-effect of producing artifacts in the very
          dark regions.

  *** Warning: implicit assumption about RGB component ordering 

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
