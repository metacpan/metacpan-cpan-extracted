package Image::Leptonica::Func::zlibmem;
$Image::Leptonica::Func::zlibmem::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::zlibmem

=head1 VERSION

version 0.04

=head1 C<zlibmem.c>

   zlibmem.c

      zlib operations in memory, using bbuffer
          l_uint8   *zlibCompress()
          l_uint8   *zlibUncompress()


    This provides an example use of the byte buffer utility
    (see bbuffer.c for details of how the bbuffer works internally).
    We use zlib to compress and decompress a byte array from
    one memory buffer to another.  The standard method uses streams,
    but here we use the bbuffer as an expandable queue of pixels
    for both the reading and writing sides of each operation.

    With memory mapping, one should be able to compress between
    memory buffers by using the file system to buffer everything in
    the background, but the bbuffer implementation is more portable.

=head1 FUNCTIONS

=head2 zlibCompress

l_uint8 * zlibCompress ( l_uint8 *datain, size_t nin, size_t *pnout )

  zlibCompress()

      Input:  datain (byte buffer with input data)
              nin    (number of bytes of input data)
              &nout  (<return> number of bytes of output data)
      Return: dataout (compressed data), or null on error

  Notes:
      (1) We repeatedly read in and fill up an input buffer,
          compress the data, and read it back out.  zlib
          uses two byte buffers internally in the z_stream
          data structure.  We use the bbuffers to feed data
          into the fixed bufferin, and feed it out of bufferout,
          in the same way that a pair of streams would normally
          be used if the data were being read from one file
          and written to another.  This is done iteratively,
          compressing L_BUF_SIZE bytes of input data at a time.

=head2 zlibUncompress

l_uint8 * zlibUncompress ( l_uint8 *datain, size_t nin, size_t *pnout )

  zlibUncompress()

      Input:  datain (byte buffer with compressed input data)
              nin    (number of bytes of input data)
              &nout  (<return> number of bytes of output data)
      Return: dataout (uncompressed data), or null on error

  Notes:
      (1) See zlibCompress().

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
