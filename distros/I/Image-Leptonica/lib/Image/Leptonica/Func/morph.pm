package Image::Leptonica::Func::morph;
$Image::Leptonica::Func::morph::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::morph

=head1 VERSION

version 0.04

=head1 C<morph.c>

  morph.c

     Generic binary morphological ops implemented with rasterop
         PIX     *pixDilate()
         PIX     *pixErode()
         PIX     *pixHMT()
         PIX     *pixOpen()
         PIX     *pixClose()
         PIX     *pixCloseSafe()
         PIX     *pixOpenGeneralized()
         PIX     *pixCloseGeneralized()

     Binary morphological (raster) ops with brick Sels
         PIX     *pixDilateBrick()
         PIX     *pixErodeBrick()
         PIX     *pixOpenBrick()
         PIX     *pixCloseBrick()
         PIX     *pixCloseSafeBrick()

     Binary composed morphological (raster) ops with brick Sels
         l_int32  selectComposableSels()
         l_int32  selectComposableSizes()
         PIX     *pixDilateCompBrick()
         PIX     *pixErodeCompBrick()
         PIX     *pixOpenCompBrick()
         PIX     *pixCloseCompBrick()
         PIX     *pixCloseSafeCompBrick()

     Functions associated with boundary conditions
         void     resetMorphBoundaryCondition()
         l_int32  getMorphBorderPixelColor()

     Static helpers for arg processing
         static PIX     *processMorphArgs1()
         static PIX     *processMorphArgs2()

  You are provided with many simple ways to do binary morphology.
  In particular, if you are using brick Sels, there are six
  convenient methods, all specially tailored for separable operations
  on brick Sels.  A "brick" Sel is a Sel that is a rectangle
  of solid SEL_HITs with the origin at or near the center.
  Note that a brick Sel can have one dimension of size 1.
  This is very common.  All the brick Sel operations are
  separable, meaning the operation is done first in the horizontal
  direction and then in the vertical direction.  If one of the
  dimensions is 1, this is a special case where the operation is
  only performed in the other direction.

  These six brick Sel methods are enumerated as follows:

  (1) Brick Sels: pix*Brick(), where * = {Dilate, Erode, Open, Close}.
      These are separable rasterop implementations.  The Sels are
      automatically generated, used, and destroyed at the end.
      You can get the result as a new Pix, in-place back into the src Pix,
      or written to another existing Pix.

  (2) Brick Sels: pix*CompBrick(), where * = {Dilate, Erode, Open, Close}.
      These are separable, 2-way composite, rasterop implementations.
      The Sels are automatically generated, used, and destroyed at the end.
      You can get the result as a new Pix, in-place back into the src Pix,
      or written to another existing Pix.  For large Sels, these are
      considerably faster than the corresponding pix*Brick() functions.
      N.B.:  The size of the Sels that are actually used are typically
      close to, but not exactly equal to, the size input to the function.

  (3) Brick Sels: pix*BrickDwa(), where * = {Dilate, Erode, Open, Close}.
      These are separable dwa (destination word accumulation)
      implementations.  They use auto-gen'd dwa code.  You can get
      the result as a new Pix, in-place back into the src Pix,
      or written to another existing Pix.  This is typically
      about 3x faster than the analogous rasterop pix*Brick()
      function, but it has the limitation that the Sel size must
      be less than 63.  This is pre-set to work on a number
      of pre-generated Sels.  If you want to use other Sels, the
      code can be auto-gen'd for them; see the instructions in morphdwa.c.

  (4) Same as (1), but you run it through pixMorphSequence(), with
      the sequence string either compiled in or generated using sprintf.
      All intermediate images and Sels are created, used and destroyed.
      You always get the result as a new Pix.  For example, you can
      specify a separable 11 x 17 brick opening as "o11.17",
      or you can specify the horizontal and vertical operations
      explicitly as "o11.1 + o1.11".  See morphseq.c for details.

  (5) Same as (2), but you run it through pixMorphCompSequence(), with
      the sequence string either compiled in or generated using sprintf.
      All intermediate images and Sels are created, used and destroyed.
      You always get the result as a new Pix.  See morphseq.c for details.

  (6) Same as (3), but you run it through pixMorphSequenceDwa(), with
      the sequence string either compiled in or generated using sprintf.
      All intermediate images and Sels are created, used and destroyed.
      You always get the result as a new Pix.  See morphseq.c for details.

  If you are using Sels that are not bricks, you have two choices:
      (a) simplest: use the basic rasterop implementations (pixDilate(), ...)
      (b) fastest: generate the destination word accumumlation (dwa)
          code for your Sels and compile it with the library.

      For an example, see flipdetect.c, which gives implementations
      using hit-miss Sels with both the rasterop and dwa versions.
      For the latter, the dwa code resides in fliphmtgen.c, and it
      was generated by prog/flipselgen.c.  Both the rasterop and dwa
      implementations are tested by prog/fliptest.c.

  A global constant MORPH_BC is used to set the boundary conditions
  for rasterop-based binary morphology.  MORPH_BC, in morph.c,
  is set by default to ASYMMETRIC_MORPH_BC for a non-symmetric
  convention for boundary pixels in dilation and erosion:
      All pixels outside the image are assumed to be OFF
      for both dilation and erosion.
  To use a symmetric definition, see comments in pixErode()
  and reset MORPH_BC to SYMMETRIC_MORPH_BC, using
  resetMorphBoundaryCondition().

  Boundary artifacts are possible in closing when the non-symmetric
  boundary conditions are used, because foreground pixels very close
  to the edge can be removed.  This can be avoided by using either
  the symmetric boundary conditions or the function pixCloseSafe(),
  which adds a border before the operation and removes it afterwards.

  The hit-miss transform (HMT) is the bit-and of 2 erosions:
     (erosion of the src by the hits)  &  (erosion of the bit-inverted
                                           src by the misses)

  The 'generalized opening' is an HMT followed by a dilation that uses
  only the hits of the hit-miss Sel.
  The 'generalized closing' is a dilation (again, with the hits
  of a hit-miss Sel), followed by the HMT.
  Both of these 'generalized' functions are idempotent.

  These functions are extensively tested in prog/binmorph1_reg.c,
  prog/binmorph2_reg.c, and prog/binmorph3_reg.c.

=head1 FUNCTIONS

=head2 getMorphBorderPixelColor

l_uint32 getMorphBorderPixelColor ( l_int32 type, l_int32 depth )

  getMorphBorderPixelColor()

      Input:  type (L_MORPH_DILATE, L_MORPH_ERODE)
              depth (of pix)
      Return: color of border pixels for this operation

=head2 pixClose

PIX * pixClose ( PIX *pixd, PIX *pixs, SEL *sel )

  pixClose()

      Input:  pixd (<optional>; this can be null, equal to pixs,
                    or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) Generic morphological closing, using hits in the Sel.
      (2) This implementation is a strict dual of the opening if
          symmetric boundary conditions are used (see notes at top
          of this file).
      (3) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (4) For clarity, if the case is known, use these patterns:
          (a) pixd = pixClose(NULL, pixs, ...);
          (b) pixClose(pixs, pixs, ...);
          (c) pixClose(pixd, pixs, ...);
      (5) The size of the result is determined by pixs.

=head2 pixCloseBrick

PIX * pixCloseBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do separably if both hsize and vsize are > 1.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseBrick(NULL, pixs, ...);
          (b) pixCloseBrick(pixs, pixs, ...);
          (c) pixCloseBrick(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixCloseCompBrick

PIX * pixCloseCompBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseCompBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do compositely for each dimension > 1.
      (4) Do separably if both hsize and vsize are > 1.
      (5) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (6) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseCompBrick(NULL, pixs, ...);
          (b) pixCloseCompBrick(pixs, pixs, ...);
          (c) pixCloseCompBrick(pixd, pixs, ...);
      (7) The dimensions of the resulting image are determined by pixs.
      (8) CAUTION: both hsize and vsize are being decomposed.
          The decomposer chooses a product of sizes (call them
          'terms') for each that is close to the input size,
          but not necessarily equal to it.  It attempts to optimize:
             (a) for consistency with the input values: the product
                 of terms is close to the input size
             (b) for efficiency of the operation: the sum of the
                 terms is small; ideally about twice the square
                 root of the input size.
          So, for example, if the input hsize = 37, which is
          a prime number, the decomposer will break this into two
          terms, 6 and 6, so that the net result is a dilation
          with hsize = 36.

=head2 pixCloseGeneralized

PIX * pixCloseGeneralized ( PIX *pixd, PIX *pixs, SEL *sel )

  pixCloseGeneralized()

      Input:  pixd (<optional>; this can be null, equal to pixs,
                    or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) Generalized morphological closing, using both hits and
          misses in the Sel.
      (2) This does a dilation using the hits, followed by a
          hit-miss transform.
      (3) This operation is a dual of the generalized opening.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseGeneralized(NULL, pixs, ...);
          (b) pixCloseGeneralized(pixs, pixs, ...);
          (c) pixCloseGeneralized(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixCloseSafe

PIX * pixCloseSafe ( PIX *pixd, PIX *pixs, SEL *sel )

  pixCloseSafe()

      Input:  pixd (<optional>; this can be null, equal to pixs,
                    or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) Generic morphological closing, using hits in the Sel.
      (2) If non-symmetric boundary conditions are used, this
          function adds a border of OFF pixels that is of
          sufficient size to avoid losing pixels from the dilation,
          and it removes the border after the operation is finished.
          It thus enforces a correct extensive result for closing.
      (3) If symmetric b.c. are used, it is not necessary to add
          and remove this border.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseSafe(NULL, pixs, ...);
          (b) pixCloseSafe(pixs, pixs, ...);
          (c) pixCloseSafe(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixCloseSafeBrick

PIX * pixCloseSafeBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseSafeBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do separably if both hsize and vsize are > 1.
      (4) Safe closing adds a border of 0 pixels, of sufficient size so
          that all pixels in input image are processed within
          32-bit words in the expanded image.  As a result, there is
          no special processing for pixels near the boundary, and there
          are no boundary effects.  The border is removed at the end.
      (5) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (6) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseBrick(NULL, pixs, ...);
          (b) pixCloseBrick(pixs, pixs, ...);
          (c) pixCloseBrick(pixd, pixs, ...);
      (7) The size of the result is determined by pixs.

=head2 pixCloseSafeCompBrick

PIX * pixCloseSafeCompBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseSafeCompBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do compositely for each dimension > 1.
      (4) Do separably if both hsize and vsize are > 1.
      (5) Safe closing adds a border of 0 pixels, of sufficient size so
          that all pixels in input image are processed within
          32-bit words in the expanded image.  As a result, there is
          no special processing for pixels near the boundary, and there
          are no boundary effects.  The border is removed at the end.
      (6) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (7) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseSafeCompBrick(NULL, pixs, ...);
          (b) pixCloseSafeCompBrick(pixs, pixs, ...);
          (c) pixCloseSafeCompBrick(pixd, pixs, ...);
      (8) The dimensions of the resulting image are determined by pixs.
      (9) CAUTION: both hsize and vsize are being decomposed.
          The decomposer chooses a product of sizes (call them
          'terms') for each that is close to the input size,
          but not necessarily equal to it.  It attempts to optimize:
             (a) for consistency with the input values: the product
                 of terms is close to the input size
             (b) for efficiency of the operation: the sum of the
                 terms is small; ideally about twice the square
                 root of the input size.
          So, for example, if the input hsize = 37, which is
          a prime number, the decomposer will break this into two
          terms, 6 and 6, so that the net result is a dilation
          with hsize = 36.

=head2 pixDilate

PIX * pixDilate ( PIX *pixd, PIX *pixs, SEL *sel )

  pixDilate()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) This dilates src using hits in Sel.
      (2) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (3) For clarity, if the case is known, use these patterns:
          (a) pixd = pixDilate(NULL, pixs, ...);
          (b) pixDilate(pixs, pixs, ...);
          (c) pixDilate(pixd, pixs, ...);
      (4) The size of the result is determined by pixs.

=head2 pixDilateBrick

PIX * pixDilateBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do separably if both hsize and vsize are > 1.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixDilateBrick(NULL, pixs, ...);
          (b) pixDilateBrick(pixs, pixs, ...);
          (c) pixDilateBrick(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixDilateCompBrick

PIX * pixDilateCompBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateCompBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do compositely for each dimension > 1.
      (4) Do separably if both hsize and vsize are > 1.
      (5) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (6) For clarity, if the case is known, use these patterns:
          (a) pixd = pixDilateCompBrick(NULL, pixs, ...);
          (b) pixDilateCompBrick(pixs, pixs, ...);
          (c) pixDilateCompBrick(pixd, pixs, ...);
      (7) The dimensions of the resulting image are determined by pixs.
      (8) CAUTION: both hsize and vsize are being decomposed.
          The decomposer chooses a product of sizes (call them
          'terms') for each that is close to the input size,
          but not necessarily equal to it.  It attempts to optimize:
             (a) for consistency with the input values: the product
                 of terms is close to the input size
             (b) for efficiency of the operation: the sum of the
                 terms is small; ideally about twice the square
                 root of the input size.
          So, for example, if the input hsize = 37, which is
          a prime number, the decomposer will break this into two
          terms, 6 and 6, so that the net result is a dilation
          with hsize = 36.

=head2 pixErode

PIX * pixErode ( PIX *pixd, PIX *pixs, SEL *sel )

  pixErode()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) This erodes src using hits in Sel.
      (2) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (3) For clarity, if the case is known, use these patterns:
          (a) pixd = pixErode(NULL, pixs, ...);
          (b) pixErode(pixs, pixs, ...);
          (c) pixErode(pixd, pixs, ...);
      (4) The size of the result is determined by pixs.

=head2 pixErodeBrick

PIX * pixErodeBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do separably if both hsize and vsize are > 1.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixErodeBrick(NULL, pixs, ...);
          (b) pixErodeBrick(pixs, pixs, ...);
          (c) pixErodeBrick(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixErodeCompBrick

PIX * pixErodeCompBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeCompBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do compositely for each dimension > 1.
      (4) Do separably if both hsize and vsize are > 1.
      (5) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (6) For clarity, if the case is known, use these patterns:
          (a) pixd = pixErodeCompBrick(NULL, pixs, ...);
          (b) pixErodeCompBrick(pixs, pixs, ...);
          (c) pixErodeCompBrick(pixd, pixs, ...);
      (7) The dimensions of the resulting image are determined by pixs.
      (8) CAUTION: both hsize and vsize are being decomposed.
          The decomposer chooses a product of sizes (call them
          'terms') for each that is close to the input size,
          but not necessarily equal to it.  It attempts to optimize:
             (a) for consistency with the input values: the product
                 of terms is close to the input size
             (b) for efficiency of the operation: the sum of the
                 terms is small; ideally about twice the square
                 root of the input size.
          So, for example, if the input hsize = 37, which is
          a prime number, the decomposer will break this into two
          terms, 6 and 6, so that the net result is a dilation
          with hsize = 36.

=head2 pixHMT

PIX * pixHMT ( PIX *pixd, PIX *pixs, SEL *sel )

  pixHMT()

      Input:  pixd (<optional>; this can be null, equal to pixs,
                    or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) The hit-miss transform erodes the src, using both hits
          and misses in the Sel.  It ANDs the shifted src for hits
          and ANDs the inverted shifted src for misses.
      (2) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (3) For clarity, if the case is known, use these patterns:
          (a) pixd = pixHMT(NULL, pixs, ...);
          (b) pixHMT(pixs, pixs, ...);
          (c) pixHMT(pixd, pixs, ...);
      (4) The size of the result is determined by pixs.

=head2 pixOpen

PIX * pixOpen ( PIX *pixd, PIX *pixs, SEL *sel )

  pixOpen()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) Generic morphological opening, using hits in the Sel.
      (2) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (3) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpen(NULL, pixs, ...);
          (b) pixOpen(pixs, pixs, ...);
          (c) pixOpen(pixd, pixs, ...);
      (4) The size of the result is determined by pixs.

=head2 pixOpenBrick

PIX * pixOpenBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do separably if both hsize and vsize are > 1.
      (4) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (5) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpenBrick(NULL, pixs, ...);
          (b) pixOpenBrick(pixs, pixs, ...);
          (c) pixOpenBrick(pixd, pixs, ...);
      (6) The size of the result is determined by pixs.

=head2 pixOpenCompBrick

PIX * pixOpenCompBrick ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenCompBrick()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd, or null on error

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) The origin is at (x, y) = (hsize/2, vsize/2)
      (3) Do compositely for each dimension > 1.
      (4) Do separably if both hsize and vsize are > 1.
      (5) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (6) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpenCompBrick(NULL, pixs, ...);
          (b) pixOpenCompBrick(pixs, pixs, ...);
          (c) pixOpenCompBrick(pixd, pixs, ...);
      (7) The dimensions of the resulting image are determined by pixs.
      (8) CAUTION: both hsize and vsize are being decomposed.
          The decomposer chooses a product of sizes (call them
          'terms') for each that is close to the input size,
          but not necessarily equal to it.  It attempts to optimize:
             (a) for consistency with the input values: the product
                 of terms is close to the input size
             (b) for efficiency of the operation: the sum of the
                 terms is small; ideally about twice the square
                 root of the input size.
          So, for example, if the input hsize = 37, which is
          a prime number, the decomposer will break this into two
          terms, 6 and 6, so that the net result is a dilation
          with hsize = 36.

=head2 pixOpenGeneralized

PIX * pixOpenGeneralized ( PIX *pixd, PIX *pixs, SEL *sel )

  pixOpenGeneralized()

      Input:  pixd (<optional>; this can be null, equal to pixs,
                    or different from pixs)
              pixs (1 bpp)
              sel
      Return: pixd

  Notes:
      (1) Generalized morphological opening, using both hits and
          misses in the Sel.
      (2) This does a hit-miss transform, followed by a dilation
          using the hits.
      (3) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (4) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpenGeneralized(NULL, pixs, ...);
          (b) pixOpenGeneralized(pixs, pixs, ...);
          (c) pixOpenGeneralized(pixd, pixs, ...);
      (5) The size of the result is determined by pixs.

=head2 resetMorphBoundaryCondition

void resetMorphBoundaryCondition ( l_int32 bc )

  resetMorphBoundaryCondition()

      Input:  bc (SYMMETRIC_MORPH_BC, ASYMMETRIC_MORPH_BC)
      Return: void

=head2 selectComposableSels

l_int32 selectComposableSels ( l_int32 size, l_int32 direction, SEL **psel1, SEL **psel2 )

selectComposableSels()

      Input:  size (of composed sel)
              direction (L_HORIZ, L_VERT)
              &sel1 (<optional return> contiguous sel; can be null)
              &sel2 (<optional return> comb sel; can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) When using composable Sels, where the original Sel is
          decomposed into two, the best you can do in terms
          of reducing the computation is by a factor:

               2 * sqrt(size) / size

          In practice, you get quite close to this.  E.g.,

             Sel size     |   Optimum reduction factor
             --------         ------------------------
                36        |          1/3
                64        |          1/4
               144        |          1/6
               256        |          1/8

=head2 selectComposableSizes

l_int32 selectComposableSizes ( l_int32 size, l_int32 *pfactor1, l_int32 *pfactor2 )

  selectComposableSizes()

      Input:  size (of sel to be decomposed)
              &factor1 (<return> larger factor)
              &factor2 (<return> smaller factor)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This works for Sel sizes up to 62500, which seems sufficient.
      (2) The composable sel size is typically within +- 1 of
          the requested size.  Up to size = 300, the maximum difference
          is +- 2.
      (3) We choose an overall cost function where the penalty for
          the size difference between input and actual is 4 times
          the penalty for additional rasterops.
      (4) Returned values: factor1 >= factor2
          If size > 1, then factor1 > 1.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
