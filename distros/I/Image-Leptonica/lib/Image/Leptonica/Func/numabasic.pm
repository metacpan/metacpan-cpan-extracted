package Image::Leptonica::Func::numabasic;
$Image::Leptonica::Func::numabasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::numabasic

=head1 VERSION

version 0.04

=head1 C<numabasic.c>

   numabasic.c

      Numa creation, destruction, copy, clone, etc.
          NUMA        *numaCreate()
          NUMA        *numaCreateFromIArray()
          NUMA        *numaCreateFromFArray()
          void        *numaDestroy()
          NUMA        *numaCopy()
          NUMA        *numaClone()
          l_int32      numaEmpty()

      Add/remove number (float or integer)
          l_int32      numaAddNumber()
          static l_int32  numaExtendArray()
          l_int32      numaInsertNumber()
          l_int32      numaRemoveNumber()
          l_int32      numaReplaceNumber()

      Numa accessors
          l_int32      numaGetCount()
          l_int32      numaSetCount()
          l_int32      numaGetIValue()
          l_int32      numaGetFValue()
          l_int32      numaSetValue()
          l_int32      numaShiftValue()
          l_int32     *numaGetIArray()
          l_float32   *numaGetFArray()
          l_int32      numaGetRefcount()
          l_int32      numaChangeRefcount()
          l_int32      numaGetParameters()
          l_int32      numaSetParameters()
          l_int32      numaCopyParameters()

      Convert to string array
          SARRAY      *numaConvertToSarray()

      Serialize numa for I/O
          NUMA        *numaRead()
          NUMA        *numaReadStream()
          l_int32      numaWrite()
          l_int32      numaWriteStream()

      Numaa creation, destruction, truncation
          NUMAA       *numaaCreate()
          NUMAA       *numaaCreateFull()
          NUMAA       *numaaTruncate()
          void        *numaaDestroy()

      Add Numa to Numaa
          l_int32      numaaAddNuma()
          l_int32      numaaExtendArray()

      Numaa accessors
          l_int32      numaaGetCount()
          l_int32      numaaGetNumaCount()
          l_int32      numaaGetNumberCount()
          NUMA       **numaaGetPtrArray()
          NUMA        *numaaGetNuma()
          NUMA        *numaaReplaceNuma()
          l_int32      numaaGetValue()
          l_int32      numaaAddNumber()

      Serialize numaa for I/O
          NUMAA       *numaaRead()
          NUMAA       *numaaReadStream()
          l_int32      numaaWrite()
          l_int32      numaaWriteStream()

      Numa2d creation, destruction
          NUMA2D      *numa2dCreate()
          void        *numa2dDestroy()

      Numa2d Accessors
          l_int32      numa2dAddNumber()
          l_int32      numa2dGetCount()
          NUMA        *numa2dGetNuma()
          l_int32      numa2dGetFValue()
          l_int32      numa2dGetIValue()

      NumaHash creation, destruction
          NUMAHASH    *numaHashCreate()
          void        *numaHashDestroy()

      NumaHash Accessors
          NUMA        *numaHashGetNuma()
          void        *numaHashAdd()

    (1) The Numa is a struct holding an array of floats.  It can also
        be used to store l_int32 values, with some loss of precision
        for floats larger than about 10 million.  Use the L_Dna instead
        if integers larger than a few million need to be stored.

    (2) Always use the accessors in this file, never the fields directly.

    (3) Storing and retrieving numbers:

       * to append a new number to the array, use numaAddNumber().  If
         the number is an int, it will will automatically be converted
         to l_float32 and stored.

       * to reset a value stored in the array, use numaSetValue().

       * to increment or decrement a value stored in the array,
         use numaShiftValue().

       * to obtain a value from the array, use either numaGetIValue()
         or numaGetFValue(), depending on whether you are retrieving
         an integer or a float.  This avoids doing an explicit cast,
         such as
           (a) return a l_float32 and cast it to an l_int32
           (b) cast the return directly to (l_float32 *) to
               satisfy the function prototype, as in
                 numaGetFValue(na, index, (l_float32 *)&ival);   [ugly!]

    (4) int <--> float conversions:

        Tradition dictates that type conversions go automatically from
        l_int32 --> l_float32, even though it is possible to lose
        precision for large integers, whereas you must cast (l_int32)
        to go from l_float32 --> l_int32 because you're truncating
        to the integer value.

    (5) As with other arrays in leptonica, the numa has both an allocated
        size and a count of the stored numbers.  When you add a number, it
        goes on the end of the array, and causes a realloc if the array
        is already filled.  However, in situations where you want to
        add numbers randomly into an array, such as when you build a
        histogram, you must set the count of stored numbers in advance.
        This is done with numaSetCount().  If you set a count larger
        than the allocated array, it does a realloc to the size requested.

    (6) In situations where the data in a numa correspond to a function
        y(x), the values can be either at equal spacings in x or at
        arbitrary spacings.  For the former, we can represent all x values
        by two parameters: startx (corresponding to y[0]) and delx
        for the change in x for adjacent values y[i] and y[i+1].
        startx and delx are initialized to 0.0 and 1.0, rsp.
        For arbitrary spacings, we use a second numa, and the two
        numas are typically denoted nay and nax.

    (7) The numa is also the basic struct used for histograms.  Every numa
        has startx and delx fields, initialized to 0.0 and 1.0, that can
        be used to represent the "x" value for the location of the
        first bin and the bin width, respectively.  Accessors are the
        numa*Parameters() functions.  All functions that make numa
        histograms must set these fields properly, and many functions
        that use numa histograms rely on the correctness of these values.

=head1 FUNCTIONS

=head2 numa2dAddNumber

l_int32 numa2dAddNumber ( NUMA2D *na2d, l_int32 row, l_int32 col, l_float32 val )

  numa2dAddNumber()

      Input:  na2d
              row of 2d array
              col of 2d array
              val  (float or int to be added; stored as a float)
      Return: 0 if OK, 1 on error

=head2 numa2dCreate

NUMA2D * numa2dCreate ( l_int32 nrows, l_int32 ncols, l_int32 initsize )

  numa2dCreate()

      Input:  nrows (of 2d array)
              ncols (of 2d array)
              initsize (initial size of each allocated numa)
      Return: numa2d, or null on error

  Notes:
      (1) The numa2d holds a doubly-indexed array of numa.
      (2) The numa ptr array is initialized with all ptrs set to NULL.
      (3) The numas are created only when a number is to be stored
          at an index (i,j) for which a numa has not yet been made.

=head2 numa2dDestroy

void numa2dDestroy ( NUMA2D **pna2d )

  numa2dDestroy()

      Input:  &numa2d (<to be nulled if it exists>)
      Return: void

=head2 numa2dGetCount

l_int32 numa2dGetCount ( NUMA2D *na2d, l_int32 row, l_int32 col )

  numa2dGetCount()

      Input:  na2d
              row of 2d array
              col of 2d array
      Return: size of numa at [row][col], or 0 if the numa doesn't exist
              or on error

=head2 numa2dGetFValue

l_int32 numa2dGetFValue ( NUMA2D *na2d, l_int32 row, l_int32 col, l_int32 index, l_float32 *pval )

  numa2dGetFValue()

      Input:  na2d
              row of 2d array
              col of 2d array
              index (into numa)
              &val (<return> float value)
      Return: 0 if OK, 1 on error

=head2 numa2dGetIValue

l_int32 numa2dGetIValue ( NUMA2D *na2d, l_int32 row, l_int32 col, l_int32 index, l_int32 *pval )

  numa2dGetIValue()

      Input:  na2d
              row of 2d array
              col of 2d array
              index (into numa)
              &val (<return> integer value)
      Return: 0 if OK, 1 on error

=head2 numa2dGetNuma

NUMA * numa2dGetNuma ( NUMA2D *na2d, l_int32 row, l_int32 col )

  numa2dGetNuma()

      Input:  na2d
              row of 2d array
              col of 2d array
      Return: na (a clone of the numa if it exists) or null if it doesn't

  Notes:
      (1) This does not give an error if the index is out of bounds.

=head2 numaAddNumber

l_int32 numaAddNumber ( NUMA *na, l_float32 val )

  numaAddNumber()

      Input:  na
              val  (float or int to be added; stored as a float)
      Return: 0 if OK, 1 on error

=head2 numaChangeRefcount

l_int32 numaChangeRefcount ( NUMA *na, l_int32 delta )

  numaChangeRefcount()

      Input:  na
              delta (change to be applied)
      Return: 0 if OK, 1 on error

=head2 numaClone

NUMA * numaClone ( NUMA *na )

  numaClone()

      Input:  na
      Return: ptr to same numa, or null on error

=head2 numaConvertToSarray

SARRAY * numaConvertToSarray ( NUMA *na, l_int32 size1, l_int32 size2, l_int32 addzeros, l_int32 type )

  numaConvertToSarray()

      Input:  na
              size1 (size of conversion field)
              size2 (for float conversion: size of field to the right
                     of the decimal point)
              addzeros (for integer conversion: to add lead zeros)
              type (L_INTEGER_VALUE, L_FLOAT_VALUE)
      Return: a sarray of the float values converted to strings
              representing either integer or float values; or null on error.

  Notes:
      (1) For integer conversion, size2 is ignored.
          For float conversion, addzeroes is ignored.

=head2 numaCopy

NUMA * numaCopy ( NUMA *na )

  numaCopy()

      Input:  na
      Return: copy of numa, or null on error

=head2 numaCopyParameters

l_int32 numaCopyParameters ( NUMA *nad, NUMA *nas )

  numaCopyParameters()

      Input:  nad (destination Numa)
              nas (source Numa)
      Return: 0 if OK, 1 on error

=head2 numaCreate

NUMA * numaCreate ( l_int32 n )

  numaCreate()

      Input:  size of number array to be alloc'd (0 for default)
      Return: na, or null on error

=head2 numaCreateFromFArray

NUMA * numaCreateFromFArray ( l_float32 *farray, l_int32 size, l_int32 copyflag )

  numaCreateFromFArray()

      Input:  farray (float)
              size (of the array)
              copyflag (L_INSERT or L_COPY)
      Return: na, or null on error

  Notes:
      (1) With L_INSERT, ownership of the input array is transferred
          to the returned numa, and all @size elements are considered
          to be valid.

=head2 numaCreateFromIArray

NUMA * numaCreateFromIArray ( l_int32 *iarray, l_int32 size )

  numaCreateFromIArray()

      Input:  iarray (integer)
              size (of the array)
      Return: na, or null on error

  Notes:
      (1) We can't insert this int array into the numa, because a numa
          takes a float array.  So this just copies the data from the
          input array into the numa.  The input array continues to be
          owned by the caller.

=head2 numaDestroy

void numaDestroy ( NUMA **pna )

  numaDestroy()

      Input:  &na (<to be nulled if it exists>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the numa.
      (2) Always nulls the input ptr.

=head2 numaEmpty

l_int32 numaEmpty ( NUMA *na )

  numaEmpty()

      Input:  na
      Return: 0 if OK; 1 on error

  Notes:
      (1) This does not change the allocation of the array.
          It just clears the number of stored numbers, so that
          the array appears to be empty.

=head2 numaGetCount

l_int32 numaGetCount ( NUMA *na )

  numaGetCount()

      Input:  na
      Return: count, or 0 if no numbers or on error

=head2 numaGetFArray

l_float32 * numaGetFArray ( NUMA *na, l_int32 copyflag )

  numaGetFArray()

      Input:  na
              copyflag (L_NOCOPY or L_COPY)
      Return: either the bare internal array or a copy of it,
              or null on error

  Notes:
      (1) If copyflag == L_COPY, it makes a copy which the caller
          is responsible for freeing.  Otherwise, it operates
          directly on the bare array of the numa.
      (2) Very important: for L_NOCOPY, any writes to the array
          will be in the numa.  Do not write beyond the size of
          the count field, because it will not be accessable
          from the numa!  If necessary, be sure to set the count
          field to a larger number (such as the alloc size)
          BEFORE calling this function.  Creating with numaMakeConstant()
          is another way to insure full initialization.

=head2 numaGetFValue

l_int32 numaGetFValue ( NUMA *na, l_int32 index, l_float32 *pval )

  numaGetFValue()

      Input:  na
              index (into numa)
              &val  (<return> float value; 0.0 on error)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caller may need to check the function return value to
          decide if a 0.0 in the returned ival is valid.

=head2 numaGetIArray

l_int32 * numaGetIArray ( NUMA *na )

  numaGetIArray()

      Input:  na
      Return: a copy of the bare internal array, integerized
              by rounding, or null on error
  Notes:
      (1) A copy of the array is always made, because we need to
          generate an integer array from the bare float array.
          The caller is responsible for freeing the array.
      (2) The array size is determined by the number of stored numbers,
          not by the size of the allocated array in the Numa.
      (3) This function is provided to simplify calculations
          using the bare internal array, rather than continually
          calling accessors on the numa.  It is typically used
          on an array of size 256.

=head2 numaGetIValue

l_int32 numaGetIValue ( NUMA *na, l_int32 index, l_int32 *pival )

  numaGetIValue()

      Input:  na
              index (into numa)
              &ival  (<return> integer value; 0 on error)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caller may need to check the function return value to
          decide if a 0 in the returned ival is valid.

=head2 numaGetParameters

l_int32 numaGetParameters ( NUMA *na, l_float32 *pstartx, l_float32 *pdelx )

  numaGetParameters()

      Input:  na
              &startx (<optional return> startx)
              &delx (<optional return> delx)
      Return: 0 if OK, 1 on error

=head2 numaGetRefcount

l_int32 numaGetRefcount ( NUMA *na )

  numaGetRefcount()

      Input:  na
      Return: refcount, or UNDEF on error

=head2 numaHashAdd

l_int32 numaHashAdd ( NUMAHASH *nahash, l_uint32 key, l_float32 value )

  numaHashAdd()

      Input:  nahash
              key  (key to be hashed into a bucket number)
              value  (float value to be appended to the specific numa)
      Return: 0 if OK; 1 on error

=head2 numaHashCreate

NUMAHASH * numaHashCreate ( l_int32 nbuckets, l_int32 initsize )

  numaHashCreate()

      Input: nbuckets (the number of buckets in the hash table,
                       which should be prime.)
             initsize (initial size of each allocated numa; 0 for default)
      Return: ptr to new nahash, or null on error

  Note: actual numa are created only as required by numaHashAdd()

=head2 numaHashDestroy

void numaHashDestroy ( NUMAHASH **pnahash )

  numaHashDestroy()

      Input:  &nahash (<to be nulled, if it exists>)
      Return: void

=head2 numaHashGetNuma

NUMA * numaHashGetNuma ( NUMAHASH *nahash, l_uint32 key )

  numaHashGetNuma()

      Input:  nahash
              key  (key to be hashed into a bucket number)
      Return: ptr to numa

=head2 numaInsertNumber

l_int32 numaInsertNumber ( NUMA *na, l_int32 index, l_float32 val )

  numaInsertNumber()

      Input:  na
              index (location in na to insert new value)
              val  (float32 or integer to be added)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts na[i] --> na[i + 1] for all i >= index,
          and then inserts val as na[index].
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 numaRead

NUMA * numaRead ( const char *filename )

  numaRead()

      Input:  filename
      Return: na, or null on error

=head2 numaReadStream

NUMA * numaReadStream ( FILE *fp )

  numaReadStream()

      Input:  stream
      Return: numa, or null on error

=head2 numaRemoveNumber

l_int32 numaRemoveNumber ( NUMA *na, l_int32 index )

  numaRemoveNumber()

      Input:  na
              index (element to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts na[i] --> na[i - 1] for all i > index.
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 numaReplaceNumber

l_int32 numaReplaceNumber ( NUMA *na, l_int32 index, l_float32 val )

  numaReplaceNumber()

      Input:  na
              index (element to be replaced)
              val (new value to replace old one)
      Return: 0 if OK, 1 on error

=head2 numaSetCount

l_int32 numaSetCount ( NUMA *na, l_int32 newcount )

  numaSetCount()

      Input:  na
              newcount
      Return: 0 if OK, 1 on error

  Notes:
      (1) If newcount <= na->nalloc, this resets na->n.
          Using newcount = 0 is equivalent to numaEmpty().
      (2) If newcount > na->nalloc, this causes a realloc
          to a size na->nalloc = newcount.
      (3) All the previously unused values in na are set to 0.0.

=head2 numaSetParameters

l_int32 numaSetParameters ( NUMA *na, l_float32 startx, l_float32 delx )

  numaSetParameters()

      Input:  na
              startx (x value corresponding to na[0])
              delx (difference in x values for the situation where the
                    elements of na correspond to the evaulation of a
                    function at equal intervals of size @delx)
      Return: 0 if OK, 1 on error

=head2 numaSetValue

l_int32 numaSetValue ( NUMA *na, l_int32 index, l_float32 val )

  numaSetValue()

      Input:  na
              index   (to element to be set)
              val  (to set element)
      Return: 0 if OK; 1 on error

=head2 numaShiftValue

l_int32 numaShiftValue ( NUMA *na, l_int32 index, l_float32 diff )

  numaShiftValue()

      Input:  na
              index (to element to change relative to the current value)
              diff  (increment if diff > 0 or decrement if diff < 0)
      Return: 0 if OK; 1 on error

=head2 numaWrite

l_int32 numaWrite ( const char *filename, NUMA *na )

  numaWrite()

      Input:  filename, na
      Return: 0 if OK, 1 on error

=head2 numaWriteStream

l_int32 numaWriteStream ( FILE *fp, NUMA *na )

  numaWriteStream()

      Input:  stream, na
      Return: 0 if OK, 1 on error

=head2 numaaAddNuma

l_int32 numaaAddNuma ( NUMAA *naa, NUMA *na, l_int32 copyflag )

  numaaAddNuma()

      Input:  naa
              na   (to be added)
              copyflag  (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 numaaAddNumber

l_int32 numaaAddNumber ( NUMAA *naa, l_int32 index, l_float32 val )

  numaaAddNumber()

      Input:  naa
              index (of numa within numaa)
              val  (float or int to be added; stored as a float)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Adds to an existing numa only.

=head2 numaaCreate

NUMAA * numaaCreate ( l_int32 n )

  numaaCreate()

      Input:  size of numa ptr array to be alloc'd (0 for default)
      Return: naa, or null on error

=head2 numaaCreateFull

NUMAA * numaaCreateFull ( l_int32 ntop, l_int32 n )

  numaaCreateFull()

      Input:  ntop: size of numa ptr array to be alloc'd
              n: size of individual numa arrays to be alloc'd (0 for default)
      Return: naa, or null on error

  Notes:
      (1) This allocates numaa and fills the array with allocated numas.
          In use, after calling this function, use
              numaaAddNumber(naa, index, val);
          to add val to the index-th numa in naa.

=head2 numaaDestroy

void numaaDestroy ( NUMAA **pnaa )

  numaaDestroy()

      Input: &numaa <to be nulled if it exists>
      Return: void

=head2 numaaExtendArray

l_int32 numaaExtendArray ( NUMAA *naa )

  numaaExtendArray()

      Input:  naa
      Return: 0 if OK, 1 on error

=head2 numaaGetCount

l_int32 numaaGetCount ( NUMAA *naa )

  numaaGetCount()

      Input:  naa
      Return: count (number of numa), or 0 if no numa or on error

=head2 numaaGetNuma

NUMA * numaaGetNuma ( NUMAA *naa, l_int32 index, l_int32 accessflag )

  numaaGetNuma()

      Input:  naa
              index  (to the index-th numa)
              accessflag   (L_COPY or L_CLONE)
      Return: numa, or null on error

=head2 numaaGetNumaCount

l_int32 numaaGetNumaCount ( NUMAA *naa, l_int32 index )

  numaaGetNumaCount()

      Input:  naa
              index (of numa in naa)
      Return: count of numbers in the referenced numa, or 0 on error.

=head2 numaaGetNumberCount

l_int32 numaaGetNumberCount ( NUMAA *naa )

  numaaGetNumberCount()

      Input:  naa
      Return: count (total number of numbers in the numaa),
                     or 0 if no numbers or on error

=head2 numaaGetPtrArray

NUMA ** numaaGetPtrArray ( NUMAA *naa )

  numaaGetPtrArray()

      Input:  naa
      Return: the internal array of ptrs to Numa, or null on error

  Notes:
      (1) This function is convenient for doing direct manipulation on
          a fixed size array of Numas.  To do this, it sets the count
          to the full size of the allocated array of Numa ptrs.
          The originating Numaa owns this array: DO NOT free it!
      (2) Intended usage:
            Numaa *naa = numaaCreate(n);
            Numa **array = numaaGetPtrArray(naa);
             ...  [manipulate Numas directly on the array]
            numaaDestroy(&naa);
      (3) Cautions:
           - Do not free this array; it is owned by tne Numaa.
           - Do not call any functions on the Numaa, other than
             numaaDestroy() when you're finished with the array.
             Adding a Numa will force a resize, destroying the ptr array.
           - Do not address the array outside its allocated size.
             With the bare array, there are no protections.  If the
             allocated size is n, array[n] is an error.

=head2 numaaGetValue

l_int32 numaaGetValue ( NUMAA *naa, l_int32 i, l_int32 j, l_float32 *pfval, l_int32 *pival )

  numaaGetValue()

      Input:  naa
              i (index of numa within numaa)
              j (index into numa)
              fval (<optional return> float value)
              ival (<optional return> int value)
      Return: 0 if OK, 1 on error

=head2 numaaRead

NUMAA * numaaRead ( const char *filename )

  numaaRead()

      Input:  filename
      Return: naa, or null on error

=head2 numaaReadStream

NUMAA * numaaReadStream ( FILE *fp )

  numaaReadStream()

      Input:  stream
      Return: naa, or null on error

=head2 numaaReplaceNuma

l_int32 numaaReplaceNuma ( NUMAA *naa, l_int32 index, NUMA *na )

  numaaReplaceNuma()

      Input:  naa
              index  (to the index-th numa)
              numa (insert and replace any existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Any existing numa is destroyed, and the input one
          is inserted in its place.
      (2) If the index is invalid, return 1 (error)

=head2 numaaTruncate

l_int32 numaaTruncate ( NUMAA *naa )

  numaaTruncate()

      Input:  naa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This identifies the largest index containing a numa that
          has any numbers within it, destroys all numa above that index,
          and resets the count.

=head2 numaaWrite

l_int32 numaaWrite ( const char *filename, NUMAA *naa )

  numaaWrite()

      Input:  filename, naa
      Return: 0 if OK, 1 on error

=head2 numaaWriteStream

l_int32 numaaWriteStream ( FILE *fp, NUMAA *naa )

  numaaWriteStream()

      Input:  stream, naa
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
