package Image::Leptonica::Func::bytearray;
$Image::Leptonica::Func::bytearray::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::bytearray

=head1 VERSION

version 0.04

=head1 C<bytearray.c>

   bytearray.c

   Functions for handling byte arrays, in analogy with C++ 'strings'

      Creation, copy, clone, destruction
           L_BYTEA      *l_byteaCreate()
           L_BYTEA      *l_byteaInitFromMem()
           L_BYTEA      *l_byteaInitFromFile()
           L_BYTEA      *l_byteaInitFromStream()
           L_BYTEA      *l_byteaCopy()
           L_BYTEA      *l_byteaClone()
           void          l_byteaDestroy()

      Accessors
           size_t        l_byteaGetSize()
           l_uint8      *l_byteaGetData()
           l_uint8      *l_byteaCopyData()

      Appending
           l_int32       l_byteaAppendData()
           l_int32       l_byteaAppendString()
           static l_int32  l_byteaExtendArrayToSize()

      Join/Split
           l_int32       l_byteaJoin()
           l_int32       l_byteaSplit()

      Search
           l_int32       l_byteaFindEachSequence()

      Output to file
           l_int32       l_byteaWrite()
           l_int32       l_byteaWriteStream()

   The internal data array is always null-terminated, for ease of use
   in the event that it is an ascii string without null bytes.

=head1 FUNCTIONS

=head2 l_byteaAppendData

l_int32 l_byteaAppendData ( L_BYTEA *ba, l_uint8 *newdata, size_t newbytes )

  l_byteaAppendData()

      Input:  ba
              newdata (byte array to be appended)
              size (size of data array)
      Return: 0 if OK, 1 on error

=head2 l_byteaAppendString

l_int32 l_byteaAppendString ( L_BYTEA *ba, char *str )

  l_byteaAppendString()

      Input:  ba
              str (null-terminated string to be appended)
      Return: 0 if OK, 1 on error

=head2 l_byteaCopy

L_BYTEA * l_byteaCopy ( L_BYTEA *bas, l_int32 copyflag )

  l_byteaCopy()

      Input:  bas  (source lba)
              copyflag (L_COPY, L_CLONE)
      Return: clone or copy of bas, or null on error

  Notes:
      (1) If cloning, up the refcount and return a ptr to @bas.

=head2 l_byteaCopyData

l_uint8 * l_byteaCopyData ( L_BYTEA *ba, size_t *psize )

  l_byteaCopyData()

      Input:  ba
              &size (<returned> size of data in lba)
      Return: copy of data in use in the data array, or null on error.

  Notes:
      (1) The returned data is owned by the caller.  The input @ba
          still owns the original data array.

=head2 l_byteaCreate

L_BYTEA * l_byteaCreate ( size_t nbytes )

  l_byteaCreate()

      Input:  n (determines initial size of data array)
      Return: l_bytea, or null on error

  Notes:
      (1) The allocated array is n + 1 bytes.  This allows room
          for null termination.

=head2 l_byteaDestroy

void l_byteaDestroy ( L_BYTEA **pba )

  l_byteaDestroy()

      Input:  &ba (<will be set to null before returning>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the lba.
      (2) Always nulls the input ptr.
      (3) If the data has been previously removed, the lba will
          have been nulled, so this will do nothing.

=head2 l_byteaFindEachSequence

l_int32 l_byteaFindEachSequence ( L_BYTEA *ba, l_uint8 *sequence, l_int32 seqlen, L_DNA **pda )

  l_byteaFindEachSequence()

      Input:  ba
              sequence (subarray of bytes to find in data)
              seqlen (length of sequence, in bytes)
              &da (<return> byte positions of each occurrence of @sequence)
      Return: 0 if OK, 1 on error

=head2 l_byteaGetData

l_uint8 * l_byteaGetData ( L_BYTEA *ba, size_t *psize )

  l_byteaGetData()

      Input:  ba
              &size (<returned> size of data in lba)
      Return: ptr to existing data array, or NULL on error

  Notes:
      (1) The returned ptr is owned by @ba.  Do not free it!

=head2 l_byteaGetSize

size_t l_byteaGetSize ( L_BYTEA *ba )

  l_byteaGetSize()

      Input:  ba
      Return: size of stored byte array, or 0 on error

=head2 l_byteaInitFromFile

L_BYTEA * l_byteaInitFromFile ( const char *fname )

  l_byteaInitFromFile()

      Input:  fname
      Return: l_bytea, or null on error

=head2 l_byteaInitFromMem

L_BYTEA * l_byteaInitFromMem ( l_uint8 *data, size_t size )

  l_byteaInitFromMem()

      Input:  data (to be copied to the array)
              size (amount of data)
      Return: l_bytea, or null on error

=head2 l_byteaInitFromStream

L_BYTEA * l_byteaInitFromStream ( FILE *fp )

  l_byteaInitFromStream()

      Input:  stream
      Return: l_bytea, or null on error

=head2 l_byteaJoin

l_int32 l_byteaJoin ( L_BYTEA *ba1, L_BYTEA **pba2 )

  l_byteaJoin()

      Input:  ba1
              &ba2 (data array is added to the one in ba1, and
                     then ba2 is destroyed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) It is a no-op, not an error, for @ba2 to be null.

=head2 l_byteaSplit

l_int32 l_byteaSplit ( L_BYTEA *ba1, size_t splitloc, L_BYTEA **pba2 )

  l_byteaSplit()

      Input:  ba1 (lba to split; array bytes nulled beyond the split loc)
              splitloc (location in ba1 to split; ba2 begins there)
              &ba2 (<return> with data starting at splitloc)
      Return: 0 if OK, 1 on error

=head2 l_byteaWrite

l_int32 l_byteaWrite ( const char *fname, L_BYTEA *ba, size_t startloc, size_t endloc )

  l_byteaWrite()

      Input:  fname (output file)
              ba
              startloc (first byte to output)
              endloc (last byte to output; use 0 to write to the
                      end of the data array)
      Return: 0 if OK, 1 on error

=head2 l_byteaWriteStream

l_int32 l_byteaWriteStream ( FILE *fp, L_BYTEA *ba, size_t startloc, size_t endloc )

  l_byteaWriteStream()

      Input:  stream (opened for binary write)
              ba
              startloc (first byte to output)
              endloc (last byte to output; use 0 to write to the
                      end of the data array)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
