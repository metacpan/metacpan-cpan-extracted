package Image::Leptonica::Func::compare;
$Image::Leptonica::Func::compare::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::compare

=head1 VERSION

version 0.04

=head1 C<compare.c>

  compare.c

      Test for pix equality
           l_int32     pixEqual()
           l_int32     pixEqualWithAlpha()
           l_int32     pixEqualWithCmap()
           l_int32     pixUsesCmapColor()

      Binary correlation
           l_int32     pixCorrelationBinary()

      Difference of two images of same size
           l_int32     pixDisplayDiffBinary()
           l_int32     pixCompareBinary()
           l_int32     pixCompareGrayOrRGB()
           l_int32     pixCompareGray()
           l_int32     pixCompareRGB()
           l_int32     pixCompareTiled()

      Other measures of the difference of two images of the same size
           NUMA       *pixCompareRankDifference()
           l_int32     pixTestForSimilarity()
           l_int32     pixGetDifferenceStats()
           NUMA       *pixGetDifferenceHistogram()
           l_int32     pixGetPerceptualDiff()
           l_int32     pixGetPSNR()

      Translated images at the same resolution
           l_int32     pixCompareWithTranslation()
           l_int32     pixBestCorrelation()

=head1 FUNCTIONS

=head2 pixBestCorrelation

l_int32 pixBestCorrelation ( PIX *pix1, PIX *pix2, l_int32 area1, l_int32 area2, l_int32 etransx, l_int32 etransy, l_int32 maxshift, l_int32 *tab8, l_int32 *pdelx, l_int32 *pdely, l_float32 *pscore, l_int32 debugflag )

  pixBestCorrelation()

      Input:  pix1   (1 bpp)
              pix2   (1 bpp)
              area1  (number of on pixels in pix1)
              area2  (number of on pixels in pix2)
              etransx (estimated x translation of pix2 to align with pix1)
              etransy (estimated y translation of pix2 to align with pix1)
              maxshift  (max x and y shift of pix2, around the estimated
                          alignment location, relative to pix1)
              tab8 (<optional> sum tab for ON pixels in byte; can be NULL)
              &delx (<optional return> best x shift of pix2 relative to pix1
              &dely (<optional return> best y shift of pix2 relative to pix1
              &score (<optional return> maximum score found; can be NULL)
              debugflag (<= 0 to skip; positive to generate output.
                         The integer is used to label the debug image.)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This maximizes the correlation score between two 1 bpp images,
          by starting with an estimate of the alignment
          (@etransx, @etransy) and computing the correlation around this.
          It optionally returns the shift (@delx, @dely) that maximizes
          the correlation score when pix2 is shifted by this amount
          relative to pix1.
      (2) Get the centroids of pix1 and pix2, using pixCentroid(),
          to compute (@etransx, @etransy).  Get the areas using
          pixCountPixels().
      (3) The centroid of pix2 is shifted with respect to the centroid
          of pix1 by all values between -maxshiftx and maxshiftx,
          and likewise for the y shifts.  Therefore, the number of
          correlations computed is:
               (2 * maxshiftx + 1) * (2 * maxshifty + 1)
          Consequently, if pix1 and pix2 are large, you should do this
          in a coarse-to-fine sequence.  See the use of this function
          in pixCompareWithTranslation().

=head2 pixCompareBinary

l_int32 pixCompareBinary ( PIX *pix1, PIX *pix2, l_int32 comptype, l_float32 *pfract, PIX **ppixdiff )

  pixCompareBinary()

      Input:  pix1 (1 bpp)
              pix2 (1 bpp)
              comptype (L_COMPARE_XOR, L_COMPARE_SUBTRACT)
              &fract (<return> fraction of pixels that are different)
              &pixdiff (<optional return> pix of difference)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The two images are aligned at the UL corner, and do not
          need to be the same size.
      (2) If using L_COMPARE_SUBTRACT, pix2 is subtracted from pix1.
      (3) The total number of pixels is determined by pix1.

=head2 pixCompareGray

l_int32 pixCompareGray ( PIX *pix1, PIX *pix2, l_int32 comptype, l_int32 plottype, l_int32 *psame, l_float32 *pdiff, l_float32 *prmsdiff, PIX **ppixdiff )

  pixCompareGray()

      Input:  pix1 (8 or 16 bpp, not cmapped)
              pix2 (8 or 16 bpp, not cmapped)
              comptype (L_COMPARE_SUBTRACT, L_COMPARE_ABS_DIFF)
              plottype (gplot plot output type, or 0 for no plot)
              &same (<optional return> 1 if pixel values are identical)
              &diff (<optional return> average difference)
              &rmsdiff (<optional return> rms of difference)
              &pixdiff (<optional return> pix of difference)
      Return: 0 if OK; 1 on error

  Notes:
      (1) See pixCompareGrayOrRGB() for details.
      (2) Use pixCompareGrayOrRGB() if the input pix are colormapped.

=head2 pixCompareGrayOrRGB

l_int32 pixCompareGrayOrRGB ( PIX *pix1, PIX *pix2, l_int32 comptype, l_int32 plottype, l_int32 *psame, l_float32 *pdiff, l_float32 *prmsdiff, PIX **ppixdiff )

  pixCompareGrayOrRGB()

      Input:  pix1 (8 or 16 bpp gray, 32 bpp rgb, or colormapped)
              pix2 (8 or 16 bpp gray, 32 bpp rgb, or colormapped)
              comptype (L_COMPARE_SUBTRACT, L_COMPARE_ABS_DIFF)
              plottype (gplot plot output type, or 0 for no plot)
              &same (<optional return> 1 if pixel values are identical)
              &diff (<optional return> average difference)
              &rmsdiff (<optional return> rms of difference)
              &pixdiff (<optional return> pix of difference)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The two images are aligned at the UL corner, and do not
          need to be the same size.  If they are not the same size,
          the comparison will be made over overlapping pixels.
      (2) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (3) If RGB, each component is compared separately.
      (4) If type is L_COMPARE_ABS_DIFF, pix2 is subtracted from pix1
          and the absolute value is taken.
      (5) If type is L_COMPARE_SUBTRACT, pix2 is subtracted from pix1
          and the result is clipped to 0.
      (6) The plot output types are specified in gplot.h.
          Use 0 if no difference plot is to be made.
      (7) If the images are pixelwise identical, no difference
          plot is made, even if requested.  The result (TRUE or FALSE)
          is optionally returned in the parameter 'same'.
      (8) The average difference (either subtracting or absolute value)
          is optionally returned in the parameter 'diff'.
      (9) The RMS difference is optionally returned in the
          parameter 'rmsdiff'.  For RGB, we return the average of
          the RMS differences for each of the components.

=head2 pixCompareRGB

l_int32 pixCompareRGB ( PIX *pix1, PIX *pix2, l_int32 comptype, l_int32 plottype, l_int32 *psame, l_float32 *pdiff, l_float32 *prmsdiff, PIX **ppixdiff )

  pixCompareRGB()

      Input:  pix1 (32 bpp rgb)
              pix2 (32 bpp rgb)
              comptype (L_COMPARE_SUBTRACT, L_COMPARE_ABS_DIFF)
              plottype (gplot plot output type, or 0 for no plot)
              &same (<optional return> 1 if pixel values are identical)
              &diff (<optional return> average difference)
              &rmsdiff (<optional return> rms of difference)
              &pixdiff (<optional return> pix of difference)
      Return: 0 if OK; 1 on error

  Notes:
      (1) See pixCompareGrayOrRGB() for details.

=head2 pixCompareRankDifference

NUMA * pixCompareRankDifference ( PIX *pix1, PIX *pix2, l_int32 factor )

  pixCompareRankDifference()

      Input:  pix1 (8 bpp gray or 32 bpp rgb, or colormapped)
              pix2 (8 bpp gray or 32 bpp rgb, or colormapped)
              factor (subsampling factor; use 0 or 1 for no subsampling)
      Return: narank (numa of rank difference), or null on error

  Notes:
      (1) This answers the question: if the pixel values in each
          component are compared by absolute difference, for
          any value of difference, what is the fraction of
          pixel pairs that have a difference of this magnitude
          or greater.  For a difference of 0, the fraction is 1.0.
          In this sense, it is a mapping from pixel difference to
          rank order of difference.
      (2) The two images are aligned at the UL corner, and do not
          need to be the same size.  If they are not the same size,
          the comparison will be made over overlapping pixels.
      (3) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (4) If RGB, pixel differences for each component are aggregated
          into a single histogram.

=head2 pixCompareTiled

l_int32 pixCompareTiled ( PIX *pix1, PIX *pix2, l_int32 sx, l_int32 sy, l_int32 type, PIX **ppixdiff )

  pixCompareTiled()

      Input:  pix1 (8 bpp or 32 bpp rgb)
              pix2 (8 bpp 32 bpp rgb)
              sx, sy (tile size; must be > 1)
              type (L_MEAN_ABSVAL or L_ROOT_MEAN_SQUARE)
              &pixdiff (<return> pix of difference)
      Return: 0 if OK; 1 on error

  Notes:
      (1) With L_MEAN_ABSVAL, we compute for each tile the
          average abs value of the pixel component difference between
          the two (aligned) images.  With L_ROOT_MEAN_SQUARE, we
          compute instead the rms difference over all components.
      (2) The two input pix must be the same depth.  Comparison is made
          using UL corner alignment.
      (3) For 32 bpp, the distance between corresponding tiles
          is found by averaging the measured difference over all three
          components of each pixel in the tile.
      (4) The result, pixdiff, contains one pixel for each source tile.

=head2 pixCompareWithTranslation

l_int32 pixCompareWithTranslation ( PIX *pix1, PIX *pix2, l_int32 thresh, l_int32 *pdelx, l_int32 *pdely, l_float32 *pscore, l_int32 debugflag )

  pixCompareWithTranslation()

      Input:  pix1, pix2 (any depth; colormap OK)
              thresh (threshold for converting to 1 bpp)
              &delx (<return> x translation on pix2 to align with pix1)
              &dely (<return> y translation on pix2 to align with pix1)
              &score (<return> correlation score at best alignment)
              debugflag (1 for debug output; 0 for no debugging)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a coarse-to-fine search for best translational
          alignment of two images, measured by a scoring function
          that is the correlation between the fg pixels.
      (2) The threshold is used if the images aren't 1 bpp.
      (3) With debug on, you get a pdf that shows, as a grayscale
          image, the score as a function of shift from the initial
          estimate, for each of the four levels.  The shift is 0 at
          the center of the image.
      (4) With debug on, you also get a pdf that shows the
          difference at the best alignment between the two images,
          at each of the four levels.  The red and green pixels
          show locations where one image has a fg pixel and the
          other doesn't.  The black pixels are where both images
          have fg pixels, and white pixels are where neither image
          has fg pixels.

=head2 pixCorrelationBinary

l_int32 pixCorrelationBinary ( PIX *pix1, PIX *pix2, l_float32 *pval )

  pixCorrelationBinary()

      Input:  pix1 (1 bpp)
              pix2 (1 bpp)
              &val (<return> correlation)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The correlation is a number between 0.0 and 1.0,
          based on foreground similarity:
                           (|1 AND 2|)**2
            correlation =  --------------
                             |1| * |2|
          where |x| is the count of foreground pixels in image x.
          If the images are identical, this is 1.0.
          If they have no fg pixels in common, this is 0.0.
          If one or both images have no fg pixels, the correlation is 0.0.
      (2) Typically the two images are of equal size, but this
          is not enforced.  Instead, the UL corners are aligned.

=head2 pixDisplayDiffBinary

PIX * pixDisplayDiffBinary ( PIX *pix1, PIX *pix2 )

  pixDisplayDiffBinary()

      Input:  pix1 (1 bpp)
              pix2 (1 bpp)
      Return: pixd (4 bpp cmapped), or null on error

  Notes:
      (1) This gives a color representation of the difference between
          pix1 and pix2.  The color difference depends on the order.
          The pixels in pixd have 4 colors:
           * unchanged:  black (on), white (off)
           * on in pix1, off in pix2: red
           * on in pix2, off in pix1: green
      (2) This aligns the UL corners of pix1 and pix2, and crops
          to the overlapping pixels.

=head2 pixEqual

l_int32 pixEqual ( PIX *pix1, PIX *pix2, l_int32 *psame )

  pixEqual()

      Input:  pix1
              pix2
              &same  (<return> 1 if same; 0 if different)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Equality is defined as having the same pixel values for
          each respective image pixel.
      (2) This works on two pix of any depth.  If one or both pix
          have a colormap, the depths can be different and the
          two pix can still be equal.
      (3) This ignores the alpha component for 32 bpp images.
      (4) If both pix have colormaps and the depths are equal,
          use the pixEqualWithCmap() function, which does a fast
          comparison if the colormaps are identical and a relatively
          slow comparison otherwise.
      (5) In all other cases, any existing colormaps must first be
          removed before doing pixel comparison.  After the colormaps
          are removed, the resulting two images must have the same depth.
          The "lowest common denominator" is RGB, but this is only
          chosen when necessary, or when both have colormaps but
          different depths.
      (6) For images without colormaps that are not 32 bpp, all bits
          in the image part of the data array must be identical.

=head2 pixEqualWithAlpha

l_int32 pixEqualWithAlpha ( PIX *pix1, PIX *pix2, l_int32 use_alpha, l_int32 *psame )

  pixEqualWithAlpha()

      Input:  pix1
              pix2
              use_alpha (1 to compare alpha in RGBA; 0 to ignore)
              &same  (<return> 1 if same; 0 if different)
      Return: 0 if OK; 1 on error

  Notes:
      (1) See notes in pixEqual().
      (2) This is more general than pixEqual(), in that for 32 bpp
          RGBA images, where spp = 4, you can optionally include
          the alpha component in the comparison.

=head2 pixEqualWithCmap

l_int32 pixEqualWithCmap ( PIX *pix1, PIX *pix2, l_int32 *psame )

  pixEqualWithCmap()

      Input:  pix1
              pix2
              &same
      Return: 0 if OK, 1 on error

  Notes:
      (1) This returns same = TRUE if the images have identical content.
      (2) Both pix must have a colormap, and be of equal size and depth.
          If these conditions are not satisfied, it is not an error;
          the returned result is same = FALSE.
      (3) We then check whether the colormaps are the same; if so,
          the comparison proceeds 32 bits at a time.
      (4) If the colormaps are different, the comparison is done by
          slow brute force.

=head2 pixGetDifferenceHistogram

NUMA * pixGetDifferenceHistogram ( PIX *pix1, PIX *pix2, l_int32 factor )

  pixGetDifferenceHistogram()

      Input:  pix1 (8 bpp gray or 32 bpp rgb, or colormapped)
              pix2 (8 bpp gray or 32 bpp rgb, or colormapped)
              factor (subsampling factor; use 0 or 1 for no subsampling)
      Return: na (Numa of histogram of differences), or null on error

  Notes:
      (1) The two images are aligned at the UL corner, and do not
          need to be the same size.  If they are not the same size,
          the comparison will be made over overlapping pixels.
      (2) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (3) If RGB, the maximum difference between pixel components is
          saved in the histogram.

=head2 pixGetDifferenceStats

l_int32 pixGetDifferenceStats ( PIX *pix1, PIX *pix2, l_int32 factor, l_int32 mindiff, l_float32 *pfractdiff, l_float32 *pavediff, l_int32 printstats )

  pixGetDifferenceStats()

      Input:  pix1 (8 bpp gray or 32 bpp rgb, or colormapped)
              pix2 (8 bpp gray or 32 bpp rgb, or colormapped)
              factor (subsampling factor; use 0 or 1 for no subsampling)
              mindiff (minimum pixel difference to be counted; > 0)
              &fractdiff (<return> fraction of pixels with diff greater
                          than or equal to mindiff)
              &avediff (<return> average difference of pixels with diff
                        greater than or equal to mindiff, less mindiff)
              printstats (use 1 to print normalized histogram to stderr)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This takes a threshold @mindiff and describes the difference
          between two images in terms of two numbers:
            (a) the fraction of pixels, @fractdiff, whose difference
                equals or exceeds the threshold @mindiff, and
            (b) the average value @avediff of the difference in pixel value
                for the pixels in the set given by (a), after you subtract
                @mindiff.  The reason for subtracting @mindiff is that
                you then get a useful measure for the rate of falloff
                of the distribution for larger differences.  For example,
                if @mindiff = 10 and you find that @avediff = 2.5, it
                says that of the pixels with diff > 10, the average of
                their diffs is just mindiff + 2.5 = 12.5.  This is a
                fast falloff in the histogram with increasing difference.
      (2) The two images are aligned at the UL corner, and do not
          need to be the same size.  If they are not the same size,
          the comparison will be made over overlapping pixels.
      (3) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (4) If RGB, the maximum difference between pixel components is
          saved in the histogram.

=head2 pixGetPSNR

l_int32 pixGetPSNR ( PIX *pix1, PIX *pix2, l_int32 factor, l_float32 *ppsnr )

  pixGetPSNR()

      Input:  pix1, pix2 (8 or 32 bpp; no colormap)
              factor (sampling factor; >= 1)
              &psnr (<return> power signal/noise ratio difference)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This computes the power S/N ratio, in dB, for the difference
          between two images.  By convention, the power S/N
          for a grayscale image is ('log' == log base 10,
          and 'ln == log base e):
            PSNR = 10 * log((255/MSE)^2)
                 = 4.3429 * ln((255/MSE)^2)
                 = -4.3429 * ln((MSE/255)^2)
          where MSE is the mean squared error.
          Here are some examples:
             MSE             PSNR
             ---             ----
             10              28.1
             3               38.6
             1               48.1
             0.1             68.1
      (2) If pix1 and pix2 have the same pixel values, the MSE = 0.0
          and the PSNR is infinity.  For that case, this returns
          PSNR = 1000, which corresponds to the very small MSE of
          about 10^(-48).

=head2 pixGetPerceptualDiff

l_int32 pixGetPerceptualDiff ( PIX *pixs1, PIX *pixs2, l_int32 sampling, l_int32 dilation, l_int32 mindiff, l_float32 *pfract, PIX **ppixdiff1, PIX **ppixdiff2 )

  pixGetPerceptualDiff()

      Input:  pix1 (8 bpp gray or 32 bpp rgb, or colormapped)
              pix2 (8 bpp gray or 32 bpp rgb, or colormapped)
              sampling (subsampling factor; use 0 or 1 for no subsampling)
              dilation (size of grayscale or color Sel; odd)
              mindiff (minimum pixel difference to be counted; > 0)
              &fract (<return> fraction of pixels with diff greater than
                      mindiff)
              &pixdiff1 (<optional return> showing difference (gray or color))
              &pixdiff2 (<optional return> showing pixels of sufficient diff)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This takes 2 pix and determines, using 2 input parameters:
           * @dilation specifies the amount of grayscale or color
             dilation to apply to the images, to compensate for
             a small amount of misregistration.  A typical number might
             be 5, which uses a 5x5 Sel.  Grayscale dilation expands
             lighter pixels into darker pixel regions.
           * @mindiff determines the threshold on the difference in
             pixel values to be counted -- two pixels are not similar
             if their difference in value is at least @mindiff.  For
             color pixels, we use the maximum component difference.
      (2) The pixelwise comparison is always done with the UL corners
          aligned.  The sizes of pix1 and pix2 need not be the same,
          although in practice it can be useful to scale to the same size.
      (3) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (4) Two optional diff images can be retrieved (typ. for debugging):
           pixdiff1: the gray or color difference
           pixdiff2: thresholded to 1 bpp for pixels exceeding @mindiff
      (5) The returned value of fract can be compared to some threshold,
          which is application dependent.
      (6) This method is in analogy to the two-sided hausdorff transform,
          except here it is for d > 1.  For d == 1 (see pixRankHaustest()),
          we verify that when one pix1 is dilated, it covers at least a
          given fraction of the pixels in pix2, and v.v.; in that
          case, the two pix are sufficiently similar.  Here, we
          do an analogous thing: subtract the dilated pix1 from pix2 to
          get a 1-sided hausdorff-like transform.  Then do it the
          other way.  Take the component-wise max of the two results,
          and threshold to get the fraction of pixels with a difference
          below the threshold.

=head2 pixTestForSimilarity

l_int32 pixTestForSimilarity ( PIX *pix1, PIX *pix2, l_int32 factor, l_int32 mindiff, l_float32 maxfract, l_float32 maxave, l_int32 *psimilar, l_int32 printstats )

  pixTestForSimilarity()

      Input:  pix1 (8 bpp gray or 32 bpp rgb, or colormapped)
              pix2 (8 bpp gray or 32 bpp rgb, or colormapped)
              factor (subsampling factor; use 0 or 1 for no subsampling)
              mindiff (minimum pixel difference to be counted; > 0)
              maxfract (maximum fraction of pixels allowed to have
                        diff greater than or equal to mindiff)
              maxave (maximum average difference of pixels allowed for
                      pixels with diff greater than or equal to mindiff,
                      after subtracting mindiff)
              &similar (<return> 1 if similar, 0 otherwise)
              printstats (use 1 to print normalized histogram to stderr)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This takes 2 pix that are the same size and determines using
          3 input parameters if they are "similar".  The first parameter
          @mindiff establishes a criterion of pixel-to-pixel similarity:
          two pixels are not similar if their difference in value is
          at least mindiff.  Then @maxfract and @maxave are thresholds
          on the number and distribution of dissimilar pixels
          allowed for the two pix to be similar.   If the pix are
          to be similar, neither threshold can be exceeded.
      (2) In setting the @maxfract and @maxave thresholds, you have
          these options:
            (a) Base the comparison only on @maxfract.  Then set
                @maxave = 0.0 or 256.0.  (If 0, we always ignore it.)
            (b) Base the comparison only on @maxave.  Then set
                @maxfract = 1.0.
            (c) Base the comparison on both thresholds.
      (3) Example of values that can be expected at mindiff = 15 when
          comparing lossless png encoding with jpeg encoding, q=75:
             (smoothish bg)       fractdiff = 0.01, avediff = 2.5
             (natural scene)      fractdiff = 0.13, avediff = 3.5
          To identify these images as 'similar', select maxfract
          and maxave to be upper bounds of what you expect.
      (4) See pixGetDifferenceStats() for a discussion of why we subtract
          mindiff from the computed average diff of the nonsimilar pixels
          to get the 'avediff' returned by that function.
      (5) If there is a colormap, it is removed and the result
          is either gray or RGB depending on the colormap.
      (6) If RGB, the maximum difference between pixel components is
          saved in the histogram.

=head2 pixUsesCmapColor

l_int32 pixUsesCmapColor ( PIX *pixs, l_int32 *pcolor )

  pixUsesCmapColor()

      Input:  pixs
              &color (<return>)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This returns color = TRUE if three things are obtained:
          (a) the pix has a colormap
          (b) the colormap has at least one color entry
          (c) a color entry is actually used
      (2) It is used in pixEqual() for comparing two images, in a
          situation where it is required to know if the colormap
          has color entries that are actually used in the image.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
