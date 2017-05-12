package Image::Leptonica::Func::arrayaccess;
$Image::Leptonica::Func::arrayaccess::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::arrayaccess

=head1 VERSION

version 0.04

=head1 C<arrayaccess.c>

  arrayaccess.c

     Access within an array of 32-bit words

           l_int32     l_getDataBit()
           void        l_setDataBit()
           void        l_clearDataBit()
           void        l_setDataBitVal()
           l_int32     l_getDataDibit()
           void        l_setDataDibit()
           void        l_clearDataDibit()
           l_int32     l_getDataQbit()
           void        l_setDataQbit()
           void        l_clearDataQbit()
           l_int32     l_getDataByte()
           void        l_setDataByte()
           l_int32     l_getDataTwoBytes()
           void        l_setDataTwoBytes()
           l_int32     l_getDataFourBytes()
           void        l_setDataFourBytes()

     Note that these all require 32-bit alignment, and hence an input
     ptr to l_uint32.  However, this is not enforced by the compiler.
     Instead, we allow the use of a void* ptr, because the line ptrs
     are an efficient way to get random access (see pixGetLinePtrs()).
     It is then necessary to cast internally within each function
     because ptr arithmetic requires knowing the size of the units
     being referenced.

=head1 FUNCTIONS

=head2 l_clearDataBit

void l_clearDataBit ( void *line, l_int32 n )

  l_clearDataBit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: void

  Action: sets the (1-bit) pixel to 0

=head2 l_clearDataDibit

void l_clearDataDibit ( void *line, l_int32 n )

  l_clearDataDibit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: void

  Action: sets the (2-bit) pixel to 0

=head2 l_clearDataQbit

void l_clearDataQbit ( void *line, l_int32 n )

  l_clearDataQbit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: void

  Action: sets the (4-bit) pixel to 0

=head2 l_getDataBit

l_int32 l_getDataBit ( void *line, l_int32 n )

  l_getDataBit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: val of the nth (1-bit) pixel.

=head2 l_getDataByte

l_int32 l_getDataByte ( void *line, l_int32 n )

  l_getDataByte()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: value of the n-th (byte) pixel

=head2 l_getDataDibit

l_int32 l_getDataDibit ( void *line, l_int32 n )

  l_getDataDibit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: val of the nth (2-bit) pixel.

=head2 l_getDataFourBytes

l_int32 l_getDataFourBytes ( void *line, l_int32 n )

  l_getDataFourBytes()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: value of the n-th (4-byte) pixel

=head2 l_getDataQbit

l_int32 l_getDataQbit ( void *line, l_int32 n )

  l_getDataQbit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: val of the nth (4-bit) pixel.

=head2 l_getDataTwoBytes

l_int32 l_getDataTwoBytes ( void *line, l_int32 n )

  l_getDataTwoBytes()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: value of the n-th (2-byte) pixel

=head2 l_setDataBit

void l_setDataBit ( void *line, l_int32 n )

  l_setDataBit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
      Return: void

  Action: sets the pixel to 1

=head2 l_setDataBitVal

void l_setDataBitVal ( void *line, l_int32 n, l_int32 val )

  l_setDataBitVal()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 or 1)
      Return: void

  Notes:
      (1) This is an accessor for a 1 bpp pix.
      (2) It is actually a little slower than using:
            if (val == 0)
                l_ClearDataBit(line, n);
            else
                l_SetDataBit(line, n);

=head2 l_setDataByte

void l_setDataByte ( void *line, l_int32 n, l_int32 val )

  l_setDataByte()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 - 0xff)
      Return: void

=head2 l_setDataDibit

void l_setDataDibit ( void *line, l_int32 n, l_int32 val )

  l_setDataDibit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 - 3)
      Return: void

=head2 l_setDataFourBytes

void l_setDataFourBytes ( void *line, l_int32 n, l_int32 val )

  l_setDataFourBytes()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 - 0xffffffff)
      Return: void

=head2 l_setDataQbit

void l_setDataQbit ( void *line, l_int32 n, l_int32 val )

  l_setDataQbit()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 - 0xf)
      Return: void

=head2 l_setDataTwoBytes

void l_setDataTwoBytes ( void *line, l_int32 n, l_int32 val )

  l_setDataTwoBytes()

      Input:  line  (ptr to beginning of data line)
              n     (pixel index)
              val   (val to be inserted: 0 - 0xffff)
      Return: void

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
