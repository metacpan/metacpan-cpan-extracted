package Image::Leptonica::Func::list;
$Image::Leptonica::Func::list::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::list

=head1 VERSION

version 0.04

=head1 C<list.c>

   list.c

      Inserting and removing elements

           void      listDestroy()
           DLLIST   *listAddToHead()
           l_int32   listAddToTail()
           l_int32   listInsertBefore()
           l_int32   listInsertAfter()
           void     *listRemoveElement()
           void     *listRemoveFromHead()
           void     *listRemoveFromTail()

      Other list operations

           DLLIST   *listFindElement()
           DLLIST   *listFindTail()
           l_int32   listGetCount()
           l_int32   listReverse()
           DLLIST   *listJoin()

      Lists are much harder to handle than arrays.  There is
      more overhead for the programmer, both cognitive and
      codewise, and more likelihood that an error can be made.
      For that reason, lists should only be used when it is
      inefficient to use arrays, such as when elements are
      routinely inserted or deleted from inside arrays whose
      average size is greater than about 10.

      A list of data structures can be implemented in a number
      of ways.  The two most popular are:

         (1) The list can be composed of a linked list of
             pointer cells ("cons cells"), where the data structures
             are hung off the cells.  This is more difficult
             to use because you have to keep track of both
             your hanging data and the cell structures.
             It requires 3 pointers for every data structure
             that is put in a list.  There is no problem
             cloning (using reference counts) for structures that
             are put in such a list.  We implement lists by this
             method here.

         (2) The list pointers can be inserted directly into
             the data structures.  This is easy to implement
             and easier to use, but it adds 2 ptrs of overhead
             to every data structure in which the ptrs are embedded.
             It also requires special care not to put the ptrs
             in any data that is cloned with a reference count;
             else your lists will break.

      Writing C code that uses list pointers explicitly to make
      and alter lists is difficult and prone to error.
      Consequently, a generic list utility that handles lists
      of arbitrary objects and doesn't force the programmer to
      touch the "next" and "prev" pointers, is quite useful.
      Such functions are provided here.   However, the usual
      situation requires traversing a list and applying some
      function to one or more of the list elements.  Macros
      for traversing the list are, in general, necessary, to
      achieve the goal of invisibly handling all "next" and "prev"
      pointers in generic lists.  We provide macros for
      traversing a list in both forward and reverse directions.

      Because of the typing in C, implementation of a general
      list utility requires casting.  If macros are used, the
      casting can be done implicitly; otherwise, using functions,
      some of the casts must be explicit.  Fortunately, this
      can be implemented with void* so the programmer using
      the library will not have to make any casts!  (Unless you
      compile with g++, in which case the rules on implicit
      conversion are more strict.)

      For example, to add an arbitrary data structure foo to the
      tail of a list, use
             listAddToTail(&head, &tail, pfoo);
      where head and tail are list cell ptrs and pfoo is
      a pointer to the foo object.
      And to remove an arbitrary data structure foo from a
      list, when you know the list cell element it is hanging from,
      use
             pfoo = listRemoveElement(&head, elem)
      where head and elem are list cell ptrs and pfoo is a pointer
      to the foo object.  No casts are required for foo in
      either direction in ANSI C.  (However, casts are
      required for ANSI C++).

      We use lists that are composed of doubly-linked
      cells with data structures hanging off the cells.
      We use doubly-linked cells to simplify insertion
      and deletion, and to allow operations to proceed in either
      direction along the list.  With doubly-linked lists,
      it is tempting to make them circular, by setting head->prev
      to the tail of the list and tail->next to the head.
      The circular list costs nothing extra in storage, and
      allows operations to proceed from either end of the list
      with equal speed.  However, the circular link adds
      cognitive overhead for the application programmer in
      general, and it greatly complicates list traversal when
      arbitrary list elements can be added or removed as you
      move through.  It can be done, but in the spirit of
      simplicity, we avoid the temptation.  The price to be paid
      is the extra cost to find the tail of a list -- a full
      traversal -- before the tail can be used.  This is a
      cheap price to pay to avoid major headaches and buggy code.

      When you are only applying some function to each element
      in a list, you can go either forwards or backwards.
      To run through a list forwards, use:

          for (elem = head; elem; elem = nextelem) {
              nextelem = elem->next;   (in case we destroy elem)
              <do something with elem->data>
          }

      To run through a list backwards, find the tail and use:

          for (elem = tail; elem; elem = prevelem) {
 #              prevelem = elem->prev;  (in case we destroy elem)
              <do something with elem->data>
          }

      Even though these patterns are very simple, they are so common
      that we've provided macros for them in list.h.  Using the
      macros, this becomes:

          L_BEGIN_LIST_FORWARD(head, elem)
              <do something with elem->data>
          L_END_LIST

          L_BEGIN_LIST_REVERSE(tail, elem)
              <do something with elem->data>
          L_END_LIST

      Note again that with macros, the application programmer does
      not need to refer explicitly to next and prev fields.  Also,
      in the reverse case, note that we do not explicitly
      show the head of the list.  However, the head of the list
      is always in scope, and functions can be called within the
      iterator that change the head.

      Some special cases are simpler.  For example, when
      removing all items from the head of the list, you can use

          while (head) {
              obj = listRemoveFromHead(&head);
              <do something with obj>
          }

      Removing successive elements from the tail is equally simple:

          while (tail) {
              obj = listRemoveFromTail(&head, &tail);
              <do something with obj>
          }

      When removing an arbitrary element from a list, use

              obj = listRemoveElement(&head, elem);

      All the listRemove*() functions hand you the object,
      destroy the list cell to which it was attached, and
      reset the list pointers if necessary.

      Several other list operations, that do not involve
      inserting or removing objects, are also provided.
      The function listFindElement() locates a list pointer
      by matching the object hanging on it to a given
      object.  The function listFindTail() gets a handle
      to the tail list ptr, allowing backwards traversals of
      the list.  listGetCount() gives the number of elements
      in a list.  Functions that reverse a list and concatenate
      two lists are also provided.

      These functions can be modified for efficiency in the
      situation where there is a large amount of creation and
      destruction of list cells.  If millions of cells are
      made and destroyed, but a relatively small number are
      around at any time, the list cells can be stored for
      later re-use in a stack (see the generic stack functions
      in stack.c).

=head1 FUNCTIONS

=head2 listAddToHead

l_int32 listAddToHead ( DLLIST **phead, void *data )

  listAddToHead()

      Input:  &head  (<optional> input head)
              data  (void* ptr, to be added)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This makes a new cell, attaches the data, and adds the
          cell to the head of the list.
      (2) When consing from NULL, be sure to initialize head to NULL
          before calling this function.

=head2 listAddToTail

l_int32 listAddToTail ( DLLIST **phead, DLLIST **ptail, void *data )

  listAddToTail()

      Input:  &head  (<may be updated>, head can be null)
              &tail  (<updated>, tail can be null)
              data  (void* ptr, to be hung on tail cons cell)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This makes a new cell, attaches the data, and adds the
          cell to the tail of the list.
      (2) &head is input to allow the list to be "cons'd" up from NULL.
      (3) &tail is input to allow the tail to be updated
          for efficient sequential operation with this function.
      (4) We assume that if *phead and/or *ptail are not NULL,
          then they are valid addresses.  Therefore:
           (a) when consing from NULL, be sure to initialize both
               head and tail to NULL.
           (b) when tail == NULL for an existing list, the tail
               will be found and updated.

=head2 listDestroy

void listDestroy ( DLLIST **phead )

  listDestroy()

      Input:  &head   (<to be nulled> head of list)
      Return: void

  Notes:
      (1) This only destroys the cons cells.  Before destroying
          the list, it is necessary to remove all data and set the
          data pointers in each cons cell to NULL.
      (2) listDestroy() will give a warning message for each data
          ptr that is not NULL.

=head2 listFindElement

DLLIST * listFindElement ( DLLIST *head, void *data )

  listFindElement()

      Input:  head  (list head)
              data  (void*  address, to be searched for)
      Return: cell  (the containing cell, or null if not found or on error)

  Notes:
      (1) This returns a ptr to the cell, which is still embedded in
          the list.
      (2) This handle and the attached data have not been copied or
          reference counted, so they must not be destroyed.  This
          violates our basic rule that every handle returned from a
          function is owned by that function and must be destroyed,
          but if rules aren't there to be broken, why have them?

=head2 listFindTail

DLLIST * listFindTail ( DLLIST *head )

  listFindTail()

      Input:  head
      Return: tail, or null on error

=head2 listGetCount

l_int32 listGetCount ( DLLIST *head )

  listGetCount()

      Input:  head  (of list)
      Return: number of elements; 0 if no list or on error

=head2 listInsertAfter

l_int32 listInsertAfter ( DLLIST **phead, DLLIST *elem, void *data )

  listInsertAfter()

      Input:  &head  (<optional> input head)
               elem  (list element to be inserted after;
                      must be null if head is null)
               data  (void*  ptr, to be added)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This can be called on a null list, in which case both
          head and elem must be null.  The head is included
          in the call to allow "consing" up from NULL.
      (2) If you are searching through a list, looking for a condition
          to add an element, you can do something like this:
            L_BEGIN_LIST_FORWARD(head, elem)
                <identify an elem to insert after>
                listInsertAfter(&head, elem, data);
            L_END_LIST

=head2 listInsertBefore

l_int32 listInsertBefore ( DLLIST **phead, DLLIST *elem, void *data )

  listInsertBefore()

      Input:  &head  (<optional> input head)
               elem  (list element to be inserted in front of;
                      must be null if head is null)
               data  (void*  address, to be added)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This can be called on a null list, in which case both
          head and elem must be null.
      (2) If you are searching through a list, looking for a condition
          to add an element, you can do something like this:
            L_BEGIN_LIST_FORWARD(head, elem)
                <identify an elem to insert before>
                listInsertBefore(&head, elem, data);
            L_END_LIST

=head2 listJoin

l_int32 listJoin ( DLLIST **phead1, DLLIST **phead2 )

  listJoin()

      Input:  &head1  (<may be changed> head of first list)
              &head2  (<to be nulled> head of second list)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The concatenated list is returned with head1 as the new head.
      (2) Both input ptrs must exist, though either can have the value NULL.

=head2 listRemoveElement

void * listRemoveElement ( DLLIST **phead, DLLIST *elem )

  listRemoveElement()

      Input:  &head (<can be changed> input head)
              elem (list element to be removed)
      Return: data  (void* struct on cell)

  Notes:
      (1) in ANSI C, it is not necessary to cast return to actual type; e.g.,
             pix = listRemoveElement(&head, elem);
          but in ANSI C++, it is necessary to do the cast:
             pix = (Pix *)listRemoveElement(&head, elem);

=head2 listRemoveFromHead

void * listRemoveFromHead ( DLLIST **phead )

  listRemoveFromHead()

      Input:  &head (<to be updated> head of list)
      Return: data  (void* struct on cell), or null on error

  Notes:
      (1) in ANSI C, it is not necessary to cast return to actual type; e.g.,
            pix = listRemoveFromHead(&head);
          but in ANSI C++, it is necessary to do the cast; e.g.,
            pix = (Pix *)listRemoveFromHead(&head);

=head2 listRemoveFromTail

void * listRemoveFromTail ( DLLIST **phead, DLLIST **ptail )

  listRemoveFromTail()

      Input:  &head (<may be changed>, head must NOT be null)
              &tail (<always updated>, tail may be null)
      Return: data  (void* struct on cell) or null on error

  Notes:
      (1) We include &head so that it can be set to NULL if
          if the only element in the list is removed.
      (2) The function is relying on the fact that if tail is
          not NULL, then is is a valid address.  You can use
          this function with tail == NULL for an existing list, in
          which case  the tail is found and updated, and the
          removed element is returned.
      (3) In ANSI C, it is not necessary to cast return to actual type; e.g.,
            pix = listRemoveFromTail(&head, &tail);
          but in ANSI C++, it is necessary to do the cast; e.g.,
            pix = (Pix *)listRemoveFromTail(&head, &tail);

=head2 listReverse

l_int32 listReverse ( DLLIST **phead )

  listReverse()

      Input:  &head  (<may be changed> list head)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This reverses the list in-place.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
