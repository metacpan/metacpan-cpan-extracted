package Image::Leptonica::Func::pixalloc;
$Image::Leptonica::Func::pixalloc::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixalloc

=head1 VERSION

version 0.04

=head1 C<pixalloc.c>

  pixalloc.c

      Custom memory storage with allocator and deallocator

          l_int32       pmsCreate()
          void          pmsDestroy()
          void         *pmsCustomAlloc()
          void          pmsCustomDealloc()
          void         *pmsGetAlloc()
          l_int32       pmsGetLevelForAlloc()
          l_int32       pmsGetLevelForDealloc()
          void          pmsLogInfo()

=head1 FUNCTIONS

=head2 pmsCreate

l_int32 pmsCreate ( size_t minsize, size_t smallest, NUMA *numalloc, const char *logfile )

  pmsCreate()

      Input:  minsize (of data chunk that can be supplied by pms)
              smallest (bytes of the smallest pre-allocated data chunk.
              numalloc (array with the number of data chunks for each
                        size that are in the memory store)
              logfile (use for debugging; null otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This computes the size of the block of memory required
          and allocates it.  Each chunk starts on a 32-bit word boundary.
          The chunk sizes are in powers of 2, starting at @smallest,
          and the number of levels and chunks at each level is
          specified by @numalloc.
      (2) This is intended to manage the image data for a small number
          of relatively large pix.  The system malloc is expected to
          handle very large numbers of small chunks efficiently.
      (3) Important: set the allocators and call this function
          before any pix have been allocated.  Destroy all the pix
          in the normal way before calling pmsDestroy().
      (4) The pms struct is stored in a static global, so this function
          is not thread-safe.  When used, there must be only one thread
          per process.

=head2 pmsCustomAlloc

void * pmsCustomAlloc ( size_t nbytes )

  pmsCustomAlloc()

      Input: nbytes (min number of bytes in the chunk to be retrieved)
      Return: data (ptr to chunk)

  Notes:
      (1) This attempts to find a suitable pre-allocated chunk.
          If not found, it dynamically allocates the chunk.
      (2) If logging is turned on, the allocations that are not taken
          from the memory store, and are at least as large as the
          minimum size the store can handle, are logged to file.

=head2 pmsCustomDealloc

void pmsCustomDealloc ( void *data )

  pmsCustomDealloc()

      Input: data (to be freed or returned to the storage)
      Return: void

=head2 pmsDestroy

void pmsDestroy (  )

  pmsDestroy()

      Input:  (none)
      Return: void

  Notes:
      (1) Important: call this function at the end of the program, after
          the last pix has been destroyed.

=head2 pmsGetAlloc

void * pmsGetAlloc ( size_t nbytes )

  pmsGetAlloc()

      Input:  nbytes
      Return: data

  Notes:
      (1) This is called when a request for pix data cannot be
          obtained from the preallocated memory store.  After use it
          is freed like normal memory.
      (2) If logging is on, only write out allocs that are as large as
          the minimum size handled by the memory store.
      (3) size_t is %lu on 64 bit platforms and %u on 32 bit platforms.
          The C99 platform-independent format specifier for size_t is %zu,
          but windows hasn't conformed, so we are forced to go back to
          C89, use %lu, and cast to get platform-independence.  Ugh.

=head2 pmsGetLevelForAlloc

l_int32 pmsGetLevelForAlloc ( size_t nbytes, l_int32 *plevel )

  pmsGetLevelForAlloc()

      Input: nbytes (min number of bytes in the chunk to be retrieved)
             &level (<return>; -1 if either too small or too large)
      Return: 0 if OK, 1 on error

=head2 pmsGetLevelForDealloc

l_int32 pmsGetLevelForDealloc ( void *data, l_int32 *plevel )

  pmsGetLevelForDealloc()

      Input: data (ptr to memory chunk)
             &level (<return> level in memory store; -1 if allocated
                     outside the store)
      Return: 0 if OK, 1 on error

=head2 pmsLogInfo

void pmsLogInfo (  )

  pmsLogInfo()

      Input:  (none)
      Return: void

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
