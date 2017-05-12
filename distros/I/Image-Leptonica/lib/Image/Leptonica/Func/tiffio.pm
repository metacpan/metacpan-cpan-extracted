package Image::Leptonica::Func::tiffio;
$Image::Leptonica::Func::tiffio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::tiffio

=head1 VERSION

version 0.04

=head1 C<tiffio.c>

  tiffio.c

     Reading tiff:
             PIX       *pixReadTiff()    [ special top level ]
             PIX       *pixReadStreamTiff()
      static PIX       *pixReadFromTiffStream()

     Writing tiff:
             l_int32    pixWriteTiff()   [ special top level ]
             l_int32    pixWriteTiffCustom()   [ special top level ]
             l_int32    pixWriteStreamTiff()
      static l_int32    pixWriteToTiffStream()
      static l_int32    writeCustomTiffTags()

     Reading and writing multipage tiff
             PIXA       pixaReadMultipageTiff()
             l_int32    writeMultipageTiff()  [ special top level ]
             l_int32    writeMultipageTiffSA()

     Information about tiff file
             l_int32    fprintTiffInfo()
             l_int32    tiffGetCount()
             l_int32    getTiffResolution()
      static l_int32    getTiffStreamResolution()
             l_int32    readHeaderTiff()
             l_int32    freadHeaderTiff()
             l_int32    readHeaderMemTiff()
      static l_int32    tiffReadHeaderTiff()
             l_int32    findTiffCompression()
      static l_int32    getTiffCompressedFormat()

     Extraction of tiff g4 data:
             l_int32    extractG4DataFromFile()

     Open tiff stream from file stream
      static TIFF      *fopenTiff()

     Wrapper for TIFFOpen:
      static TIFF      *openTiff()

     Memory I/O: reading memory --> pix and writing pix --> memory
             [10 static helper functions]
             l_int32    pixReadMemTiff();
             l_int32    pixWriteMemTiff();
             l_int32    pixWriteMemTiffCustom();

   Note:  You should be using version 3.7.4 of libtiff to be certain
          that all the necessary functions are included.

=head1 FUNCTIONS

=head2 extractG4DataFromFile

l_int32 extractG4DataFromFile ( const char *filein, l_uint8 **pdata, size_t *pnbytes, l_int32 *pw, l_int32 *ph, l_int32 *pminisblack )

  extractG4DataFromFile()

      Input:  filein
              &data (<return> binary data of ccitt g4 encoded stream)
              &nbytes (<return> size of binary data)
              &w (<return optional> image width)
              &h (<return optional> image height)
              &minisblack (<return optional> boolean)
      Return: 0 if OK, 1 on error

=head2 findTiffCompression

l_int32 findTiffCompression ( FILE *fp, l_int32 *pcomptype )

  findTiffCompression()

      Input:  stream (must be rewound to BOF)
              &comptype (<return> compression type)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The returned compression type is that defined in
          the enum in imageio.h.  It is not the tiff flag value.
      (2) The compression type is initialized to IFF_UNKNOWN.
          If it is not one of the specified types, the returned
          type is IFF_TIFF, which indicates no compression.
      (3) When this function is called, the stream must be at BOF.
          If the opened stream is to be used again to read the
          file, it must be rewound to BOF after calling this function.

=head2 fprintTiffInfo

l_int32 fprintTiffInfo ( FILE *fpout, const char *tiffile )

  fprintTiffInfo()

      Input:  stream (for output of tag data)
              tiffile (input)
      Return: 0 if OK; 1 on error

=head2 freadHeaderTiff

l_int32 freadHeaderTiff ( FILE *fp, l_int32 n, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *pres, l_int32 *pcmap, l_int32 *pformat )

  freadHeaderTiff()

      Input:  stream
              n (page image number: 0-based)
              &width (<return>)
              &height (<return>)
              &bps (<return> bits per sample -- 1, 2, 4 or 8)
              &spp (<return>; samples per pixel -- 1 or 3)
              &res (<optional return>; resolution in x dir; NULL to ignore)
              &cmap (<optional return>; colormap exists; input NULL to ignore)
              &format (<optional return>; tiff format; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, cmap is returned as 1; else 0.
      (2) If @n is equal to or greater than the number of images, returns 1.

=head2 getTiffResolution

l_int32 getTiffResolution ( FILE *fp, l_int32 *pxres, l_int32 *pyres )

  getTiffResolution()

      Input:  stream (opened for read)
              &xres, &yres (<return> resolution in ppi)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If neither resolution field is set, this is not an error;
          the returned resolution values are 0 (designating 'unknown').

=head2 pixReadMemTiff

PIX * pixReadMemTiff ( const l_uint8 *cdata, size_t size, l_int32 n )

  pixReadMemTiff()

      Input:  data (const; tiff-encoded)
              datasize (size of data)
              n (page image number: 0-based)
      Return: pix, or null on error

  Notes:
      (1) This is a version of pixReadTiff(), where the data is read
          from a memory buffer and uncompressed.
      (2) Use TIFFClose(); TIFFCleanup() doesn't free internal memstream.

=head2 pixReadStreamTiff

PIX * pixReadStreamTiff ( FILE *fp, l_int32 n )

  pixReadStreamTiff()

      Input:  stream
              n (page number: 0 based)
      Return: pix, or null on error (e.g., if the page number is invalid)

=head2 pixReadTiff

PIX * pixReadTiff ( const char *filename, l_int32 n )

  pixReadTiff()

      Input:  filename
              page number (0 based)
      Return: pix, or null on error

  Notes:
      (1) This is a version of pixRead(), specialized for tiff
          files, that allows specification of the page to be returned

=head2 pixWriteMemTiff

l_int32 pixWriteMemTiff ( l_uint8 **pdata, size_t *psize, PIX *pix, l_int32 comptype )

  pixWriteMemTiff()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
              comptype (IFF_TIFF, IFF_TIFF_RLE, IFF_TIFF_PACKBITS,
                        IFF_TIFF_G3, IFF_TIFF_G4,
                        IFF_TIFF_LZW, IFF_TIFF_ZIP)
      Return: 0 if OK, 1 on error

  Usage:
      (1) See pixWriteTiff().  This version writes to
          memory instead of to a file.

=head2 pixWriteMemTiffCustom

l_int32 pixWriteMemTiffCustom ( l_uint8 **pdata, size_t *psize, PIX *pix, l_int32 comptype, NUMA *natags, SARRAY *savals, SARRAY *satypes, NUMA *nasizes )

  pixWriteMemTiffCustom()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
              comptype (IFF_TIFF, IFF_TIFF_RLE, IFF_TIFF_PACKBITS,
                        IFF_TIFF_G3, IFF_TIFF_G4,
                        IFF_TIFF_LZW, IFF_TIFF_ZIP)
              natags (<optional> NUMA of custom tiff tags)
              savals (<optional> SARRAY of values)
              satypes (<optional> SARRAY of types)
              nasizes (<optional> NUMA of sizes)
      Return: 0 if OK, 1 on error

  Usage:
      (1) See pixWriteTiffCustom().  This version writes to
          memory instead of to a file.
      (2) Use TIFFClose(); TIFFCleanup() doesn't free internal memstream.

=head2 pixWriteStreamTiff

l_int32 pixWriteStreamTiff ( FILE *fp, PIX *pix, l_int32 comptype )

  pixWriteStreamTiff()

      Input:  stream (opened for append or write)
              pix
              comptype (IFF_TIFF, IFF_TIFF_RLE, IFF_TIFF_PACKBITS,
                        IFF_TIFF_G3, IFF_TIFF_G4,
                        IFF_TIFF_LZW, IFF_TIFF_ZIP)
      Return: 0 if OK, 1 on error

  Notes:
      (1) For images with bpp > 1, this resets the comptype, if
          necessary, to write uncompressed data.
      (2) G3 and G4 are only defined for 1 bpp.
      (3) We only allow PACKBITS for bpp = 1, because for bpp > 1
          it typically expands images that are not synthetically generated.
      (4) G4 compression is typically about twice as good as G3.
          G4 is excellent for binary compression of text/line-art,
          but terrible for halftones and dithered patterns.  (In
          fact, G4 on halftones can give a file that is larger
          than uncompressed!)  If a binary image has dithered
          regions, it is usually better to compress with png.

=head2 pixWriteTiff

l_int32 pixWriteTiff ( const char *filename, PIX *pix, l_int32 comptype, const char *modestring )

  pixWriteTiff()

      Input:  filename (to write to)
              pix
              comptype (IFF_TIFF, IFF_TIFF_RLE, IFF_TIFF_PACKBITS,
                        IFF_TIFF_G3, IFF_TIFF_G4,
                        IFF_TIFF_LZW, IFF_TIFF_ZIP)
              modestring ("a" or "w")
      Return: 0 if OK, 1 on error

  Notes:
      (1) For multi-page tiff, write the first pix with mode "w" and
          all subsequent pix with mode "a".

=head2 pixWriteTiffCustom

l_int32 pixWriteTiffCustom ( const char *filename, PIX *pix, l_int32 comptype, const char *modestring, NUMA *natags, SARRAY *savals, SARRAY *satypes, NUMA *nasizes )

  pixWriteTiffCustom()

      Input:  filename (to write to)
              pix
              comptype (IFF_TIFF, IFF_TIFF_RLE, IFF_TIFF_PACKBITS,
                        IFF_TIFF_G3, IFF_TIFF_G4)
                        IFF_TIFF_LZW, IFF_TIFF_ZIP)
              modestring ("a" or "w")
              natags (<optional> NUMA of custom tiff tags)
              savals (<optional> SARRAY of values)
              satypes (<optional> SARRAY of types)
              nasizes (<optional> NUMA of sizes)
      Return: 0 if OK, 1 on error

  Usage:
      (1) This writes a page image to a tiff file, with optional
          extra tags defined in tiff.h
      (2) For multi-page tiff, write the first pix with mode "w" and
          all subsequent pix with mode "a".
      (3) For the custom tiff tags:
          (a) The three arrays {natags, savals, satypes} must all be
              either NULL or defined and of equal size.
          (b) If they are defined, the tags are an array of integers,
              the vals are an array of values in string format, and
              the types are an array of types in string format.
          (c) All valid tags are definined in tiff.h.
          (d) The types allowed are the set of strings:
                "char*"
                "l_uint8*"
                "l_uint16"
                "l_uint32"
                "l_int32"
                "l_float64"
                "l_uint16-l_uint16" (note the dash; use it between the
                                    two l_uint16 vals in the val string)
              Of these, "char*" and "l_uint16" are the most commonly used.
          (e) The last array, nasizes, is also optional.  It is for
              tags that take an array of bytes for a value, a number of
              elements in the array, and a type that is either "char*"
              or "l_uint8*" (probably either will work).
              Use NULL if there are no such tags.
          (f) VERY IMPORTANT: if there are any tags that require the
              extra size value, stored in nasizes, they must be
              written first!

=head2 pixaReadMultipageTiff

PIXA * pixaReadMultipageTiff ( const char *filename )

  pixaReadMultipageTiff()

      Input:  filename (input tiff file)
      Return: pixa (of page images), or null on error

=head2 readHeaderMemTiff

l_int32 readHeaderMemTiff ( const l_uint8 *cdata, size_t size, l_int32 n, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *pres, l_int32 *pcmap, l_int32 *pformat )

  readHeaderMemTiff()

      Input:  cdata (const; tiff-encoded)
              size (size of data)
              n (page image number: 0-based)
              &width (<return>)
              &height (<return>)
              &bps (<return> bits per sample -- 1, 2, 4 or 8)
              &spp (<return>; samples per pixel -- 1 or 3)
              &res (<optional return>; resolution in x dir; NULL to ignore)
              &cmap (<optional return>; colormap exists; input NULL to ignore)
              &format (<optional return>; tiff format; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Use TIFFClose(); TIFFCleanup() doesn't free internal memstream.

=head2 readHeaderTiff

l_int32 readHeaderTiff ( const char *filename, l_int32 n, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *pres, l_int32 *pcmap, l_int32 *pformat )

  readHeaderTiff()

      Input:  filename
              n (page image number: 0-based)
              &width (<return>)
              &height (<return>)
              &bps (<return> bits per sample -- 1, 2, 4 or 8)
              &spp (<return>; samples per pixel -- 1 or 3)
              &res (<optional return>; resolution in x dir; NULL to ignore)
              &cmap (<optional return>; colormap exists; input NULL to ignore)
              &format (<optional return>; tiff format; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, cmap is returned as 1; else 0.
      (2) If @n is equal to or greater than the number of images, returns 1.

=head2 tiffGetCount

l_int32 tiffGetCount ( FILE *fp, l_int32 *pn )

  tiffGetCount()

      Input:  stream (opened for read)
              &n (<return> number of images)
      Return: 0 if OK; 1 on error

=head2 writeMultipageTiff

l_int32 writeMultipageTiff ( const char *dirin, const char *substr, const char *fileout )

  writeMultipageTiff()

      Input:  dirin (input directory)
              substr (<optional> substring filter on filenames; can be NULL)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This writes a set of image files in a directory out
          as a multipage tiff file.  The images can be in any
          initial file format.
      (2) Images with a colormap have the colormap removed before
          re-encoding as tiff.
      (3) All images are encoded losslessly.  Those with 1 bpp are
          encoded 'g4'.  The rest are encoded as 'zip' (flate encoding).
          Because it is lossless, this is an expensive method for
          saving most rgb images.

=head2 writeMultipageTiffSA

l_int32 writeMultipageTiffSA ( SARRAY *sa, const char *fileout )

  writeMultipageTiffSA()

      Input:  sarray (of full path names)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See writeMultipageTiff()

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
