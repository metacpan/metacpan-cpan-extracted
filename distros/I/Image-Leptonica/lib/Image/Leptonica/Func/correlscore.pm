package Image::Leptonica::Func::correlscore;
$Image::Leptonica::Func::correlscore::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::correlscore

=head1 VERSION

version 0.04

=head1 C<correlscore.c>

 correlscore.c

     These are functions for computing correlation between
     pairs of 1 bpp images.

     Optimized 2 pix correlators (for jbig2 clustering)
         l_int32     pixCorrelationScore()
         l_int32     pixCorrelationScoreThresholded()

     Simple 2 pix correlators
         l_int32     pixCorrelationScoreSimple()
         l_int32     pixCorrelationScoreShifted()

     There are other, more application-oriented functions, that
     compute the correlation between two binary images, taking into
     account small translational shifts, between two binary images.
     These are:
         compare.c:     pixBestCorrelation()
                        Uses coarse-to-fine translations of full image
         recogident.c:  pixCorrelationBestShift()
                        Uses small shifts between c.c. centroids.

=head1 FUNCTIONS

=head2 pixCorrelationScore

l_int32 pixCorrelationScore ( PIX *pix1, PIX *pix2, l_int32 area1, l_int32 area2, l_float32 delx, l_float32 dely, l_int32 maxdiffw, l_int32 maxdiffh, l_int32 *tab, l_float32 *pscore )

  pixCorrelationScore()

      Input:  pix1   (test pix, 1 bpp)
              pix2   (exemplar pix, 1 bpp)
              area1  (number of on pixels in pix1)
              area2  (number of on pixels in pix2)
              delx   (x comp of centroid difference)
              dely   (y comp of centroid difference)
              maxdiffw (max width difference of pix1 and pix2)
              maxdiffh (max height difference of pix1 and pix2)
              tab    (sum tab for byte)
              &score (<return> correlation score)
      Return: 0 if OK, 1 on error

  Note: we check first that the two pix are roughly the same size.
  For jbclass (jbig2) applications at roughly 300 ppi, maxdiffw and
  maxdiffh should be at least 2.

  Only if they meet that criterion do we compare the bitmaps.
  The centroid difference is used to align the two images to the
  nearest integer for the correlation.

  The correlation score is the ratio of the square of the number of
  pixels in the AND of the two bitmaps to the product of the number
  of ON pixels in each.  Denote the number of ON pixels in pix1
  by |1|, the number in pix2 by |2|, and the number in the AND
  of pix1 and pix2 by |1 & 2|.  The correlation score is then
  (|1 & 2|)**2 / (|1|*|2|).

  This score is compared with an input threshold, which can
  be modified depending on the weight of the template.
  The modified threshold is
     thresh + (1.0 - thresh) * weight * R
  where
     weight is a fixed input factor between 0.0 and 1.0
     R = |2| / area(2)
  and area(2) is the total number of pixels in 2 (i.e., width x height).

  To understand why a weight factor is useful, consider what happens
  with thick, sans-serif characters that look similar and have a value
  of R near 1.  Different characters can have a high correlation value,
  and the classifier will make incorrect substitutions.  The weight
  factor raises the threshold for these characters.

  Yet another approach to reduce such substitutions is to run the classifier
  in a non-greedy way, matching to the template with the highest
  score, not the first template with a score satisfying the matching
  constraint.  However, this is not particularly effective.

  The implementation here gives the same result as in
  pixCorrelationScoreSimple(), where a temporary Pix is made to hold
  the AND and implementation uses rasterop:
      pixt = pixCreateTemplate(pix1);
      pixRasterop(pixt, idelx, idely, wt, ht, PIX_SRC, pix2, 0, 0);
      pixRasterop(pixt, 0, 0, wi, hi, PIX_SRC & PIX_DST, pix1, 0, 0);
      pixCountPixels(pixt, &count, tab);
      pixDestroy(&pixt);
  However, here it is done in a streaming fashion, counting as it goes,
  and touching memory exactly once, giving a 3-4x speedup over the
  simple implementation.  This very fast correlation matcher was
  contributed by William Rucklidge.

=head2 pixCorrelationScoreShifted

l_int32 pixCorrelationScoreShifted ( PIX *pix1, PIX *pix2, l_int32 area1, l_int32 area2, l_int32 delx, l_int32 dely, l_int32 *tab, l_float32 *pscore )

  pixCorrelationScoreShifted()

      Input:  pix1   (1 bpp)
              pix2   (1 bpp)
              area1  (number of on pixels in pix1)
              area2  (number of on pixels in pix2)
              delx (x translation of pix2 relative to pix1)
              dely (y translation of pix2 relative to pix1)
              tab    (sum tab for byte)
              &score (<return> correlation score)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This finds the correlation between two 1 bpp images,
          when pix2 is shifted by (delx, dely) with respect
          to each other.
      (2) This is implemented by starting with a copy of pix1 and
          ANDing its pixels with those of a shifted pix2.
      (3) Get the pixel counts for area1 and area2 using piCountPixels().
      (4) A good estimate for a shift that would maximize the correlation
          is to align the centroids (cx1, cy1; cx2, cy2), giving the
          relative translations etransx and etransy:
             etransx = cx1 - cx2
             etransy = cy1 - cy2
          Typically delx is chosen to be near etransx; ditto for dely.
          This function is used in pixBestCorrelation(), where the
          translations delx and dely are varied to find the best alignment.
      (5) We do not check the sizes of pix1 and pix2, because they should
          be comparable.

=head2 pixCorrelationScoreSimple

l_int32 pixCorrelationScoreSimple ( PIX *pix1, PIX *pix2, l_int32 area1, l_int32 area2, l_float32 delx, l_float32 dely, l_int32 maxdiffw, l_int32 maxdiffh, l_int32 *tab, l_float32 *pscore )

  pixCorrelationScoreSimple()

      Input:  pix1   (test pix, 1 bpp)
              pix2   (exemplar pix, 1 bpp)
              area1  (number of on pixels in pix1)
              area2  (number of on pixels in pix2)
              delx   (x comp of centroid difference)
              dely   (y comp of centroid difference)
              maxdiffw (max width difference of pix1 and pix2)
              maxdiffh (max height difference of pix1 and pix2)
              tab    (sum tab for byte)
              &score (<return> correlation score, in range [0.0 ... 1.0])
      Return: 0 if OK, 1 on error

  Notes:
      (1) This calculates exactly the same value as pixCorrelationScore().
          It is 2-3x slower, but much simpler to understand.
      (2) The returned correlation score is 0.0 if the width or height
          exceed @maxdiffw or @maxdiffh.

=head2 pixCorrelationScoreThresholded

l_int32 pixCorrelationScoreThresholded ( PIX *pix1, PIX *pix2, l_int32 area1, l_int32 area2, l_float32 delx, l_float32 dely, l_int32 maxdiffw, l_int32 maxdiffh, l_int32 *tab, l_int32 *downcount, l_float32 score_threshold )

  pixCorrelationScoreThresholded()

      Input:  pix1   (test pix, 1 bpp)
              pix2   (exemplar pix, 1 bpp)
              area1  (number of on pixels in pix1)
              area2  (number of on pixels in pix2)
              delx   (x comp of centroid difference)
              dely   (y comp of centroid difference)
              maxdiffw (max width difference of pix1 and pix2)
              maxdiffh (max height difference of pix1 and pix2)
              tab    (sum tab for byte)
              downcount (count of 1 pixels below each row of pix1)
              score_threshold
      Return: whether the correlation score is >= score_threshold


  Note: we check first that the two pix are roughly the same size.
  Only if they meet that criterion do we compare the bitmaps.
  The centroid difference is used to align the two images to the
  nearest integer for the correlation.

  The correlation score is the ratio of the square of the number of
  pixels in the AND of the two bitmaps to the product of the number
  of ON pixels in each.  Denote the number of ON pixels in pix1
  by |1|, the number in pix2 by |2|, and the number in the AND
  of pix1 and pix2 by |1 & 2|.  The correlation score is then
  (|1 & 2|)**2 / (|1|*|2|).

  This score is compared with an input threshold, which can
  be modified depending on the weight of the template.
  The modified threshold is
     thresh + (1.0 - thresh) * weight * R
  where
     weight is a fixed input factor between 0.0 and 1.0
     R = |2| / area(2)
  and area(2) is the total number of pixels in 2 (i.e., width x height).

  To understand why a weight factor is useful, consider what happens
  with thick, sans-serif characters that look similar and have a value
  of R near 1.  Different characters can have a high correlation value,
  and the classifier will make incorrect substitutions.  The weight
  factor raises the threshold for these characters.

  Yet another approach to reduce such substitutions is to run the classifier
  in a non-greedy way, matching to the template with the highest
  score, not the first template with a score satisfying the matching
  constraint.  However, this is not particularly effective.

  This very fast correlation matcher was contributed by William Rucklidge.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
