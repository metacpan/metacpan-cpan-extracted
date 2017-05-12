package Image::Leptonica::Func::rotateorthlow;
$Image::Leptonica::Func::rotateorthlow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rotateorthlow

=head1 VERSION

version 0.04

=head1 C<rotateorthlow.c>

  rotateorthlow.c

      90-degree rotation (cw)
            void      rotate90Low()

      LR-flip
            void      flipLRLow()

      TB-flip
            void      flipTBLow()

      Byte reverse tables
            l_uint8  *makeReverseByteTab1()
            l_uint8  *makeReverseByteTab2()
            l_uint8  *makeReverseByteTab4()

=head1 FUNCTIONS

=head2 flipLRLow

void flipLRLow ( l_uint32 *data, l_int32 w, l_int32 h, l_int32 d, l_int32 wpl, l_uint8 *tab, l_uint32 *buffer )

  flipLRLow()

  Notes:
      (1) The pixel access routines allow a trivial implementation.
          However, for d < 8, it is more efficient to right-justify
          each line to a 32-bit boundary and then extract bytes and
          do pixel reversing.   In those cases, as in the 180 degree
          rotation, we right-shift the data (if necessary) to
          right-justify on the 32 bit boundary, and then read the
          bytes off each raster line in reverse order, reversing
          the pixels in each byte using a table.  These functions
          for 1, 2 and 4 bpp were tested against the "trivial"
          version (shown here for 4 bpp):
              for (i = 0; i < h; i++) {
                  line = data + i * wpl;
                  memcpy(buffer, line, bpl);
                    for (j = 0; j < w; j++) {
                      val = GET_DATA_QBIT(buffer, w - 1 - j);
                        SET_DATA_QBIT(line, j, val);
                  }
              }
      (2) This operation is in-place.

=head2 flipTBLow

void flipTBLow ( l_uint32 *data, l_int32 h, l_int32 wpl, l_uint32 *buffer )

  flipTBLow()

  Notes:
      (1) This is simple and fast.  We use the memcpy function
          to do all the work on aligned data, regardless of pixel
          depth.
      (2) This operation is in-place.

=head2 makeReverseByteTab1

l_uint8 * makeReverseByteTab1 ( void )

  makeReverseByteTab1()

  Notes:
      (1) This generates an 8 bit lookup table for reversing
          the order of eight 1-bit pixels.

=head2 makeReverseByteTab2

l_uint8 * makeReverseByteTab2 ( void )

  makeReverseByteTab2()

  Notes:
      (1) This generates an 8 bit lookup table for reversing
          the order of four 2-bit pixels.

=head2 makeReverseByteTab4

l_uint8 * makeReverseByteTab4 ( void )

  makeReverseByteTab4()

  Notes:
      (1) This generates an 8 bit lookup table for reversing
          the order of two 4-bit pixels.

=head2 rotate90Low

void rotate90Low ( l_uint32 *datad, l_int32 wd, l_int32 hd, l_int32 d, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 direction )

  rotate90Low()

      direction:  1 for cw rotation
                 -1 for ccw rotation

  Notes:
      (1) The dest must be cleared in advance because not
          all source pixels are written to the destination.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
