package Image::Leptonica::Func::pnmio;
$Image::Leptonica::Func::pnmio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pnmio

=head1 VERSION

version 0.04

=head1 C<pnmio.c>

  pnmio.c

      Stream interface
          PIX             *pixReadStreamPnm()
          l_int32          readHeaderPnm()
          l_int32          freadHeaderPnm()
          l_int32          pixWriteStreamPnm()
          l_int32          pixWriteStreamAsciiPnm()

      Read/write to memory
          PIX             *pixReadMemPnm()
          l_int32          sreadHeaderPnm()
          l_int32          pixWriteMemPnm()

      Local helpers
          static l_int32   pnmReadNextAsciiValue();
          static l_int32   pnmSkipCommentLines();

      These are here by popular demand, with the help of Mattias
      Kregert (mattias@kregert.se), who provided the first implementation.

      The pnm formats are exceedingly simple, because they have
      no compression and no colormaps.  They support images that
      are 1 bpp; 2, 4, 8 and 16 bpp grayscale; and rgb.

      The original pnm formats ("ascii") are included for completeness,
      but their use is deprecated for all but tiny iconic images.
      They are extremely wasteful of memory; for example, the P1 binary
      ascii format is 16 times as big as the packed uncompressed
      format, because 2 characters are used to represent every bit
      (pixel) in the image.  Reading is slow because we check for extra
      white space and EOL at every sample value.

      The packed pnm formats ("raw") give file sizes similar to
      bmp files, which are uncompressed packed.  However, bmp
      are more flexible, because they can support colormaps.

      We don't differentiate between the different types ("pbm",
      "pgm", "ppm") at the interface level, because this is really a
      "distinction without a difference."  You read a file, you get
      the appropriate Pix.  You write a file from a Pix, you get the
      appropriate type of file.  If there is a colormap on the Pix,
      and the Pix is more than 1 bpp, you get either an 8 bpp pgm
      or a 24 bpp RGB pnm, depending on whether the colormap colors
      are gray or rgb, respectively.

      This follows the general policy that the I/O routines don't
      make decisions about the content of the image -- you do that
      with image processing before you write it out to file.
      The I/O routines just try to make the closest connection
      possible between the file and the Pix in memory.

      On systems like windows without fmemopen() and open_memstream(),
      we write data to a temp file and read it back for operations
      between pix and compressed-data, such as pixReadMemPnm() and
      pixWriteMemPnm().

=head1 FUNCTIONS

=head2 freadHeaderPnm

l_int32 freadHeaderPnm ( FILE *fp, l_int32 *pw, l_int32 *ph, l_int32 *pd, l_int32 *ptype, l_int32 *pbps, l_int32 *pspp )

  freadHeaderPnm()

      Input:  stream opened for read
              &w (<optional return>)
              &h (<optional return>)
              &d (<optional return>)
              &type (<optional return> pnm type)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
      Return: 0 if OK, 1 on error

=head2 pixReadMemPnm

PIX * pixReadMemPnm ( const l_uint8 *cdata, size_t size )

  pixReadMemPnm()

      Input:  cdata (const; pnm-encoded)
              size (of data)
      Return: pix, or null on error

  Notes:
      (1) The @size byte of @data must be a null character.

=head2 pixReadStreamPnm

PIX * pixReadStreamPnm ( FILE *fp )

  pixReadStreamPnm()

      Input:  stream opened for read
      Return: pix, or null on error

=head2 pixWriteMemPnm

l_int32 pixWriteMemPnm ( l_uint8 **pdata, size_t *psize, PIX *pix )

  pixWriteMemPnm()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteStreamPnm() for usage.  This version writes to
          memory instead of to a file stream.

=head2 pixWriteStreamAsciiPnm

l_int32 pixWriteStreamAsciiPnm ( FILE *fp, PIX *pix )

  pixWriteStreamAsciiPnm()

      Input:  stream opened for write
              pix
      Return: 0 if OK; 1 on error

  Writes "ascii" format only:
      1 bpp --> pbm (P1)
      2, 4, 8, 16 bpp, no colormap or grayscale colormap --> pgm (P2)
      2, 4, 8 bpp with color-valued colormap, or rgb --> rgb ppm (P3)

=head2 pixWriteStreamPnm

l_int32 pixWriteStreamPnm ( FILE *fp, PIX *pix )

  pixWriteStreamPnm()

      Input:  stream opened for write
              pix
      Return: 0 if OK; 1 on error

  Notes:
      (1) This writes "raw" packed format only:
          1 bpp --> pbm (P4)
          2, 4, 8, 16 bpp, no colormap or grayscale colormap --> pgm (P5)
          2, 4, 8 bpp with color-valued colormap, or rgb --> rgb ppm (P6)
      (2) 24 bpp rgb are not supported in leptonica, but this will
          write them out as a packed array of bytes (3 to a pixel).

=head2 readHeaderPnm

l_int32 readHeaderPnm ( const char *filename, l_int32 *pw, l_int32 *ph, l_int32 *pd, l_int32 *ptype, l_int32 *pbps, l_int32 *pspp )

  readHeaderPnm()

      Input:  filename
              &w (<optional return>)
              &h (<optional return>)
              &d (<optional return>)
              &type (<optional return> pnm type)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
      Return: 0 if OK, 1 on error

=head2 sreadHeaderPnm

l_int32 sreadHeaderPnm ( const l_uint8 *cdata, size_t size, l_int32 *pw, l_int32 *ph, l_int32 *pd, l_int32 *ptype, l_int32 *pbps, l_int32 *pspp )

  sreadHeaderPnm()

      Input:  cdata (const; pnm-encoded)
              size (of data)
              &w (<optional return>)
              &h (<optional return>)
              &d (<optional return>)
              &type (<optional return> pnm type)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
