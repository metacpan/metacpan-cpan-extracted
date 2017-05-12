package Image::Leptonica::Func::jbclass;
$Image::Leptonica::Func::jbclass::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::jbclass

=head1 VERSION

version 0.04

=head1 C<jbclass.c>

 jbclass.c

     These are functions for unsupervised classification of
     collections of connected components -- either characters or
     words -- in binary images.  They can be used as image
     processing steps in jbig2 compression.

     Initialization

         JBCLASSER         *jbRankHausInit()      [rank hausdorff encoder]
         JBCLASSER         *jbCorrelationInit()   [correlation encoder]
         JBCLASSER         *jbCorrelationInitWithoutComponents()  [ditto]
         static JBCLASSER  *jbCorrelationInitInternal()

     Classify the pages

         l_int32     jbAddPages()
         l_int32     jbAddPage()
         l_int32     jbAddPageComponents()

     Rank hausdorff classifier

         l_int32     jbClassifyRankHaus()
         l_int32     pixHaustest()
         l_int32     pixRankHaustest()

     Binary correlation classifier

         l_int32     jbClassifyCorrelation()

     Determine the image components we start with

         l_int32     jbGetComponents()
         l_int32     pixWordMaskByDilation()
         l_int32     pixWordBoxesByDilation()

     Build grayscale composites (templates)

         PIXA       *jbAccumulateComposites
         PIXA       *jbTemplatesFromComposites

     Utility functions for Classer

         JBCLASSER  *jbClasserCreate()
         void        jbClasserDestroy()

     Utility functions for Data

         JBDATA     *jbDataSave()
         void        jbDataDestroy()
         l_int32     jbDataWrite()
         JBDATA     *jbDataRead()
         PIXA       *jbDataRender()
         l_int32     jbGetULCorners()
         l_int32     jbGetLLCorners()

     Static helpers

         static JBFINDCTX *findSimilarSizedTemplatesInit()
         static l_int32    findSimilarSizedTemplatesNext()
         static void       findSimilarSizedTemplatesDestroy()
         static l_int32    finalPositioningForAlignment()

     Note: this is NOT an implementation of the JPEG jbig2
     proposed standard encoder, the specifications for which
     can be found at http://www.jpeg.org/jbigpt2.html.
     (See below for a full implementation.)
     It is an implementation of the lower-level part of an encoder that:

        (1) identifies connected components that are going to be used
        (2) puts them in similarity classes (this is an unsupervised
            classifier), and
        (3) stores the result in a simple file format (2 files,
            one for templates and one for page/coordinate/template-index
            quartets).

     An actual implementation of the official jbig2 encoder could
     start with parts (1) and (2), and would then compress the quartets
     according to the standards requirements (e.g., Huffman or
     arithmetic coding of coordinate differences and image templates).

     The low-level part of the encoder provided here has the
     following useful features:

         - It is accurate in the identification of templates
           and classes because it uses a windowed hausdorff
           distance metric.
         - It is accurate in the placement of the connected
           components, doing a two step process of first aligning
           the the centroids of the template with those of each instance,
           and then making a further correction of up to +- 1 pixel
           in each direction to best align the templates.
         - It is fast because it uses a morphologically based
           matching algorithm to implement the hausdorff criterion,
           and it selects the patterns that are possible matches
           based on their size.

     We provide two different matching functions, one using Hausdorff
     distance and one using a simple image correlation.
     The Hausdorff method sometimes produces better results for the
     same number of classes, because it gives a relatively small
     effective weight to foreground pixels near the boundary,
     and a relatively  large weight to foreground pixels that are
     not near the boundary.  By effectively ignoring these boundary
     pixels, Hausdorff weighting corresponds better to the expected
     probabilities of the pixel values in a scanned image, where the
     variations in instances of the same printed character are much
     more likely to be in pixels near the boundary.  By contrast,
     the correlation method gives equal weight to all foreground pixels.

     For best results, use the correlation method.  Correlation takes
     the number of fg pixels in the AND of instance and template,
     divided by the product of the number of fg pixels in instance
     and template.  It compares this with a threshold that, in
     general, depends on the fractional coverage of the template.
     For heavy text, the threshold is raised above that for light
     text,  By using both these parameters (basic threshold and
     adjustment factor for text weight), one has more flexibility
     and can arrive at the fewest substitution errors, although
     this comes at the price of more templates.

     The strict Hausdorff scoring is not a rank weighting, because a
     single pixel beyond the given distance will cause a match
     failure.  A rank Hausdorff is more robust to non-boundary noise,
     but it is also more susceptible to confusing components that
     should be in different classes.  For implementing a jbig2
     application for visually lossless binary image compression,
     you have two choices:

        (1) use a 3x3 structuring element (size = 3) and a strict
            Hausdorff comparison (rank = 1.0 in the rank Hausdorff
            function).  This will result in a minimal number of classes,
            but confusion of small characters, such as italic and
            non-italic lower-case 'o', can still occur.
        (2) use the correlation method with a threshold of 0.85
            and a weighting factor of about 0.7.  This will result in
            a larger number of classes, but should not be confused
            either by similar small characters or by extremely
            thick sans serif characters, such as in prog/cootoots.png.

     As mentioned above, if visual substitution errors must be
     avoided, you should use the correlation method.

     We provide executables that show how to do the encoding:
         prog/jbrankhaus.c
         prog/jbcorrelation.c

     The basic flow for correlation classification goes as follows,
     where specific choices have been made for parameters (Hausdorff
     is the same except for initialization):

             // Initialize and save data in the classer
         JBCLASSER *classer =
             jbCorrelationInit(JB_CONN_COMPS, 0, 0, 0.8, 0.7);
         SARRAY *safiles = getSortedPathnamesInDirectory(directory,
                                                         NULL, 0, 0);
         jbAddPages(classer, safiles);

             // Save the data in a data structure for serialization,
             // and write it into two files.
         JBDATA *data = jbDataSave(classer);
         jbDataWrite(rootname, data);

             // Reconstruct (render) the pages from the encoded data.
         PIXA *pixa = jbDataRender(data, FALSE);

     Adam Langley has built a jbig2 standards-compliant encoder, the
     first one to appear in open source.  You can get this encoder at:
          http://www.imperialviolet.org/jbig2.html

     It uses arithmetic encoding throughout.  It encodes binary images
     losslessly with a single arithmetic coding over the full image.
     It also does both lossy and lossless encoding from connected
     components, using leptonica to generate the templates representing
     each cluster.

=head1 FUNCTIONS

=head2 jbAccumulateComposites

PIXA * jbAccumulateComposites ( PIXAA *pixaa, NUMA **pna, PTA **pptat )

  jbAccumulateComposites()

      Input:  pixaa (one pixa for each class)
              &pna (<return> number of samples used to build each composite)
              &ptat (<return> centroids of bordered composites)
      Return: pixad (accumulated sum of samples in each class),
                     or null on error

=head2 jbAddPage

l_int32 jbAddPage ( JBCLASSER *classer, PIX *pixs )

  jbAddPage()

      Input:  jbclasser
              pixs (of input page)
      Return: 0 if OK; 1 on error

=head2 jbAddPageComponents

l_int32 jbAddPageComponents ( JBCLASSER *classer, PIX *pixs, BOXA *boxas, PIXA *pixas )

  jbAddPageComponents()

      Input:  jbclasser
              pixs (of input page)
              boxas (b.b. of components for this page)
              pixas (components for this page)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If there are no components on the page, we don't require input
          of empty boxas or pixas, although that's the typical situation.

=head2 jbAddPages

l_int32 jbAddPages ( JBCLASSER *classer, SARRAY *safiles )

  jbAddPages()

      Input:  jbclasser
              safiles (of page image file names)
      Return: 0 if OK; 1 on error

  Note:
      (1) jbclasser makes a copy of the array of file names.
      (2) The caller is still responsible for destroying the input array.

=head2 jbClasserCreate

JBCLASSER * jbClasserCreate ( l_int32 method, l_int32 components )

  jbClasserCreate()

      Input:  method (JB_RANKHAUS, JB_CORRELATION)
              components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
      Return: jbclasser, or null on error

=head2 jbClasserDestroy

void jbClasserDestroy ( JBCLASSER **pclasser )

  jbClasserDestroy()

      Input: &classer (<to be nulled>)
      Return: void

=head2 jbClassifyCorrelation

l_int32 jbClassifyCorrelation ( JBCLASSER *classer, BOXA *boxa, PIXA *pixas )

  jbClassifyCorrelation()

      Input:  jbclasser
              boxa (of new components for classification)
              pixas (of new components for classification)
      Return: 0 if OK; 1 on error

=head2 jbClassifyRankHaus

l_int32 jbClassifyRankHaus ( JBCLASSER *classer, BOXA *boxa, PIXA *pixas )

  jbClassifyRankHaus()

      Input:  jbclasser
              boxa (of new components for classification)
              pixas (of new components for classification)
      Return: 0 if OK; 1 on error

=head2 jbCorrelationInit

JBCLASSER * jbCorrelationInit ( l_int32 components, l_int32 maxwidth, l_int32 maxheight, l_float32 thresh, l_float32 weightfactor )

  jbCorrelationInit()

      Input:  components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
              maxwidth (of component; use 0 for default)
              maxheight (of component; use 0 for default)
              thresh (value for correlation score: in [0.4 - 0.98])
              weightfactor (corrects thresh for thick characters [0.0 - 1.0])
      Return: jbclasser if OK; NULL on error

  Notes:
      (1) For scanned text, suggested input values are:
            thresh ~ [0.8 - 0.85]
            weightfactor ~ [0.5 - 0.6]
      (2) For electronically generated fonts (e.g., rasterized pdf),
          a very high thresh (e.g., 0.95) will not cause a significant
          increase in the number of classes.

=head2 jbCorrelationInitWithoutComponents

JBCLASSER * jbCorrelationInitWithoutComponents ( l_int32 components, l_int32 maxwidth, l_int32 maxheight, l_float32 thresh, l_float32 weightfactor )

  jbCorrelationInitWithoutComponents()

      Input:  same as jbCorrelationInit
      Output: same as jbCorrelationInit

  Note: acts the same as jbCorrelationInit(), but the resulting
        object doesn't keep a list of all the components.

=head2 jbDataDestroy

void jbDataDestroy ( JBDATA **pdata )

  jbDataDestroy()

      Input: &data (<to be nulled>)
      Return: void

=head2 jbDataRead

JBDATA * jbDataRead ( const char *rootname )

  jbDataRead()

      Input:  rootname (for template and data files)
      Return: jbdata, or NULL on error

=head2 jbDataRender

PIXA * jbDataRender ( JBDATA *data, l_int32 debugflag )

  jbDataRender()

      Input:  jbdata
              debugflag (if TRUE, writes into 2 bpp pix and adds
                         component outlines in color)
      Return: pixa (reconstruction of original images, using templates) or
              null on error

=head2 jbDataSave

JBDATA * jbDataSave ( JBCLASSER *classer )

  jbDataSave()

      Input:  jbclasser
              latticew, latticeh (cell size used to store each
                  connected component in the composite)
      Return: jbdata, or null on error

  Notes:
      (1) This routine stores the jbig2-type data required for
          generating a lossy jbig2 version of the image.
          It can be losslessly written to (and read from) two files.
      (2) It generates and stores the mosaic of templates.
      (3) It clones the Numa and Pta arrays, so these must all
          be destroyed by the caller.
      (4) Input 0 to use the default values for latticew and/or latticeh,

=head2 jbDataWrite

l_int32 jbDataWrite ( const char *rootout, JBDATA *jbdata )

  jbDataWrite()

      Input:  rootname (for output files; everything but the extension)
              jbdata
      Return: 0 if OK, 1 on error

  Notes:
      (1) Serialization function that writes data in jbdata to file.

=head2 jbGetComponents

l_int32 jbGetComponents ( PIX *pixs, l_int32 components, l_int32 maxwidth, l_int32 maxheight, BOXA **pboxad, PIXA **ppixad )

  jbGetComponents()

      Input:  pixs (1 bpp)
              components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
              maxwidth, maxheight (of saved components; larger are discarded)
              &pboxa (<return> b.b. of component items)
              &ppixa (<return> component items)
      Return: 0 if OK, 1 on error

=head2 jbGetLLCorners

l_int32 jbGetLLCorners ( JBCLASSER *classer )

  jbGetLLCorners()

      Input:  jbclasser
      Return: 0 if OK, 1 on error

  Notes:
      (1) This computes the ptall field, which has the global LL corners,
          adjusted for each specific component, so that each component
          can be replaced by the template for its class and have the
          centroid in the template in the same position as the
          centroid of the original connected component. It is important
          that this be done properly to avoid a wavy baseline in the result.
      (2) It is computed here from the corresponding UL corners, where
          the input templates and stored instances are all bordered.
          This should be done after all pages have been processed.
      (3) For proper substitution, the templates whose LL corners are
          placed in these locations must be UN-bordered.
          This is available for a realistic jbig2 encoder, which would
          (1) encode each template without a border, and (2) encode
          the position using the LL corner (rather than the UL
          corner) because the difference between y-values
          of successive instances is typically close to zero.

=head2 jbGetULCorners

l_int32 jbGetULCorners ( JBCLASSER *classer, PIX *pixs, BOXA *boxa )

  jbGetULCorners()

      Input:  jbclasser
              pixs (full res image)
              boxa (of c.c. bounding rectangles for this page)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This computes the ptaul field, which has the global UL corners,
          adjusted for each specific component, so that each component
          can be replaced by the template for its class and have the
          centroid in the template in the same position as the
          centroid of the original connected component.  It is important
          that this be done properly to avoid a wavy baseline in the
          result.
      (2) The array fields ptac and ptact give the centroids of
          those components relative to the UL corner of each component.
          Here, we compute the difference in each component, round to
          nearest integer, and correct the box->x and box->y by
          the appropriate integral difference.
      (3) The templates and stored instances are all bordered.

=head2 jbRankHausInit

JBCLASSER * jbRankHausInit ( l_int32 components, l_int32 maxwidth, l_int32 maxheight, l_int32 size, l_float32 rank )

  jbRankHausInit()

      Input:  components (JB_CONN_COMPS, JB_CHARACTERS, JB_WORDS)
              maxwidth (of component; use 0 for default)
              maxheight (of component; use 0 for default)
              size  (of square structuring element; 2, representing
                     2x2 sel, is necessary for reasonable accuracy of
                     small components; combine this with rank ~ 0.97
                     to avoid undue class expansion)
              rank (rank val of match, each way; in [0.5 - 1.0];
                    when using size = 2, 0.97 is a reasonable value)
      Return: jbclasser if OK; NULL on error

=head2 jbTemplatesFromComposites

PIXA * jbTemplatesFromComposites ( PIXA *pixac, NUMA *na )

  jbTemplatesFromComposites()

      Input:  pixac (one pix of composites for each class)
              na (number of samples used for each class composite)
      Return: pixad (8 bpp templates for each class), or null on error

=head2 pixHaustest

l_int32 pixHaustest ( PIX *pix1, PIX *pix2, PIX *pix3, PIX *pix4, l_float32 delx, l_float32 dely, l_int32 maxdiffw, l_int32 maxdiffh )

  pixHaustest()

      Input:  pix1   (new pix, not dilated)
              pix2   (new pix, dilated)
              pix3   (exemplar pix, not dilated)
              pix4   (exemplar pix, dilated)
              delx   (x comp of centroid difference)
              dely   (y comp of centroid difference)
              maxdiffw (max width difference of pix1 and pix2)
              maxdiffh (max height difference of pix1 and pix2)
      Return: 0 (FALSE) if no match, 1 (TRUE) if the new
              pix is in the same class as the exemplar.

  Note: we check first that the two pix are roughly
  the same size.  Only if they meet that criterion do
  we compare the bitmaps.  The Hausdorff is a 2-way
  check.  The centroid difference is used to align the two
  images to the nearest integer for each of the checks.
  These check that the dilated image of one contains
  ALL the pixels of the undilated image of the other.
  Checks are done in both direction.  A single pixel not
  contained in either direction results in failure of the test.

=head2 pixRankHaustest

l_int32 pixRankHaustest ( PIX *pix1, PIX *pix2, PIX *pix3, PIX *pix4, l_float32 delx, l_float32 dely, l_int32 maxdiffw, l_int32 maxdiffh, l_int32 area1, l_int32 area3, l_float32 rank, l_int32 *tab8 )

  pixRankHaustest()

      Input:  pix1   (new pix, not dilated)
              pix2   (new pix, dilated)
              pix3   (exemplar pix, not dilated)
              pix4   (exemplar pix, dilated)
              delx   (x comp of centroid difference)
              dely   (y comp of centroid difference)
              maxdiffw (max width difference of pix1 and pix2)
              maxdiffh (max height difference of pix1 and pix2)
              area1  (fg pixels in pix1)
              area3  (fg pixels in pix3)
              rank   (rank value of test, each way)
              tab8   (table of pixel sums for byte)
      Return: 0 (FALSE) if no match, 1 (TRUE) if the new
                 pix is in the same class as the exemplar.

  Note: we check first that the two pix are roughly
  the same size.  Only if they meet that criterion do
  we compare the bitmaps.  We convert the rank value to
  a number of pixels by multiplying the rank fraction by the number
  of pixels in the undilated image.  The Hausdorff is a 2-way
  check.  The centroid difference is used to align the two
  images to the nearest integer for each of the checks.
  The rank hausdorff checks that the dilated image of one
  contains the rank fraction of the pixels of the undilated
  image of the other.   Checks are done in both direction.
  Failure of the test in either direction results in failure
  of the test.

=head2 pixWordBoxesByDilation

l_int32 pixWordBoxesByDilation ( PIX *pixs, l_int32 maxdil, l_int32 minwidth, l_int32 minheight, l_int32 maxwidth, l_int32 maxheight, BOXA **pboxa, l_int32 *psize )

  pixWordBoxesByDilation()

      Input:  pixs (1 bpp; typ. at 75 to 150 ppi)
              maxdil (maximum dilation; 0 for default; warning if > 20)
              minwidth, minheight (of saved components; smaller are discarded)
              maxwidth, maxheight (of saved components; larger are discarded)
              &boxa (<return> dilated word mask)
              &size (<optional return> size of optimal horiz Sel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Returns a pruned set of word boxes.
      (2) See pixWordMaskByDilation().

=head2 pixWordMaskByDilation

l_int32 pixWordMaskByDilation ( PIX *pixs, l_int32 maxdil, PIX **ppixm, l_int32 *psize )

  pixWordMaskByDilation()

      Input:  pixs (1 bpp; typ. at 75 to 150 ppi)
              maxdil (maximum dilation; 0 for default; warning if > 20)
              &mask (<optional return> dilated word mask)
              &size (<optional return> size of optimal horiz Sel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This gives a crude estimate of the word masks.  See
          pixWordBoxesByDilation() for further filtering of the word boxes.
      (2) For 75 to 150 ppi, the optimal dilation will be between 5 and 11.
          For 200 to 300 ppi, it is advisable to use a larger value
          for @maxdil, say between 10 and 20.  Setting maxdil <= 0
          results in a default dilation of 16.
      (3) The best size for dilating to get word masks is optionally returned.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
