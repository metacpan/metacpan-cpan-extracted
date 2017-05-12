package Image::Leptonica::Func::pdfio;
$Image::Leptonica::Func::pdfio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pdfio

=head1 VERSION

version 0.04

=head1 C<pdfio.c>

  pdfio.c

    |=============================================================|
    |                         Important note                      |
    |=============================================================|
    | Some of these functions require libtiff, libjpeg, and libz  |
    | If you do not have these libraries, you must set            |
    |      #define  USE_PDFIO     0                               |
    | in environ.h.  This will link pdfiostub.c                   |
    |=============================================================|

     Set 1. These functions convert a set of image files
     to a multi-page pdf file, with one image on each page.
     All images are rendered at the same (input) resolution.
     The images can be specified as being in a directory, or they
     can be in an sarray.  The output pdf can be either a file
     or an array of bytes in memory.

     Set 2. These functions are a special case of set 1, where
     no scaling or change in quality is requires.  For jpeg and
     jp2k images, the bytes in each jpeg file can be directly
     incorporated into the output pdf, and the wrapping up of
     multiple image files is very fast.  For other image formats,
     the image must be read and then the G4 or Flate (gzip)
     encodings are generated.

     Set 3. These functions convert a set of images in memory
     to a multi-page pdf, with one image on each page.  The pdf
     output can be either a file or an array of bytes in memory.

     Set 4. These functions implement a pdf output "device driver"
     for wrapping (encoding) any number of images on a single page
     in pdf.  The input can be either an image file or a Pix;
     the pdf output can be either a file or an array of bytes in memory.

     Set 5. These "segmented" functions take a set of image
     files, along with optional segmentation information, and
     generate a multi-page pdf file, where each page consists
     in general of a mixed raster pdf of image and non-image regions.
     The segmentation information for each page can be input as
     either a mask over the image parts, or as a Boxa of those
     regions.

     Set 6. These "segmented" functions convert an image and
     an optional Boxa of image regions into a mixed raster pdf file
     for the page.  The input image can be either a file or a Pix.

     Set 7. These functions take a set of single-page pdf files
     and concatenates them into a multi-page pdf.
     The input can be a set of single page pdf files, or of
     pdf 'strings' in memory.  The output can be either a file or
     an array of bytes in memory.

     The images in the pdf file can be rendered using a pdf viewer,
     such as gv, evince, xpdf or acroread.

     Reference on the pdf file format:
         http://www.adobe.com/devnet/pdf/pdf_reference_archive.html

     1. Convert specified image files to pdf (one image file per page)
          l_int32             convertFilesToPdf()
          l_int32             saConvertFilesToPdf()
          l_int32             saConvertFilesToPdfData()
          l_int32             selectDefaultPdfEncoding()

     2. Convert specified image files to pdf without scaling
          l_int32             convertUnscaledFilesToPdf()
          l_int32             saConvertUnscaledFilesToPdf()
          l_int32             saConvertUnscaledFilesToPdfData()
          l_int32             convertUnscaledToPdfData()
          static L_COMP_DATA *l_generateJp2kData()
          static l_int32      cidConvertToPdfData()

     3. Convert multiple images to pdf (one image per page)
          l_int32             pixaConvertToPdf()
          l_int32             pixaConvertToPdfData()

     4. Single page, multi-image converters
          l_int32             convertToPdf()
          l_int32             convertImageDataToPdf()
          l_int32             convertToPdfData()
          l_int32             convertImageDataToPdfData()
          l_int32             pixConvertToPdf()
          l_int32             pixConvertToPdfData()
          l_int32             pixWriteStreamPdf()

     5. Segmented multi-page, multi-image converter
          l_int32             convertSegmentedFilesToPdf()
          BOXAA              *convertNumberedMasksToBoxaa()

     6. Segmented single page, multi-image converters
          l_int32             convertToPdfSegmented()
          l_int32             pixConvertToPdfSegmented()
          l_int32             convertToPdfDataSegmented()
          l_int32             pixConvertToPdfDataSegmented()

     Helper functions for generating the output pdf string
          static l_int32      l_generatePdf()
          static void         generateFixedStringsPdf()
          static void         generateMediaboxPdf()
          static l_int32      generatePageStringPdf()
          static l_int32      generateContentStringPdf()
          static l_int32      generatePreXStringsPdf()
          static l_int32      generateColormapStringsPdf()
          static void         generateTrailerPdf()
          static l_int32      makeTrailerStringPdf()
          static l_int32      generateOutputDataPdf()

     7. Multi-page concatenation
          l_int32             concatenatePdf()
          l_int32             saConcatenatePdf()
          l_int32             ptraConcatenatePdf()
          l_int32             concatenatePdfToData()
          l_int32             saConcatenatePdfToData()
          l_int32             ptraConcatenatePdfToData()

     Helper functions for generating the multi-page pdf output
          static l_int32      parseTrailerPdf()
          static char        *generatePagesObjStringPdf()
          static L_BYTEA     *substituteObjectNumbers()

     Create/destroy/access pdf data
          static L_PDF_DATA   *pdfdataCreate()
          static void          pdfdataDestroy()
          static L_COMP_DATA  *pdfdataGetCid()

     Set flags for special modes
          void                l_pdfSetG4ImageMask()
          void                l_pdfSetDateAndVersion()

     The top-level multi-image functions can be visualized as follows:
          Output pdf data to file:
             convertToPdf()  and  convertImageDataToPdf()
                     --> pixConvertToPdf()
                           --> pixConvertToPdfData()

          Output pdf data to array in memory:
             convertToPdfData()  and  convertImageDataToPdfData()
                     --> pixConvertToPdfData()

     The top-level segmented image functions can be visualized as follows:
          Output pdf data to file:
             convertToPdfSegmented()
                     --> pixConvertToPdfSegmented()
                           --> pixConvertToPdfDataSegmented()

          Output pdf data to array in memory:
             convertToPdfDataSegmented()
                     --> pixConvertToPdfDataSegmented()

     For multi-page concatenation, there are three different types of input
        (1) directory and optional filename filter
        (2) sarray of filenames
        (3) ptra of byte arrays of pdf data
     and two types of output for the concatenated pdf data
        (1) filename
        (2) data array and size
     High-level interfaces are given for each of the six combinations.

     Note: When wrapping small images into pdf, it is useful to give
     them a relatively low resolution value, to avoid rounding errors
     when rendering the images.  For example, if you want an image
     of width w pixels to be 5 inches wide on a screen, choose a
     resolution w/5.

     The very fast functions in section (2) require neither transcoding
     nor parsing of the compressed jpeg file, because the pdf representation
     of DCT-encoded images simply includes the entire jpeg-encoded data
     as a byte array in the pdf file.  This was a good choice on the part
     of the pdf designers.  They could have chosen to do the same with FLATE
     encoding, by including the png file data as a byte array in the
     pdf, but unfortunately they didn't.  Whereas png compression
     uses a two-dimensional predictor, flate compression simply
     gzips the image data.  So transcoding of png images is reguired;
     to wrap them in flate encoding you must uncompress the image,
     gzip the image data, recompress with gzip and generate a colormap
     object if it exists.  And the resulting one-dimensional compression
     is worse than png.  For CCITT-G4 compression, again, you can not simply
     include a tiff G4 file -- you must either parse it and extract the
     G4 compressed data within it, or uncompress to a raster and
     compress again.

=head1 FUNCTIONS

=head2 concatenatePdf

l_int32 concatenatePdf ( const char *dirname, const char *substr, const char *fileout )

  concatenatePdf()

      Input:  directory name (containing single-page pdf files)
              substr (<optional> substring filter on filenames; can be NULL)
              fileout (concatenated pdf file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.
      (2) If @substr is not NULL, only filenames that contain
          the substring can be returned.  If @substr == NULL,
          none of the filenames are filtered out.
      (3) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order
          before concatenation.

=head2 concatenatePdfToData

l_int32 concatenatePdfToData ( const char *dirname, const char *substr, l_uint8 **pdata, size_t *pnbytes )

  concatenatePdfToData()

      Input:  directory name (containing single-page pdf files)
              substr (<optional> substring filter on filenames; can be NULL)
              &data (<return> concatenated pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.
      (2) If @substr is not NULL, only filenames that contain
          the substring can be returned.  If @substr == NULL,
          none of the filenames are filtered out.
      (3) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order
          before concatenation.

=head2 convertFilesToPdf

l_int32 convertFilesToPdf ( const char *dirname, const char *substr, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, const char *fileout )

  convertFilesToPdf()

      Input:  directory name (containing images)
              substr (<optional> substring filter on filenames; can be NULL)
              res (input resolution of all images)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @substr is not NULL, only image filenames that contain
          the substring can be used.  If @substr == NULL, all files
          in the directory are used.
      (2) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order
          before concatenation.
      (3) The scalefactor is applied to each image before encoding.
          If you enter a value <= 0.0, it will be set to 1.0.
      (4) Specifying one of the three encoding types for @type forces
          all images to be compressed with that type.  Use 0 to have
          the type determined for each image based on depth and whether
          or not it has a colormap.

=head2 convertImageDataToPdf

l_int32 convertImageDataToPdf ( l_uint8 *imdata, size_t size, l_int32 type, l_int32 quality, const char *fileout, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  convertImageDataToPdf()

      Input:  imdata (array of formatted image data; e.g., png, jpeg)
              size (size of image data)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              fileout (output pdf file; only required on last image on page)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed, at which
                    time it is destroyed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @res == 0 and the input resolution field is 0,
          this will use DEFAULT_INPUT_RES.
      (2) See comments in convertToPdf().

=head2 convertImageDataToPdfData

l_int32 convertImageDataToPdfData ( l_uint8 *imdata, size_t size, l_int32 type, l_int32 quality, l_uint8 **pdata, size_t *pnbytes, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  convertImageDataToPdfData()

      Input:  imdata (array of formatted image data; e.g., png, jpeg)
              size (size of image data)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              &data (<return> pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed, at which
                    time it is destroyed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @res == 0 and the input resolution field is 0,
          this will use DEFAULT_INPUT_RES.
      (2) See comments in convertToPdf().

=head2 convertNumberedMasksToBoxaa

BOXAA * convertNumberedMasksToBoxaa ( const char *dirname, const char *substr, l_int32 numpre, l_int32 numpost )

  convertNumberedMasksToBoxaa()

      Input:  directory name (containing mask images)
              substr (<optional> substring filter on filenames; can be NULL)
              numpre (number of characters in name before number)
              numpost (number of characters in name after number, up
                       to a dot before an extension)
                       including an extension and the dot separator)
      Return: boxaa of mask regions, or null on error

  Notes:
      (1) This is conveniently used to generate the input boxaa
          for convertSegmentedFilesToPdf().  It guarantees that the
          boxa will be aligned with the page images, even if some
          of the boxa are empty.

=head2 convertSegmentedFilesToPdf

l_int32 convertSegmentedFilesToPdf ( const char *dirname, const char *substr, l_int32 res, l_int32 type, l_int32 thresh, BOXAA *baa, l_int32 quality, l_float32 scalefactor, const char *title, const char *fileout )

  convertSegmentedFilesToPdf()

      Input:  directory name (containing images)
              substr (<optional> substring filter on filenames; can be NULL)
              res (input resolution of all images)
              type (compression type for non-image regions; the
                    image regions are always compressed with L_JPEG_ENCODE)
              thresh (used for converting gray --> 1 bpp with L_G4_ENCODE)
              boxaa (<optional> of image regions)
              quality (used for JPEG only; 0 for default (75))
              scalefactor (scaling factor applied to each image region)
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @substr is not NULL, only image filenames that contain
          the substring can be used.  If @substr == NULL, all files
          in the directory are used.
      (2) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order
          before concatenation.
      (3) The images are encoded with G4 if 1 bpp; JPEG if 8 bpp without
          colormap and many colors, or 32 bpp; FLATE for anything else.
      (4) The boxaa, if it exists, contains one boxa of "image regions"
          for each image file.  The boxa must be aligned with the
          sorted set of images.
      (5) The scalefactor is applied to each image region.  It is
          typically < 1.0, to save bytes in the final pdf, because
          the resolution is often not critical in non-text regions.
      (6) If the non-image regions have pixel depth > 1 and the encoding
          type is G4, they are automatically scaled up by 2x and
          thresholded.  Otherwise, no scaling is performed on them.
      (7) Note that this function can be used to generate multipage
          G4 compressed pdf from any input, by using @boxaa == NULL
          and @type == L_G4_ENCODE.

=head2 convertToPdf

l_int32 convertToPdf ( const char *filein, l_int32 type, l_int32 quality, const char *fileout, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  convertToPdf()

      Input:  filein (input image file -- any format)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              fileout (output pdf file; only required on last image on page)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title; if null, taken from filein)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed, at which
                    time it is destroyed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) To wrap only one image in pdf, input @plpd = NULL, and
          the value of @position will be ignored:
            convertToPdf(...  type, quality, x, y, res, NULL, 0);
      (2) To wrap multiple images on a single pdf page, this is called
          once for each successive image.  Do it this way:
            L_PDF_DATA   *lpd;
            convertToPdf(...  type, quality, x, y, res, &lpd, L_FIRST_IMAGE);
            convertToPdf(...  type, quality, x, y, res, &lpd, L_NEXT_IMAGE);
            ...
            convertToPdf(...  type, quality, x, y, res, &lpd, L_LAST_IMAGE);
          This will write the result to the value of @fileout specified
          in the first call; succeeding values of @fileout are ignored.
          On the last call: the pdf data bytes are computed and written
          to @fileout, lpd is destroyed internally, and the returned
          value of lpd is null.  So the client has nothing to clean up.
      (3) (a) Set @res == 0 to respect the resolution embedded in the
              image file.  If no resolution is embedded, it will be set
              to the default value.
          (b) Set @res to some other value to override the file resolution.
      (4) (a) If the input @res and the resolution of the output device
              are equal, the image will be "displayed" at the same size
              as the original.
          (b) If the input @res is 72, the output device will render
              the image at 1 pt/pixel.
          (c) Some possible choices for the default input pix resolution are:
                 72 ppi     Render pix on any output device at one pt/pixel
                 96 ppi     Windows default for generated display images
                300 ppi     Typical default for scanned images.
              We choose 300, which is sensible for rendering page images.
              However,  images come from a variety of sources, and
              some are explicitly created for viewing on a display.

=head2 convertToPdfData

l_int32 convertToPdfData ( const char *filein, l_int32 type, l_int32 quality, l_uint8 **pdata, size_t *pnbytes, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  convertToPdfData()

      Input:  filein (input image file -- any format)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              &data (<return> pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title; if null, use filein)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed, at which
                    time it is destroyed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @res == 0 and the input resolution field is 0,
          this will use DEFAULT_INPUT_RES.
      (2) See comments in convertToPdf().

=head2 convertToPdfDataSegmented

l_int32 convertToPdfDataSegmented ( const char *filein, l_int32 res, l_int32 type, l_int32 thresh, BOXA *boxa, l_int32 quality, l_float32 scalefactor, const char *title, l_uint8 **pdata, size_t *pnbytes )

  convertToPdfDataSegmented()

      Input:  filein (input image file -- any format)
              res (input image resolution; typ. 300 ppi; use 0 for default)
              type (compression type for non-image regions; the
                    image regions are always compressed with L_JPEG_ENCODE)
              thresh (used for converting gray --> 1 bpp with L_G4_ENCODE)
              boxa (<optional> image regions; can be null)
              quality (used for jpeg image regions; 0 for default)
              scalefactor (used for jpeg regions; must be <= 1.0)
              title (<optional> pdf title; if null, uses filein)
              &data (<return> pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there are no image regions, set @boxa == NULL;
          @quality and @scalefactor are ignored.
      (2) Typically, @scalefactor is < 1.0.  The image regions are

=head2 convertToPdfSegmented

l_int32 convertToPdfSegmented ( const char *filein, l_int32 res, l_int32 type, l_int32 thresh, BOXA *boxa, l_int32 quality, l_float32 scalefactor, const char *title, const char *fileout )

  convertToPdfSegmented()

      Input:  filein (input image file -- any format)
              res (input image resolution; typ. 300 ppi; use 0 for default)
              type (compression type for non-image regions; the
                    image regions are always compressed with L_JPEG_ENCODE)
              thresh (used for converting gray --> 1 bpp with L_G4_ENCODE)
              boxa (<optional> of image regions; can be null)
              quality (used for jpeg image regions; 0 for default)
              scalefactor (used for jpeg regions; must be <= 1.0)
              title (<optional> pdf title; typically taken from the
                     input file for the pix)
              fileout (output pdf file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there are no image regions, set @boxa == NULL;
          @quality and @scalefactor are ignored.
      (2) Typically, @scalefactor is < 1.0, because the image regions
          can be rendered at a lower resolution (for better compression)
          than the text regions.  If @scalefactor == 0, we use 1.0.
          If the input image is 1 bpp and scalefactor < 1.0, we
          use scaleToGray() to downsample the image regions to gray
          before compressing them.
      (3) If the compression type for non-image regions is L_G4_ENCODE
          and bpp > 1, the image is upscaled 2x and thresholded
          to 1 bpp.  That is the only situation where @thresh is used.
      (4) The parameter @quality is only used for image regions.
          If @type == L_JPEG_ENCODE, default jpeg quality (75) is
          used for the non-image regions.
      (5) Processing matrix for non-image regions.

          Input           G4              JPEG                FLATE
          ----------|---------------------------------------------------
          1 bpp     |  1x, 1 bpp       1x flate, 1 bpp     1x, 1 bpp
                    |
          cmap      |  2x, 1 bpp       1x flate, cmap      1x, cmap
                    |
          2,4 bpp   |  2x, 1 bpp       1x flate            1x, 2,4 bpp
          no cmap   |                  2,4 bpp
                    |
          8,32 bpp  |  2x, 1 bpp       1x (jpeg)           1x, 8,32 bpp
          no cmap   |                  8,32 bpp

          Summary:
          (a) if G4 is requested, G4 is used, with 2x upscaling
              for all cases except 1 bpp.
          (b) if JPEG is requested, use flate encoding for all cases
              except 8 bpp without cmap and 32 bpp (rgb).
          (c) if FLATE is requested, use flate with no transformation
              of the raster data.
      (6) Calling options/sequence for these functions:
              file  -->  file      (convertToPdfSegmented)
                  pix  -->  file      (pixConvertToPdfSegmented)
                      pix  -->  data      (pixConvertToPdfDataSegmented)
              file  -->  data      (convertToPdfDataSegmented)
                      pix  -->  data      (pixConvertToPdfDataSegmented)

=head2 convertUnscaledFilesToPdf

l_int32 convertUnscaledFilesToPdf ( const char *dirname, const char *substr, const char *title, const char *fileout )

  convertUnscaledFilesToPdf()

      Input:  directory name (containing images)
              substr (<optional> substring filter on filenames; can be NULL)
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @substr is not NULL, only image filenames that contain
          the substring can be used.  If @substr == NULL, all files
          in the directory are used.
      (2) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order
          before concatenation.
      (3) For jpeg and jp2k, this is very fast because the compressed
          data is wrapped up and concatenated.  For png and tiffg4,
          the images must be read and recompressed.

=head2 convertUnscaledToPdfData

l_int32 convertUnscaledToPdfData ( const char *fname, const char *title, l_uint8 **pdata, size_t *pnbytes )

  convertUnscaledToPdfData()

      Input:  fname (of image file)
              title (<optional> pdf title; can be NULL)
              &data (<return> output pdf data for image)
              &nbytes (<return> size of output pdf data)
      Return: 0 if OK, 1 on error

=head2 l_pdfSetDateAndVersion

void l_pdfSetDateAndVersion ( l_int32 flag )

  l_pdfSetDateAndVersion()

      Input:  flag (1 for writing date/time and leptonica version;
                    0 for omitting this from the metadata)
      Return: void

  Notes:
      (1) The default is for writing this data.  For regression tests
          that compare output against golden files, it is useful to omit.

=head2 l_pdfSetG4ImageMask

void l_pdfSetG4ImageMask ( l_int32 flag )

  l_pdfSetG4ImageMask()

      Input:  flag (1 for writing g4 data as fg only through a mask;
                    0 for writing fg and bg)
      Return: void

  Notes:
      (1) The default is for writing only the fg (through the mask).
          That way when you write a 1 bpp image, the bg is transparent,
          so any previously written image remains visible behind it.

=head2 pixConvertToPdf

l_int32 pixConvertToPdf ( PIX *pix, l_int32 type, l_int32 quality, const char *fileout, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  pixConvertToPdf()

      Input:  pix
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              fileout (output pdf file; only required on last image on page)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @res == 0 and the input resolution field is 0,
          this will use DEFAULT_INPUT_RES.
      (2) This only writes data to fileout if it is the last
          image to be written on the page.
      (3) See comments in convertToPdf().

=head2 pixConvertToPdfData

l_int32 pixConvertToPdfData ( PIX *pix, l_int32 type, l_int32 quality, l_uint8 **pdata, size_t *pnbytes, l_int32 x, l_int32 y, l_int32 res, const char *title, L_PDF_DATA **plpd, l_int32 position )

  pixConvertToPdfData()

      Input:  pix (all depths; cmap OK)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for JPEG only; 0 for default (75))
              &data (<return> pdf array)
              &nbytes (<return> number of bytes in pdf array)
              x, y (location of lower-left corner of image, in pixels,
                    relative to the PostScript origin (0,0) at
                    the lower-left corner of the page)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title)
              &lpd (ptr to lpd, which is created on the first invocation
                    and returned until last image is processed)
              position (in image sequence: L_FIRST_IMAGE, L_NEXT_IMAGE,
                       L_LAST_IMAGE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If @res == 0 and the input resolution field is 0,
          this will use DEFAULT_INPUT_RES.
      (2) This only writes @data if it is the last image to be
          written on the page.
      (3) See comments in convertToPdf().

=head2 pixConvertToPdfDataSegmented

l_int32 pixConvertToPdfDataSegmented ( PIX *pixs, l_int32 res, l_int32 type, l_int32 thresh, BOXA *boxa, l_int32 quality, l_float32 scalefactor, const char *title, l_uint8 **pdata, size_t *pnbytes )

  pixConvertToPdfDataSegmented()

      Input:  pixs (any depth, cmap OK)
              res (input image resolution; typ. 300 ppi; use 0 for default)
              type (compression type for non-image regions; the
                    image regions are always compressed with L_JPEG_ENCODE)
              thresh (used for converting gray --> 1 bpp with L_G4_ENCODE)
              boxa (<optional> of image regions; can be null)
              quality (used for jpeg image regions; 0 for default)
              scalefactor (used for jpeg regions; must be <= 1.0)
              title (<optional> pdf title; typically taken from the
                     input file for the pix)
              &data (<return> pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertToPdfSegmented() for details.

=head2 pixConvertToPdfSegmented

l_int32 pixConvertToPdfSegmented ( PIX *pixs, l_int32 res, l_int32 type, l_int32 thresh, BOXA *boxa, l_int32 quality, l_float32 scalefactor, const char *title, const char *fileout )

  pixConvertToPdfSegmented()

      Input:  pixs (any depth, cmap OK)
              res (input image resolution; typ. 300 ppi; use 0 for default)
              type (compression type for non-image regions; the
                    image regions are always compressed with L_JPEG_ENCODE)
              thresh (used for converting gray --> 1 bpp with L_G4_ENCODE)
              boxa (<optional> of image regions; can be null)
              quality (used for jpeg image regions; 0 for default)
              scalefactor (used for jpeg regions; must be <= 1.0)
              title (<optional> pdf title; typically taken from the
                     input file for the pix)
              fileout (output pdf file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertToPdfSegmented() for details.

=head2 pixWriteStreamPdf

l_int32 pixWriteStreamPdf ( FILE *fp, PIX *pix, l_int32 res, const char *title )

  pixWriteStreamPdf()

      Input:  fp (stream opened for writing)
              pix (all depths, cmap OK)
              res (override the resolution of the input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              title (<optional> pdf title; taken from the first image
                     placed on a page; e.g., an input image filename)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is the simplest interface for writing a single image
          with pdf encoding.  It uses G4 encoding for 1 bpp,
          JPEG encoding for 8 bpp (no cmap) and 32 bpp, and FLATE
          encoding for everything else.

=head2 pixaConvertToPdf

l_int32 pixaConvertToPdf ( PIXA *pixa, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, const char *fileout )

  pixaConvertToPdf()

      Input:  pixa (containing images all at the same resolution)
              res (override the resolution of each input image, in ppi;
                   use 0 to respect the resolution embedded in the input)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The images are encoded with G4 if 1 bpp; JPEG if 8 bpp without
          colormap and many colors, or 32 bpp; FLATE for anything else.
      (2) The scalefactor must be > 0.0; otherwise it is set to 1.0.
      (3) Specifying one of the three encoding types for @type forces
          all images to be compressed with that type.  Use 0 to have
          the type determined for each image based on depth and whether
          or not it has a colormap.

=head2 pixaConvertToPdfData

l_int32 pixaConvertToPdfData ( PIXA *pixa, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, l_uint8 **pdata, size_t *pnbytes )

  pixaConvertToPdfData()

      Input:  pixa (containing images all at the same resolution)
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
      (1) See pixaConvertToPdf().

=head2 ptraConcatenatePdf

l_int32 ptraConcatenatePdf ( L_PTRA *pa, const char *fileout )

  ptraConcatenatePdf()

      Input:  ptra (array of pdf strings, each for a single-page pdf file)
              fileout (concatenated pdf file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.

=head2 ptraConcatenatePdfToData

l_int32 ptraConcatenatePdfToData ( L_PTRA *pa_data, SARRAY *sa, l_uint8 **pdata, size_t *pnbytes )

  ptraConcatenatePdfToData()

      Input:  ptra (array of pdf strings, each for a single-page pdf file)
              sarray (<optional> of pathnames for input pdf files)
              &data (<return> concatenated pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.
          pdf files generated by other programs will have unpredictable
          (and usually bad) results.  The requirements for each pdf file:
            (a) The Catalog and Info objects are the first two.
            (b) Object 3 is Pages
            (c) Object 4 is Page
            (d) The remaining objects are Contents, XObjects, and ColorSpace
      (2) We remove trailers from each page, and append the full trailer
          for all pages at the end.
      (3) For all but the first file, remove the ID and the first 3
          objects (catalog, info, pages), so that each subsequent
          file has only objects of these classes:
              Page, Contents, XObject, ColorSpace (Indexed RGB).
          For those objects, we substitute these refs to objects
          in the local file:
              Page:  Parent(object 3), Contents, XObject(typically multiple)
              XObject:  [ColorSpace if indexed]
          The Pages object on the first page (object 3) has a Kids array
          of references to all the Page objects, with a Count equal
          to the number of pages.  Each Page object refers back to
          this parent.

=head2 saConcatenatePdf

l_int32 saConcatenatePdf ( SARRAY *sa, const char *fileout )

  saConcatenatePdf()

      Input:  sarray (of pathnames for single-page pdf files)
              fileout (concatenated pdf file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.

=head2 saConcatenatePdfToData

l_int32 saConcatenatePdfToData ( SARRAY *sa, l_uint8 **pdata, size_t *pnbytes )

  saConcatenatePdfToData()

      Input:  sarray (of pathnames for single-page pdf files)
              &data (<return> concatenated pdf data in memory)
              &nbytes (<return> number of bytes in pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only works with leptonica-formatted single-page pdf files.

=head2 saConvertFilesToPdf

l_int32 saConvertFilesToPdf ( SARRAY *sa, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, const char *fileout )

  saConvertFilesToPdf()

      Input:  sarray (of pathnames for images)
              res (input resolution of all images)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertFilesToPdf().

=head2 saConvertFilesToPdfData

l_int32 saConvertFilesToPdfData ( SARRAY *sa, l_int32 res, l_float32 scalefactor, l_int32 type, l_int32 quality, const char *title, l_uint8 **pdata, size_t *pnbytes )

  saConvertFilesToPdfData()

      Input:  sarray (of pathnames for images)
              res (input resolution of all images)
              scalefactor (scaling factor applied to each image; > 0.0)
              type (encoding type (L_JPEG_ENCODE, L_G4_ENCODE,
                    L_FLATE_ENCODE, or 0 for default)
              quality (used for JPEG only; 0 for default (75))
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              &data (<return> output pdf data (of all images)
              &nbytes (<return> size of output pdf data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertFilesToPdf().

=head2 saConvertUnscaledFilesToPdf

l_int32 saConvertUnscaledFilesToPdf ( SARRAY *sa, const char *title, const char *fileout )

  saConvertUnscaledFilesToPdf()

      Input:  sarray (of pathnames for images)
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              fileout (pdf file of all images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertUnscaledFilesToPdf().

=head2 saConvertUnscaledFilesToPdfData

l_int32 saConvertUnscaledFilesToPdfData ( SARRAY *sa, const char *title, l_uint8 **pdata, size_t *pnbytes )

  saConvertUnscaledFilesToPdfData()

      Input:  sarray (of pathnames for images)
              title (<optional> pdf title; if null, taken from the first
                     image filename)
              &data (<return> output pdf data (of all images)
              &nbytes (<return> size of output pdf data)
      Return: 0 if OK, 1 on error

=head2 selectDefaultPdfEncoding

l_int32 selectDefaultPdfEncoding ( PIX *pix, l_int32 *ptype )

  selectDefaultPdfEncoding()

      Input:  pix
              &type (<return> L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)

  Notes:
      (1) This attempts to choose an encoding for the pix that results
          in the smallest file, assuming that if jpeg encoded, it will
          use quality = 75.  The decision is approximate, in that
          (a) all colormapped images will be losslessly encoded with
          gzip (flate), and (b) an image with less than about 20 colors
          is likely to be smaller if flate encoded than if encoded
          as a jpeg (dct).  For example, an image made by pixScaleToGray3()
          will have 10 colors, and flate encoding will give about
          twice the compression as jpeg with quality = 75.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
