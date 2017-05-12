package Image::Leptonica::Func::scalelow;
$Image::Leptonica::Func::scalelow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::scalelow

=head1 VERSION

version 0.04

=head1 C<scalelow.c>

  scalelow.c

         Color (interpolated) scaling: general case
                  void       scaleColorLILow()

         Grayscale (interpolated) scaling: general case
                  void       scaleGrayLILow()

         Color (interpolated) scaling: 2x upscaling
                  void       scaleColor2xLILow()
                  void       scaleColor2xLILineLow()

         Grayscale (interpolated) scaling: 2x upscaling
                  void       scaleGray2xLILow()
                  void       scaleGray2xLILineLow()

         Grayscale (interpolated) scaling: 4x upscaling
                  void       scaleGray4xLILow()
                  void       scaleGray4xLILineLow()

         Grayscale and color scaling by closest pixel sampling
                  l_int32    scaleBySamplingLow()

         Color and grayscale downsampling with (antialias) lowpass filter
                  l_int32    scaleSmoothLow()
                  void       scaleRGBToGray2Low()

         Color and grayscale downsampling with (antialias) area mapping
                  l_int32    scaleColorAreaMapLow()
                  l_int32    scaleGrayAreaMapLow()
                  l_int32    scaleAreaMapLow2()

         Binary scaling by closest pixel sampling
                  l_int32    scaleBinaryLow()

         Scale-to-gray 2x
                  void       scaleToGray2Low()
                  l_uint32  *makeSumTabSG2()
                  l_uint8   *makeValTabSG2()

         Scale-to-gray 3x
                  void       scaleToGray3Low()
                  l_uint32  *makeSumTabSG3()
                  l_uint8   *makeValTabSG3()

         Scale-to-gray 4x
                  void       scaleToGray4Low()
                  l_uint32  *makeSumTabSG4()
                  l_uint8   *makeValTabSG4()

         Scale-to-gray 6x
                  void       scaleToGray6Low()
                  l_uint8   *makeValTabSG6()

         Scale-to-gray 8x
                  void       scaleToGray8Low()
                  l_uint8   *makeValTabSG8()

         Scale-to-gray 16x
                  void       scaleToGray16Low()

         Grayscale mipmap
                  l_int32    scaleMipmapLow()

=head1 FUNCTIONS

=head2 makeSumTabSG2

l_uint32 * makeSumTabSG2 ( void )

  makeSumTabSG2()

  Returns a table of 256 l_uint32s, giving the four output
  8-bit grayscale sums corresponding to 8 input bits of a binary
  image, for a 2x scale-to-gray op.  The sums from two
  adjacent scanlines are then added and transformed to
  output four 8 bpp pixel values, using makeValTabSG2().

=head2 makeSumTabSG3

l_uint32 * makeSumTabSG3 ( void )

  makeSumTabSG3()

  Returns a table of 64 l_uint32s, giving the two output
  8-bit grayscale sums corresponding to 6 input bits of a binary
  image, for a 3x scale-to-gray op.  In practice, this would
  be used three times (on adjacent scanlines), and the sums would
  be added and then transformed to output 8 bpp pixel values,
  using makeValTabSG3().

=head2 makeSumTabSG4

l_uint32 * makeSumTabSG4 ( void )

  makeSumTabSG4()

  Returns a table of 256 l_uint32s, giving the two output
  8-bit grayscale sums corresponding to 8 input bits of a binary
  image, for a 4x scale-to-gray op.  The sums from four
  adjacent scanlines are then added and transformed to
  output 8 bpp pixel values, using makeValTabSG4().

=head2 makeValTabSG2

l_uint8 * makeValTabSG2 ( void )

  makeValTabSG2()

  Returns an 8 bit value for the sum of ON pixels
  in a 2x2 square, according to

         val = 255 - (255 * sum)/4

  where sum is in set {0,1,2,3,4}

=head2 makeValTabSG3

l_uint8 * makeValTabSG3 ( void )

  makeValTabSG3()

  Returns an 8 bit value for the sum of ON pixels
  in a 3x3 square, according to
      val = 255 - (255 * sum)/9
  where sum is in set {0, ... ,9}

=head2 makeValTabSG4

l_uint8 * makeValTabSG4 ( void )

  makeValTabSG4()

  Returns an 8 bit value for the sum of ON pixels
  in a 4x4 square, according to

         val = 255 - (255 * sum)/16

  where sum is in set {0, ... ,16}

=head2 makeValTabSG6

l_uint8 * makeValTabSG6 ( void )

  makeValTabSG6()

  Returns an 8 bit value for the sum of ON pixels
  in a 6x6 square, according to
      val = 255 - (255 * sum)/36
  where sum is in set {0, ... ,36}

=head2 makeValTabSG8

l_uint8 * makeValTabSG8 ( void )

  makeValTabSG8()

  Returns an 8 bit value for the sum of ON pixels
  in an 8x8 square, according to
      val = 255 - (255 * sum)/64
  where sum is in set {0, ... ,64}

=head2 scaleAreaMapLow2

void scaleAreaMapLow2 ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 d, l_int32 wpls )

  scaleAreaMapLow2()

  Note: This function is called with either 8 bpp gray or 32 bpp RGB.
        The result is a 2x reduced dest.

=head2 scaleBinaryLow

l_int32 scaleBinaryLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleBinaryLow()

  Notes:
      (1) The dest must be cleared prior to this operation,
          and we clear it here in the low-level code.
      (2) We reuse dest pixels and dest pixel rows whenever
          possible for upscaling; downscaling is done by
          strict subsampling.

=head2 scaleBySamplingLow

l_int32 scaleBySamplingLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 d, l_int32 wpls )

  scaleBySamplingLow()

  Notes:
      (1) The dest must be cleared prior to this operation,
          and we clear it here in the low-level code.
      (2) We reuse dest pixels and dest pixel rows whenever
          possible.  This speeds the upscaling; downscaling
          is done by strict subsampling and is unaffected.
      (3) Because we are sampling and not interpolating, this
          routine works directly, without conversion to full
          RGB color, for 2, 4 or 8 bpp palette color images.

=head2 scaleColor2xLILineLow

void scaleColor2xLILineLow ( l_uint32 *lined, l_int32 wpld, l_uint32 *lines, l_int32 ws, l_int32 wpls, l_int32 lastlineflag )

  scaleColor2xLILineLow()

      Input:  lined   (ptr to top destline, to be made from current src line)
              wpld
              lines   (ptr to current src line)
              ws
              wpls
              lastlineflag  (1 if last src line; 0 otherwise)
      Return: void

  *** Warning: implicit assumption about RGB component ordering 

=head2 scaleColor2xLILow

void scaleColor2xLILow ( l_uint32 *datad, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleColor2xLILow()

  This is a special case of 2x expansion by linear
  interpolation.  Each src pixel contains 4 dest pixels.
  The 4 dest pixels in src pixel 1 are numbered at
  their UL corners.  The 4 dest pixels in src pixel 1
  are related to that src pixel and its 3 neighboring
  src pixels as follows:

             1-----2-----|-----|-----|
             |     |     |     |     |
             |     |     |     |     |
  src 1 -->  3-----4-----|     |     |  <-- src 2
             |     |     |     |     |
             |     |     |     |     |
             |-----|-----|-----|-----|
             |     |     |     |     |
             |     |     |     |     |
  src 3 -->  |     |     |     |     |  <-- src 4
             |     |     |     |     |
             |     |     |     |     |
             |-----|-----|-----|-----|

           dest      src
           ----      ---
           dp1    =  sp1
           dp2    =  (sp1 + sp2) / 2
           dp3    =  (sp1 + sp3) / 2
           dp4    =  (sp1 + sp2 + sp3 + sp4) / 4

  We iterate over the src pixels, and unroll the calculation
  for each set of 4 dest pixels corresponding to that src
  pixel, caching pixels for the next src pixel whenever possible.
  The method is exactly analogous to the one we use for
  scaleGray2xLILow() and its line version.

  P3 speed is about 5 x 10^7 dst pixels/sec/GHz

=head2 scaleColorAreaMapLow

void scaleColorAreaMapLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleColorAreaMapLow()

  This should only be used for downscaling.
  We choose to divide each pixel into 16 x 16 sub-pixels.
  This is much slower than scaleSmoothLow(), but it gives a
  better representation, esp. for downscaling factors between
  1.5 and 5.  All src pixels are subdivided into 256 sub-pixels,
  and are weighted by the number of sub-pixels covered by
  the dest pixel.  This is about 2x slower than scaleSmoothLow(),
  but the results are significantly better on small text.

=head2 scaleColorLILow

void scaleColorLILow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleColorLILow()

  We choose to divide each pixel into 16 x 16 sub-pixels.
  Linear interpolation is equivalent to finding the
  fractional area (i.e., number of sub-pixels divided
  by 256) associated with each of the four nearest src pixels,
  and weighting each pixel value by this fractional area.

  P3 speed is about 7 x 10^6 dst pixels/sec/GHz

=head2 scaleGray2xLILineLow

void scaleGray2xLILineLow ( l_uint32 *lined, l_int32 wpld, l_uint32 *lines, l_int32 ws, l_int32 wpls, l_int32 lastlineflag )

  scaleGray2xLILineLow()

      Input:  lined   (ptr to top destline, to be made from current src line)
              wpld
              lines   (ptr to current src line)
              ws
              wpls
              lastlineflag  (1 if last src line; 0 otherwise)
      Return: void

=head2 scaleGray2xLILow

void scaleGray2xLILow ( l_uint32 *datad, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleGray2xLILow()

  This is a special case of 2x expansion by linear
  interpolation.  Each src pixel contains 4 dest pixels.
  The 4 dest pixels in src pixel 1 are numbered at
  their UL corners.  The 4 dest pixels in src pixel 1
  are related to that src pixel and its 3 neighboring
  src pixels as follows:

             1-----2-----|-----|-----|
             |     |     |     |     |
             |     |     |     |     |
  src 1 -->  3-----4-----|     |     |  <-- src 2
             |     |     |     |     |
             |     |     |     |     |
             |-----|-----|-----|-----|
             |     |     |     |     |
             |     |     |     |     |
  src 3 -->  |     |     |     |     |  <-- src 4
             |     |     |     |     |
             |     |     |     |     |
             |-----|-----|-----|-----|

           dest      src
           ----      ---
           dp1    =  sp1
           dp2    =  (sp1 + sp2) / 2
           dp3    =  (sp1 + sp3) / 2
           dp4    =  (sp1 + sp2 + sp3 + sp4) / 4

  We iterate over the src pixels, and unroll the calculation
  for each set of 4 dest pixels corresponding to that src
  pixel, caching pixels for the next src pixel whenever possible.

=head2 scaleGray4xLILineLow

void scaleGray4xLILineLow ( l_uint32 *lined, l_int32 wpld, l_uint32 *lines, l_int32 ws, l_int32 wpls, l_int32 lastlineflag )

  scaleGray4xLILineLow()

      Input:  lined   (ptr to top destline, to be made from current src line)
              wpld
              lines   (ptr to current src line)
              ws
              wpls
              lastlineflag  (1 if last src line; 0 otherwise)
      Return: void

=head2 scaleGray4xLILow

void scaleGray4xLILow ( l_uint32 *datad, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleGray4xLILow()

  This is a special case of 4x expansion by linear
  interpolation.  Each src pixel contains 16 dest pixels.
  The 16 dest pixels in src pixel 1 are numbered at
  their UL corners.  The 16 dest pixels in src pixel 1
  are related to that src pixel and its 3 neighboring
  src pixels as follows:

             1---2---3---4---|---|---|---|---|
             |   |   |   |   |   |   |   |   |
             5---6---7---8---|---|---|---|---|
             |   |   |   |   |   |   |   |   |
  src 1 -->  9---a---b---c---|---|---|---|---|  <-- src 2
             |   |   |   |   |   |   |   |   |
             d---e---f---g---|---|---|---|---|
             |   |   |   |   |   |   |   |   |
             |===|===|===|===|===|===|===|===|
             |   |   |   |   |   |   |   |   |
             |---|---|---|---|---|---|---|---|
             |   |   |   |   |   |   |   |   |
  src 3 -->  |---|---|---|---|---|---|---|---|  <-- src 4
             |   |   |   |   |   |   |   |   |
             |---|---|---|---|---|---|---|---|
             |   |   |   |   |   |   |   |   |
             |---|---|---|---|---|---|---|---|

           dest      src
           ----      ---
           dp1    =  sp1
           dp2    =  (3 * sp1 + sp2) / 4
           dp3    =  (sp1 + sp2) / 2
           dp4    =  (sp1 + 3 * sp2) / 4
           dp5    =  (3 * sp1 + sp3) / 4
           dp6    =  (9 * sp1 + 3 * sp2 + 3 * sp3 + sp4) / 16
           dp7    =  (3 * sp1 + 3 * sp2 + sp3 + sp4) / 8
           dp8    =  (3 * sp1 + 9 * sp2 + 1 * sp3 + 3 * sp4) / 16
           dp9    =  (sp1 + sp3) / 2
           dp10   =  (3 * sp1 + sp2 + 3 * sp3 + sp4) / 8
           dp11   =  (sp1 + sp2 + sp3 + sp4) / 4
           dp12   =  (sp1 + 3 * sp2 + sp3 + 3 * sp4) / 8
           dp13   =  (sp1 + 3 * sp3) / 4
           dp14   =  (3 * sp1 + sp2 + 9 * sp3 + 3 * sp4) / 16
           dp15   =  (sp1 + sp2 + 3 * sp3 + 3 * sp4) / 8
           dp16   =  (sp1 + 3 * sp2 + 3 * sp3 + 9 * sp4) / 16

  We iterate over the src pixels, and unroll the calculation
  for each set of 16 dest pixels corresponding to that src
  pixel, caching pixels for the next src pixel whenever possible.

=head2 scaleGrayAreaMapLow

void scaleGrayAreaMapLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleGrayAreaMapLow()

  This should only be used for downscaling.
  We choose to divide each pixel into 16 x 16 sub-pixels.
  This is about 2x slower than scaleSmoothLow(), but the results
  are significantly better on small text, esp. for downscaling
  factors between 1.5 and 5.  All src pixels are subdivided
  into 256 sub-pixels, and are weighted by the number of
  sub-pixels covered by the dest pixel.

=head2 scaleGrayLILow

void scaleGrayLILow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 wpls )

  scaleGrayLILow()

  We choose to divide each pixel into 16 x 16 sub-pixels.
  Linear interpolation is equivalent to finding the
  fractional area (i.e., number of sub-pixels divided
  by 256) associated with each of the four nearest src pixels,
  and weighting each pixel value by this fractional area.

=head2 scaleMipmapLow

l_int32 scaleMipmapLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas1, l_int32 wpls1, l_uint32 *datas2, l_int32 wpls2, l_float32 red )

  scaleMipmapLow()

  See notes in scale.c for pixScaleToGrayMipmap().  This function
  is here for pedagogical reasons.  It gives poor results on document
  images because of aliasing.

=head2 scaleRGBToGray2Low

void scaleRGBToGray2Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_float32 rwt, l_float32 gwt, l_float32 bwt )

  scaleRGBToGray2Low()

  Notes:
      (1) This function is called with 32 bpp RGB src and 8 bpp,
          half-resolution dest.  The weights should add to 1.0.

=head2 scaleSmoothLow

l_int32 scaleSmoothLow ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 ws, l_int32 hs, l_int32 d, l_int32 wpls, l_int32 size )

  scaleSmoothLow()

  Notes:
      (1) This function is called on 8 or 32 bpp src and dest images.
      (2) size is the full width of the lowpass smoothing filter.
          It is correlated with the reduction ratio, being the
          nearest integer such that size is approximately equal to hs / hd.

=head2 scaleToGray16Low

void scaleToGray16Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 *tab8 )

  scaleToGray16Low()

      Input:  usual image variables
              tab8  (made from makePixelSumTab8())
      Return: 0 if OK; 1 on error.

  The output is processed one dest byte at a time, corresponding
  to 16 rows consisting each of 2 src bytes in the input image.
  This uses one lookup table, tab8, which gives the sum of
  ON pixels in a byte.  After summing for all ON pixels in the
  32 src bytes, which is between 0 and 256, this is converted
  to an 8 bpp grayscale value between 0 (for 255 or 256 bits ON)
  and 255 (for 0 bits ON).

=head2 scaleToGray2Low

void scaleToGray2Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *sumtab, l_uint8 *valtab )

  scaleToGray2Low()

      Input:  usual image variables
              sumtab  (made from makeSumTabSG2())
              valtab  (made from makeValTabSG2())
      Return: 0 if OK; 1 on error.

  The output is processed in sets of 4 output bytes on a row,
  corresponding to 4 2x2 bit-blocks in the input image.
  Two lookup tables are used.  The first, sumtab, gets the
  sum of ON pixels in 4 sets of two adjacent bits,
  storing the result in 4 adjacent bytes.  After sums from
  two rows have been added, the second table, valtab,
  converts from the sum of ON pixels in the 2x2 block to
  an 8 bpp grayscale value between 0 (for 4 bits ON)
  and 255 (for 0 bits ON).

=head2 scaleToGray3Low

void scaleToGray3Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *sumtab, l_uint8 *valtab )

  scaleToGray3Low()

      Input:  usual image variables
              sumtab  (made from makeSumTabSG3())
              valtab  (made from makeValTabSG3())
      Return: 0 if OK; 1 on error

  Each set of 8 3x3 bit-blocks in the source image, which
  consist of 72 pixels arranged 24 pixels wide by 3 scanlines,
  is converted to a row of 8 8-bit pixels in the dest image.
  These 72 pixels of the input image are runs of 24 pixels
  in three adjacent scanlines.  Each run of 24 pixels is
  stored in the 24 LSbits of a 32-bit word.  We use 2 LUTs.
  The first, sumtab, takes 6 of these bits and stores
  sum, taken 3 bits at a time, in two bytes.  (See
  makeSumTabSG3).  This is done for each of the 3 scanlines,
  and the results are added.  We now have the sum of ON pixels
  in the first two 3x3 blocks in two bytes.  The valtab LUT
  then converts these values (which go from 0 to 9) to
  grayscale values between between 255 and 0.  (See makeValTabSG3).
  This process is repeated for each of the other 3 sets of
  6x3 input pixels, giving 8 output pixels in total.

  Note: because the input image is processed in groups of
        24 x 3 pixels, the process clips the input height to
        (h - h % 3) and the input width to (w - w % 24).

=head2 scaleToGray4Low

void scaleToGray4Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *sumtab, l_uint8 *valtab )

  scaleToGray4Low()

      Input:  usual image variables
              sumtab  (made from makeSumTabSG4())
              valtab  (made from makeValTabSG4())
      Return: 0 if OK; 1 on error.

  The output is processed in sets of 2 output bytes on a row,
  corresponding to 2 4x4 bit-blocks in the input image.
  Two lookup tables are used.  The first, sumtab, gets the
  sum of ON pixels in two sets of four adjacent bits,
  storing the result in 2 adjacent bytes.  After sums from
  four rows have been added, the second table, valtab,
  converts from the sum of ON pixels in the 4x4 block to
  an 8 bpp grayscale value between 0 (for 16 bits ON)
  and 255 (for 0 bits ON).

=head2 scaleToGray6Low

void scaleToGray6Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 *tab8, l_uint8 *valtab )

  scaleToGray6Low()

      Input:  usual image variables
              tab8  (made from makePixelSumTab8())
              valtab  (made from makeValTabSG6())
      Return: 0 if OK; 1 on error

  Each set of 4 6x6 bit-blocks in the source image, which
  consist of 144 pixels arranged 24 pixels wide by 6 scanlines,
  is converted to a row of 4 8-bit pixels in the dest image.
  These 144 pixels of the input image are runs of 24 pixels
  in six adjacent scanlines.  Each run of 24 pixels is
  stored in the 24 LSbits of a 32-bit word.  We use 2 LUTs.
  The first, tab8, takes 6 of these bits and stores
  sum in one byte.  This is done for each of the 6 scanlines,
  and the results are added.
  We now have the sum of ON pixels in the first 6x6 block.  The
  valtab LUT then converts these values (which go from 0 to 36) to
  grayscale values between between 255 and 0.  (See makeValTabSG6).
  This process is repeated for each of the other 3 sets of
  6x6 input pixels, giving 4 output pixels in total.

  Note: because the input image is processed in groups of
        24 x 6 pixels, the process clips the input height to
        (h - h % 6) and the input width to (w - w % 24).

=head2 scaleToGray8Low

void scaleToGray8Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 *tab8, l_uint8 *valtab )

  scaleToGray8Low()

      Input:  usual image variables
              tab8  (made from makePixelSumTab8())
              valtab  (made from makeValTabSG8())
      Return: 0 if OK; 1 on error.

  The output is processed one dest byte at a time,
  corresponding to 8 rows of src bytes in the input image.
  Two lookup tables are used.  The first, tab8, gets the
  sum of ON pixels in a byte.  After sums from 8 rows have
  been added, the second table, valtab, converts from this
  value (which is between 0 and 64) to an 8 bpp grayscale
  value between 0 (for all 64 bits ON) and 255 (for 0 bits ON).

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
