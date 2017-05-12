package Image::Leptonica::Func::pixacc;
$Image::Leptonica::Func::pixacc::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixacc

=head1 VERSION

version 0.04

=head1 C<pixacc.c>

   pixacc.c

      Pixacc creation, destruction
           PIXACC   *pixaccCreate()
           PIXACC   *pixaccCreateFromPix()
           void      pixaccDestroy()

      Pixacc finalization
           PIX      *pixaccFinal()

      Pixacc accessors
           PIX      *pixaccGetPix()
           l_int32   pixaccGetOffset()

      Pixacc accumulators
           l_int32   pixaccAdd()
           l_int32   pixaccSubtract()
           l_int32   pixaccMultConst()
           l_int32   pixaccMultConstAccumulate()

  This is a simple interface for some of the pixel arithmetic operations
  in pixarith.c.  These are easy to code up, but not as fast as
  hand-coded functions that do arithmetic on corresponding pixels.

  Suppose you want to make a linear combination of pix1 and pix2:
     pixd = 0.4 * pix1 + 0.6 * pix2
  where pix1 and pix2 are the same size and have depth 'd'.  Then:
     Pixacc *pacc = pixaccCreateFromPix(pix1, 0);  // first; addition only
     pixaccMultConst(pacc, 0.4);
     pixaccMultConstAccumulate(pacc, pix2, 0.6);  // Add in 0.6 of the second
     pixd = pixaccFinal(pacc, d);  // Get the result
     pixaccDestroy(&pacc);

=head1 FUNCTIONS

=head2 pixaccAdd

l_int32 pixaccAdd ( PIXACC *pixacc, PIX *pix )

  pixaccAdd()

      Input:  pixacc
              pix (to be added)
      Return: 0 if OK, 1 on error

=head2 pixaccCreate

PIXACC * pixaccCreate ( l_int32 w, l_int32 h, l_int32 negflag )

  pixaccCreate()

      Input:  w, h (of 32 bpp internal Pix)
              negflag (0 if only positive numbers are involved;
                       1 if there will be negative numbers)
      Return: pixacc, or null on error

  Notes:
      (1) Use @negflag = 1 for safety if any negative numbers are going
          to be used in the chain of operations.  Negative numbers
          arise, e.g., by subtracting a pix, or by adding a pix
          that has been pre-multiplied by a negative number.
      (2) Initializes the internal 32 bpp pix, similarly to the
          initialization in pixInitAccumulate().

=head2 pixaccCreateFromPix

PIXACC * pixaccCreateFromPix ( PIX *pix, l_int32 negflag )

  pixaccCreateFromPix()

      Input:  pix
              negflag (0 if only positive numbers are involved;
                       1 if there will be negative numbers)
      Return: pixacc, or null on error

  Notes:
      (1) See pixaccCreate()

=head2 pixaccDestroy

void pixaccDestroy ( PIXACC **ppixacc )

  pixaccDestroy()

      Input:  &pixacc (<can be null>)
      Return: void

  Notes:
      (1) Always nulls the input ptr.

=head2 pixaccFinal

PIX * pixaccFinal ( PIXACC *pixacc, l_int32 outdepth )

  pixaccFinal()

      Input:  pixacc
              outdepth (8, 16 or 32 bpp)
      Return: pixd (8 , 16 or 32 bpp), or null on error

=head2 pixaccGetOffset

l_int32 pixaccGetOffset ( PIXACC *pixacc )

  pixaccGetOffset()

      Input:  pixacc
      Return: offset, or -1 on error

=head2 pixaccGetPix

PIX * pixaccGetPix ( PIXACC *pixacc )

  pixaccGetPix()

      Input:  pixacc
      Return: pix, or null on error

=head2 pixaccMultConst

l_int32 pixaccMultConst ( PIXACC *pixacc, l_float32 factor )

  pixaccMultConst()

      Input:  pixacc
              factor
      Return: 0 if OK, 1 on error

=head2 pixaccMultConstAccumulate

l_int32 pixaccMultConstAccumulate ( PIXACC *pixacc, PIX *pix, l_float32 factor )

  pixaccMultConstAccumulate()

      Input:  pixacc
              pix
              factor
      Return: 0 if OK, 1 on error

  Notes:
      (1) This creates a temp pix that is @pix multiplied by the
          constant @factor.  It then adds that into @pixacc.

=head2 pixaccSubtract

l_int32 pixaccSubtract ( PIXACC *pixacc, PIX *pix )

  pixaccSubtract()

      Input:  pixacc
              pix (to be subtracted)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
