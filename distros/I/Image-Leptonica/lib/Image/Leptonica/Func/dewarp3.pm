package Image::Leptonica::Func::dewarp3;
$Image::Leptonica::Func::dewarp3::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::dewarp3

=head1 VERSION

version 0.04

=head1 C<dewarp3.c>

  dewarp3.c

    Applying and stripping the page disparity model

      Apply disparity array
          l_int32            dewarpaApplyDisparity()
          static l_int32     pixApplyVertDisparity()
          static l_int32     pixApplyHorizDisparity()

      Stripping out data and populating full res disparity
          l_int32            dewarpMinimize()
          l_int32            dewarpPopulateFullRes()

      Static functions not presently in use
          static FPIX       *fpixSampledDisparity()
          static FPIX       *fpixExtraHorizDisparity()

=head1 FUNCTIONS

=head2 dewarpMinimize

l_int32 dewarpMinimize ( L_DEWARP *dew )

  dewarpMinimize()

      Input:  dew
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes all data that is not needed for serialization.
          It keeps the subsampled disparity array(s), so the full
          resolution arrays can be reconstructed.

=head2 dewarpPopulateFullRes

l_int32 dewarpPopulateFullRes ( L_DEWARP *dew, PIX *pix, l_int32 x, l_int32 y )

  dewarpPopulateFullRes()

      Input:  dew
              pix (<optional>, to give size of actual image)
              x, y (origin for generation of disparity arrays)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If the full resolution vertical and horizontal disparity
          arrays do not exist, they are built from the subsampled ones.
      (2) If pixs is not given, the size of the arrays is determined
          by the original image from which the sampled version was
          generated.  Any values of (x,y) are ignored.
      (3) If pixs is given, the full resolution disparity arrays must
          be large enough to accommodate it.
          (a) If the arrays do not exist, the value of (x,y) determines
              the origin of the full resolution arrays without extension,
              relative to pixs.  Thus, (x,y) gives the amount of
              slope extension in (left, top).  The (right, bottom)
              extension is then determined by the size of pixs and
              (x,y); the values should never be < 0.
          (b) If the arrays exist and pixs is too large, the existing
              full res arrays are destroyed and new ones are made,
              again using (x,y) to determine the extension in the
              four directions.

=head2 dewarpaApplyDisparity

l_int32 dewarpaApplyDisparity ( L_DEWARPA *dewa, l_int32 pageno, PIX *pixs, l_int32 grayin, l_int32 x, l_int32 y, PIX **ppixd, const char *debugfile )

  dewarpaApplyDisparity()

      Input:  dewa
              pageno (of page model to be used; may be a ref model)
              pixs (image to be modified; can be 1, 8 or 32 bpp)
              grayin (gray value, from 0 to 255, for pixels brought in;
                      use -1 to use pixels on the boundary of pixs)
              x, y (origin for generation of disparity arrays)
              &pixd (<return> disparity corrected image)
              debugfile (use null to skip writing this)
      Return: 0 if OK, 1 on error (no models or ref models available)

  Notes:
      (1) This applies the disparity arrays to the specified image.
      (2) Specify gray color for pixels brought in from the outside:
          0 is black, 255 is white.  Use -1 to select pixels from the
          boundary of the source image.
      (3) If the models and ref models have not been validated, this
          will do so by calling dewarpaInsertRefModels().
      (4) This works with both stripped and full resolution page models.
          If the full res disparity array(s) are missing, they are remade.
      (5) The caller must handle errors that are returned because there
          are no valid models or ref models for the page -- typically
          by using the input pixs.
      (6) If there is no model for @pageno, this will use the model for
          'refpage' and put the result in the dew for @pageno.
      (7) This populates the full resolution disparity arrays if
          necessary.  If x and/or y are positive, they are used,
          in conjunction with pixs, to determine the required
          slope-based extension of the full resolution disparity
          arrays in each direction.  When (x,y) == (0,0), all
          extension is to the right and down.  Nonzero values of (x,y)
          are useful for dewarping when pixs is deliberately undercropped.
      (8) Important: when applying disparity to a number of images,
          after calling this function and saving the resulting pixd,
          you should call dewarpMinimize(dew) on the dew for @pageno.
          This will remove pixs and pixd (or their clones) stored in dew,
          as well as the full resolution disparity arrays.  Together,
          these hold approximately 16 bytes for each pixel in pixs.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
