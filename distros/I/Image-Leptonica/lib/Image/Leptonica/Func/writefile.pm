package Image::Leptonica::Func::writefile;
$Image::Leptonica::Func::writefile::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::writefile

=head1 VERSION

version 0.04

=head1 C<writefile.c>

 writefile.c

     High-level procedures for writing images to file:
        l_int32     pixaWriteFiles()
        l_int32     pixWrite()    [behavior depends on WRITE_AS_NAMED]
        l_int32     pixWriteStream()
        l_int32     pixWriteImpliedFormat()
        l_int32     pixWriteTempfile()

     Selection of output format if default is requested
        l_int32     pixChooseOutputFormat()
        l_int32     getImpliedFileFormat()
        const char *getFormatExtension()

     Write to memory
        l_int32     pixWriteMem()

     Image display for debugging
        l_int32     pixDisplay()
        l_int32     pixDisplayWithTitle()
        l_int32     pixDisplayMultiple()
        l_int32     pixDisplayWrite()
        l_int32     pixDisplayWriteFormat()
        l_int32     pixSaveTiled()
        l_int32     pixSaveTiledOutline()
        l_int32     pixSaveTiledWithText()
        void        l_chooseDisplayProg()

  Supported file formats:
  (1) Writing is supported without any external libraries:
          bmp
          pnm   (including pbm, pgm, etc)
          spix  (raw serialized)
  (2) Writing is supported with installation of external libraries:
          png
          jpg   (standard jfif version)
          tiff  (including most varieties of compression)
          gif
          webp
  (3) Writing is supported through special interfaces:
          ps (PostScript, in psio1.c, psio2.c):
              level 1 (uncompressed)
              level 2 (g4 and dct encoding: requires tiff, jpg)
              level 3 (g4, dct and flate encoding: requires tiff, jpg, zlib)
          pdf (PDF, in pdfio.c):
              level 1 (g4 and dct encoding: requires tiff, jpg)
              level 2 (g4, dct and flate encoding: requires tiff, jpg, zlib)
  (4) No other output formats are supported, such as jp2 (jpeg2000)

=head1 FUNCTIONS

=head2 getFormatExtension

const char * getFormatExtension ( l_int32 format )

  getFormatExtension()

      Input:  format (integer)
      Return: extension (string), or null if format is out of range

  Notes:
      (1) This string is NOT owned by the caller; it is just a pointer
          to a global string.  Do not free it.

=head2 getImpliedFileFormat

l_int32 getImpliedFileFormat ( const char *filename )

  getImpliedFileFormat()

      Input:  filename
      Return: output format, or IFF_UNKNOWN on error or invalid extension.

  Notes:
      (1) This determines the output file format from the extension
          of the input filename.

=head2 pixChooseOutputFormat

l_int32 pixChooseOutputFormat ( PIX *pix )

  pixChooseOutputFormat()

      Input:  pix
      Return: output format, or 0 on error

  Notes:
      (1) This should only be called if the requested format is IFF_DEFAULT.
      (2) If the pix wasn't read from a file, its input format value
          will be IFF_UNKNOWN, and in that case it is written out
          in a compressed but lossless format.

=head2 pixDisplay

l_int32 pixDisplay ( PIX *pixs, l_int32 x, l_int32 y )

  pixDisplay()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              x, y  (location of display frame on the screen)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This displays the image using xzgv, xli or xv on Unix,
          or i_view on Windows.  The display program must be on
          your $PATH variable.  It is chosen by setting the global
          var_DISPLAY_PROG, using l_chooseDisplayProg().
          Default on Unix is xzgv.
      (2) Images with dimensions larger than MAX_DISPLAY_WIDTH or
          MAX_DISPLAY_HEIGHT are downscaled to fit those constraints.
          This is particulary important for displaying 1 bpp images
          with xv, because xv automatically downscales large images
          by subsampling, which looks poor.  For 1 bpp, we use
          scale-to-gray to get decent-looking anti-aliased images.
          In all cases, we write a temporary file to /tmp, that is
          read by the display program.
      (3) For spp == 4, we call pixDisplayLayersRGBA() to show 3
          versions of the image: the image with a fully opaque
          alpha, the alpha, and the image as it would appear with
          a white background.
      (4) Note: this function uses a static internal variable to number
          output files written by a single process.  Behavior with a
          shared library may be unpredictable.

=head2 pixDisplayMultiple

l_int32 pixDisplayMultiple ( const char *filepattern )

  pixDisplayMultiple()

      Input:  filepattern
      Return: 0 if OK; 1 on error

  Notes:
      (1) This allows display of multiple images using gthumb on unix
          and i_view32 on windows.  The @filepattern is a regular
          expression that is expanded by the shell.
      (2) _fullpath automatically changes '/' to '\' if necessary.

=head2 pixDisplayWithTitle

l_int32 pixDisplayWithTitle ( PIX *pixs, l_int32 x, l_int32 y, const char *title, l_int32 dispflag )

  pixDisplayWithTitle()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              x, y  (location of display frame)
              title (<optional> on frame; can be NULL);
              dispflag (1 to write, else disabled)
      Return: 0 if OK; 1 on error

  Notes:
      (1) See notes for pixDisplay().
      (2) This displays the image if dispflag == 1.

=head2 pixDisplayWrite

l_int32 pixDisplayWrite ( PIX *pixs, l_int32 reduction )

  pixDisplayWrite()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              reduction (-1 to reset/erase; 0 to disable;
                         otherwise this is a reduction factor)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This defaults to jpeg output for pix that are 32 bpp or
          8 bpp without a colormap.  If you want to write all images
          losslessly, use format == IFF_PNG in pixDisplayWriteFormat().
      (2) See pixDisplayWriteFormat() for usage details.

=head2 pixDisplayWriteFormat

l_int32 pixDisplayWriteFormat ( PIX *pixs, l_int32 reduction, l_int32 format )

  pixDisplayWriteFormat()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              reduction (-1 to reset/erase; 0 to disable;
                         otherwise this is a reduction factor)
              format (IFF_PNG or IFF_JFIF_JPEG)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This writes files if reduction > 0.  These can be displayed using
            pixDisplayMultiple("/tmp/display/file*");
      (2) All previously written files can be erased by calling with
          reduction < 0; the value of pixs is ignored.
      (3) If reduction > 1 and depth == 1, this does a scale-to-gray
          reduction.
      (4) This function uses a static internal variable to number
          output files written by a single process.  Behavior
          with a shared library may be unpredictable.
      (5) Output file format is as follows:
            format == IFF_JFIF_JPEG:
                png if d < 8 or d == 16 or if the output pix
                has a colormap.   Otherwise, output is jpg.
            format == IFF_PNG:
                png (lossless) on all images.
      (6) For 16 bpp, the choice of full dynamic range with log scale
          is the best for displaying these images.  Alternative outputs are
             pix8 = pixMaxDynamicRange(pixt, L_LINEAR_SCALE);
             pix8 = pixConvert16To8(pixt, 0);  // low order byte
             pix8 = pixConvert16To8(pixt, 1);  // high order byte

=head2 pixSaveTiled

l_int32 pixSaveTiled ( PIX *pixs, PIXA *pixa, l_float32 scalefactor, l_int32 newrow, l_int32 space, l_int32 dp )

  pixSaveTiled()

      Input:  pixs (1, 2, 4, 8, 32 bpp)
              pixa (the pix are accumulated here)
              scalefactor (0.0 to disable; otherwise this is a scale factor)
              newrow (0 if placed on the same row as previous; 1 otherwise)
              space (horizontal and vertical spacing, in pixels)
              dp (depth of pixa; 8 or 32 bpp; only used on first call)
      Return: 0 if OK, 1 on error.

=head2 pixSaveTiledOutline

l_int32 pixSaveTiledOutline ( PIX *pixs, PIXA *pixa, l_float32 scalefactor, l_int32 newrow, l_int32 space, l_int32 linewidth, l_int32 dp )

  pixSaveTiledOutline()

      Input:  pixs (1, 2, 4, 8, 32 bpp)
              pixa (the pix are accumulated here)
              scalefactor (0.0 to disable; otherwise this is a scale factor)
              newrow (0 if placed on the same row as previous; 1 otherwise)
              space (horizontal and vertical spacing, in pixels)
              linewidth (width of added outline for image; 0 for no outline)
              dp (depth of pixa; 8 or 32 bpp; only used on first call)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) Before calling this function for the first time, use
          pixaCreate() to make the @pixa that will accumulate the pix.
          This is passed in each time pixSaveTiled() is called.
      (2) @scalefactor scales the input image.  After scaling and
          possible depth conversion, the image is saved in the input
          pixa, along with a box that specifies the location to
          place it when tiled later.  Disable saving the pix by
          setting @scalefactor == 0.0.
      (3) @newrow and @space specify the location of the new pix
          with respect to the last one(s) that were entered.
      (4) @dp specifies the depth at which all pix are saved.  It can
          be only 8 or 32 bpp.  Any colormap is removed.  This is only
          used at the first invocation.
      (5) This function uses two variables from call to call.
          If they were static, the function would not be .so or thread
          safe, and furthermore, there would be interference with two or
          more pixa accumulating images at a time.  Consequently,
          we use the first pix in the pixa to store and obtain both
          the depth and the current position of the bottom (one pixel
          below the lowest image raster line when laid out using
          the boxa).  The bottom variable is stored in the input format
          field, which is the only field available for storing an int.

=head2 pixSaveTiledWithText

l_int32 pixSaveTiledWithText ( PIX *pixs, PIXA *pixa, l_int32 outwidth, l_int32 newrow, l_int32 space, l_int32 linewidth, L_BMF *bmf, const char *textstr, l_uint32 val, l_int32 location )

  pixSaveTiledWithText()

      Input:  pixs (1, 2, 4, 8, 32 bpp)
              pixa (the pix are accumulated here; as 32 bpp)
              outwidth (in pixels; use 0 to disable entirely)
              newrow (1 to start a new row; 0 to go on same row as previous)
              space (horizontal and vertical spacing, in pixels)
              linewidth (width of added outline for image; 0 for no outline)
              bmf (<optional> font struct)
              textstr (<optional> text string to be added)
              val (color to set the text)
              location (L_ADD_ABOVE, L_ADD_AT_TOP, L_ADD_AT_BOT, L_ADD_BELOW)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) Before calling this function for the first time, use
          pixaCreate() to make the @pixa that will accumulate the pix.
          This is passed in each time pixSaveTiled() is called.
      (2) @outwidth is the scaled width.  After scaling, the image is
          saved in the input pixa, along with a box that specifies
          the location to place it when tiled later.  Disable saving
          the pix by setting @outwidth == 0.
      (3) @newrow and @space specify the location of the new pix
          with respect to the last one(s) that were entered.
      (4) All pix are saved as 32 bpp RGB.
      (5) If both @bmf and @textstr are defined, this generates a pix
          with the additional text; otherwise, no text is written.
      (6) The text is written before scaling, so it is properly
          antialiased in the scaled pix.  However, if the pix on
          different calls have different widths, the size of the
          text will vary.
      (7) See pixSaveTiledOutline() for other implementation details.

=head2 pixWrite

l_int32 pixWrite ( const char *filename, PIX *pix, l_int32 format )

  pixWrite()

      Input:  filename
              pix
              format  (defined in imageio.h)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Open for write using binary mode (with the "b" flag)
          to avoid having Windows automatically translate the NL
          into CRLF, which corrupts image files.  On non-windows
          systems this flag should be ignored, per ISO C90.
          Thanks to Dave Bryan for pointing this out.
      (2) If the default image format is requested, we use the input format;
          if the input format is unknown, a lossless format is assigned.
      (3) There are two modes with respect to file naming.
          (a) The default code writes to @filename.
          (b) If WRITE_AS_NAMED is defined to 0, it's a bit fancier.
              Then, if @filename does not have a file extension, one is
              automatically appended, depending on the requested format.
          The original intent for providing option (b) was to insure
          that filenames on Windows have an extension that matches
          the image compression.  However, this is not the default.

=head2 pixWriteImpliedFormat

l_int32 pixWriteImpliedFormat ( const char *filename, PIX *pix, l_int32 quality, l_int32 progressive )

  pixWriteImpliedFormat()

      Input:  filename
              pix
              quality (iff JPEG; 1 - 100, 0 for default)
              progressive (iff JPEG; 0 for baseline seq., 1 for progressive)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This determines the output format from the filename extension.
      (2) The last two args are ignored except for requests for jpeg files.
      (3) The jpeg default quality is 75.

=head2 pixWriteMem

l_int32 pixWriteMem ( l_uint8 **pdata, size_t *psize, PIX *pix, l_int32 format )

  pixWriteMem()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
              format  (defined in imageio.h)
      Return: 0 if OK, 1 on error

  Notes:
      (1) On windows, this will only write tiff and PostScript to memory.
          For other formats, it requires open_memstream(3).
      (2) PostScript output is uncompressed, in hex ascii.
          Most printers support level 2 compression (tiff_g4 for 1 bpp,
          jpeg for 8 and 32 bpp).

=head2 pixWriteStream

l_int32 pixWriteStream ( FILE *fp, PIX *pix, l_int32 format )

  pixWriteStream()

      Input:  stream
              pix
              format
      Return: 0 if OK; 1 on error.

=head2 pixaWriteFiles

l_int32 pixaWriteFiles ( const char *rootname, PIXA *pixa, l_int32 format )

  pixaWriteFiles()

      Input:  rootname
              pixa
              format  (defined in imageio.h)
      Return: 0 if OK; 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
