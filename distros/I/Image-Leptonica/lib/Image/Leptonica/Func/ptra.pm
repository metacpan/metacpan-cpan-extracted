package Image::Leptonica::Func::ptra;
$Image::Leptonica::Func::ptra::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ptra

=head1 VERSION

version 0.04

=head1 C<ptra.c>

   ptra.c

      Ptra creation and destruction
          L_PTRA      *ptraCreate()
          void        *ptraDestroy()

      Add/insert/remove/replace generic ptr object
          l_int32      ptraAdd()
          static l_int32  ptraExtendArray()
          l_int32      ptraInsert()
          void        *ptraRemove()
          void        *ptraRemoveLast()
          void        *ptraReplace()
          l_int32      ptraSwap()
          l_int32      ptraCompactArray()

      Other array operations
          l_int32      ptraReverse()
          l_int32      ptraJoin()

      Simple Ptra accessors
          l_int32      ptraGetMaxIndex()
          l_int32      ptraGetActualCount()
          void        *ptraGetPtrToItem()

      Ptraa creation and destruction
          L_PTRAA     *ptraaCreate()
          void        *ptraaDestroy()

      Ptraa accessors
          l_int32      ptraaGetSize()
          l_int32      ptraaInsertPtra()
          L_PTRA      *ptraaGetPtra()

      Ptraa conversion
          L_PTRA      *ptraaFlattenToPtra()

    Notes on the Ptra:

    (1) The Ptra is a struct, not an array.  Always use the accessors
        in this file, never the fields directly.
    (2) Items can be placed anywhere in the allocated ptr array,
        including one index beyond the last ptr (in which case the
        ptr array is realloc'd).
    (3) Thus, the items on the ptr array need not be compacted.  In
        general there will be null pointers in the ptr array.
    (4) A compacted array will remain compacted on removal if
        arbitrary items are removed with compaction, or if items
        are removed from the end of the array.
    (5) For addition to and removal from the end of the array, this
        functions exactly like a stack, and with the same O(1) cost.
    (6) This differs from the generic stack in that we allow
        random access for insertion, removal and replacement.
        Removal can be done without compacting the array.
        Insertion into a null ptr in the array has no effect on
        the other pointers, but insertion into a location already
        occupied by an item has a cost proportional to the
        distance to the next null ptr in the array.
    (7) Null ptrs are valid input args for both insertion and
        replacement; this allows arbitrary swapping.
    (8) The item in the array with the largest index is at pa->imax.
        This can be any value from -1 (initialized; all array ptrs
        are null) up to pa->nalloc - 1 (the last ptr in the array).
    (9) In referring to the array: the first ptr is the "top" or
        "beginning"; the last pointer is the "bottom" or "end";
        items are shifted "up" towards the top when compaction occurs;
        and items are shifted "down" towards the bottom when forced to
        move due to an insertion.
   (10) It should be emphasized that insertion, removal and replacement
        are general:
         * You can insert an item into any ptr location in the
           allocated ptr array, as well as into the next ptr address
           beyond the allocated array (in which case a realloc will occur).
         * You can remove or replace an item from any ptr location
           in the allocated ptr array.
         * When inserting into an occupied location, you have
           three options for downshifting.
         * When removing, you can either leave the ptr null or
           compact the array.

    Notes on the Ptraa:

    (1) The Ptraa is a fixed size ptr array for holding Ptra.
        In that respect, it is different from other pointer arrays, which
        are extensible and grow using the *Add*() functions.
    (2) In general, the Ptra ptrs in the Ptraa can be randomly occupied.
        A typical usage is to allow an O(n) horizontal sort of Pix,
        where the size of the Ptra array is the width of the image,
        and each Ptra is an array of all the Pix at a specific x location.

=head1 FUNCTIONS

=head2 ptraAdd

l_int32 ptraAdd ( L_PTRA *pa, void *item )

  ptraAdd()

      Input:  ptra
              item  (generic ptr to a struct)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This adds the element to the next location beyond imax,
          which is the largest occupied ptr in the array.  This is
          what you expect from a stack, where all ptrs up to and
          including imax are occupied, but here the occuption of
          items in the array is entirely arbitrary.

=head2 ptraCompactArray

l_int32 ptraCompactArray ( L_PTRA *pa )

  ptraCompactArray()

      Input:  ptra
      Return: 0 if OK, 1 on error

  Notes:
      (1) This compacts the items on the array, filling any empty ptrs.
      (2) This does not change the size of the array of ptrs.

=head2 ptraCreate

L_PTRA * ptraCreate ( l_int32 n )

  ptraCreate()

      Input:  size of ptr array to be alloc'd (0 for default)
      Return: pa, or null on error

=head2 ptraDestroy

void ptraDestroy ( L_PTRA **ppa, l_int32 freeflag, l_int32 warnflag )

  ptraDestroy()

      Input:  &ptra (<to be nulled>)
              freeflag (TRUE to free each remaining item in the array)
              warnflag (TRUE to warn if any remaining items are not destroyed)
      Return: void

  Notes:
      (1) If @freeflag == TRUE, frees each item in the array.
      (2) If @freeflag == FALSE and warnflag == TRUE, and there are
          items on the array, this gives a warning and destroys the array.
          If these items are not owned elsewhere, this will cause
          a memory leak of all the items that were on the array.
          So if the items are not owned elsewhere and require their
          own destroy function, they must be destroyed before the ptra.
      (3) If warnflag == FALSE, no warnings will be issued.  This is
          useful if the items are owned elsewhere, such as a
          PixMemoryStore().
      (4) To destroy the ptra, we destroy the ptr array, then
          the ptra, and then null the contents of the input ptr.

=head2 ptraGetActualCount

l_int32 ptraGetActualCount ( L_PTRA *pa, l_int32 *pcount )

  ptraGetActualCount()

      Input:  ptra
              &count (<return> actual number of items on the ptr array)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The actual number of items on the ptr array, pa->nactual,
          will be smaller than pa->n if the array is not compacted.

=head2 ptraGetMaxIndex

l_int32 ptraGetMaxIndex ( L_PTRA *pa, l_int32 *pmaxindex )

  ptraGetMaxIndex()

      Input:  ptra
              &maxindex (<return> index of last item in the array);
      Return: 0 if OK; 1 on error

  Notes:
      (1) The largest index to an item in the array is @maxindex.
          @maxindex is one less than the number of items that would be
          in the array if there were no null pointers between 0
          and @maxindex - 1.  However, because the internal ptr array
          need not be compacted, there may be null pointers at
          indices below @maxindex; for example, if items have
          been removed.
      (2) When an item is added to the end of the array, it goes
          into pa->array[maxindex + 1], and maxindex is then
          incremented by 1.
      (3) If there are no items in the array, this returns @maxindex = -1.

=head2 ptraGetPtrToItem

void * ptraGetPtrToItem ( L_PTRA *pa, l_int32 index )

  ptraGetPtrToItem()

      Input:  ptra
              index (of element to be retrieved)
      Return: a ptr to the element, or null on error

  Notes:
      (1) This returns a ptr to the item.  You must cast it to
          the type of item.  Do not destroy it; the item belongs
          to the Ptra.
      (2) This can access all possible items on the ptr array.
          If an item doesn't exist, it returns null.

=head2 ptraInsert

l_int32 ptraInsert ( L_PTRA *pa, l_int32 index, void *item, l_int32 shiftflag )

  ptraInsert()

      Input:  ptra
              index (location in ptra to insert new value)
              item  (generic ptr to a struct; can be null)
              shiftflag (L_AUTO_DOWNSHIFT, L_MIN_DOWNSHIFT, L_FULL_DOWNSHIFT)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This checks first to see if the location is valid, and
          then if there is presently an item there.  If there is not,
          it is simply inserted into that location.
      (2) If there is an item at the insert location, items must be
          moved down to make room for the insert.  In the downward
          shift there are three options, given by @shiftflag.
            - If @shiftflag == L_AUTO_DOWNSHIFT, a decision is made
              whether, in a cascade of items, to downshift a minimum
              amount or for all items above @index.  The decision is
              based on the expectation of finding holes (null ptrs)
              between @index and the bottom of the array.
              Assuming the holes are distributed uniformly, if 2 or more
              holes are expected, we do a minimum shift.
            - If @shiftflag == L_MIN_DOWNSHIFT, the downward shifting
              cascade of items progresses a minimum amount, until
              the first empty slot is reached.  This mode requires
              some computation before the actual shifting is done.
            - If @shiftflag == L_FULL_DOWNSHIFT, a shifting cascade is
              performed where pa[i] --> pa[i + 1] for all i >= index.
              Then, the item is inserted at pa[index].
      (3) If you are not using L_AUTO_DOWNSHIFT, the rule of thumb is
          to use L_FULL_DOWNSHIFT if the array is compacted (each
          element points to an item), and to use L_MIN_DOWNSHIFT
          if there are a significant number of null pointers.
          There is no penalty to using L_MIN_DOWNSHIFT for a
          compacted array, however, because the full shift is required
          and we don't do the O(n) computation to look for holes.
      (4) This should not be used repeatedly on large arrays,
          because the function is generally O(n).
      (5) However, it can be used repeatedly if we start with an empty
          ptr array and insert only once at each location.  For example,
          you can support an array of Numa, where at each ptr location
          you store either 0 or 1 Numa, and the Numa can be added
          randomly to the ptr array.

=head2 ptraJoin

l_int32 ptraJoin ( L_PTRA *pa1, L_PTRA *pa2 )

  ptraJoin()

      Input:  ptra1 (add to this one)
              ptra2 (appended to ptra1, and emptied of items; can be null)
      Return: 0 if OK, 1 on error

=head2 ptraRemove

void * ptraRemove ( L_PTRA *pa, l_int32 index, l_int32 flag )

  ptraRemove()

      Input:  ptra
              index (element to be removed)
              flag (L_NO_COMPACTION, L_COMPACTION)
      Return: item, or null on error

  Notes:
      (1) If flag == L_NO_COMPACTION, this removes the item and
          nulls the ptr on the array.  If it takes the last item
          in the array, pa->n is reduced to the next item.
      (2) If flag == L_COMPACTION, this compacts the array for
          for all i >= index.  It should not be used repeatedly on
          large arrays, because compaction is O(n).
      (3) The ability to remove without automatic compaction allows
          removal with cost O(1).

=head2 ptraRemoveLast

void * ptraRemoveLast ( L_PTRA *pa )

  ptraRemoveLast()

      Input:  ptra
      Return: item, or null on error or if the array is empty

=head2 ptraReplace

void * ptraReplace ( L_PTRA *pa, l_int32 index, void *item, l_int32 freeflag )

  ptraReplace()

      Input:  ptra
              index (element to be replaced)
              item  (new generic ptr to a struct; can be null)
              freeflag (TRUE to free old item; FALSE to return it)
      Return: item  (old item, if it exists and is not freed),
                     or null on error

=head2 ptraReverse

l_int32 ptraReverse ( L_PTRA *pa )

  ptraReverse()

      Input:  ptra
      Return: 0 if OK, 1 on error

=head2 ptraSwap

l_int32 ptraSwap ( L_PTRA *pa, l_int32 index1, l_int32 index2 )

  ptraSwap()

      Input:  ptra
              index1
              index2
      Return: 0 if OK, 1 on error

=head2 ptraaCreate

L_PTRAA * ptraaCreate ( l_int32 n )

  ptraaCreate()

      Input:  size of ptr array to be alloc'd
      Return: paa, or null on error

  Notes:
      (1) The ptraa is generated with a fixed size, that can not change.
          The ptra can be generated and inserted randomly into this array.

=head2 ptraaDestroy

void ptraaDestroy ( L_PTRAA **ppaa, l_int32 freeflag, l_int32 warnflag )

  ptraaDestroy()

      Input:  &paa (<to be nulled>)
              freeflag (TRUE to free each remaining item in each ptra)
              warnflag (TRUE to warn if any remaining items are not destroyed)
      Return: void

  Notes:
      (1) See ptraDestroy() for use of @freeflag and @warnflag.
      (2) To destroy the ptraa, we destroy each ptra, then the ptr array,
          then the ptraa, and then null the contents of the input ptr.

=head2 ptraaFlattenToPtra

L_PTRA * ptraaFlattenToPtra ( L_PTRAA *paa )

  ptraaFlattenToPtra()

      Input:  ptraa
      Return: ptra, or null on error

  Notes:
      (1) This 'flattens' the ptraa to a ptra, taking the items in
          each ptra, in order, starting with the first ptra, etc.
      (2) As a side-effect, the ptra are all removed from the ptraa
          and destroyed, leaving an empty ptraa.

=head2 ptraaGetPtra

L_PTRA * ptraaGetPtra ( L_PTRAA *paa, l_int32 index, l_int32 accessflag )

  ptraaGetPtra()

      Input:  ptraa
              index (location in array)
              accessflag (L_HANDLE_ONLY, L_REMOVE)
      Return: ptra (at index location), or NULL on error or if there
              is no ptra there.

  Notes:
      (1) This returns the ptra ptr.  If @accessflag == L_HANDLE_ONLY,
          the ptra is left on the ptraa.  If @accessflag == L_REMOVE,
          the ptr in the ptraa is set to NULL, and the caller
          is responsible for disposing of the ptra (either putting it
          back on the ptraa, or destroying it).
      (2) This returns NULL if there is no Ptra at the index location.

=head2 ptraaGetSize

l_int32 ptraaGetSize ( L_PTRAA *paa, l_int32 *psize )

  ptraaGetSize()

      Input:  ptraa
              &size (<return> size of ptr array)
      Return: 0 if OK; 1 on error

=head2 ptraaInsertPtra

l_int32 ptraaInsertPtra ( L_PTRAA *paa, l_int32 index, L_PTRA *pa )

  ptraaInsertPtra()

      Input:  ptraa
              index (location in array for insertion)
              ptra (to be inserted)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caller should check return value.  On success, the Ptra
          is inserted in the Ptraa and is owned by it.  However,
          on error, the Ptra remains owned by the caller.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
