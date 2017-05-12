package Image::Leptonica::Func::stack;
$Image::Leptonica::Func::stack::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::stack

=head1 VERSION

version 0.04

=head1 C<stack.c>

  stack.c

      Generic stack

      The lstack is an array of void * ptrs, onto which
      objects can be stored.  At any time, the number of
      stored objects is lstack->n.  The object at the bottom
      of the lstack is at array[0]; the object at the top of
      the lstack is at array[n-1].  New objects are added
      to the top of the lstack; i.e., the first available
      location, which is at array[n].  The lstack is expanded
      by doubling, when needed.  Objects are removed
      from the top of the lstack.  When an attempt is made
      to remove an object from an empty lstack, the result is null.

      Create/Destroy
           L_STACK        *lstackCreate()
           void            lstackDestroy()

      Accessors
           l_int32         lstackAdd()
           void           *lstackRemove()
           static l_int32  lstackExtendArray()
           l_int32         lstackGetCount()

      Text description
           l_int32         lstackPrint()

=head1 FUNCTIONS

=head2 lstackAdd

l_int32 lstackAdd ( L_STACK *lstack, void *item )

  lstackAdd()

      Input:  lstack
              item to be added to the lstack
      Return: 0 if OK; 1 on error.

=head2 lstackCreate

L_STACK * lstackCreate ( l_int32 nalloc )

  lstackCreate()

      Input:  nalloc (initial ptr array size; use 0 for default)
      Return: lstack, or null on error

=head2 lstackDestroy

void lstackDestroy ( L_STACK **plstack, l_int32 freeflag )

  lstackDestroy()

      Input:  &lstack (<to be nulled>)
              freeflag (TRUE to free each remaining struct in the array)
      Return: void

  Notes:
      (1) If freeflag is TRUE, frees each struct in the array.
      (2) If freeflag is FALSE but there are elements on the array,
          gives a warning and destroys the array.  This will
          cause a memory leak of all the items that were on the lstack.
          So if the items require their own destroy function, they
          must be destroyed before the lstack.
      (3) To destroy the lstack, we destroy the ptr array, then
          the lstack, and then null the contents of the input ptr.

=head2 lstackGetCount

l_int32 lstackGetCount ( L_STACK *lstack )

  lstackGetCount()

      Input:  lstack
      Return: count, or 0 on error

=head2 lstackPrint

l_int32 lstackPrint ( FILE *fp, L_STACK *lstack )

  lstackPrint()

      Input:  stream
              lstack
      Return: 0 if OK; 1 on error

=head2 lstackRemove

void * lstackRemove ( L_STACK *lstack )

  lstackRemove()

      Input:  lstack
      Return: ptr to item popped from the top of the lstack,
              or null if the lstack is empty or on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
