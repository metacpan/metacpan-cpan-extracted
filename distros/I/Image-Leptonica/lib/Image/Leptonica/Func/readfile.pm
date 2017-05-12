package Image::Leptonica::Func::readfile;
$Image::Leptonica::Func::readfile::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::readfile

=head1 VERSION

version 0.04

=head1 C<readfile.c>

  readfile.c:  reads image on file into memory

      Top-level functions for reading images from file
           PIXA      *pixaReadFiles()
           PIXA      *pixaReadFilesSA()
           PIX       *pixRead()
           PIX       *pixReadWithHint()
           PIX       *pixReadIndexed()
           PIX       *pixReadStream()

      Read header information from file
           l_int32    pixReadHeader()

      Format finders
           l_int32    findFileFormat()
           l_int32    findFileFormatStream()
           l_int32    findFileFormatBuffer()
           l_int32    fileFormatIsTiff()

      Read from memory
           PIX       *pixReadMem()
           l_int32    pixReadHeaderMem()

      Test function for I/O with different formats
           l_int32    ioFormatTest()

  Supported file formats:
  (1) Reading is supported without any external libraries:
          bmp
          pnm   (including pbm, pgm, etc)
          spix  (raw serialized)
  (2) Reading is supported with installation of external libraries:
          png
          jpg   (standard jfif version)
          tiff  (including most varieties of compression)
          gif
          webp
  (3) This file format is recognized by the library but reading
      is not supported:
          jp2 (jpeg2000)
  (4) All other file types will get an "unknown format" error.

=head1 FUNCTIONS

=head2 fileFormatIsTiff

l_int32 fileFormatIsTiff ( FILE *fp )

  fileFormatIsTiff()

      Input:  fp (file stream)
      Return: 1 if file is tiff; 0 otherwise or on error

=head2 findFileFormat

l_int32 findFileFormat ( const char *filename, l_int32 *pformat )

  findFileFormat()

      Input:  filename
              &format (<return>)
      Return: 0 if OK, 1 on error or if format is not recognized

=head2 findFileFormatBuffer

l_int32 findFileFormatBuffer ( const l_uint8 *buf, l_int32 *pformat )

  findFileFormatBuffer()

      Input:  byte buffer (at least 12 bytes in size; we can't check)
              &format (<return>)
      Return: 0 if OK, 1 on error or if format is not recognized

  Notes:
      (1) This determines the file format from the first 12 bytes in
          the compressed data stream, which are stored in memory.
      (2) For tiff files, this returns IFF_TIFF.  The specific tiff
          compression is then determined using findTiffCompression().

=head2 findFileFormatStream

l_int32 findFileFormatStream ( FILE *fp, l_int32 *pformat )

  findFileFormatStream()

      Input:  fp (file stream)
              &format (<return>)
      Return: 0 if OK, 1 on error or if format is not recognized

  Notes:
      (1) Important: Side effect -- this resets fp to BOF.

=head2 ioFormatTest

l_int32 ioFormatTest ( const char *filename )

  ioFormatTest()

      Input:  filename (input file)
      Return: 0 if OK; 1 on error or if the test fails

  Notes:
      (1) This writes and reads a set of output files losslessly
          in different formats to /tmp, and tests that the
          result before and after is unchanged.
      (2) This should work properly on input images of any depth,
          with and without colormaps.
      (3) All supported formats are tested for bmp, png, tiff and
          non-ascii pnm.  Ascii pnm also works (but who'd ever want
          to use it?)   We allow 2 bpp bmp, although it's not
          supported elsewhere.  And we don't support reading
          16 bpp png, although this can be turned on in pngio.c.
      (4) This silently skips png or tiff testing if HAVE_LIBPNG
          or HAVE_LIBTIFF are 0, respectively.

=head2 pixRead

PIX * pixRead ( const char *filename )

  pixRead()

      Input:  filename (with full pathname or in local directory)
      Return: pix if OK; null on error

  Notes:
      (1) See at top of file for supported formats.

=head2 pixReadHeader

l_int32 pixReadHeader ( const char *filename, l_int32 *pformat, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  pixReadHeader()

      Input:  filename (with full pathname or in local directory)
              &format (<optional return> file format)
              &w, &h (<optional returns> width and height)
              &bps <optional return> bits/sample
              &spp <optional return> samples/pixel (1, 3 or 4)
              &iscmap (<optional return> 1 if cmap exists; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This reads the actual headers for jpeg, png, tiff and pnm.
          For bmp and gif, we cheat and read the entire file into a pix,
          from which we extract the "header" information.

=head2 pixReadHeaderMem

l_int32 pixReadHeaderMem ( const l_uint8 *data, size_t size, l_int32 *pformat, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  pixReadHeaderMem()

      Input:  data (const; encoded)
              datasize (size of data)
              &format (<optional returns> image format)
              &w, &h (<optional returns> width and height)
              &bps <optional return> bits/sample
              &spp <optional return> samples/pixel (1, 3 or 4)
              &iscmap (<optional return> 1 if cmap exists; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This reads the actual headers for jpeg, png, tiff and pnm.
          For bmp and gif, we cheat and read all the data into a pix,
          from which we extract the "header" information.
      (2) On windows, this will only read tiff formatted files from
          memory.  For other formats, it requires fmemopen(3).
          Attempts to read those formats will fail at runtime.
      (3) findFileFormatBuffer() requires up to 8 bytes to decide on
          the format.  That determines the constraint here.

=head2 pixReadIndexed

PIX * pixReadIndexed ( SARRAY *sa, l_int32 index )

  pixReadIndexed()

      Input:  sarray (of full pathnames)
              index (into pathname array)
      Return: pix if OK; null if not found

  Notes:
      (1) This function is useful for selecting image files from a
          directory, where the integer @index is embedded into
          the file name.
      (2) This is typically done by generating the sarray using
          getNumberedPathnamesInDirectory(), so that the @index
          pathname would have the number @index in it.  The size
          of the sarray should be the largest number (plus 1) appearing
          in the file names, respecting the constraints in the
          call to getNumberedPathnamesInDirectory().
      (3) Consequently, for some indices into the sarray, there may
          be no pathnames in the directory containing that number.
          By convention, we place empty C strings ("") in those
          locations in the sarray, and it is not an error if such
          a string is encountered and no pix is returned.
          Therefore, the caller must verify that a pix is returned.
      (4) See convertSegmentedPagesToPS() in src/psio1.c for an
          example of usage.

=head2 pixReadMem

PIX * pixReadMem ( const l_uint8 *data, size_t size )

  pixReadMem()

      Input:  data (const; encoded)
              datasize (size of data)
      Return: pix, or null on error

  Notes:
      (1) This is a variation of pixReadStream(), where the data is read
          from a memory buffer rather than a file.
      (2) On windows, this will only read tiff formatted files from
          memory.  For other formats, it requires fmemopen(3).
          Attempts to read those formats will fail at runtime.
      (3) findFileFormatBuffer() requires up to 8 bytes to decide on
          the format.  That determines the constraint here.

=head2 pixReadStream

PIX * pixReadStream ( FILE *fp, l_int32 hint )

  pixReadStream()

      Input:  fp (file stream)
              hint (bitwise OR of L_HINT_* values for jpeg; use 0 for no hint)
      Return: pix if OK; null on error

  Notes:
      (1) The hint only applies to jpeg.

=head2 pixReadWithHint

PIX * pixReadWithHint ( const char *filename, l_int32 hint )

  pixReadWithHint()

      Input:  filename (with full pathname or in local directory)
              hint (bitwise OR of L_HINT_* values for jpeg; use 0 for no hint)
      Return: pix if OK; null on error

  Notes:
      (1) The hint is not binding, but may be used to optimize jpeg decoding.
          Use 0 for no hinting.

=head2 pixaReadFiles

PIXA * pixaReadFiles ( const char *dirname, const char *substr )

  pixaReadFiles()

      Input:  dirname
              substr (<optional> substring filter on filenames; can be null)
      Return: pixa, or null on error

  Notes:
      (1) @dirname is the full path for the directory.
      (2) @substr is the part of the file name (excluding
          the directory) that is to be matched.  All matching
          filenames are read into the Pixa.  If substr is NULL,
          all filenames are read into the Pixa.

=head2 pixaReadFilesSA

PIXA * pixaReadFilesSA ( SARRAY *sa )

  pixaReadFilesSA()

      Input:  sarray (full pathnames for all files)
      Return: pixa, or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
