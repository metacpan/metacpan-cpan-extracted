package Image::Leptonica::Func::fpix2;
$Image::Leptonica::Func::fpix2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::fpix2

=head1 VERSION

version 0.04

=head1 C<fpix2.c>

  fpix2.c

    This file has these FPix utilities:
       - interconversions with pix, fpix, dpix
       - min and max values
       - integer scaling
       - arithmetic operations
       - set all
       - border functions
       - simple rasterop (source --> dest)
       - geometric transforms

    Interconversions between Pix, FPix and DPix
          FPIX          *pixConvertToFPix()
          DPIX          *pixConvertToDPix()
          PIX           *fpixConvertToPix()
          PIX           *fpixDisplayMaxDynamicRange()  [useful for debugging]
          DPIX          *fpixConvertToDPix()
          PIX           *dpixConvertToPix()
          FPIX          *dpixConvertToFPix()

    Min/max value
          l_int32        fpixGetMin()
          l_int32        fpixGetMax()
          l_int32        dpixGetMin()
          l_int32        dpixGetMax()

    Integer scaling
          FPIX          *fpixScaleByInteger()
          DPIX          *dpixScaleByInteger()

    Arithmetic operations
          FPIX          *fpixLinearCombination()
          l_int32        fpixAddMultConstant()
          DPIX          *dpixLinearCombination()
          l_int32        dpixAddMultConstant()

    Set all
          l_int32        fpixSetAllArbitrary()
          l_int32        dpixSetAllArbitrary()

    FPix border functions
          FPIX          *fpixAddBorder()
          FPIX          *fpixRemoveBorder()
          FPIX          *fpixAddMirroredBorder()
          FPIX          *fpixAddContinuedBorder()
          FPIX          *fpixAddSlopeBorder()

    FPix simple rasterop
          l_int32        fpixRasterop()

    FPix rotation by multiples of 90 degrees
          FPIX          *fpixRotateOrth()
          FPIX          *fpixRotate180()
          FPIX          *fpixRotate90()
          FPIX          *fpixFlipLR()
          FPIX          *fpixFlipTB()

    FPix affine and projective interpolated transforms
          FPIX          *fpixAffinePta()
          FPIX          *fpixAffine()
          FPIX          *fpixProjectivePta()
          FPIX          *fpixProjective()
          l_int32        linearInterpolatePixelFloat()

    Thresholding to 1 bpp Pix
          PIX           *fpixThresholdToPix()

    Generate function from components
          FPIX          *pixComponentFunction()

=head1 FUNCTIONS

=head2 dpixAddMultConstant

l_int32 dpixAddMultConstant ( DPIX *dpix, l_float64 addc, l_float64 multc )

  dpixAddMultConstant()

      Input:  dpix
              addc  (use 0.0 to skip the operation)
              multc (use 1.0 to skip the operation)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) It can be used to multiply each pixel by a constant,
          and also to add a constant to each pixel.  Multiplication
          is done first.

=head2 dpixConvertToFPix

FPIX * dpixConvertToFPix ( DPIX *dpix )

  dpixConvertToFPix()

      Input:  dpix
      Return: fpix, or null on error

=head2 dpixConvertToPix

PIX * dpixConvertToPix ( DPIX *dpixs, l_int32 outdepth, l_int32 negvals, l_int32 errorflag )

  dpixConvertToPix()

      Input:  dpixs
              outdepth (0, 8, 16 or 32 bpp)
              negvals (L_CLIP_TO_ZERO, L_TAKE_ABSVAL)
              errorflag (1 to output error stats; 0 otherwise)
      Return: pixd, or null on error

  Notes:
      (1) Use @outdepth = 0 to programmatically determine the
          output depth.  If no values are greater than 255,
          it will set outdepth = 8; otherwise to 16 or 32.
      (2) Because we are converting a float to an unsigned int
          with a specified dynamic range (8, 16 or 32 bits), errors
          can occur.  If errorflag == TRUE, output the number
          of values out of range, both negative and positive.
      (3) If a pixel value is positive and out of range, clip to
          the maximum value represented at the outdepth of 8, 16
          or 32 bits.

=head2 dpixGetMax

l_int32 dpixGetMax ( DPIX *dpix, l_float64 *pmaxval, l_int32 *pxmaxloc, l_int32 *pymaxloc )

  dpixGetMax()

      Input:  dpix
              &maxval (<optional return> max value)
              &xmaxloc (<optional return> x location of max)
              &ymaxloc (<optional return> y location of max)
      Return: 0 if OK; 1 on error

=head2 dpixGetMin

l_int32 dpixGetMin ( DPIX *dpix, l_float64 *pminval, l_int32 *pxminloc, l_int32 *pyminloc )

  dpixGetMin()

      Input:  dpix
              &minval (<optional return> min value)
              &xminloc (<optional return> x location of min)
              &yminloc (<optional return> y location of min)
      Return: 0 if OK; 1 on error

=head2 dpixLinearCombination

DPIX * dpixLinearCombination ( DPIX *dpixd, DPIX *dpixs1, DPIX *dpixs2, l_float32 a, l_float32 b )

  dpixLinearCombination()

      Input:  dpixd (<optional>; this can be null, equal to dpixs1, or
                     different from dpixs1)
              dpixs1 (can be == to dpixd)
              dpixs2
              a, b (multiplication factors on dpixs1 and dpixs2, rsp.)
      Return: dpixd always

  Notes:
      (1) Computes pixelwise linear combination: a * src1 + b * src2
      (2) Alignment is to UL corner.
      (3) There are 3 cases.  The result can go to a new dest,
          in-place to dpixs1, or to an existing input dest:
          * dpixd == null:   (src1 + src2) --> new dpixd
          * dpixd == dpixs1:  (src1 + src2) --> src1  (in-place)
          * dpixd != dpixs1: (src1 + src2) --> input dpixd
      (4) dpixs2 must be different from both dpixd and dpixs1.

=head2 dpixScaleByInteger

DPIX * dpixScaleByInteger ( DPIX *dpixs, l_int32 factor )

  dpixScaleByInteger()

      Input:  dpixs (low resolution, subsampled)
              factor (scaling factor)
      Return: dpixd (interpolated result), or null on error

  Notes:
      (1) The width wd of dpixd is related to ws of dpixs by:
              wd = factor * (ws - 1) + 1   (and ditto for the height)
          We avoid special-casing boundary pixels in the interpolation
          by constructing fpixd by inserting (factor - 1) interpolated
          pixels between each pixel in fpixs.  Then
               wd = ws + (ws - 1) * (factor - 1)    (same as above)
          This also has the advantage that if we subsample by @factor,
          throwing out all the interpolated pixels, we regain the
          original low resolution dpix.

=head2 dpixSetAllArbitrary

l_int32 dpixSetAllArbitrary ( DPIX *dpix, l_float64 inval )

  dpixSetAllArbitrary()

      Input:  dpix
              val (to set at each pixel)
      Return: 0 if OK, 1 on error

=head2 fpixAddBorder

FPIX * fpixAddBorder ( FPIX *fpixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  fpixAddBorder()

      Input:  fpixs
              left, right, top, bot (pixels on each side to be added)
      Return: fpixd, or null on error

  Notes:
      (1) Adds border of '0' 32-bit pixels

=head2 fpixAddContinuedBorder

FPIX * fpixAddContinuedBorder ( FPIX *fpixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  fpixAddContinuedBorder()

      Input:  fpixs
              left, right, top, bot (pixels on each side to be added)
      Return: fpixd, or null on error

  Notes:
      (1) This adds pixels on each side whose values are equal to
          the value on the closest boundary pixel.

=head2 fpixAddMirroredBorder

FPIX * fpixAddMirroredBorder ( FPIX *fpixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  fpixAddMirroredBorder()

      Input:  fpixs
              left, right, top, bot (pixels on each side to be added)
      Return: fpixd, or null on error

  Notes:
      (1) See pixAddMirroredBorder() for situations of usage.

=head2 fpixAddMultConstant

l_int32 fpixAddMultConstant ( FPIX *fpix, l_float32 addc, l_float32 multc )

  fpixAddMultConstant()

      Input:  fpix
              addc  (use 0.0 to skip the operation)
              multc (use 1.0 to skip the operation)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is an in-place operation.
      (2) It can be used to multiply each pixel by a constant,
          and also to add a constant to each pixel.  Multiplication
          is done first.

=head2 fpixAddSlopeBorder

FPIX * fpixAddSlopeBorder ( FPIX *fpixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  fpixAddSlopeBorder()

      Input:  fpixs
              left, right, top, bot (pixels on each side to be added)
      Return: fpixd, or null on error

  Notes:
      (1) This adds pixels on each side whose values have a normal
          derivative equal to the normal derivative at the boundary
          of fpixs.

=head2 fpixAffine

FPIX * fpixAffine ( FPIX *fpixs, l_float32 *vc, l_float32 inval )

  fpixAffine()

      Input:  fpixs (8 bpp)
              vc  (vector of 8 coefficients for projective transformation)
              inval (value brought in; typ. 0)
      Return: fpixd, or null on error

=head2 fpixAffinePta

FPIX * fpixAffinePta ( FPIX *fpixs, PTA *ptad, PTA *ptas, l_int32 border, l_float32 inval )

  fpixAffinePta()

      Input:  fpixs (8 bpp)
              ptad  (4 pts of final coordinate space)
              ptas  (4 pts of initial coordinate space)
              border (size of extension with constant normal derivative)
              inval (value brought in; typ. 0)
      Return: fpixd, or null on error

  Notes:
      (1) If @border > 0, all four sides are extended by that distance,
          and removed after the transformation is finished.  Pixels
          that would be brought in to the trimmed result from outside
          the extended region are assigned @inval.  The purpose of
          extending the image is to avoid such assignments.
      (2) On the other hand, you may want to give all pixels that
          are brought in from outside fpixs a specific value.  In that
          case, set @border == 0.

=head2 fpixConvertToDPix

DPIX * fpixConvertToDPix ( FPIX *fpix )

  fpixConvertToDPix()

      Input:  fpix
      Return: dpix, or null on error

=head2 fpixConvertToPix

PIX * fpixConvertToPix ( FPIX *fpixs, l_int32 outdepth, l_int32 negvals, l_int32 errorflag )

  fpixConvertToPix()

      Input:  fpixs
              outdepth (0, 8, 16 or 32 bpp)
              negvals (L_CLIP_TO_ZERO, L_TAKE_ABSVAL)
              errorflag (1 to output error stats; 0 otherwise)
      Return: pixd, or null on error

  Notes:
      (1) Use @outdepth = 0 to programmatically determine the
          output depth.  If no values are greater than 255,
          it will set outdepth = 8; otherwise to 16 or 32.
      (2) Because we are converting a float to an unsigned int
          with a specified dynamic range (8, 16 or 32 bits), errors
          can occur.  If errorflag == TRUE, output the number
          of values out of range, both negative and positive.
      (3) If a pixel value is positive and out of range, clip to
          the maximum value represented at the outdepth of 8, 16
          or 32 bits.

=head2 fpixDisplayMaxDynamicRange

PIX * fpixDisplayMaxDynamicRange ( FPIX *fpixs )

  fpixDisplayMaxDynamicRange()

      Input:  fpixs
      Return: pixd (8 bpp), or null on error

=head2 fpixFlipTB

FPIX * fpixFlipTB ( FPIX *fpixd, FPIX *fpixs )

  fpixFlipTB()

      Input:  fpixd (<optional>; can be null, equal to fpixs,
                     or different from fpixs)
              fpixs
      Return: fpixd, or null on error

  Notes:
      (1) This does a top-bottom flip of the image, which is
          equivalent to a rotation out of the plane about a
          horizontal line through the image center.
      (2) There are 3 cases for input:
          (a) fpixd == null (creates a new fpixd)
          (b) fpixd == fpixs (in-place operation)
          (c) fpixd != fpixs (existing fpixd)
      (3) For clarity, use these three patterns, respectively:
          (a) fpixd = fpixFlipTB(NULL, fpixs);
          (b) fpixFlipTB(fpixs, fpixs);
          (c) fpixFlipTB(fpixd, fpixs);
      (4) If an existing fpixd is not the same size as fpixs, the
          image data will be reallocated.

=head2 fpixGetMax

l_int32 fpixGetMax ( FPIX *fpix, l_float32 *pmaxval, l_int32 *pxmaxloc, l_int32 *pymaxloc )

  fpixGetMax()

      Input:  fpix
              &maxval (<optional return> max value)
              &xmaxloc (<optional return> x location of max)
              &ymaxloc (<optional return> y location of max)
      Return: 0 if OK; 1 on error

=head2 fpixGetMin

l_int32 fpixGetMin ( FPIX *fpix, l_float32 *pminval, l_int32 *pxminloc, l_int32 *pyminloc )

  fpixGetMin()

      Input:  fpix
              &minval (<optional return> min value)
              &xminloc (<optional return> x location of min)
              &yminloc (<optional return> y location of min)
      Return: 0 if OK; 1 on error

=head2 fpixLinearCombination

FPIX * fpixLinearCombination ( FPIX *fpixd, FPIX *fpixs1, FPIX *fpixs2, l_float32 a, l_float32 b )

  fpixLinearCombination()

      Input:  fpixd (<optional>; this can be null, equal to fpixs1, or
                     different from fpixs1)
              fpixs1 (can be == to fpixd)
              fpixs2
              a, b (multiplication factors on fpixs1 and fpixs2, rsp.)
      Return: fpixd always

  Notes:
      (1) Computes pixelwise linear combination: a * src1 + b * src2
      (2) Alignment is to UL corner.
      (3) There are 3 cases.  The result can go to a new dest,
          in-place to fpixs1, or to an existing input dest:
          * fpixd == null:   (src1 + src2) --> new fpixd
          * fpixd == fpixs1:  (src1 + src2) --> src1  (in-place)
          * fpixd != fpixs1: (src1 + src2) --> input fpixd
      (4) fpixs2 must be different from both fpixd and fpixs1.

=head2 fpixProjective

FPIX * fpixProjective ( FPIX *fpixs, l_float32 *vc, l_float32 inval )

  fpixProjective()

      Input:  fpixs (8 bpp)
              vc  (vector of 8 coefficients for projective transformation)
              inval (value brought in; typ. 0)
      Return: fpixd, or null on error

=head2 fpixProjectivePta

FPIX * fpixProjectivePta ( FPIX *fpixs, PTA *ptad, PTA *ptas, l_int32 border, l_float32 inval )

  fpixProjectivePta()

      Input:  fpixs (8 bpp)
              ptad  (4 pts of final coordinate space)
              ptas  (4 pts of initial coordinate space)
              border (size of extension with constant normal derivative)
              inval (value brought in; typ. 0)
      Return: fpixd, or null on error

  Notes:
      (1) If @border > 0, all four sides are extended by that distance,
          and removed after the transformation is finished.  Pixels
          that would be brought in to the trimmed result from outside
          the extended region are assigned @inval.  The purpose of
          extending the image is to avoid such assignments.
      (2) On the other hand, you may want to give all pixels that
          are brought in from outside fpixs a specific value.  In that
          case, set @border == 0.

=head2 fpixRasterop

l_int32 fpixRasterop ( FPIX *fpixd, l_int32 dx, l_int32 dy, l_int32 dw, l_int32 dh, FPIX *fpixs, l_int32 sx, l_int32 sy )

  fpixRasterop()

      Input:  fpixd  (dest fpix)
              dx     (x val of UL corner of dest rectangle)
              dy     (y val of UL corner of dest rectangle)
              dw     (width of dest rectangle)
              dh     (height of dest rectangle)
              fpixs  (src fpix)
              sx     (x val of UL corner of src rectangle)
              sy     (y val of UL corner of src rectangle)
      Return: 0 if OK; 1 on error.

  Notes:
      (1) This is similiar in structure to pixRasterop(), except
          it only allows copying from the source into the destination.
          For that reason, no op code is necessary.  Additionally,
          all pixels are 32 bit words (float values), which makes
          the copy very simple.
      (2) Clipping of both src and dest fpix are done automatically.
      (3) This allows in-place copying, without checking to see if
          the result is valid:  use for in-place with caution!

=head2 fpixRemoveBorder

FPIX * fpixRemoveBorder ( FPIX *fpixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  fpixRemoveBorder()

      Input:  fpixs
              left, right, top, bot (pixels on each side to be removed)
      Return: fpixd, or null on error

=head2 fpixRotate180

FPIX * fpixRotate180 ( FPIX *fpixd, FPIX *fpixs )

  fpixRotate180()

      Input:  fpixd  (<optional>; can be null, equal to fpixs,
                      or different from fpixs)
              fpixs
      Return: fpixd, or null on error

  Notes:
      (1) This does a 180 rotation of the image about the center,
          which is equivalent to a left-right flip about a vertical
          line through the image center, followed by a top-bottom
          flip about a horizontal line through the image center.
      (2) There are 3 cases for input:
          (a) fpixd == null (creates a new fpixd)
          (b) fpixd == fpixs (in-place operation)
          (c) fpixd != fpixs (existing fpixd)
      (3) For clarity, use these three patterns, respectively:
          (a) fpixd = fpixRotate180(NULL, fpixs);
          (b) fpixRotate180(fpixs, fpixs);
          (c) fpixRotate180(fpixd, fpixs);

=head2 fpixRotate90

FPIX * fpixRotate90 ( FPIX *fpixs, l_int32 direction )

  fpixRotate90()

      Input:  fpixs
              direction (1 = clockwise,  -1 = counter-clockwise)
      Return: fpixd, or null on error

  Notes:
      (1) This does a 90 degree rotation of the image about the center,
          either cw or ccw, returning a new pix.
      (2) The direction must be either 1 (cw) or -1 (ccw).

=head2 fpixRotateOrth

FPIX * fpixRotateOrth ( FPIX *fpixs, l_int32 quads )

  fpixRotateOrth()

      Input:  fpixs
              quads (0-3; number of 90 degree cw rotations)
      Return: fpixd, or null on error

=head2 fpixScaleByInteger

FPIX * fpixScaleByInteger ( FPIX *fpixs, l_int32 factor )

  fpixScaleByInteger()

      Input:  fpixs (low resolution, subsampled)
              factor (scaling factor)
      Return: fpixd (interpolated result), or null on error

  Notes:
      (1) The width wd of fpixd is related to ws of fpixs by:
              wd = factor * (ws - 1) + 1   (and ditto for the height)
          We avoid special-casing boundary pixels in the interpolation
          by constructing fpixd by inserting (factor - 1) interpolated
          pixels between each pixel in fpixs.  Then
               wd = ws + (ws - 1) * (factor - 1)    (same as above)
          This also has the advantage that if we subsample by @factor,
          throwing out all the interpolated pixels, we regain the
          original low resolution fpix.

=head2 fpixSetAllArbitrary

l_int32 fpixSetAllArbitrary ( FPIX *fpix, l_float32 inval )

  fpixSetAllArbitrary()

      Input:  fpix
              val (to set at each pixel)
      Return: 0 if OK, 1 on error

=head2 fpixThresholdToPix

PIX * fpixThresholdToPix ( FPIX *fpix, l_float32 thresh )

  fpixThresholdToPix()

      Input:  fpix
              thresh
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) For all values of fpix that are <= thresh, sets the pixel
          in pixd to 1.

=head2 linearInterpolatePixelFloat

l_int32 linearInterpolatePixelFloat ( l_float32 *datas, l_int32 w, l_int32 h, l_float32 x, l_float32 y, l_float32 inval, l_float32 *pval )

  linearInterpolatePixelFloat()

      Input:  datas (ptr to beginning of float image data)
              wpls (32-bit word/line for this data array)
              w, h (of image)
              x, y (floating pt location for evaluation)
              inval (float value brought in from the outside when the
                     input x,y location is outside the image)
              &val (<return> interpolated float value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a standard linear interpolation function.  It is
          equivalent to area weighting on each component, and
          avoids "jaggies" when rendering sharp edges.

=head2 pixComponentFunction

FPIX * pixComponentFunction ( PIX *pix, l_float32 rnum, l_float32 gnum, l_float32 bnum, l_float32 rdenom, l_float32 gdenom, l_float32 bdenom )

  pixComponentFunction()

      Input:  pix (32 bpp rgb)
              rnum, gnum, bnum (coefficients for numerator)
              rdenom, gdenom, bdenom (coefficients for denominator)
      Return: fpixd, or null on error

  Notes:
      (1) This stores a function of the component values of each
          input pixel in @fpixd.
      (2) The function is a ratio of linear combinations of component values.
          There are two special cases for denominator coefficients:
          (a) The denominator is 1.0: input 0 for all denominator coefficients
          (b) Only one component is used in the denominator: input 1.0
              for that denominator component and 0.0 for the other two.
      (3) If the denominator is 0, multiply by an arbitrary number that
          is much larger than 1.  Choose 256 "arbitrarily".

=head2 pixConvertToDPix

DPIX * pixConvertToDPix ( PIX *pixs, l_int32 ncomps )

  pixConvertToDPix()

      Input:  pix (1, 2, 4, 8, 16 or 32 bpp)
              ncomps (number of components: 3 for RGB, 1 otherwise)
      Return: dpix, or null on error

  Notes:
      (1) If colormapped, remove to grayscale.
      (2) If 32 bpp and @ncomps == 3, this is RGB; convert to luminance.
          In all other cases the src image is treated as having a single
          component of pixel values.

=head2 pixConvertToFPix

FPIX * pixConvertToFPix ( PIX *pixs, l_int32 ncomps )

  pixConvertToFPix()

      Input:  pix (1, 2, 4, 8, 16 or 32 bpp)
              ncomps (number of components: 3 for RGB, 1 otherwise)
      Return: fpix, or null on error

  Notes:
      (1) If colormapped, remove to grayscale.
      (2) If 32 bpp and @ncomps == 3, this is RGB; convert to luminance.
          In all other cases the src image is treated as having a single
          component of pixel values.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
