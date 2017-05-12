package Image::Leptonica::Func::rotateam;
$Image::Leptonica::Func::rotateam::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rotateam

=head1 VERSION

version 0.04

=head1 C<rotateam.c>

  rotateam.c

     Grayscale and color rotation for area mapping (== interpolation)

         Rotation about the image center
                  PIX     *pixRotateAM()
                  PIX     *pixRotateAMColor()
                  PIX     *pixRotateAMGray()

         Rotation about the UL corner of the image
                  PIX     *pixRotateAMCorner()
                  PIX     *pixRotateAMColorCorner()
                  PIX     *pixRotateAMGrayCorner()

         Faster color rotation about the image center
                  PIX     *pixRotateAMColorFast()

     Rotations are measured in radians; clockwise is positive.

     The basic area mapping grayscale rotation works on 8 bpp images.
     For color, the same method is applied to each color separately.
     This can be done in two ways: (1) as here, computing each dest
     rgb pixel from the appropriate four src rgb pixels, or (2) separating
     the color image into three 8 bpp images, rotate each of these,
     and then combine the result.  Method (1) is about 2.5x faster.
     We have also implemented a fast approximation for color area-mapping
     rotation (pixRotateAMColorFast()), which is about 25% faster
     than the standard color rotator.  If you need the extra speed,
     use it.

     Area mapping works as follows.  For each dest
     pixel you find the 4 source pixels that it partially
     covers.  You then compute the dest pixel value as
     the area-weighted average of those 4 source pixels.
     We make two simplifying approximations:

       -  For simplicity, compute the areas as if the dest
          pixel were translated but not rotated.

       -  Compute area overlaps on a discrete sub-pixel grid.
          Because we are using 8 bpp images with 256 levels,
          it is convenient to break each pixel into a
          16x16 sub-pixel grid, and count the number of
          overlapped sub-pixels.

     It is interesting to note that the digital filter that
     implements the area mapping algorithm for rotation
     is identical to the digital filter used for linear
     interpolation when arbitrarily scaling grayscale images.

     The advantage of area mapping over pixel sampling
     in grayscale rotation is that the former naturally
     blurs sharp edges ("anti-aliasing"), so that stair-step
     artifacts are not introduced.  The disadvantage is that
     it is significantly slower.

     But it is still pretty fast.  With standard 3 GHz hardware,
     the anti-aliased (area-mapped) color rotation speed is
     about 15 million pixels/sec.

     The function pixRotateAMColorFast() is about 10-20% faster
     than pixRotateAMColor().  The quality is slightly worse,
     and if you make many successive small rotations, with a
     total angle of 360 degrees, it has been noted that the
     center wanders -- it seems to be doing a 1 pixel translation
     in addition to the rotation.

=head1 FUNCTIONS

=head2 pixRotateAM

PIX * pixRotateAM ( PIX *pixs, l_float32 angle, l_int32 incolor )

  pixRotateAM()

      Input:  pixs (2, 4, 8 bpp gray or colormapped, or 32 bpp RGB)
              angle (radians; clockwise is positive)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Rotates about image center.
      (2) A positive angle gives a clockwise rotation.
      (3) Brings in either black or white pixels from the boundary.

=head2 pixRotateAMColor

PIX * pixRotateAMColor ( PIX *pixs, l_float32 angle, l_uint32 colorval )

  pixRotateAMColor()

      Input:  pixs (32 bpp)
              angle (radians; clockwise is positive)
              colorval (e.g., 0 to bring in BLACK, 0xffffff00 for WHITE)
      Return: pixd, or null on error

  Notes:
      (1) Rotates about image center.
      (2) A positive angle gives a clockwise rotation.
      (3) Specify the color to be brought in from outside the image.

=head2 pixRotateAMColorCorner

PIX * pixRotateAMColorCorner ( PIX *pixs, l_float32 angle, l_uint32 fillval )

  pixRotateAMColorCorner()

      Input:  pixs
              angle (radians; clockwise is positive)
              colorval (e.g., 0 to bring in BLACK, 0xffffff00 for WHITE)
      Return: pixd, or null on error

  Notes:
      (1) Rotates the image about the UL corner.
      (2) A positive angle gives a clockwise rotation.
      (3) Specify the color to be brought in from outside the image.

=head2 pixRotateAMColorFast

PIX * pixRotateAMColorFast ( PIX *pixs, l_float32 angle, l_uint32 colorval )

  pixRotateAMColorFast()

      Input:  pixs
              angle (radians; clockwise is positive)
              colorval (e.g., 0 to bring in BLACK, 0xffffff00 for WHITE)
      Return: pixd, or null on error

  Notes:
      (1) This rotates a color image about the image center.
      (2) A positive angle gives a clockwise rotation.
      (3) It uses area mapping, dividing each pixel into
          16 subpixels.
      (4) It is about 10% to 20% faster than the more accurate linear
          interpolation function pixRotateAMColor(),
          which uses 256 subpixels.
      (5) For some reason it shifts the image center.
          No attempt is made to rotate the alpha component.

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixRotateAMCorner

PIX * pixRotateAMCorner ( PIX *pixs, l_float32 angle, l_int32 incolor )

  pixRotateAMCorner()

      Input:  pixs (1, 2, 4, 8 bpp gray or colormapped, or 32 bpp RGB)
              angle (radians; clockwise is positive)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Rotates about the UL corner of the image.
      (2) A positive angle gives a clockwise rotation.
      (3) Brings in either black or white pixels from the boundary.

=head2 pixRotateAMGray

PIX * pixRotateAMGray ( PIX *pixs, l_float32 angle, l_uint8 grayval )

  pixRotateAMGray()

      Input:  pixs (8 bpp)
              angle (radians; clockwise is positive)
              grayval (0 to bring in BLACK, 255 for WHITE)
      Return: pixd, or null on error

  Notes:
      (1) Rotates about image center.
      (2) A positive angle gives a clockwise rotation.
      (3) Specify the grayvalue to be brought in from outside the image.

=head2 pixRotateAMGrayCorner

PIX * pixRotateAMGrayCorner ( PIX *pixs, l_float32 angle, l_uint8 grayval )

  pixRotateAMGrayCorner()

      Input:  pixs
              angle (radians; clockwise is positive)
              grayval (0 to bring in BLACK, 255 for WHITE)
      Return: pixd, or null on error

  Notes:
      (1) Rotates the image about the UL corner.
      (2) A positive angle gives a clockwise rotation.
      (3) Specify the grayvalue to be brought in from outside the image.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
