package Image::Leptonica::Func::ropiplow;
$Image::Leptonica::Func::ropiplow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ropiplow

=head1 VERSION

version 0.04

=head1 C<ropiplow.c>

  ropiplow.c

      Low level in-place full height vertical block transfer

           void     rasteropVipLow()

      Low level in-place full width horizontal block transfer

           void     rasteropHipLow()
           void     shiftDataHorizontalLow()

=head1 FUNCTIONS

=head2 rasteropHipLow

void rasteropHipLow ( l_uint32 *data, l_int32 pixh, l_int32 depth, l_int32 wpl, l_int32 y, l_int32 h, l_int32 shift )

  rasteropHipLow()

      Input:  data   (ptr to image data)
              pixh   (height)
              depth  (depth)
              wpl    (wpl)
              y      (y val of UL corner of rectangle)
              h      (height of rectangle)
              shift  (+ shifts data to the left in a horizontal column)
      Return: 0 if OK; 1 on error.

  Notes:
      (1) This clears the pixels that are left exposed after the rasterop.
          Therefore, for Pix with depth > 1, these pixels become black,
          and must be subsequently SET if they are to be white.
          For example, see pixRasteropHip().
      (2) This function performs clipping and calls shiftDataHorizontalLine()
          to do the in-place rasterop on each line.

=head2 rasteropVipLow

void rasteropVipLow ( l_uint32 *data, l_int32 pixw, l_int32 pixh, l_int32 depth, l_int32 wpl, l_int32 x, l_int32 w, l_int32 shift )

  rasteropVipLow()

      Input:  data   (ptr to image data)
              pixw   (width)
              pixh   (height)
              depth  (depth)
              wpl    (wpl)
              x      (x val of UL corner of rectangle)
              w      (width of rectangle)
              shift  (+ shifts data downward in vertical column)
      Return: 0 if OK; 1 on error.

  Notes:
      (1) This clears the pixels that are left exposed after the
          translation.  You can consider them as pixels that are
          shifted in from outside the image.  This can be later
          overridden by the incolor parameter in higher-level functions
          that call this.  For example, for images with depth > 1,
          these pixels are cleared to black; to be white they
          must later be SET to white.  See, e.g., pixRasteropVip().
      (2) This function scales the width to accommodate any depth,
          performs clipping, and then does the in-place rasterop.

=head2 shiftDataHorizontalLow

void shiftDataHorizontalLow ( l_uint32 *datad, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 shift )

  shiftDataHorizontalLow()

      Input:  datad  (ptr to beginning of dest line)
              wpld   (wpl of dest)
              datas  (ptr to beginning of src line)
              wpls   (wpl of src)
              shift  (horizontal shift of block; >0 is to right)
      Return: void

  Notes:
      (1) This can also be used for in-place operation; see, e.g.,
          rasteropHipLow().
      (2) We are clearing the pixels that are shifted in from
          outside the image.  This can be overridden by the
          incolor parameter in higher-level functions that call this.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
