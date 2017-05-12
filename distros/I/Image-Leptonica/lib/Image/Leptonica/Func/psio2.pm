package Image::Leptonica::Func::psio2;
$Image::Leptonica::Func::psio2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::psio2

=head1 VERSION

version 0.04

=head1 C<psio2.c>

  psio2.c

    |=============================================================|
    |                         Important note                      |
    |=============================================================|
    | Some of these functions require libtiff, libjpeg and libz.  |
    | If you do not have these libraries, you must set            |
    |     #define  USE_PSIO     0                                 |
    | in environ.h.  This will link psio2stub.c                   |
    |=============================================================|

     These are lower-level functions that implement a PostScript
     "device driver" for wrapping images in PostScript.  The images
     can be rendered by a PostScript interpreter for viewing,
     using evince or gv.  They can also be rasterized for printing,
     using gs or an embedded interpreter in a PostScript printer.
     And they can be converted to a pdf using gs (ps2pdf).

     For uncompressed images
          l_int32              pixWritePSEmbed()
          l_int32              pixWriteStreamPS()
          char                *pixWriteStringPS()
          char                *generateUncompressedPS()
          void                 getScaledParametersPS()
          l_int32              convertByteToHexAscii()

     For jpeg compressed images (use dct compression)
          l_int32              convertJpegToPSEmbed()
          l_int32              convertJpegToPS()
          l_int32              convertJpegToPSString()
          char                *generateJpegPS()
          L_COMP_DATA         *pixGenerateJpegData()
          L_COMP_DATA         *l_generateJpegData()
          void                 l_compdataDestroy()

     For g4 fax compressed images (use ccitt g4 compression)
          l_int32              convertG4ToPSEmbed()
          l_int32              convertG4ToPS()
          l_int32              convertG4ToPSString()
          char                *generateG4PS()
          L_COMP_DATA         *pixGenerateG4Data()
          L_COMP_DATA         *l_generateG4Data()

     For multipage tiff images
          l_int32              convertTiffMultipageToPS()

     For flate (gzip) compressed images (e.g., png)
          l_int32              convertFlateToPSEmbed()
          l_int32              convertFlateToPS()
          l_int32              convertFlateToPSString()
          char                *generateFlatePS()
          L_COMP_DATA         *l_generateFlateData()
          L_COMP_DATA         *pixGenerateFlateData()

     For compressed images in general
          l_int32              l_generateCIData()
          l_int32              pixGenerateCIData()

     Write to memory
          l_int32              pixWriteMemPS()

     Converting resolution
          l_int32              getResLetterPage()
          l_int32              getResA4Page()

     Utility for encoding and decoding data with ascii85
          char                *encodeAscii85()
          static l_int32      *convertChunkToAscii85()
          l_uint8             *decodeAscii85()

     Setting flag for writing bounding box hint
          void                 l_psWriteBoundingBox()

  See psio1.c for higher-level functions and their usage.

=head1 FUNCTIONS

=head2 convertByteToHexAscii

void convertByteToHexAscii ( l_uint8 byteval, char *pnib1, char *pnib2 )

  convertByteToHexAscii()

      Input:  byteval  (input byte)
              &nib1, &nib2  (<return> two hex ascii characters)
      Return: void

=head2 convertFlateToPS

l_int32 convertFlateToPS ( const char *filein, const char *fileout, const char *operation, l_int32 x, l_int32 y, l_int32 res, l_float32 scale, l_int32 pageno, l_int32 endpage )

  convertFlateToPS()

      Input:  filein (input file -- any format)
              fileout (output ps file)
              operation ("w" for write; "a" for append)
              x, y (location of LL corner of image, in pixels, relative
                    to the PostScript origin (0,0) at the LL corner
                    of the page)
              res (resolution of the input image, in ppi; use 0 for default)
              scale (scaling by printer; use 0.0 or 1.0 for no scaling)
              pageno (page number; must start with 1; you can use 0
                      if there is only one page.)
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This outputs level 3 PS as flate compressed (overlaid
          with ascii85 encoding).
      (2) An output file can contain multiple pages, each with
          multiple images.  The arguments to convertFlateToPS()
          allow you to control placement of png images on multiple
          pages within a PostScript file.
      (3) For the first image written to a file, use "w", which
          opens for write and clears the file.  For all subsequent
          images written to that file, use "a".
      (4) The (x, y) parameters give the LL corner of the image
          relative to the LL corner of the page.  They are in
          units of pixels if scale = 1.0.  If you use (e.g.)
          scale = 2.0, the image is placed at (2x, 2y) on the page,
          and the image dimensions are also doubled.
      (5) Display vs printed resolution:
           * If your display is 75 ppi and your image was created
             at a resolution of 300 ppi, you can get the image
             to print at the same size as it appears on your display
             by either setting scale = 4.0 or by setting  res = 75.
             Both tell the printer to make a 4x enlarged image.
           * If your image is generated at 150 ppi and you use scale = 1,
             it will be rendered such that 150 pixels correspond
             to 72 pts (1 inch on the printer).  This function does
             the conversion from pixels (with or without scaling) to
             pts, which are the units that the printer uses.
           * The printer will choose its own resolution to use
             in rendering the image, which will not affect the size
             of the rendered image.  That is because the output
             PostScript file describes the geometry in terms of pts,
             which are defined to be 1/72 inch.  The printer will
             only see the size of the image in pts, through the
             scale and translate parameters and the affine
             transform (the ImageMatrix) of the image.
      (6) To render multiple images on the same page, set
          endpage = FALSE for each image until you get to the
          last, for which you set endpage = TRUE.  This causes the
          "showpage" command to be invoked.  Showpage outputs
          the entire page and clears the raster buffer for the
          next page to be added.  Without a "showpage",
          subsequent images from the next page will overlay those
          previously put down.
      (7) For multiple pages, increment the page number, starting
          with page 1.  This allows PostScript (and PDF) to build
          a page directory, which viewers use for navigation.

=head2 convertFlateToPSEmbed

l_int32 convertFlateToPSEmbed ( const char *filein, const char *fileout )

  convertFlateToPSEmbed()

      Input:  filein (input file -- any format)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function takes any image file as input and generates a
          flate-compressed, ascii85 encoded PS file, with a bounding box.
      (2) The bounding box is required when a program such as TeX
          (through epsf) places and rescales the image.
      (3) The bounding box is sized for fitting the image to an
          8.5 x 11.0 inch page.

=head2 convertG4ToPS

l_int32 convertG4ToPS ( const char *filein, const char *fileout, const char *operation, l_int32 x, l_int32 y, l_int32 res, l_float32 scale, l_int32 pageno, l_int32 maskflag, l_int32 endpage )

  convertG4ToPS()

      Input:  filein (input tiff g4 file)
              fileout (output ps file)
              operation ("w" for write; "a" for append)
              x, y (location of LL corner of image, in pixels, relative
                    to the PostScript origin (0,0) at the LL corner
                    of the page)
              res (resolution of the input image, in ppi; typ. values
                   are 300 and 600; use 0 for automatic determination
                   based on image size)
              scale (scaling by printer; use 0.0 or 1.0 for no scaling)
              pageno (page number; must start with 1; you can use 0
                      if there is only one page.)
              maskflag (boolean: use TRUE if just painting through fg;
                        FALSE if painting both fg and bg.
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See the usage comments in convertJpegToPS(), some of
          which are repeated here.
      (2) This is a wrapper for tiff g4.  The PostScript that
          is generated is expanded by about 5/4 (due to the
          ascii85 encoding.  If you convert to pdf (ps2pdf), the
          ascii85 decoder is automatically invoked, so that the
          pdf wrapped g4 file is essentially the same size as
          the original g4 file.  It's useful to have the PS
          file ascii85 encoded, because many printers will not
          print binary PS files.
      (3) For the first image written to a file, use "w", which
          opens for write and clears the file.  For all subsequent
          images written to that file, use "a".
      (4) To render multiple images on the same page, set
          endpage = FALSE for each image until you get to the
          last, for which you set endpage = TRUE.  This causes the
          "showpage" command to be invoked.  Showpage outputs
          the entire page and clears the raster buffer for the
          next page to be added.  Without a "showpage",
          subsequent images from the next page will overlay those
          previously put down.
      (5) For multiple images to the same page, where you are writing
          both jpeg and tiff-g4, you have two options:
           (a) write the g4 first, as either image (maskflag == FALSE)
               or imagemask (maskflag == TRUE), and then write the
               jpeg over it.
           (b) write the jpeg first and as the last item, write
               the g4 as an imagemask (maskflag == TRUE), to paint
               through the foreground only.
          We have this flexibility with the tiff-g4 because it is 1 bpp.
      (6) For multiple pages, increment the page number, starting
          with page 1.  This allows PostScript (and PDF) to build
          a page directory, which viewers use for navigation.

=head2 convertG4ToPSEmbed

l_int32 convertG4ToPSEmbed ( const char *filein, const char *fileout )

  convertG4ToPSEmbed()

      Input:  filein (input tiff file)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function takes a g4 compressed tif file as input and
          generates a g4 compressed, ascii85 encoded PS file, with
          a bounding box.
      (2) The bounding box is required when a program such as TeX
          (through epsf) places and rescales the image.
      (3) The bounding box is sized for fitting the image to an
          8.5 x 11.0 inch page.
      (4) We paint this through a mask, over whatever is below.

=head2 convertJpegToPS

l_int32 convertJpegToPS ( const char *filein, const char *fileout, const char *operation, l_int32 x, l_int32 y, l_int32 res, l_float32 scale, l_int32 pageno, l_int32 endpage )

  convertJpegToPS()

      Input:  filein (input jpeg file)
              fileout (output ps file)
              operation ("w" for write; "a" for append)
              x, y (location of LL corner of image, in pixels, relative
                    to the PostScript origin (0,0) at the LL corner
                    of the page)
              res (resolution of the input image, in ppi; use 0 for default)
              scale (scaling by printer; use 0.0 or 1.0 for no scaling)
              pageno (page number; must start with 1; you can use 0
                      if there is only one page)
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is simpler to use than pixWriteStringPS(), and
          it outputs in level 2 PS as compressed DCT (overlaid
          with ascii85 encoding).
      (2) An output file can contain multiple pages, each with
          multiple images.  The arguments to convertJpegToPS()
          allow you to control placement of jpeg images on multiple
          pages within a PostScript file.
      (3) For the first image written to a file, use "w", which
          opens for write and clears the file.  For all subsequent
          images written to that file, use "a".
      (4) The (x, y) parameters give the LL corner of the image
          relative to the LL corner of the page.  They are in
          units of pixels if scale = 1.0.  If you use (e.g.)
          scale = 2.0, the image is placed at (2x, 2y) on the page,
          and the image dimensions are also doubled.
      (5) Display vs printed resolution:
           * If your display is 75 ppi and your image was created
             at a resolution of 300 ppi, you can get the image
             to print at the same size as it appears on your display
             by either setting scale = 4.0 or by setting  res = 75.
             Both tell the printer to make a 4x enlarged image.
           * If your image is generated at 150 ppi and you use scale = 1,
             it will be rendered such that 150 pixels correspond
             to 72 pts (1 inch on the printer).  This function does
             the conversion from pixels (with or without scaling) to
             pts, which are the units that the printer uses.
           * The printer will choose its own resolution to use
             in rendering the image, which will not affect the size
             of the rendered image.  That is because the output
             PostScript file describes the geometry in terms of pts,
             which are defined to be 1/72 inch.  The printer will
             only see the size of the image in pts, through the
             scale and translate parameters and the affine
             transform (the ImageMatrix) of the image.
      (6) To render multiple images on the same page, set
          endpage = FALSE for each image until you get to the
          last, for which you set endpage = TRUE.  This causes the
          "showpage" command to be invoked.  Showpage outputs
          the entire page and clears the raster buffer for the
          next page to be added.  Without a "showpage",
          subsequent images from the next page will overlay those
          previously put down.
      (7) For multiple pages, increment the page number, starting
          with page 1.  This allows PostScript (and PDF) to build
          a page directory, which viewers use for navigation.

=head2 convertJpegToPSEmbed

l_int32 convertJpegToPSEmbed ( const char *filein, const char *fileout )

  convertJpegToPSEmbed()

      Input:  filein (input jpeg file)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function takes a jpeg file as input and generates a DCT
          compressed, ascii85 encoded PS file, with a bounding box.
      (2) The bounding box is required when a program such as TeX
          (through epsf) places and rescales the image.
      (3) The bounding box is sized for fitting the image to an
          8.5 x 11.0 inch page.

=head2 convertTiffMultipageToPS

l_int32 convertTiffMultipageToPS ( const char *filein, const char *fileout, const char *tempfile, l_float32 fillfract )

  convertTiffMultipageToPS()

      Input:  filein (input tiff multipage file)
              fileout (output ps file)
              tempfile (<optional> for temporary g4 tiffs;
                        use NULL for default)
              factor (for filling 8.5 x 11 inch page;
                      use 0.0 for DEFAULT_FILL_FRACTION)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This converts a multipage tiff file of binary page images
          into a ccitt g4 compressed PS file.
      (2) If the images are generated from a standard resolution fax,
          the vertical resolution is doubled to give a normal-looking
          aspect ratio.

=head2 decodeAscii85

l_uint8 * decodeAscii85 ( char *ina, l_int32 insize, l_int32 *poutsize )

  decodeAscii85()

      Input:  inarray (ascii85 input data)
              insize (number of bytes in input array)
              &outsize (<return> number of bytes in output l_uint8 array)
      Return: outarray (binary)

  Notes:
      (1) We assume the data is properly encoded, so we do not check
          for invalid characters or the final '>' character.
      (2) We permit whitespace to be added to the encoding in an
          arbitrary way.

=head2 encodeAscii85

char * encodeAscii85 ( l_uint8 *inarray, l_int32 insize, l_int32 *poutsize )

  encodeAscii85()

      Input:  inarray (input data)
              insize (number of bytes in input array)
              &outsize (<return> number of bytes in output char array)
      Return: chara (with 64 characters + \n in each line)

  Notes:
      (1) Ghostscript has a stack break if the last line of
          data only has a '>', so we avoid the problem by
          always putting '~>' on the last line.

=head2 generateFlatePS

char * generateFlatePS ( const char *filein, L_COMP_DATA *cid, l_float32 xpt, l_float32 ypt, l_float32 wpt, l_float32 hpt, l_int32 pageno, l_int32 endpage )

  generateFlatePS()

      Input:  filein (<optional> input filename; can be null)
              cid (flate compressed image data)
              xpt, ypt (location of LL corner of image, in pts, relative
                        to the PostScript origin (0,0) at the LL corner
                        of the page)
              wpt, hpt (rendered image size in pts)
              pageno (page number; must start with 1; you can use 0
                      if there is only one page)
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: PS string, or null on error

=head2 generateG4PS

char * generateG4PS ( const char *filein, L_COMP_DATA *cid, l_float32 xpt, l_float32 ypt, l_float32 wpt, l_float32 hpt, l_int32 maskflag, l_int32 pageno, l_int32 endpage )

  generateG4PS()

      Input:  filein (<optional> input tiff g4 file; can be null)
              cid (g4 compressed image data)
              xpt, ypt (location of LL corner of image, in pts, relative
                        to the PostScript origin (0,0) at the LL corner
                        of the page)
              wpt, hpt (rendered image size in pts)
              maskflag (boolean: use TRUE if just painting through fg;
                        FALSE if painting both fg and bg.
              pageno (page number; must start with 1; you can use 0
                      if there is only one page.)
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: PS string, or null on error

  Notes:
      (1) Low-level function.

=head2 generateJpegPS

char * generateJpegPS ( const char *filein, L_COMP_DATA *cid, l_float32 xpt, l_float32 ypt, l_float32 wpt, l_float32 hpt, l_int32 pageno, l_int32 endpage )

  generateJpegPS()

      Input:  filein (<optional> input jpeg filename; can be null)
              cid (jpeg compressed image data)
              xpt, ypt (location of LL corner of image, in pts, relative
                        to the PostScript origin (0,0) at the LL corner
                        of the page)
              wpt, hpt (rendered image size in pts)
              pageno (page number; must start with 1; you can use 0
                      if there is only one page.)
              endpage (boolean: use TRUE if this is the last image to be
                       added to the page; FALSE otherwise)
      Return: PS string, or null on error

  Notes:
      (1) Low-level function.

=head2 generateUncompressedPS

char * generateUncompressedPS ( char *hexdata, l_int32 w, l_int32 h, l_int32 d, l_int32 psbpl, l_int32 bps, l_float32 xpt, l_float32 ypt, l_float32 wpt, l_float32 hpt, l_int32 boxflag )

  generateUncompressedPS()

      Input:  hexdata
              w, h  (raster image size in pixels)
              d (image depth in bpp; rgb is 32)
              psbpl (raster bytes/line, when packed to the byte boundary)
              bps (bits/sample: either 1 or 8)
              xpt, ypt (location of LL corner of image, in pts, relative
                    to the PostScript origin (0,0) at the LL corner
                    of the page)
              wpt, hpt (rendered image size in pts)
              boxflag (1 to print out bounding box hint; 0 to skip)
      Return: PS string, or null on error

  Notes:
      (1) Low-level function.

=head2 getResA4Page

l_int32 getResA4Page ( l_int32 w, l_int32 h, l_float32 fillfract )

  getResA4Page()

      Input:  w (image width, pixels)
              h (image height, pixels)
              fillfract (fraction in linear dimension of full page, not
                        to be exceeded; use 0 for default)
      Return: 0 if OK, 1 on error

=head2 getResLetterPage

l_int32 getResLetterPage ( l_int32 w, l_int32 h, l_float32 fillfract )

  getResLetterPage()

      Input:  w (image width, pixels)
              h (image height, pixels)
              fillfract (fraction in linear dimension of full page, not
                         to be exceeded; use 0 for default)
      Return: 0 if OK, 1 on error

=head2 getScaledParametersPS

void getScaledParametersPS ( BOX *box, l_int32 wpix, l_int32 hpix, l_int32 res, l_float32 scale, l_float32 *pxpt, l_float32 *pypt, l_float32 *pwpt, l_float32 *phpt )

  getScaledParametersPS()

      Input:  box (<optional> location of image in mils; with
                   (x,y) being the LL corner)
              wpix (pix width in pixels)
              hpix (pix height in pixels)
              res (of printer; use 0 for default)
              scale (use 1.0 or 0.0 for no scaling)
              &xpt (location of llx in pts)
              &ypt (location of lly in pts)
              &wpt (image width in pts)
              &hpt (image height in pts)
      Return: void (no arg checking)

  Notes:
      (1) The image is always scaled, depending on res and scale.
      (2) If no box, the image is centered on the page.
      (3) If there is a box, the image is placed within it.

=head2 l_compdataDestroy

void l_compdataDestroy ( L_COMP_DATA **pcid )

  l_compdataDestroy()

      Input:  &cid (<will be set to null before returning>)
      Return: void

=head2 l_generateCIData

l_int32 l_generateCIData ( const char *fname, l_int32 type, l_int32 quality, l_int32 ascii85, L_COMP_DATA **pcid )

  l_generateCIData()

      Input:  fname
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for jpeg only; 0 for default (75))
              ascii85 (0 for binary; 1 for ascii85-encoded)
              &cid (<return> compressed data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Set ascii85:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data

=head2 l_generateFlateData

L_COMP_DATA * l_generateFlateData ( const char *fname, l_int32 ascii85flag )

  l_generateFlateData()

      Input:  fname
              ascii85flag (0 for gzipped; 1 for ascii85-encoded gzipped)
      Return: cid (flate compressed image data), or null on error

  Notes:
      (1) The input image is converted to one of these 4 types:
           - 1 bpp
           - 8 bpp, no colormap
           - 8 bpp, colormap
           - 32 bpp rgb
      (2) Set ascii85flag:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data

=head2 l_generateG4Data

L_COMP_DATA * l_generateG4Data ( const char *fname, l_int32 ascii85flag )

  l_generateG4Data()

      Input:  fname (of g4 compressed file)
              ascii85flag (0 for g4 compressed; 1 for ascii85-encoded g4)
      Return: cid (g4 compressed image data), or null on error

  Notes:
      (1) Set ascii85flag:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data
             (not permitted in pdf)

=head2 l_generateJpegData

L_COMP_DATA * l_generateJpegData ( const char *fname, l_int32 ascii85flag )

  l_generateJpegData()

      Input:  fname (of jpeg file)
              ascii85flag (0 for jpeg; 1 for ascii85-encoded jpeg)
      Return: cid (containing jpeg data), or null on error

  Notes:
      (1) Set ascii85flag:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data
               (not permitted in pdf)

=head2 pixGenerateCIData

l_int32 pixGenerateCIData ( PIX *pixs, l_int32 type, l_int32 quality, l_int32 ascii85, L_COMP_DATA **pcid )

  pixGenerateCIData()

      Input:  pixs (8 or 32 bpp, no colormap)
              type (L_G4_ENCODE, L_JPEG_ENCODE, L_FLATE_ENCODE)
              quality (used for jpeg only; 0 for default (75))
              ascii85 (0 for binary; 1 for ascii85-encoded)
              &cid (<return> compressed data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Set ascii85:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data

=head2 pixGenerateFlateData

L_COMP_DATA * pixGenerateFlateData ( PIX *pixs, l_int32 ascii85flag )

  pixGenerateFlateData()

      Input:  pixs
              ascii85flag (0 for gzipped; 1 for ascii85-encoded gzipped)
      Return: cid (flate compressed image data), or null on error

=head2 pixGenerateG4Data

L_COMP_DATA * pixGenerateG4Data ( PIX *pixs, l_int32 ascii85flag )

  pixGenerateG4Data()

      Input:  pixs (1 bpp)
              ascii85flag (0 for gzipped; 1 for ascii85-encoded gzipped)
      Return: cid (g4 compressed image data), or null on error

  Notes:
      (1) Set ascii85flag:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data

=head2 pixGenerateJpegData

L_COMP_DATA * pixGenerateJpegData ( PIX *pixs, l_int32 ascii85flag, l_int32 quality )

  pixGenerateJpegData()

      Input:  pixs (8 or 32 bpp, no colormap)
              ascii85flag (0 for jpeg; 1 for ascii85-encoded jpeg)
              quality (0 for default, which is 75)
      Return: cid (jpeg compressed data), or null on error

  Notes:
      (1) Set ascii85flag:
           - 0 for binary data (not permitted in PostScript)
           - 1 for ascii85 (5 for 4) encoded binary data

=head2 pixWriteMemPS

l_int32 pixWriteMemPS ( l_uint8 **pdata, size_t *psize, PIX *pix, BOX *box, l_int32 res, l_float32 scale )

  pixWriteMemPS()

      Input:  &data (<return> data of tiff compressed image)
              &size (<return> size of returned data)
              pix
              box  (<optional>)
              res  (can use 0 for default of 300 ppi)
              scale (to prevent scaling, use either 1.0 or 0.0)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixWriteStringPS() for usage.
      (2) This is just a wrapper for pixWriteStringPS(), which
          writes uncompressed image data to memory.

=head2 pixWritePSEmbed

l_int32 pixWritePSEmbed ( const char *filein, const char *fileout )

  pixWritePSEmbed()

      Input:  filein (input file, all depths, colormap OK)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a simple wrapper function that generates an
          uncompressed PS file, with a bounding box.
      (2) The bounding box is required when a program such as TeX
          (through epsf) places and rescales the image.
      (3) The bounding box is sized for fitting the image to an
          8.5 x 11.0 inch page.

=head2 pixWriteStreamPS

l_int32 pixWriteStreamPS ( FILE *fp, PIX *pix, BOX *box, l_int32 res, l_float32 scale )

  pixWriteStreamPS()

      Input:  stream
              pix
              box  (<optional>)
              res  (can use 0 for default of 300 ppi)
              scale (to prevent scaling, use either 1.0 or 0.0)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This writes image in PS format, optionally scaled,
          adjusted for the printer resolution, and with
          a bounding box.
      (2) For details on use of parameters, see pixWriteStringPS().

=head2 pixWriteStringPS

char * pixWriteStringPS ( PIX *pixs, BOX *box, l_int32 res, l_float32 scale )

  pixWriteStringPS()

      Input:  pixs:  all depths, colormap OK
              box:  (a) If box == null, image is placed, optionally scaled,
                        in a standard b.b. at the center of the page.
                        This is to be used when another program like
                        TeX (through epsf) places the image.
                    (b) If box != null, image is placed without a
                        b.b. at the specified page location and with
                        (optional) scaling.  This is to be used when
                        you want to specify exactly where (and optionally
                        how big) you want the image to be.
                        Note that all coordinates are in PS convention,
                        with (0,0) at LL corner of the page:
                            (x,y)    location of LL corner of image, in mils.
                            (w,h)    scaled size, in mils.  Use 0 to
                                     scale with "scale" and "res" input.
              res:  resolution, in printer ppi.  Use 0 for default (300 ppi).
              scale: scale factor.  If no scaling is desired, use
                     either 1.0 or 0.0.   Scaling just resets the resolution
                     parameter; the actual scaling is done in the
                     interpreter at rendering time.  This is important:
                     it allows you to scale the image up without
                     increasing the file size.
      Return: ps string if OK, or null on error

  Notes:
      (1) OK, this seems a bit complicated, because there are various
          ways to scale and not to scale.  Here's a summary:
      (2) If you don't want any scaling at all:
           * if you are using a box:
               set w = 0, h = 0, and use scale = 1.0; it will print
               each pixel unscaled at printer resolution
           * if you are not using a box:
               set scale = 1.0; it will print at printer resolution
      (3) If you want the image to be a certain size in inches:
           * you must use a box and set the box (w,h) in mils
      (4) If you want the image to be scaled by a scale factor != 1.0:
           * if you are using a box:
               set w = 0, h = 0, and use the desired scale factor;
               the higher the printer resolution, the smaller the
               image will actually appear.
           * if you are not using a box:
               set the desired scale factor; the higher the printer
               resolution, the smaller the image will actually appear.
      (5) Another complication is the proliferation of distance units:
           * The interface distances are in milli-inches.
           * Three different units are used internally:
              - pixels  (units of 1/res inch)
              - printer pts (units of 1/72 inch)
              - inches
           * Here is a quiz on volume units from a reviewer:
             How many UK milli-cups in a US kilo-teaspoon?
               (Hint: 1.0 US cup = 0.75 UK cup + 0.2 US gill;
                      1.0 US gill = 24.0 US teaspoons)

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
