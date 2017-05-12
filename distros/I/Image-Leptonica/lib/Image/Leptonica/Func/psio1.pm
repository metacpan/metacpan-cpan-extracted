package Image::Leptonica::Func::psio1;
$Image::Leptonica::Func::psio1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::psio1

=head1 VERSION

version 0.04

=head1 C<psio1.c>

  psio1.c

    |=============================================================|
    |                         Important note                      |
    |=============================================================|
    | Some of these functions require libtiff, libjpeg and libz.  |
    | If you do not have these libraries, you must set            |
    |     #define  USE_PSIO     0                                 |
    | in environ.h.  This will link psio1stub.c                   |
    |=============================================================|

     This is a PostScript "device driver" for wrapping images
     in PostScript.  The images can be rendered by a PostScript
     interpreter for viewing, using evince or gv.  They can also be
     rasterized for printing, using gs or an embedded interpreter
     in a PostScript printer.  And they can be converted to a pdf
     using gs (ps2pdf).

     Convert specified files to PS
          l_int32          convertFilesToPS()
          l_int32          sarrayConvertFilesToPS()
          l_int32          convertFilesFittedToPS()
          l_int32          sarrayConvertFilesFittedToPS()
          l_int32          writeImageCompressedToPSFile()

     Convert mixed text/image files to PS
          l_int32          convertSegmentedPagesToPS()
          l_int32          pixWriteSegmentedPageToPS()
          l_int32          pixWriteMixedToPS()

     Convert any image file to PS for embedding
          l_int32          convertToPSEmbed()

     Write all images in a pixa out to PS
          l_int32          pixaWriteCompressedToPS()

  These PostScript converters are used in three different ways.

  (1) For embedding a PS file in a program like TeX.
      convertToPSEmbed() handles this for levels 1, 2 and 3 output,
      and prog/converttops wraps this in an executable.
      converttops is a generalization of Thomas Merz's jpeg2ps wrapper,
      in that it works for all types (formats, depth, colormap)
      of input images and gives PS output in one of these formats
        * level 1 (uncompressed)
        * level 2 (compressed ccittg4 or dct)
        * level 3 (compressed flate)

  (2) For composing a set of pages with any number of images
      painted on them, in either level 2 or level 3 formats.

  (3) For printing a page image or a set of page images, at a
      resolution that optimally fills the page, using
      convertFilesFittedToPS().

  The top-level calls of utilities in category 2, which can compose
  multiple images on a page, and which generate a PostScript file for
  printing or display (e.g., conversion to pdf), are:
      convertFilesToPS()
      convertFilesFittedToPS()
      convertSegmentedPagesToPS()

  All images are output with page numbers.  Bounding box hints are
  more subtle.  They must be included for embeding images in
  TeX, for example, and the low-level writers include bounding
  box hints by default.  However, these hints should not be included for
  multi-page PostScript that is composed of a sequence of images;
  consequently, they are not written when calling higher level
  functions such as convertFilesToPS(), convertFilesFittedToPS()
  and convertSegmentedPagesToPS().  The function l_psWriteBoundingBox()
  sets a flag to give low-level control over this.

=head1 FUNCTIONS

=head2 convertFilesFittedToPS

l_int32 convertFilesFittedToPS ( const char *dirin, const char *substr, l_float32 xpts, l_float32 ypts, const char *fileout )

  convertFilesFittedToPS()

      Input:  dirin (input directory)
              substr (<optional> substring filter on filenames; can be NULL)
              xpts, ypts (desired size in printer points; use 0 for default)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a PS file for all files in a specified directory
          that contain the substr pattern to be matched.
      (2) Each image is written to a separate page in the output PS file.
      (3) All images are written compressed:
              * if tiffg4  -->  use ccittg4
              * if jpeg    -->  use dct
              * all others -->  use flate
          If the image is jpeg or tiffg4, we use the existing compressed
          strings for the encoding; otherwise, we read the image into
          a pix and flate-encode the pieces.
      (4) The resolution is internally determined such that the images
          are rendered, in at least one direction, at 100% of the given
          size in printer points.  Use 0.0 for xpts or ypts to get
          the default value, which is 612.0 or 792.0, rsp.
      (5) The size of the PostScript file is independent of the resolution,
          because the entire file is encoded.  The @xpts and @ypts
          parameter tells the PS decomposer how to render the page.

=head2 convertFilesToPS

l_int32 convertFilesToPS ( const char *dirin, const char *substr, l_int32 res, const char *fileout )

  convertFilesToPS()

      Input:  dirin (input directory)
              substr (<optional> substring filter on filenames; can be NULL)
              res (typ. 300 or 600 ppi)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a PS file for all image files in a specified
          directory that contain the substr pattern to be matched.
      (2) Each image is written to a separate page in the output PS file.
      (3) All images are written compressed:
              * if tiffg4  -->  use ccittg4
              * if jpeg    -->  use dct
              * all others -->  use flate
          If the image is jpeg or tiffg4, we use the existing compressed
          strings for the encoding; otherwise, we read the image into
          a pix and flate-encode the pieces.
      (4) The resolution is often confusing.  It is interpreted
          as the resolution of the output display device:  "If the
          input image were digitized at 300 ppi, what would it
          look like when displayed at res ppi."  So, for example,
          if res = 100 ppi, then the display pixels are 3x larger
          than the 300 ppi pixels, and the image will be rendered
          3x larger.
      (5) The size of the PostScript file is independent of the resolution,
          because the entire file is encoded.  The res parameter just
          tells the PS decomposer how to render the page.  Therefore,
          for minimum file size without loss of visual information,
          if the output res is less than 300, you should downscale
          the image to the output resolution before wrapping in PS.
      (6) The "canvas" on which the image is rendered, at the given
          output resolution, is a standard page size (8.5 x 11 in).

=head2 convertSegmentedPagesToPS

l_int32 convertSegmentedPagesToPS ( const char *pagedir, const char *pagestr, const char *maskdir, const char *maskstr, l_int32 numpre, l_int32 numpost, l_int32 maxnum, l_float32 textscale, l_float32 imagescale, l_int32 threshold, const char *fileout )

  convertSegmentedPagesToPS()

      Input:  pagedir (input page image directory)
              pagestr (<optional> substring filter on page filenames;
                       can be NULL)
              maskdir (input mask image directory)
              maskstr (<optional> substring filter on mask filenames;
                       can be NULL)
              numpre (number of characters in name before number)
              numpost (number of characters in name after number)
              maxnum (only consider page numbers up to this value)
              textscale (scale of text output relative to pixs)
              imagescale (scale of image output relative to pixs)
              threshold (for binarization; typ. about 190; 0 for default)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a PS file for all page image and mask files in two
          specified directories and that contain the page numbers as
          specified below.  The two directories can be the same, in which
          case the page and mask files are differentiated by the two
          substrings for string matches.
      (2) The page images are taken in lexicographic order.
          Mask images whose numbers match the page images are used to
          segment the page images.  Page images without a matching
          mask image are scaled, thresholded and rendered entirely as text.
      (3) Each PS page is generated as a compressed representation of
          the page image, where the part of the image under the mask
          is suitably scaled and compressed as DCT (i.e., jpeg), and
          the remaining part of the page is suitably scaled, thresholded,
          compressed as G4 (i.e., tiff g4), and rendered by painting
          black through the resulting text mask.
      (4) The scaling is typically 2x down for the DCT component
          (@imagescale = 0.5) and 2x up for the G4 component
          (@textscale = 2.0).
      (5) The resolution is automatically set to fit to a
          letter-size (8.5 x 11 inch) page.
      (6) Both the DCT and the G4 encoding are PostScript level 2.
      (7) It is assumed that the page number is contained within
          the basename (the filename without directory or extension).
          @numpre is the number of characters in the basename
          preceeding the actual page numer; @numpost is the number
          following the page number.  Note: the same numbers must be
          applied to both the page and mask image names.
      (8) To render a page as is -- that is, with no thresholding
          of any pixels -- use a mask in the mask directory that is
          full size with all pixels set to 1.  If the page is 1 bpp,
          it is not necessary to have a mask.

=head2 convertToPSEmbed

l_int32 convertToPSEmbed ( const char *filein, const char *fileout, l_int32 level )

  convertToPSEmbed()

      Input:  filein (input image file -- any format)
              fileout (output ps file)
              level (compression: 1 (uncompressed), 2 or 3)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a wrapper function that generates a PS file with
          a bounding box, from any input image file.
      (2) Do the best job of compression given the specified level.
          @level=3 does flate compression on anything that is not
          tiffg4 (1 bpp) or jpeg (8 bpp or rgb).
      (3) If @level=2 and the file is not tiffg4 or jpeg, it will
          first be written to file as jpeg with quality = 75.
          This will remove the colormap and cause some degradation
          in the image.
      (4) The bounding box is required when a program such as TeX
          (through epsf) places and rescales the image.  It is
          sized for fitting the image to an 8.5 x 11.0 inch page.

=head2 pixWriteMixedToPS

l_int32 pixWriteMixedToPS ( PIX *pixb, PIX *pixc, l_float32 scale, l_int32 pageno, const char *fileout )

  pixWriteMixedToPS()

      Input:  pixb (<optionall> 1 bpp "mask"; typically for text)
              pixc (<optional> 8 or 32 bpp image regions)
              scale (relative scale factor for rendering pixb
                    relative to pixc; typ. 4.0)
              pageno (page number in set; use 1 for new output file)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This low level function generates the PS string for a mixed
          text/image page, and adds it to an existing file if
          @pageno > 1.
      (2) The two images (pixb and pixc) are typically generated at the
          resolution that they will be rendered in the PS file.
      (3) pixb is the text component.  In the PostScript world, we think of
          it as a mask through which we paint black.
      (4) pixc is the (typically halftone) image component.  It is
          white in the rest of the page.  To minimize the size of the
          PS file, it should be rendered at a resolution that is at
          least equal to its actual resolution.
      (5) @scale gives the ratio of resolution of pixb to pixc.
          Typical resolutions are: 600 ppi for pixb, 150 ppi for pixc;
          so @scale = 4.0.  If one of the images is not defined,
          the value of @scale is ignored.
      (6) We write pixc with DCT compression (jpeg).  This is followed
          by painting the text as black through the mask pixb.  If
          pixc doesn't exist (alltext), we write the text with the
          PS "image" operator instead of the "imagemask" operator,
          because ghostscript's ps2pdf is flaky when the latter is used.
      (7) The actual output resolution is determined by fitting the
          result to a letter-size (8.5 x 11 inch) page.

=head2 pixWriteSegmentedPageToPS

l_int32 pixWriteSegmentedPageToPS ( PIX *pixs, PIX *pixm, l_float32 textscale, l_float32 imagescale, l_int32 threshold, l_int32 pageno, const char *fileout )

  pixWriteSegmentedPageToPS()

      Input:  pixs (all depths; colormap ok)
              pixm (<optional> 1 bpp segmentation mask over image region)
              textscale (scale of text output relative to pixs)
              imagescale (scale of image output relative to pixs)
              threshold (threshold for binarization; typ. 190)
              pageno (page number in set; use 1 for new output file)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates the PS string for a mixed text/image page,
          and adds it to an existing file if @pageno > 1.
          The PS output is determined by fitting the result to
          a letter-size (8.5 x 11 inch) page.
      (2) The two images (pixs and pixm) are at the same resolution
          (typically 300 ppi).  They are used to generate two compressed
          images, pixb and pixc, that are put directly into the output
          PS file.
      (3) pixb is the text component.  In the PostScript world, we think of
          it as a mask through which we paint black.  It is produced by
          scaling pixs by @textscale, and thresholding to 1 bpp.
      (4) pixc is the image component, which is that part of pixs under
          the mask pixm.  It is scaled from pixs by @imagescale.
      (5) Typical values are textscale = 2.0 and imagescale = 0.5.
      (6) If pixm == NULL, the page has only text.  If it is all black,
          the page is all image and has no text.
      (7) This can be used to write a multi-page PS file, by using
          sequential page numbers with the same output file.  It can
          also be used to write separate PS files for each page,
          by using different output files with @pageno = 0 or 1.

=head2 pixaWriteCompressedToPS

l_int32 pixaWriteCompressedToPS ( PIXA *pixa, const char *fileout, l_int32 res, l_int32 level )

  pixaWriteCompressedToPS()

      Input:  pixa (any set of images)
              fileout (output ps file)
              res (of input image)
              level (compression: 2 or 3)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a PS file of multiple page images, all
          with bounding boxes.
      (2) It compresses to:
              cmap + level2:        jpeg
              cmap + level3:        flate
              1 bpp:                tiffg4
              2 or 4 bpp + level2:  jpeg
              2 or 4 bpp + level3:  flate
              8 bpp:                jpeg
              16 bpp:               flate
              32 bpp:               jpeg
      (3) To generate a pdf, use: ps2pdf <infile.ps> <outfile.pdf>

=head2 sarrayConvertFilesFittedToPS

l_int32 sarrayConvertFilesFittedToPS ( SARRAY *sa, l_float32 xpts, l_float32 ypts, const char *fileout )

  sarrayConvertFilesFittedToPS()

      Input:  sarray (of full path names)
              xpts, ypts (desired size in printer points; use 0 for default)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertFilesFittedToPS()

=head2 sarrayConvertFilesToPS

l_int32 sarrayConvertFilesToPS ( SARRAY *sa, l_int32 res, const char *fileout )

  sarrayConvertFilesToPS()

      Input:  sarray (of full path names)
              res (typ. 300 or 600 ppi)
              fileout (output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertFilesToPS()

=head2 writeImageCompressedToPSFile

l_int32 writeImageCompressedToPSFile ( const char *filein, const char *fileout, l_int32 res, l_int32 *pfirstfile, l_int32 *pindex )

  writeImageCompressedToPSFile()

      Input:  filein (input image file)
              fileout (output ps file)
              res (output printer resolution)
              &firstfile (<input and return> 1 if the first image;
                          0 otherwise)
              &index (<input and return> index of image in output ps file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This wraps a single page image in PS.
      (2) The input file can be in any format.  It is compressed as follows:
             * if in tiffg4  -->  use ccittg4
             * if in jpeg    -->  use dct
             * all others    -->  use flate
      (3) Before the first call, set @firstpage = 1.  After writing
          the first page, it will be set to 0.
      (4) @index is incremented if the page is successfully written.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
