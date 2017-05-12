package Image::Leptonica::Func::dnabasic;
$Image::Leptonica::Func::dnabasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::dnabasic

=head1 VERSION

version 0.04

=head1 C<dnabasic.c>

   dnabasic.c

      Dna creation, destruction, copy, clone, etc.
          L_DNA       *l_dnaCreate()
          L_DNA       *l_dnaCreateFromIArray()
          L_DNA       *l_dnaCreateFromDArray()
          L_DNA       *l_dnaMakeSequence()
          void        *l_dnaDestroy()
          L_DNA       *l_dnaCopy()
          L_DNA       *l_dnaClone()
          l_int32      l_dnaEmpty()

      Dna: add/remove number and extend array
          l_int32      l_dnaAddNumber()
          static l_int32  l_dnaExtendArray()
          l_int32      l_dnaInsertNumber()
          l_int32      l_dnaRemoveNumber()
          l_int32      l_dnaReplaceNumber()

      Dna accessors
          l_int32      l_dnaGetCount()
          l_int32      l_dnaSetCount()
          l_int32      l_dnaGetIValue()
          l_int32      l_dnaGetDValue()
          l_int32      l_dnaSetValue()
          l_int32      l_dnaShiftValue()
          l_int32     *l_dnaGetIArray()
          l_float64   *l_dnaGetDArray()
          l_int32      l_dnaGetRefcount()
          l_int32      l_dnaChangeRefcount()
          l_int32      l_dnaGetParameters()
          l_int32      l_dnaSetParameters()
          l_int32      l_dnaCopyParameters()

      Serialize Dna for I/O
          L_DNA       *l_dnaRead()
          L_DNA       *l_dnaReadStream()
          l_int32      l_dnaWrite()
          l_int32      l_dnaWriteStream()

      Dnaa creation, destruction
          L_DNAA      *l_dnaaCreate()
          void        *l_dnaaDestroy()

      Add Dna to Dnaa
          l_int32      l_dnaaAddDna()
          l_int32      l_dnaaExtendArray()

      Dnaa accessors
          l_int32      l_dnaaGetCount()
          l_int32      l_dnaaGetDnaCount()
          l_int32      l_dnaaGetNumberCount()
          L_DNA       *l_dnaaGetDna()
          L_DNA       *l_dnaaReplaceDna()
          l_int32      l_dnaaGetValue()
          l_int32      l_dnaaAddNumber()

      Serialize Dnaa for I/O
          L_DNAA      *l_dnaaRead()
          L_DNAA      *l_dnaaReadStream()
          l_int32      l_dnaaWrite()
          l_int32      l_dnaaWriteStream()

      Other Dna functions
          L_DNA       *l_dnaMakeDelta()
          NUMA        *l_dnaConvertToNuma()
          L_DNA       *numaConvertToDna()
          l_int32     *l_dnaJoin()

    (1) The Dna is a struct holding an array of doubles.  It can also
        be used to store l_int32 values, up to the full precision
        of int32.  Use it whenever integers larger than a few million
        need to be stored.

    (2) Always use the accessors in this file, never the fields directly.

    (3) Storing and retrieving numbers:

       * to append a new number to the array, use l_dnaAddNumber().  If
         the number is an int, it will will automatically be converted
         to l_float64 and stored.

       * to reset a value stored in the array, use l_dnaSetValue().

       * to increment or decrement a value stored in the array,
         use l_dnaShiftValue().

       * to obtain a value from the array, use either l_dnaGetIValue()
         or l_dnaGetDValue(), depending on whether you are retrieving
         an integer or a float.  This avoids doing an explicit cast,
         such as
           (a) return a l_float64 and cast it to an l_int32
           (b) cast the return directly to (l_float64 *) to
               satisfy the function prototype, as in
                 l_dnaGetDValue(da, index, (l_float64 *)&ival);   [ugly!]

    (4) int <--> double conversions:

        Conversions go automatically from l_int32 --> l_float64,
        without loss of precision.  You must cast (l_int32)
        to go from l_float64 --> l_int32 because you're truncating
        to the integer value.

    (5) As with other arrays in leptonica, the l_dna has both an allocated
        size and a count of the stored numbers.  When you add a number, it
        goes on the end of the array, and causes a realloc if the array
        is already filled.  However, in situations where you want to
        add numbers randomly into an array, such as when you build a
        histogram, you must set the count of stored numbers in advance.
        This is done with l_dnaSetCount().  If you set a count larger
        than the allocated array, it does a realloc to the size requested.

    (6) In situations where the data in a l_dna correspond to a function
        y(x), the values can be either at equal spacings in x or at
        arbitrary spacings.  For the former, we can represent all x values
        by two parameters: startx (corresponding to y[0]) and delx
        for the change in x for adjacent values y[i] and y[i+1].
        startx and delx are initialized to 0.0 and 1.0, rsp.
        For arbitrary spacings, we use a second l_dna, and the two
        l_dnas are typically denoted dnay and dnax.

=head1 FUNCTIONS

=head2 l_dnaAddNumber

l_int32 l_dnaAddNumber ( L_DNA *da, l_float64 val )

  l_dnaAddNumber()

      Input:  da
              val  (float or int to be added; stored as a float)
      Return: 0 if OK, 1 on error

=head2 l_dnaChangeRefcount

l_int32 l_dnaChangeRefcount ( L_DNA *da, l_int32 delta )

  l_dnaChangeRefcount()

      Input:  da
              delta (change to be applied)
      Return: 0 if OK, 1 on error

=head2 l_dnaClone

L_DNA * l_dnaClone ( L_DNA *da )

  l_dnaClone()

      Input:  da
      Return: ptr to same l_dna, or null on error

=head2 l_dnaConvertToNuma

NUMA * l_dnaConvertToNuma ( L_DNA *da )

  l_dnaConvertToNuma()

      Input:  da
      Return: na, or null on error

=head2 l_dnaCopy

L_DNA * l_dnaCopy ( L_DNA *da )

  l_dnaCopy()

      Input:  da
      Return: copy of l_dna, or null on error

=head2 l_dnaCopyParameters

l_int32 l_dnaCopyParameters ( L_DNA *dad, L_DNA *das )

  l_dnaCopyParameters()

      Input:  dad (destination DNuma)
              das (source DNuma)
      Return: 0 if OK, 1 on error

=head2 l_dnaCreate

L_DNA * l_dnaCreate ( l_int32 n )

  l_dnaCreate()

      Input:  size of number array to be alloc'd (0 for default)
      Return: da, or null on error

=head2 l_dnaCreateFromDArray

L_DNA * l_dnaCreateFromDArray ( l_float64 *darray, l_int32 size, l_int32 copyflag )

  l_dnaCreateFromDArray()

      Input:  da (float)
              size (of the array)
              copyflag (L_INSERT or L_COPY)
      Return: da, or null on error

  Notes:
      (1) With L_INSERT, ownership of the input array is transferred
          to the returned l_dna, and all @size elements are considered
          to be valid.

=head2 l_dnaCreateFromIArray

L_DNA * l_dnaCreateFromIArray ( l_int32 *iarray, l_int32 size )

  l_dnaCreateFromIArray()

      Input:  iarray (integer)
              size (of the array)
      Return: da, or null on error

  Notes:
      (1) We can't insert this int array into the l_dna, because a l_dna
          takes a double array.  So this just copies the data from the
          input array into the l_dna.  The input array continues to be
          owned by the caller.

=head2 l_dnaDestroy

void l_dnaDestroy ( L_DNA **pda )

  l_dnaDestroy()

      Input:  &da (<to be nulled if it exists>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the l_dna.
      (2) Always nulls the input ptr.

=head2 l_dnaEmpty

l_int32 l_dnaEmpty ( L_DNA *da )

  l_dnaEmpty()

      Input:  da
      Return: 0 if OK; 1 on error

  Notes:
      (1) This does not change the allocation of the array.
          It just clears the number of stored numbers, so that
          the array appears to be empty.

=head2 l_dnaGetCount

l_int32 l_dnaGetCount ( L_DNA *da )

  l_dnaGetCount()

      Input:  da
      Return: count, or 0 if no numbers or on error

=head2 l_dnaGetDArray

l_float64 * l_dnaGetDArray ( L_DNA *da, l_int32 copyflag )

  l_dnaGetDArray()

      Input:  da
              copyflag (L_NOCOPY or L_COPY)
      Return: either the bare internal array or a copy of it,
              or null on error

  Notes:
      (1) If copyflag == L_COPY, it makes a copy which the caller
          is responsible for freeing.  Otherwise, it operates
          directly on the bare array of the l_dna.
      (2) Very important: for L_NOCOPY, any writes to the array
          will be in the l_dna.  Do not write beyond the size of
          the count field, because it will not be accessable
          from the l_dna!  If necessary, be sure to set the count
          field to a larger number (such as the alloc size)
          BEFORE calling this function.  Creating with l_dnaMakeConstant()
          is another way to insure full initialization.

=head2 l_dnaGetDValue

l_int32 l_dnaGetDValue ( L_DNA *da, l_int32 index, l_float64 *pval )

  l_dnaGetDValue()

      Input:  da
              index (into l_dna)
              &val  (<return> double value; 0.0 on error)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caller may need to check the function return value to
          decide if a 0.0 in the returned ival is valid.

=head2 l_dnaGetIArray

l_int32 * l_dnaGetIArray ( L_DNA *da )

  l_dnaGetIArray()

      Input:  da
      Return: a copy of the bare internal array, integerized
              by rounding, or null on error
  Notes:
      (1) A copy of the array is made, because we need to
          generate an integer array from the bare double array.
          The caller is responsible for freeing the array.
      (2) The array size is determined by the number of stored numbers,
          not by the size of the allocated array in the l_dna.
      (3) This function is provided to simplify calculations
          using the bare internal array, rather than continually
          calling accessors on the l_dna.  It is typically used
          on an array of size 256.

=head2 l_dnaGetIValue

l_int32 l_dnaGetIValue ( L_DNA *da, l_int32 index, l_int32 *pival )

  l_dnaGetIValue()

      Input:  da
              index (into l_dna)
              &ival  (<return> integer value; 0 on error)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caller may need to check the function return value to
          decide if a 0 in the returned ival is valid.

=head2 l_dnaGetParameters

l_int32 l_dnaGetParameters ( L_DNA *da, l_float64 *pstartx, l_float64 *pdelx )

  l_dnaGetParameters()

      Input:  da
              &startx (<optional return> startx)
              &delx (<optional return> delx)
      Return: 0 if OK, 1 on error

=head2 l_dnaGetRefcount

l_int32 l_dnaGetRefcount ( L_DNA *da )

  l_dnaGetRefcount()

      Input:  da
      Return: refcount, or UNDEF on error

=head2 l_dnaInsertNumber

l_int32 l_dnaInsertNumber ( L_DNA *da, l_int32 index, l_float64 val )

  l_dnaInsertNumber()

      Input:  da
              index (location in da to insert new value)
              val  (float64 or integer to be added)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts da[i] --> da[i + 1] for all i >= index,
          and then inserts val as da[index].
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 l_dnaJoin

l_int32 l_dnaJoin ( L_DNA *dad, L_DNA *das, l_int32 istart, l_int32 iend )

  l_dnaJoin()

      Input:  dad  (dest dma; add to this one)
              das  (<optional> source dna; add from this one)
              istart  (starting index in das)
              iend  (ending index in das; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (2) iend < 0 means 'read to the end'
      (3) if das == NULL, this is a no-op

=head2 l_dnaMakeDelta

L_DNA * l_dnaMakeDelta ( L_DNA *das )

  l_dnaMakeDelta()

      Input:  das (input l_dna)
      Return: dad (of difference values val[i+1] - val[i]),
                   or null on error

=head2 l_dnaMakeSequence

L_DNA * l_dnaMakeSequence ( l_float64 startval, l_float64 increment, l_int32 size )

  l_dnaMakeSequence()

      Input:  startval
              increment
              size (of sequence)
      Return: l_dna of sequence of evenly spaced values, or null on error

=head2 l_dnaRead

L_DNA * l_dnaRead ( const char *filename )

  l_dnaRead()

      Input:  filename
      Return: da, or null on error

=head2 l_dnaReadStream

L_DNA * l_dnaReadStream ( FILE *fp )

  l_dnaReadStream()

      Input:  stream
      Return: da, or null on error

=head2 l_dnaRemoveNumber

l_int32 l_dnaRemoveNumber ( L_DNA *da, l_int32 index )

  l_dnaRemoveNumber()

      Input:  da
              index (element to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts da[i] --> da[i - 1] for all i > index.
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 l_dnaReplaceNumber

l_int32 l_dnaReplaceNumber ( L_DNA *da, l_int32 index, l_float64 val )

  l_dnaReplaceNumber()

      Input:  da
              index (element to be replaced)
              val (new value to replace old one)
      Return: 0 if OK, 1 on error

=head2 l_dnaSetCount

l_int32 l_dnaSetCount ( L_DNA *da, l_int32 newcount )

  l_dnaSetCount()

      Input:  da
              newcount
      Return: 0 if OK, 1 on error

  Notes:
      (1) If newcount <= da->nalloc, this resets da->n.
          Using newcount = 0 is equivalent to l_dnaEmpty().
      (2) If newcount > da->nalloc, this causes a realloc
          to a size da->nalloc = newcount.
      (3) All the previously unused values in da are set to 0.0.

=head2 l_dnaSetParameters

l_int32 l_dnaSetParameters ( L_DNA *da, l_float64 startx, l_float64 delx )

  l_dnaSetParameters()

      Input:  da
              startx (x value corresponding to da[0])
              delx (difference in x values for the situation where the
                    elements of da correspond to the evaulation of a
                    function at equal intervals of size @delx)
      Return: 0 if OK, 1 on error

=head2 l_dnaSetValue

l_int32 l_dnaSetValue ( L_DNA *da, l_int32 index, l_float64 val )

  l_dnaSetValue()

      Input:  da
              index  (to element to be set)
              val  (to set element)
      Return: 0 if OK; 1 on error

=head2 l_dnaShiftValue

l_int32 l_dnaShiftValue ( L_DNA *da, l_int32 index, l_float64 diff )

  l_dnaShiftValue()

      Input:  da
              index (to element to change relative to the current value)
              diff  (increment if diff > 0 or decrement if diff < 0)
      Return: 0 if OK; 1 on error

=head2 l_dnaWrite

l_int32 l_dnaWrite ( const char *filename, L_DNA *da )

  l_dnaWrite()

      Input:  filename, da
      Return: 0 if OK, 1 on error

=head2 l_dnaWriteStream

l_int32 l_dnaWriteStream ( FILE *fp, L_DNA *da )

  l_dnaWriteStream()

      Input:  stream, da
      Return: 0 if OK, 1 on error

=head2 l_dnaaAddDna

l_int32 l_dnaaAddDna ( L_DNAA *daa, L_DNA *da, l_int32 copyflag )

  l_dnaaAddDna()

      Input:  daa
              da   (to be added)
              copyflag  (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 l_dnaaAddNumber

l_int32 l_dnaaAddNumber ( L_DNAA *daa, l_int32 index, l_float64 val )

  l_dnaaAddNumber()

      Input:  daa
              index (of l_dna within l_dnaa)
              val  (number to be added; stored as a double)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Adds to an existing l_dna only.

=head2 l_dnaaCreate

L_DNAA * l_dnaaCreate ( l_int32 n )

  l_dnaaCreate()

      Input:  size of l_dna ptr array to be alloc'd (0 for default)
      Return: daa, or null on error

=head2 l_dnaaDestroy

void l_dnaaDestroy ( L_DNAA **pdaa )

  l_dnaaDestroy()

      Input: &dnaa <to be nulled if it exists>
      Return: void

=head2 l_dnaaGetCount

l_int32 l_dnaaGetCount ( L_DNAA *daa )

  l_dnaaGetCount()

      Input:  daa
      Return: count (number of l_dna), or 0 if no l_dna or on error

=head2 l_dnaaGetDna

L_DNA * l_dnaaGetDna ( L_DNAA *daa, l_int32 index, l_int32 accessflag )

  l_dnaaGetDna()

      Input:  daa
              index  (to the index-th l_dna)
              accessflag   (L_COPY or L_CLONE)
      Return: l_dna, or null on error

=head2 l_dnaaGetDnaCount

l_int32 l_dnaaGetDnaCount ( L_DNAA *daa, l_int32 index )

  l_dnaaGetDnaCount()

      Input:  daa
              index (of l_dna in daa)
      Return: count of numbers in the referenced l_dna, or 0 on error.

=head2 l_dnaaGetNumberCount

l_int32 l_dnaaGetNumberCount ( L_DNAA *daa )

  l_dnaaGetNumberCount()

      Input:  daa
      Return: count (total number of numbers in the l_dnaa),
                     or 0 if no numbers or on error

=head2 l_dnaaGetValue

l_int32 l_dnaaGetValue ( L_DNAA *daa, l_int32 i, l_int32 j, l_float64 *pval )

  l_dnaaGetValue()

      Input:  daa
              i (index of l_dna within l_dnaa)
              j (index into l_dna)
              val (<return> double value)
      Return: 0 if OK, 1 on error

=head2 l_dnaaRead

L_DNAA * l_dnaaRead ( const char *filename )

  l_dnaaRead()

      Input:  filename
      Return: daa, or null on error

=head2 l_dnaaReadStream

L_DNAA * l_dnaaReadStream ( FILE *fp )

  l_dnaaReadStream()

      Input:  stream
      Return: daa, or null on error

=head2 l_dnaaReplaceDna

l_int32 l_dnaaReplaceDna ( L_DNAA *daa, l_int32 index, L_DNA *da )

  l_dnaaReplaceDna()

      Input:  daa
              index  (to the index-th l_dna)
              l_dna (insert and replace any existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Any existing l_dna is destroyed, and the input one
          is inserted in its place.
      (2) If the index is invalid, return 1 (error)

=head2 l_dnaaWrite

l_int32 l_dnaaWrite ( const char *filename, L_DNAA *daa )

  l_dnaaWrite()

      Input:  filename, daa
      Return: 0 if OK, 1 on error

=head2 l_dnaaWriteStream

l_int32 l_dnaaWriteStream ( FILE *fp, L_DNAA *daa )

  l_dnaaWriteStream()

      Input:  stream, daa
      Return: 0 if OK, 1 on error

=head2 numaConvertToDna

L_DNA * numaConvertToDna ( NUMA *na )

  numaConvertToDna

      Input:  na
      Return: da, or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
