package Image::Leptonica::Func::pixcomp;
$Image::Leptonica::Func::pixcomp::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixcomp

=head1 VERSION

version 0.04

=head1 C<pixcomp.c>

   pixcomp.c

      Pixcomp creation and destruction
           PIXC     *pixcompCreateFromPix()
           PIXC     *pixcompCreateFromString()
           PIXC     *pixcompCreateFromFile()
           void      pixcompDestroy()
      Pixcomp accessors
           l_int32   pixcompGetDimensions()
           l_int32   pixcompDetermineFormat()

      Pixcomp conversion to Pix
           PIX      *pixCreateFromPixcomp()

      Pixacomp creation and destruction
           PIXAC    *pixacompCreate()
           PIXAC    *pixacompCreateWithInit()
           PIXAC    *pixacompCreateFromPixa()
           PIXAC    *pixacompCreateFromFiles()
           PIXAC    *pixacompCreateFromSA()
           void      pixacompDestroy()

      Pixacomp addition/replacement
           l_int32   pixacompAddPix()
           l_int32   pixacompAddPixcomp()
           static l_int32  pixacompExtendArray()
           l_int32   pixacompReplacePix()
           l_int32   pixacompReplacePixcomp()
           l_int32   pixacompAddBox()

      Pixacomp accessors
           l_int32   pixacompGetCount()
           PIXC     *pixacompGetPixcomp()
           PIX      *pixacompGetPix()
           l_int32   pixacompGetPixDimensions()
           BOXA     *pixacompGetBoxa()
           l_int32   pixacompGetBoxaCount()
           BOX      *pixacompGetBox()
           l_int32   pixacompGetBoxGeometry()
           l_int32   pixacompGetOffset()
           l_int32   pixacompSetOffset()

      Pixacomp conversion to Pixa
           PIXA     *pixaCreateFromPixacomp()

      Pixacomp serialized I/O
           PIXAC    *pixacompRead()
           PIXAC    *pixacompReadStream()
           l_int32   pixacompWrite()
           l_int32   pixacompWriteStream()

      Conversion to pdf
           l_int32   pixacompConvertToPdf()
           l_int32   pixacompConvertToPdfData()

      Output for debugging
           l_int32   pixacompWriteStreamInfo()
           l_int32   pixcompWriteStreamInfo()
           PIX      *pixacompDisplayTiledAndScaled()

   The Pixacomp is an array of Pixcomp, where each Pixcomp is a compressed
   string of the image.  We don't use reference counting here.
   The basic application is to allow a large array of highly
   compressible images to reside in memory.  We purposely don't
   reuse the Pixa for this, to avoid confusion and programming errors.

   Three compression formats are used: g4, png and jpeg.
   The compression type can be either specified or defaulted.
   If specified and it is not possible to compress (for example,
   you specify a jpeg on a 1 bpp image or one with a colormap),
   the compression type defaults to png.

   The serialized version of the Pixacomp is similar to that for
   a Pixa, except that each Pixcomp can be compressed by one of
   tiffg4, png, or jpeg.  Unlike serialization of the Pixa,
   serialization of the Pixacomp does not require any imaging
   libraries because it simply reads and writes the compressed data.

   There are two modes of use in accumulating images:
     (1) addition to the end of the array
     (2) random insertion (replacement) into the array

   In use, we assume that the array is fully populated up to the
   index value (n - 1), where n is the value of the pixcomp field n.
   Addition can only be made to the end of the fully populated array,
   at the index value n.  Insertion can be made randomly, but again
   only within the array of pixcomps; i.e., within the set of
   indices {0 .... n-1}.  The functions are pixacompReplacePix()
   and pixacompReplacePixcomp(), and they destroy the existing pixcomp.

   For addition to the end of the array, use pixacompCreate(), which
   generates an initially empty array of pixcomps.  For random
   insertion and replacement of pixcomp into a pixacomp,
   initialize a fully populated array using pixacompCreateWithInit().

   The offset field allows you to use an offset-based index to
   access the 0-based ptr array in the pixacomp.  This would typically
   be used to map the pixacomp array index to a page number, or v.v.
   By default, the offset is 0.  For example, suppose you have 50 images,
   corresponding to page numbers 10 - 59.  Then you would use
      pixac = pixacompCreateWithInit(50, 10, ...);
   This would allocate an array of 50 pixcomps, but if you asked for
   the pix at index 10, using pixacompGetPix(pixac, 10), it would
   apply the offset internally, returning the pix at index 0 in the array.

=head1 FUNCTIONS

=head2 pixCreateFromPixcomp

PIX * pixCreateFromPixcomp ( PIXC *pixc )

  pixCreateFromPixcomp()

      Input:  pixc
      Return: pix, or null on error

=head2 pixaCreateFromPixacomp

PIXA * pixaCreateFromPixacomp ( PIXAC *pixac, l_int32 accesstype )

  pixaCreateFromPixacomp()

      Input:  pixac
              accesstype (L_COPY, L_CLONE, L_COPY_CLONE; for boxa)
      Return: pixa if OK, or null on error

=head2 pixacompAddBox

l_int32 pixacompAddBox ( PIXAC *pixac, BOX *box, l_int32 copyflag )

  pixacompAddBox()

      Input:  pixac
              box
              copyflag (L_INSERT, L_COPY)
      Return: 0 if OK, 1 on error

=head2 pixacompAddPix

l_int32 pixacompAddPix ( PIXAC *pixac, PIX *pix, l_int32 comptype )

  pixacompAddPix()

      Input:  pixac
              pix  (to be added)
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The array is filled up to the (n-1)-th element, and this
          converts the input pix to a pixcomp and adds it at
          the n-th position.

=head2 pixacompAddPixcomp

l_int32 pixacompAddPixcomp ( PIXAC *pixac, PIXC *pixc )

  pixacompAddPixcomp()

      Input:  pixac
              pixc  (to be added by insertion)
      Return: 0 if OK; 1 on error

=head2 pixacompConvertToPdf

l_int32 pixacompConvertToPdf ( PIXAC *pixac, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, const char *fileout )

  pixacompConvertToPdf()

      Input:  pixac (containing images all at the same resolution)
              res (override the resolution of each input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This follows closely the function pixaConvertToPdf() in pdfio.c.
      (2) The images are encoded with G4 if 1 bpp; JPEG if 8 bpp without
          colormap and many colors, or 32 bpp; FLATE for anything else.
      (3) The scalefactor must be > 0.0; otherwise it is set to 1.0.
      (4) Specifying one of the three encoding types for @type forces
          all images to be compressed with that type.  Use 0 to have
          the type determined for each image based on depth and whether
          or not it has a colormap.

=head2 pixacompConvertToPdfData

l_int32 pixacompConvertToPdfData ( PIXAC *pixac, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, l_uint8 **pdata, size_t *pnbytes )

  pixacompConvertToPdfData()

      Input:  pixac (containing images all at the same resolution)
              res (input resolution of all images)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title)
              &data (<return> output pdf data (of all images)
              &nbytes (<return> size of output pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixacompConvertToPdf().

=head2 pixacompCreate

PIXAC * pixacompCreate ( l_int32 n )

  pixacompCreate()

      Input:  n  (initial number of ptrs)
      Return: pixac, or null on error

=head2 pixacompCreateFromFiles

PIXAC * pixacompCreateFromFiles ( const char *dirname, const char *substr, l_int32 comptype )

  pixacompCreateFromFiles()

      Input:  dirname
              substr (<optional> substring filter on filenames; can be null)
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: pixac, or null on error

  Notes:
      (1) @dirname is the full path for the directory.
      (2) @substr is the part of the file name (excluding
          the directory) that is to be matched.  All matching
          filenames are read into the Pixa.  If substr is NULL,
          all filenames are read into the Pixa.
      (3) Use @comptype == IFF_DEFAULT to have the compression
          type automatically determined for each file.
      (4) If the comptype is invalid for a file, the default will
          be substituted.

=head2 pixacompCreateFromPixa

PIXAC * pixacompCreateFromPixa ( PIXA *pixa, l_int32 comptype, l_int32 accesstype )

  pixacompCreateFromPixa()

      Input:  pixa
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
              accesstype (L_COPY, L_CLONE, L_COPY_CLONE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @format == IFF_DEFAULT, the conversion format for each
          image is chosen automatically.  Otherwise, we use the
          specified format unless it can't be done (e.g., jpeg
          for a 1, 2 or 4 bpp pix, or a pix with a colormap),
          in which case we use the default (assumed best) compression.
      (2) @accesstype is used to extract a boxa from @pixa.

=head2 pixacompCreateFromSA

PIXAC * pixacompCreateFromSA ( SARRAY *sa, l_int32 comptype )

  pixacompCreateFromSA()

      Input:  sarray (full pathnames for all files)
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: pixac, or null on error

  Notes:
      (1) Use @comptype == IFF_DEFAULT to have the compression
          type automatically determined for each file.
      (2) If the comptype is invalid for a file, the default will
          be substituted.

=head2 pixacompCreateWithInit

PIXAC * pixacompCreateWithInit ( l_int32 n, l_int32 offset, PIX *pix, l_int32 comptype )

  pixacompCreateWithInit()

      Input:  n  (initial number of ptrs)
              offset (difference: accessor index - pixacomp array index)
              pix (<optional> initialize each ptr in pixacomp to this pix;
                   can be NULL)
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: pixac, or null on error

  Notes:
      (1) Initializes a pixacomp to be fully populated with @pix,
          compressed using @comptype.  If @pix == NULL, @comptype
          is ignored.
      (2) Typically, the array is initialized with a tiny pix.
          This is most easily done by setting @pix == NULL, causing
          initialization of each array element with a tiny placeholder
          pix (w = h = d = 1), using comptype = IFF_TIFF_G4 .
      (3) Example usage:
            // Generate pixacomp for pages 30 - 49.  This has an array
            // size of 20 and the page number offset is 30.
            PixaComp *pixac = pixacompCreateWithInit(20, 30, NULL,
                                                     IFF_TIFF_G4);
            // Now insert png-compressed images into the initialized array
            for (pageno = 30; pageno < 50; pageno++) {
                Pix *pixt = ...   // derived from image[pageno]
                if (pixt)
                    pixacompReplacePix(pixac, pageno, pixt, IFF_PNG);
                pixDestroy(&pixt);
            }
          The result is a pixac with 20 compressed strings, and with
          selected pixt replacing the placeholders.
          To extract the image for page 38, which is decompressed
          from element 8 in the array, use:
            pixt = pixacompGetPix(pixac, 38);

=head2 pixacompDestroy

void pixacompDestroy ( PIXAC **ppixac )

  pixacompDestroy()

      Input:  &pixac (<to be nulled>)
      Return: void

  Notes:
      (1) Always nulls the input ptr.

=head2 pixacompDisplayTiledAndScaled

PIX * pixacompDisplayTiledAndScaled ( PIXAC *pixac, l_int32 outdepth, l_int32 tilewidth, l_int32 ncols, l_int32 background, l_int32 spacing, l_int32 border )

  pixacompDisplayTiledAndScaled()

      Input:  pixac
              outdepth (output depth: 1, 8 or 32 bpp)
              tilewidth (each pix is scaled to this width)
              ncols (number of tiles in each row)
              background (0 for white, 1 for black; this is the color
                 of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of additional black border on each image;
                      use 0 for no border)
      Return: pix of tiled images, or null on error

  Notes:
      (1) This is the same function as pixaDisplayTiledAndScaled(),
          except it works on a Pixacomp instead of a Pix.  It is particularly
          useful for showing the images in a Pixacomp at reduced resolution.
      (2) This can be used to tile a number of renderings of
          an image that are at different scales and depths.
      (3) Each image, after scaling and optionally adding the
          black border, has width 'tilewidth'.  Thus, the border does
          not affect the spacing between the image tiles.  The
          maximum allowed border width is tilewidth / 5.

=head2 pixacompGetBox

BOX * pixacompGetBox ( PIXAC *pixac, l_int32 index, l_int32 accesstype )

  pixacompGetBox()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
              accesstype  (L_COPY or L_CLONE)
      Return: box (if null, not automatically an error), or null on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.
      (2) There is always a boxa with a pixac, and it is initialized so
          that each box ptr is NULL.
      (3) In general, we expect that there is either a box associated
          with each pixc, or no boxes at all in the boxa.
      (4) Having no boxes is thus not an automatic error.  Whether it
          is an actual error is determined by the calling program.
          If the caller expects to get a box, it is an error; see, e.g.,
          pixacGetBoxGeometry().

=head2 pixacompGetBoxGeometry

l_int32 pixacompGetBoxGeometry ( PIXAC *pixac, l_int32 index, l_int32 *px, l_int32 *py, l_int32 *pw, l_int32 *ph )

  pixacompGetBoxGeometry()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
              &x, &y, &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.

=head2 pixacompGetBoxa

BOXA * pixacompGetBoxa ( PIXAC *pixac, l_int32 accesstype )

  pixacompGetBoxa()

      Input:  pixac
              accesstype  (L_COPY, L_CLONE, L_COPY_CLONE)
      Return: boxa, or null on error

=head2 pixacompGetBoxaCount

l_int32 pixacompGetBoxaCount ( PIXAC *pixac )

  pixacompGetBoxaCount()

      Input:  pixac
      Return: count, or 0 on error

=head2 pixacompGetCount

l_int32 pixacompGetCount ( PIXAC *pixac )

  pixacompGetCount()

      Input:  pixac
      Return: count, or 0 if no pixa

=head2 pixacompGetOffset

l_int32 pixacompGetOffset ( PIXAC *pixac )

  pixacompGetOffset()

      Input:  pixac
      Return: offset, or 0 on error

  Notes:
      (1) The offset is the difference between the caller's view of
          the index into the array and the actual array index.
          By default it is 0.

=head2 pixacompGetPix

PIX * pixacompGetPix ( PIXAC *pixac, l_int32 index )

  pixacompGetPix()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
      Return: pix, or null on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.

=head2 pixacompGetPixDimensions

l_int32 pixacompGetPixDimensions ( PIXAC *pixac, l_int32 index, l_int32 *pw, l_int32 *ph, l_int32 *pd )

  pixacompGetPixDimensions()

      Input:  pixa
              index (caller's view of index within pixac; includes offset)
              &w, &h, &d (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.

=head2 pixacompGetPixcomp

PIXC * pixacompGetPixcomp ( PIXAC *pixac, l_int32 index )

  pixacompGetPixcomp()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
      Return: pixc, or null on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.
      (2) Important: this is just a ptr to the pixc owned by the pixac.
          Do not destroy unless you are replacing the pixc.

=head2 pixacompRead

PIXAC * pixacompRead ( const char *filename )

  pixacompRead()

      Input:  filename
      Return: pixac, or null on error

  Notes:
      (1) Unlike the situation with serialized Pixa, where the image
          data is stored in png format, the Pixacomp image data
          can be stored in tiffg4, png and jpg formats.

=head2 pixacompReadStream

PIXAC * pixacompReadStream ( FILE *fp )

  pixacompReadStream()

      Input:  stream
      Return: pixac, or null on error

=head2 pixacompReplacePix

l_int32 pixacompReplacePix ( PIXAC *pixac, l_int32 index, PIX *pix, l_int32 comptype )

  pixacompReplacePix()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
              pix  (owned by the caller)
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.
      (2) The input @pix is converted to a pixc, which is then inserted
          into the pixac.

=head2 pixacompReplacePixcomp

l_int32 pixacompReplacePixcomp ( PIXAC *pixac, l_int32 index, PIXC *pixc )

  pixacompReplacePixcomp()

      Input:  pixac
              index (caller's view of index within pixac; includes offset)
              pixc  (to replace existing one, which is destroyed)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The @index includes the offset, which must be subtracted
          to get the actual index into the ptr array.
      (2) The inserted @pixc is now owned by the pixac.  The caller
          must not destroy it.

=head2 pixacompSetOffset

l_int32 pixacompSetOffset ( PIXAC *pixac, l_int32 offset )

  pixacompSetOffset()

      Input:  pixac
              offset (non-negative)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The offset is the difference between the caller's view of
          the index into the array and the actual array index.
          By default it is 0.

=head2 pixacompWrite

l_int32 pixacompWrite ( const char *filename, PIXAC *pixac )

  pixacompWrite()

      Input:  filename
              pixac
      Return: 0 if OK, 1 on error

  Notes:
      (1) Unlike the situation with serialized Pixa, where the image
          data is stored in png format, the Pixacomp image data
          can be stored in tiffg4, png and jpg formats.

=head2 pixacompWriteStream

l_int32 pixacompWriteStream ( FILE *fp, PIXAC *pixac )

  pixacompWriteStream()

      Input:  stream
              pixac
      Return: 0 if OK, 1 on error

=head2 pixacompWriteStreamInfo

l_int32 pixacompWriteStreamInfo ( FILE *fp, PIXAC *pixac, const char *text )

  pixacompWriteStreamInfo()

      Input:  fp (file stream)
              pixac
              text (<optional> identifying string; can be null)
      Return: 0 if OK, 1 on error

=head2 pixcompCreateFromFile

PIXC * pixcompCreateFromFile ( const char *filename, l_int32 comptype )

  pixcompCreateFromFile()

      Input:  filename
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: pixc, or null on error

  Notes:
      (1) Use @comptype == IFF_DEFAULT to have the compression
          type automatically determined.
      (2) If the comptype is invalid for this file, the default will
          be substituted.

=head2 pixcompCreateFromPix

PIXC * pixcompCreateFromPix ( PIX *pix, l_int32 comptype )

  pixcompCreateFromPix()

      Input:  pix
              comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
      Return: pixc, or null on error

  Notes:
      (1) Use @comptype == IFF_DEFAULT to have the compression
          type automatically determined.

=head2 pixcompCreateFromString

PIXC * pixcompCreateFromString ( l_uint8 *data, size_t size, l_int32 copyflag )

  pixcompCreateFromString()

      Input:  data (compressed string)
              size (number of bytes)
              copyflag (L_INSERT or L_COPY)
      Return: pixc, or null on error

  Notes:
      (1) This works when the compressed string is png, jpeg or tiffg4.
      (2) The copyflag determines if the data in the new Pixcomp is
          a copy of the input data.

=head2 pixcompDestroy

void pixcompDestroy ( PIXC **ppixc )

  pixcompDestroy()

      Input:  &pixc <will be nulled>
      Return: void

  Notes:
      (1) Always nulls the input ptr.

=head2 pixcompDetermineFormat

l_int32 pixcompDetermineFormat ( l_int32 comptype, l_int32 d, l_int32 cmapflag, l_int32 *pformat )

  pixcompDetermineFormat()

      Input:  comptype (IFF_DEFAULT, IFF_TIFF_G4, IFF_PNG, IFF_JFIF_JPEG)
              d (pix depth)
              cmapflag (1 if pix to be compressed as a colormap; 0 otherwise)
              &format (return IFF_TIFF, IFF_PNG or IFF_JFIF_JPEG)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This determines the best format for a pix, given both
          the request (@comptype) and the image characteristics.
      (2) If @comptype == IFF_DEFAULT, this does not necessarily result
          in png encoding.  Instead, it returns one of the three formats
          that is both valid and most likely to give best compression.
      (3) If the pix cannot be compressed by the input value of
          @comptype, this selects IFF_PNG, which can compress all pix.

=head2 pixcompGetDimensions

l_int32 pixcompGetDimensions ( PIXC *pixc, l_int32 *pw, l_int32 *ph, l_int32 *pd )

  pixcompGetDimensions()

      Input:  pixc
              &w, &h, &d (<optional return>)
      Return: 0 if OK, 1 on error

=head2 pixcompWriteStreamInfo

l_int32 pixcompWriteStreamInfo ( FILE *fp, PIXC *pixc, const char *text )

  pixcompWriteStreamInfo()

      Input:  fp (file stream)
              pixc
              text (<optional> identifying string; can be null)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
