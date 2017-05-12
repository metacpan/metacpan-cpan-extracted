package Image::Leptonica::Func::baseline;
$Image::Leptonica::Func::baseline::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::baseline

=head1 VERSION

version 0.04

=head1 C<baseline.c>

  baseline.c

      Locate text baselines in an image
           NUMA     *pixFindBaselines()

      Projective transform to remove local skew
           PIX      *pixDeskewLocal()

      Determine local skew
           l_int32   pixGetLocalSkewTransform()
           NUMA     *pixGetLocalSkewAngles()

  We have two apparently different functions here:
    - finding baselines
    - finding a projective transform to remove keystone warping
  The function pixGetLocalSkewAngles() returns an array of angles,
  one for each raster line, and the baselines of the text lines
  should intersect the left edge of the image with that angle.

=head1 FUNCTIONS

=head2 pixDeskewLocal

PIX * pixDeskewLocal ( PIX *pixs, l_int32 nslices, l_int32 redsweep, l_int32 redsearch, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta )

  pixDeskewLocal()

      Input:  pixs
              nslices  (the number of horizontal overlapping slices; must
                  be larger than 1 and not exceed 20; use 0 for default)
              redsweep (sweep reduction factor: 1, 2, 4 or 8;
                        use 0 for default value)
              redsearch (search reduction factor: 1, 2, 4 or 8, and
                         not larger than redsweep; use 0 for default value)
              sweeprange (half the full range, assumed about 0; in degrees;
                          use 0.0 for default value)
              sweepdelta (angle increment of sweep; in degrees;
                          use 0.0 for default value)
              minbsdelta (min binary search increment angle; in degrees;
                          use 0.0 for default value)
      Return: pixd, or null on error

  Notes:
      (1) This function allows deskew of a page whose skew changes
          approximately linearly with vertical position.  It uses
          a projective tranform that in effect does a differential
          shear about the LHS of the page, and makes all text lines
          horizontal.
      (2) The origin of the keystoning can be either a cheap document
          feeder that rotates the page as it is passed through, or a
          camera image taken from either the left or right side
          of the vertical.
      (3) The image transformation is a projective warping,
          not a rotation.  Apart from this function, the text lines
          must be properly aligned vertically with respect to each
          other.  This can be done by pre-processing the page; e.g.,
          by rotating or horizontally shearing it.
          Typically, this can be achieved by vertically aligning
          the page edge.

=head2 pixFindBaselines

NUMA * pixFindBaselines ( PIX *pixs, PTA **ppta, l_int32 debug )

  pixFindBaselines()

      Input:  pixs (1 bpp)
              &pta (<optional return> pairs of pts corresponding to
                    approx. ends of each text line)
              debug (usually 0; set to 1 for debugging output)
      Return: na (of baseline y values), or null on error

  Notes:
      (1) Input binary image must have text lines already aligned
          horizontally.  This can be done by either rotating the
          image with pixDeskew(), or, if a projective transform
          is required, by doing pixDeskewLocal() first.
      (2) Input null for &pta if you don't want this returned.
          The pta will come in pairs of points (left and right end
          of each baseline).
      (3) Caution: this will not work properly on text with multiple
          columns, where the lines are not aligned between columns.
          If there are multiple columns, they should be extracted
          separately before finding the baselines.
      (4) This function constructs different types of output
          for baselines; namely, a set of raster line values and
          a set of end points of each baseline.
      (5) This function was designed to handle short and long text lines
          without using dangerous thresholds on the peak heights.  It does
          this by combining the differential signal with a morphological
          analysis of the locations of the text lines.  One can also
          combine this data to normalize the peak heights, by weighting
          the differential signal in the region of each baseline
          by the inverse of the width of the text line found there.
      (6) There are various debug sections that can be turned on
          with the debug flag.

=head2 pixGetLocalSkewAngles

NUMA * pixGetLocalSkewAngles ( PIX *pixs, l_int32 nslices, l_int32 redsweep, l_int32 redsearch, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta, l_float32 *pa, l_float32 *pb )

  pixGetLocalSkewAngles()

      Input:  pixs
              nslices  (the number of horizontal overlapping slices; must
                  be larger than 1 and not exceed 20; use 0 for default)
              redsweep (sweep reduction factor: 1, 2, 4 or 8;
                        use 0 for default value)
              redsearch (search reduction factor: 1, 2, 4 or 8, and
                         not larger than redsweep; use 0 for default value)
              sweeprange (half the full range, assumed about 0; in degrees;
                          use 0.0 for default value)
              sweepdelta (angle increment of sweep; in degrees;
                          use 0.0 for default value)
              minbsdelta (min binary search increment angle; in degrees;
                          use 0.0 for default value)
              &a (<optional return> slope of skew as fctn of y)
              &b (<optional return> intercept at y=0 of skew as fctn of y)
      Return: naskew, or null on error

  Notes:
      (1) The local skew is measured in a set of overlapping strips.
          We then do a least square linear fit parameters to get
          the slope and intercept parameters a and b in
              skew-angle = a * y + b  (degrees)
          for the local skew as a function of raster line y.
          This is then used to make naskew, which can be interpreted
          as the computed skew angle (in degrees) at the left edge
          of each raster line.
      (2) naskew can then be used to find the baselines of text, because
          each text line has a baseline that should intersect
          the left edge of the image with the angle given by this
          array, evaluated at the raster line of intersection.

=head2 pixGetLocalSkewTransform

l_int32 pixGetLocalSkewTransform ( PIX *pixs, l_int32 nslices, l_int32 redsweep, l_int32 redsearch, l_float32 sweeprange, l_float32 sweepdelta, l_float32 minbsdelta, PTA **pptas, PTA **pptad )

  pixGetLocalSkewTransform()

      Input:  pixs
              nslices  (the number of horizontal overlapping slices; must
                  be larger than 1 and not exceed 20; use 0 for default)
              redsweep (sweep reduction factor: 1, 2, 4 or 8;
                        use 0 for default value)
              redsearch (search reduction factor: 1, 2, 4 or 8, and
                         not larger than redsweep; use 0 for default value)
              sweeprange (half the full range, assumed about 0; in degrees;
                          use 0.0 for default value)
              sweepdelta (angle increment of sweep; in degrees;
                          use 0.0 for default value)
              minbsdelta (min binary search increment angle; in degrees;
                          use 0.0 for default value)
              &ptas  (<return> 4 points in the source)
              &ptad  (<return> the corresponding 4 pts in the dest)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates two pairs of points in the src, each pair
          corresponding to a pair of points that would lie along
          the same raster line in a transformed (dewarped) image.
      (2) The sets of 4 src and 4 dest points returned by this function
          can then be used, in a projective or bilinear transform,
          to remove keystoning in the src.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
