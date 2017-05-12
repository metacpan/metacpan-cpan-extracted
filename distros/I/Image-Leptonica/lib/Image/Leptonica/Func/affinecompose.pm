package Image::Leptonica::Func::affinecompose;
$Image::Leptonica::Func::affinecompose::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::affinecompose

=head1 VERSION

version 0.04

=head1 C<affinecompose.c>

  affinecompose.c

      Composable coordinate transforms
           l_float32   *createMatrix2dTranslate()
           l_float32   *createMatrix2dScale()
           l_float32   *createMatrix2dRotate()

      Special coordinate transforms on pta
           PTA         *ptaTranslate()
           PTA         *ptaScale()
           PTA         *ptaRotate()

      Special coordinate transforms on boxa
           BOXA        *boxaTranslate()
           BOXA        *boxaScale()
           BOXA        *boxaRotate()

      General coordinate transform on pta and boxa
           PTA         *ptaAffineTransform()
           BOXA        *boxaAffineTransform()

      Matrix operations
           l_int32      l_productMatVec()
           l_int32      l_productMat2()
           l_int32      l_productMat3()
           l_int32      l_productMat4()

=head1 FUNCTIONS

=head2 boxaAffineTransform

BOXA * boxaAffineTransform ( BOXA *boxas, l_float32 *mat )

  boxaAffineTransform()

      Input:  boxas
              mat  (3x3 transform matrix; canonical form)
      Return: boxad  (transformed boxas), or null on error

=head2 boxaRotate

BOXA * boxaRotate ( BOXA *boxas, l_float32 xc, l_float32 yc, l_float32 angle )

  boxaRotate()

      Input:  boxas
              (xc, yc)  (location of center of rotation)
              angle  (rotation in radians; clockwise is positive)
      Return: boxad  (scaled boxas), or null on error

  Notes;
      (1) See createMatrix2dRotate() for details of transform.

=head2 boxaScale

BOXA * boxaScale ( BOXA *boxas, l_float32 scalex, l_float32 scaley )

  boxaScale()

      Input:  boxas
              scalex  (horizontal scale factor)
              scaley  (vertical scale factor)
      Return: boxad  (scaled boxas), or null on error

  Notes;
      (1) See createMatrix2dScale() for details of transform.

=head2 boxaTranslate

BOXA * boxaTranslate ( BOXA *boxas, l_float32 transx, l_float32 transy )

  boxaTranslate()

      Input:  boxas
              transx  (x component of translation wrt. the origin)
              transy  (y component of translation wrt. the origin)
      Return: boxad  (translated boxas), or null on error

  Notes;
      (1) See createMatrix2dTranslate() for details of transform.

=head2 createMatrix2dRotate

l_float32 * createMatrix2dRotate ( l_float32 xc, l_float32 yc, l_float32 angle )

  createMatrix2dRotate()

      Input:  xc, yc  (location of center of rotation)
              angle  (rotation in radians; clockwise is positive)
      Return: 3x3 transform matrix, or null on error

  Notes;
      (1) The rotation is equivalent to:
             v' = Av
          where v and v' are 1x3 column vectors in the form
             v = [x, y, 1]^    (^ denotes transpose)
          and the affine rotation matrix is
             A = [ cosa   -sina    xc*(1-cosa) + yc*sina
                   sina    cosa    yc*(1-cosa) - xc*sina
                     0       0                 1         ]

          If the rotation is about the origin, (xc, yc) = (0, 0) and
          this simplifies to
             A = [ cosa   -sina    0
                   sina    cosa    0
                     0       0     1 ]

          These relations follow from the following equations, which
          you can convince yourself are correct as follows.  Draw a
          circle centered on (xc,yc) and passing through (x,y), with
          (x',y') on the arc at an angle 'a' clockwise from (x,y).
          [ Hint: cos(a + b) = cosa * cosb - sina * sinb
                  sin(a + b) = sina * cosb + cosa * sinb ]

            x' - xc =  (x - xc) * cosa - (y - yc) * sina
            y' - yc =  (x - xc) * sina + (y - yc) * cosa

=head2 createMatrix2dScale

l_float32 * createMatrix2dScale ( l_float32 scalex, l_float32 scaley )

  createMatrix2dScale()

      Input:  scalex  (horizontal scale factor)
              scaley  (vertical scale factor)
      Return: 3x3 transform matrix, or null on error

  Notes;
      (1) The scaling is equivalent to:
             v' = Av
          where v and v' are 1x3 column vectors in the form
             v = [x, y, 1]^    (^ denotes transpose)
          and the affine scaling matrix is
             A = [ sx  0    0
                   0   sy   0
                   0   0    1  ]

      (2) We consider scaling as with respect to a fixed origin.
          In other words, the origin is the only point that doesn't
          move in the scaling transform.

=head2 createMatrix2dTranslate

l_float32 * createMatrix2dTranslate ( l_float32 transx, l_float32 transy )

  createMatrix2dTranslate()

      Input:  transx  (x component of translation wrt. the origin)
              transy  (y component of translation wrt. the origin)
      Return: 3x3 transform matrix, or null on error

  Notes;
      (1) The translation is equivalent to:
             v' = Av
          where v and v' are 1x3 column vectors in the form
             v = [x, y, 1]^    (^ denotes transpose)
          and the affine tranlation matrix is
             A = [ 1   0   tx
                   0   1   ty
                   0   0    1  ]

      (2) We consider translation as with respect to a fixed origin.
          In a clipping operation, the origin moves and the points
          are fixed, and you use (-tx, -ty) where (tx, ty) is the
          translation vector of the origin.

=head2 l_productMat2

l_int32 l_productMat2 ( l_float32 *mat1, l_float32 *mat2, l_float32 *matd, l_int32 size )

  l_productMat2()

      Input:  mat1  (square matrix, as a 1-dimensional size^2 array)
              mat2  (square matrix, as a 1-dimensional size^2 array)
              matd  (square matrix; product stored here)
              size (of matrices)
      Return: 0 if OK, 1 on error

=head2 l_productMat3

l_int32 l_productMat3 ( l_float32 *mat1, l_float32 *mat2, l_float32 *mat3, l_float32 *matd, l_int32 size )

  l_productMat3()

      Input:  mat1  (square matrix, as a 1-dimensional size^2 array)
              mat2  (square matrix, as a 1-dimensional size^2 array)
              mat3  (square matrix, as a 1-dimensional size^2 array)
              matd  (square matrix; product stored here)
              size  (of matrices)
      Return: 0 if OK, 1 on error

=head2 l_productMat4

l_int32 l_productMat4 ( l_float32 *mat1, l_float32 *mat2, l_float32 *mat3, l_float32 *mat4, l_float32 *matd, l_int32 size )

  l_productMat4()

      Input:  mat1  (square matrix, as a 1-dimensional size^2 array)
              mat2  (square matrix, as a 1-dimensional size^2 array)
              mat3  (square matrix, as a 1-dimensional size^2 array)
              mat4  (square matrix, as a 1-dimensional size^2 array)
              matd  (square matrix; product stored here)
              size  (of matrices)
      Return: 0 if OK, 1 on error

=head2 l_productMatVec

l_int32 l_productMatVec ( l_float32 *mat, l_float32 *vecs, l_float32 *vecd, l_int32 size )

  l_productMatVec()

      Input:  mat  (square matrix, as a 1-dimensional @size^2 array)
              vecs (input column vector of length @size)
              vecd (result column vector)
              size (matrix is @size x @size; vectors are length @size)
      Return: 0 if OK, 1 on error

=head2 ptaAffineTransform

PTA * ptaAffineTransform ( PTA *ptas, l_float32 *mat )

  ptaAffineTransform()

      Input:  ptas (for initial points)
              mat  (3x3 transform matrix; canonical form)
      Return: ptad  (transformed points), or null on error

=head2 ptaRotate

PTA * ptaRotate ( PTA *ptas, l_float32 xc, l_float32 yc, l_float32 angle )

  ptaRotate()

      Input:  ptas (for initial points)
              (xc, yc)  (location of center of rotation)
              angle  (rotation in radians; clockwise is positive)
              (&ptad)  (<return> new locations)
      Return: 0 if OK; 1 on error

  Notes;
      (1) See createMatrix2dScale() for details of transform.

=head2 ptaScale

PTA * ptaScale ( PTA *ptas, l_float32 scalex, l_float32 scaley )

  ptaScale()

      Input:  ptas (for initial points)
              scalex  (horizontal scale factor)
              scaley  (vertical scale factor)
      Return: 0 if OK; 1 on error

  Notes;
      (1) See createMatrix2dScale() for details of transform.

=head2 ptaTranslate

PTA * ptaTranslate ( PTA *ptas, l_float32 transx, l_float32 transy )

  ptaTranslate()

      Input:  ptas (for initial points)
              transx  (x component of translation wrt. the origin)
              transy  (y component of translation wrt. the origin)
      Return: ptad  (translated points), or null on error

  Notes;
      (1) See createMatrix2dTranslate() for details of transform.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
