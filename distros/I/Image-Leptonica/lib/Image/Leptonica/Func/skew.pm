package Image::Leptonica::Func::skew;
$Image::Leptonica::Func::skew::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::skew

=head1 VERSION

version 0.04

=head1 C<skew.c>

  skew.c

      Top-level deskew interfaces
          PIX       *pixDeskew()
          PIX       *pixFindSkewAndDeskew()
          PIX       *pixDeskewGeneral()

      Top-level angle-finding interface
          l_int32    pixFindSkew()

      Basic angle-finding functions
          l_int32    pixFindSkewSweep()
          l_int32    pixFindSkewSweepAndSearch()
          l_int32    pixFindSkewSweepAndSearchScore()
          l_int32    pixFindSkewSweepAndSearchScorePivot()

      Search over arbitrary range of angles in orthogonal directions
          l_int32    pixFindSkewOrthogonalRange()

      Differential square sum function for scoring
          l_int32    pixFindDifferentialSquareSum()

      Measures of variance of row sums
          l_int32    pixFindNormalizedSquareSum()


      ==============================================================
      Page skew detection

      Skew is determined by pixel profiles, which are computed
      as pixel sums along the raster line for each line in the
      image.  By vertically shearing the image by a given angle,
      the sums can be computed quickly along the raster lines
      rather than along lines at that angle.  The score is
      computed from these line sums by taking the square of
      the DIFFERENCE between adjacent line sums, summed over
      all lines.  The skew angle is then found as the angle
      that maximizes the score.  The actual computation for
      any sheared image is done in the function
      pixFindDifferentialSquareSum().

      The search for the angle that maximizes this score is
      most efficiently performed by first sweeping coarsely
      over angles, using a significantly reduced image (say, 4x
      reduction), to find the approximate maximum within a half
      degree or so, and then doing an interval-halving binary
      search at higher resolution to get the skew angle to
      within 1/20 degree or better.

      The differential signal is used (rather than just using
      that variance of line sums) because it rejects the
      background noise due to total number of black pixels,
      and has maximum contributions from the baselines and
      x-height lines of text when the textlines are aligned
      with the raster lines.  It also works well in multicolumn
      pages where the textlines do not line up across columns.

      The method is fast, accurate to within an angle (in radians)
      of approximately the inverse width in pixels of the image,
      and will work on a surprisingly small amount of text data
      (just a couple of text lines).  Consequently, it can
      also be used to find local skew if the skew were to vary
      significantly over the page.  Local skew determination
      is not very important except for locating lines of
      handwritten text that may be mixed with printed text.

=head1 FUNCTIONS

=head2 pixDeskew

PIX * pixDeskew ( PIX *pixs, l_int32 redsearch )

  pixDeskew()

      Input:  pixs (any depth)
              redsearch (for binary search: reduction factor = 1, 2 or 4;
                         use 0 for default)
      Return: pixd (deskewed pix), or null on error

  Notes:
      (1) This binarizes if necessary and finds the skew angle.  If the
          angle is large enough and there is sufficient confidence,
          it returns a deskewed image; otherwise, it returns a clone.

=head2 pixDeskewGeneral

PIX * pixDeskewGeneral ( PIX *pixs, l_int32 redsweep, l_float32 sweeprange, l_float32 sweepdelta, l_int32 redsearch, l_int32 thresh, l_float32 *pangle, l_float32 *pconf )

  pixDeskewGeneral()

      Input:  pixs  (any depth)
              redsweep  (for linear search: reduction factor = 1, 2 or 4;
                         use 0 for default)
              sweeprange (in degrees in each direction from 0;
                          use 0.0 for default)
              sweepdelta (in degrees; use 0.0 for default)
              redsearch  (for binary search: reduction factor = 1, 2 or 4;
                          use 0 for default;)
              thresh (for binarizing the image; use 0 for default)
              &angle   (<optional return> angle required to deskew,
                        in degrees; use NULL to skip)
              &conf    (<optional return> conf value is ratio
                        of max/min scores; use NULL to skip)
      Return: pixd (deskewed pix), or null on error

  Notes:
      (1) This binarizes if necessary and finds the skew angle.  If the
          angle is large enough and there is sufficient confidence,
          it returns a deskewed image; otherwise, it returns a clone.

=head2 pixFindDifferentialSquareSum

l_int32 pixFindDifferentialSquareSum ( PIX *pixs, l_float32 *psum )

  pixFindDifferentialSquareSum()

      Input:  pixs
              &sum  (<return> result)
      Return: 0 if OK, 1 on error

  Notes:
      (1) At the top and bottom, we skip:
           - at least one scanline
           - not more than 10% of the image height
           - not more than 5% of the image width

=head2 pixFindNormalizedSquareSum

l_int32 pixFindNormalizedSquareSum ( PIX *pixs, l_float32 *phratio, l_float32 *pvratio, l_float32 *pfract )

  pixFindNormalizedSquareSum()

      Input:  pixs
              &hratio (<optional return> ratio of normalized horiz square sum
                       to result if the pixel distribution were uniform)
              &vratio (<optional return> ratio of normalized vert square sum
                       to result if the pixel distribution were uniform)
              &fract  (<optional return> ratio of fg pixels to total pixels)
      Return: 0 if OK, 1 on error or if there are no fg pixels

  Notes:
      (1) Let the image have h scanlines and N fg pixels.
          If the pixels were uniformly distributed on scanlines,
          the sum of squares of fg pixels on each scanline would be
          h * (N / h)^2.  However, if the pixels are not uniformly
          distributed (e.g., for text), the sum of squares of fg
          pixels will be larger.  We return in hratio and vratio the
          ratio of these two values.
      (2) If there are no fg pixels, hratio and vratio are returned as 0.0.

=head2 pixFindSkew

l_int32 pixFindSkew ( PIX *pixs, l_float32 *pangle, l_float32 *pconf )

  pixFindSkew()

      Input:  pixs  (1 bpp)
              &angle   (<return> angle required to deskew, in degrees)
              &conf    (<return> confidence value is ratio max/min scores)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) This is a simple high-level interface, that uses default
          values of the parameters for reasonable speed and accuracy.
      (2) The angle returned is the negative of the skew angle of
          the image.  It is the angle required for deskew.
          Clockwise rotations are positive angles.

=head2 pixFindSkewAndDeskew

PIX * pixFindSkewAndDeskew ( PIX *pixs, l_int32 redsearch, l_float32 *pangle, l_float32 *pconf )

  pixFindSkewAndDeskew()

      Input:  pixs (any depth)
              redsearch (for binary search: reduction factor = 1, 2 or 4;
                         use 0 for default)
              &angle   (<optional return> angle required to deskew,
                        in degrees; use NULL to skip)
              &conf    (<optional return> conf value is ratio
                        of max/min scores; use NULL to skip)
      Return: pixd (deskewed pix), or null on error

  Notes:
      (1) This binarizes if necessary and finds the skew angle.  If the
          angle is large enough and there is sufficient confidence,
          it returns a deskewed image; otherwise, it returns a clone.

=head2 pixFindSkewOrthogonalRange

l_int32 pixFindSkewOrthogonalRange ( PIX *pixs, l_float32 *pangle, l_float32 *pconf, l_int32 redsweep, l_int32 redsearch, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta, l_float32 confprior )

   pixFindSkewOrthogonalRange()

      Input:  pixs  (1 bpp)
              &angle  (<return> angle required to deskew; in degrees cw)
              &conf   (<return> confidence given by ratio of max/min score)
              redsweep  (sweep reduction factor = 1, 2, 4 or 8)
              redsearch  (binary search reduction factor = 1, 2, 4 or 8;
                          and must not exceed redsweep)
              sweeprange  (half the full range in each orthogonal
                           direction, taken about 0, in degrees)
              sweepdelta   (angle increment of sweep; in degrees)
              minbsdelta   (min binary search increment angle; in degrees)
              confprior  (amount by which confidence of 90 degree rotated
                          result is reduced when comparing with unrotated
                          confidence value)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) This searches for the skew angle, first in the range
          [-sweeprange, sweeprange], and then in
          [90 - sweeprange, 90 + sweeprange], with angles measured
          clockwise.  For exploring the full range of possibilities,
          suggest using sweeprange = 47.0 degrees, giving some overlap
          at 45 and 135 degrees.  From these results, and discounting
          the the second confidence by @confprior, it selects the
          angle for maximal differential variance.  If the angle
          is larger than pi/4, the angle found after 90 degree rotation
          is selected.
      (2) The larger the confidence value, the greater the probability
          that the proper alignment is given by the angle that maximizes
          variance.  It should be compared to a threshold, which depends
          on the application.  Values between 3.0 and 6.0 are common.
      (3) Allowing for both portrait and landscape searches is more
          difficult, because if the signal from the text lines is weak,
          a signal from vertical rules can be larger!
          The most difficult documents to deskew have some or all of:
            (a) Multiple columns, not aligned
            (b) Black lines along the vertical edges
            (c) Text from two pages, and at different angles
          Rule of thumb for resolution:
            (a) If the margins are clean, you can work at 75 ppi,
                although 100 ppi is safer.
            (b) If there are vertical lines in the margins, do not
                work below 150 ppi.  The signal from the text lines must
                exceed that from the margin lines.
      (4) Choosing the @confprior parameter depends on knowing something
          about the source of image.  However, we're not using
          real probabilities here, so its use is qualitative.
          If landscape and portrait are equally likely, use
          @confprior = 0.0.  If the likelihood of portrait (non-rotated)
          is 100 times higher than that of landscape, we want to reduce
          the chance that we rotate to landscape in a situation where
          the landscape signal is accidentally larger than the
          portrait signal.  To do this use a positive value of
          @confprior; say 1.5.

=head2 pixFindSkewSweep

l_int32 pixFindSkewSweep ( PIX *pixs, l_float32 *pangle, l_int32 reduction, l_float32 sweeprange, l_float32 sweepdelta )

  pixFindSkewSweep()

      Input:  pixs  (1 bpp)
              &angle   (<return> angle required to deskew, in degrees)
              reduction  (factor = 1, 2, 4 or 8)
              sweeprange   (half the full range; assumed about 0; in degrees)
              sweepdelta   (angle increment of sweep; in degrees)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) This examines the 'score' for skew angles with equal intervals.
      (2) Caller must check the return value for validity of the result.

=head2 pixFindSkewSweepAndSearch

l_int32 pixFindSkewSweepAndSearch ( PIX *pixs, l_float32 *pangle, l_float32 *pconf, l_int32 redsweep, l_int32 redsearch, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta )

  pixFindSkewSweepAndSearch()

      Input:  pixs  (1 bpp)
              &angle   (<return> angle required to deskew; in degrees)
              &conf    (<return> confidence given by ratio of max/min score)
              redsweep  (sweep reduction factor = 1, 2, 4 or 8)
              redsearch  (binary search reduction factor = 1, 2, 4 or 8;
                          and must not exceed redsweep)
              sweeprange   (half the full range, assumed about 0; in degrees)
              sweepdelta   (angle increment of sweep; in degrees)
              minbsdelta   (min binary search increment angle; in degrees)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) This finds the skew angle, doing first a sweep through a set
          of equal angles, and then doing a binary search until
          convergence.
      (2) Caller must check the return value for validity of the result.
      (3) In computing the differential line sum variance score, we sum
          the result over scanlines, but we always skip:
           - at least one scanline
           - not more than 10% of the image height
           - not more than 5% of the image width
      (4) See also notes in pixFindSkewSweepAndSearchScore()

=head2 pixFindSkewSweepAndSearchScore

l_int32 pixFindSkewSweepAndSearchScore ( PIX *pixs, l_float32 *pangle, l_float32 *pconf, l_float32 *pendscore, l_int32 redsweep, l_int32 redsearch, l_float32 sweepcenter, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta )

  pixFindSkewSweepAndSearchScore()

      Input:  pixs  (1 bpp)
              &angle   (<return> angle required to deskew; in degrees)
              &conf    (<return> confidence given by ratio of max/min score)
              &endscore (<optional return> max score; use NULL to ignore)
              redsweep  (sweep reduction factor = 1, 2, 4 or 8)
              redsearch  (binary search reduction factor = 1, 2, 4 or 8;
                          and must not exceed redsweep)
              sweepcenter  (angle about which sweep is performed; in degrees)
              sweeprange   (half the full range, taken about sweepcenter;
                            in degrees)
              sweepdelta   (angle increment of sweep; in degrees)
              minbsdelta   (min binary search increment angle; in degrees)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) This finds the skew angle, doing first a sweep through a set
          of equal angles, and then doing a binary search until convergence.
      (2) There are two built-in constants that determine if the
          returned confidence is nonzero:
            - MIN_VALID_MAXSCORE (minimum allowed maxscore)
            - MINSCORE_THRESHOLD_CONSTANT (determines minimum allowed
                 minscore, by multiplying by (height * width^2)
          If either of these conditions is not satisfied, the returned
          confidence value will be zero.  The maxscore is optionally
          returned in this function to allow evaluation of the
          resulting angle by a method that is independent of the
          returned confidence value.
      (3) The larger the confidence value, the greater the probability
          that the proper alignment is given by the angle that maximizes
          variance.  It should be compared to a threshold, which depends
          on the application.  Values between 3.0 and 6.0 are common.
      (4) By default, the shear is about the UL corner.

=head2 pixFindSkewSweepAndSearchScorePivot

l_int32 pixFindSkewSweepAndSearchScorePivot ( PIX *pixs, l_float32 *pangle, l_float32 *pconf, l_float32 *pendscore, l_int32 redsweep, l_int32 redsearch, l_float32 sweepcenter, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta, l_int32 pivot )

  pixFindSkewSweepAndSearchScorePivot()

      Input:  pixs  (1 bpp)
              &angle   (<return> angle required to deskew; in degrees)
              &conf    (<return> confidence given by ratio of max/min score)
              &endscore (<optional return> max score; use NULL to ignore)
              redsweep  (sweep reduction factor = 1, 2, 4 or 8)
              redsearch  (binary search reduction factor = 1, 2, 4 or 8;
                          and must not exceed redsweep)
              sweepcenter  (angle about which sweep is performed; in degrees)
              sweeprange   (half the full range, taken about sweepcenter;
                            in degrees)
              sweepdelta   (angle increment of sweep; in degrees)
              minbsdelta   (min binary search increment angle; in degrees)
              pivot  (L_SHEAR_ABOUT_CORNER, L_SHEAR_ABOUT_CENTER)
      Return: 0 if OK, 1 on error or if angle measurment not valid

  Notes:
      (1) See notes in pixFindSkewSweepAndSearchScore().
      (2) This allows choice of shear pivoting from either the UL corner
          or the center.  For small angles, the ability to discriminate
          angles is better with shearing from the UL corner.  However,
          for large angles (say, greater than 20 degrees), it is better
          to shear about the center because a shear from the UL corner
          loses too much of the image.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
