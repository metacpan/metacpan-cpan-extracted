package Image::Leptonica::Func::pixarith;
$Image::Leptonica::Func::pixarith::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixarith

=head1 VERSION

version 0.04

=head1 C<pixarith.c>

  pixarith.c

      One-image grayscale arithmetic operations (8, 16, 32 bpp)
           l_int32     pixAddConstantGray()
           l_int32     pixMultConstantGray()

      Two-image grayscale arithmetic operations (8, 16, 32 bpp)
           PIX        *pixAddGray()
           PIX        *pixSubtractGray()

      Grayscale threshold operation (8, 16, 32 bpp)
           PIX        *pixThresholdToValue()

      Image accumulator arithmetic operations
           PIX        *pixInitAccumulate()
           PIX        *pixFinalAccumulate()
           PIX        *pixFinalAccumulateThreshold()
           l_int32     pixAccumulate()
           l_int32     pixMultConstAccumulate()

      Absolute value of difference
           PIX        *pixAbsDifference()

      Sum of color images
           PIX        *pixAddRGB()

      Two-image min and max operations (8 and 16 bpp)
           PIX        *pixMinOrMax()

      Scale pix for maximum dynamic range in 8 bpp image:
           PIX        *pixMaxDynamicRange()

      Log base2 lookup
           l_float32  *makeLogBase2Tab()
           l_float32   getLogBase2()

      The image accumulator operations are used when you expect
      overflow from 8 bits on intermediate results.  For example,
      you might want a tophat contrast operator which is
         3*I - opening(I,S) - closing(I,S)
      To use these operations, first use the init to generate
      a 16 bpp image, use the accumulate to add or subtract 8 bpp
      images from that, or the multiply constant to multiply
      by a small constant (much less than 256 -- we don't want
      overflow from the 16 bit images!), and when you're finished
      use final to bring the result back to 8 bpp, clipped
      if necessary.  There is also a divide function, which
      can be used to divide one image by another, scaling the
      result for maximum dynamic range, and giving back the
      8 bpp result.

      A simpler interface to the arithmetic operations is
      provided in pixacc.c.

=head1 FUNCTIONS

=head2 getLogBase2

l_float32 getLogBase2 ( l_int32 val, l_float32 *logtab )

 getLogBase2()

     Input:  val
             logtab (256-entry table of logs)
     Return: logdist, or 0 on error

=head2 makeLogBase2Tab

l_float32 * makeLogBase2Tab ( void )

  makeLogBase2Tab()

      Input: void
      Return: table (giving the log[base 2] of val)

=head2 pixAbsDifference

PIX * pixAbsDifference ( PIX *pixs1, PIX *pixs2 )

  pixAbsDifference()

      Input:  pixs1, pixs2  (both either 8 or 16 bpp gray, or 32 bpp RGB)
      Return: pixd, or null on error

  Notes:
      (1) The depth of pixs1 and pixs2 must be equal.
      (2) Clips computation to the min size, aligning the UL corners
      (3) For 8 and 16 bpp, assumes one gray component.
      (4) For 32 bpp, assumes 3 color components, and ignores the
          LSB of each word (the alpha channel)
      (5) Computes the absolute value of the difference between
          each component value.

=head2 pixAccumulate

l_int32 pixAccumulate ( PIX *pixd, PIX *pixs, l_int32 op )

  pixAccumulate()

      Input:  pixd (32 bpp)
              pixs (1, 8, 16 or 32 bpp)
              op  (L_ARITH_ADD or L_ARITH_SUBTRACT)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This adds or subtracts each pixs value from pixd.
      (2) This clips to the minimum of pixs and pixd, so they
          do not need to be the same size.
      (3) The alignment is to the origin (UL corner) of pixs & pixd.

=head2 pixAddConstantGray

l_int32 pixAddConstantGray ( PIX *pixs, l_int32 val )

  pixAddConstantGray()

      Input:  pixs (8, 16 or 32 bpp)
              val  (amount to add to each pixel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) In-place operation.
      (2) No clipping for 32 bpp.
      (3) For 8 and 16 bpp, if val > 0 the result is clipped
          to 0xff and 0xffff, rsp.
      (4) For 8 and 16 bpp, if val < 0 the result is clipped to 0.

=head2 pixAddGray

PIX * pixAddGray ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixAddGray()

      Input:  pixd (<optional>; this can be null, equal to pixs1, or
                    different from pixs1)
              pixs1 (can be == to pixd)
              pixs2
      Return: pixd always

  Notes:
      (1) Arithmetic addition of two 8, 16 or 32 bpp images.
      (2) For 8 and 16 bpp, we do explicit clipping to 0xff and 0xffff,
          respectively.
      (3) Alignment is to UL corner.
      (4) There are 3 cases.  The result can go to a new dest,
          in-place to pixs1, or to an existing input dest:
          * pixd == null:   (src1 + src2) --> new pixd
          * pixd == pixs1:  (src1 + src2) --> src1  (in-place)
          * pixd != pixs1:  (src1 + src2) --> input pixd
      (5) pixs2 must be different from both pixd and pixs1.

=head2 pixAddRGB

PIX * pixAddRGB ( PIX *pixs1, PIX *pixs2 )

  pixAddRGB()

      Input:  pixs1, pixs2  (32 bpp RGB, or colormapped)
      Return: pixd, or null on error

  Notes:
      (1) Clips computation to the minimum size, aligning the UL corners.
      (2) Removes any colormap to RGB, and ignores the LSB of each
          pixel word (the alpha channel).
      (3) Adds each component value, pixelwise, clipping to 255.
      (4) This is useful to combine two images where most of the
          pixels are essentially black, such as in pixPerceptualDiff().

=head2 pixFinalAccumulate

PIX * pixFinalAccumulate ( PIX *pixs, l_uint32 offset, l_int32 depth )

  pixFinalAccumulate()

      Input:  pixs (32 bpp)
              offset (same as used for initialization)
              depth  (8, 16 or 32 bpp, of destination)
      Return: pixd (8, 16 or 32 bpp), or null on error

  Notes:
      (1) The offset must be >= 0 and should not exceed 0x40000000.
      (2) The offset is subtracted from the src 32 bpp image
      (3) For 8 bpp dest, the result is clipped to [0, 0xff]
      (4) For 16 bpp dest, the result is clipped to [0, 0xffff]

=head2 pixFinalAccumulateThreshold

PIX * pixFinalAccumulateThreshold ( PIX *pixs, l_uint32 offset, l_uint32 threshold )

  pixFinalAccumulateThreshold()

      Input:  pixs (32 bpp)
              offset (same as used for initialization)
              threshold (values less than this are set in the destination)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) The offset must be >= 0 and should not exceed 0x40000000.
      (2) The offset is subtracted from the src 32 bpp image

=head2 pixInitAccumulate

PIX * pixInitAccumulate ( l_int32 w, l_int32 h, l_uint32 offset )

  pixInitAccumulate()

      Input:  w, h (of accumulate array)
              offset (initialize the 32 bpp to have this
                      value; not more than 0x40000000)
      Return: pixd (32 bpp), or null on error

  Notes:
      (1) The offset must be >= 0.
      (2) The offset is used so that we can do arithmetic
          with negative number results on l_uint32 data; it
          prevents the l_uint32 data from going negative.
      (3) Because we use l_int32 intermediate data results,
          these should never exceed the max of l_int32 (0x7fffffff).
          We do not permit the offset to be above 0x40000000,
          which is half way between 0 and the max of l_int32.
      (4) The same offset should be used for initialization,
          multiplication by a constant, and final extraction!
      (5) If you're only adding positive values, offset can be 0.

=head2 pixMaxDynamicRange

PIX * pixMaxDynamicRange ( PIX *pixs, l_int32 type )

  pixMaxDynamicRange()

      Input:  pixs  (4, 8, 16 or 32 bpp source)
              type  (L_LINEAR_SCALE or L_LOG_SCALE)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) Scales pixel values to fit maximally within the dest 8 bpp pixd
      (2) Uses a LUT for log scaling

=head2 pixMinOrMax

PIX * pixMinOrMax ( PIX *pixd, PIX *pixs1, PIX *pixs2, l_int32 type )

  pixMinOrMax()

      Input:  pixd  (<optional> destination: this can be null,
                     equal to pixs1, or different from pixs1)
              pixs1 (can be == to pixd)
              pixs2
              type (L_CHOOSE_MIN, L_CHOOSE_MAX)
      Return: pixd always

  Notes:
      (1) This gives the min or max of two images, component-wise.
      (2) The depth can be 8 or 16 bpp for 1 component, and 32 bpp
          for a 3 component image.  For 32 bpp, ignore the LSB
          of each word (the alpha channel)
      (3) There are 3 cases:
          -  if pixd == null,   Min(src1, src2) --> new pixd
          -  if pixd == pixs1,  Min(src1, src2) --> src1  (in-place)
          -  if pixd != pixs1,  Min(src1, src2) --> input pixd

=head2 pixMultConstAccumulate

l_int32 pixMultConstAccumulate ( PIX *pixs, l_float32 factor, l_uint32 offset )

  pixMultConstAccumulate()

      Input:  pixs (32 bpp)
              factor
              offset (same as used for initialization)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The offset must be >= 0 and should not exceed 0x40000000.
      (2) This multiplies each pixel, relative to offset, by the input factor
      (3) The result is returned with the offset back in place.

=head2 pixMultConstantGray

l_int32 pixMultConstantGray ( PIX *pixs, l_float32 val )

  pixMultConstantGray()

      Input:  pixs (8, 16 or 32 bpp)
              val  (>= 0.0; amount to multiply by each pixel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) In-place operation; val must be >= 0.
      (2) No clipping for 32 bpp.
      (3) For 8 and 16 bpp, the result is clipped to 0xff and 0xffff, rsp.

=head2 pixSubtractGray

PIX * pixSubtractGray ( PIX *pixd, PIX *pixs1, PIX *pixs2 )

  pixSubtractGray()

      Input:  pixd (<optional>; this can be null, equal to pixs1, or
                    different from pixs1)
              pixs1 (can be == to pixd)
              pixs2
      Return: pixd always

  Notes:
      (1) Arithmetic subtraction of two 8, 16 or 32 bpp images.
      (2) Source pixs2 is always subtracted from source pixs1.
      (3) Do explicit clipping to 0.
      (4) Alignment is to UL corner.
      (5) There are 3 cases.  The result can go to a new dest,
          in-place to pixs1, or to an existing input dest:
          (a) pixd == null   (src1 - src2) --> new pixd
          (b) pixd == pixs1  (src1 - src2) --> src1  (in-place)
          (d) pixd != pixs1  (src1 - src2) --> input pixd
      (6) pixs2 must be different from both pixd and pixs1.

=head2 pixThresholdToValue

PIX * pixThresholdToValue ( PIX *pixd, PIX *pixs, l_int32 threshval, l_int32 setval )

  pixThresholdToValue()

      Input:  pixd (<optional>; if not null, must be equal to pixs)
              pixs (8, 16, 32 bpp)
              threshval
              setval
      Return: pixd always

  Notes:
    - operation can be in-place (pixs == pixd) or to a new pixd
    - if setval > threshval, sets pixels with a value >= threshval to setval
    - if setval < threshval, sets pixels with a value <= threshval to setval
    - if setval == threshval, no-op

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
