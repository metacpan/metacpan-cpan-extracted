package Image::Leptonica::Func::morphdwa;
$Image::Leptonica::Func::morphdwa::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::morphdwa

=head1 VERSION

version 0.04

=head1 C<morphdwa.c>

  morphdwa.c

    Binary morphological (dwa) ops with brick Sels
         PIX     *pixDilateBrickDwa()
         PIX     *pixErodeBrickDwa()
         PIX     *pixOpenBrickDwa()
         PIX     *pixCloseBrickDwa()

    Binary composite morphological (dwa) ops with brick Sels
         PIX     *pixDilateCompBrickDwa()
         PIX     *pixErodeCompBrickDwa()
         PIX     *pixOpenCompBrickDwa()
         PIX     *pixCloseCompBrickDwa()

    Binary extended composite morphological (dwa) ops with brick Sels
         PIX     *pixDilateCompBrickExtendDwa()
         PIX     *pixErodeCompBrickExtendDwa()
         PIX     *pixOpenCompBrickExtendDwa()
         PIX     *pixCloseCompBrickExtendDwa()
         l_int32  getExtendedCompositeParameters()

    These are higher-level interfaces for dwa morphology with brick Sels.
    Because many morphological operations are performed using
    separable brick Sels, it is useful to have a simple interface
    for this.

    We have included all 58 of the brick Sels that are generated
    by selaAddBasic().  These are sufficient for all the decomposable
    bricks up to size 63, which is the limit for dwa Sels with
    origins at the center of the Sel.

    All three sets can be used as the basic interface for general
    brick operations.  Here are the internal calling sequences:

      (1) If you try to apply a non-decomposable operation, such as
          pixErodeBrickDwa(), with a Sel size that doesn't exist,
          this calls a decomposable operation, pixErodeCompBrickDwa(),
          instead.  This can differ in linear Sel size by up to
          2 pixels from the request.

      (2) If either Sel brick dimension is greater than 63, the extended
          composite function is called.

      (3) The extended composite function calls the composite function
          a number of times with size 63, and once with size < 63.
          Because each operation with a size of 63 is done compositely
          with 7 x 9 (exactly 63), the net result is correct in
          length to within 2 pixels.

    For composite operations, both using a comb and extended (beyond 63),
    horizontal and vertical operations are composed separately
    and sequentially.

    We have also included use of all the 76 comb Sels that are generated
    by selaAddDwaCombs().  The generated code is in dwacomb.2.c
    and dwacomblow.2.c.  These are used for the composite dwa
    brick operations.

    The non-composite brick operations, such as pixDilateBrickDwa(),
    will call the associated composite operation in situations where
    the requisite brick Sel has not been compiled into fmorphgen*.1.c.

    If you want to use brick Sels that are not represented in the
    basic set of 58, you must generate the dwa code to implement them.
    You have three choices for how to use these:

    (1) Add both the new Sels and the dwa code to the library:
        - For simplicity, add your new brick Sels to those defined
          in selaAddBasic().
        - Recompile the library.
        - Make prog/fmorphautogen.
        - Run prog/fmorphautogen, to generate new versions of the
          dwa code in fmorphgen.1.c and fmorphgenlow.1.c.
        - Copy these two files to src.
        - Recompile the library again.
        - Use the new brick Sels in your program and compile it.

    (2) Make both the new Sels and dwa code outside the library,
        and link it directly to an executable:
        - Write a function to generate the new Sels in a Sela, and call
          fmorphautogen(sela, <N>, filename) to generate the code.
        - Compile your program that uses the newly generated function
          pixMorphDwa_<N>(), and link to the two new C files.

    (3) Make the new Sels in the library and use the dwa code outside it:
        - Add code in the library to generate your new brick Sels.
          (It is suggested that you NOT add these Sels to the
          selaAddBasic() function; write a new function that generates
          a new Sela.)
        - Recompile the library.
        - Write a small program that generates the Sela and calls
          fmorphautogen(sela, <N>, filename) to generate the code.
        - Compile your program that uses the newly generated function
          pixMorphDwa_<N>(), and link to the two new C files.
       As an example of this approach, see prog/dwamorph*_reg.c:
        - added selaAddDwaLinear() to sel2.c
        - wrote dwamorph1_reg.c, to generate the dwa code.
        - compiled and linked the generated code with the application,
          dwamorph2_reg.c.  (Note: because this was a regression test,
          dwamorph1_reg also builds and runs the application program.)

=head1 FUNCTIONS

=head2 getExtendedCompositeParameters

l_int32 getExtendedCompositeParameters ( l_int32 size, l_int32 *pn, l_int32 *pextra, l_int32 *pactualsize )

  getExtendedCompositeParameters()

      Input:  size (of linear Sel)
              &pn (<return> number of 63 wide convolutions)
              &pextra (<return> size of extra Sel)
              &actualsize (<optional return> actual size used in operation)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The DWA implementation allows Sels to be used with hits
          up to 31 pixels from the origin, either horizontally or
          vertically.  Larger Sels can be used if decomposed into
          a set of operations with Sels not exceeding 63 pixels
          in either width or height (and with the origin as close
          to the center of the Sel as possible).
      (2) This returns the decomposition of a linear Sel of length
          @size into a set of @n Sels of length 63 plus an extra
          Sel of length @extra.
      (3) For notation, let w == @size, n == @n, and e == @extra.
          We have 1 < e < 63.

          Then if w < 64, we have n = 0 and e = w.
          The general formula for w > 63 is:
             w = 63 + (n - 1) * 62 + (e - 1)

          Where did this come from?  Each successive convolution with
          a Sel of length L adds a total length (L - 1) to w.
          This accounts for using 62 for each additional Sel of size 63,
          and using (e - 1) for the additional Sel of size e.

          Solving for n and e for w > 63:
             n = 1 + Int((w - 63) / 62)
             e = w - 63 - (n - 1) * 62 + 1

          The extra part is decomposed into two factors f1 and f2,
          and the actual size of the extra part is
             e' = f1 * f2
          Then the actual width is:
             w' = 63 + (n - 1) * 62 + f1 * f2 - 1

=head2 pixCloseBrickDwa

PIX * pixCloseBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) This is a 'safe' closing; we add an extra border of 32 OFF
          pixels for the standard asymmetric b.c.
      (2) These implement 2D brick Sels, using linear Sels generated
          with selaAddBasic().
      (3) A brick Sel has hits for all elements.
      (4) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (5) Do separably if both hsize and vsize are > 1.
      (6) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (7) Note that we must always set or clear the border pixels
          before each operation, depending on the the b.c.
          (symmetric or asymmetric).
      (8) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (9) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseBrickDwa(NULL, pixs, ...);
          (b) pixCloseBrickDwa(pixs, pixs, ...);
          (c) pixCloseBrickDwa(pixd, pixs, ...);
      (10) The size of the result is determined by pixs.
      (11) If either linear Sel is not found, this calls
           the appropriate decomposible function.

=head2 pixCloseCompBrickDwa

PIX * pixCloseCompBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseCompBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) This implements a separable composite safe closing with 2D
          brick Sels.
      (2) For efficiency, it may decompose each linear morphological
          operation into two (brick + comb).
      (3) A brick Sel has hits for all elements.
      (4) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (5) Do separably if both hsize and vsize are > 1.
      (6) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixCloseCompBrickDwa(NULL, pixs, ...);
          (b) pixCloseCompBrickDwa(pixs, pixs, ...);
          (c) pixCloseCompBrickDwa(pixd, pixs, ...);
      (9) The size of pixd is determined by pixs.
      (10) CAUTION: both hsize and vsize are being decomposed.
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

=head2 pixCloseCompBrickExtendDwa

PIX * pixCloseCompBrickExtendDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseCompBrickExtendDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

      (1) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (2) There is no need to call this directly:  pixCloseCompBrickDwa()
          calls this function if either brick dimension exceeds 63.

=head2 pixDilateBrickDwa

PIX * pixDilateBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement 2D brick Sels, using linear Sels generated
          with selaAddBasic().
      (2) A brick Sel has hits for all elements.
      (3) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (4) Do separably if both hsize and vsize are > 1.
      (5) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (6) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (7) For clarity, if the case is known, use these patterns:
          (a) pixd = pixDilateBrickDwa(NULL, pixs, ...);
          (b) pixDilateBrickDwa(pixs, pixs, ...);
          (c) pixDilateBrickDwa(pixd, pixs, ...);
      (8) The size of pixd is determined by pixs.
      (9) If either linear Sel is not found, this calls
          the appropriate decomposible function.

=head2 pixDilateCompBrickDwa

PIX * pixDilateCompBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateCompBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement a separable composite dilation with 2D brick Sels.
      (2) For efficiency, it may decompose each linear morphological
          operation into two (brick + comb).
      (3) A brick Sel has hits for all elements.
      (4) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (5) Do separably if both hsize and vsize are > 1.
      (6) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixDilateCompBrickDwa(NULL, pixs, ...);
          (b) pixDilateCompBrickDwa(pixs, pixs, ...);
          (c) pixDilateCompBrickDwa(pixd, pixs, ...);
      (9) The size of pixd is determined by pixs.
      (10) CAUTION: both hsize and vsize are being decomposed.
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

=head2 pixDilateCompBrickExtendDwa

PIX * pixDilateCompBrickExtendDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateCompBrickExtendDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) Ankur Jain suggested and implemented extending the composite
          DWA operations beyond the 63 pixel limit.  This is a
          simplified and approximate implementation of the extension.
          This allows arbitrary Dwa morph operations using brick Sels,
          by decomposing the horizontal and vertical dilations into
          a sequence of 63-element dilations plus a dilation of size
          between 3 and 62.
      (2) The 63-element dilations are exact, whereas the extra dilation
          is approximate, because the underlying decomposition is
          in pixDilateCompBrickDwa().  See there for further details.
      (3) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (4) There is no need to call this directly:  pixDilateCompBrickDwa()
          calls this function if either brick dimension exceeds 63.

=head2 pixErodeBrickDwa

PIX * pixErodeBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement 2D brick Sels, using linear Sels generated
          with selaAddBasic().
      (2) A brick Sel has hits for all elements.
      (3) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (4) Do separably if both hsize and vsize are > 1.
      (5) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (6) Note that we must always set or clear the border pixels
          before each operation, depending on the the b.c.
          (symmetric or asymmetric).
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixErodeBrickDwa(NULL, pixs, ...);
          (b) pixErodeBrickDwa(pixs, pixs, ...);
          (c) pixErodeBrickDwa(pixd, pixs, ...);
      (9) The size of the result is determined by pixs.
      (10) If either linear Sel is not found, this calls
           the appropriate decomposible function.

=head2 pixErodeCompBrickDwa

PIX * pixErodeCompBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeCompBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement a separable composite erosion with 2D brick Sels.
      (2) For efficiency, it may decompose each linear morphological
          operation into two (brick + comb).
      (3) A brick Sel has hits for all elements.
      (4) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (5) Do separably if both hsize and vsize are > 1.
      (6) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixErodeCompBrickDwa(NULL, pixs, ...);
          (b) pixErodeCompBrickDwa(pixs, pixs, ...);
          (c) pixErodeCompBrickDwa(pixd, pixs, ...);
      (9) The size of pixd is determined by pixs.
      (10) CAUTION: both hsize and vsize are being decomposed.
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

=head2 pixErodeCompBrickExtendDwa

PIX * pixErodeCompBrickExtendDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeCompBrickExtendDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) See pixDilateCompBrickExtendDwa() for usage.
      (2) There is no need to call this directly:  pixErodeCompBrickDwa()
          calls this function if either brick dimension exceeds 63.

=head2 pixOpenBrickDwa

PIX * pixOpenBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement 2D brick Sels, using linear Sels generated
          with selaAddBasic().
      (2) A brick Sel has hits for all elements.
      (3) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (4) Do separably if both hsize and vsize are > 1.
      (5) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (6) Note that we must always set or clear the border pixels
          before each operation, depending on the the b.c.
          (symmetric or asymmetric).
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpenBrickDwa(NULL, pixs, ...);
          (b) pixOpenBrickDwa(pixs, pixs, ...);
          (c) pixOpenBrickDwa(pixd, pixs, ...);
      (9) The size of the result is determined by pixs.
      (10) If either linear Sel is not found, this calls
           the appropriate decomposible function.

=head2 pixOpenCompBrickDwa

PIX * pixOpenCompBrickDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenCompBrickDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

  Notes:
      (1) These implement a separable composite opening with 2D brick Sels.
      (2) For efficiency, it may decompose each linear morphological
          operation into two (brick + comb).
      (3) A brick Sel has hits for all elements.
      (4) The origin of the Sel is at (x, y) = (hsize/2, vsize/2)
      (5) Do separably if both hsize and vsize are > 1.
      (6) It is necessary that both horizontal and vertical Sels
          of the input size are defined in the basic sela.
      (7) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (8) For clarity, if the case is known, use these patterns:
          (a) pixd = pixOpenCompBrickDwa(NULL, pixs, ...);
          (b) pixOpenCompBrickDwa(pixs, pixs, ...);
          (c) pixOpenCompBrickDwa(pixd, pixs, ...);
      (9) The size of pixd is determined by pixs.
      (10) CAUTION: both hsize and vsize are being decomposed.
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

=head2 pixOpenCompBrickExtendDwa

PIX * pixOpenCompBrickExtendDwa ( PIX *pixd, PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenCompBrickExtendDwa()

      Input:  pixd  (<optional>; this can be null, equal to pixs,
                     or different from pixs)
              pixs (1 bpp)
              hsize (width of brick Sel)
              vsize (height of brick Sel)
      Return: pixd

      (1) There are three cases:
          (a) pixd == null   (result into new pixd)
          (b) pixd == pixs   (in-place; writes result back to pixs)
          (c) pixd != pixs   (puts result into existing pixd)
      (2) There is no need to call this directly:  pixOpenCompBrickDwa()
          calls this function if either brick dimension exceeds 63.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
