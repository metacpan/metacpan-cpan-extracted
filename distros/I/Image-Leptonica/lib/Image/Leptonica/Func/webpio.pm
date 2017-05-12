package Image::Leptonica::Func::webpio;
$Image::Leptonica::Func::webpio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::webpio

=head1 VERSION

version 0.04

=head1 C<webpio.c>

  webpio.c

    Reading WebP
          PIX             *pixReadStreamWebP()
          PIX             *pixReadMemWebP()

    Reading WebP header
          l_int32          readHeaderWebP()

    Writing WebP
          l_int32          pixWriteWebP()  [ special top level ]
          l_int32          pixWriteStreamWebP()
          l_int32          pixWriteMemWebP()

=head1 FUNCTIONS

=head2 pixReadMemWebP

PIX * pixReadMemWebP ( const l_uint8 *filedata, size_t filesize )

  pixReadMemWebP()

      Input:  filedata (webp compressed data in memory)
              filesize (number of bytes in data)
      Return: pix (32 bpp), or null on error

  Notes:
      (1) When the encoded data only has 3 channels (no alpha),
          WebPDecodeRGBAInto() generates a raster of 32-bit pixels, with
          the alpha channel set to opaque (255).
      (2) We don't need to use the gnu runtime functions like fmemopen()
          for redirecting data from a stream to memory, because
          the webp library has been written with memory-to-memory
          functions at the lowest level (which is good!).  And, in
          any event, fmemopen() doesn't work with l_binaryReadStream().

=head2 pixReadStreamWebP

PIX * pixReadStreamWebP ( FILE *fp )

  pixReadStreamWebP()

      Input:  stream corresponding to WebP image
      Return: pix (32 bpp), or null on error

=head2 pixWriteMemWebP

l_int32 pixWriteMemWebP ( l_uint8 **pencdata, size_t *pencsize, PIX *pixs, l_int32 quality, l_int32 lossless )

  pixWriteMemWebP()

      Input:  &encdata (<return> webp encoded data of pixs)
              &encsize (<return> size of webp encoded data)
              pixs (any depth, cmapped OK)
              quality (0 - 100; default ~80)
              lossless (use 1 for lossless; 0 for lossy)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Lossless and lossy encoding are entirely different in webp.
          @quality applies to lossy, and is ignored for lossless.
      (2) The input image is converted to RGB if necessary.  If spp == 3,
          we set the alpha channel to fully opaque (255), and
          WebPEncodeRGBA() then removes the alpha chunk when encoding,
          setting the internal header field has_alpha to 0.

=head2 pixWriteStreamWebP

l_int32 pixWriteStreamWebP ( FILE *fp, PIX *pixs, l_int32 quality, l_int32 lossless )

  pixWriteStreamWebP()

      Input:  stream
              pixs  (all depths)
              quality (0 - 100; default ~80)
              lossless (use 1 for lossless; 0 for lossy)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteMemWebP() for details.
      (2) Use 'free', and not leptonica's 'FREE', for all heap data
          that is returned from the WebP library.

=head2 pixWriteWebP

l_int32 pixWriteWebP ( const char *filename, PIX *pixs, l_int32 quality, l_int32 lossless )

  pixWriteWebP()

      Input:  filename
              pixs
              quality (0 - 100; default ~80)
              lossless (use 1 for lossless; 0 for lossy)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Special top-level function allowing specification of quality.

=head2 readHeaderWebP

l_int32 readHeaderWebP ( const char *filename, l_int32 *pw, l_int32 *ph, l_int32 *pspp )

  readHeaderWebP()

      Input:  filename
              &w (<return> width)
              &h (<return> height)
              &spp (<return> spp (3 or 4))
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
