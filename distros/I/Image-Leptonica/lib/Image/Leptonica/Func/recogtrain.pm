package Image::Leptonica::Func::recogtrain;
$Image::Leptonica::Func::recogtrain::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::recogtrain

=head1 VERSION

version 0.04

=head1 C<recogtrain.c>

  recogtrain.c

      Training on labelled data
         l_int32             recogTrainLabelled()
         l_int32             recogProcessMultLabelled()
         PIX                *recogProcessSingleLabelled()
         l_int32             recogAddSamples()
         PIX                *recogScaleCharacter()
         l_int32             recogAverageSamples()
         l_int32             pixaAccumulateSamples()
         l_int32             recogTrainingFinished()
         l_int32             recogRemoveOutliers()

      Evaluate training status
         l_int32             recogaTrainingDone()
         l_int32             recogaFinishAveraging()

      Training on unlabelled data
         l_int32             recogTrainUnlabelled()

      Padding the training set
         l_int32             recogPadTrainingSet()
         l_int32            *recogMapIndexToIndex()
         static l_int32      recogAverageClassGeom()
         l_int32             recogaBestCorrelForPadding()
         l_int32             recogCorrelAverages()
         l_int32             recogSetPadParams()
         static l_int32      recogGetCharsetSize()
         static l_int32      recogCharsetAvailable()

      Debugging
         l_int32             recogaShowContent()
         l_int32             recogShowContent()
         l_int32             recogDebugAverages()
         l_int32             recogShowAverageTemplates()
         PIX                *recogShowMatchesInRange()
         PIX                *recogShowMatch()
         l_int32             recogMakeBmf()

      Static helpers
         static char        *l_charToString()
         static void         addDebugImage1()
         static void         addDebugImage2()

=head1 FUNCTIONS

=head2 pixaAccumulateSamples

l_int32 pixaAccumulateSamples ( PIXA *pixa, PTA *pta, PIX **ppixd, l_float32 *px, l_float32 *py )

  pixaAccumulateSamples()

      Input:  pixa (of samples from the same class, 1 bpp)
              pta (<optional> of centroids of the samples)
              &ppixd (<return> accumulated samples, 8 bpp)
              &px (<optional return> average x coordinate of centroids)
              &py (<optional return> average y coordinate of centroids)
      Return: 0 on success, 1 on failure

  Notes:
      (1) This generates an aligned (by centroid) sum of the input pix.
      (2) We use only the first 256 samples; that's plenty.
      (3) If pta is not input, we generate two tables, and discard
          after use.  If this is called many times, it is better
          to precompute the pta.

=head2 recogAddSamples

l_int32 recogAddSamples ( L_RECOG *recog, PIXA *pixa, l_int32 classindex, l_int32 debug )

  recogAddSamples()

      Input:  recog
              pixa (1 or more characters)
              classindex (use -1 if not forcing into a specified class)
              debug
      Return: 0 if OK, 1 on error

  Notes:
      (1) The pix in the pixa are all 1 bpp, and the character string
          labels are embedded in the pix.
      (2) Note: this function decides what class each pix belongs in.
          When input is from a multifont pixaa, with a valid value
          for @classindex, the character string label in each pix
          is ignored, and @classindex is used as the class index
          for all the pix in the pixa.  Thus, for that situation we
          use this class index to avoid making the decision through a
          lookup based on the character strings embedded in the pix.
      (3) When a recog is initially filled with samples, the pixaa_u
          array is initialized to accept up to 256 different classes.
          When training is finished, the arrays are truncated to the
          actual number of classes.  To pad an existing recog from
          the boot recognizers, training is started again; if samples
          from a new class are added, the pixaa_u array must be
          extended by adding a pixa to hold them.

=head2 recogAverageSamples

l_int32 recogAverageSamples ( L_RECOG *recog, l_int32 debug )

  recogAverageSamples()

      Input:  recog
              debug
      Return: 0 on success, 1 on failure

  Notes:
      (1) This is called when training is finished, and after
          outliers have been removed.
          Both unscaled and scaled inputs are averaged.
          Averages must be computed before any identification is done.
      (2) Set debug = 1 to view the resulting templates
          and their centroids.

=head2 recogBestCorrelForPadding

l_int32 recogBestCorrelForPadding ( L_RECOG *recog, L_RECOGA *recoga, NUMA **pnaset, NUMA **pnaindex, NUMA **pnascore, NUMA **pnasum, PIXA **ppixadb )

  recogBestCorrelForPadding()

      Input:  recog (typically the recog to be padded)
              recoga (array of recogs for potentially providing the padding)
              &naset (<return> of indices into the sets to be matched)
              &naindex (<return> of matching indices into the best set)
              &nascore (<return> of best correlation scores)
              &naave (<return> average of correlation scores from each recog)
              &pixadb (<optional return> debug images; use NULL for no debug)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This finds, for each class in recog, the best matching template
          in the recoga.  For that best match, it returns:
            * the recog set index in the recoga,
            * the index in that recog for the class,
            * the score for the best match
      (2) It also returns in @naave, for each recog in recoga, the
          average overall correlation for all averaged templates to
          those in the input recog.  The recog with the largest average
          can supply templates in cases where the input recog has
          no examples.
      (3) For classes in recog1 for which no corresponding class
          is found in any recog in recoga, the index -1 is stored
          in both naset and naindex, and 0.0 is stored in nascore.
      (4) Both recog and all the recog in recoga should be generated
          with isotropic scaling to the same character height (e.g., 30).

=head2 recogCorrelAverages

l_int32 recogCorrelAverages ( L_RECOG *recog1, L_RECOG *recog2, NUMA **pnaindex, NUMA **pnascore, PIXA **ppixadb )

  recogCorrelAverages()

      Input:  recog1 (typically the recog to be padded)
              recog2 (potentially providing the padding)
              &naindex (<return> of classes in 2 with respect to classes in 1)
              &nascore (<return> correlation scores of corresponding classes)
              &pixadb (<optional return> debug images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Use this for potentially padding recog1 with instances in recog2.
          The recog have been generated with isotropic scaling to the
          same fixed height (e.g., 30).  The training has been "finished"
          in the sense that all arrays have been computed and they
          could potentially be used as they are.  This is necessary
          for doing the correlation between scaled images.
          However, this function is called when there is a request to
          augument some of the examples in classes in recog1.
      (2) Iterate over classes in recog1, finding the corresponding
          class in recog2 and computing the correlation score between
          the average templates of the two.  naindex is a LUT between
          the index of a class in recog1 and the corresponding one in recog2.
      (3) For classes in recog1 that do not exist in recog2, the index
          -1 is stored in naindex, and 0.0 is stored in the score.

=head2 recogDebugAverages

l_int32 recogDebugAverages ( L_RECOG *recog, l_int32 debug )

  recogDebugAverages()

      Input:  recog
              debug (0 no output; 1 for images; 2 for text; 3 for both)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Generates an image that pairs each of the input images used
          in training with the average template that it is best
          correlated to.  This is written into the recog.
      (2) It also generates pixa_tr of all the input training images,
          which can be used, e.g., in recogShowMatchesInRange().

=head2 recogMakeBmf

l_int32 recogMakeBmf ( L_RECOG *recog, const char *fontdir, l_int32 size )

  recogMakeBmf()

      Input:  recog
              fontdir (for bitmap fonts; typically "fonts")
              size  (of font; even integer between 4 and 20; default is 6)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This can be used to (re)set the size of the font used for
          debug labelling.

=head2 recogPadTrainingSet

l_int32 recogPadTrainingSet ( L_RECOG **precog, l_int32 debug )

  recogPadTrainingSet()

      Input:  &recog (to be replaced if padding or more drastic measures
                      are necessary; otherwise, it is unchanged.)
              debug (1 for debug output saved to recog; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Before calling this, call recogSetPadParams() if you want
          non-default values for the character set type, min_nopad
          and max_afterpad values, and paths for labelled bitmap
          character sets that can be used to augment an input recognizer.
      (2) If all classes in @recog have at least min_nopad samples,
          nothing is done.  If the total number of samples in @recog
          is very small, @recog is replaced by a boot recog from the
          specified bootpath.  Otherwise (the intermediate case),
          @recog is replaced by one with scaling to fixed height,
          where an array of recog are used to augment the input recog.
      (3) If padding or total replacement is done, this destroys
          the input recog and replaces it by a new one.  If the recog
          belongs to a recoga, the replacement is also done in the recoga.

=head2 recogProcessMultLabelled

l_int32 recogProcessMultLabelled ( L_RECOG *recog, PIX *pixs, BOX *box, char *text, PIXA **ppixa, l_int32 debug )

  recogProcessMultLabelled()

      Input:  recog (in training mode)
              pixs (if depth > 1, will be thresholded to 1 bpp)
              box (<optional> cropping box)
              text (<optional> if null, use text field in pix)
              &pixa (<return> of split and thresholded characters)
              debug (1 to display images of samples not captured)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This crops and segments one or more labelled and contiguous
          ascii characters, for input in training.  It is a special case.
      (2) The character images are bundled into a pixa with the
          character text data embedded in each pix.
      (3) Where there is more than one character, this does some
          noise reduction and extracts the resulting character images
          from left to right.  No scaling is performed.

=head2 recogProcessSingleLabelled

l_int32 recogProcessSingleLabelled ( L_RECOG *recog, PIX *pixs, BOX *box, char *text, PIXA **ppixa )

  recogProcessSingleLabelled()

      Input:  recog (in training mode)
              pixs (if depth > 1, will be thresholded to 1 bpp)
              box (<optional> cropping box)
              text (<optional> if null, use text field in pix)
              &pixa (one pix, 1 bpp, labelled)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This crops and binarizes the input image, generating a pix
          of one character where the charval is inserted into the pix.

=head2 recogRemoveOutliers

l_int32 recogRemoveOutliers ( L_RECOG *recog, l_float32 targetscore, l_float32 minfract, l_int32 debug )

  recogRemoveOutliers()

      Input:  recog (after training samples are entered)
              targetscore (keep everything with at least this score)
              minfract (minimum fraction to retain)
              debug (1 for debug output)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Removing outliers is particularly important when recognition
          goes against all the samples in the training set, as opposed
          to the averages for each class.  The reason is that we get
          an identification error if a mislabeled sample is a best
          match for an input bitmap.
      (2) However, the score values depend strongly on the quality
          of the character images.  To avoid losing too many samples,
          we supplement a target score for retention with a minimum
          fraction that we must keep.  With poor quality images, we
          may keep samples with a score less than the targetscore,
          in order to satisfy the @minfract requirement.
      (3) We always require that at least one sample will be retained.
      (4) Where the training set is from the same source (e.g., the
          same book), use a relatively large minscore; say, ~0.8.
      (5) Method: for each class, generate the averages and match each
          scaled sample against the average.  Decide which
          samples will be ejected, and throw out both the
          scaled and unscaled samples and associated data.
          Recompute the average without the poor matches.

=head2 recogScaleCharacter

PIX * recogScaleCharacter ( L_RECOG *recog, PIX *pixs )

  recogScaleCharacter()

      Input:  recog
              pixs (1 bpp, to be scaled)
      Return: pixd (scaled) if OK, null on error

=head2 recogSetPadParams

l_int32 recogSetPadParams ( L_RECOG *recog, const char *bootdir, const char *bootpattern, const char *bootpath, l_int32 type, l_int32 min_nopad, l_int32 max_afterpad )

  recogSetPadParams()

      Input:  recog (to be padded, if necessary)
              bootdir (<optional> directory to bootstrap labelled pixa)
              bootpattern (<optional> pattern for bootstrap labelled pixa)
              bootpath (<optional> path to single bootstrap labelled pixa)
              type (character set type; -1 for default; see enum in recog.h)
              size (character set size; -1 for default)
              min_nopad (min number in a class without padding; -1 default)
              max_afterpad (max number of samples in padded classes;
                            -1 for default)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used to augment or replace a book-adapted recognizer (BAR).
          It is called when the recognizer is created, and must be
          called again before recogPadTrainingSet() if non-default
          values are to be used.
      (2) Default values allow for some padding.  To disable padding,
          set @min_nopad = 0.
      (3) Constraint on @min_nopad and @max_afterpad guarantees that
          padding will be allowed if requested.
      (4) The file directory (@bootdir) and tail pattern (@bootpattern)
          are used to identify serialized pixa, from which we can
          generate an array of recog.  These can be used to augment
          an input but incomplete BAR (book adapted recognizer).
      (5) If the BAR is very sparse, we will ignore it and use a generic
          bootstrap recognizer at @bootpath.

=head2 recogShowAverageTemplates

l_int32 recogShowAverageTemplates ( L_RECOG *recog )

  recogShowAverageTemplates()

      Input:  recog
      Return: 0 on success, 1 on failure

  Notes:
      (1) This debug routine generates a display of the averaged templates,
          both scaled and unscaled, with the centroid visible in red.

=head2 recogShowContent

l_int32 recogShowContent ( FILE *fp, L_RECOG *recog, l_int32 display )

  recogShowContent()

      Input:  stream
              recog
              display (1 for showing template images, 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 recogShowMatch

PIX * recogShowMatch ( L_RECOG *recog, PIX *pix1, PIX *pix2, BOX *box, l_int32 index, l_float32 score )

  recogShowMatch()

      Input:  recog
              pix1  (input pix; several possibilities)
              pix2  (<optional> matching template)
              box  (<optional> region in pix1 for which pix2 matches)
              index  (index of matching template; use -1 to disable printing)
              score  (score of match)
      Return: pixd (pair of images, showing input pix and best template),
                    or null on error.

  Notes:
      (1) pix1 can be one of these:
          (a) The input pix alone, which can be either a single character
              (box == NULL) or several characters that need to be
              segmented.  If more than character is present, the box
              region is displayed with an outline.
          (b) Both the input pix and the matching template.  In this case,
              pix2 and box will both be null.
      (2) If the bmf has been made (by a call to recogMakeBmf())
          and the index >= 0, the index and score will be rendered;
          otherwise their values will be ignored.

=head2 recogShowMatchesInRange

l_int32 recogShowMatchesInRange ( L_RECOG *recog, PIXA *pixa, l_float32 minscore, l_float32 maxscore, l_int32 display )

  recogShowMatchesInRange()

      Input:  recog
              pixa (of 1 bpp images to match)
              minscore, maxscore (range to include output)
              display (to display the result)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives a visual output of the best matches for a given
          range of scores.  Each pair of images can optionally be
          labelled with the index of the best match and the correlation.
          If the bmf has been previously made, it will be used here.
      (2) To use this, save a set of 1 bpp images (labelled or
          unlabelled) that can be given to a recognizer in a pixa.
          Then call this function with the pixa and parameters
          to filter a range of score.

=head2 recogTrainLabelled

l_int32 recogTrainLabelled ( L_RECOG *recog, PIX *pixs, BOX *box, char *text, l_int32 multflag, l_int32 debug )

  recogTrainLabelled()

      Input:  recog (in training mode)
              pixs (if depth > 1, will be thresholded to 1 bpp)
              box (<optional> cropping box)
              text (<optional> if null, use text field in pix)
              multflag (1 if one or more contiguous ascii characters;
                        0 for a single arbitrary character)
              debug (1 to display images of samples not captured)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Training is restricted to the addition of either:
          (a) multflag == 0: a single character in an arbitrary
              (e.g., UTF8) charset
          (b) multflag == 1: one or more ascii characters rendered
              contiguously in pixs
      (2) If box != null, it should represent the cropped location of
          the character image.
      (3) If multflag == 1, samples will be rejected if the number of
          connected components does not equal to the number of ascii
          characters in the textstring.  In that case, if debug == 1,
          the rejected samples will be displayed.

=head2 recogTrainUnlabelled

l_int32 recogTrainUnlabelled ( L_RECOG *recog, L_RECOG *recogboot, PIX *pixs, BOX *box, l_int32 singlechar, l_float32 minscore, l_int32 debug )

  recogTrainUnlabelled()

      Input:  recog (in training mode: the input characters in pixs are
                     inserted after labelling)
              recogboot (labels the input)
              pixs (if depth > 1, will be thresholded to 1 bpp)
              box (<optional> cropping box)
              singlechar (1 if pixs is a single character; 0 otherwise)
              minscore (min score for accepting the example; e.g., 0.75)
              debug (1 for debug output saved to recog; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This trains on unlabelled data, using a bootstrap recognizer
          to apply the labels.  In this way, we can build a recognizer
          using a source of unlabelled data.
      (2) The input pix can have several (non-touching) characters.
          If box != NULL, we treat the region in the box as a single char
          If box == NULL, use all of pixs:
             if singlechar == 0, we identify each c.c. as a single character
             if singlechar == 1, we treat pixs as a single character
          Multiple chars are identified separately by recogboot and
          inserted into recog.
      (3) recogboot is a trained recognizer.  It would typically be
          constructed from a variety of sources, and use the average
          templates for scoring.
      (4) For debugging, if bmf is defined in the recog, the correlation
          scores are generated and saved (by adding to the pixadb_boot
          field) with the matching images.

=head2 recogTrainingFinished

l_int32 recogTrainingFinished ( L_RECOG *recog, l_int32 debug )

  recogTrainingFinished()

      Input:  recog
              debug
      Return: 0 if OK, 1 on error

  Notes:
      (1) This must be called after all training samples have been added.
      (2) Set debug = 1 to view the resulting templates
          and their centroids.
      (3) The following things are done here:
          (a) Allocate (or reallocate) storage for (possibly) scaled
              bitmaps, centroids, and fg areas.
          (b) Generate the (possibly) scaled bitmaps.
          (c) Compute centroid and fg area data for both unscaled and
              scaled bitmaps.
          (d) Compute the averages for both scaled and unscaled bitmaps
          (e) Truncate the pixaa, ptaa and numaa arrays down from
              256 to the actual size.
      (4) Putting these operations here makes it simple to recompute
          the recog with different scaling on the bitmaps.
      (5) Removal of outliers must happen after this is called.

=head2 recogaFinishAveraging

l_int32 recogaFinishAveraging ( L_RECOGA *recoga )

  recogaFinishAveraging()

      Input:  recoga
      Return: 0 if OK, 1 on error

=head2 recogaShowContent

l_int32 recogaShowContent ( FILE *fp, L_RECOGA *recoga, l_int32 display )

  recogaShowContent()

      Input:  stream
              recoga
              display (1 for showing template images, 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 recogaTrainingDone

l_int32 recogaTrainingDone ( L_RECOGA *recoga, l_int32 *pdone )

  recogaTrainingDone()

      Input:  recoga
             &done  (1 if training finished on all recog; 0 otherwise)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
