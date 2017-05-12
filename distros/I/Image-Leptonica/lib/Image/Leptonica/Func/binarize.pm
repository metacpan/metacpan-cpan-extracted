package Image::Leptonica::Func::binarize;
$Image::Leptonica::Func::binarize::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::binarize

=head1 VERSION

version 0.04

=head1 C<binarize.c>

  binarize.c

  ===================================================================
  Image binarization algorithms are found in:
    grayquant.c:   standard, simple, general grayscale quantization
    adaptmap.c:    local adaptive; mostly gray-to-gray in preparation
                   for binarization
    binarize.c:    special binarization methods, locally adaptive.
  ===================================================================

      Adaptive Otsu-based thresholding
          l_int32    pixOtsuAdaptiveThreshold()       8 bpp

      Otsu thresholding on adaptive background normalization
          PIX       *pixOtsuThreshOnBackgroundNorm()  8 bpp

      Masking and Otsu estimate on adaptive background normalization
          PIX       *pixMaskedThreshOnBackgroundNorm()  8 bpp

      Sauvola local thresholding
          l_int32    pixSauvolaBinarizeTiled()
          l_int32    pixSauvolaBinarize()
          PIX       *pixSauvolaGetThreshold()
          PIX       *pixApplyLocalThreshold();

  Notes:
      (1) pixOtsuAdaptiveThreshold() computes a global threshold over each
          tile and performs the threshold operation, resulting in a
          binary image for each tile.  These are stitched into the
          final result.
      (2) pixOtsuThreshOnBackgroundNorm() and
          pixMaskedThreshOnBackgroundNorm() are binarization functions
          that use background normalization with other techniques.
      (3) Sauvola binarization computes a local threshold based on
          the local average and square average.  It takes two constants:
          the window size for the measurment at each pixel and a
          parameter that determines the amount of normalized local
          standard deviation to subtract from the local average value.

=head1 FUNCTIONS

=head2 pixApplyLocalThreshold

PIX * pixApplyLocalThreshold ( PIX *pixs, PIX *pixth, l_int32 redfactor )

  pixApplyLocalThreshold()

      Input:  pixs (8 bpp grayscale; not colormapped)
              pixth (8 bpp array of local thresholds)
              redfactor ( ... )
      Return: pixd (1 bpp, thresholded image), or null on error

=head2 pixMaskedThreshOnBackgroundNorm

PIX * pixMaskedThreshOnBackgroundNorm ( PIX *pixs, PIX *pixim, l_int32 sx, l_int32 sy, l_int32 thresh, l_int32 mincount, l_int32 smoothx, l_int32 smoothy, l_float32 scorefract, l_int32 *pthresh )

  pixMaskedThreshOnBackgroundNorm()

      Input:  pixs (8 bpp grayscale; not colormapped)
              pixim (<optional> 1 bpp 'image' mask; can be null)
              sx, sy (tile size in pixels)
              thresh (threshold for determining foreground)
              mincount (min threshold on counts in a tile)
              smoothx (half-width of block convolution kernel width)
              smoothy (half-width of block convolution kernel height)
              scorefract (fraction of the max Otsu score; typ. ~ 0.1)
              &thresh (<optional return> threshold value that was
                       used on the normalized image)
      Return: pixd (1 bpp thresholded image), or null on error

  Notes:
      (1) This begins with a standard background normalization.
          Additionally, there is a flexible background norm, that
          will adapt to a rapidly varying background, and this
          puts white pixels in the background near regions with
          significant foreground.  The white pixels are turned into
          a 1 bpp selection mask by binarization followed by dilation.
          Otsu thresholding is performed on the input image to get an
          estimate of the threshold in the non-mask regions.
          The background normalized image is thresholded with two
          different values, and the result is combined using
          the selection mask.
      (2) Note that the numbers 255 (for bgval target) and 190 (for
          thresholding on pixn) are tied together, and explicitly
          defined in this function.
      (3) See pixBackgroundNorm() for meaning and typical values
          of input parameters.  For a start, you can try:
            sx, sy = 10, 15
            thresh = 100
            mincount = 50
            smoothx, smoothy = 2

=head2 pixOtsuAdaptiveThreshold

l_int32 pixOtsuAdaptiveThreshold ( PIX *pixs, l_int32 sx, l_int32 sy, l_int32 smoothx, l_int32 smoothy, l_float32 scorefract, PIX **ppixth, PIX **ppixd )

  pixOtsuAdaptiveThreshold()

      Input:  pixs (8 bpp)
              sx, sy (desired tile dimensions; actual size may vary)
              smoothx, smoothy (half-width of convolution kernel applied to
                                threshold array: use 0 for no smoothing)
              scorefract (fraction of the max Otsu score; typ. 0.1;
                          use 0.0 for standard Otsu)
              &pixth (<optional return> array of threshold values
                      found for each tile)
              &pixd (<optional return> thresholded input pixs, based on
                     the threshold array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The Otsu method finds a single global threshold for an image.
          This function allows a locally adapted threshold to be
          found for each tile into which the image is broken up.
      (2) The array of threshold values, one for each tile, constitutes
          a highly downscaled image.  This array is optionally
          smoothed using a convolution.  The full width and height of the
          convolution kernel are (2 * @smoothx + 1) and (2 * @smoothy + 1).
      (3) The minimum tile dimension allowed is 16.  If such small
          tiles are used, it is recommended to use smoothing, because
          without smoothing, each small tile determines the splitting
          threshold independently.  A tile that is entirely in the
          image bg will then hallucinate fg, resulting in a very noisy
          binarization.  The smoothing should be large enough that no
          tile is only influenced by one type (fg or bg) of pixels,
          because it will force a split of its pixels.
      (4) To get a single global threshold for the entire image, use
          input values of @sx and @sy that are larger than the image.
          For this situation, the smoothing parameters are ignored.
      (5) The threshold values partition the image pixels into two classes:
          one whose values are less than the threshold and another
          whose values are greater than or equal to the threshold.
          This is the same use of 'threshold' as in pixThresholdToBinary().
      (6) The scorefract is the fraction of the maximum Otsu score, which
          is used to determine the range over which the histogram minimum
          is searched.  See numaSplitDistribution() for details on the
          underlying method of choosing a threshold.
      (7) This uses enables a modified version of the Otsu criterion for
          splitting the distribution of pixels in each tile into a
          fg and bg part.  The modification consists of searching for
          a minimum in the histogram over a range of pixel values where
          the Otsu score is within a defined fraction, @scorefract,
          of the max score.  To get the original Otsu algorithm, set
          @scorefract == 0.

=head2 pixOtsuThreshOnBackgroundNorm

PIX * pixOtsuThreshOnBackgroundNorm ( PIX *pixs, PIX *pixim, l_int32 sx, l_int32 sy, l_int32 thresh, l_int32 mincount, l_int32 bgval, l_int32 smoothx, l_int32 smoothy, l_float32 scorefract, l_int32 *pthresh )

  pixOtsuThreshOnBackgroundNorm()

      Input:  pixs (8 bpp grayscale; not colormapped)
              pixim (<optional> 1 bpp 'image' mask; can be null)
              sx, sy (tile size in pixels)
              thresh (threshold for determining foreground)
              mincount (min threshold on counts in a tile)
              bgval (target bg val; typ. > 128)
              smoothx (half-width of block convolution kernel width)
              smoothy (half-width of block convolution kernel height)
              scorefract (fraction of the max Otsu score; typ. 0.1)
              &thresh (<optional return> threshold value that was
                       used on the normalized image)
      Return: pixd (1 bpp thresholded image), or null on error

  Notes:
      (1) This does background normalization followed by Otsu
          thresholding.  Otsu binarization attempts to split the
          image into two roughly equal sets of pixels, and it does
          a very poor job when there are large amounts of dark
          background.  By doing a background normalization first,
          to get the background near 255, we remove this problem.
          Then we use a modified Otsu to estimate the best global
          threshold on the normalized image.
      (2) See pixBackgroundNorm() for meaning and typical values
          of input parameters.  For a start, you can try:
            sx, sy = 10, 15
            thresh = 100
            mincount = 50
            bgval = 255
            smoothx, smoothy = 2

=head2 pixSauvolaBinarize

l_int32 pixSauvolaBinarize ( PIX *pixs, l_int32 whsize, l_float32 factor, l_int32 addborder, PIX **ppixm, PIX **ppixsd, PIX **ppixth, PIX **ppixd )

  pixSauvolaBinarize()

      Input:  pixs (8 bpp grayscale; not colormapped)
              whsize (window half-width for measuring local statistics)
              factor (factor for reducing threshold due to variance; >= 0)
              addborder (1 to add border of width (@whsize + 1) on all sides)
              &pixm (<optional return> local mean values)
              &pixsd (<optional return> local standard deviation values)
              &pixth (<optional return> threshold values)
              &pixd (<optional return> thresholded image)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The window width and height are 2 * @whsize + 1.  The minimum
          value for @whsize is 2; typically it is >= 7..
      (2) The local statistics, measured over the window, are the
          average and standard deviation.
      (3) The measurements of the mean and standard deviation are
          performed inside a border of (@whsize + 1) pixels.  If pixs does
          not have these added border pixels, use @addborder = 1 to add
          it here; otherwise use @addborder = 0.
      (4) The Sauvola threshold is determined from the formula:
            t = m * (1 - k * (1 - s / 128))
          where:
            t = local threshold
            m = local mean
            k = @factor (>= 0)   [ typ. 0.35 ]
            s = local standard deviation, which is maximized at
                127.5 when half the samples are 0 and half are 255.
      (5) The basic idea of Niblack and Sauvola binarization is that
          the local threshold should be less than the median value,
          and the larger the variance, the closer to the median
          it should be chosen.  Typical values for k are between
          0.2 and 0.5.

=head2 pixSauvolaBinarizeTiled

l_int32 pixSauvolaBinarizeTiled ( PIX *pixs, l_int32 whsize, l_float32 factor, l_int32 nx, l_int32 ny, PIX **ppixth, PIX **ppixd )

  pixSauvolaBinarizeTiled()

      Input:  pixs (8 bpp grayscale, not colormapped)
              whsize (window half-width for measuring local statistics)
              factor (factor for reducing threshold due to variance; >= 0)
              nx, ny (subdivision into tiles; >= 1)
              &pixth (<optional return> Sauvola threshold values)
              &pixd (<optional return> thresholded image)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The window width and height are 2 * @whsize + 1.  The minimum
          value for @whsize is 2; typically it is >= 7..
      (2) For nx == ny == 1, this defaults to pixSauvolaBinarize().
      (3) Why a tiled version?
          (a) Because the mean value accumulator is a uint32, overflow
              can occur for an image with more than 16M pixels.
          (b) The mean value accumulator array for 16M pixels is 64 MB.
              The mean square accumulator array for 16M pixels is 128 MB.
              Using tiles reduces the size of these arrays.
          (c) Each tile can be processed independently, in parallel,
              on a multicore processor.
      (4) The Sauvola threshold is determined from the formula:
              t = m * (1 - k * (1 - s / 128))
          See pixSauvolaBinarize() for details.

=head2 pixSauvolaGetThreshold

PIX * pixSauvolaGetThreshold ( PIX *pixm, PIX *pixms, l_float32 factor, PIX **ppixsd )

  pixSauvolaGetThreshold()

      Input:  pixm (8 bpp grayscale; not colormapped)
              pixms (32 bpp)
              factor (factor for reducing threshold due to variance; >= 0)
              &pixsd (<optional return> local standard deviation)
      Return: pixd (8 bpp, sauvola threshold values), or null on error

  Notes:
      (1) The Sauvola threshold is determined from the formula:
            t = m * (1 - k * (1 - s / 128))
          where:
            t = local threshold
            m = local mean
            k = @factor (>= 0)   [ typ. 0.35 ]
            s = local standard deviation, which is maximized at
                127.5 when half the samples are 0 and half are 255.
      (2) See pixSauvolaBinarize() for other details.
      (3) Important definitions and relations for computing averages:
            v == pixel value
            E(p) == expected value of p == average of p over some pixel set
            S(v) == square of v == v * v
            mv == E(v) == expected pixel value == mean value
            ms == E(S(v)) == expected square of pixel values
               == mean square value
            var == variance == expected square of deviation from mean
                == E(S(v - mv)) = E(S(v) - 2 * S(v * mv) + S(mv))
                                = E(S(v)) - S(mv)
                                = ms - mv * mv
            s == standard deviation = sqrt(var)
          So for evaluating the standard deviation in the Sauvola
          threshold, we take
            s = sqrt(ms - mv * mv)

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
