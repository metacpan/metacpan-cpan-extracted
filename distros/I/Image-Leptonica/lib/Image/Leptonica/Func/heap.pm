package Image::Leptonica::Func::heap;
$Image::Leptonica::Func::heap::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::heap

=head1 VERSION

version 0.04

=head1 C<heap.c>

   heap.c

      Create/Destroy L_Heap
          L_HEAP         *lheapCreate()
          void           *lheapDestroy()

      Operations to add/remove to/from the heap
          l_int32         lheapAdd()
          static l_int32  lheapExtendArray()
          void           *lheapRemove()

      Heap operations
          l_int32         lheapSwapUp()
          l_int32         lheapSwapDown()
          l_int32         lheapSort()
          l_int32         lheapSortStrictOrder()

      Accessors
          l_int32         lheapGetCount()

      Debug output
          l_int32         lheapPrint()

    The L_Heap is useful to implement a priority queue, that is sorted
    on a key in each element of the heap.  The heap is an array
    of nearly arbitrary structs, with a l_float32 the first field.
    This field is the key on which the heap is sorted.

    Internally, we keep track of the heap size, n.  The item at the
    root of the heap is at the head of the array.  Items are removed
    from the head of the array and added to the end of the array.
    When an item is removed from the head, the item at the end
    of the array is moved to the head.  When items are either
    added or removed, it is usually necesary to swap array items
    to restore the heap order.  It is guaranteed that the number
    of swaps does not exceed log(n).

    --------------------------  N.B.  ------------------------------
    The items on the heap (or, equivalently, in the array) are cast
    to void*.  Their key is a l_float32, and it is REQUIRED that the
    key be the first field in the struct.  That allows us to get the
    key by simply dereferencing the struct.  Alternatively, we could
    choose (but don't) to pass an application-specific comparison
    function into the heap operation functions.
    --------------------------  N.B.  ------------------------------

=head1 FUNCTIONS

=head2 lheapAdd

l_int32 lheapAdd ( L_HEAP *lh, void *item )

  lheapAdd()

      Input:  lheap
              item to be added to the tail of the heap
      Return: 0 if OK, 1 on error

=head2 lheapCreate

L_HEAP * lheapCreate ( l_int32 nalloc, l_int32 direction )

  lheapCreate()

      Input:  size of ptr array to be alloc'd (0 for default)
              direction (L_SORT_INCREASING, L_SORT_DECREASING)
      Return: lheap, or null on error

=head2 lheapDestroy

void lheapDestroy ( L_HEAP **plh, l_int32 freeflag )

  lheapDestroy()

      Input:  &lheap  (<to be nulled>)
              freeflag (TRUE to free each remaining struct in the array)
      Return: void

  Notes:
      (1) Use freeflag == TRUE when the items in the array can be
          simply destroyed using free.  If those items require their
          own destroy function, they must be destroyed before
          calling this function, and then this function is called
          with freeflag == FALSE.
      (2) To destroy the lheap, we destroy the ptr array, then
          the lheap, and then null the contents of the input ptr.

=head2 lheapGetCount

l_int32 lheapGetCount ( L_HEAP *lh )

  lheapGetCount()

      Input:  lheap
      Return: count, or 0 on error

=head2 lheapPrint

l_int32 lheapPrint ( FILE *fp, L_HEAP *lh )

  lheapPrint()

      Input:  stream
              lheap
      Return: 0 if OK; 1 on error

=head2 lheapRemove

void * lheapRemove ( L_HEAP *lh )

  lheapRemove()

      Input:  lheap
      Return: ptr to item popped from the root of the heap,
              or null if the heap is empty or on error

=head2 lheapSort

l_int32 lheapSort ( L_HEAP *lh )

  lheapSort()

      Input:  lh (heap, with internal array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This sorts an array into heap order.  If the heap is already
          in heap order for the direction given, this has no effect.

=head2 lheapSortStrictOrder

l_int32 lheapSortStrictOrder ( L_HEAP *lh )

  lheapSortStrictOrder()

      Input:  lh (heap, with internal array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This sorts a heap into strict order.
      (2) For each element, starting at the end of the array and
          working forward, the element is swapped with the head
          element and then allowed to swap down onto a heap of
          size reduced by one.  The result is that the heap is
          reversed but in strict order.  The array elements are
          then reversed to put it in the original order.

=head2 lheapSwapDown

l_int32 lheapSwapDown ( L_HEAP *lh )

  lheapSwapDown()

      Input:  lh (heap)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is called after an item has been popped off the
          root of the heap, and the last item in the heap has
          been placed at the root.
      (2) To regain the heap order, we let it bubble down,
          iteratively swapping with one of its children.  For a
          decreasing sort, it swaps with the largest child; for
          an increasing sort, the smallest.  This continues until
          it either reaches the lowest level in the heap, or the
          parent finds that neither child should swap with it
          (e.g., for a decreasing heap, the parent is larger
          than or equal to both children).

=head2 lheapSwapUp

l_int32 lheapSwapUp ( L_HEAP *lh, l_int32 index )

  lheapSwapUp()

      Input:  lh (heap)
              index (of array corresponding to node to be swapped up)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is called after a new item is put on the heap, at the
          bottom of a complete tree.
      (2) To regain the heap order, we let it bubble up,
          iteratively swapping with its parent, until it either
          reaches the root of the heap or it finds a parent that
          is in the correct position already vis-a-vis the child.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
