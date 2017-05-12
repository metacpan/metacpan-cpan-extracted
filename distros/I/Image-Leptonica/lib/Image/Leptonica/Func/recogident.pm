package Image::Leptonica::Func::recogident;
$Image::Leptonica::Func::recogident::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::recogident

=head1 VERSION

version 0.04

=head1 C<recogident.c>

  recogident.c

      Top-level identification
         l_int32             recogaIdentifyMultiple()

      Segmentation and noise removal
         l_int32             recogSplitIntoCharacters()
         l_int32             recogCorrelationBestRow()
         l_int32             recogCorrelationBestChar()
         static l_int32      pixCorrelationBestShift()

      Low-level identification of single characters
         l_int32             recogaIdentifyPixa()
         l_int32             recogIdentifyPixa()
         l_int32             recogIdentifyPix()
         l_int32             recogSkipIdentify()

      Operations for handling identification results
         static L_RCHA      *rchaCreate()
         l_int32            *rchaDestroy()
         static L_RCH       *rchCreate()
         l_int32            *rchDestroy()
         l_int32             rchaExtract()
         l_int32             rchExtract()
         static l_int32      transferRchToRcha()
         static l_int32      recogaSaveBestRcha()
         static l_int32      recogaTransferRch()
         l_int32             recogTransferRchToDid()

      Preprocessing and filtering
         l_int32             recogProcessToIdentify()
         PIX                *recogPreSplittingFilter()
         PIX                *recogSplittingFilter()

      Postprocessing
         SARRAY             *recogExtractNumbers()

      Modifying recog behavior
         l_int32             recogSetTemplateType()
         l_int32             recogSetScaling()

      Static debug helper
         static void         l_showIndicatorSplitValues()

  See recogbasic.c for examples of training a recognizer, which is
  required before it can be used for identification.

  The character splitter repeatedly does a greedy correlation with each
  averaged unscaled template, at all pixel locations along the text to
  be identified.  The vertical alignment is between the template
  centroid and the (moving) windowed centroid, including a delta of
  1 pixel above and below.  The best match then removes part of the
  input image, leaving 1 or 2 pieces, which, after filtering,
  are put in a queue.  The process ends when the queue is empty.
  The filtering is based on the size and aspect ratio of the
  remaining pieces; the intent is to remove anything that is
  unlikely to be text, such as small pieces and line graphics.

  After splitting, the selected segments are identified using
  the input parameters that were initially specified for the
  recognizer.  Unlike the splitter, which uses the averaged
  templates from the unscaled input, the recognizer can use
  either all training examples or averaged templates, and these
  can be either scaled or unscaled.  These choices are specified
  when the recognizer is constructed.

=head1 FUNCTIONS

=head2 rchDestroy

void rchDestroy ( L_RCH **prch )

  rchDestroy()

      Input:  &rch
      Return: void

=head2 rchaDestroy

void rchaDestroy ( L_RCHA **prcha )

  rchaDestroy()

      Input:  &rcha
      Return: void

=head2 rchaExtract

l_int32 rchaExtract ( L_RCHA *rcha, NUMA **pnaindex, NUMA **pnascore, SARRAY **psatext, NUMA **pnasample, NUMA **pnaxloc, NUMA **pnayloc, NUMA **pnawidth )

  rchaExtract()

      Input:  rcha
              &naindex (<optional return> indices of best templates)
              &nascore (<optional return> correl scores of best templates)
              &satext (<optional return> character strings of best templates)
              &nasample (<optional return> indices of best samples)
              &naxloc (<optional return> x-locations of templates)
              &nayloc (<optional return> y-locations of templates)
              &nawidth (<optional return> widths of best templates)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This returns clones of the number and string arrays.  They must
          be destroyed by the caller.

=head2 recogCorrelationBestRow

l_int32 recogCorrelationBestRow ( L_RECOG *recog, PIX *pixs, BOXA **pboxa, NUMA **pnascore, NUMA **pnaindex, SARRAY **psachar, l_int32 debug )

  recogCorrelationBestRow()

      Input:  recog (with LUT's pre-computed)
              pixs (typically of multiple touching characters, 1 bpp)
              &boxa (<return> bounding boxs of best fit character)
              &nascores (<optional return> correlation scores)
              &naindex (<optional return> indices of classes)
              &sachar (<optional return> array of character strings)
              debug (1 for results written to pixadb_split)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Supervises character matching for (in general) a c.c with
          multiple touching characters.  Finds the best match greedily.
          Rejects small parts that are left over after splitting.
      (2) Matching is to the average, and without character scaling.

=head2 recogIdentifyPix

l_int32 recogIdentifyPix ( L_RECOG *recog, PIX *pixs, PIX **ppixdb )

  recogIdentifyPix()

      Input:  recog (with LUT's pre-computed)
              pixs (of a single character, 1 bpp)
              &pixdb (<optional return> debug pix showing input and best fit)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Basic recognition function for a single character.
      (2) If L_USE_AVERAGE, the matching is only to the averaged bitmaps,
          and the index of the sample is meaningless (0 is returned
          if requested).
      (3) The score is related to the confidence (probability of correct
          identification), in that a higher score is correlated with
          a higher probability.  However, the actual relation between
          the correlation (score) and the probability is not known;
          we call this a "score" because "confidence" can be misinterpreted
          as an actual probability.

=head2 recogIdentifyPixa

l_int32 recogIdentifyPixa ( L_RECOG *recog, PIXA *pixa, NUMA *naid, PIX **ppixdb )

  recogIdentifyPixa()

      Input:  recog
              pixa (of 1 bpp images to match)
              naid (<optional> indices of components to identify; can be null)
              &pixdb (<optional return> pix showing inputs and best fits)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See recogIdentifyPix().  This does the same operation
          for each pix in a pixa, and optionally returns the arrays
          of results (scores, class index and character string)
          for the best correlation match.

=head2 recogPreSplittingFilter

PIX * recogPreSplittingFilter ( L_RECOG *recog, PIX *pixs, l_float32 maxasp, l_float32 minaf, l_float32 maxaf, l_int32 debug )

  recogPreSplittingFilter()

      Input:  recog
              pixs (1 bpp, single connected component)
              maxasp (maximum asperity ratio (width/height) to be retained)
              minaf (minimum area fraction (|fg|/(w*h)) to be retained)
              maxaf (maximum area fraction (|fg|/(w*h)) to be retained)
              debug (1 to output indicator arrays)
      Return: pixd (with filtered components removed) or null on error

=head2 recogProcessToIdentify

PIX * recogProcessToIdentify ( L_RECOG *recog, PIX *pixs, l_int32 pad )

  recogProcessToIdentify()

      Input:  recog (with LUT's pre-computed)
              pixs (typ. single character, possibly d > 1 and uncropped)
              pad (extra pixels added to left and right sides)
      Return: pixd (1 bpp, clipped to foreground), or null on error.

  Notes:
      (1) This is a lightweight operation to insure that the input
          image is 1 bpp, properly cropped, and padded on each side.
          If bpp > 1, the image is thresholded.

=head2 recogSetScaling

l_int32 recogSetScaling ( L_RECOG *recog, l_int32 scalew, l_int32 scaleh )

  recogSetScaling()

      Input:  recog
              scalew  (scale all widths to this; use 0 for no scaling)
              scaleh  (scale all heights to this; use 0 for no scaling)
      Return: 0 if OK, 1 on error

=head2 recogSetTemplateType

l_int32 recogSetTemplateType ( L_RECOG *recog, l_int32 templ_type )

  recogSetTemplateType()

      Input:  recog
              templ_type (L_USE_AVERAGE or L_USE_ALL)
      Return: 0 if OK, 1 on error

=head2 recogSkipIdentify

l_int32 recogSkipIdentify ( L_RECOG *recog )

  recogSkipIdentify()

      Input:  recog
      Return: 0 if OK, 1 on error

  Notes:
      (1) This just writes a "dummy" result with 0 score and empty
          string id into the rch.

=head2 recogSplitIntoCharacters

l_int32 recogSplitIntoCharacters ( L_RECOG *recog, PIX *pixs, l_int32 minw, l_int32 minh, BOXA **pboxa, PIXA **ppixa, NUMA **pnaid, l_int32 debug )

  recogSplitIntoCharacters()

      Input:  recog
              pixs (1 bpp, contains only mostly deskewed text)
              minw (remove components with width less than this;
                    use -1 for default removing out of band components)
              minh (remove components with height less than this;
                    use -1 for default removing out of band components)
              &boxa (<return> character bounding boxes)
              &pixa (<return> character images)
              &naid (<return> indices of components to identify)
              debug (1 for results written to pixadb_split)

      Return: 0 if OK, 1 on error

  Notes:
      (1) This can be given an image that has an arbitrary number
          of text characters.  It does splitting of connected
          components based on greedy correlation matching in
          recogCorrelationBestRow().  The returned pixa includes
          the boxes from which the (possibly split) components
          are extracted.
      (2) If either @minw < 0 or @minh < 0, noise components are
          filtered out, and the returned @naid array is all 1.
          Otherwise, some noise components whose dimensions (w,h)
          satisfy w >= @minw and h >= @minh are allowed through, but
          they are identified in the returned @naid, where they are
          labelled by 0 to indicate that they are not to be run
          through identification.  Retaining the noise components
          provides spatial information that can help applications
          interpret the results.
      (3) In addition to optional filtering of the noise, the
          resulting components are put in row-major (2D) order,
          and the smaller of overlapping components are removed if
          they satisfy conditions of relative size and fractional overlap.
      (4) Note that the spliting function uses unscaled templates
          and does not bother returning the class results and scores.
          Thes are more accurately found later using the scaled templates.

=head2 recogSplittingFilter

l_int32 recogSplittingFilter ( L_RECOG *recog, PIX *pixs, l_float32 maxasp, l_float32 minaf, l_float32 maxaf, l_int32 *premove, l_int32 debug )

  recogSplittingFilter()

      Input:  recog
              pixs (1 bpp, single connected component)
              maxasp (maximum asperity ratio (width/height) to be retained)
              minaf (minimum area fraction (|fg|/(w*h)) to be retained)
              maxaf (maximum area fraction (|fg|/(w*h)) to be retained)
              &remove (<return> 0 to save, 1 to remove)
              debug (1 to output indicator arrays)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We don't want to eliminate sans serif characters like "1" or "l",
          so we use the filter condition requiring both a large area fill
          and a w/h ratio > 1.0.

=head2 recogaExtractNumbers

SARRAY * recogaExtractNumbers ( L_RECOGA *recoga, BOXA *boxas, l_float32 scorethresh, l_int32 spacethresh, BOXAA **pbaa, NUMAA **pnaa )

  recogaExtractNumbers()

      Input:  recog
              boxas (location of components)
              scorethresh (min score for which we accept a component)
              spacethresh (max horizontal distance allowed between digits,
                           use -1 for default)
              &baa (<optional return> bounding boxes of identified numbers)
              &naa (<optional return> scores of identified digits)
      Return: sa (of identified numbers), or null on error

  Notes:
      (1) Each string in the returned sa contains a sequence of ascii
          digits in a number.
      (2) The horizontal distance between boxes (limited by @spacethresh)
          is the negative of the horizontal overlap.
      (3) We allow two digits to be combined if these conditions apply:
            (a) the first is to the left of the second
            (b) the second has a horizontal separation less than @spacethresh
            (c) the vertical overlap >= 0 (vertical separation < 0)
            (d) both have a score that exceeds @scorethresh
      (4) Each numa in the optionally returned naa contains the digit
          scores of a number.  Each boxa in the optionally returned baa
          contains the bounding boxes of the digits in the number.
      (5) Components with a score less than @scorethresh, which may
          be hyphens or other small characters, will signal the
          end of the current sequence of digits in the number.

=head2 recogaIdentifyMultiple

l_int32 recogaIdentifyMultiple ( L_RECOGA *recoga, PIX *pixs, l_int32 nitems, l_int32 minw, l_int32 minh, BOXA **pboxa, PIXA **ppixa, PIX **ppixdb, l_int32 debugsplit )

  recogaIdentifyMultiple()

      Input:  recoga (with training finished)
              pixs (containing typically a small number of characters)
              nitems (to be identified in pix; use 0 if not known)
              minw (remove components with width less than this;
                    use -1 for removing all noise components)
              minh (remove components with height less than this;
                    use -1 for removing all noise components)
              &boxa (<optional return> locations of identified components)
              &pixa (<optional return> images of identified components)
              &pixdb (<optional return> debug pix: inputs and best fits)
              debugsplit (1 returns pix split debugging images)
      Return: 0 if OK; 1 if more or less than nitems were found (a warning);
              2 on error.

  Notes:
      (1) This filters the input pixa, looking for @nitems if requested.
          Set @nitems == 0 if you don't know how many chars to expect.
      (2) This bundles the filtered components into a pixa and calls
          recogIdentifyPixa().  If @nitems > 0, use @minw = -1 and
          @minh = -1 to remove all noise components.  If @nitems > 0
          and it doesn't agree with the number of filtered components
          in pixs, a warning is issued and a 1 is returned.
      (3) Set @minw = 0 and @minh = 0 to get all noise components.
          Set @minw > 0 and/or @minh > 0 to retain selected noise components.
          All noise components are recognized as an empty string with
          a score of 0.0.
      (4) An attempt is made to return 2-dimensional sorted arrays
          of (optional) images and boxes, which can then be used to
          aggregate identified characters into numbers or words.
          One typically wants the pixa, which contains a boxa of the
          extracted subimages.

=head2 recogaIdentifyPixa

l_int32 recogaIdentifyPixa ( L_RECOGA *recoga, PIXA *pixa, NUMA *naid, PIX **ppixdb )

  recogaIdentifyPixa()

      Input:  recoga
              pixa (of 1 bpp images to match)
              naid (<optional> indices of components to identify; can be null)
              &pixdb (<optional return> pix showing inputs and best fits)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See recogIdentifyPixa().  This does the same operation
          for each recog, returning the arrays of results (scores,
          class index and character string) for the best correlation match.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
