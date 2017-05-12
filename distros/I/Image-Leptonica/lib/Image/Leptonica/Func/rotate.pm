package Image::Leptonica::Func::rotate;
$Image::Leptonica::Func::rotate::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rotate

=head1 VERSION

version 0.04

=head1 C<rotate.c>

  rotate.c

     General rotation about image center
              PIX     *pixRotate()
              PIX     *pixEmbedForRotation()

     General rotation by sampling
              PIX     *pixRotateBySampling()

     Nice (slow) rotation of 1 bpp image
              PIX     *pixRotateBinaryNice()

     Rotation including alpha (blend) component
              PIX     *pixRotateWithAlpha()

     Rotations are measured in radians; clockwise is positive.

     The general rotation pixRotate() does the best job for
     rotating about the image center.  For 1 bpp, it uses shear;
     for others, it uses either shear or area mapping.
     If requested, it expands the output image so that no pixels are lost
     in the rotation, and this can be done on multiple successive shears
     without expanding beyond the maximum necessary size.

=head1 FUNCTIONS

=head2 pixEmbedForRotation

PIX * pixEmbedForRotation ( PIX *pixs, l_float32 angle, l_int32 incolor, l_int32 width, l_int32 height )

  pixEmbedForRotation()

      Input:  pixs (1, 2, 4, 8, 32 bpp rgb)
              angle (radians; clockwise is positive)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
              width (original width; use 0 to avoid embedding)
              height (original height; use 0 to avoid embedding)
      Return: pixd, or null on error

  Notes:
      (1) For very small rotations, just return a clone.
      (2) Generate larger image to embed pixs if necessary, and
          place the center of the input image in the center.
      (3) Rotation brings either white or black pixels in
          from outside the image.  For colormapped images where
          there is no white or black, a new color is added if
          possible for these pixels; otherwise, either the
          lightest or darkest color is used.  In most cases,
          the colormap will be removed prior to rotation.
      (4) The dest is to be expanded so that no image pixels
          are lost after rotation.  Input of the original width
          and height allows the expansion to stop at the maximum
          required size, which is a square with side equal to
          sqrt(w*w + h*h).
      (5) For an arbitrary angle, the expansion can be found by
          considering the UL and UR corners.  As the image is
          rotated, these move in an arc centered at the center of
          the image.  Normalize to a unit circle by dividing by half
          the image diagonal.  After a rotation of T radians, the UL
          and UR corners are at points T radians along the unit
          circle.  Compute the x and y coordinates of both these
          points and take the max of absolute values; these represent
          the half width and half height of the containing rectangle.
          The arithmetic is done using formulas for sin(a+b) and cos(a+b),
          where b = T.  For the UR corner, sin(a) = h/d and cos(a) = w/d.
          For the UL corner, replace a by (pi - a), and you have
          sin(pi - a) = h/d, cos(pi - a) = -w/d.  The equations
          given below follow directly.

=head2 pixRotate

PIX * pixRotate ( PIX *pixs, l_float32 angle, l_int32 type, l_int32 incolor, l_int32 width, l_int32 height )

  pixRotate()

      Input:  pixs (1, 2, 4, 8, 32 bpp rgb)
              angle (radians; clockwise is positive)
              type (L_ROTATE_AREA_MAP, L_ROTATE_SHEAR, L_ROTATE_SAMPLING)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
              width (original width; use 0 to avoid embedding)
              height (original height; use 0 to avoid embedding)
      Return: pixd, or null on error

  Notes:
      (1) This is a high-level, simple interface for rotating images
          about their center.
      (2) For very small rotations, just return a clone.
      (3) Rotation brings either white or black pixels in
          from outside the image.
      (4) The rotation type is adjusted if necessary for the image
          depth and size of rotation angle.  For 1 bpp images, we
          rotate either by shear or sampling.
      (5) Colormaps are removed for rotation by area mapping.
      (6) The dest can be expanded so that no image pixels
          are lost.  To invoke expansion, input the original
          width and height.  For repeated rotation, use of the
          original width and height allows the expansion to
          stop at the maximum required size, which is a square
          with side = sqrt(w*w + h*h).

  *** Warning: implicit assumption about RGB component ordering 

=head2 pixRotateBinaryNice

PIX * pixRotateBinaryNice ( PIX *pixs, l_float32 angle, l_int32 incolor )

  pixRotateBinaryNice()

      Input:  pixs (1 bpp)
              angle (radians; clockwise is positive; about the center)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) For very small rotations, just return a clone.
      (2) This does a computationally expensive rotation of 1 bpp images.
          The fastest rotators (using shears or subsampling) leave
          visible horizontal and vertical shear lines across which
          the image shear changes by one pixel.  To ameliorate the
          visual effect one can introduce random dithering.  One
          way to do this in a not-too-random fashion is given here.
          We convert to 8 bpp, do a very small blur, rotate using
          linear interpolation (same as area mapping), do a
          small amount of sharpening to compensate for the initial
          blur, and threshold back to binary.  The shear lines
          are magically removed.
      (3) This operation is about 5x slower than rotation by sampling.

=head2 pixRotateBySampling

PIX * pixRotateBySampling ( PIX *pixs, l_int32 xcen, l_int32 ycen, l_float32 angle, l_int32 incolor )

  pixRotateBySampling()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp rgb; can be cmapped)
              xcen (x value of center of rotation)
              ycen (y value of center of rotation)
              angle (radians; clockwise is positive)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) For very small rotations, just return a clone.
      (2) Rotation brings either white or black pixels in
          from outside the image.
      (3) Colormaps are retained.

=head2 pixRotateWithAlpha

PIX * pixRotateWithAlpha ( PIX *pixs, l_float32 angle, PIX *pixg, l_float32 fract )

  pixRotateWithAlpha()

      Input:  pixs (32 bpp rgb or cmapped)
              angle (radians; clockwise is positive)
              pixg (<optional> 8 bpp, can be null)
              fract (between 0.0 and 1.0, with 0.0 fully transparent
                     and 1.0 fully opaque)
      Return: pixd (32 bpp rgba), or null on error

  Notes:
      (1) The alpha channel is transformed separately from pixs,
          and aligns with it, being fully transparent outside the
          boundary of the transformed pixs.  For pixels that are fully
          transparent, a blending function like pixBlendWithGrayMask()
          will give zero weight to corresponding pixels in pixs.
      (2) Rotation is about the center of the image; for very small
          rotations, just return a clone.  The dest is automatically
          expanded so that no image pixels are lost.
      (3) Rotation is by area mapping.  It doesn't matter what
          color is brought in because the alpha channel will
          be transparent (black) there.
      (4) If pixg is NULL, it is generated as an alpha layer that is
          partially opaque, using @fract.  Otherwise, it is cropped
          to pixs if required and @fract is ignored.  The alpha
          channel in pixs is never used.
      (4) Colormaps are removed to 32 bpp.
      (5) The default setting for the border values in the alpha channel
          is 0 (transparent) for the outermost ring of pixels and
          (0.5 * fract * 255) for the second ring.  When blended over
          a second image, this
          (a) shrinks the visible image to make a clean overlap edge
              with an image below, and
          (b) softens the edges by weakening the aliasing there.
          Use l_setAlphaMaskBorder() to change these values.
      (6) A subtle use of gamma correction is to remove gamma correction
          before rotation and restore it afterwards.  This is done
          by sandwiching this function between a gamma/inverse-gamma
          photometric transform:
              pixt = pixGammaTRCWithAlpha(NULL, pixs, 1.0 / gamma, 0, 255);
              pixd = pixRotateWithAlpha(pixt, angle, NULL, fract);
              pixGammaTRCWithAlpha(pixd, pixd, gamma, 0, 255);
              pixDestroy(&pixt);
          This has the side-effect of producing artifacts in the very
          dark regions.

  *** Warning: implicit assumption about RGB component ordering 

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
