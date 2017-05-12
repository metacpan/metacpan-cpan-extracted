package Image::Leptonica::Func::roplow;
$Image::Leptonica::Func::roplow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::roplow

=head1 VERSION

version 0.04

=head1 C<roplow.c>

  roplow.c

      Low level dest-only
           void            rasteropUniLow()
           static void     rasteropUniWordAlignedlLow()
           static void     rasteropUniGeneralLow()

      Low level src and dest
           void            rasteropLow()
           static void     rasteropWordAlignedLow()
           static void     rasteropVAlignedLow()
           static void     rasteropGeneralLow()

=head1 FUNCTIONS

=head2 rasteropLow

void rasteropLow ( l_uint32 *datad, l_int32 dpixw, l_int32 dpixh, l_int32 depth, l_int32 dwpl, l_int32 dx, l_int32 dy, l_int32 dw, l_int32 dh, l_int32 op, l_uint32 *datas, l_int32 spixw, l_int32 spixh, l_int32 swpl, l_int32 sx, l_int32 sy )

  rasteropLow()

      Input:  datad  (ptr to dest image data)
              dpixw  (width of dest)
              dpixh  (height of dest)
              depth  (depth of src and dest)
              dwpl   (wpl of dest)
              dx     (x val of UL corner of dest rectangle)
              dy     (y val of UL corner of dest rectangle)
              dw     (width of dest rectangle)
              dh     (height of dest rectangle)
              op     (op code)
              datas  (ptr to src image data)
              spixw  (width of src)
              spixh  (height of src)
              swpl   (wpl of src)
              sx     (x val of UL corner of src rectangle)
              sy     (y val of UL corner of src rectangle)
      Return: void

  Action: Scales width, performs clipping, checks alignment, and
          dispatches for the rasterop.

  Warning: the two images must have equal depth.  This is not checked.

=head2 rasteropUniLow

void rasteropUniLow ( l_uint32 *datad, l_int32 dpixw, l_int32 dpixh, l_int32 depth, l_int32 dwpl, l_int32 dx, l_int32 dy, l_int32 dw, l_int32 dh, l_int32 op )

  rasteropUniLow()

      Input:  datad  (ptr to dest image data)
              dpixw  (width of dest)
              dpixh  (height of dest)
              depth  (depth of src and dest)
              dwpl   (wpl of dest)
              dx     (x val of UL corner of dest rectangle)
              dy     (y val of UL corner of dest rectangle)
              dw     (width of dest rectangle)
              dh     (height of dest rectangle)
              op     (op code)
      Return: void

  Action: scales width, performs clipping, checks alignment, and
          dispatches for the rasterop.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
