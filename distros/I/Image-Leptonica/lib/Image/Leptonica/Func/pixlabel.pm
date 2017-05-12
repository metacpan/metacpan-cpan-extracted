package Image::Leptonica::Func::pixlabel;
$Image::Leptonica::Func::pixlabel::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixlabel

=head1 VERSION

version 0.04

=head1 C<pixlabel.c>

  pixlabel.c

     Label pixels by an index for connected component membership
           PIX         *pixConnCompTransform()

     Label pixels by the area of their connected component
           PIX         *pixConnCompAreaTransform()

     Label pixels with spatially-dependent color coding
           PIX         *pixLocToColorTransform()

  Pixels get labelled in various ways throughout the leptonica library,
  but most of the labelling is implicit, where the new value isn't
  even considered to be a label -- it is just a transformed pixel value
  that may be transformed again by another operation.  Quantization
  by thresholding, and dilation by a structuring element, are examples
  of these typical image processing operations.

  However, there are some explicit labelling procedures that are useful
  as end-points of analysis, where it typically would not make sense
  to do further image processing on the result.  Assigning false color
  based on pixel properties is an example of such labelling operations.
  Such operations typically have 1 bpp input images, and result
  in grayscale or color images.

  The procedures in this file are concerned with such explicit labelling.
  Some of these labelling procedures are also in other places in leptonica:

    runlength.c:
       This file has two labelling transforms based on runlengths:
       pixStrokeWidthTransform() and pixvRunlengthTransform().
       The pixels are labelled based on the width of the "stroke" to
       which they belong, or on the length of the horizontal or
       vertical run in which they are a member.  Runlengths can easily
       be filtered using a threshold.

    pixafunc2.c:
       This file has an operation, pixaDisplayRandomCmap(), that
       randomly labels pix in a pixa (that are typically found using
       pixConnComp) with up to 256 values, and assigns each value to
       a random colormap color.

    seedfill.c:
       This file has pixDistanceFunction(), that labels each pixel with
       its distance from either the foreground or the background.

=head1 FUNCTIONS

=head2 pixConnCompAreaTransform

PIX * pixConnCompAreaTransform ( PIX *pixs, l_int32 connect )

  pixConnCompAreaTransform()

      Input:   pixs (1 bpp)
               connect (connectivity: 4 or 8)
      Return:  pixd (16 bpp), or null on error

  Notes:
      (1) The pixel values in pixd label the area of the fg component
          to which the pixel belongs.  Pixels in the bg are labelled 0.
      (2) The pixel values cannot exceed 2^16 - 1, even if the area
          of the c.c. is larger.
      (3) For purposes of visualization, the output can be converted
          to 8 bpp, using pixConvert16To8() or pixMaxDynamicRange().

=head2 pixConnCompTransform

PIX * pixConnCompTransform ( PIX *pixs, l_int32 connect, l_int32 depth )

  pixConnCompTransform()

      Input:   pixs (1 bpp)
               connect (connectivity: 4 or 8)
               depth (of pixd: 8 or 16 bpp; use 0 for auto determination)
      Return:  pixd (8 or 16 bpp), or null on error

  Notes:
      (1) pixd is 8 or 16 bpp, and the pixel values label the fg component,
          starting with 1.  Pixels in the bg are labelled 0.
      (2) If @depth = 0, the depth of pixd is 8 if the number of c.c.
          is less than 254, and 16 otherwise.
      (3) If @depth = 8, the assigned label for the n-th component is
          1 + n % 254.  We use mod 254 because 0 is uniquely assigned
          to black: e.g., see pixcmapCreateRandom().  Likewise,
          if @depth = 16, the assigned label uses mod(2^16 - 2).

=head2 pixLocToColorTransform

PIX * pixLocToColorTransform ( PIX *pixs )

  pixLocToColorTransform()

      Input:   pixs (1 bpp)
      Return:  pixd (32 bpp rgb), or null on error

  Notes:
      (1) This generates an RGB image where each component value
          is coded depending on the (x.y) location and the size
          of the fg connected component that the pixel in pixs belongs to.
          It is independent of the 4-fold orthogonal orientation, and
          only weakly depends on translations and small angle rotations.
          Background pixels are black.
      (2) Such encodings can be compared between two 1 bpp images
          by performing this transform and calculating the
          "earth-mover" distance on the resulting R,G,B histograms.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
