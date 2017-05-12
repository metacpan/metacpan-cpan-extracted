package Image::Leptonica::Func::pngio;
$Image::Leptonica::Func::pngio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pngio

=head1 VERSION

version 0.04

=head1 C<pngio.c>

  pngio.c

    Read png from file
          PIX        *pixReadStreamPng()
          l_int32     readHeaderPng()
          l_int32     freadHeaderPng()
          l_int32     sreadHeaderPng()
          l_int32     fgetPngResolution()

    Write png to file
          l_int32     pixWritePng()  [ special top level ]
          l_int32     pixWriteStreamPng()
          l_int32     pixSetZlibCompression()

    Setting flag for special read mode
          void        l_pngSetReadStrip16To8()

    Read/write to memory
          PIX        *pixReadMemPng()
          l_int32     pixWriteMemPng()

    Documentation: libpng.txt and example.c

    On input (decompression from file), palette color images
    are read into an 8 bpp Pix with a colormap, and 24 bpp
    3 component color images are read into a 32 bpp Pix with
    rgb samples.  On output (compression to file), palette color
    images are written as 8 bpp with the colormap, and 32 bpp
    full color images are written compressed as a 24 bpp,
    3 component color image.

    In the following, we use these abbreviations:
       bps == bit/sample
       spp == samples/pixel
       bpp == bits/pixel of image in Pix (memory)
    where each component is referred to as a "sample".

    For reading and writing rgb and rgba images, we read and write
    alpha if it exists (spp == 4) and do not read or write if
    it doesn't (spp == 3).  The alpha component can be 'removed'
    simply by setting spp to 3.  In leptonica, we make relatively
    little explicit use of the alpha sample.  Note that the alpha
    sample in the image is also called "alpha transparency",
    "alpha component" and "alpha layer."

    To change the zlib compression level, use pixSetZlibCompression()
    before writing the file.  The default is for standard png compression.
    The zlib compression value can be set [0 ... 9], with
         0     no compression (huge files)
         1     fastest compression
         -1    default compression  (equivalent to 6 in latest version)
         9     best compression
    Note that if you are using the defined constants in zlib instead
    of the compression integers given above, you must include zlib.h.

    There is global for determining the size of retained samples:
             var_PNG_STRIP_16_to_8
    and a function l_pngSetReadStrip16To8() for setting it.
    The default is TRUE, which causes pixRead() to strip each 16 bit
    sample down to 8 bps:
     - For 16 bps rgb (16 bps, 3 spp) --> 32 bpp rgb Pix
     - For 16 bps gray (16 bps, 1 spp) --> 8 bpp grayscale Pix
    If the variable is set to FALSE, the 16 bit gray samples
    are saved when read; the 16 bit rgb samples return an error.
    Note: results can be non-deterministic if used with
    multi-threaded applications.

    On systems like windows without fmemopen() and open_memstream(),
    we write data to a temp file and read it back for operations
    between pix and compressed-data, such as pixReadMemPng() and
    pixWriteMemPng().

=head1 FUNCTIONS

=head2 fgetPngResolution

l_int32 fgetPngResolution ( FILE *fp, l_int32 *pxres, l_int32 *pyres )

  fgetPngResolution()

      Input:  stream (opened for read)
              &xres, &yres (<return> resolution in ppi)
      Return: 0 if OK; 0 on error

  Notes:
      (1) If neither resolution field is set, this is not an error;
          the returned resolution values are 0 (designating 'unknown').
      (2) Side-effect: this rewinds the stream.

=head2 freadHeaderPng

l_int32 freadHeaderPng ( FILE *fp, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  freadHeaderPng()

      Input:  stream
              &w (<optional return>)
              &h (<optional return>)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
              &iscmap (<optional return>)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See readHeaderPng().

=head2 l_pngSetReadStrip16To8

void l_pngSetReadStrip16To8 ( l_int32 flag )

  l_pngSetReadStrip16To8()

      Input:  flag (1 for stripping 16 bpp to 8 bpp on reading;
                    0 for leaving 16 bpp)
      Return: void

=head2 pixReadMemPng

PIX * pixReadMemPng ( const l_uint8 *cdata, size_t size )

  pixReadMemPng()

      Input:  cdata (const; png-encoded)
              size (of data)
      Return: pix, or null on error

  Notes:
      (1) The @size byte of @data must be a null character.

=head2 pixReadStreamPng

PIX * pixReadStreamPng ( FILE *fp )

  pixReadStreamPng()

      Input:  stream
      Return: pix, or null on error

  Notes:
      (1) If called from pixReadStream(), the stream is positioned
          at the beginning of the file.
      (2) To do sequential reads of png format images from a stream,
          use pixReadStreamPng()
      (3) Grayscale-with-alpha pngs (spp = 2) are converted to RGBA
          on read; the returned pix has spp = 4 and equal red, green and
          blue channels.
      (4) spp = 1 with alpha (palette) is converted to RGBA with spp = 4.
      (5) We use the high level png interface, where the transforms are set
          up in advance and the header and image are read with a single
          call.  The more complicated interface, where the header is
          read first and the buffers for the raster image are user-
          allocated before reading the image, works OK for single images,
          but I could not get it to work properly for the successive
          png reads that are required by pixaReadStream().

=head2 pixSetZlibCompression

l_int32 pixSetZlibCompression ( PIX *pix, l_int32 compval )

  pixSetZlibCompression()

      Input:  pix
              compval (zlib compression value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Valid zlib compression values are in the interval [0 ... 9],
          where, as defined in zlib.h:
            0         Z_NO_COMPRESSION
            1         Z_BEST_SPEED    (poorest compression)
            9         Z_BEST_COMPRESSION
          For the default value, use either of these:
            6         Z_DEFAULT_COMPRESSION
           -1         (resolves to Z_DEFAULT_COMPRESSION)
      (2) If you use the defined constants in zlib.h instead of the
          compression integers given above, you must include zlib.h.

=head2 pixWriteMemPng

l_int32 pixWriteMemPng ( l_uint8 **pdata, size_t *psize, PIX *pix, l_float32 gamma )

  pixWriteMemPng()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
              gamma (use 0.0 if gamma is not defined)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteStreamPng() for usage.  This version writes to
          memory instead of to a file stream.

=head2 pixWritePng

l_int32 pixWritePng ( const char *filename, PIX *pix, l_float32 gamma )

  pixWritePng()

      Input:  filename
              pix
              gamma
      Return: 0 if OK; 1 on error

  Notes:
      (1) Special version for writing png with a specified gamma.
          When using pixWrite(), no field is given for gamma.

=head2 pixWriteStreamPng

l_int32 pixWriteStreamPng ( FILE *fp, PIX *pix, l_float32 gamma )

  pixWriteStreamPng()

      Input:  stream
              pix
              gamma (use 0.0 if gamma is not defined)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If called from pixWriteStream(), the stream is positioned
          at the beginning of the file.
      (2) To do sequential writes of png format images to a stream,
          use pixWriteStreamPng() directly.
      (3) gamma is an optional png chunk.  If no gamma value is to be
          placed into the file, use gamma = 0.0.  Otherwise, if
          gamma > 0.0, its value is written into the header.
      (4) The use of gamma in png is highly problematic.  For an illuminating
          discussion, see:  http://hsivonen.iki.fi/png-gamma/
      (5) What is the effect/meaning of gamma in the png file?  This
          gamma, which we can call the 'source' gamma, is the
          inverse of the gamma that was used in enhance.c to brighten
          or darken images.  The 'source' gamma is supposed to indicate
          the intensity mapping that was done at the time the
          image was captured.  Display programs typically apply a
          'display' gamma of 2.2 to the output, which is intended
          to linearize the intensity based on the response of
          thermionic tubes (CRTs).  Flat panel LCDs have typically
          been designed to give a similar response as CRTs (call it
          "backward compatibility").  The 'display' gamma is
          in some sense the inverse of the 'source' gamma.
          jpeg encoders attached to scanners and cameras will lighten
          the pixels, applying a gamma corresponding to approximately
          a square-root relation of output vs input:
                output = input^(gamma)
          where gamma is often set near 0.4545  (1/gamma is 2.2).
          This is stored in the image file.  Then if the display
          program reads the gamma, it will apply a display gamma,
          typically about 2.2; the product is 1.0, and the
          display program produces a linear output.  This works because
          the dark colors were appropriately boosted by the scanner,
          as described by the 'source' gamma, so they should not
          be further boosted by the display program.
      (6) As an example, with xv and display, if no gamma is stored,
          the program acts as if gamma were 0.4545, multiplies this by 2.2,
          and does a linear rendering.  Taking this as a baseline
          brightness, if the stored gamma is:
              > 0.4545, the image is rendered lighter than baseline
              < 0.4545, the image is rendered darker than baseline
          In contrast, gqview seems to ignore the gamma chunk in png.
      (7) The only valid pixel depths in leptonica are 1, 2, 4, 8, 16
          and 32.  However, it is possible, and in some cases desirable,
          to write out a png file using an rgb pix that has 24 bpp.
          For example, the open source xpdf SplashBitmap class generates
          24 bpp rgb images.  Consequently, we enable writing 24 bpp pix.
          To generate such a pix, you can make a 24 bpp pix without data
          and assign the data array to the pix; e.g.,
              pix = pixCreateHeader(w, h, 24);
              pixSetData(pix, rgbdata);
          See pixConvert32To24() for an example, where we get rgbdata
          from the 32 bpp pix.  Caution: do not call pixSetPadBits(),
          because the alignment is wrong and you may erase part of the
          last pixel on each line.
      (8) If the pix has a colormap, it is written to file.  In most
          situations, the alpha component is 255 for each colormap entry,
          which is opaque and indicates that it should be ignored.
          However, if any alpha component is not 255, it is assumed that
          the alpha values are valid, and they are written to the png
          file in a tRNS segment.  On readback, the tRNS segment is
          identified, and the colormapped image with alpha is converted
          to a 4 spp rgba image.

=head2 readHeaderPng

l_int32 readHeaderPng ( const char *filename, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  readHeaderPng()

      Input:  filename
              &w (<optional return>)
              &h (<optional return>)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
              &iscmap (<optional return>)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, iscmap is returned as 1; else 0.
      (2) For gray+alpha, although the png records bps = 16, we
          consider this as two 8 bpp samples (gray and alpha).
          When a gray+alpha is read, it is converted to 32 bpp RGBA.

=head2 sreadHeaderPng

l_int32 sreadHeaderPng ( const l_uint8 *data, l_int32 *pw, l_int32 *ph, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  sreadHeaderPng()

      Input:  data
              &w (<optional return>)
              &h (<optional return>)
              &bps (<optional return>, bits/sample)
              &spp (<optional return>, samples/pixel)
              &iscmap (<optional return>; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See readHeaderPng().
      (2) png colortypes (see png.h: PNG_COLOR_TYPE_*):
          0:  gray; fully transparent (with tRNS) (1 spp)
          2:  RGB (3 spp)
          3:  colormap; colormap+alpha (with tRNS) (1 spp)
          4:  gray + alpha (2 spp)
          6:  RGBA (4 spp)
          Note:
            0 and 3 have the alpha information in a tRNS chunk
            4 and 6 have separate alpha samples with each pixel.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
