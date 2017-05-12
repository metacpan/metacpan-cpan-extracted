package Image::Leptonica::Func::classapp;
$Image::Leptonica::Func::classapp::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::classapp

=head1 VERSION

version 0.04

=head1 C<classapp.c>

  classapp.c

      Top-level jb2 correlation and rank-hausdorff

         l_int32         jbCorrelation()
         l_int32         jbRankHaus()

      Extract and classify words in textline order

         JBCLASSER      *jbWordsInTextlines()
         l_int32         pixGetWordsInTextlines()
         l_int32         pixGetWordBoxesInTextlines()

      Use word bounding boxes to compare page images

         NUMAA          *boxaExtractSortedPattern()
         l_int32         numaaCompareImagesByBoxes()
         static l_int32  testLineAlignmentX()
         static l_int32  countAlignedMatches()
         static void     printRowIndices()

=head1 FUNCTIONS

=head2 boxaExtractSortedPattern

NUMAA * boxaExtractSortedPattern ( BOXA *boxa, NUMA *na )

  boxaExtractSortedPattern()

      Input:  boxa (typ. of word bounding boxes, in textline order)
              numa (index of textline for each box in boxa)
      Return: naa (numaa, where each numa represents one textline),
                   or null on error

  Notes:
      (1) The input is expected to come from pixGetWordBoxesInTextlines().
      (2) Each numa in the output consists of an average y coordinate
          of the first box in the textline, followed by pairs of
          x coordinates representing the left and right edges of each
          of the boxes in the textline.

=head2 jbCorrelation

l_int32 jbCorrelation ( const char *dirin, l_float32 thresh, l_float32 weight, l_int32 components, const char *rootname, l_int32 firstpage, l_int32 npages, l_int32 renderflag )

  jbCorrelation()

       Input:  dirin (directory of input images)
               thresh (typically ~0.8)
               weight (typically ~0.6)
               components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
               rootname (for output files)
               firstpage (0-based)
               npages (use 0 for all pages in dirin)
               renderflag (1 to render from templates; 0 to skip)
       Return: 0 if OK, 1 on error

  Notes:
      (1) The images must be 1 bpp.  If they are not, you can convert
          them using convertFilesTo1bpp().
      (2) See prog/jbcorrelation for generating more output (e.g.,
          for debugging)

=head2 jbRankHaus

l_int32 jbRankHaus ( const char *dirin, l_int32 size, l_float32 rank, l_int32 components, const char *rootname, l_int32 firstpage, l_int32 npages, l_int32 renderflag )

  jbRankHaus()

       Input:  dirin (directory of input images)
               size (of Sel used for dilation; typ. 2)
               rank (rank value of match; typ. 0.97)
               components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
               rootname (for output files)
               firstpage (0-based)
               npages (use 0 for all pages in dirin)
               renderflag (1 to render from templates; 0 to skip)
       Return: 0 if OK, 1 on error

  Notes:
      (1) See prog/jbrankhaus for generating more output (e.g.,
          for debugging)

=head2 jbWordsInTextlines

JBCLASSER * jbWordsInTextlines ( const char *dirin, l_int32 reduction, l_int32 maxwidth, l_int32 maxheight, l_float32 thresh, l_float32 weight, NUMA **pnatl, l_int32 firstpage, l_int32 npages )

  jbWordsInTextlines()

      Input:  dirin (directory of input pages)
              reduction (1 for full res; 2 for half-res)
              maxwidth (of word mask components, to be kept)
              maxheight (of word mask components, to be kept)
              thresh (on correlation; 0.80 is reasonable)
              weight (for handling thick text; 0.6 is reasonable)
              natl (<return> numa with textline index for each component)
              firstpage (0-based)
              npages (use 0 for all pages in dirin)
      Return: classer (for the set of pages)

  Notes:
      (1) This is a high-level function.  See prog/jbwords for example
          of usage.
      (2) Typically, words can be found reasonably well at a resolution
          of about 150 ppi.  For highest accuracy, you should use 300 ppi.
          Assuming that the input images are 300 ppi, use reduction = 1
          for finding words at full res, and reduction = 2 for finding
          them at 150 ppi.

=head2 numaaCompareImagesByBoxes

l_int32 numaaCompareImagesByBoxes ( NUMAA *naa1, NUMAA *naa2, l_int32 nperline, l_int32 nreq, l_int32 maxshiftx, l_int32 maxshifty, l_int32 delx, l_int32 dely, l_int32 *psame, l_int32 debugflag )

  numaaCompareImagesByBoxes()

      Input:  naa1 (for image 1, formatted by boxaExtractSortedPattern())
              naa2 (ditto; for image 2)
              nperline (number of box regions to be used in each textline)
              nreq (number of complete row matches required)
              maxshiftx (max allowed x shift between two patterns, in pixels)
              maxshifty (max allowed y shift between two patterns, in pixels)
              delx (max allowed difference in x data, after alignment)
              dely (max allowed difference in y data, after alignment)
              &same (<return> 1 if @nreq row matches are found; 0 otherwise)
              debugflag (1 for debug output)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Each input numaa describes a set of sorted bounding boxes
          (sorted by textline and, within each textline, from
          left to right) in the images from which they are derived.
          See boxaExtractSortedPattern() for a description of the data
          format in each of the input numaa.
      (2) This function does an alignment between the input
          descriptions of bounding boxes for two images. The
          input parameter @nperline specifies the number of boxes
          to consider in each line when testing for a match, and
          @nreq is the required number of lines that must be well-aligned
          to get a match.
      (3) Testing by alignment has 3 steps:
          (a) Generating the location of word bounding boxes from the
              images (prior to calling this function).
          (b) Listing all possible pairs of aligned rows, based on
              tolerances in horizontal and vertical positions of
              the boxes.  Specifically, all pairs of rows are enumerated
              whose first @nperline boxes can be brought into close
              alignment, based on the delx parameter for boxes in the
              line and within the overall the @maxshiftx and @maxshifty
              constraints.
          (c) Each pair, starting with the first, is used to search
              for a set of @nreq - 1 other pairs that can all be aligned
              with a difference in global translation of not more
              than (@delx, @dely).

=head2 pixGetWordBoxesInTextlines

l_int32 pixGetWordBoxesInTextlines ( PIX *pixs, l_int32 reduction, l_int32 minwidth, l_int32 minheight, l_int32 maxwidth, l_int32 maxheight, BOXA **pboxad, NUMA **pnai )

  pixGetWordBoxesInTextlines()

      Input:  pixs (1 bpp, typ. 300 ppi)
              reduction (1 for input res; 2 for 2x reduction of input res)
              minwidth, minheight (of saved components; smaller are discarded)
              maxwidth, maxheight (of saved components; larger are discarded)
              &boxad (<return> word boxes sorted in textline line order)
              &naindex (<optional return> index of textline for each word)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The input should be at a resolution of about 300 ppi.
          The word masks can be computed at either 150 ppi or 300 ppi.
          For the former, set reduction = 2.
      (2) This is a special version of pixGetWordsInTextlines(), that
          just finds the word boxes in line order, with a numa
          giving the textline index for each word.
          See pixGetWordsInTextlines() for more details.

=head2 pixGetWordsInTextlines

l_int32 pixGetWordsInTextlines ( PIX *pixs, l_int32 reduction, l_int32 minwidth, l_int32 minheight, l_int32 maxwidth, l_int32 maxheight, BOXA **pboxad, PIXA **ppixad, NUMA **pnai )

  pixGetWordsInTextlines()

      Input:  pixs (1 bpp, typ. 300 ppi)
              reduction (1 for input res; 2 for 2x reduction of input res)
              minwidth, minheight (of saved components; smaller are discarded)
              maxwidth, maxheight (of saved components; larger are discarded)
              &boxad (<return> word boxes sorted in textline line order)
              &pixad (<return> word images sorted in textline line order)
              &naindex (<return> index of textline for each word)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The input should be at a resolution of about 300 ppi.
          The word masks and word images can be computed at either
          150 ppi or 300 ppi.  For the former, set reduction = 2.
      (2) The four size constraints on saved components are all
          scaled by @reduction.
      (3) The result are word images (and their b.b.), extracted in
          textline order, at either full res or 2x reduction,
          and with a numa giving the textline index for each word.
      (4) The pixa and boxa interfaces should make this type of
          application simple to put together.  The steps are:
           - optionally reduce by 2x
           - generate first estimate of word masks
           - get b.b. of these, and remove the small and big ones
           - extract pixa of the word images, using the b.b.
           - sort actual word images in textline order (2d)
           - flatten them to a pixa (1d), saving the textline index
             for each pix
      (5) In an actual application, it may be desirable to pre-filter
          the input image to remove large components, to extract
          single columns of text, and to deskew them.  For example,
          to remove both large components and small noisy components
          that can interfere with the statistics used to estimate
          parameters for segmenting by words, but still retain text lines,
          the following image preprocessing can be done:
                Pix *pixt = pixMorphSequence(pixs, "c40.1", 0);
                Pix *pixf = pixSelectBySize(pixt, 0, 60, 8,
                                     L_SELECT_HEIGHT, L_SELECT_IF_LT, NULL);
                pixAnd(pixf, pixf, pixs);  // the filtered image
          The closing turns text lines into long blobs, but does not
          significantly increase their height.  But if there are many
          small connected components in a dense texture, this is likely
          to generate tall components that will be eliminated in pixf.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
