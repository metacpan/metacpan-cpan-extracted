package Image::Leptonica::Func::jpegio;
$Image::Leptonica::Func::jpegio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::jpegio

=head1 VERSION

version 0.04

=head1 C<jpegio.c>

  jpegio.c

    Read jpeg from file
          PIX             *pixReadJpeg()  [special top level]
          PIX             *pixReadStreamJpeg()

    Read jpeg metadata from file
          l_int32          readHeaderJpeg()
          l_int32          freadHeaderJpeg()
          l_int32          fgetJpegResolution()
          l_int32          fgetJpegComment()

    Write jpeg to file
          l_int32          pixWriteJpeg()  [special top level]
          l_int32          pixWriteStreamJpeg()

    Read/write to memory
          PIX             *pixReadMemJpeg()
          l_int32          readHeaderMemJpeg()
          l_int32          pixWriteMemJpeg()

    Setting special flag
          l_int32          pixSetChromaSampling()

    Static system helpers
          static void      jpeg_error_catch_all_1()
          static void      jpeg_error_catch_all_2()
          static l_uint8   jpeg_getc()
          static l_int32   jpeg_comment_callback()

    Extraction of jpeg header info by parsing  [deprecated]
          l_int32          extractJpegDataFromFile()
          l_int32          extractJpegDataFromArray()
          static l_int32   extractJpegHeaderDataFallback()
          static l_int32   locateJpegImageParameters()
          static l_int32   getNextJpegMarker()
          static l_int32   getTwoByteParameter()

    Documentation: libjpeg.doc can be found, along with all
    source code, at ftp://ftp.uu.net/graphics/jpeg
    Download and untar the file:  jpegsrc.v6b.tar.gz
    A good paper on jpeg can also be found there: wallace.ps.gz

    The functions in libjpeg make it very simple to compress
    and decompress images.  On input (decompression from file),
    3 component color images can be read into either an 8 bpp Pix
    with a colormap or a 32 bpp Pix with RGB components.  For output
    (compression to file), all color Pix, whether 8 bpp with a
    colormap or 32 bpp, are written compressed as a set of three
    8 bpp (rgb) images.

    Low-level error handling
    ------------------------
    The default behavior of the jpeg library is to call exit.
    This is often undesirable, and the caller should make the
    decision when to abort a process.  To prevent the jpeg library
    from calling exit(), setjmp() has been inserted into all
    readers and writers, and the cinfo struct has been set up so that
    the low-level jpeg library will call a special error handler
    that doesn't exit, instead of the default function error_exit().

    To avoid race conditions and make these functions thread-safe in
    the rare situation where calls to two threads are simultaneously
    failing on bad jpegs, we insert a local copy of the jmp_buf struct
    into the cinfo.client_data field, and use this on longjmp.
    For extracting the jpeg comment, we have the added complication
    that the client_data field must also return the jpeg comment,
    and we use a different error handler.

    How to avoid subsampling the chroma channels
    --------------------------------------------
    When writing, you can avoid subsampling the U,V (chroma)
    channels.  This gives higher quality for the color, which is
    important for some situations.  The default subsampling is 2x2 on
    both channels.  Before writing, call pixSetChromaSampling(pix, 0)
    to prevent chroma subsampling.

    Compressing to memory and decompressing from memory
    ---------------------------------------------------
    On systems like windows without fmemopen() and open_memstream(),
    we write data to a temp file and read it back for operations
    between pix and compressed-data, such as pixReadMemJpeg() and
    pixWriteMemJpeg().

    Vestigial code: parsing the jpeg file for header metadata
    ---------------------------------------------------------
    For extracting header metadata, we used to parse the file, looking
    for specific markers.  This is error-prone because of non-standard
    jpeg files and you should use readHeaderJpeg() and readHeaderMemJpeg()
    instead.  Nevertheless, it is retained here in case you want to
    understand a bit about how to parse jpeg markers.

=head1 FUNCTIONS

=head2 extractJpegDataFromArray

l_int32 extractJpegDataFromArray ( const void *data, size_t nbytes, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp )

  extractJpegDataFromArray()

      Input:  data (binary data consisting of the entire jpeg file)
              nbytes (size of binary data)
              &w (<optional return> image width)
              &h (<optional return> image height)
              &bps (<optional return> bits/sample; should be 8)
              &spp (<optional return> samples/pixel; should be 1, 3 or 4)
      Return: 0 if OK, 1 on error

=head2 extractJpegDataFromFile

l_int32 extractJpegDataFromFile ( const char *filein, l_uint8 **pdata, size_t *pnbytes, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp )

  extractJpegDataFromFile()

      Input:  filein
              &data (<optional return> binary jpeg compressed file data)
              &nbytes (<optional return> size of binary jpeg data)
              &w (<optional return> image width)
              &h (<optional return> image height)
              &bps (<optional return> bits/sample; should be 8)
              &spp (<optional return> samples/pixel; should be 1 or 3)
      Return: 0 if OK, 1 on error

=head2 fgetJpegComment

l_int32 fgetJpegComment ( FILE *fp, l_uint8 **pcomment )

  fgetJpegComment()

      Input:  stream (opened for read)
              &comment (<return> comment)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Side-effect: this rewinds the stream.

=head2 fgetJpegResolution

l_int32 fgetJpegResolution ( FILE *fp, l_int32 *pxres, l_int32 *pyres )

  fgetJpegResolution()

      Input:  stream (opened for read)
              &xres, &yres (<return> resolution in ppi)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If neither resolution field is set, this is not an error;
          the returned resolution values are 0 (designating 'unknown').
      (2) Side-effect: this rewinds the stream.

=head2 freadHeaderJpeg

l_int32 freadHeaderJpeg ( FILE *fp, l_int32 *pw, l_int32 *ph, l_int32 *pspp, l_int32 *pycck, l_int32 *pcmyk )

  freadHeaderJpeg()

      Input:  stream
              &w (<optional return>)
              &h (<optional return>)
              &spp (<optional return>, samples/pixel)
              &ycck (<optional return>, 1 if ycck color space; 0 otherwise)
              &cmyk (<optional return>, 1 if cmyk color space; 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 pixReadJpeg

PIX * pixReadJpeg ( const char *filename, l_int32 cmflag, l_int32 reduction, l_int32 *pnwarn )

  pixReadJpeg()

      Input:  filename
              colormap flag (0 means return RGB image if color;
                             1 means create colormap and return 8 bpp
                               palette image if color)
              reduction (scaling factor: 1, 2, 4 or 8)
              &nwarn (<optional return> number of warnings about
                       corrupted data)
      Return: pix, or null on error

  Images reduced by factors of 2, 4 or 8 can be returned
  significantly faster than full resolution images.

  The jpeg library will return warnings (or exit) if
  the jpeg data is bad.  Use this function if you want the
  jpeg library to create an 8 bpp palette image, or to
  tell if the jpeg data has been corrupted.  For corrupt jpeg
  data, there are two possible outcomes:
    (1) a damaged pix will be returned, along with a nonzero
        number of warnings, or
    (2) for sufficiently serious problems, the library will attempt
        to exit (caught by our error handler) and no pix will be returned.

=head2 pixReadMemJpeg

PIX * pixReadMemJpeg ( const l_uint8 *cdata, size_t size, l_int32 cmflag, l_int32 reduction, l_int32 *pnwarn, l_int32 hint )

  pixReadMemJpeg()

      Input:  cdata (const; jpeg-encoded)
              size (of data)
              colormap flag (0 means return RGB image if color;
                             1 means create colormap and return 8 bpp
                               palette image if color)
              reduction (scaling factor: 1, 2, 4 or 8)
              &nwarn (<optional return> number of warnings)
              hint (bitwise OR of L_HINT_* values; use 0 for no hint)
      Return: pix, or null on error

  Notes:
      (1) The @size byte of @data must be a null character.
      (2) See pixReadJpeg() for usage.

=head2 pixReadStreamJpeg

PIX * pixReadStreamJpeg ( FILE *fp, l_int32 cmflag, l_int32 reduction, l_int32 *pnwarn, l_int32 hint )

  pixReadStreamJpeg()

      Input:  stream
              colormap flag (0 means return RGB image if color;
                             1 means create colormap and return 8 bpp
                               palette image if color)
              reduction (scaling factor: 1, 2, 4 or 8)
              &nwarn (<optional return> number of warnings)
              hint: (a bitwise OR of L_HINT_* values); use 0 for no hints
      Return: pix, or null on error

  Usage: see pixReadJpeg()
  Notes:
      (1) This does not get the jpeg comment.

=head2 pixSetChromaSampling

l_int32 pixSetChromaSampling ( PIX *pix, l_int32 sampling )

  pixSetChromaSampling()

      Input:  pix
              sampling (1 for subsampling; 0 for no subsampling)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The default is for 2x2 chroma subsampling because the files are
          considerably smaller and the appearance is typically satisfactory.
          Call this with @sampling == 0 for full resolution output in
          chroma channels for jpeg writing.

=head2 pixWriteJpeg

l_int32 pixWriteJpeg ( const char *filename, PIX *pix, l_int32 quality, l_int32 progressive )

  pixWriteJpeg()

      Input:  filename
              pix
              quality (1 - 100; 75 is default)
              progressive (0 for baseline sequential; 1 for progressive)
      Return: 0 if OK; 1 on error

=head2 pixWriteMemJpeg

l_int32 pixWriteMemJpeg ( l_uint8 **pdata, size_t *psize, PIX *pix, l_int32 quality, l_int32 progressive )

  pixWriteMemJpeg()

      Input:  &data (<return> data of jpeg compressed image)
              &size (<return> size of returned data)
              pix
              quality  (1 - 100; 75 is default value; 0 is also default)
              progressive (0 for baseline sequential; 1 for progressive)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteStreamJpeg() for usage.  This version writes to
          memory instead of to a file stream.

=head2 pixWriteStreamJpeg

l_int32 pixWriteStreamJpeg ( FILE *fp, PIX *pix, l_int32 quality, l_int32 progressive )

  pixWriteStreamJpeg()

      Input:  stream
              pix  (8 or 32 bpp)
              quality  (1 - 100; 75 is default value; 0 is also default)
              progressive (0 for baseline sequential; 1 for progressive)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Under the covers, the library transforms rgb to a
          luminence-chromaticity triple, each component of which is
          also 8 bits, and compresses that.  It uses 2 Huffman tables,
          a higher resolution one (with more quantization levels)
          for luminosity and a lower resolution one for the chromas.
      (2) Progressive encoding gives better compression, at the
          expense of slower encoding and decoding.
      (3) Standard chroma subsampling is 2x2 on both the U and V
          channels.  For highest quality, use no subsampling; this
          option is set by pixSetChromaSampling(pix, 0).
      (4) There are three possibilities:
          * Grayscale image, no colormap: compress as 8 bpp image.
          * rgb full color image: copy each line into the color
            line buffer, and compress as three 8 bpp images.
          * 8 bpp colormapped image: convert each line to three
            8 bpp line images in the color line buffer, and
            compress as three 8 bpp images.
      (5) The only valid pixel depths in leptonica are 1, 2, 4, 8, 16
          and 32 bpp.  However, it is possible, and in some cases desirable,
          to write out a jpeg file using an rgb pix that has 24 bpp.
          This can be created by appending the raster data for a 24 bpp
          image (with proper scanline padding) directly to a 24 bpp
          pix that was created without a data array.  See note in
          pixWriteStreamPng() for an example.

=head2 readHeaderJpeg

l_int32 readHeaderJpeg ( const char *filename, l_int32 *pw, l_int32 *ph, l_int32 *pspp, l_int32 *pycck, l_int32 *pcmyk )

  readHeaderJpeg()

      Input:  filename
              &w (<optional return>)
              &h (<optional return>)
              &spp (<optional return>, samples/pixel)
              &ycck (<optional return>, 1 if ycck color space; 0 otherwise)
              &cmyk (<optional return>, 1 if cmyk color space; 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 readHeaderMemJpeg

l_int32 readHeaderMemJpeg ( const l_uint8 *cdata, size_t size, l_int32 *pw, l_int32 *ph, l_int32 *pspp, l_int32 *pycck, l_int32 *pcmyk )

  readHeaderMemJpeg()

      Input:  cdata (const; jpeg-encoded)
              size (of data)
              &w (<optional return>)
              &h (<optional return>)
              &spp (<optional return>, samples/pixel)
              &ycck (<optional return>, 1 if ycck color space; 0 otherwise)
              &cmyk (<optional return>, 1 if cmyk color space; 0 otherwise)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
