package Image::Leptonica::Func::bardecode;
$Image::Leptonica::Func::bardecode::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::bardecode

=head1 VERSION

version 0.04

=head1 C<bardecode.c>

  bardecode.c

      Dispatcher
          char            *barcodeDispatchDecoder()

      Format Determination
          static l_int32   barcodeFindFormat()
          l_int32          barcodeFormatIsSupported()
          static l_int32   barcodeVerifyFormat()

      Decode 2 of 5
          static char     *barcodeDecode2of5()

      Decode Interleaved 2 of 5
          static char     *barcodeDecodeI2of5()

      Decode Code 93
          static char     *barcodeDecode93()

      Decode Code 39
          static char     *barcodeDecode39()

      Decode Codabar
          static char     *barcodeDecodeCodabar()

      Decode UPC-A
          static char     *barcodeDecodeUpca()

      Decode EAN 13
          static char     *barcodeDecodeEan13()

=head1 FUNCTIONS

=head2 barcodeDispatchDecoder

char * barcodeDispatchDecoder ( char *barstr, l_int32 format, l_int32 debugflag )

  barcodeDispatchDecoder()

      Input:  barstr (string of integers in set {1,2,3,4} of bar widths)
              format (L_BF_ANY, L_BF_CODEI2OF5, L_BF_CODE93, ...)
              debugflag (use 1 to generate debug output)
      Return: data (string of decoded barcode data), or null on error

=head2 barcodeFormatIsSupported

l_int32 barcodeFormatIsSupported ( l_int32 format )

  barcodeFormatIsSupported()

      Input:  format
      Return: 1 if format is one of those supported; 0 otherwise

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
