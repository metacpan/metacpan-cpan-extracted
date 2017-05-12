package Image::Leptonica::Func::rotateorth;
$Image::Leptonica::Func::rotateorth::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rotateorth

=head1 VERSION

version 0.04

=head1 C<rotateorth.c>

  rotateorth.c

      Top-level rotation by multiples of 90 degrees
            PIX     *pixRotateOrth()

      180-degree rotation
            PIX     *pixRotate180()

      90-degree rotation (both directions)
            PIX     *pixRotate90()

      Left-right flip
            PIX     *pixFlipLR()

      Top-bottom flip
            PIX     *pixFlipTB()

=head1 FUNCTIONS

=head2 pixFlipLR

PIX * pixFlipLR ( PIX *pixd, PIX *pixs )

  pixFlipLR()

      Input:  pixd  (<optional>; can be null, equal to pixs,
                     or different from pixs)
              pixs (all depths)
      Return: pixd, or null on error

  Notes:
      (1) This does a left-right flip of the image, which is
          equivalent to a rotation out of the plane about a
          vertical line through the image center.
      (2) There are 3 cases for input:
          (a) pixd == null (creates a new pixd)
          (b) pixd == pixs (in-place operation)
          (c) pixd != pixs (existing pixd)
      (3) For clarity, use these three patterns, respectively:
          (a) pixd = pixFlipLR(NULL, pixs);
          (b) pixFlipLR(pixs, pixs);
          (c) pixFlipLR(pixd, pixs);
      (4) If an existing pixd is not the same size as pixs, the
          image data will be reallocated.

=head2 pixFlipTB

PIX * pixFlipTB ( PIX *pixd, PIX *pixs )

  pixFlipTB()

      Input:  pixd  (<optional>; can be null, equal to pixs,
                     or different from pixs)
              pixs (all depths)
      Return: pixd, or null on error

  Notes:
      (1) This does a top-bottom flip of the image, which is
          equivalent to a rotation out of the plane about a
          horizontal line through the image center.
      (2) There are 3 cases for input:
          (a) pixd == null (creates a new pixd)
          (b) pixd == pixs (in-place operation)
          (c) pixd != pixs (existing pixd)
      (3) For clarity, use these three patterns, respectively:
          (a) pixd = pixFlipTB(NULL, pixs);
          (b) pixFlipTB(pixs, pixs);
          (c) pixFlipTB(pixd, pixs);
      (4) If an existing pixd is not the same size as pixs, the
          image data will be reallocated.

=head2 pixRotate180

PIX * pixRotate180 ( PIX *pixd, PIX *pixs )

  pixRotate180()

      Input:  pixd  (<optional>; can be null, equal to pixs,
                     or different from pixs)
              pixs (all depths)
      Return: pixd, or null on error

  Notes:
      (1) This does a 180 rotation of the image about the center,
          which is equivalent to a left-right flip about a vertical
          line through the image center, followed by a top-bottom
          flip about a horizontal line through the image center.
      (2) There are 3 cases for input:
          (a) pixd == null (creates a new pixd)
          (b) pixd == pixs (in-place operation)
          (c) pixd != pixs (existing pixd)
      (3) For clarity, use these three patterns, respectively:
          (a) pixd = pixRotate180(NULL, pixs);
          (b) pixRotate180(pixs, pixs);
          (c) pixRotate180(pixd, pixs);

=head2 pixRotate90

PIX * pixRotate90 ( PIX *pixs, l_int32 direction )

  pixRotate90()

      Input:  pixs (all depths)
              direction (1 = clockwise,  -1 = counter-clockwise)
      Return: pixd, or null on error

  Notes:
      (1) This does a 90 degree rotation of the image about the center,
          either cw or ccw, returning a new pix.
      (2) The direction must be either 1 (cw) or -1 (ccw).

=head2 pixRotateOrth

PIX * pixRotateOrth ( PIX *pixs, l_int32 quads )

  pixRotateOrth()

      Input:  pixs (all depths)
              quads (0-3; number of 90 degree cw rotations)
      Return: pixd, or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
