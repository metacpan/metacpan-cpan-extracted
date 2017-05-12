package Image::Leptonica::Func::spixio;
$Image::Leptonica::Func::spixio::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::spixio

=head1 VERSION

version 0.04

=head1 C<spixio.c>

  spixio.c

    This does fast serialization of a pix in memory to file,
    copying the raw data for maximum speed.  The underlying
    function serializes it to memory, and it is wrapped to be
    callable from standard pixRead and pixWrite functions.

      Reading spix from file
           PIX        *pixReadStreamSpix()
           l_int32     readHeaderSpix()
           l_int32     freadHeaderSpix()
           l_int32     sreadHeaderSpix()

      Writing spix to file
           l_int32     pixWriteStreamSpix()

      Low-level serialization of pix to/from memory (uncompressed)
           PIX        *pixReadMemSpix()
           l_int32     pixWriteMemSpix()
           l_int32     pixSerializeToMemory()
           PIX        *pixDeserializeFromMemory()

=head1 FUNCTIONS

=head2 freadHeaderSpix

l_int32 freadHeaderSpix ( FILE *fp, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  freadHeaderSpix()

      Input:  stream
              &width (<return>)
              &height (<return>)
              &bps (<return>, bits/sample)
              &spp (<return>, samples/pixel)
              &iscmap (<optional return>; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, iscmap is returned as 1; else 0.

=head2 pixDeserializeFromMemory

PIX * pixDeserializeFromMemory ( const l_uint32 *data, size_t nbytes )

  pixDeserializeFromMemory()

      Input:  data (serialized data in memory)
              nbytes (number of bytes in data string)
      Return: pix, or NULL on error

  Notes:
      (1) See pixSerializeToMemory() for the binary format.

=head2 pixReadMemSpix

PIX * pixReadMemSpix ( const l_uint8 *data, size_t size )

  pixReadMemSpix()

      Input:  data (const; uncompressed)
              size (of data)
      Return: pix, or null on error

=head2 pixReadStreamSpix

PIX * pixReadStreamSpix ( FILE *fp )

  pixReadStreamSpix()

      Input:  stream
      Return: pix, or null on error.

  Notes:
      (1) If called from pixReadStream(), the stream is positioned
          at the beginning of the file.

=head2 pixSerializeToMemory

l_int32 pixSerializeToMemory ( PIX *pixs, l_uint32 **pdata, size_t *pnbytes )

  pixSerializeToMemory()

      Input:  pixs (all depths, colormap OK)
              &data (<return> serialized data in memory)
              &nbytes (<return> number of bytes in data string)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a fast serialization of the principal elements
          of the pix, as follows:
            "spix"    (4 bytes) -- ID for file type
            w         (4 bytes)
            h         (4 bytes)
            d         (4 bytes)
            wpl       (4 bytes)
            ncolors   (4 bytes) -- in colormap; 0 if there is no colormap
            cdata     (4 * ncolors)  -- size of serialized colormap array
            rdatasize (4 bytes) -- size of serialized raster data
                                   = 4 * wpl * h
            rdata     (rdatasize)

=head2 pixWriteMemSpix

l_int32 pixWriteMemSpix ( l_uint8 **pdata, size_t *psize, PIX *pix )

  pixWriteMemSpix()

      Input:  &data (<return> data of serialized, uncompressed pix)
              &size (<return> size of returned data)
              pix (all depths; colormap OK)
      Return: 0 if OK, 1 on error

=head2 pixWriteStreamSpix

l_int32 pixWriteStreamSpix ( FILE *fp, PIX *pix )

  pixWriteStreamSpix()

      Input:  stream
              pix
      Return: 0 if OK; 1 on error

=head2 readHeaderSpix

l_int32 readHeaderSpix ( const char *filename, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  readHeaderSpix()

      Input:  filename
              &width (<return>)
              &height (<return>)
              &bps (<return>, bits/sample)
              &spp (<return>, samples/pixel)
              &iscmap (<optional return>; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, iscmap is returned as 1; else 0.

=head2 sreadHeaderSpix

l_int32 sreadHeaderSpix ( const l_uint32 *data, l_int32 *pwidth, l_int32 *pheight, l_int32 *pbps, l_int32 *pspp, l_int32 *piscmap )

  sreadHeaderSpix()

      Input:  data
              &width (<return>)
              &height (<return>)
              &bps (<return>, bits/sample)
              &spp (<return>, samples/pixel)
              &iscmap (<optional return>; input NULL to ignore)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If there is a colormap, iscmap is returned as 1; else 0.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
