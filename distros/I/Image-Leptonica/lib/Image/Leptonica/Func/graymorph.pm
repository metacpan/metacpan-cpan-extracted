package Image::Leptonica::Func::graymorph;
$Image::Leptonica::Func::graymorph::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::graymorph

=head1 VERSION

version 0.04

=head1 C<graymorph.c>

  graymorph.c

      Top-level binary morphological operations (van Herk / Gil-Werman)
            PIX     *pixErodeGray()
            PIX     *pixDilateGray()
            PIX     *pixOpenGray()
            PIX     *pixCloseGray()

      Special operations for 1x3, 3x1 and 3x3 Sels  (direct)
            PIX     *pixErodeGray3()
            PIX     *pixDilateGray3()
            PIX     *pixOpenGray3()
            PIX     *pixCloseGray3()


      Method: Algorithm by van Herk and Gil and Werman, 1992

      Measured speed of the vH/G-W implementation is about 1 output
      pixel per 120 PIII clock cycles, for a horizontal or vertical
      erosion or dilation.  The computation time doubles for opening
      or closing, or for a square SE, as expected, and is independent
      of the size of the SE.

      A faster implementation can be made directly for brick Sels
      of maximum size 3.  We unroll the computation for sets of 8 bytes.
      It needs to be called explicitly; the general functions do not
      default for the size 3 brick Sels.

=head1 FUNCTIONS

=head2 pixCloseGray

PIX * pixCloseGray ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseGray()

      Input:  pixs
              hsize  (of Sel; must be odd; origin implicitly in center)
              vsize  (ditto)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixCloseGray3

PIX * pixCloseGray3 ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixCloseGray3()

      Input:  pixs (8 bpp, not cmapped)
              hsize  (1 or 3)
              vsize  (1 or 3)
      Return: pixd, or null on error

  Notes:
      (1) Special case for 1x3, 3x1 or 3x3 brick sel (all hits)
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixDilateGray

PIX * pixDilateGray ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateGray()

      Input:  pixs
              hsize  (of Sel; must be odd; origin implicitly in center)
              vsize  (ditto)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixDilateGray3

PIX * pixDilateGray3 ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixDilateGray3()

      Input:  pixs (8 bpp, not cmapped)
              hsize  (1 or 3)
              vsize  (1 or 3)
      Return: pixd, or null on error

  Notes:
      (1) Special case for 1x3, 3x1 or 3x3 brick sel (all hits)
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixErodeGray

PIX * pixErodeGray ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeGray()

      Input:  pixs
              hsize  (of Sel; must be odd; origin implicitly in center)
              vsize  (ditto)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixErodeGray3

PIX * pixErodeGray3 ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixErodeGray3()

      Input:  pixs (8 bpp, not cmapped)
              hsize  (1 or 3)
              vsize  (1 or 3)
      Return: pixd, or null on error

  Notes:
      (1) Special case for 1x3, 3x1 or 3x3 brick sel (all hits)
      (2) If hsize = vsize = 1, just returns a copy.
      (3) It would be nice not to add a border, but it is required
          if we want the same results as from the general case.
          We add 4 bytes on the left to speed up the copying, and
          8 bytes at the right and bottom to allow unrolling of
          the computation of 8 pixels.

=head2 pixOpenGray

PIX * pixOpenGray ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenGray()

      Input:  pixs
              hsize  (of Sel; must be odd; origin implicitly in center)
              vsize  (ditto)
      Return: pixd

  Notes:
      (1) Sel is a brick with all elements being hits
      (2) If hsize = vsize = 1, just returns a copy.

=head2 pixOpenGray3

PIX * pixOpenGray3 ( PIX *pixs, l_int32 hsize, l_int32 vsize )

  pixOpenGray3()

      Input:  pixs (8 bpp, not cmapped)
              hsize  (1 or 3)
              vsize  (1 or 3)
      Return: pixd, or null on error

  Notes:
      (1) Special case for 1x3, 3x1 or 3x3 brick sel (all hits)
      (2) If hsize = vsize = 1, just returns a copy.
      (3) It would be nice not to add a border, but it is required
          to get the same results as for the general case.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
