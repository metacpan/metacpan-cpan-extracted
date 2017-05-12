package Image::Leptonica::Func::flipdetect;
$Image::Leptonica::Func::flipdetect::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::flipdetect

=head1 VERSION

version 0.04

=head1 C<flipdetect.c>

  flipdetect.c

      Page orientation detection (pure rotation by 90 degree increments):
          l_int32      pixOrientDetect()
          l_int32      makeOrientDecision()
          l_int32      pixUpDownDetect()
          l_int32      pixUpDownDetectGeneral()
          l_int32      pixOrientDetectDwa()
          l_int32      pixUpDownDetectDwa()
          l_int32      pixUpDownDetectGeneralDwa()

      Page mirror detection (flip 180 degrees about line in plane of image):
          l_int32      pixMirrorDetect()
          l_int32      pixMirrorDetectDwa()

      Static debug helper
          void         pixDebugFlipDetect()

  ===================================================================

  Page transformation detection:

  Once a page is deskewed, there are 8 possible states that it
  can be in, shown symbolically below.  Suppose state 0 is correct.

      0: correct     1          2          3
      +------+   +------+   +------+   +------+
      | **** |   | *    |   | **** |   |    * |
      | *    |   | *    |   |    * |   |    * |
      | *    |   | **** |   |    * |   | **** |
      +------+   +------+   +------+   +------+

         4          5          6          7
      +-----+    +-----+    +-----+    +-----+
      | *** |    |   * |    | *** |    | *   |
      |   * |    |   * |    | *   |    | *   |
      |   * |    |   * |    | *   |    | *   |
      |   * |    | *** |    | *   |    | *** |
      +-----+    +-----+    +-----+    +-----+

  Each of the other seven can be derived from state 0 by applying some
  combination of a 90 degree clockwise rotation, a flip about
  a horizontal line, and a flip about a vertical line,
  all abbreviated as:
      R = Rotation (about a line perpendicular to the image)
      H = Horizontal flip (about a vertical line in the plane of the image)
      V = Vertical flip (about a horizontal line in the plane of the image)

  We get these transformations:
      RHV
      000  -> 0
      001  -> 1
      010  -> 2
      011  -> 3
      100  -> 4
      101  -> 5
      110  -> 6
      111  -> 7

  Note that in four of these, the sum of H and V is 1 (odd).
  For these four, we have a change in parity (handedness) of
  the image, and the transformation cannot be performed by
  rotation about a vertical line out of the page.   Under
  rotation R, the set of 8 transformations decomposes into
  two subgroups linking {0, 3, 4, 7} and {1, 2, 5, 6} independently.

  pixOrientDetect*() tests for a pure rotation (0, 90, 180, 270 degrees).
  It doesn't change parity.

  pixMirrorDetect*() tests for a horizontal flip about the vertical axis.
  It changes parity.

  The landscape/portrait rotation can be detected in two ways:

    (1) Compute the deskew confidence for an image segment,
        both as is and rotated 90 degrees  (see skew.c).

    (2) Compute the ascender/descender signal for the image,
        both as is and rotated 90 degrees  (implemented here).

  The ascender/descender signal is useful for determining text
  orientation in Roman alphabets because the incidence of letters
  with straight-line ascenders (b, d, h, k, l, <t>) outnumber
  those with descenders (<g>, p, q).  The letters <t> and <g>
  will respond variably to the filter, depending on the type face.

  What about the mirror image situations?  These aren't common
  unless you're dealing with film, for example.
  But you can reliably test if the image has undergone a
  parity-changing flip once about some axis in the plane
  of the image, using pixMirrorDetect*().  This works ostensibly by
  counting the number of characters with ascenders that
  stick out to the left and right of the ascender.  Characters
  that are not mirror flipped are more likely to extend to the
  right (b, h, k) than to the left (d).  Of course, that is for
  text that is rightside-up.  So before you apply the mirror
  test, it is necessary to insure that the text has the ascenders
  going up, and not down or to the left or right.  But here's
  what *really* happens.  It turns out that the pre-filtering before
  the hit-miss transform (HMT) is crucial, and surprisingly, when
  the pre-filtering is chosen to generate a large signal, the majority
  of the signal comes from open regions of common lower-case
  letters such as 'e', 'c' and 'f'.

  All operations are given in two implementations whose results are
  identical: rasterop morphology and dwa morphology.  The dwa
  implementations are between 2x and 3x faster.

  The set of operations you actually use depends on your prior knowledge:

  (1) If the page is known to be either rightside-up or upside-down, use
      either pixOrientDetect*() with pleftconf = NULL, or
      pixUpDownDetect*().   [The '*' refers to either the rasterop
      or dwa versions.]

  (2) If any of the four orientations are possible, use pixOrientDetect*().

  (3) If the text is horizontal and rightside-up, the only remaining
      degree of freedom is a left-right mirror flip: use
      pixMirrorDetect*().

  (4) If you have a relatively large amount of numbers on the page,
      us the slower pixUpDownDetectGeneral().

  We summarize the full orientation and mirror flip detection process:

  (1) First determine which of the four 90 degree rotations
      causes the text to be rightside-up.  This can be done
      with either skew confidence or the pixOrientDetect*()
      signals.  For the latter, see the table for pixOrientDetect().

  (2) Then, with ascenders pointing up, apply pixMirrorDetect*().
      In the normal situation the confidence confidence will be
      large and positive.  However, if mirror flipped, the
      confidence will be large and negative.

=head1 FUNCTIONS

=head2 makeOrientDecision

l_int32 makeOrientDecision ( l_float32 upconf, l_float32 leftconf, l_float32 minupconf, l_float32 minratio, l_int32 *porient, l_int32 debug )

  makeOrientDecision()

      Input:  upconf (nonzero)
              leftconf (nonzero)
              minupconf (minimum value for which a decision can be made)
              minratio (minimum conf ratio required for a decision)
              &orient (<return> text orientation enum {0,1,2,3,4})
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This can be run after pixOrientDetect()
      (2) Both upconf and leftconf must be nonzero; otherwise the
          orientation cannot be determined.
      (3) The abs values of the input confidences are compared to
          minupconf.
      (4) The abs value of the largest of (upconf/leftconf) and
          (leftconf/upconf) is compared with minratio.
      (5) Input 0.0 for the default values for minupconf and minratio.
      (6) The return value of orient is interpreted thus:
            L_TEXT_ORIENT_UNKNOWN:  not enough evidence to determine
            L_TEXT_ORIENT_UP:       text rightside-up
            L_TEXT_ORIENT_LEFT:     landscape, text up facing left
            L_TEXT_ORIENT_DOWN:     text upside-down
            L_TEXT_ORIENT_RIGHT:    landscape, text up facing right

=head2 pixMirrorDetect

l_int32 pixMirrorDetect ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 debug )

  pixMirrorDetect()

      Input:  pixs (1 bpp, deskewed, English text)
              &conf (<return> confidence that text is not LR mirror reversed)
              mincount (min number of left + right; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) For this test, it is necessary that the text is horizontally
          oriented, with ascenders going up.
      (2) conf is the normalized difference between the number of
          right and left facing characters with ascenders.
          Left-facing are {d}; right-facing are {b, h, k}.
          At least that was the expectation.  In practice, we can
          really just say that it is the normalized difference in
          hits using two specific hit-miss filters, textsel1 and textsel2,
          after the image has been suitably pre-filtered so that
          these filters are effective.  See (4) for what's really happening.
      (3) A large positive conf value indicates normal text, whereas
          a large negative conf value means the page is mirror reversed.
      (4) The implementation is a bit tricky.  The general idea is
          to fill the x-height part of characters, but not the space
          between them, before doing the HMT.  This is done by
          finding pixels added using two different operations -- a
          horizontal close and a vertical dilation -- and adding
          the intersection of these sets to the original.  It turns
          out that the original intuition about the signal was largely
          in error: much of the signal for right-facing characters
          comes from the lower part of common x-height characters, like
          the e and c, that remain open after these operations.
          So it's important that the operations to close the x-height
          parts of the characters are purposely weakened sufficiently
          to allow these characters to remain open.  The wonders
          of morphology!

=head2 pixMirrorDetectDwa

l_int32 pixMirrorDetectDwa ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 debug )

  pixMirrorDetectDwa()

      Input:  pixs (1 bpp, deskewed, English text)
              &conf (<return> confidence that text is not LR mirror reversed)
              mincount (min number of left + right; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) We assume the text is horizontally oriented, with
          ascenders going up.
      (2) See notes in pixMirrorDetect().

=head2 pixOrientDetect

l_int32 pixOrientDetect ( PIX *pixs, l_float32 *pupconf, l_float32 *pleftconf, l_int32 mincount, l_int32 debug )

  pixOrientDetect()

      Input:  pixs (1 bpp, deskewed, English text, 150 - 300 ppi)
              &upconf (<optional return> ; may be null)
              &leftconf (<optional return> ; may be null)
              mincount (min number of up + down; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See "Measuring document image skew and orientation"
          Dan S. Bloomberg, Gary E. Kopec and Lakshmi Dasari
          IS&T/SPIE EI'95, Conference 2422: Document Recognition II
          pp 302-316, Feb 6-7, 1995, San Jose, CA
      (2) upconf is the normalized difference between up ascenders
          and down ascenders.  The image is analyzed without rotation
          for being rightside-up or upside-down.  Set &upconf to null
          to skip this operation.
      (3) leftconf is the normalized difference between up ascenders
          and down ascenders in the image after it has been
          rotated 90 degrees clockwise.  With that rotation, ascenders
          projecting to the left in the source image will project up
          in the rotated image.  We compute this by rotating 90 degrees
          clockwise and testing for up and down ascenders.  Set
          &leftconf to null to skip this operation.
      (4) Note that upconf and leftconf are not linear measures of
          confidence, e.g., in a range between 0 and 100.  They
          measure how far you are out on the tail of a (presumably)
          normal distribution.  For example, a confidence of 10 means
          that it is nearly certain that the difference did not
          happen at random.  However, these values must be interpreted
          cautiously, taking into consideration the estimated prior
          for a particular orientation or mirror flip.   The up-down
          signal is very strong if applied to text with ascenders
          up and down, and relatively weak for text at 90 degrees,
          but even at 90 degrees, the difference can look significant.
          For example, suppose the ascenders are oriented horizontally,
          but the test is done vertically.  Then upconf can
          be < -MIN_CONF_FOR_UP_DOWN, suggesting the text may be
          upside-down.  However, if instead the test were done
          horizontally, leftconf will be very much larger
          (in absolute value), giving the correct orientation.
      (5) If you compute both upconf and leftconf, and there is
          sufficient signal, the following table determines the
          cw angle necessary to rotate pixs so that the text is
          rightside-up:
             0 deg :           upconf >> 1,    abs(upconf) >> abs(leftconf)
             90 deg :          leftconf >> 1,  abs(leftconf) >> abs(upconf)
             180 deg :         upconf << -1,   abs(upconf) >> abs(leftconf)
             270 deg :         leftconf << -1, abs(leftconf) >> abs(upconf)
      (6) One should probably not interpret the direction unless
          there are a sufficient number of counts for both orientations,
          in which case neither upconf nor leftconf will be 0.0.
      (7) Uses rasterop implementation of HMT.

=head2 pixOrientDetectDwa

l_int32 pixOrientDetectDwa ( PIX *pixs, l_float32 *pupconf, l_float32 *pleftconf, l_int32 mincount, l_int32 debug )

  pixOrientDetectDwa()

      Input:  pixs (1 bpp, deskewed, English text)
              &upconf (<optional return> ; may be null)
              &leftconf (<optional return> ; may be null)
              mincount (min number of up + down; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Same interface as for pixOrientDetect().  See notes
          there for usage.
      (2) Uses auto-gen'd code for the Sels defined at the
          top of this file, with some renaming of functions.
          The auto-gen'd code is in fliphmtgen.c, and can
          be generated by a simple executable; see prog/flipselgen.c.
      (3) This runs about 2.5 times faster than the pixOrientDetect().

=head2 pixUpDownDetect

l_int32 pixUpDownDetect ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 debug )

  pixUpDownDetect()

      Input:  pixs (1 bpp, deskewed, English text, 150 - 300 ppi)
              &conf (<return> confidence that text is rightside-up)
              mincount (min number of up + down; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Special (typical, slightly faster) case, where the pixels
          identified through the HMT (hit-miss transform) are not
          clipped by a truncated word mask pixm.  See pixOrientDetect()
          and pixUpDownDetectGeneral() for details.
      (2) The returned confidence is the normalized difference
          between the number of detected up and down ascenders,
          assuming that the text is either rightside-up or upside-down
          and not rotated at a 90 degree angle.

=head2 pixUpDownDetectDwa

l_int32 pixUpDownDetectDwa ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 debug )

  pixUpDownDetectDwa()

      Input:  pixs (1 bpp, deskewed, English text, 150 - 300 ppi)
              &conf (<return> confidence that text is rightside-up)
              mincount (min number of up + down; use 0 for default)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Faster (DWA) version of pixUpDownDetect().
      (2) This is a special case (but typical and slightly faster) of
          pixUpDownDetectGeneralDwa(), where the pixels identified
          through the HMT (hit-miss transform) are not clipped by
          a truncated word mask pixm.  See pixUpDownDetectGeneral()
          for usage and other details.
      (3) The returned confidence is the normalized difference
          between the number of detected up and down ascenders,
          assuming that the text is either rightside-up or upside-down
          and not rotated at a 90 degree angle.

=head2 pixUpDownDetectGeneral

l_int32 pixUpDownDetectGeneral ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 npixels, l_int32 debug )

  pixUpDownDetectGeneral()

      Input:  pixs (1 bpp, deskewed, English text, 150 - 300 ppi)
              &conf (<return> confidence that text is rightside-up)
              mincount (min number of up + down; use 0 for default)
              npixels (number of pixels removed from each side of word box)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See pixOrientDetect() for other details.
      (2) @conf is the normalized difference between the number of
          detected up and down ascenders, assuming that the text
          is either rightside-up or upside-down and not rotated
          at a 90 degree angle.
      (3) The typical mode of operation is @npixels == 0.
          If @npixels > 0, this removes HMT matches at the
          beginning and ending of "words."  This is useful for
          pages that may have mostly digits, because if npixels == 0,
          leading "1" and "3" digits can register as having
          ascenders or descenders, and "7" digits can match descenders.
          Consequently, a page image of only digits may register
          as being upside-down.
      (4) We want to count the number of instances found using the HMT.
          An expensive way to do this would be to count the
          number of connected components.  A cheap way is to do a rank
          reduction cascade that reduces each component to a single
          pixel, and results (after two or three 2x reductions)
          in one pixel for each of the original components.
          After the reduction, you have a much smaller pix over
          which to count pixels.  We do only 2 reductions, because
          this function is designed to work for input pix between
          150 and 300 ppi, and an 8x reduction on a 150 ppi image
          is going too far -- components will get merged.

=head2 pixUpDownDetectGeneralDwa

l_int32 pixUpDownDetectGeneralDwa ( PIX *pixs, l_float32 *pconf, l_int32 mincount, l_int32 npixels, l_int32 debug )

  pixUpDownDetectGeneralDwa()

      Input:  pixs (1 bpp, deskewed, English text)
              &conf (<return> confidence that text is rightside-up)
              mincount (min number of up + down; use 0 for default)
              npixels (number of pixels removed from each side of word box)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See the notes in pixUpDownDetectGeneral() for usage.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
