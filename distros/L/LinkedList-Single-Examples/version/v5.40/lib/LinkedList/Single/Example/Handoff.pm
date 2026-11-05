########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Handoff v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single qw( v2 );

use LinkedList::Single::Example::Lock;

########################################################################
# the queue is a list that begins with a permanent anchor node:
#
#   anchor -> item 1 -> item 2 -> ... -> last item -> sentinel
#
# every item is a node [ $id, @data ].
#
# three things are kept beside the list, all of them cursors:
#
#   anchor  the first node, never removed. it gives the first item a
#           predecessor, which is what the handles need.
#   last    the last node (the anchor when the queue is empty). the
#           sentinel after it is where the next item is pushed, so
#           enqueue never walks the list.
#   pred    id => cursor on the node *before* that item. a singly
#           linked list can only remove a node from its predecessor,
#           so this is what makes cancel O(1).
#
# the cursors are only ever used to step off of ('next' returns a new
# cursor), never advanced, so one cursor can safely be stored in two
# places.
#
# which operations may touch a node that a stored cursor stands on is
# the whole difficulty: 'drop' (remove the node after) and 'push'
# leave every other node where it is (so does the pointer append_to),
# but 'fragment' moves the *contents* of the node it cuts at into
# another node, so a cursor that stood on that node is left looking at
# the wrong data. take uses it, and requeue puts items back whose
# predecessors are new, so both finish by re-walking the few nodes whose
# predecessors may have changed (_reindex).
########################################################################

sub new( $class, %arg )
{
    my $lock    = $arg{ lock } // LinkedList::Single::Example::Lock->new;
    my $list    = LinkedList::Single->new;

    # an empty list: push fills the sentinel in place.

    $list->push( 0 );

    my $anchor  = $list->cursor;

    bless
    {
        lock    => $lock
      , list    => $list
      , anchor  => $anchor
      , last    => $anchor
      , pred    => {}
      , serial  => 0
      , size    => 0

        # statistics: nodes this module's code stepped over, and
        # index entries thrown away, while the lock was held.

      , walked  => 0
      , purged  => 0
    }
    => $class
}

########################################################################
# public interface: take the lock and do the work.
########################################################################

# queue one item; returns its handle (an id).

sub enqueue( $self, @data )
{
    $self->{ lock }->hold( \&_enqueue, $self, @data )
}

# the whole queue as one batch, in O(1) list operations.
#
# the lock-held code hands back the old index along with the batch,
# the way the array hands back its old array, and it is let go here
# once the lock has been released. it has to be gone before the batch
# is processed: its cursors stand on the batch's nodes, and would keep
# each one (and its payload) alive after processing had finished with it.

sub drain( $self )
{
    my( $batch, $retired )
    = $self->{ lock }->hold( \&_drain, $self )->@*;

    undef $retired;

    $batch
}

# at most $k items from the front.

sub take( $self, $k )
{
    my( $batch, $retired )
    = $self->{ lock }->hold( \&_take, $self, $k )->@*;

    # only set when the whole queue went (see _drain).

    undef $retired;

    $batch
}

# remove one queued item by handle. true if it was still queued.

sub cancel( $self, $id )
{
    $self->{ lock }->hold( \&_cancel, $self, $id )
}

# put what is left of a batch back at the front of the queue.
# returns the number of items put back.

sub requeue( $self, $batch )
{
    # a fully consumed batch has nothing to give back.

    $batch
    or return 0;

    $self->{ lock }->hold( \&_requeue, $self, $batch )
}

########################################################################
# work on a batch: the lock is NOT held. the batch belongs to the
# caller, nothing else can see it.
#
# the handler gets ( $id, @data ) for each item. stopping after $limit
# items leaves the rest in the batch for requeue. each item is let go
# as the batch advances past it.
########################################################################

sub process( $self, $batch, $handler, $limit = undef )
{
    $batch
    or return 0;

    my $done    = 0;

    # consume ends quietly on die "\n", and puts the item it was
    # on back to the caller as the head of what is left. any other
    # exception is carped and also stops the batch there.

    $batch->consume
    (
        sub( @item )
        {
            defined $limit
            && $done >= $limit
            and die "\n";

            $handler->( @item );

            ++$done;
        }
    );

    $done
}

# items left in a batch.

sub left( $self, $batch )
{
    $batch
    ? $batch->count
    : 0
}

########################################################################
# the work done while the lock is held
########################################################################

sub _enqueue( $self, @data )
{
    my $id      = ++$self->{ serial };
    my $last    = $self->{ last };

    # the node after $last is the sentinel: push fills it and hangs
    # a new sentinel off the end. the old last node is the new
    # item's predecessor, and the filled node is the new last.

    $last->next->push( $id, @data );

    $self->{ pred }{ $id }  = $last;
    $self->{ last }         = $last->next;

    ++$self->{ size };

    $id
}

########################################################################
# the entire queue goes in one fragment. nothing is walked.
#
# the fragment takes the old sentinel with it, and the node after the
# anchor is left as a fresh, empty one for the next enqueue to fill.
#
# the index is swapped out, not cleared: every handle in it points into
# the batch, so it leaves with the batch and the caller frees it after
# the lock is released. freeing it is proportional to the queue (a
# cursor object per item), and an array that keeps an index for cancel
# has exactly the same bill. 'purged' counts the entries retired.
########################################################################

sub _drain( $self )
{
    my $anchor  = $self->{ anchor };
    my $batch   = $anchor->next->fragment;
    my $index   = $self->{ pred };

    $self->{ purged }   += $self->{ size };

    $self->{ pred }     = {};
    $self->{ last }     = $anchor;
    $self->{ size }     = 0;

    [ $batch, $index ]
}

########################################################################
# the first $k items. walking to the end of them is the O(k) part;
# the cut itself is two fragments:
#
#   anchor -> a1 .. ak -> r1 -> r2 ...
#
#   $rest  = r1 and everything after it     (r1 becomes a sentinel)
#   $batch = a1 .. ak, ending at that sentinel
#
# and the rest goes back after the anchor, into the empty node that
# a1 left behind. the contents of a1 and r1 have moved, so the
# predecessors of r1 and r2 are re-recorded.
########################################################################

sub _take( $self, $k )
{
    $k > 0
    or return [ LinkedList::Single::Fragment->new ];

    my $anchor  = $self->{ anchor };
    my $cut     = $anchor->next;
    my @id      = ();

    while( $cut && @id < $k )
    {
        push @id, ( $cut->data )[ 0 ];

        $cut->advance;
    }

    $self->{ walked }   += @id;

    # ran off the end: that is the whole queue.

    $cut
    or return _drain( $self );

    my $rest    = $cut->fragment;
    my $batch   = $anchor->next->fragment;

    $rest->push_onto( $anchor->next );

    # the taken items are no longer cancellable.

    delete $self->{ pred }->@{ @id };

    $self->{ size } -= @id;

    _reindex( $self, 2 );

    [ $batch ]
}

########################################################################
# remove one item from the middle of the queue: O(1).
#
# $pred stands on the node before the item; drop unlinks the node
# after it by pointer, which moves nothing else. the item after the
# one removed now follows $pred, so its handle is re-pointed.
########################################################################

sub _cancel( $self, $id )
{
    my $pred    = delete $self->{ pred }{ $id }
    // return 0;

    # next( 2 ) and not next->next: the intermediate cursor of the
    # latter would be kept by the Cursor class (the stale whence slot, see the POD) with the node about
    # to be dropped, and the payload would outlive the cancel. the
    # target always exists, so two steps land on the sentinel at worst
    # and never past it (the bounds fix for next( $n ) does not apply).

    my $after   = $pred->next( 2 );

    if( $after )
    {
        $self->{ pred }{ ( $after->data )[ 0 ] }    = $pred;
    }
    else
    {
        # the item was the last one: its predecessor is now.

        $self->{ last } = $pred;
    }

    # void context: the data is not wanted, and goes with the node.

    $pred->drop;

    --$self->{ size };

    1
}

########################################################################
# the unprocessed rest of a batch goes back to the front. append_to
# puts it after the anchor and the old queue after it, without copying
# a node; it walks the batch once to find its end. every item put back
# gets a handle again, and so does the old front of the queue (and the
# one behind it), since its predecessor is now the end of the batch.
########################################################################

sub _requeue( $self, $batch )
{
    my $count   = $batch->count;

    $batch->append_to( $self->{ anchor } );

    $self->{ size }     += $count;
    $self->{ walked }   += $count;

    _reindex( $self, $count + 2 );

    $count
}

########################################################################
# record the predecessor of each of the first $count items, walking
# from the anchor, and if that reaches the end of the queue, the last
# node too. nothing past the window is touched.
########################################################################

sub _reindex( $self, $count )
{
    my $pred    = $self->{ anchor };
    my $item    = $pred->next;

    for( 1 .. $count )
    {
        $item
        or last;

        $self->{ pred }{ ( $item->data )[ 0 ] } = $pred;

        ++$self->{ walked };

        $pred   = $item;
        $item   = $pred->next;
    }

    # no item left to look at: $pred is the last node.

    $item
    or $self->{ last } = $pred;

    return
}

########################################################################
# introspection
########################################################################

# arrayref of [ $id, @data ], oldest first.

sub contents( $self )
{
    my @item
    = ( ( scalar $self->{ list }->extract ) // [] )->@*;

    # the anchor is not an item.

    shift @item;

    \@item
}

sub size( $self )
{
    $self->{ size }
}

sub lock( $self )
{
    $self->{ lock }
}

sub walked( $self )
{
    $self->{ walked }
}

sub purged( $self )
{
    $self->{ purged }
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Handoff - a work queue handed from producer to consumer, with cancel by handle, kept in a linked list

=head1 SYNOPSIS

    use LinkedList::Single::Example::Handoff;

    my $queue   = LinkedList::Single::Example::Handoff->new;

    my $id      = $queue->enqueue( 'send', $mail );

    $queue->cancel( $id );                 # still queued? then gone

    my $batch   = $queue->take( 50 );      # or ->drain for all of it

    # the lock is not held for any of this

    my $done    = $queue->process( $batch, sub( $id, @job ) { ... }, 20 );

    $queue->requeue( $batch );             # whatever was left

=head1 DESCRIPTION

A producer puts work on a queue with C<enqueue>, which returns a handle
(an integer id); C<cancel( $id )> takes that item out again if it is
still queued. A consumer takes a batch under the lock, either the whole
queue (C<drain>) or at most C<$k> items from the front (C<take>), and
works through it with the lock released: C<process> passes each item to
a handler, optionally stopping after a limit, and C<requeue> puts the
part of a batch that was not done back at the front. C<left> counts what
is still in a batch; C<contents>, C<size>, C<walked> and C<purged> look at
the queue without changing it.

The queue is a L<LinkedList::Single> list behind a permanent anchor node,
with a cursor on its last node and a hash from each id to a cursor on the
node I<before> that item. A batch is a Fragment cut off the list. Every
method that touches the queue runs inside
L<LinkedList::Single::Example::Lock>, a stand-in lock that records how
often and for how long it was held (perl ithreads cannot share a linked
list, so there are no real threads).

Two classes with the same interface keep the queue in perl arrays:
L<LinkedList::Single::Example::Handoff::Array> (hand-off by swapping the
array reference, or by copying, and cancel by search) and
L<LinkedList::Single::Example::Handoff::Marked> (an array plus a hash from
id to item, with cancel by marking). The tests drive all of them with the
same random schedule and compare every result.

=head2 How it is benchmarked

F<benchmarks/40-Handoff/compare> runs, at queue lengths of 1,000, 20,000
and 200,000: a whole-queue hand-off, 100 bounded batches of 50, 200
cancels by handle, and 200 rounds of take 100, process 50, requeue 50. It
reports the seconds the lock was held and the total seconds (best of 3),
the nodes or elements stepped over under the lock, the resident memory of
a fresh process holding 200,000 items, the bytes left after a burst and
after cancelling 90% of a queue, and statements and branches counted in
the lock-held code.

=head2 Why it matters

Everything done while a lock is held is time the other side waits. Under
the lock the list's whole-queue hand-off is constant time, but so is the
array's reference swap, and the list is slower than the arrays at taking
a bounded batch, at requeueing, and at processing. Its one lasting
advantage is cancel: constant time, with the item's memory returned at
once, where an array either searches or leaves a husk behind. The
measurements, the background and the references are in
L<LinkedList::Single::Example::Handoff::POD>.

This is an example, not a queue for production use: there are no real
threads, no blocking and no priorities.

=head1 SEE ALSO

L<LinkedList::Single::Example::Handoff::POD>, L<LinkedList::Single>
