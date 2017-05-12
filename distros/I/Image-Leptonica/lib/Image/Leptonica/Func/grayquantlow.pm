package Image::Leptonica::Func::grayquantlow;
$Image::Leptonica::Func::grayquantlow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::grayquantlow

=head1 VERSION

version 0.04

=head1 C<grayquantlow.c>

  grayquantlow.c

      Thresholding from 8 bpp to 1 bpp

          Floyd-Steinberg dithering to binary
              void       ditherToBinaryLow()
              void       ditherToBinaryLineLow()

          Simple (pixelwise) binarization
              void       thresholdToBinaryLow()
              void       thresholdToBinaryLineLow()

          A slower version of Floyd-Steinberg dithering that uses LUTs
              void       ditherToBinaryLUTLow()
              void       ditherToBinaryLineLUTLow()
              l_int32    make8To1DitherTables()

      Thresholding from 8 bpp to 2 bpp

          Floyd-Steinberg-like dithering to 2 bpp
              void       ditherTo2bppLow()
              void       ditherTo2bppLineLow()
              l_int32    make8To2DitherTables()

          Simple thresholding to 2 bpp
              void       thresholdTo2bppLow()

      Thresholding from 8 bpp to 4 bpp

          Simple thresholding to 4 bpp
              void       thresholdTo4bppLow()

=head1 FUNCTIONS

=head2 ditherTo2bppLineLow

void ditherTo2bppLineLow ( l_uint32 *lined, l_int32 w, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 *tabval, l_int32 *tab38, l_int32 *tab14, l_int32 lastlineflag )

  ditherTo2bppLineLow()

      Input:  lined  (ptr to beginning of dest line
              w   (width of image in pixels)
              bufs1 (buffer of current source line)
              bufs2 (buffer of next source line)
              tabval (value to assign for current pixel)
              tab38 (excess value to give to neighboring 3/8 pixels)
              tab14 (excess value to give to neighboring 1/4 pixel)
              lastlineflag  (0 if not last dest line, 1 if last dest line)
      Return: void

  Dispatches error diffusion dithering for
  a single line of the image.  If lastlineflag == 0,
  both source buffers are used; otherwise, only bufs1
  is used.  We use source buffers because the error
  is propagated into them, and we don't want to change
  the input src image.

  We break dithering out line by line to make it
  easier to combine functions like interpolative
  scaling and error diffusion dithering, as such a
  combination of operations obviates the need to
  generate a 2x grayscale image as an intermediary.

=head2 ditherTo2bppLow

void ditherTo2bppLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 *tabval, l_int32 *tab38, l_int32 *tab14 )

  ditherTo2bppLow()

  Low-level function for doing Floyd-Steinberg error diffusion
  dithering from 8 bpp (datas) to 2 bpp (datad).  Two source
  line buffers, bufs1 and bufs2, are provided, along with three
  256-entry lookup tables: tabval gives the output pixel value,
  tab38 gives the extra (plus or minus) transferred to the pixels
  directly to the left and below, and tab14 gives the extra
  transferred to the diagonal below.  The choice of 3/8 and 1/4
  is traditional but arbitrary when you use a lookup table; the
  only constraint is that the sum is 1.  See other comments
  below and in grayquant.c.

=head2 ditherToBinaryLUTLow

void ditherToBinaryLUTLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 *tabval, l_int32 *tab38, l_int32 *tab14 )

  ditherToBinaryLUTLow()

  Low-level function for doing Floyd-Steinberg error diffusion
  dithering from 8 bpp (datas) to 1 bpp (datad).  Two source
  line buffers, bufs1 and bufs2, are provided, along with three
  256-entry lookup tables: tabval gives the output pixel value,
  tab38 gives the extra (plus or minus) transferred to the pixels
  directly to the left and below, and tab14 gives the extra
  transferred to the diagonal below.  The choice of 3/8 and 1/4
  is traditional but arbitrary when you use a lookup table; the
  only constraint is that the sum is 1.  See other comments below.

=head2 ditherToBinaryLineLUTLow

void ditherToBinaryLineLUTLow ( l_uint32 *lined, l_int32 w, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 *tabval, l_int32 *tab38, l_int32 *tab14, l_int32 lastlineflag )

  ditherToBinaryLineLUTLow()

      Input:  lined  (ptr to beginning of dest line
              w   (width of image in pixels)
              bufs1 (buffer of current source line)
              bufs2 (buffer of next source line)
              tabval (value to assign for current pixel)
              tab38 (excess value to give to neighboring 3/8 pixels)
              tab14 (excess value to give to neighboring 1/4 pixel)
              lastlineflag  (0 if not last dest line, 1 if last dest line)
      Return: void

=head2 ditherToBinaryLineLow

void ditherToBinaryLineLow ( l_uint32 *lined, l_int32 w, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 lowerclip, l_int32 upperclip, l_int32 lastlineflag )

  ditherToBinaryLineLow()

      Input:  lined  (ptr to beginning of dest line
              w   (width of image in pixels)
              bufs1 (buffer of current source line)
              bufs2 (buffer of next source line)
              lowerclip (lower clip distance to black)
              upperclip (upper clip distance to white)
              lastlineflag  (0 if not last dest line, 1 if last dest line)
      Return: void

  Dispatches FS error diffusion dithering for
  a single line of the image.  If lastlineflag == 0,
  both source buffers are used; otherwise, only bufs1
  is used.  We use source buffers because the error
  is propagated into them, and we don't want to change
  the input src image.

  We break dithering out line by line to make it
  easier to combine functions like interpolative
  scaling and error diffusion dithering, as such a
  combination of operations obviates the need to
  generate a 2x grayscale image as an intermediary.

=head2 ditherToBinaryLow

void ditherToBinaryLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_uint32 *bufs1, l_uint32 *bufs2, l_int32 lowerclip, l_int32 upperclip )

  ditherToBinaryLow()

  See comments in pixDitherToBinary() in binarize.c

=head2 make8To1DitherTables

l_int32 make8To1DitherTables ( l_int32 **ptabval, l_int32 **ptab38, l_int32 **ptab14, l_int32 lowerclip, l_int32 upperclip )

  make8To1DitherTables()

      Input: &tabval (value assigned to output pixel; 0 or 1)
             &tab38  (amount propagated to pixels left and below)
             &tab14  (amount propagated to pixel to left and down)
             lowerclip (values near 0 where the excess is not propagated)
             upperclip (values near 255 where the deficit is not propagated)

      Return: 0 if OK, 1 on error

=head2 make8To2DitherTables

l_int32 make8To2DitherTables ( l_int32 **ptabval, l_int32 **ptab38, l_int32 **ptab14, l_int32 cliptoblack, l_int32 cliptowhite )

  make8To2DitherTables()

      Input: &tabval (value assigned to output pixel; 0, 1, 2 or 3)
             &tab38  (amount propagated to pixels left and below)
             &tab14  (amount propagated to pixel to left and down)
             cliptoblack (values near 0 where the excess is not propagated)
             cliptowhite (values near 255 where the deficit is not propagated)

      Return: 0 if OK, 1 on error

=head2 thresholdTo2bppLow

void thresholdTo2bppLow ( l_uint32 *datad, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 *tab )

  thresholdTo2bppLow()

  Low-level function for thresholding from 8 bpp (datas) to
  2 bpp (datad), using thresholds implicitly defined through @tab,
  a 256-entry lookup table that gives a 2-bit output value
  for each possible input.

  For each line, unroll the loop so that for each 32 bit src word,
  representing four consecutive 8-bit pixels, we compose one byte
  of output consisiting of four 2-bit pixels.

=head2 thresholdTo4bppLow

void thresholdTo4bppLow ( l_uint32 *datad, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 *tab )

  thresholdTo4bppLow()

  Low-level function for thresholding from 8 bpp (datas) to
  4 bpp (datad), using thresholds implicitly defined through @tab,
  a 256-entry lookup table that gives a 4-bit output value
  for each possible input.

  For each line, unroll the loop so that for each 32 bit src word,
  representing four consecutive 8-bit pixels, we compose two bytes
  of output consisiting of four 4-bit pixels.

=head2 thresholdToBinaryLineLow

void thresholdToBinaryLineLow ( l_uint32 *lined, l_int32 w, l_uint32 *lines, l_int32 d, l_int32 thresh )

  thresholdToBinaryLineLow()

=head2 thresholdToBinaryLow

void thresholdToBinaryLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 d, l_int32 wpls, l_int32 thresh )

  thresholdToBinaryLow()

  If the source pixel is less than thresh,
  the dest will be 1; otherwise, it will be 0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
