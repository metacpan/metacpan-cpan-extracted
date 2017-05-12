package Image::Leptonica::Func::rotateamlow;
$Image::Leptonica::Func::rotateamlow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rotateamlow

=head1 VERSION

version 0.04

=head1 C<rotateamlow.c>

  rotateamlow.c

      Grayscale and color rotation (area mapped)

          32 bpp grayscale rotation about image center
               void    rotateAMColorLow()

          8 bpp grayscale rotation about image center
               void    rotateAMGrayLow()

          32 bpp grayscale rotation about UL corner of image
               void    rotateAMColorCornerLow()

          8 bpp grayscale rotation about UL corner of image
               void    rotateAMGrayCornerLow()

          Fast RGB color rotation about center:
               void    rotateAMColorFastLow()

=head1 FUNCTIONS

=head2 rotateAMColorFastLow

void rotateAMColorFastLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_float32 angle, l_uint32 colorval )

  rotateAMColorFastLow()

     This is a special simplification of area mapping with division
     of each pixel into 16 sub-pixels.  The exact coefficients that
     should be used are the same as for the 4x linear interpolation
     scaling case, and are given there.  I tried to approximate these
     as weighted coefficients with a maximum sum of 4, which
     allows us to do the arithmetic in parallel for the R, G and B
     components in a 32 bit pixel.  However, there are three reasons
     for not doing that:
        (1) the loss of accuracy in the parallel implementation
            is visually significant
        (2) the parallel implementation (described below) is slower
        (3) the parallel implementation requires allocation of
            a temporary color image

     There are 16 cases for the choice of the subpixel, and
     for each, the mapping to the relevant source
     pixels is as follows:

      subpixel      src pixel weights
      --------      -----------------
         0          sp1
         1          (3 * sp1 + sp2) / 4
         2          (sp1 + sp2) / 2
         3          (sp1 + 3 * sp2) / 4
         4          (3 * sp1 + sp3) / 4
         5          (9 * sp1 + 3 * sp2 + 3 * sp3 + sp4) / 16
         6          (3 * sp1 + 3 * sp2 + sp3 + sp4) / 8
         7          (3 * sp1 + 9 * sp2 + sp3 + 3 * sp4) / 16
         8          (sp1 + sp3) / 2
         9          (3 * sp1 + sp2 + 3 * sp3 + sp4) / 8
         10         (sp1 + sp2 + sp3 + sp4) / 4
         11         (sp1 + 3 * sp2 + sp3 + 3 * sp4) / 8
         12         (sp1 + 3 * sp3) / 4
         13         (3 * sp1 + sp2 + 9 * sp3 + 3 * sp4) / 16
         14         (sp1 + sp2 + 3 * sp3 + 3 * sp4) / 8
         15         (sp1 + 3 * sp2 + 3 * sp3 + 9 * sp4) / 16

     Another way to visualize this is to consider the area mapping
     (or linear interpolation) coefficients  for the pixel sp1.
     Expressed in fourths, they can be written as asymmetric matrix:

           4      3      2      1
           3      2.25   1.5    0.75
           2      1.5    1      0.5
           1      0.75   0.5    0.25

     The coefficients for the three neighboring pixels can be
     similarly written.

     This is implemented here, where, for each color component,
     we inline its extraction from each participating word,
     construct the linear combination, and combine the results
     into the destination 32 bit RGB pixel, using the appropriate shifts.

     It is interesting to note that an alternative method, where
     we do the arithmetic on the 32 bit pixels directly (after
     shifting the components so they won't overflow into each other)
     is significantly inferior.  Because we have only 8 bits for
     internal overflows, which can be distributed as 2, 3, 3, it
     is impossible to add these with the correct linear
     interpolation coefficients, which require a sum of up to 16.
     Rounding off to a sum of 4 causes appreciable visual artifacts
     in the rotated image.  The code for the inferior method
     can be found in prog/rotatefastalt.c, for reference.

     *** Warning: explicit assumption about RGB component ordering 

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
