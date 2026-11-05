package LinkedList::Single::Example::Timer::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::Timer::POD - A queue that dispatches what is due, within a window, and puts the rest back

=head1 SYNOPSIS

    perl app/70-Timer/timer-queue                       # a short demonstration
    prove -r t/70-Timer                                 # the tests
    perl benchmarks/70-Timer/compare                    # time, memory, code
    perl benchmarks/70-Timer/compare Cycle              # one scenario
    perl benchmarks/70-Timer/latency                    # the time of every call
    LATENCY_CLOCK=wall perl benchmarks/70-Timer/latency Growth

    # the comparison takes about ten minutes, the latency run about the same

=head1 THE PROBLEM

Mail is queued to go out later: a reminder at nine, a retry in five
minutes, a digest at midnight. Each message carries the time it may
start. A I<dispatcher> wakes up, takes every message whose start time
has passed, and sends them. It has a I<window>, say a minute, to do it
in; whatever it has not sent when the window closes goes back at the
front of the queue, ahead of anything queued meanwhile, and is due again
at the next round. Nothing is dropped, and the dispatcher must not hold
the queue while it works, so that new messages can be queued.

One round, whatever the data structure:

    batch = cut every message with start <= now off the front
    until the window closes or the batch is empty:
        send the next message of the batch
    put what is left of the batch back in front of the queue

Messages are kept in start order, earliest first, so "every message that
is due" is a run at the front, and finding it means finding the first
message that is not due yet. Varghese and Lauck call this an ordered
timer list (their "Scheme 2"): it keeps absolute expiry times, the
earliest at the head, and deletes from the head while the head is due;
starting a timer searches the list for its place, which is O(n) in the
worst case (time in proportion to the number of timers), but O(1)
(the same time however many there are) if the search starts from the
rear and timers always go in at the rear, as they do when every
interval is the same [1]. The list here does the same thing: it checks
the last message's start first, and only walks when that check fails.

The two questions this example set out to answer were whether putting
the unused part back on a list is "nearly zero" time, and whether the
slowest call is bounded better on a list than on an array.

=head2 The order invariant

Putting the batch back in front keeps the queue in order only if no
start time in the batch is later than the first one queued. That holds
unless a message whose start has already passed was queued while the
batch was out. Both versions check it with one comparison, the batch's
latest start against the head's, and if the order would break they put
the batch back one message at a time, each in its place, counting these
in C<merged>. Messages with the same start keep the order they arrived
in, and a batch that ends exactly at the head's start still goes back in
front.

=head1 THE ARRAY VERSION

L<LinkedList::Single::Example::Timer::Array> keeps C<[ $start, @msg ]>
in a perl array in start order and uses what perl is fast at. The cut is
a binary search (halving the range each step, so 18 steps for 200,000
messages) and one C<splice>; putting back is one C<unshift> (the
search loop is left out; it leaves in C<$lo> the number of messages
that are due):

    my @item    = splice @$queue, 0, $lo;           # the batch

    ...

    my @rest    = splice @$items, $batch->{ at };   # requeue: what is left

    unshift @$queue, @rest;

Neither end is slow. A C<splice> at the front moves the array's start
pointer instead of the messages that stay, and perl keeps room before
the start of an array, so the C<unshift> copies only the pointers of
what is put back. An out-of-order message is placed by the same binary
search and one C<splice> in the middle (a block copy of the pointers
behind it). This is a strong version, written as well as it can be, and
it is the one to compare with.

=head1 THE LINKED-LIST VERSION

L<LinkedList::Single> (version 2) is a chain of nodes, each holding its
data and a link to the next. A I<cursor> marks a node and can be asked
about the node after it (C<next>, C<next_data>) or stepped forward
(C<advance>); the I<sentinel>
is the empty node at the end of every list, which C<push> fills in place;
C<< $cursor->detach( $count ) >> cuts C<$count> nodes after the cursor
out, joins the nodes on either side, and returns the cut nodes as a
I<Fragment>, a short list of its own that owns them until it is attached
somewhere; and a Fragment can be put back after a cursor
(C<< $fragment->append_to( $cursor ) >>) or have its nodes' data handed
to a sub one at a time, each node let go as it is passed
(C<< $fragment->consume( $sub ) >>).

The queue is a list behind a permanent I<anchor> node that holds no
message, so that the first message has a node before it to be cut from:

    anchor -> m1 -> m2 -> ... -> last -> (sentinel)

    anchor  = a cursor on the anchor; batches are cut after it
    last    = a cursor on the last message; new messages go after it
    latest  = the start of the last message

A message that starts no earlier than C<latest> is pushed on the
sentinel behind C<last>, with no search. Any other is placed by walking
from the anchor.

=head2 Taking the batch

C<take> walks from the anchor while the next start is due, counting,
then cuts that many nodes off in one call (trimmed: the statistics, the
early return when nothing is due, the size update and the returned
batch, which holds the Fragment, C<latest> and the count, are left out):

    my $cursor  = $anchor->next( 0 );               # a copy of the anchor

    for(;;)
    {
        my( $start )    = $cursor->next_data;

        defined $start
        && $start <= $now
        or last;

        $latest = $start;

        $cursor->advance;
        ++$count;
    }

    my $frag    = $anchor->detach( $count );        # the batch

    $anchor->next
    or $self->_reset;                               # the queue is empty now

The batch is one object, cut off in one step, and the queue is free
again as soon as C<take> returns. This is the part the list does well.
It also costs the most: every due message's start time is read through a
cursor, and C<detach( $count )> then walks the same nodes a second time.

=head2 Dispatching within the window

C<process> is C<consume> on the Fragment. The window is closed by
C<die "\n">, which C<consume> takes as a quiet stop (any other exception
it reports with C<carp>). Left out: the default deadline, the clock plus
the window, and the count of what is left in the batch:

    $frag->consume
    (
        sub( @item )
        {
            $clock->() >= $deadline
            and die "\n";

            $handler->( @item );

            ++$done;
        }
    );

C<consume> leaves the Fragment standing on the first message it did not
dispatch, so what is left of the batch I<is> the Fragment, with no index
of where the batch stopped (the array version keeps one, C<at>). Each
dispatched message is let go as the Fragment moves past it.

=head2 Putting the rest back

The three cases of C<requeue> (left out: the count in C<merged>, the
size and C<left> updates, and the return value):

    my( $head ) = $anchor->next_data;

    if( ! defined $head )                           # the queue is empty
    {
        $self->{ last }     = $frag->tail;
        $self->{ latest }   = $batch->{ latest };

        $frag->append_to( $anchor );
    }
    elsif( $batch->{ latest } <= $head )            # in front, in order
    {
        $frag->append_to( $anchor );
    }
    else                                            # a late arrival
    {
        $frag->consume( sub( @item ) { $self->_insert( @item ) } );
    }

The usual case is one line, and nothing in the queue behind the anchor
is touched. What the code does not show is that C<append_to> walks the
whole Fragment to find its last node, so it is not constant: it grows
with the size of the part put back. The other price is C<last> and
C<latest>, which the array does not need. They have to be put right at
three places: when a C<take> empties the queue, when a batch is put back
into an empty queue (as above), and on every push. The stored cursors
are only stepped off, never moved, and only C<detach>, C<append_to>,
C<push>, C<append> and C<drop> are used next to them, because those
leave every other node where it is.

=head1 CHECKING THAT IT IS RIGHT

=over 4

=item F<t/70-Timer/20-vs-array.t>

Drives both queues with one random schedule of 2,500 steps: enqueue (in
order, out of order, with ties), take, process with windows that close
part way, requeue, and late arrivals while a batch is out. What each call
returns, what is dispatched and the whole queue must agree after every
step, and the run must have cut a batch short, requeued, and merged.

=item F<t/70-Timer/40-invariants.t>

After each of 1,500 random operations, checks the anchor, the order, the
size, that C<last> stands on the last node and C<latest> is its start;
and the case the random run seldom reaches: the whole queue taken, cut
short and put back, after which C<last> must be at the end of what was
put back.

=item F<t/70-Timer/50-window.t> and F<t/70-Timer/30-lifetime.t>

The cases by name, for both queues (an empty queue, a window that closes,
a tie at the head, a merge, a handler that dies); and that a dispatched
message is released as the batch moves past it, a requeue releases
nothing, and dropping the queue releases what it held.

=back

The tests were checked by breaking the module: without the merge, the
tie rule, the reset when a take empties the queue, C<last> after a
requeue into an empty queue, or the C<E<lt>=> in the order test, a test
fails each time. The last two were not caught by the first version of
the tests and have tests of their own now.

=head1 WHAT IT COSTS

All figures are from one machine (Linux, perl 5.40), with the module as
it is, from F<benchmarks/70-Timer/compare> and F<benchmarks/70-Timer/latency>.

=head2 Enqueue

    microseconds per message           in start order                out of order
                                  1,000   20,000   200,000      500    2,000    8,000
    list                          11.20    11.02     11.27    220.56   889.08  3616.28
    array                          1.24     1.29      1.36      2.60     3.38     4.90

In start order both are flat and the array is 8 to 9 times faster; the
list's cost is the cursor work of C<push>, as in
L<LinkedList::Single::Example::Handoff>. Out of order the list walks,
about 0.9 microseconds per message passed, and loses by about 700 times
at 8,000 queued. Messages that arrive in no particular order need the
index of L<LinkedList::Single::Example::Ordered>, or the array.

=head2 The cycle: take, then put everything back

Microseconds, best of 3; C<due> is the batch and so the part put back.

                    queued behind: 200,000          queued behind: 10,000
    case     due      take  requeue     total      take  requeue     total
    list      10      87.0     21.0     108.0      69.1     13.8      83.0
    array     10      34.8     10.0      44.8       6.0      1.9       7.9
    list   1,000   2,515.8    141.9   2,657.7   2,008.9     92.0   2,100.9
    array  1,000      57.9     37.0      94.9      11.9     25.0      37.0
    list  10,000  23,037.9  1,269.1  24,307.0  18,176.1    654.0  18,830.1
    array 10,000     161.2    278.0     439.2     102.0    248.0     350.0

The size of the batch matters to both; the length of the queue behind it
shows only in the array's binary search. The array takes 2 to 180 times
faster, and puts back 2 to 7 times faster. The list's scan reads about 2
microseconds a due message and is 95% of its cycle; the re-attach is
about 5% (1.3 of 24.3 milliseconds at 10,000).

Putting back only the unused part: 10,000 due, 200,000 queued behind,
the handler stopped after some (microseconds for C<requeue>):

    unused part         0        10     1,000    10,000
    list              3.8      22.2     145.9   1,146.1
    array             3.8       9.1      36.0     287.1

So the answer to the first question: putting back is cheap and does not
depend on the queue's length, but it is not zero and not constant. It
is about 0.115 microseconds per message put back on the list, the walk
of the Fragment in C<append_to> (C<attach_nodes>, which calls
C<tail_node>), against 0.029 for the array's C<unshift>.

=head2 Re-attaching in constant time (a proposal, not in the module)

The dispatcher already has a cursor on the last message of the batch: it
walked there to find the cut. A scratch copy of the library was given
C<append_to( $thence, $known_tail )> and C<detach_through( $stop )>
(a known-tail argument and C<detach_through>: proposed for LinkedList::Single, not made, and so not in its F<CHANGES> file). For a queue of 200,000 and a
batch of k, in microseconds:

    k          today: detach(k)  append_to   proposed: detach_through  append_to(tail)
    10                     21.0        8.0                       12.8              5.4
    1,000                 114.2       63.8                       12.2              5.0
    100,000             7,846.6    7,348.7                       56.0             16.8

With the change both are flat in k: about 17 microseconds to put back
100,000 messages (what is left is making the Fragment and cursor
objects), where the array's C<unshift> would take about 2,900 (0.029
each, extrapolated). That is the one operation where the list would win
on time. It is a proposal: the module is unmodified, and the example
does not use it. It would not touch the scan for due messages, which is
the larger cost. Removing that too would need marker nodes per second or
minute and an index over them, a form of the timing wheels of [1] built
from linked buckets (as Kafka's are [3]); it has not been built or measured.

=head2 Bounded time

The second question is about the I<slowest> call, which an average
hides, so F<benchmarks/70-Timer/latency> times every call, in a fresh
process for each case, three runs each. The row shown is the run with
the median worst call; the range of the worst calls follows it.

The clock matters. On wall time an empty loop's slowest call was 376
microseconds in one run: the scheduler took the processor. The default
clock is the thread's CPU time (C<CLOCK_THREAD_CPUTIME_ID> [4]), which still
counts a page fault or a reallocation but not being descheduled; its
empty loop has a median of 0.5 microseconds and a slowest call of 17 to
275. Take the 99.9th percentile (the time 999 calls in 1,000 stay under)
as the dependable bound, and the maximum as an upper limit with that
noise in it. Microseconds per call, CPU time:

    case               mean      p50      p99    p99.9     max      worst of 3 runs
    Growth: enqueue 200,000 messages in start order
    list              12.34    11.60    25.97    39.08   355.0     221 .. 423
    array              1.87     1.65     6.25    10.52   606.6     556 .. 652
    Steady, 200,000 queued: enqueue one in order (50,000 calls)
    list              12.29    11.68    20.76    28.19   269.3     207 .. 285
    array              1.83     1.69     3.90     8.69   163.1     135 .. 205
    Steady, 200,000 queued: dispatch one (take + process, 50,000 calls)
    list              37.20    35.97    78.70    98.36   264.2     221 .. 550
    array              7.16     6.92    14.50    18.07    66.0      66 ..  79
    Window cycle, 5,000 due, none dispatched, 200,000 behind (100 cycles)
    list take       8,987.5  8,974.0  9,347.5    9,347    9,689    9,411 .. 15,189
    array take         44.0     43.1     61.4       61      265      245 ..    271
    list requeue      301.7    296.4    392.5      392      637      343 ..    739
    array requeue     124.4    124.1    138.9      139      212      210 ..    217
    Free: letting go of a queue of 200,000 messages (one call)
    list           18,478   (18,354 .. 18,978)
    array          15,018   (14,641 .. 15,661)

=over 4

=item * The array's growth spike is real and small: a reallocation (call
182,783 of 200,000 here), 556 to 652 microseconds in the table, 213 to
367 when the same enqueues run alone, 408 to 500 at 1,000,000 messages
and 572 to 642 at 2,000,000. The list has none; its slowest growth call
(221 to 423) is the machine's noise. Its median is 7 times higher.

=item * In steady state, where each call does a fixed amount of work,
the array's slowest calls are lower: 135 to 205 microseconds for
enqueue and 66 to 79 for dispatch, against 207 to 285 and 221 to 550
on the list. The median is 7 times slower on the list for enqueue and 5
times for dispatch.

=item * C<take> and C<requeue> do work for every message in the batch,
so their time is set by how many are due: 207 microseconds for 100 due
on the list and 8,988 for 5,000, against 6 and 44 on the array (the
100-due figures are from a run not in the table). A bound has to come
from limiting the batch: K messages cost about 2K microseconds to take on
the list and 0.01K on the array, so for the same bound the array's limit
can be about 200 times larger.

=item * Freeing 200,000 messages is a pause on both (18 and 15
milliseconds); a queue that must not pause has to be let go in limited
batches, which both allow.

=back

So the answer to the second question is no, for this workload and these
sizes. The list's time per call is as bounded as the array's, and the
array's is lower.

=head2 Memory

Resident memory per message with 200,000 queued (a fresh process, a
short string as the payload): the list 268 bytes, the array 227, about
18% more. A hash is not a sensible third here: it keeps no order, so it
cannot answer "everything due" without sorting its keys or keeping
buckets as a timer wheel does, and no hash version was built.

After a burst of 200,000 has been dispatched and 10 messages are left,
the container (measured shallowly with C<Devel::Size>: the array itself,
and the list node by node) holds 1,152 bytes on the list, which is 10
messages and the anchor, and 1,754,784 on the array, which keeps the
capacity it grew to. The list gives a node back as the batch moves past
it.

=head2 Code

Deparsed statements, branches and index operations
(C<benchmarks/70-Timer/compare Complexity>):

    method                  stmts  branch  index
    Timer::take                24      10      2
    Timer::Array::take         17       8      6
    Timer::requeue             24       8      2
    Timer::Array::requeue      19       9      4
    Timer::_insert             23       6      4
    Timer::Array::_insert      18       6      7

The list is a little longer. The array has about three times the index
arithmetic (the binary search, the C<at> of the batch); the list has
cursors instead, and the bookkeeping of C<last> and C<latest>.

=head1 READABILITY AND CHANGE

Readable here means that someone with ordinary Perl can match each step
of the code to a line of the round described under L</THE PROBLEM>
without working out positions in their head. Easy to change means that a
new rule touches one sub and nothing that has to be kept in step with
it. In this example the list wins on one step, the dispatch, and the
array is the simpler of the two everywhere else.

=head2 Dispatching: the list reads as the problem

The list's C<process> loop is shown under L</Dispatching within the
window>: C<consume> hands over each message and C<die "\n"> closes the
window. The array's loop (comments left out) has to say what C<consume>
does for the list: keep a position, stop on an exception, report it:

    while( $batch->{ at } < @$items )
    {
        $clock->() >= $deadline
        and last;

        try
        {
            $handler->( $items->[ $batch->{ at } ]->@* );
        }
        catch( $err )
        {
            $err eq "\n"
            or carp "Failed consume: $err\n";

            last
        }

        ++$batch->{ at };
        ++$done;
    }

=head2 Where the batch stopped: a position, or what is left

On the list, what is left of the batch is the Fragment. On the array it
is "the items from C<at> on": the dispatched messages stay in C<items>
below C<at> until the batch is dropped, and only C<at> tells the two
apart. It is set in C<take> and used four times in C<Timer::Array>: the
loop test, the handler call and the increment in C<process> (lines 104,
114, 124), and C<splice @$items, $batch-E<gt>{ at }> in C<requeue>
(line 150). Any new code that reads a batch has to honour it too.

The increment must also come after the C<try>/C<catch>. One line
earlier, a handler that dies would be counted as done and C<requeue>
would leave its message out: the C<carp> still appears, but the message
is gone from the queue. F<t/70-Timer/50-window.t> (lines 186-215) checks
this for both classes. The C<"\n"> test and the C<carp> are a hand copy
of what C<consume> does.

The list has none of this in the example. C<consume> holds the C<try>,
the C<"\n"> test and the advance after a handler that returned
(F<lib/LinkedList/Single/v2.pm>, lines 1347-1366), and a message, once
dispatched, is no longer in the Fragment, so there is nothing to mark.

=head2 What the list has to keep in step instead

The list has a smaller surface at this one place, not overall. C<left>
is a count kept by hand on both sides (list lines 195 and 254, array
lines 128 and 163); the array could work it out as C<@$items - at>, but
the list would have to walk the Fragment to count it. C<consume> croaks
on an empty Fragment (F<v2.pm> lines 1344-1345), so C<process> needs a
guard the array does not (C<$frag or return 0>, lines 179-180). And the
list's marker is its stored cursor C<last>. When a C<take> empties the
queue, C<last> stands on a node that is now in the batch, and C<_reset>
(lines 145-146) must move it back to the anchor. Without the reset, the
next message in order would be pushed after that node, into the batch
and not the queue. Nothing would report it; the tests catch it (see
L</CHECKING THAT IT IS RIGHT>). The places C<last> must be put right are
listed under L</Putting the rest back>. Not checked: whether the
C<whence> slot of a cursor or Fragment here keeps a dispatched message
alive for longer; F<t/70-Timer/30-lifetime.t> finds each one released
as the batch moves past it.

=head2 Putting back: the array has fewer cases

The list's C<requeue> (shown under L</Putting the rest back>) has three
cases, because an empty queue must also set C<last> and C<latest>. The
array folds the empty queue into the order test (left out: the guards,
the C<left> updates and the return value):

    my @rest    = splice @$items, $batch->{ at };

    if( ! @$queue || $batch->{ latest } <= $queue->[ 0 ][ 0 ] )
    {
        unshift @$queue, @rest;
    }
    else
    {
        $self->_insert( $_->@* ) for @rest;

        $self->{ merged }   += $left;
    }

C<append_to( $anchor )> and C<unshift> say the same thing equally
plainly; the difference is the extra case the list needs for its cursors.

=head2 Queueing in order: the array has nothing to keep

The fast path of C<_insert>, list first, then array:

    if( $start >= $self->{ latest } )
    {
        my $last    = $self->{ last };

        $last->next->push( $start, @msg );

        $self->{ last }     = $last->next;
        $self->{ latest }   = $start;

        return $self
    }

    if( ! @$queue || $start >= $queue->[ -1 ][ 0 ] )
    {
        push @$queue, [ $start, @msg ];

        return $self
    }

The array asks itself for its last start (C<$queue-E<gt>[ -1 ][ 0 ]>);
the list has to remember it, and every place that changes the end of the
queue has to update the two copies.

=head2 Changing it

=over 4

=item * B<Cap the batch at K messages> (the bound recommended under
L</Bounded time>). The list adds C<$count E<lt> $max> to the walk's test
in C<take>; the array lowers C<$lo> to C<$max> after the search. One line
in one sub each.

=item * B<Cancel a queued message.> The array finds it and C<splice>s it
out; C<size> and the last start follow by themselves. The list must walk
to the node before it, and if it was the last message, move C<last> and
C<latest> back (or call C<_reset>), and lower C<size>. Such fix-ups are
easy to miss: the first version of the tests did not catch a missing
C<last> after a requeue into an empty queue (see
L</CHECKING THAT IT IS RIGHT>).

=back

=head2 Where the list is not simpler

C<last>, C<latest> and C<size> are state the array does not have: the
first two are set in C<_insert>, C<_reset> (called from C<take>) and
C<requeue>, the count in C<enqueue>, C<take> and C<requeue>, where the
array asks C<@$queue>. They are the reason for the third case in
C<requeue>. The
list's C<take> also needs the anchor node, a copy of its cursor
(C<next( 0 )>) to walk with, and a check after the cut that the queue is
not empty. The array's binary search is more index arithmetic than the
list's walk, but it is a textbook loop, written twice, and it is the
reason the array's C<take> is fast.

=head2 Line counts

Lines of each sub in this repository's code, first with blank lines and
comments, then without (not the best possible code for either):

    sub          list     array
    take        47 / 30   36 / 27
    process     32 / 23   40 / 28
    requeue     46 / 28   27 / 21
    _insert     38 / 25   31 / 24
    new         32 / 19   12 / 12
    _reset       7 /  6    - /  -

Only C<process> is shorter on the list.

=head1 WHAT TO TAKE FROM IT

The list provides a batch that is one object, cut off in one step and
owned by the dispatcher, with nothing held on the queue while it is
worked on; a natural end to the window (C<consume> stops where it was,
and what is left is the Fragment); messages released as they are
dispatched; memory that follows what is queued; and a put-back that does
not depend on the length of the queue.

It does not provide speed: the array is faster at every operation
measured, by the factors in the tables above. It does not provide a
put-back in constant time today (that needs the proposed known-tail argument and C<detach_through>),
a lower worst case (its slowest calls
are as high or higher in every steady-state case), cheap insertion in
the middle, or a cost independent of the number of messages due. If the
goal is a bounded time per round, limit the messages taken per round and
measure with a clock that excludes the scheduler; on these numbers the
array allows a far larger limit.

=head1 WHERE THE TECHNIQUE IS USED

The ordered timer list is the classic design: Varghese and Lauck write
that algorithms like it were used by VMS and UNIX for their timer
modules [1]. Linux began with one: in Ingo Molnar's account the early
kernel kept all timers in a doubly linked list sorted at insertion, so
adding a timer was O(n); since 1997 it has used a timer wheel of
buckets, in which adding and removing a timer is O(1) [2]. The cost the
list shows here, a search to insert out of order and a walk over what is
due, is the cost those designs were built to avoid. The wheel has costs
of its own: LWN reported in 2015 that moving timers down its levels (the
cascade) can be expensive and takes a time that is, to a first
approximation, unpredictable, and described a rework that drops the
cascade and runs far-off timeouts with lower accuracy [5].

The array version has a Perl precedent: POE keeps its events and alarms
in POE::Queue::Array, a perl array ordered by due time, which appends
when the new item is due no earlier than the last, and otherwise places
it by a binary search and C<splice> [6]. Two other common designs are
the binary heap, whose pop is logarithmic in the number queued and which
is not stable, so equal times need an entry count to keep their arrival
order [7]; and the hierarchical timing wheel, which Kafka adopted in
place of Java's C<DelayQueue> (O(log n) to insert or delete, by its
account), with buckets that are doubly linked lists of its own [3].

=head1 A NOTE FOR LinkedList::Single

=over 4

=item * C<attach_nodes> (and so C<append_to>) walks the whole Fragment to
find its tail, though the caller often holds a cursor there already. An
optional known-tail argument to C<append_to>, and C<detach_through>, are
proposed for LinkedList::Single with the measurements above; neither is in its F<CHANGES> file.

=item * C<detach( $count )> empties the first node it removes, so a
cursor held on that node is not usable afterwards. With a batch of one,
a cursor kept on its "last" node is on that node.

=item * C<consume> advances the Fragment itself and leaves it standing
on the message that failed or was not tried, which is what makes
C<requeue> possible with no bookkeeping of where the batch stopped.

=back

=head1 SEE ALSO

L<LinkedList::Single::Example::Timer>,
L<LinkedList::Single::Example::Timer::Array>, L<LinkedList::Single>.
The numbers are the references in the text.

=over 4

=item [1] Varghese and Lauck, "Hashed and Hierarchical Timing Wheels: Data Structures for the Efficient Implementation of a Timer Facility"

ACM, 1987, pp. 25-38 (the 11th Symposium on Operating Systems
Principles, by a library catalogue record). The ordered timer list
(Scheme 2) and the timing wheels that replace it. A copy on a course
page, not the publisher's:
L<http://www.cs.columbia.edu/~nahum/w6998/papers/sosp87-timing-wheels.pdf>

=item [2] Ingo Molnar, "kernel/timer.c design", on LWN.net

A message to the Linux kernel list (2005-10-19) on the history and costs
of the kernel's timer list and timer wheel (read 2026-11-01).
L<https://lwn.net/Articles/156329/>

=item [3] Yasuhiro Matsuda, "Apache Kafka, Purgatory, and Hierarchical Timing Wheels"

Confluent blog, 2015-10-28: why Kafka replaced its DelayQueue timer
(O(log n) insert and delete) with hierarchical timing wheels (insert
O(m) for m wheels, delete O(1)), using its own doubly linked buckets.
L<https://www.confluent.io/blog/apache-kafka-purgatory-hierarchical-timing-wheels/>

=item [4] clock_gettime(2), Linux man-pages

The clock ids, among them C<CLOCK_THREAD_CPUTIME_ID>, which measures the
CPU time consumed by the calling thread, and C<CLOCK_MONOTONIC>.
L<https://man7.org/linux/man-pages/man2/clock_gettime.2.html>

=item [5] Jonathan Corbet, "Reinventing the timer wheel", on LWN.net

2015-06-03: the costs of the Linux timer wheel (the cascade, finding the
next expiry) and a then-experimental rework that trades accuracy of
far-off timeouts for no cascade (read 2026-11-02).
L<https://lwn.net/Articles/646950/>

=item [6] POE::Queue::Array, in POE 1.370

The source of POE's array-based priority queue: append at the end,
insert at the head, otherwise a binary seek and C<splice>.
POE::Resource::Events, in the same release, enqueues events and alarms
in it by due time.
L<https://metacpan.org/release/BINGOS/POE-1.370/source/lib/POE/Queue/Array.pm>

=item [7] heapq, the Python standard library

A binary heap as a priority queue, with notes on its use: heap sorting is
not stable, an entry count breaks ties in arrival order, and a task is
cancelled by marking it removed.
L<https://docs.python.org/3/library/heapq.html>

=back
