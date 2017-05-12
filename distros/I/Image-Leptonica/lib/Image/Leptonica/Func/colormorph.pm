package Image::Leptonica::Func::colormorph;
$Image::Leptonica::Func::colormorph::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::colormorph

=head1 VERSION

version 0.04

=head1 C<colormorph.c>

  colormorph.c

      Top-level color morphological operations

            PIX     *pixColorMorph()

      Method: Algorithm by van Herk and Gil and Werman, 1992
              Apply grayscale morphological operations separately
              to each component.

=head1 FUNCTIONS

=head2 pixColorMorph

PIX * pixColorMorph ( PIX *pixs, l_int32 type, l_int32 hsize, l_int32 vsize )

  pixColorMorph()

      Input:  pixs
              type  (L_MORPH_DILATE, L_MORPH_ERODE, L_MORPH_OPEN,
                     or L_MORPH_CLOSE)
              hsize  (of Sel; must be odd; origin implicitly in center)
              vsize  (ditto)
      Return: pixd

  Notes:
      (1) This does the morph operation on each component separately,
          and recombines the result.
      (2) Sel is a brick with all elements being hits.
      (3) If hsize = vsize = 1, just returns a copy.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
