package Image::Leptonica::Func::queue;
$Image::Leptonica::Func::queue::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::queue

=head1 VERSION

version 0.04

=head1 C<queue.c>

   queue.c

      Create/Destroy L_Queue
          L_QUEUE        *lqueueCreate()
          void           *lqueueDestroy()

      Operations to add/remove to/from a L_Queue
          l_int32         lqueueAdd()
          static l_int32  lqueueExtendArray()
          void           *lqueueRemove()

      Accessors
          l_int32         lqueueGetCount()

      Debug output
          l_int32         lqueuePrint()

    The lqueue is a fifo that implements a queue of void* pointers.
    It can be used to hold a queue of any type of struct.
    Internally, it maintains two counters:
        nhead:  location of head (in ptrs) from the beginning
                of the buffer
        nelem:  number of ptr elements stored in the queue
    As items are added to the queue, nelem increases.
    As items are removed, nhead increases and nelem decreases.
    Any time the tail reaches the end of the allocated buffer,
      all the pointers are shifted to the left, so that the head
      is at the beginning of the array.
    If the buffer becomes more than 3/4 full, it doubles in size.

    [A circular queue would allow us to skip the shifting and
    to resize only when the buffer is full.  For most applications,
    the extra work we do for a linear queue is not significant.]

=head1 FUNCTIONS

=head2 lqueueAdd

l_int32 lqueueAdd ( L_QUEUE *lq, void *item )

  lqueueAdd()

      Input:  lqueue
              item to be added to the tail of the queue
      Return: 0 if OK, 1 on error

  Notes:
      (1) The algorithm is as follows.  If the queue is populated
          to the end of the allocated array, shift all ptrs toward
          the beginning of the array, so that the head of the queue
          is at the beginning of the array.  Then, if the array is
          more than 0.75 full, realloc with double the array size.
          Finally, add the item to the tail of the queue.

=head2 lqueueCreate

L_QUEUE * lqueueCreate ( l_int32 nalloc )

  lqueueCreate()

      Input:  size of ptr array to be alloc'd (0 for default)
      Return: lqueue, or null on error

  Notes:
      (1) Allocates a ptr array of given size, and initializes counters.

=head2 lqueueDestroy

void lqueueDestroy ( L_QUEUE **plq, l_int32 freeflag )

  lqueueDestroy()

      Input:  &lqueue  (<to be nulled>)
              freeflag (TRUE to free each remaining struct in the array)
      Return: void

  Notes:
      (1) If freeflag is TRUE, frees each struct in the array.
      (2) If freeflag is FALSE but there are elements on the array,
          gives a warning and destroys the array.  This will
          cause a memory leak of all the items that were on the queue.
          So if the items require their own destroy function, they
          must be destroyed before the queue.  The same applies to the
          auxiliary stack, if it is used.
      (3) To destroy the L_Queue, we destroy the ptr array, then
          the lqueue, and then null the contents of the input ptr.

=head2 lqueueGetCount

l_int32 lqueueGetCount ( L_QUEUE *lq )

  lqueueGetCount()

      Input:  lqueue
      Return: count, or 0 on error

=head2 lqueuePrint

l_int32 lqueuePrint ( FILE *fp, L_QUEUE *lq )

  lqueuePrint()

      Input:  stream
              lqueue
      Return: 0 if OK; 1 on error

=head2 lqueueRemove

void * lqueueRemove ( L_QUEUE *lq )

  lqueueRemove()

      Input:  lqueue
      Return: ptr to item popped from the head of the queue,
              or null if the queue is empty or on error

  Notes:
      (1) If this is the last item on the queue, so that the queue
          becomes empty, nhead is reset to the beginning of the array.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
