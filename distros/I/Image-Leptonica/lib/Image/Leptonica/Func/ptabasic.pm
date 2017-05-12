package Image::Leptonica::Func::ptabasic;
$Image::Leptonica::Func::ptabasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ptabasic

=head1 VERSION

version 0.04

=head1 C<ptabasic.c>

   ptabasic.c

      Pta creation, destruction, copy, clone, empty
           PTA            *ptaCreate()
           PTA            *ptaCreateFromNuma()
           void            ptaDestroy()
           PTA            *ptaCopy()
           PTA            *ptaCopyRange()
           PTA            *ptaClone()
           l_int32         ptaEmpty()

      Pta array extension
           l_int32         ptaAddPt()
           static l_int32  ptaExtendArrays()

      Pta insertion and removal
           l_int32         ptaInsertPt()
           l_int32         ptaRemovePt()

      Pta accessors
           l_int32         ptaGetRefcount()
           l_int32         ptaChangeRefcount()
           l_int32         ptaGetCount()
           l_int32         ptaGetPt()
           l_int32         ptaGetIPt()
           l_int32         ptaSetPt()
           l_int32         ptaGetArrays()

      Pta serialized for I/O
           PTA            *ptaRead()
           PTA            *ptaReadStream()
           l_int32         ptaWrite()
           l_int32         ptaWriteStream()

      Ptaa creation, destruction
           PTAA           *ptaaCreate()
           void            ptaaDestroy()

      Ptaa array extension
           l_int32         ptaaAddPta()
           static l_int32  ptaaExtendArray()

      Ptaa accessors
           l_int32         ptaaGetCount()
           l_int32         ptaaGetPta()
           l_int32         ptaaGetPt()

      Ptaa array modifiers
           l_int32         ptaaInitFull()
           l_int32         ptaaReplacePta()
           l_int32         ptaaAddPt()
           l_int32         ptaaTruncate()

      Ptaa serialized for I/O
           PTAA           *ptaaRead()
           PTAA           *ptaaReadStream()
           l_int32         ptaaWrite()
           l_int32         ptaaWriteStream()

=head1 FUNCTIONS

=head2 ptaAddPt

l_int32 ptaAddPt ( PTA *pta, l_float32 x, l_float32 y )

  ptaAddPt()

      Input:  pta
              x, y
      Return: 0 if OK, 1 on error

=head2 ptaClone

PTA * ptaClone ( PTA *pta )

  ptaClone()

      Input:  pta
      Return: ptr to same pta, or null on error

=head2 ptaCopy

PTA * ptaCopy ( PTA *pta )

  ptaCopy()

      Input:  pta
      Return: copy of pta, or null on error

=head2 ptaCopyRange

PTA * ptaCopyRange ( PTA *ptas, l_int32 istart, l_int32 iend )

  ptaCopyRange()

      Input:  ptas
              istart  (starting index in ptas)
              iend  (ending index in ptas; use 0 to copy to end)
      Return: 0 if OK, 1 on error

=head2 ptaCreate

PTA * ptaCreate ( l_int32 n )

  ptaCreate()

      Input:  n  (initial array sizes)
      Return: pta, or null on error.

=head2 ptaCreateFromNuma

PTA * ptaCreateFromNuma ( NUMA *nax, NUMA *nay )

  ptaCreateFromNuma()

      Input:  nax (<optional> can be null)
              nay
      Return: pta, or null on error.

=head2 ptaDestroy

void ptaDestroy ( PTA **ppta )

  ptaDestroy()

      Input:  &pta (<to be nulled>)
      Return: void

  Note:
      - Decrements the ref count and, if 0, destroys the pta.
      - Always nulls the input ptr.

=head2 ptaEmpty

l_int32 ptaEmpty ( PTA *pta )

  ptaEmpty()

      Input:  pta
      Return: 0 if OK, 1 on error

  Note: this only resets the "n" field, for reuse

=head2 ptaGetArrays

l_int32 ptaGetArrays ( PTA *pta, NUMA **pnax, NUMA **pnay )

  ptaGetArrays()

      Input:  pta
              &nax (<optional return> numa of x array)
              &nay (<optional return> numa of y array)
      Return: 0 if OK; 1 on error or if pta is empty

  Notes:
      (1) This copies the internal arrays into new Numas.

=head2 ptaGetCount

l_int32 ptaGetCount ( PTA *pta )

  ptaGetCount()

      Input:  pta
      Return: count, or 0 if no pta

=head2 ptaGetIPt

l_int32 ptaGetIPt ( PTA *pta, l_int32 index, l_int32 *px, l_int32 *py )

  ptaGetIPt()

      Input:  pta
              index  (into arrays)
              &x (<optional return> integer x value)
              &y (<optional return> integer y value)
      Return: 0 if OK; 1 on error

=head2 ptaGetPt

l_int32 ptaGetPt ( PTA *pta, l_int32 index, l_float32 *px, l_float32 *py )

  ptaGetPt()

      Input:  pta
              index  (into arrays)
              &x (<optional return> float x value)
              &y (<optional return> float y value)
      Return: 0 if OK; 1 on error

=head2 ptaInsertPt

l_int32 ptaInsertPt ( PTA *pta, l_int32 index, l_int32 x, l_int32 y )

  ptaInsertPt()

      Input:  pta
              index (at which pt is to be inserted)
              x, y (point values)
      Return: 0 if OK; 1 on error

=head2 ptaRead

PTA * ptaRead ( const char *filename )

  ptaRead()

      Input:  filename
      Return: pta, or null on error

=head2 ptaReadStream

PTA * ptaReadStream ( FILE *fp )

  ptaReadStream()

      Input:  stream
      Return: pta, or null on error

=head2 ptaRemovePt

l_int32 ptaRemovePt ( PTA *pta, l_int32 index )

  ptaRemovePt()

      Input:  pta
              index (of point to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts pta[i] --> pta[i - 1] for all i > index.
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 ptaSetPt

l_int32 ptaSetPt ( PTA *pta, l_int32 index, l_float32 x, l_float32 y )

  ptaSetPt()

      Input:  pta
              index  (into arrays)
              x, y
      Return: 0 if OK; 1 on error

=head2 ptaWrite

l_int32 ptaWrite ( const char *filename, PTA *pta, l_int32 type )

  ptaWrite()

      Input:  filename
              pta
              type  (0 for float values; 1 for integer values)
      Return: 0 if OK, 1 on error

=head2 ptaWriteStream

l_int32 ptaWriteStream ( FILE *fp, PTA *pta, l_int32 type )

  ptaWriteStream()

      Input:  stream
              pta
              type  (0 for float values; 1 for integer values)
      Return: 0 if OK; 1 on error

=head2 ptaaAddPt

l_int32 ptaaAddPt ( PTAA *ptaa, l_int32 ipta, l_float32 x, l_float32 y )

  ptaaAddPt()

      Input:  ptaa
              ipta  (to the i-th pta)
              x,y (point coordinates)
      Return: 0 if OK; 1 on error

=head2 ptaaAddPta

l_int32 ptaaAddPta ( PTAA *ptaa, PTA *pta, l_int32 copyflag )

  ptaaAddPta()

      Input:  ptaa
              pta  (to be added)
              copyflag  (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 ptaaCreate

PTAA * ptaaCreate ( l_int32 n )

  ptaaCreate()

      Input:  n  (initial number of ptrs)
      Return: ptaa, or null on error

=head2 ptaaDestroy

void ptaaDestroy ( PTAA **pptaa )

  ptaaDestroy()

      Input:  &ptaa <to be nulled>
      Return: void

=head2 ptaaGetCount

l_int32 ptaaGetCount ( PTAA *ptaa )

  ptaaGetCount()

      Input:  ptaa
      Return: count, or 0 if no ptaa

=head2 ptaaGetPt

l_int32 ptaaGetPt ( PTAA *ptaa, l_int32 ipta, l_int32 jpt, l_float32 *px, l_float32 *py )

  ptaaGetPt()

      Input:  ptaa
              ipta  (to the i-th pta)
              jpt (index to the j-th pt in the pta)
              &x (<optional return> float x value)
              &y (<optional return> float y value)
      Return: 0 if OK; 1 on error

=head2 ptaaGetPta

PTA * ptaaGetPta ( PTAA *ptaa, l_int32 index, l_int32 accessflag )

  ptaaGetPta()

      Input:  ptaa
              index  (to the i-th pta)
              accessflag  (L_COPY or L_CLONE)
      Return: pta, or null on error

=head2 ptaaInitFull

l_int32 ptaaInitFull ( PTAA *ptaa, PTA *pta )

  ptaaInitFull()

      Input:  ptaa (can have non-null ptrs in the ptr array)
              pta (to be replicated into the entire ptr array)
      Return: 0 if OK; 1 on error

=head2 ptaaRead

PTAA * ptaaRead ( const char *filename )

  ptaaRead()

      Input:  filename
      Return: ptaa, or null on error

=head2 ptaaReadStream

PTAA * ptaaReadStream ( FILE *fp )

  ptaaReadStream()

      Input:  stream
      Return: ptaa, or null on error

=head2 ptaaReplacePta

l_int32 ptaaReplacePta ( PTAA *ptaa, l_int32 index, PTA *pta )

  ptaaReplacePta()

      Input:  ptaa
              index  (to the index-th pta)
              pta (insert and replace any existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Any existing pta is destroyed, and the input one
          is inserted in its place.
      (2) If the index is invalid, return 1 (error)

=head2 ptaaTruncate

l_int32 ptaaTruncate ( PTAA *ptaa )

  ptaaTruncate()

      Input:  ptaa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This identifies the largest index containing a pta that
          has any points within it, destroys all pta above that index,
          and resets the count.

=head2 ptaaWrite

l_int32 ptaaWrite ( const char *filename, PTAA *ptaa, l_int32 type )

  ptaaWrite()

      Input:  filename
              ptaa
              type  (0 for float values; 1 for integer values)
      Return: 0 if OK, 1 on error

=head2 ptaaWriteStream

l_int32 ptaaWriteStream ( FILE *fp, PTAA *ptaa, l_int32 type )

  ptaaWriteStream()

      Input:  stream
              ptaa
              type  (0 for float values; 1 for integer values)
      Return: 0 if OK; 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
