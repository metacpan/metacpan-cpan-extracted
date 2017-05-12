package Image::Leptonica::Func::affine;
$Image::Leptonica::Func::affine::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::affine

=head1 VERSION

version 0.04

=head1 C<affine.c>

  affine.c

      Affine (3 pt) image transformation using a sampled
      (to nearest integer) transform on each dest point
           PIX        *pixAffineSampledPta()
           PIX        *pixAffineSampled()

      Affine (3 pt) image transformation using interpolation
      (or area mapping) for anti-aliasing images that are
      2, 4, or 8 bpp gray, or colormapped, or 32 bpp RGB
           PIX        *pixAffinePta()
           PIX        *pixAffine()
           PIX        *pixAffinePtaColor()
           PIX        *pixAffineColor()
           PIX        *pixAffinePtaGray()
           PIX        *pixAffineGray()

      Affine transform including alpha (blend) component
           PIX        *pixAffinePtaWithAlpha()

      Affine coordinate transformation
           l_int32     getAffineXformCoeffs()
           l_int32     affineInvertXform()
           l_int32     affineXformSampledPt()
           l_int32     affineXformPt()

      Interpolation helper functions
           l_int32     linearInterpolatePixelGray()
           l_int32     linearInterpolatePixelColor()

      Gauss-jordan linear equation solver
           l_int32     gaussjordan()

      Affine image transformation using a sequence of
      shear/scale/translation operations
           PIX        *pixAffineSequential()

      One can define a coordinate space by the location of the origin,
      the orientation of x and y axes, and the unit scaling along
      each axis.  An affine transform is a general linear
      transformation from one coordinate space to another.

      For the general case, we can define the affine transform using
      two sets of three (noncollinear) points in a plane.  One set
      corresponds to the input (src) coordinate space; the other to the
      transformed (dest) coordinate space.  Each point in the
      src corresponds to one of the points in the dest.  With two
      sets of three points, we get a set of 6 equations in 6 unknowns
      that specifies the mapping between the coordinate spaces.
      The interface here allows you to specify either the corresponding
      sets of 3 points, or the transform itself (as a vector of 6
      coefficients).

      Given the transform as a vector of 6 coefficients, we can compute
      both a a pointwise affine coordinate transformation and an
      affine image transformation.

      To compute the coordinate transform, we need the coordinate
      value (x',y') in the transformed space for any point (x,y)
      in the original space.  To derive this transform from the
      three corresponding points, it is convenient to express the affine
      coordinate transformation using an LU decomposition of
      a set of six linear equations that express the six coordinates
      of the three points in the transformed space as a function of
      the six coordinates in the original space.  Once we have
      this transform matrix , we can transform an image by
      finding, for each destination pixel, the pixel (or pixels)
      in the source that give rise to it.

      This 'pointwise' transformation can be done either by sampling
      and picking a single pixel in the src to replicate into the dest,
      or by interpolating (or averaging) over four src pixels to
      determine the value of the dest pixel.  The first method is
      implemented by pixAffineSampled() and the second method by
      pixAffine().  The interpolated method can only be used for
      images with more than 1 bpp, but for these, the image quality
      is significantly better than the sampled method, due to
      the 'antialiasing' effect of weighting the src pixels.

      Interpolation works well when there is relatively little scaling,
      or if there is image expansion in general.  However, if there
      is significant image reduction, one should apply a low-pass
      filter before subsampling to avoid aliasing the high frequencies.

      A typical application might be to align two images, which
      may be scaled, rotated and translated versions of each other.
      Through some pre-processing, three corresponding points are
      located in each of the two images.  One of the images is
      then to be (affine) transformed to align with the other.
      As mentioned, the standard way to do this is to use three
      sets of points, compute the 6 transformation coefficients
      from these points that describe the linear transformation,

          x' = ax + by + c
          y' = dx + ey + f

      and use this in a pointwise manner to transform the image.

      N.B.  Be sure to see the comment in getAffineXformCoeffs(),
      regarding using the inverse of the affine transform for points
      to transform images.

      There is another way to do this transformation; namely,
      by doing a sequence of simple affine transforms, without
      computing directly the affine coordinate transformation.
      We have at our disposal (1) translations (using rasterop),
      (2) horizontal and vertical shear about any horizontal and vertical
      line, respectively, and (3) non-isotropic scaling by two
      arbitrary x and y scaling factors.  We also have rotation
      about an arbitrary point, but this is equivalent to a set
      of three shears so we do not need to use it.

      Why might we do this?  For binary images, it is usually
      more efficient to do such transformations by a sequence
      of word parallel operations.  Shear and translation can be
      done in-place and word parallel; arbitrary scaling is
      mostly pixel-wise.

      Suppose that we are tranforming image 1 to correspond to image 2.
      We have a set of three points, describing the coordinate space
      embedded in image 1, and we need to transform image 1 until
      those three points exactly correspond to the new coordinate space
      defined by the second set of three points.  In our image
      matching application, the latter set of three points was
      found to be the corresponding points in image 2.

      The most elegant way I can think of to do such a sequential
      implementation is to imagine that we're going to transform
      BOTH images until they're aligned.  (We don't really want
      to transform both, because in fact we may only have one image
      that is undergoing a general affine transformation.)

      Choose the 3 corresponding points as follows:
         - The 1st point is an origin
         - The 2nd point gives the orientation and scaling of the
           "x" axis with respect to the origin
         - The 3rd point does likewise for the "y" axis.
      These "axes" must not be collinear; otherwise they are
      arbitrary (although some strange things will happen if
      the handedness sweeping through the minimum angle between
      the axes is opposite).

      An important constraint is that we have shear operations
      about an arbitrary horizontal or vertical line, but always
      parallel to the x or y axis.  If we continue to pretend that
      we have an unprimed coordinate space embedded in image 1 and
      a primed coordinate space embedded in image 2, we imagine
      (a) transforming image 1 by horizontal and vertical shears about
      point 1 to align points 3 and 2 along the y and x axes,
      respectively, and (b) transforming image 2 by horizontal and
      vertical shears about point 1' to align points 3' and 2' along
      the y and x axes.  Then we scale image 1 so that the distances
      from 1 to 2 and from 1 to 3 are equal to the distances in
      image 2 from 1' to 2' and from 1' to 3'.  This scaling operation
      leaves the true image origin, at (0,0) invariant, and will in
      general translate point 1.  The original points 1 and 1' will
      typically not coincide in any event, so we must translate
      the origin of image 1, at its current point 1, to the origin
      of image 2 at 1'.  The images should now be aligned.  But
      because we never really transformed image 2 (and image 2 may
      not even exist), we now perform  on image 1 the reverse of
      the shear transforms that we imagined doing on image 2;
      namely, the negative vertical shear followed by the negative
      horizontal shear.  Image 1 should now have its transformed
      unprimed coordinates aligned with the original primed
      coordinates.  In all this, it is only necessary to keep track
      of the shear angles and translations of points during the shears.
      What has been accomplished is a general affine transformation
      on image 1.

      Having described all this, if you are going to use an
      affine transformation in an application, this is what you
      need to know:

          (1) You should NEVER use the sequential method, because
              the image quality for 1 bpp text is much poorer
              (even though it is about 2x faster than the pointwise sampled
              method), and for images with depth greater than 1, it is
              nearly 20x slower than the pointwise sampled method
              and over 10x slower than the pointwise interpolated method!
              The sequential method is given here for purely
              pedagogical reasons.

          (2) For 1 bpp images, use the pointwise sampled function
              pixAffineSampled().  For all other images, the best
              quality results result from using the pointwise
              interpolated function pixAffinePta() or pixAffine();
              the cost is less than a doubling of the computation time
              with respect to the sampled function.  If you use
              interpolation on colormapped images, the colormap will
              be removed, resulting in either a grayscale or color
              image, depending on the values in the colormap.
              If you want to retain the colormap, use pixAffineSampled().

      Typical relative timing of pointwise transforms (sampled = 1.0):
      8 bpp:   sampled        1.0
               interpolated   1.6
      32 bpp:  sampled        1.0
               interpolated   1.8
      Additionally, the computation time/pixel is nearly the same
      for 8 bpp and 32 bpp, for both sampled and interpolated.

=head1 FUNCTIONS

=head2 affineInvertXform

l_int32 affineInvertXform ( l_float32 *vc, l_float32 **pvci )

  affineInvertXform()

      Input:  vc (vector of 6 coefficients)
              *vci (<return> inverted transform)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The 6 affine transform coefficients are the first
          two rows of a 3x3 matrix where the last row has
          only a 1 in the third column.  We invert this
          using gaussjordan(), and select the first 2 rows
          as the coefficients of the inverse affine transform.
      (2) Alternatively, we can find the inverse transform
          coefficients by inverting the 2x2 submatrix,
          and treating the top 2 coefficients in the 3rd column as
          a RHS vector for that 2x2 submatrix.  Then the
          6 inverted transform coefficients are composed of
          the inverted 2x2 submatrix and the negative of the
          transformed RHS vector.  Why is this so?  We have
             Y = AX + R  (2 equations in 6 unknowns)
          Then
             X = A'Y - A'R
          Gauss-jordan solves
             AF = R
          and puts the solution for F, which is A'R,
          into the input R vector.

=head2 affineXformPt

l_int32 affineXformPt ( l_float32 *vc, l_int32 x, l_int32 y, l_float32 *pxp, l_float32 *pyp )

  affineXformPt()

      Input:  vc (vector of 6 coefficients)
              (x, y)  (initial point)
              (&xp, &yp)   (<return> transformed point)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This computes the floating point location of the transformed point.
      (2) It does not check ptrs for returned data!

=head2 affineXformSampledPt

l_int32 affineXformSampledPt ( l_float32 *vc, l_int32 x, l_int32 y, l_int32 *pxp, l_int32 *pyp )

  affineXformSampledPt()

      Input:  vc (vector of 6 coefficients)
              (x, y)  (initial point)
              (&xp, &yp)   (<return> transformed point)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This finds the nearest pixel coordinates of the transformed point.
      (2) It does not check ptrs for returned data!

=head2 gaussjordan

l_int32 gaussjordan ( l_float32 **a, l_float32 *b, l_int32 n )

  gaussjordan()

      Input:   a  (n x n matrix)
               b  (rhs column vector)
               n  (dimension)
      Return:  0 if ok, 1 on error

      Note side effects:
            (1) the matrix a is transformed to its inverse
            (2) the vector b is transformed to the solution X to the
                linear equation AX = B

      Adapted from "Numerical Recipes in C, Second Edition", 1992
      pp. 36-41 (gauss-jordan elimination)

=head2 getAffineXformCoeffs

l_int32 getAffineXformCoeffs ( PTA *ptas, PTA *ptad, l_float32 **pvc )

  getAffineXformCoeffs()

      Input:  ptas  (source 3 points; unprimed)
              ptad  (transformed 3 points; primed)
              &vc   (<return> vector of coefficients of transform)
      Return: 0 if OK; 1 on error

  We have a set of six equations, describing the affine
  transformation that takes 3 points (ptas) into 3 other
  points (ptad).  These equations are:

          x1' = c[0]*x1 + c[1]*y1 + c[2]
          y1' = c[3]*x1 + c[4]*y1 + c[5]
          x2' = c[0]*x2 + c[1]*y2 + c[2]
          y2' = c[3]*x2 + c[4]*y2 + c[5]
          x3' = c[0]*x3 + c[1]*y3 + c[2]
          y3' = c[3]*x3 + c[4]*y3 + c[5]

  This can be represented as

          AC = B

  where B and C are column vectors

          B = [ x1' y1' x2' y2' x3' y3' ]
          C = [ c[0] c[1] c[2] c[3] c[4] c[5] c[6] ]

  and A is the 6x6 matrix

          x1   y1   1   0    0    0
           0    0   0   x1   y1   1
          x2   y2   1   0    0    0
           0    0   0   x2   y2   1
          x3   y3   1   0    0    0
           0    0   0   x3   y3   1

  These six equations are solved here for the coefficients C.

  These six coefficients can then be used to find the dest
  point (x',y') corresponding to any src point (x,y), according
  to the equations

           x' = c[0]x + c[1]y + c[2]
           y' = c[3]x + c[4]y + c[5]

  that are implemented in affineXformPt().

  !!!!!!!!!!!!!!!!!!   Very important   !!!!!!!!!!!!!!!!!!!!!!

  When the affine transform is composed from a set of simple
  operations such as translation, scaling and rotation,
  it is built in a form to convert from the un-transformed src
  point to the transformed dest point.  However, when an
  affine transform is used on images, it is used in an inverted
  way: it converts from the transformed dest point to the
  un-transformed src point.  So, for example, if you transform
  a boxa using transform A, to transform an image in the same
  way you must use the inverse of A.

  For example, if you transform a boxa with a 3x3 affine matrix
  'mat', the analogous image transformation must use 'matinv':

     boxad = boxaAffineTransform(boxas, mat);
     affineInvertXform(mat, &matinv);
     pixd = pixAffine(pixs, matinv, L_BRING_IN_WHITE);

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

=head2 linearInterpolatePixelColor

l_int32 linearInterpolatePixelColor ( l_uint32 *datas, l_int32 wpls, l_int32 w, l_int32 h, l_float32 x, l_float32 y, l_uint32 colorval, l_uint32 *pval )

  linearInterpolatePixelColor()

      Input:  datas (ptr to beginning of image data)
              wpls (32-bit word/line for this data array)
              w, h (of image)
              x, y (floating pt location for evaluation)
              colorval (color brought in from the outside when the
                        input x,y location is outside the image;
                        in 0xrrggbb00 format))
              &val (<return> interpolated color value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a standard linear interpolation function.  It is
          equivalent to area weighting on each component, and
          avoids "jaggies" when rendering sharp edges.

=head2 linearInterpolatePixelGray

l_int32 linearInterpolatePixelGray ( l_uint32 *datas, l_int32 wpls, l_int32 w, l_int32 h, l_float32 x, l_float32 y, l_int32 grayval, l_int32 *pval )

  linearInterpolatePixelGray()

      Input:  datas (ptr to beginning of image data)
              wpls (32-bit word/line for this data array)
              w, h (of image)
              x, y (floating pt location for evaluation)
              grayval (color brought in from the outside when the
                       input x,y location is outside the image)
              &val (<return> interpolated gray value)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is a standard linear interpolation function.  It is
          equivalent to area weighting on each component, and
          avoids "jaggies" when rendering sharp edges.

=head2 pixAffine

PIX * pixAffine ( PIX *pixs, l_float32 *vc, l_int32 incolor )

  pixAffine()

      Input:  pixs (all depths; colormap ok)
              vc  (vector of 6 coefficients for affine transformation)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Brings in either black or white pixels from the boundary
      (2) Removes any existing colormap, if necessary, before transforming

=head2 pixAffineColor

PIX * pixAffineColor ( PIX *pixs, l_float32 *vc, l_uint32 colorval )

  pixAffineColor()

      Input:  pixs (32 bpp)
              vc  (vector of 6 coefficients for affine transformation)
              colorval (e.g., 0 to bring in BLACK, 0xffffff00 for WHITE)
      Return: pixd, or null on error

=head2 pixAffineGray

PIX * pixAffineGray ( PIX *pixs, l_float32 *vc, l_uint8 grayval )

  pixAffineGray()

      Input:  pixs (8 bpp)
              vc  (vector of 6 coefficients for affine transformation)
              grayval (0 to bring in BLACK, 255 for WHITE)
      Return: pixd, or null on error

=head2 pixAffinePta

PIX * pixAffinePta ( PIX *pixs, PTA *ptad, PTA *ptas, l_int32 incolor )

  pixAffinePta()

      Input:  pixs (all depths; colormap ok)
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Brings in either black or white pixels from the boundary
      (2) Removes any existing colormap, if necessary, before transforming

=head2 pixAffinePtaColor

PIX * pixAffinePtaColor ( PIX *pixs, PTA *ptad, PTA *ptas, l_uint32 colorval )

  pixAffinePtaColor()

      Input:  pixs (32 bpp)
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              colorval (e.g., 0 to bring in BLACK, 0xffffff00 for WHITE)
      Return: pixd, or null on error

=head2 pixAffinePtaGray

PIX * pixAffinePtaGray ( PIX *pixs, PTA *ptad, PTA *ptas, l_uint8 grayval )

  pixAffinePtaGray()

      Input:  pixs (8 bpp)
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              grayval (0 to bring in BLACK, 255 for WHITE)
      Return: pixd, or null on error

=head2 pixAffinePtaWithAlpha

PIX * pixAffinePtaWithAlpha ( PIX *pixs, PTA *ptad, PTA *ptas, PIX *pixg, l_float32 fract, l_int32 border )

  pixAffinePtaWithAlpha()

      Input:  pixs (32 bpp rgb)
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              pixg (<optional> 8 bpp, can be null)
              fract (between 0.0 and 1.0, with 0.0 fully transparent
                     and 1.0 fully opaque)
              border (of pixels added to capture transformed source pixels)
      Return: pixd, or null on error

  Notes:
      (1) The alpha channel is transformed separately from pixs,
          and aligns with it, being fully transparent outside the
          boundary of the transformed pixs.  For pixels that are fully
          transparent, a blending function like pixBlendWithGrayMask()
          will give zero weight to corresponding pixels in pixs.
      (2) If pixg is NULL, it is generated as an alpha layer that is
          partially opaque, using @fract.  Otherwise, it is cropped
          to pixs if required and @fract is ignored.  The alpha channel
          in pixs is never used.
      (3) Colormaps are removed.
      (4) When pixs is transformed, it doesn't matter what color is brought
          in because the alpha channel will be transparent (0) there.
      (5) To avoid losing source pixels in the destination, it may be
          necessary to add a border to the source pix before doing
          the affine transformation.  This can be any non-negative number.
      (6) The input @ptad and @ptas are in a coordinate space before
          the border is added.  Internally, we compensate for this
          before doing the affine transform on the image after the border
          is added.
      (7) The default setting for the border values in the alpha channel
          is 0 (transparent) for the outermost ring of pixels and
          (0.5 * fract * 255) for the second ring.  When blended over
          a second image, this
          (a) shrinks the visible image to make a clean overlap edge
              with an image below, and
          (b) softens the edges by weakening the aliasing there.
          Use l_setAlphaMaskBorder() to change these values.
      (8) A subtle use of gamma correction is to remove gamma correction
          before scaling and restore it afterwards.  This is done
          by sandwiching this function between a gamma/inverse-gamma
          photometric transform:
              pixt = pixGammaTRCWithAlpha(NULL, pixs, 1.0 / gamma, 0, 255);
              pixd = pixAffinePtaWithAlpha(pixg, ptad, ptas, NULL,
                                           fract, border);
              pixGammaTRCWithAlpha(pixd, pixd, gamma, 0, 255);
              pixDestroy(&pixt);
          This has the side-effect of producing artifacts in the very
          dark regions.

=head2 pixAffineSampled

PIX * pixAffineSampled ( PIX *pixs, l_float32 *vc, l_int32 incolor )

  pixAffineSampled()

      Input:  pixs (all depths)
              vc  (vector of 6 coefficients for affine transformation)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Brings in either black or white pixels from the boundary.
      (2) Retains colormap, which you can do for a sampled transform..
      (3) For 8 or 32 bpp, much better quality is obtained by the
          somewhat slower pixAffine().  See that function
          for relative timings between sampled and interpolated.

=head2 pixAffineSampledPta

PIX * pixAffineSampledPta ( PIX *pixs, PTA *ptad, PTA *ptas, l_int32 incolor )

  pixAffineSampledPta()

      Input:  pixs (all depths)
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              incolor (L_BRING_IN_WHITE, L_BRING_IN_BLACK)
      Return: pixd, or null on error

  Notes:
      (1) Brings in either black or white pixels from the boundary.
      (2) Retains colormap, which you can do for a sampled transform..
      (3) The 3 points must not be collinear.
      (4) The order of the 3 points is arbitrary; however, to compare
          with the sequential transform they must be in these locations
          and in this order: origin, x-axis, y-axis.
      (5) For 1 bpp images, this has much better quality results
          than pixAffineSequential(), particularly for text.
          It is about 3x slower, but does not require additional
          border pixels.  The poor quality of pixAffineSequential()
          is due to repeated quantized transforms.  It is strongly
          recommended that pixAffineSampled() be used for 1 bpp images.
      (6) For 8 or 32 bpp, much better quality is obtained by the
          somewhat slower pixAffinePta().  See that function
          for relative timings between sampled and interpolated.
      (7) To repeat, use of the sequential transform,
          pixAffineSequential(), for any images, is discouraged.

=head2 pixAffineSequential

PIX * pixAffineSequential ( PIX *pixs, PTA *ptad, PTA *ptas, l_int32 bw, l_int32 bh )

  pixAffineSequential()

      Input:  pixs
              ptad  (3 pts of final coordinate space)
              ptas  (3 pts of initial coordinate space)
              bw    (pixels of additional border width during computation)
              bh    (pixels of additional border height during computation)
      Return: pixd, or null on error

  Notes:
      (1) The 3 pts must not be collinear.
      (2) The 3 pts must be given in this order:
           - origin
           - a location along the x-axis
           - a location along the y-axis.
      (3) You must guess how much border must be added so that no
          pixels are lost in the transformations from src to
          dest coordinate space.  (This can be calculated but it
          is a lot of work!)  For coordinate spaces that are nearly
          at right angles, on a 300 ppi scanned page, the addition
          of 1000 pixels on each side is usually sufficient.
      (4) This is here for pedagogical reasons.  It is about 3x faster
          on 1 bpp images than pixAffineSampled(), but the results
          on text are much inferior.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
