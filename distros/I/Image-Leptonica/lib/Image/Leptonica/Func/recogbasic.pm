package Image::Leptonica::Func::recogbasic;
$Image::Leptonica::Func::recogbasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::recogbasic

=head1 VERSION

version 0.04

=head1 C<recogbasic.c>

  recogbasic.c

      Recoga creation, destruction and access
         L_RECOGA           *recogaCreateFromRecog()
         L_RECOGA           *recogaCreateFromPixaa()
         L_RECOGA           *recogaCreate()
         void                recogaDestroy()
         l_int32             recogaAddRecog()
         static l_int32      recogaExtendArray()
         l_int32             recogReplaceInRecoga()
         L_RECOG            *recogaGetRecog()
         l_int32             recogaGetCount()
         l_int32             recogGetCount()
         l_int32             recogGetIndex()
         l_int32             recogGetParent()
         l_int32             recogSetBootflag()

      Recog initialization and destruction
         L_RECOG            *recogCreateFromRecog()
         L_RECOG            *recogCreateFromPixa()
         L_RECOG            *recogCreate()
         void                recogDestroy()

      Appending (combining two recogs into one)
         l_int32             recogAppend()

      Character/index lookup
         l_int32             recogGetClassIndex()
         l_int32             recogStringToIndex()
         l_int32             recogGetClassString()
         l_int32             l_convertCharstrToInt()

      Serialization
         L_RECOGA           *recogaRead()
         L_RECOGA           *recogaReadStream()
         l_int32             recogaWrite()
         l_int32             recogaWriteStream()
         l_int32             recogaWritePixaa()
         L_RECOG            *recogRead()
         L_RECOG            *recogReadStream()
         l_int32             recogWrite()
         l_int32             recogWriteStream()
         l_int32             recogWritePixa()
         static l_int32      recogAddCharstrLabels()
         static l_int32      recogAddAllSamples()

  The recognizer functionality is split into four files:
    recogbasic.c: create, destroy, access, serialize
    recogtrain.c: training on labelled and unlabelled data
    recogident.c: running the recognizer(s) on input
    recogdid.c:   running the recognizer(s) on input using a
                  document image decoding (DID) hidden markov model

  This is a content-adapted (or book-adapted) recognizer (BAR) application.
  The recognizers here are typically bootstrapped from data that has
  been labelled by a generic recognition system, such as Tesseract.
  The general procedure to create a recognizer (recog) from labelled data is
  to add the labelled character bitmaps, and call recogTrainingFinished()
  when done.

  Typically, the recog is added to a recoga (an array of recognizers)
  before use.  However, for identifying single characters, it is possible
  to use a single recog.

  If there is more than one recog, the usage options are:
  (1) To join the two together (e.g., if they're from the same source)
  (2) To put them separately into a recoga (recognizer array).

  For training numeric input, an example set of calls that scales
  each training input to (w, h) and will use the averaged
  templates for identifying unknown characters is:
         L_Recog  *rec = recogCreate(w, h, L_USE_AVERAGE, 128, 1, "fonts");
         for (i = 0; i < n; i++) {  // read in n training digits
             Pix *pix = ...
             recogTrainLabelled(rec, pix, NULL, text[i], 0, 0);
         }
         recogTrainingFinished(rec, 0);  // required

  It is an error if any function that computes averages, removes
  outliers or requests identification of an unlabelled character,
  such as:
         (1) computing the sample averages: recogAverageSamples()
         (2) removing outliers: recogRemoveOutliers()
         (3) requesting identification of an unlabeled character:
                 recogIdentifyPix()
  is called before an explicit call to finish training.  Note that
  to do further training on a "finished" recognizer, just set
         recog->train_done = FALSE;
  add the new training samples, and again call
         recogTrainingFinished(rec, 0);  // required

  If using all examples for identification, all scaled to (w, h),
  and with outliers removed, do something like this:
         L_Recog  *rec = recogCreate(w, h, L_USE_ALL, 128, 1, "fonts");
         for (i = 0; i < n; i++) {  // read in n training characters
             Pix *pix = ...
             recogTrainLabelled(rec, pix, NULL, text[i], 0, 0);
         }
         recogTrainingFinished(rec, 0);
         // remove anything with correlation less than 0.7 with average
         recogRemoveOutliers(rec, 0.7, 0.5, 0);

  You can train a recognizer from a pixa where the text field in each
  pix is the character string:

         L_Recog  *recboot = recogCreateFromPixa(pixa, w, h, L_USE_AVERAGE,
                                                 128, 1, "fonts");

  This is useful as a "bootstrap" recognizer for training a new
  recognizer (rec) on an unlabelled data set that has a different
  origin from recboot.  To do this, the new recognizer must be
  initialized to use the same (w,h) scaling as the bootstrap recognizer.
  If the new recognizer is to be used without scaling (e.g., on images
  from a single source, like a book), call recogSetScaling() to
  regenerate all the scaled samples and averages:

         L_Recog  *rec = recogCreate(w, h, L_USE_ALL, 128, 1, "fonts");
         for (i = 0; i < n; i++) {  // read in n training characters
             Pix *pix = ...
             recogTrainUnlabelled(rec, recboot, pix, NULL, 1, 0.75, 0);
         }
         recogTrainingFinished(rec, 0);
         recogSetScaling(rec, 0, 0);  // use with no scaling

=head1 FUNCTIONS

=head2 l_convertCharstrToInt

l_int32 l_convertCharstrToInt ( const char *str, l_int32 *pval )

  l_convertCharstrToInt()

      Input:  str (input string representing one UTF-8 character;
                   not more than 4 bytes)
              &val (<return> integer value for the input.  Think of it
                    as a 1-to-1 hash code.)
      Return: 0 if OK, 1 on error

=head2 recogAppend

l_int32 recogAppend ( L_RECOG *recog1, L_RECOG *recog2 )

  recogAppend()

      Input:  recog1
              recog2 (gets added to recog1)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used to make a training recognizer from more than
          one trained recognizer source.  It should only be used
          when the bitmaps for corresponding character classes are
          very similar.  That constraint does not arise when
          the character classes are disjoint; e.g., if recog1 is
          digits and recog2 is alphabetical.
      (2) This is done by appending recog2 to recog1.  Averages are
          computed for each recognizer, if necessary, before appending.
      (3) Non-array fields are combined using the appropriate min and max.

=head2 recogCreate

L_RECOG * recogCreate ( l_int32 scalew, l_int32 scaleh, l_int32 templ_type, l_int32 threshold, l_int32 maxyshift, const char *fontdir )

  recogCreate()

      Input:  scalew  (scale all widths to this; use 0 for no scaling)
              scaleh  (scale all heights to this; use 0 for no scaling)
              templ_type (L_USE_AVERAGE or L_USE_ALL)
              threshold (for binarization; typically ~128)
              maxyshift (from nominal centroid alignment; typically 0 or 1)
              fontdir  (<optional> directory for bitmap fonts for debugging)
      Return: recog, or null on error

  Notes:
      (1) For a set trained on one font, such as numbers in a book,
          it is sensible to set scalew = scaleh = 0.
      (2) For a mixed training set, scaling to a fixed height,
          such as 32 pixels, but leaving the width unscaled, is effective.
      (3) The storage for most of the arrays is allocated when training
          is finished.

=head2 recogCreateFromPixa

L_RECOG * recogCreateFromPixa ( PIXA *pixa, l_int32 scalew, l_int32 scaleh, l_int32 templ_type, l_int32 threshold, l_int32 maxyshift, const char *fontdir )

  recogCreateFromPixa()

      Input:  pixa (of labelled, 1 bpp images)
              scalew  (scale all widths to this; use 0 for no scaling)
              scaleh  (scale all heights to this; use 0 for no scaling)
              templ_type (L_USE_AVERAGE or L_USE_ALL)
              threshold (for binarization; typically ~128)
              maxyshift (from nominal centroid alignment; typically 0 or 1)
              fontdir  (<optional> directory for bitmap fonts for debugging)
      Return: recog, or null on error

  Notes:
      (1) This is a convenience function for training from labelled data.
          The pixa can be read from file.
      (2) The pixa should contain the unscaled bitmaps used for training.
      (3) The characters here should work as a single "font", because
          each image example is put into a class defined by its
          character label.  All examples in the same class should be
          similar.

=head2 recogCreateFromRecog

L_RECOG * recogCreateFromRecog ( L_RECOG *recs, l_int32 scalew, l_int32 scaleh, l_int32 templ_type, l_int32 threshold, l_int32 maxyshift, const char *fontdir )

  recogCreateFromRecog()

      Input:  recs (source recog with arbitrary input parameters)
              scalew  (scale all widths to this; use 0 for no scaling)
              scaleh  (scale all heights to this; use 0 for no scaling)
              templ_type (L_USE_AVERAGE or L_USE_ALL)
              threshold (for binarization; typically ~128)
              maxyshift (from nominal centroid alignment; typically 0 or 1)
              fontdir  (<optional> directory for bitmap fonts for debugging)
      Return: recd, or null on error

  Notes:
      (1) This is a convenience function that generates a recog using
          the unscaled training data in an existing recog.

=head2 recogDestroy

void recogDestroy ( L_RECOG **precog )

  recogDestroy()

      Input:  &recog (<will be set to null before returning>)
      Return: void

  Notes:
      (1) If a recog has a parent, the parent owns it.  A recogDestroy()
          will fail if there is a parent.

=head2 recogGetClassIndex

l_int32 recogGetClassIndex ( L_RECOG *recog, l_int32 val, char *text, l_int32 *pindex )

  recogGetClassIndex()

      Input:  recog (with LUT's pre-computed)
              val (integer value; can be up to 3 bytes for UTF-8)
              text (text from which @val was derived; used if not found)
              &index (<return> index into dna_tochar)
      Return: 0 if found; 1 if not found and added; 2 on error.

  Notes:
      (1) This is used during training.  It searches the
          dna character array for @val.  If not found, it increments
          the setsize by 1, augmenting both the index and text arrays.
      (2) Returns the index in &index, except on error.
      (3) Caller must check the function return value.

=head2 recogGetCount

l_int32 recogGetCount ( L_RECOG *recog )

  recogGetCount()

      Input:  recog
      Return: count of classes in recog; 0 if no recog or on error

=head2 recogGetIndex

l_int32 recogGetIndex ( L_RECOG *recog, l_int32 *pindex )

  recogGetIndex()

      Input:  recog
             &index (into the parent recoga; -1 if no parent)
      Return: 0 if OK, 1 on error

=head2 recogGetParent

L_RECOGA * recogGetParent ( L_RECOG *recog )

  recogGetParent()

      Input:  recog
      Return: recoga (back-pointer to parent); can be null

=head2 recogRead

L_RECOG * recogRead ( const char *filename )

  recogRead()

      Input:  filename
      Return: recog, or null on error

  Notes:
      (1) Serialization can be applied to any recognizer, including
          one with more than one "font".  That is, it can have
          multiple character classes with the same character set
          description, where each of those classes contains characters
          that are very similar in size and shape.  Each pixa in
          the serialized pixaa contains images for a single character
          class.

=head2 recogReadStream

L_RECOG * recogReadStream ( FILE *fp )

  recogReadStream()

      Input:  stream
      Return: recog, or null on error

=head2 recogReplaceInRecoga

l_int32 recogReplaceInRecoga ( L_RECOG **precog1, L_RECOG *recog2 )

  recogReplaceInRecoga()

      Input:  &recog1 (old recog, to be destroyed)
              recog2 (new recog, to be inserted in place of @recog1)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This always destroys recog1.
      (2) If recog1 belongs to a recoga, this inserts recog2 into
          the slot that recog1 previously occupied.

=head2 recogSetBootflag

l_int32 recogSetBootflag ( L_RECOG *recog )

  recogSetBootflag()

      Input:  recog
      Return: 0 if OK, 1 on error

  Notes:
      (1) This must be set for any bootstrap recog, where the samples
          are not from the media being identified.
      (2) It is used to enforce scaled bitmaps for identification,
          and to prevent the recog from being used to split touching
          characters (which requires unscaled samples from the
          material being identified).

=head2 recogStringToIndex

l_int32 recogStringToIndex ( L_RECOG *recog, char *text, l_int32 *pindex )

  recogStringToIndex()

      Input:  recog
              text (text string for some class)
              &index (<return> index for that class; -1 if not found)
      Return: 0 if OK, 1 on error (not finding the string is an error)

=head2 recogWrite

l_int32 recogWrite ( const char *filename, L_RECOG *recog )

  recogWrite()

      Input:  filename
              recog
      Return: 0 if OK, 1 on error

=head2 recogWritePixa

l_int32 recogWritePixa ( const char *filename, L_RECOG *recog )

  recogWritePixa()

      Input:  filename
              recog
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a pixa of all the unscaled images in the
          recognizer, where each one has its character string in
          the pix text field, by flattening pixaa_u to a pixa.
      (2) As a side-effect, the character class label is written
          into each pix in recog.

=head2 recogWriteStream

l_int32 recogWriteStream ( FILE *fp, L_RECOG *recog, const char *filename )

  recogWriteStream()

      Input:  stream (opened for "wb")
              recog
              filename (output serialized filename; embedded in file)
      Return: 0 if OK, 1 on error

=head2 recogaAddRecog

l_int32 recogaAddRecog ( L_RECOGA *recoga, L_RECOG *recog )

  recogaAddRecog()

      Input:  recoga
              recog (to be added and owned by the recoga; not a copy)
      Return: recoga, or null on error

=head2 recogaCreate

L_RECOGA * recogaCreate ( l_int32 n )

  recogaCreate()

      Input:  n (initial number of recog ptrs)
      Return: recoga, or null on error

=head2 recogaCreateFromPixaa

L_RECOGA * recogaCreateFromPixaa ( PIXAA *paa, l_int32 scalew, l_int32 scaleh, l_int32 templ_type, l_int32 threshold, l_int32 maxyshift, const char *fontdir )

  recogaCreateFromPixaa()

      Input:  paa (of labelled, 1 bpp images)
              scalew  (scale all widths to this; use 0 for no scaling)
              scaleh  (scale all heights to this; use 0 for no scaling)
              templ_type (L_USE_AVERAGE or L_USE_ALL)
              threshold (for binarization; typically ~128)
              maxyshift (from nominal centroid alignment; typically 0 or 1)
              fontdir  (<optional> directory for bitmap fonts for debugging)
      Return: recoga, or null on error

  Notes:
      (1) This is a convenience function for training from labelled data.
      (2) Each pixa in the paa is a set of labelled data that is used
          to train a recognizer (e.g., for a set of characters in a font).
          Each image example in the pixa is put into a class in its
          recognizer, defined by its character label.  All examples in
          the same class should be similar.
      (3) The pixaa can be written by recogaWritePixaa(), and must contain
          the unscaled bitmaps used for training.

=head2 recogaCreateFromRecog

L_RECOGA * recogaCreateFromRecog ( L_RECOG *recog )

  recogaCreateFromRecog()

      Input:  recog
      Return: recoga, or null on error

  Notes:
      (1) This is a convenience function for making a recoga after
          you have a recog.  The recog is owned by the recoga.
      (2) For splitting connected components, the
          input recog must be from the material to be identified,
          and not a generic bootstrap recog.  Those can be added later.

=head2 recogaDestroy

void recogaDestroy ( L_RECOGA **precoga )

  recogaDestroy()

      Input:  &recoga (<will be set to null before returning>)
      Return: void

  Notes:
      (1) If a recog has a parent, the parent owns it.  To destroy
          a recog, it must first be "orphaned".

=head2 recogaGetCount

l_int32 recogaGetCount ( L_RECOGA *recoga )

  recogaGetCount()

      Input:  recoga
      Return: count of recog in array; 0 if no recog or on error

=head2 recogaGetRecog

L_RECOG * recogaGetRecog ( L_RECOGA *recoga, l_int32 index )

  recogaGetRecog()

      Input:  recoga
              index (to the index-th recog)
      Return: recog, or null on error

  Notes:
      (1) This returns a ptr to the recog, which is still owned by
          the recoga.  Do not destroy it.

=head2 recogaRead

L_RECOGA * recogaRead ( const char *filename )

  recogaRead()

      Input:  filename
      Return: recoga, or null on error

  Notes:
      (1) This allows serialization of an array of recognizers, each of which
          can be used for different fonts, font styles, etc.

=head2 recogaReadStream

L_RECOGA * recogaReadStream ( FILE *fp )

  recogaReadStream()

      Input:  stream
      Return: recog, or null on error

=head2 recogaWrite

l_int32 recogaWrite ( const char *filename, L_RECOGA *recoga )

  recogaWrite()

      Input:  filename
              recoga
      Return: 0 if OK, 1 on error

=head2 recogaWritePixaa

l_int32 recogaWritePixaa ( const char *filename, L_RECOGA *recoga )

  recogaWritePixaa()

      Input:  filename
              recoga
      Return: 0 if OK, 1 on error

  Notes:
      (1) For each recognizer, this generates a pixa of all the
          unscaled images.  They are combined into a pixaa for
          the set of recognizers.  Each pix has has its character
          string in the pix text field.
      (2) As a side-effect, the character class label is written
          into each pix in recog.

=head2 recogaWriteStream

l_int32 recogaWriteStream ( FILE *fp, L_RECOGA *recoga, const char *filename )

  recogaWriteStream()

      Input:  stream (opened for "wb")
              recoga
              filename (output serialized filename; embedded in file)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
