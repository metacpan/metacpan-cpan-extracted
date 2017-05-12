package Image::Leptonica::Func::bbuffer;
$Image::Leptonica::Func::bbuffer::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::bbuffer

=head1 VERSION

version 0.04

=head1 C<bbuffer.c>

   bbuffer.c

      Create/Destroy BBuffer
          BBUFFER        *bbufferCreate()
          void           *bbufferDestroy()
          l_uint8        *bbufferDestroyAndSaveData()

      Operations to read data TO a BBuffer
          l_int32         bbufferRead()
          l_int32         bbufferReadStream()
          static l_int32  bbufferExtendArray()

      Operations to write data FROM a BBuffer
          l_int32         bbufferWrite()
          l_int32         bbufferWriteStream()

      Accessors
          l_int32         bbufferBytesToWrite()

      Read from stdin to memory
          l_int32         bbufferReadStdin()


    The bbuffer is an implementation of a byte queue.
    The bbuffer holds a byte array from which bytes are
    processed in a first-in/first-out fashion.  As with
    any queue, bbuffer maintains two "pointers," one to the
    tail of the queue (where you read new bytes onto it)
    and one to the head of the queue (where you start from
    when writing bytes out of it.

    The queue can be visualized:


  byte 0                                           byte (nalloc - 1)
       |                                                |
       --------------------------------------------------
                 H                             T
       [   aw   ][  bytes currently on queue  ][  anr   ]

       ---:  all allocated data in bbuffer
       H:    queue head (ptr to next byte to be written out)
       T:    queue tail (ptr to first byte to be written to)
       aw:   already written from queue
       anr:  allocated but not yet read to

    The purpose of bbuffer is to allow you to safely read
    bytes in, and to sequentially write them out as well.
    In the process of writing bytes out, you don't actually
    remove the bytes in the array; you just move the pointer
    (nwritten) which points to the head of the queue.  In
    the process of reading bytes in, you sometimes need to
    expand the array size.  If a read is performed after a
    write, so that the head of the queue is not at the
    beginning of the array, the bytes already written are
    first removed by copying the others over them; then the
    new bytes are read onto the tail of the queue.

    Note that the meaning of "read into" and "write from"
    the bbuffer is OPPOSITE to that for a stream, where
    you read "from" a stream and write "into" a stream.
    As a mnemonic for remembering the direction:
        - to read bytes from a stream into the bbuffer,
          you call fread on the stream
        - to write bytes from the bbuffer into a stream,
          you call fwrite on the stream

    See zlibmem.c for an example use of bbuffer, where we
    compress and decompress an array of bytes in memory.

    We can also use the bbuffer trivially to read from stdin
    into memory; e.g., to capture bytes piped from the stdout
    of another program.  This is equivalent to repeatedly
    calling bbufferReadStream() until the input queue is empty.

=head1 FUNCTIONS

=head2 bbufferBytesToWrite

l_int32 bbufferBytesToWrite ( BBUFFER *bb, size_t *pnbytes )

  bbufferBytesToWrite()

      Input:  bbuffer
              &nbytes (<return>)
      Return: 0 if OK; 1 on error

=head2 bbufferCreate

BBUFFER * bbufferCreate ( l_uint8 *indata, l_int32 nalloc )

  bbufferCreate()

      Input:  buffer address in memory (<optional>)
              size of byte array to be alloc'd (0 for default)
      Return: bbuffer, or null on error

  Notes:
      (1) If a buffer address is given, you should read all the data in.
      (2) Allocates a bbuffer with associated byte array of
          the given size.  If a buffer address is given,
          it then reads the number of bytes into the byte array.

=head2 bbufferDestroy

void bbufferDestroy ( BBUFFER **pbb )

  bbufferDestroy()

      Input:  &bbuffer  (<to be nulled>)
      Return: void

  Notes:
      (1) Destroys the byte array in the bbuffer and then the bbuffer;
          then nulls the contents of the input ptr.

=head2 bbufferDestroyAndSaveData

l_uint8 * bbufferDestroyAndSaveData ( BBUFFER **pbb, size_t *pnbytes )

  bbufferDestroyAndSaveData()

      Input:  &bbuffer (<to be nulled>)
              &nbytes  (<return> number of bytes saved in array)
      Return: barray (newly allocated array of data)

  Notes:
      (1) Copies data to newly allocated array; then destroys the bbuffer.

=head2 bbufferRead

l_int32 bbufferRead ( BBUFFER *bb, l_uint8 *src, l_int32 nbytes )

  bbufferRead()

      Input:  bbuffer
              src      (source memory buffer from which bytes are read)
              nbytes   (bytes to be read)
      Return: 0 if OK, 1 on error

  Notes:
      (1) For a read after write, first remove the written
          bytes by shifting the unwritten bytes in the array,
          then check if there is enough room to add the new bytes.
          If not, realloc with bbufferExpandArray(), resulting
          in a second writing of the unwritten bytes.  While less
          efficient, this is simpler than making a special case
          of reallocNew().

=head2 bbufferReadStdin

l_int32 bbufferReadStdin ( l_uint8 **pdata, size_t *pnbytes )

  bbufferReadStdin()

      Input:  &data (<return> binary data read in)
              &nbytes (<return>)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This can be used to capture data piped in from stdin.
          For example, you can read an image from stdin into memory
          using shell redirection, with one of these:
             cat <imagefile> | readprog
             readprog < <imagefile>
          where readprog is:
             bbufferReadStdin(&data, &nbytes);  // l_uint8*, size_t
             Pix *pix = pixReadMem(data, nbytes);

=head2 bbufferReadStream

l_int32 bbufferReadStream ( BBUFFER *bb, FILE *fp, l_int32 nbytes )

  bbufferReadStream()

      Input:  bbuffer
              fp      (source stream from which bytes are read)
              nbytes   (bytes to be read)
      Return: 0 if OK, 1 on error

=head2 bbufferWrite

l_int32 bbufferWrite ( BBUFFER *bb, l_uint8 *dest, size_t nbytes, size_t *pnout )

  bbufferWrite()

      Input:  bbuffer
              dest     (dest memory buffer to which bytes are written)
              nbytes   (bytes requested to be written)
              &nout    (<return> bytes actually written)
      Return: 0 if OK, 1 on error

=head2 bbufferWriteStream

l_int32 bbufferWriteStream ( BBUFFER *bb, FILE *fp, size_t nbytes, size_t *pnout )

  bbufferWriteStream()

      Input:  bbuffer
              fp       (dest stream to which bytes are written)
              nbytes   (bytes requested to be written)
              &nout    (<return> bytes actually written)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
