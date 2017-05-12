package Image::Leptonica::Func::bmpio;
$Image::Leptonica::Func::bmpio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::bmpio

=head1 VERSION

version 0.04

=head1 C<bmpio.c>

  bmpio.c

      Read bmp from file
           PIX          *pixReadStreamBmp()

      Write bmp to file
           l_int32       pixWriteStreamBmp()

      Read/write to memory
           PIX          *pixReadMemBmp()
           l_int32       pixWriteMemBmp()

    On systems like windows without fmemopen() and open_memstream(),
    we write data to a temp file and read it back for operations
    between pix and compressed-data, such as pixReadMemPng() and
    pixWriteMemPng().

=head1 FUNCTIONS

=head2 pixReadMemBmp

PIX * pixReadMemBmp ( const l_uint8 *cdata, size_t size )

  pixReadMemBmp()

      Input:  cdata (const; bmp-encoded)
              size (of data)
      Return: pix, or null on error

  Notes:
      (1) The @size byte of @data must be a null character.

=head2 pixReadStreamBmp

PIX * pixReadStreamBmp ( FILE *fp )

  pixReadStreamBmp()

      Input:  stream opened for read
      Return: pix, or null on error

  Notes:
      (1) Here are references on the bmp file format:
          http://en.wikipedia.org/wiki/BMP_file_format
          http://www.fortunecity.com/skyscraper/windows/364/bmpffrmt.html

=head2 pixWriteMemBmp

l_int32 pixWriteMemBmp ( l_uint8 **pdata, size_t *psize, PIX *pix )

  pixWriteMemBmp()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteStreamBmp() for usage.  This version writes to
          memory instead of to a file stream.

=head2 pixWriteStreamBmp

l_int32 pixWriteStreamBmp ( FILE *fp, PIX *pix )

  pixWriteStreamBmp()

      Input:  stream opened for write
              pix (1, 4, 8, 32 bpp)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We position fp at the beginning of the stream, so it
          truncates any existing data
      (2) 2 bpp Bmp files are apparently not valid!.  We can
          write and read them, but nobody else can read ours.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
