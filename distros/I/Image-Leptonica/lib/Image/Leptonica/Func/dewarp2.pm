package Image::Leptonica::Func::dewarp2;
$Image::Leptonica::Func::dewarp2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::dewarp2

=head1 VERSION

version 0.04

=head1 C<dewarp2.c>

  dewarp2.c

    Build the page disparity model

      Build page disparity model
          l_int32            dewarpBuildPageModel()
          l_int32            dewarpFindVertDisparity()
          l_int32            dewarpFindHorizDisparity()
          PTAA              *dewarpGetTextlineCenters()
          static PTA        *dewarpGetMeanVerticals()
          PTAA              *dewarpRemoveShortLines()
          static l_int32     dewarpGetLineEndpoints()
          static l_int32     dewarpQuadraticLSF()

      Build the line disparity model
          l_int32            dewarpBuildLineModel()

      Query model status
          l_int32            dewarpaModelStatus()

      Rendering helpers
          static l_int32     pixRenderFlats()
          static l_int32     pixRenderHorizEndPoints

=head1 FUNCTIONS

=head2 dewarpBuildLineModel

l_int32 dewarpBuildLineModel ( L_DEWARP *dew, l_int32 opensize, const char *debugfile )

  dewarpBuildLineModel()

      Input:  dew
              opensize (size of opening to remove perpendicular lines)
              debugfile (use null to skip writing this)
      Return: 0 if OK, 1 if unable to build the model or on error

  Notes:
      (1) This builds the horizontal and vertical disparity arrays
          for an input of ruled lines, typically for calibration.
          In book scanning, you could lay the ruled paper over a page.
          Then for that page and several below it, you can use the
          disparity correction of the line model to dewarp the pages.
      (2) The dew has been initialized with the image of ruled lines.
          These lines must be continuous, but we do a small amount
          of pre-processing here to insure that.
      (3) @opensize is typically about 8.  It must be larger than
          the thickness of the lines to be extracted.  This is the
          default value, which is applied if @opensize < 3.
      (4) Sets vsuccess = 1 and hsuccess = 1 if the vertical and/or
          horizontal disparity arrays build.
      (5) Similar to dewarpBuildPageModel(), except here the vertical
          and horizontal disparity arrays are both built from ruled lines.
          See notes there.

=head2 dewarpBuildPageModel

l_int32 dewarpBuildPageModel ( L_DEWARP *dew, const char *debugfile )

  dewarpBuildPageModel()

      Input:  dew
              debugfile (use null to skip writing this)
      Return: 0 if OK, 1 if unable to build the model or on error

  Notes:
      (1) This is the basic function that builds the horizontal and
          vertical disparity arrays, which allow determination of the
          src pixel in the input image corresponding to each
          dest pixel in the dewarped image.
      (2) Sets vsuccess = 1 if the vertical disparity array builds.
          Always attempts to build the horizontal disparity array,
          even if it will not be requested (useboth == 0).
          Sets hsuccess = 1 if horizontal disparity builds.
      (3) The method is as follows:
          (a) Estimate the points along the centers of all the
              long textlines.  If there are too few lines, no
              disparity models are built.
          (b) From the vertical deviation of the lines, estimate
              the vertical disparity.
          (c) From the ends of the lines, estimate the horizontal
              disparity, assuming that the text is made of lines
              that are left and right justified.
          (d) One can also compute an additional contribution to the
              horizontal disparity, inferred from slopes of the top
              and bottom lines.  We do not do this.
      (4) In more detail for the vertical disparity:
          (a) Fit a LS quadratic to center locations along each line.
              This smooths the curves.
          (b) Sample each curve at a regular interval, find the y-value
              of the mid-point on each curve, and subtract the sampled
              curve value from this value.  This is the vertical
              disparity at sampled points along each curve.
          (c) Fit a LS quadratic to each set of vertically aligned
              disparity samples.  This smooths the disparity values
              in the vertical direction.  Then resample at the same
              regular interval.  We now have a regular grid of smoothed
              vertical disparity valuels.
      (5) Once the sampled vertical disparity array is found, it can be
          interpolated to get a full resolution vertical disparity map.
          This can be applied directly to the src image pixels
          to dewarp the image in the vertical direction, making
          all textlines horizontal.  Likewise, the horizontal
          disparity array is used to left- and right-align the
          longest textlines.

=head2 dewarpFindHorizDisparity

l_int32 dewarpFindHorizDisparity ( L_DEWARP *dew, PTAA *ptaa )

  dewarpFindHorizDisparity()

      Input:  dew
              ptaa (unsmoothed lines, not vertically ordered)
      Return: 0 if OK, 1 if vertical disparity array is no built or on error

      (1) This is not required for a successful model; only the vertical
          disparity is required.  This will not be called if the
          function to build the vertical disparity fails.
      (2) Debug output goes to /tmp/dewmod/ for collection into a pdf.

=head2 dewarpFindVertDisparity

l_int32 dewarpFindVertDisparity ( L_DEWARP *dew, PTAA *ptaa, l_int32 rotflag )

  dewarpFindVertDisparity()

      Input:  dew
              ptaa (unsmoothed lines, not vertically ordered)
              rotflag (0 if using dew->pixs; 1 if rotated by 90 degrees cw)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This starts with points along the centers of textlines.
          It does quadratic fitting (and smoothing), first along the
          lines and then in the vertical direction, to generate
          the sampled vertical disparity map.  This can then be
          interpolated to full resolution and used to remove
          the vertical line warping.
      (2) Use @rotflag == 1 if you are dewarping vertical lines, as
          is done in dewarpBuildLineModel().  The usual case is for
          @rotflag == 0.
      (3) The model fails to build if the vertical disparity fails.
          This sets the vsuccess flag to 1 on success.
      (4) Pix debug output goes to /tmp/dewvert/ for collection into
          a pdf.  Non-pix debug output goes to /tmp.

=head2 dewarpGetTextlineCenters

PTAA * dewarpGetTextlineCenters ( PIX *pixs, l_int32 debugflag )

  dewarpGetTextlineCenters()

      Input:  pixs (1 bpp)
              debugflag (1 for debug output)
      Return: ptaa (of center values of textlines)

  Notes:
      (1) This in general does not have a point for each value
          of x, because there will be gaps between words.
          It doesn't matter because we will fit a quadratic to the
          points that we do have.

=head2 dewarpRemoveShortLines

PTAA * dewarpRemoveShortLines ( PIX *pixs, PTAA *ptaas, l_float32 fract, l_int32 debugflag )

  dewarpRemoveShortLines()

      Input:  pixs (1 bpp)
              ptaas (input lines)
              fract (minimum fraction of longest line to keep)
              debugflag
      Return: ptaad (containing only lines of sufficient length),
                     or null on error

=head2 dewarpaModelStatus

l_int32 dewarpaModelStatus ( L_DEWARPA *dewa, l_int32 pageno, l_int32 *pvsuccess, l_int32 *phsuccess )

  dewarpaModelStatus()

      Input:  dewa
              pageno
              &vsuccess (<optional return> 1 on success)
              &hsuccess (<optional return> 1 on success)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This tests if a model has been built, not if it is valid.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
