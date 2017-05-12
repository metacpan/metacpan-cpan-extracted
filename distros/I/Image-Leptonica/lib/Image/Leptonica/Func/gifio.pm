package Image::Leptonica::Func::gifio;
$Image::Leptonica::Func::gifio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::gifio

=head1 VERSION

version 0.04

=head1 C<gifio.c>

  gifio.c

    Read gif from file
          PIX        *pixReadStreamGif()
          static PIX *pixInterlaceGIF()

    Write gif to file
          l_int32     pixWriteStreamGif()

    Read/write from/to memory (see warning)
          PIX        *pixReadMemGif()
          l_int32     pixWriteMemGif()

    This uses the gif library, version 4.1.6 or later.
    Do not use 4.1.4.  It has serious problems handling 1 bpp images.

    The initial version of this module was generously contribued by
    Antony Dovgal.  He can be contacted at:  tony *AT* daylessday.org

    There are some issues with version 5:
    - valgrind detects uninitialized values used used for writing
      and conditionally jumping in EGifPutScreenDesc().
    - DGifSlurp() crashes on some images, apparently triggered by
      by some GIF extension records.  The latter problem has been
      reported but not resolved as of October 2013.

=head1 FUNCTIONS

=head2 pixReadMemGif

PIX * pixReadMemGif ( const l_uint8 *cdata, size_t size )

  pixReadMemGif()

      Input:  data (const; gif-encoded)
              size (of data)
      Return: pix, or null on error

  Notes:
      (1) Of course, we are cheating here -- writing the data to file
          in gif format and reading it back in.  We can't use the
          GNU runtime extension fmemopen() to avoid writing to a file
          because libgif doesn't have a file stream interface!
      (2) This should not be assumed to be safe from a sophisticated
          attack, even though we have attempted to make the filename
          difficult to guess by embedding the process number and the
          current time in microseconds.  The best way to handle
          temporary files is to use file descriptors (capabilities)
          or file handles.  However, I know of no way to do this
          for gif files because of the way that libgif handles the
          file descriptors.  The canonical approach would be to do this:
              char templ[] = "hiddenfilenameXXXXXX";
              l_int32 fd = mkstemp(templ);
              FILE *fp = fdopen(fd, "w+b");
              fwrite(data, 1, size, fp);
              rewind(fp);
              Pix *pix = pixReadStreamGif(fp);
          but this fails because fp is in a bad state after writing.

=head2 pixReadStreamGif

PIX * pixReadStreamGif ( FILE *fp )

  pixReadStreamGif()

      Input:  stream
      Return: pix, or null on error

=head2 pixWriteMemGif

l_int32 pixWriteMemGif ( l_uint8 **pdata, size_t *psize, PIX *pix )

  pixWriteMemGif()

      Input:  &data (<return> data of gif compressed image)
              &size (<return> size of returned data)
              pix
      Return: 0 if OK, 1 on error

  Notes:
      (1) See comments in pixReadMemGif()

=head2 pixWriteStreamGif

l_int32 pixWriteStreamGif ( FILE *fp, PIX *pix )

  pixWriteStreamGif()

      Input:  stream
              pix (1, 2, 4, 8, 16 or 32 bpp)
      Return: 0 if OK, 1 on error

  Notes:
      (1) All output gif have colormaps.  If the pix is 32 bpp rgb,
          this quantizes the colors and writes out 8 bpp.
          If the pix is 16 bpp grayscale, it converts to 8 bpp first.
      (2) We can't write to memory using open_memstream() because
          the gif functions write through a file descriptor, not a
          file stream.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
