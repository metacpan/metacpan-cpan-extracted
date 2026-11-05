package LinkedList::Single::Example::Handoff::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::Handoff::POD - A work queue handed from producer to consumer, with cancel by handle, in a linked list

=head1 SYNOPSIS

    perl app/40-Handoff/lock-handoff        # a short demonstration (a mail spooler)
    prove -r t/40-Handoff                   # the tests
    perl benchmarks/40-Handoff/compare      # the measurements below
                                            # (about three minutes, most of it
                                            # the array that searches)

=head1 THE PROBLEM

A I<producer> puts jobs on a queue and a I<consumer> takes them off: mail
to send, files to index, requests to answer. When the two run at the same
time the queue is shared, and a I<lock> makes sure only one of them
changes it at once. While one side holds the lock the other waits, so the
work done with the lock held is what matters, not the total. The consumer
therefore takes a I<batch> out under the lock and works on it with the
lock released.

Taking everything is the simple case. Real queues also want to take at
most I<k> items; to cancel one queued item by the I<handle> (here an
integer id) that C<enqueue> returned; to put the part of a batch that was
not done back at the I<front>; and to let go of the memory of a finished
or cancelled item promptly. In outline, whatever the data structure, with C<lock { ... }> meaning
"while the lock is held":

    enqueue( job ):     lock { add job at the back; answer its handle }

    drain:              lock { the whole queue becomes the batch;
                               the queue is empty }

    take( k ):          lock { the first k jobs become the batch }

    cancel( handle ):   lock { if that job is still queued, remove it }

    process( batch ):   for each job in the batch (no lock):
                            stop early if asked; do the job; let it go

    requeue( batch ):   lock { what is left of the batch goes in front }

Perl's ithreads copy all of a thread's data into a new thread and share
nothing unless it is marked shared, and a shared array or hash may hold
only simple values or references to other shared variables [1]. A list of
objects like this one cannot be shared that way, so there are no threads
here. L<LinkedList::Single::Example::Lock> stands in for the lock: its
C<hold( $code, @arg )> runs the code and records how many times the lock
was taken and for how long it was held, which is the number another
thread would wait for. Everything is single-threaded and reproducible.

=head1 A FIRST ATTEMPT: AN ARRAY

The plainest queue is an array of C<[ $id, @data ]>, pushed at the back
(L<LinkedList::Single::Example::Handoff::Array>). Handing off the whole
queue does not need to copy it; C<_drain> swaps the reference:

    my $queue           = $self->{ queue };
    $self->{ queue }    = [];

    return $queue;

This is constant time with the lock held, whatever the length of the
queue, and it is what someone who knows perl writes first. The class can
also be built with C<< drain => 'copy' >>, which copies the items out and
clears the array, so that the table can show what the swap saves.
C<take( $k )> is C<< splice $queue->@*, 0, $k >>, and C<requeue> is an
C<unshift>; both are single built-in operations.

Cancel is the problem. An array has no way to go from an id to a position
except by looking:

    ++$at
    while $at < $queue->@*
    && $queue->[ $at ][ 0 ] != $id;

    splice $queue->@*, $at, 1;

The search looks at every item up to and including the one cancelled, and
the C<splice> slides everything after it along. With 200,000 items queued,
200 cancels hold the lock for 13 seconds.

=head1 ADDING A HASH

The array version an experienced perl programmer writes when cancel has
to be fast (L<LinkedList::Single::Example::Handoff::Marked>) keeps a hash
from id to item beside the array. Cancel finds the item at once but still
cannot take it out of the middle of the array cheaply, so it empties it
in place and leaves a I<husk> that is skipped when it reaches the front:

    my $item    = delete $self->{ item }{ $id }
    // return 0;

    $item->@*   = ( undef );        # the payload goes, the husk stays

This cancel is constant time and faster than the list's. What it leaves
is memory: a husk per cancelled item until something takes it, and a
C<take> that has to step over them. A hash alone is not an alternative
here, because a hash keeps no order and a queue is an order.

=head1 KEEPING THE QUEUE IN A LINKED LIST

A linked list is a chain of nodes in which each node knows the next one.
Removing a node from the middle is changing one link, and cutting the
chain in two hands over everything after the cut at once; nothing slides
along and nothing is copied. L<LinkedList::Single> (version 2) provides
such a list. A I<cursor> marks a node and can be asked for the next one
(C<< $cursor->next >> returns a new cursor, C<next( 2 )> one two nodes on).
The I<sentinel> is the empty node at the end of every list; a cursor on it
tests false. A I<Fragment> is a run of nodes cut out of a list, owned by
the Fragment until it is put back or consumed.

The queue is one list that starts with a permanent I<anchor> node, which
holds no item:

    anchor -> item 1 -> item 2 -> ... -> last item -> (sentinel)

    last          = a cursor on the last node (the anchor when empty)
    pred{ $id }   = a cursor on the node before $id's item

In a list where each node knows only the I<next> one, a node can be
removed only from the node in front of it, because that is the node whose
link changes. So a handle that found the item itself would be no use for
cancel; the hash keeps a cursor on its I<predecessor>, and the anchor
gives the first item one. These cursors are only ever stepped off of with
C<next>, never moved, so one cursor can be stored in two places.

=head2 Enqueue

C<< $list->push >> on a list that is not empty walks to the end to find
it. C<last> avoids that: the node after it is the sentinel, and C<push> on
a sentinel fills it in place and hangs a new sentinel after it:

    sub _enqueue( $self, @data )
    {
        my $id      = ++$self->{ serial };
        my $last    = $self->{ last };

        $last->next->push( $id, @data );

        $self->{ pred }{ $id }  = $last;
        $self->{ last }         = $last->next;

        ++$self->{ size };

        $id
    }

=head2 Cancel

This is the operation the list is for, and the module reads cleanly here
(trimmed: a comment and the C<size> count):

    sub _cancel( $self, $id )
    {
        my $pred    = delete $self->{ pred }{ $id }
        // return 0;

        my $after   = $pred->next( 2 );        # the item behind it, if any

        if( $after )
        {
            $self->{ pred }{ ( $after->data )[ 0 ] } = $pred;
        }
        else
        {
            $self->{ last } = $pred;
        }

        $pred->drop;                           # unlink the node after $pred

        1
    }

C<drop> unlinks the node after a cursor by changing one link, and leaves
every other node where it was. The node, and the item's payload with it,
are freed at that moment. One handle has to be repaired, the item behind
the cancelled one, which now follows C<$pred>; that is the price of a list
linked in one direction. C<next( 2 )> is used and not C<next-E<gt>next>
for a reason given in L</A NOTE FOR LinkedList::Single>.

=head2 Draining the whole queue

C<fragment> on the cursor after the anchor cuts off everything from there
to the end as one Fragment and leaves an empty node in its place, ready
for the next C<enqueue>. Nothing is walked. The hash of handles cannot
stay behind, since its cursors stand on the batch's nodes, and clearing it
under the lock would cost one step per item; so it is swapped out the way
the array swaps its reference, and freed by the caller once the lock is
released (trimmed: the C<purged> count):

    sub _drain( $self )
    {
        my $anchor  = $self->{ anchor };
        my $batch   = $anchor->next->fragment;
        my $index   = $self->{ pred };

        $self->{ pred }     = {};
        $self->{ last }     = $anchor;
        $self->{ size }     = 0;

        [ $batch, $index ]
    }

The public C<drain> takes both from the lock, C<undef>s the old index and
returns the batch. The index must go before the batch is processed:
otherwise its cursors would keep every node, and its payload, alive after
processing had finished with it.

=head2 Taking a bounded batch

C<take( $k )> walks C<$k> nodes and cuts twice. Here the module is
awkward. C<fragment> does not cut a link; it moves the I<contents> of the
node it is called on into the Fragment and leaves an empty node behind.
A stored cursor on that node would then see different data, so the two
handles around the cut are re-recorded afterwards by a short re-walk,
C<_reindex( 2 )> (trimmed: C<$k> of zero, and the hand-over to C<_drain>
when the walk runs off the end):

    anchor -> a1 .. ak -> r1 -> r2 ...

    my $rest    = $cut->fragment;              # r1 and all after it
    my $batch   = $anchor->next->fragment;     # a1 .. ak

    $rest->push_onto( $anchor->next );         # the rest back behind the anchor

    delete $self->{ pred }->@{ @id };          # taken items cannot be cancelled

    $self->{ size } -= @id;

    _reindex( $self, 2 );

C<push_onto> moves the Fragment's nodes onto the empty node C<a1> left
behind. Deleting the taken items' handles also matters for memory: a
cursor left in the hash would keep a batch node alive.

=head2 Processing, and giving back what was not done

C<process> runs the caller's handler through C<consume>, the Fragment's
loop, which passes each node's data to a handler and lets the node go as
it advances. A bare C<die "\n"> from the handler ends the loop normally
and leaves the node it was on at the head of the Fragment; that is how
C<process( ..., $limit )> stops I<before> the item after the limit:

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

C<requeue> then puts what is left after the anchor with C<append_to>,
which relinks the Fragment in front of the old queue without building or
copying a node, walking the Fragment once to find its end. Nothing moved,
but every item put back, and the two after them, have new predecessors,
so I<j> + 2 handles are re-recorded for I<j> items:

    my $count   = $batch->count;

    $batch->append_to( $self->{ anchor } );

    $self->{ size }     += $count;

    _reindex( $self, $count + 2 );

=head1 CHECKING THAT IT IS RIGHT

The array version is simple enough to read and be sure of, so the tests
use it as the reference. F<t/40-Handoff/20-vs-array.t> drives the list
and the three array queues from one random schedule of 3,000 steps
(enqueue, take, drain, process, requeue, and cancel, including cancels of
items already gone or not yet issued) and compares every result and the
whole queue after every step.

F<t/40-Handoff/40-invariants.t> checks, after every operation and every
step of a 1,500-step random run, that the hash holds exactly the queued
items, that each handle's cursor stands on the node before its item (by
C<refaddr> against a walk), that C<last> is the final node with the
sentinel after it, that the size is right, and that a taken batch shares
no node with the queue.

F<t/40-Handoff/30-lifetime.t> uses L<LinkedList::Single::Example::Probe>
payloads, which record when they are destroyed, to show that a payload
goes at cancel and as C<process> advances, and never in C<take> or
C<requeue>.

F<t/40-Handoff/50-hold.t> checks the lock-held work by counting instead
of timing, which would be flaky: the list's C<enqueue>, C<cancel> and
C<drain> step over no nodes, its C<take> steps over I<k> + 2, and the
array that searches steps over every item up to and including the one
cancelled.

=head1 WHAT IT COSTS

Measured on one machine (the author's workstation, perl 5.40, 2026-10-30);
the relative sizes are what matters. Times are the best of 3 runs.
C<held_secs> is time inside the lock, the part another thread would wait
for; C<total_secs> includes processing the batches. C<walked> is nodes or
elements stepped over one at a time under the lock, and C<purged> is
handles retired. C<array-swap> and C<array-copy> are the first attempt,
C<array-mark> the one with a hash.

=head2 Whole queue

    queue of 200000   held_secs total_secs     walked     purged
    list               0.000030   0.961088          0     200000
    array-swap         0.000005   0.119347          0          0
    array-copy         0.039414   0.163187     200000          0
    array-mark         0.000004   0.249359          0     200000

Under the lock the list ties the swap: both are flat in the queue length
(about 30 and 5 microseconds at 200,000 items) and both beat the copy by
a factor that grows with the queue. That needed the index swapped out: in
the first build the lock-held code cleared it, and the hand-off took
0.158 seconds at 200,000 items, slower than even the copy. Swapped, the
bill is still paid, in C<total_secs> instead of C<held_secs>. The total
does not tie: 0.96 seconds against 0.12, the cost of walking and
releasing 200,000 nodes one at a time in perl code (C<consume>) against
C<shift>ing array elements, plus freeing the index.

=head2 A bounded batch

    100 x take(50), queue of 200000
                      held_secs total_secs     walked     purged
    list               0.043208   0.065082       5200          0
    array-swap         0.000641   0.004701       5000          0
    array-mark         0.010025   0.013928       5000          0

The array wins by about 70 times. Both are O(k), meaning the work grows
with I<k> and not with the queue, but C<splice> is a block move done in
C, and the list walks and cuts in perl, which costs far more per item.

=head2 Cancel by handle

    200 cancels over a queue of 1000 / 20000 / 200000
                      held_secs (1000)   (20000)    (200000)
    list                  0.001732      0.002553     0.002631
    array-swap            0.025135      0.664352    13.018624
    array-mark            0.000248      0.000421     0.000506

The list's cancel is flat; the searching array's grows in proportion to
the queue (21 million elements examined at 200,000), so the list's lead
over it grows with the queue. The array with a hash is flat as well and
about five times faster than the list, because it does less: a hash
lookup and an assignment.

=head2 Giving back the unfinished part of a batch

    200 x ( take 100, process 50, requeue 50 ), queue of 200000
                      held_secs total_secs
    list               0.173048   0.216713
    array-swap         0.001995   0.010271
    array-mark         0.027182   0.035855

An array's C<unshift> moves the whole queue, so its cost grows with the
queue; the list's requeue grows only with the items put back. At 200,000
items the block move is still cheap next to the list's per-node perl
code, so the array wins by about 90 times and no crossover was reached.
Longer queues were not tried.

=head2 Memory

Resident memory of a fresh process holding 200,000 items; the bytes per
item are those totals divided by 200,000:

                  total bytes   per item   what it holds
    list             99303424        497   nodes + handle index (a cursor per item)
    array-mark       73494528        367   items + handle index (a hash entry per item)
    array-swap       41127936        206   items only: no index, cancel by search

Each row is a whole structure; they are not additive. The fair comparison
for a queue that can cancel by handle is the list against the array with a
hash: 1.35 times the memory. Against the array with no index it is 2.4
times, but that array cannot cancel without a search. The difference is
the index: the list keeps a cursor object per item, where the array's
hash entry points at an item that exists anyway. A list without handles
would not pay that; it was not measured.

The list gives memory back as items leave:

    bytes held by the items after cancelling 180000 of 200000
    list               1920096
    array-mark        30874784

    container bytes left after a burst of 200000 is drained and processed
    list                    96
    array-swap              64
    array-copy         1754784
    array-mark              64

After cancels the husks stay in the array until something takes them,
while the list freed its nodes as it went. That is the one lasting
advantage this example shows, and it matters where cancels are common and
queues live long. After a burst the list ties the arrays that swap, and
both beat the array that copies, which keeps the size it grew to; so "the
list gives memory back" after a burst is true only against a version of
the array that is not worth writing.

=head2 Code

Statements / branches / index operations in the lock-held code
(C<LinkedList::Single::Example::Bench::complexity>):

    take      list 24/8/2     array 13/4/3     marked 21/7/4
    cancel    list 16/5/2     array 16/7/4     marked 13/4/2
    requeue   list 15/4/2     array 14/4/2     marked 18/4/2
    enqueue   list 15/2/3     array 11/2/3     marked 14/2/3
    drain     list 15/4/1     array 15/5/1     marked 14/4/1

The list has fewer index operations but is not simpler. C<take> is the
most complex method in the example, because the handles have to be
re-recorded after the cut, and that is the hard part of using a singly
linked list this way.

=head1 READABILITY AND CHANGE

Here "readable" means that a reader with ordinary perl can see what a sub
does from its lines, without having to know a rule kept somewhere else;
"easy to change" means that a new requirement touches few subs. Line
counts are below. The excerpts are from the three modules, trimmed of the
C<walked>/C<touched> statistics. Line numbers are of the modules as
they stand in this repository.

=head2 A batch is one splice in the array

The array's C<_take> is the problem statement:

    my $batch   = [ splice $queue->@*, 0, $k ];

The list's, shown above, walks C<$k> nodes collecting ids, cuts twice,
puts the rest back with C<push_onto>, deletes the taken handles and calls
C<_reindex>. None of that is in the description "the first I<k> jobs
become the batch"; it is there because C<fragment> moves contents and the
handles must follow. The array is simpler here, plainly.

=head2 A cancelled item leaves no husk behind

The array with a hash has the shortest cancel (shown above: delete from
the hash, empty the item). The husk it leaves is a rule every later
reader must know, and F<Handoff/Marked.pm> tests it six times in five
other subs: C<process> (line 100), C<left> (113), C<_take> (165 and 172),
C<_requeue> (197) and C<contents> (217); for example:

    defined $item->[ 0 ]                    # process
    or next;

    scalar grep { defined $_->[ 0 ] } $batch->@*      # left

Each guards a quiet mistake: without it C<process> calls the handler
with an C<undef> id and counts it done, C<_take> counts husks towards
I<k> and returns fewer jobs, and C<_requeue> puts husks back in front
(perl warns about the C<undef> hash key, nothing more). The array's
length is not the queue's size either, so a C<live> count is kept by
hand (lines 129, 147, 176, 190, 203).

The list's C<left> is C<< $batch ? $batch->count : 0 >>, and its
C<process>, C<take> and C<contents> know nothing about cancels: a
cancelled node is gone, and no state means "cancelled". The count is not
saved: C<size> is kept by hand in the same five subs (F<Handoff.pm>
lines 202, 230, 281, 324, 343); only the array that searches reads it
from the data (line 200). Against that array, the list's cancel has no
position and no bounds test (C<< $at < $queue->@* >>), but is not
shorter.

=head2 Each list handle depends on its neighbour

What the list removes in husks it pays back in its index. The hash of the
array with a hash points at the item itself, so a cancel touches only its
own entry and a requeue re-adds only the items put back (line 201). The
list's handle is a cursor on the item's I<predecessor>, so changing one
item changes another's handle. The rule "every handle is a cursor on the
predecessor, and C<last> is the last node" is written in C<_enqueue>
(lines 199-200), C<_drain> (228-229), C<_take> (C<_reindex( 2 )>, 283),
C<_cancel> (the item behind, 311, or C<last>, 317), C<_requeue>
(C<_reindex( $count + 2 )>, 346) and C<_reindex>, a sub only the list
needs. Forgetting one of these is worse than forgetting a husk test: a
stale cursor, or one whose node had its contents moved by C<fragment>,
makes a later cancel C<drop> a I<different> job, with no error.
F<t/40-Handoff/40-invariants.t> exists to catch that, by checking every
handle against a walk by C<refaddr>. Two rules guard memory, not order:
C<next( 2 )> in C<_cancel> (line 307, with a five-line comment on the
stale C<whence> slot), and letting the retired index go before the batch
is processed (lines 99, 113), which C<Marked::drain> also does (line 60).
The anchor has to be skipped in C<contents>. The array that searches is
the shortest module, and the tests use it as the reference. Not checked:
whether F<t/40-Handoff/20-vs-array.t> would catch each mistake above if
its guarding line were removed; none was removed to find out.

=head2 Processing, and stopping part way

The array's loop says what it does:

    while
    (
        $batch->@*
        && ( ! defined $limit || $done < $limit )
    )
    {
        my $item    = shift $batch->@*;

        $handler->( $item->@* );

        ++$done;
    }

The list's C<consume>, shown above, stops by C<die "\n">, which is a
convention of C<consume> that the reader has to be told about. Neither
side keeps a position to stay in step with the batch: the array
C<shift>s and the Fragment drops each node as it goes, so in both what is
left is the batch itself, and C<requeue> needs nothing else. The only
difference in what can go wrong is the husk test in the marked version.

=head2 Changing it

If cancelled items must give their memory back at once,
the list already does; the array with a hash would have to search and
C<splice> in C<_cancel> (becoming the array that searches) or add a
sweep, and the husk tests stay in the other five subs either way. If the
module's relinking C<detach> (see L</A NOTE FOR LinkedList::Single>)
replaced C<fragment> in C<_take>, the change is confined to C<_take>;
whether it removes the C<_reindex( 2 )> was not tried. Any new operation
that puts items in front of the queue (a "do this next" C<enqueue>) costs
the arrays one C<unshift>, plus one hash entry for the marked one; the
list has to re-record the handles of the new items and the two after
them, as C<_requeue> does.

=head2 Line counts, and the verdict

Lines from C<sub> to the closing brace, then the lines that are not blank
or comments, in the code in this repository:

                 list     array    marked
    _take        38/23     9/7      24/17
    _cancel      32/17    18/13     13/8
    _requeue     13/9     12/8      15/10
    process      27/18    19/15     22/17
    left          6/6      4/4       4/4
    _reindex     25/17      -         -
    module      421/188  218/129   240/140   (above __END__)

The verdict for this example: the arrays are simpler to read for C<take>,
C<requeue> and C<process>, and the array with a hash for C<cancel> itself;
the list is simpler only in that cancelled items leave nothing behind for
the rest of the code to skip. It moves the bookkeeping rather than
removing it: six husk tests and a C<live> count in the array with a hash,
against a predecessor index that five subs must repair (two through
C<_reindex>), where a mistake drops the wrong job.

=head1 WHAT TO TAKE FROM IT

The list provides cancel from the middle of a long queue in constant
time, with no search and with the payload and node released at once, and
no position arithmetic anywhere: C<take>, C<requeue> and C<cancel> never
use an integer index into the queue. Its whole-queue hand-off is constant
time under the lock.

It does not provide speed on any operation except against the array that
searches to cancel. It does not provide a better whole-queue hand-off: it
ties the array's reference swap under the lock, and the processing that
follows is several times slower. It does not provide low memory while
items are queued, or simpler code; the cursor and index rules are the
price. A doubly linked list could unlink an item from the item itself
and would not need the predecessor index; that was not built or measured
here, and the costs above are those of a singly linked list. The Linux
kernel's doubly linked C<list_del> takes only the entry to delete [8].

=head1 WHERE THE TECHNIQUE IS USED

Taking a whole queue in one operation is a common design. The Linux
kernel's lock-less list, C<llist>, has C<llist_del_all>, which removes
every entry and returns the first; producers can add with C<llist_add>
while consumers take everything with C<llist_del_all> without a lock. Its
entries come back newest first, not in queue order [2]. Java's
C<BlockingQueue> has C<drainTo>, which removes all available elements and
"may be more efficient than repeatedly polling", and a form with a
maximum count, the counterpart of C<take( $k )> here [3]. Perl's own
L<Thread::Queue> has C<dequeue( COUNT )>, which removes that many items
from the head, and C<extract>, which removes items at an index position
in the queue: a cancel by position, not by handle [4].

Leaving a marked entry in place of a removed one, as the array with a
hash does, is a known technique. Python's C<heapq> documentation does it
for a priority queue, because removing an entry would break the heap
invariants: the entry is marked removed and skipped when it is popped
[5]. Java's C<ScheduledThreadPoolExecutor> by default leaves a cancelled
task in its work queue until its delay elapses, notes that this "may
also cause unbounded retention of cancelled tasks", and offers
C<setRemoveOnCancelPolicy> to remove it at cancellation instead [6].

A queue that starts with a node holding no item is also the design of
Michael and Scott's two-lock queue: because of the dummy node, enqueuers
never touch the head and dequeuers never touch the tail, so each end has
its own lock [7].

=head1 A NOTE FOR LinkedList::Single

B<The stale C<whence> slot.> The Cursor class keeps the last
C<whence> argument alive until the next cursor is built.
C<< $pred->next->next >> leaves its temporary cursor on the cancelled item
there, so the payload of a cancelled item was not destroyed at cancel;
C<< $pred->next( 2 ) >> builds one cursor and does not. The Fragment class
has the same slot: items that went through C<fragment> (C<take>) are held
until the next Fragment is built, so cancelling one of them did not
destroy its payload at once. Requeued items no longer show this, since the
pointer C<append_to> holds no node afterwards. What is left is the
last list of the queue itself, which the lifetime test marks C<TODO> (the
final C<undef $queue>).

B<C<fragment> moves contents.> This is how the module works today:
handles must be re-recorded after C<fragment>. C<append_to> also moved
contents when this example was written, and now relinks (see F<CHANGES> of LinkedList::Single); the
relinking C<detach> (also in F<CHANGES>) exists as well. This example has not been
changed to use C<detach>, so C<take> still ends with C<_reindex>.

B<C<consume> is a good batch loop.> Its clean stop on C<die "\n">, leaving
the current item at the head of the Fragment, is what C<process> and
C<requeue> rely on. Other exceptions are C<carp>ed and also stop it there;
the array version lets them propagate, and the tests do not use one.

=head1 SEE ALSO

L<LinkedList::Single::Example::Handoff>,
L<LinkedList::Single::Example::Handoff::Array>,
L<LinkedList::Single::Example::Handoff::Marked>,
L<LinkedList::Single::Example::Lock>, L<LinkedList::Single>.
The numbers are the references in the text.

=over 4

=item [1] perlthrtut, "Tutorial on threads in Perl"

New threads get a private copy of all data, nothing is shared by default,
and shared aggregates hold only simple values or references to shared
variables (read 2026-11-01).
L<https://perldoc.perl.org/perlthrtut>

=item [2] Linux kernel, include/linux/llist.h

The lock-less list: when C<llist_add> and C<llist_del_all> need no lock,
and C<llist_del_all> returning entries newest first (read 2026-11-01).
L<https://github.com/torvalds/linux/blob/master/include/linux/llist.h>

=item [3] Java SE API, java.util.concurrent.BlockingQueue

C<drainTo( c )> and C<drainTo( c, maxElements )> (read 2026-11-01).
L<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/BlockingQueue.html>

=item [4] Thread::Queue, "Thread-safe queues" (version 3.14)

Perl's queue between threads: C<dequeue( COUNT )> from the head,
C<extract> and C<insert> at an index position; complex data that is not
already shared is cloned (read 2026-11-02).
L<https://perldoc.perl.org/Thread::Queue>

=item [5] Python documentation, heapq, "Priority Queue Implementation Notes"

A dictionary finds a pending task's entry; removing it would break the
heap invariants, so it is marked C<REMOVED> and skipped by C<pop_task>
(read 2026-11-02).
L<https://docs.python.org/3/library/heapq.html>

=item [6] Java SE API, java.util.concurrent.ScheduledThreadPoolExecutor

Cancelled tasks stay in the work queue until their delay elapses unless
C<setRemoveOnCancelPolicy( true )> removes them at cancellation (read 2026-11-02).
L<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/ScheduledThreadPoolExecutor.html>

=item [7] Michael and Scott, "Simple, Fast, and Practical Non-Blocking and Blocking Concurrent Queue Algorithms"

PODC 1996, pp. 267-275, doi:10.1145/248052.248106. A linked-list queue
with a dummy node at the head and separate head and tail locks; also a
non-blocking version (read 2026-11-02).
L<https://www.cs.rochester.edu/u/scott/papers/1996_PODC_queues.pdf>

=item [8] Linux kernel, include/linux/list.h

The circular doubly linked list: C<list_del( entry )> unlinks an entry
given only the entry, C<list_cut_position> cuts a list in two and
C<list_splice_init> moves a whole list and reinitialises the emptied one
(read 2026-11-02).
L<https://github.com/torvalds/linux/blob/master/include/linux/list.h>

=back
