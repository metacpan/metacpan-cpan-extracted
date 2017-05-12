package Image::Leptonica::Func::shear;
$Image::Leptonica::Func::shear::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::shear

=head1 VERSION

version 0.04

=head1 C<shear.c>

  shear.c

    About arbitrary lines
           PIX      *pixHShear()
           PIX      *pixVShear()

    About special 'points': UL corner and center
           PIX      *pixHShearCorner()
           PIX      *pixVShearCorner()
           PIX      *pixHShearCenter()
           PIX      *pixVShearCenter()

    In place about arbitrary lines
           l_int32   pixHShearIP()
           l_int32   pixVShearIP()

    Linear interpolated shear about arbitrary lines
           PIX      *pixHShearLI()
           PIX      *pixVShearLI()

    Static helper
      static l_float32  normalizeAngleForShear()

=head1 FUNCTIONS

=head2 pixHShear

PIX * pixHShear ( PIX *pixd, PIX *pixs, l_int32 yloc, l_float32 radang, l_int32 incolor )

  pixHShear()

      Input:  pixd (<optional>, this can be null, equal to pixs,
                    or different from pixs)
              pixs (no restrictions on depth)
              yloc (location of horizontal line, measured from origin)
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, always

  Notes:
      (1) There are 3 cases:
            (a) pixd == null (make a new pixd)
            (b) pixd == pixs (in-place)
            (c) pixd != pixs
      (2) For these three cases, use these patterns, respectively:
              pixd = pixHShear(NULL, pixs, ...);
              pixHShear(pixs, pixs, ...);
              pixHShear(pixd, pixs, ...);
      (3) This shear leaves the horizontal line of pixels at y = yloc
          invariant.  For a positive shear angle, pixels above this
          line are shoved to the right, and pixels below this line
          move to the left.
      (4) With positive shear angle, this can be used, along with
          pixVShear(), to perform a cw rotation, either with 2 shears
          (for small angles) or in the general case with 3 shears.
      (5) Changing the value of yloc is equivalent to translating
          the result horizontally.
      (6) This brings in 'incolor' pixels from outside the image.
      (7) For in-place operation, pixs cannot be colormapped,
          because the in-place operation only blits in 0 or 1 bits,
          not an arbitrary colormap index.
      (8) The angle is brought into the range [-pi, -pi].  It is
          not permitted to be within MIN_DIFF_FROM_HALF_PI radians
          from either -pi/2 or pi/2.

=head2 pixHShearCenter

PIX * pixHShearCenter ( PIX *pixd, PIX *pixs, l_float32 radang, l_int32 incolor )

  pixHShearCenter()

      Input:  pixd (<optional>, if not null, must be equal to pixs)
              pixs
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, or null on error.

  Notes:
      (1) See pixHShear() for usage.
      (2) This does a horizontal shear about the center, with (+) shear
          pushing increasingly leftward (-x) with increasing y.

=head2 pixHShearCorner

PIX * pixHShearCorner ( PIX *pixd, PIX *pixs, l_float32 radang, l_int32 incolor )

  pixHShearCorner()

      Input:  pixd (<optional>, if not null, must be equal to pixs)
              pixs
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, or null on error.

  Notes:
      (1) See pixHShear() for usage.
      (2) This does a horizontal shear about the UL corner, with (+) shear
          pushing increasingly leftward (-x) with increasing y.

=head2 pixHShearIP

l_int32 pixHShearIP ( PIX *pixs, l_int32 yloc, l_float32 radang, l_int32 incolor )

  pixHShearIP()

      Input:  pixs
              yloc (location of horizontal line, measured from origin)
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place version of pixHShear(); see comments there.
      (2) This brings in 'incolor' pixels from outside the image.
      (3) pixs cannot be colormapped, because the in-place operation
          only blits in 0 or 1 bits, not an arbitrary colormap index.
      (4) Does a horizontal full-band shear about the line with (+) shear
          pushing increasingly leftward (-x) with increasing y.

=head2 pixHShearLI

PIX * pixHShearLI ( PIX *pixs, l_int32 yloc, l_float32 radang, l_int32 incolor )

  pixHShearLI()

      Input:  pixs (8 bpp or 32 bpp, or colormapped)
              yloc (location of horizontal line, measured from origin)
              angle (in radians, in range (-pi/2 ... pi/2))
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd (sheared), or null on error

  Notes:
      (1) This does horizontal shear with linear interpolation for
          accurate results on 8 bpp gray, 32 bpp rgb, or cmapped images.
          It is relatively slow compared to the sampled version
          implemented by rasterop, but the result is much smoother.
      (2) This shear leaves the horizontal line of pixels at y = yloc
          invariant.  For a positive shear angle, pixels above this
          line are shoved to the right, and pixels below this line
          move to the left.
      (3) Any colormap is removed.
      (4) The angle is brought into the range [-pi/2 + del, pi/2 - del],
          where del == MIN_DIFF_FROM_HALF_PI.

=head2 pixVShear

PIX * pixVShear ( PIX *pixd, PIX *pixs, l_int32 xloc, l_float32 radang, l_int32 incolor )

  pixVShear()

      Input:  pixd (<optional>, this can be null, equal to pixs,
                    or different from pixs)
              pixs (no restrictions on depth)
              xloc (location of vertical line, measured from origin)
              angle (in radians; not too close to +-(pi / 2))
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, or null on error

  Notes:
      (1) There are 3 cases:
            (a) pixd == null (make a new pixd)
            (b) pixd == pixs (in-place)
            (c) pixd != pixs
      (2) For these three cases, use these patterns, respectively:
              pixd = pixVShear(NULL, pixs, ...);
              pixVShear(pixs, pixs, ...);
              pixVShear(pixd, pixs, ...);
      (3) This shear leaves the vertical line of pixels at x = xloc
          invariant.  For a positive shear angle, pixels to the right
          of this line are shoved downward, and pixels to the left
          of the line move upward.
      (4) With positive shear angle, this can be used, along with
          pixHShear(), to perform a cw rotation, either with 2 shears
          (for small angles) or in the general case with 3 shears.
      (5) Changing the value of xloc is equivalent to translating
          the result vertically.
      (6) This brings in 'incolor' pixels from outside the image.
      (7) For in-place operation, pixs cannot be colormapped,
          because the in-place operation only blits in 0 or 1 bits,
          not an arbitrary colormap index.
      (8) The angle is brought into the range [-pi, -pi].  It is
          not permitted to be within MIN_DIFF_FROM_HALF_PI radians
          from either -pi/2 or pi/2.

=head2 pixVShearCenter

PIX * pixVShearCenter ( PIX *pixd, PIX *pixs, l_float32 radang, l_int32 incolor )

  pixVShearCenter()

      Input:  pixd (<optional>, if not null, must be equal to pixs)
              pixs
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, or null on error.

  Notes:
      (1) See pixVShear() for usage.
      (2) This does a vertical shear about the center, with (+) shear
          pushing increasingly downward (+y) with increasing x.

=head2 pixVShearCorner

PIX * pixVShearCorner ( PIX *pixd, PIX *pixs, l_float32 radang, l_int32 incolor )

  pixVShearCorner()

      Input:  pixd (<optional>, if not null, must be equal to pixs)
              pixs
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd, or null on error.

  Notes:
      (1) See pixVShear() for usage.
      (2) This does a vertical shear about the UL corner, with (+) shear
          pushing increasingly downward (+y) with increasing x.

=head2 pixVShearIP

l_int32 pixVShearIP ( PIX *pixs, l_int32 xloc, l_float32 radang, l_int32 incolor )

  pixVShearIP()

      Input:  pixs (all depths; not colormapped)
              xloc  (location of vertical line, measured from origin)
              angle (in radians)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place version of pixVShear(); see comments there.
      (2) This brings in 'incolor' pixels from outside the image.
      (3) pixs cannot be colormapped, because the in-place operation
          only blits in 0 or 1 bits, not an arbitrary colormap index.
      (4) Does a vertical full-band shear about the line with (+) shear
          pushing increasingly downward (+y) with increasing x.

=head2 pixVShearLI

PIX * pixVShearLI ( PIX *pixs, l_int32 xloc, l_float32 radang, l_int32 incolor )

  pixVShearLI()

      Input:  pixs (8 bpp or 32 bpp, or colormapped)
              xloc  (location of vertical line, measured from origin)
              angle (in radians, in range (-pi/2 ... pi/2))
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK);
      Return: pixd (sheared), or null on error

  Notes:
      (1) This does vertical shear with linear interpolation for
          accurate results on 8 bpp gray, 32 bpp rgb, or cmapped images.
          It is relatively slow compared to the sampled version
          implemented by rasterop, but the result is much smoother.
      (2) This shear leaves the vertical line of pixels at x = xloc
          invariant.  For a positive shear angle, pixels to the right
          of this line are shoved downward, and pixels to the left
          of the line move upward.
      (3) Any colormap is removed.
      (4) The angle is brought into the range [-pi/2 + del, pi/2 - del],
          where del == MIN_DIFF_FROM_HALF_PI.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
