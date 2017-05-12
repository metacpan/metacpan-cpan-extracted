package Image::Leptonica::Func::pageseg;
$Image::Leptonica::Func::pageseg::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pageseg

=head1 VERSION

version 0.04

=head1 C<pageseg.c>

   pageseg.c

      Top level page segmentation
          l_int32   pixGetRegionsBinary()

      Halftone region extraction
          PIX      *pixGenHalftoneMask()

      Textline extraction
          PIX      *pixGenTextlineMask()

      Textblock extraction
          PIX      *pixGenTextblockMask()

      Location of page foreground
          PIX      *pixFindPageForeground()

      Extraction of characters from image with only text
          l_int32   pixSplitIntoCharacters()
          BOXA     *pixSplitComponentWithProfile()

=head1 FUNCTIONS

=head2 pixFindPageForeground

BOX * pixFindPageForeground ( PIX *pixs, l_int32 threshold, l_int32 mindist, l_int32 erasedist, l_int32 pagenum, l_int32 showmorph, l_int32 display, const char *pdfdir )

  pixFindPageForeground()

      Input:  pixs (full resolution (any type or depth)
              threshold (for binarization; typically about 128)
              mindist (min distance of text from border to allow
                       cleaning near border; at 2x reduction, this
                       should be larger than 50; typically about 70)
              erasedist (when conditions are satisfied, erase anything
                         within this distance of the edge;
                         typically 30 at 2x reduction)
              pagenum (use for debugging when called repeatedly; labels
                       debug images that are assembled into pdfdir)
              showmorph (set to a negative integer to show steps in
                         generating masks; this is typically used
                         for debugging region extraction)
              display (set to 1  to display mask and selected region
                       for debugging a single page)
              pdfdir (subdirectory of /tmp where images showing the
                      result are placed when called repeatedly; use
                      null if no output requested)
      Return: box (region including foreground, with some pixel noise
                   removed), or null if not found

  Notes:
      (1) This doesn't simply crop to the fg.  It attempts to remove
          pixel noise and junk at the edge of the image before cropping.
          The input @threshold is used if pixs is not 1 bpp.
      (2) There are several debugging options, determined by the
          last 4 arguments.
      (3) If you want pdf output of results when called repeatedly,
          the pagenum arg labels the images written, which go into
          /tmp/<pdfdir>/<pagenum>.png.  In that case,
          you would clean out the /tmp directory before calling this
          function on each page:
              lept_rmdir(pdfdir);
              lept_mkdir(pdfdir);

=head2 pixGenHalftoneMask

PIX * pixGenHalftoneMask ( PIX *pixs, PIX **ppixtext, l_int32 *phtfound, l_int32 debug )

  pixGenHalftoneMask()

      Input:  pixs (1 bpp, assumed to be 150 to 200 ppi)
              &pixtext (<optional return> text part of pixs)
              &htfound (<optional return> 1 if the mask is not empty)
              debug (flag: 1 for debug output)
      Return: pixd (halftone mask), or null on error

=head2 pixGenTextblockMask

PIX * pixGenTextblockMask ( PIX *pixs, PIX *pixvws, l_int32 debug )

  pixGenTextblockMask()

      Input:  pixs (1 bpp, textline mask, assumed to be 150 to 200 ppi)
              pixvws (vertical white space mask)
              debug (flag: 1 for debug output)
      Return: pixd (textblock mask), or null on error

  Notes:
      (1) Both the input masks (textline and vertical white space) and
          the returned textblock mask are at the same resolution.
      (2) The result is somewhat noisy, in that small "blocks" of
          text may be included.  These can be removed by post-processing,
          using, e.g.,
             pixSelectBySize(pix, 60, 60, 4, L_SELECT_IF_EITHER,
                             L_SELECT_IF_GTE, NULL);

=head2 pixGenTextlineMask

PIX * pixGenTextlineMask ( PIX *pixs, PIX **ppixvws, l_int32 *ptlfound, l_int32 debug )

  pixGenTextlineMask()

      Input:  pixs (1 bpp, assumed to be 150 to 200 ppi)
              &pixvws (<return> vertical whitespace mask)
              &tlfound (<optional return> 1 if the mask is not empty)
              debug (flag: 1 for debug output)
      Return: pixd (textline mask), or null on error

  Notes:
      (1) The input pixs should be deskewed.
      (2) pixs should have no halftone pixels.
      (3) Both the input image and the returned textline mask
          are at the same resolution.

=head2 pixGetRegionsBinary

l_int32 pixGetRegionsBinary ( PIX *pixs, PIX **ppixhm, PIX **ppixtm, PIX **ppixtb, l_int32 debug )

  pixGetRegionsBinary()

      Input:  pixs (1 bpp, assumed to be 300 to 400 ppi)
              &pixhm (<optional return> halftone mask)
              &pixtm (<optional return> textline mask)
              &pixtb (<optional return> textblock mask)
              debug (flag: set to 1 for debug output)
      Return: 0 if OK, 1 on error

  Notes:
      (1) It is best to deskew the image before segmenting.
      (2) The debug flag enables a number of outputs.  These
          are included to show how to generate and save/display
          these results.

=head2 pixSplitComponentWithProfile

BOXA * pixSplitComponentWithProfile ( PIX *pixs, l_int32 delta, l_int32 mindel, PIX **ppixdebug )

  pixSplitComponentWithProfile()

      Input:  pixs (1 bpp, exactly one connected component)
              delta (distance used in extrema finding in a numa; typ. 10)
              mindel (minimum required difference between profile minimum
                      and profile values +2 and -2 away; typ. 7)
              &pixdebug (<optional return> debug image of splitting)
      Return: boxa (of c.c. after splitting), or null on error

  Notes:
      (1) This will split the most obvious cases of touching characters.
          The split points it is searching for are narrow and deep
          minimima in the vertical pixel projection profile, after a
          large vertical closing has been applied to the component.

=head2 pixSplitIntoCharacters

l_int32 pixSplitIntoCharacters ( PIX *pixs, l_int32 minw, l_int32 minh, BOXA **pboxa, PIXA **ppixa, PIX **ppixdebug )

  pixSplitIntoCharacters()

      Input:  pixs (1 bpp, contains only deskewed text)
              minw (minimum component width for initial filtering; typ. 4)
              minh (minimum component height for initial filtering; typ. 4)
              &boxa (<optional return> character bounding boxes)
              &pixa (<optional return> character images)
              &pixdebug (<optional return> showing splittings)

      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a simple function that attempts to find split points
          based on vertical pixel profiles.
      (2) It should be given an image that has an arbitrary number
          of text characters.
      (3) The returned pixa includes the boxes from which the
          (possibly split) components are extracted.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
