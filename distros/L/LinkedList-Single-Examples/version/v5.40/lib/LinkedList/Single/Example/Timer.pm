########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Timer v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single qw( v2 );

########################################################################
# a queue of messages, each with the time it may start, in start order,
# held in a linked list that begins with a permanent anchor node:
#
#   anchor -> m1 -> m2 -> ... -> last -> sentinel
#
# every message is a node [ $start, @msg ]; the anchor holds -inf.
#
# two cursors are kept beside the list:
#
#   anchor  the first node, never removed. it gives the first message a
#           predecessor, which is what detach and append_to need.
#   last    the last node (the anchor when the queue is empty). the
#           sentinel after it is where the next message is pushed, so a
#           message that starts no earlier than the last one never walks.
#
# the dispatcher works in rounds:
#
#   take( $now )         cut every message with start <= $now off the
#                        front, as one Fragment: the batch.
#   process( $batch )    hand the batch's messages to a handler, in
#                        order, until the window closes or the batch is
#                        empty. the handler is called without any hold
#                        on the queue: the batch belongs to the caller.
#   requeue( $batch )    whatever the window cut off goes back in front
#                        of the queue.
#
# the batch is a Fragment, so putting its unused part back in front of
# the queue is a relink of that part and of nothing else. the length of
# the queue behind it does not enter into the cost. the length of the
# part being put back does: attach_nodes walks the Fragment to find its
# tail (the POD has the numbers, and the module change that would make
# that O(1)).
#
# a batch is in start order and every message in it starts no later than
# the cut, which is no later than anything left in the queue. putting it
# back in front keeps the queue in order unless a message with a start
# time in the past was enqueued while the batch was away. requeue checks
# for that (the batch's latest start against the head's), and merges the
# batch item by item when the order would break.
#
# the stored cursors are only stepped off of, never advanced, and are
# only used with operations that leave every node where it is: detach,
# append_to, push, append and drop.
########################################################################

my $before_all  = -9**9**9;

sub new( $class, %arg )
{
    my $list    = LinkedList::Single->new;

    # an empty list: push fills the sentinel in place.

    $list->push( $before_all );

    my $anchor  = $list->cursor;

    bless
    {
        clock   => $arg{ clock  } // sub { time }
      , window  => $arg{ window } // 60
      , list    => $list
      , anchor  => $anchor
      , last    => $anchor
      , latest  => $before_all
      , size    => 0

        # statistics.
        #
        # walked  nodes this module's code stepped over to find a place
        #         for an out-of-order message, or for the cut
        # merged  messages put back one at a time because of a late
        #         arrival

      , walked  => 0
      , merged  => 0
    }
    => $class
}

########################################################################
# public interface
########################################################################

# queue one message that may start at $start.

sub enqueue( $self, $start, @msg )
{
    $self->_insert( $start, @msg );

    ++$self->{ size };

    $self
}

# cut the messages that are due off the front of the queue. returns a
# batch, or undef if nothing is due.

sub take( $self, $now = $self->{ clock }->() )
{
    my $anchor  = $self->{ anchor };
    my $cursor  = $anchor->next( 0 );
    my $count   = 0;
    my $latest;

    # the walk is the only look at the start times, and it stops at the
    # first message that is not due.

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

    $self->{ walked }   += $count;

    $count
    or return undef;

    my $frag    = $anchor->detach( $count );

    # nothing left behind the cut: the queue is empty again. ($cursor
    # now stands on the last node of the batch, whose next is the
    # batch's own sentinel, so it is the anchor that is asked.)

    $anchor->next
    or $self->_reset;

    $self->{ size } -= $count;

    return
    {
        frag    => $frag
      , latest  => $latest
      , left    => $count
    };
}

# hand the batch to $handler, one message at a time, until the clock
# reaches $deadline (the default is a window from now), or the batch is
# used up. the handler gets ( $start, @msg ). returns the number
# dispatched.
#
# consume ends quietly on die "\n" and leaves the batch standing on the
# message it did not dispatch. any other exception is carped and also
# stops the batch there.

sub process( $self, $batch, $handler, $deadline = undef )
{
    $batch
    or return 0;

    my $clock   = $self->{ clock };

    $deadline //= $clock->() + $self->{ window };

    my $frag    = $batch->{ frag };
    my $done    = 0;

    $frag
    or return 0;

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

    $batch->{ left }    -= $done;

    $done
}

# messages left in a batch.

sub left( $self, $batch )
{
    $batch
    ? $batch->{ left }
    : 0
}

# put the unused part of a batch back in front of the queue. returns the
# number of messages put back.

sub requeue( $self, $batch )
{
    $batch
    or return 0;

    my $left    = $batch->{ left }
    or return 0;

    my $frag    = $batch->{ frag };
    my $anchor  = $self->{ anchor };

    # the first message of what is queued now.

    my( $head ) = $anchor->next_data;

    if( ! defined $head )
    {
        # the queue is empty: the batch is all of it. the cursor on its
        # last node is made first, while it is still a Fragment.

        $self->{ last }     = $frag->tail;
        $self->{ latest }   = $batch->{ latest };

        $frag->append_to( $anchor );
    }
    elsif( $batch->{ latest } <= $head )
    {
        # the cheap case: in front, and in order.

        $frag->append_to( $anchor );
    }
    else
    {
        # a message that is due came in while the batch was out. the
        # batch goes back one message at a time, each in its place.

        $frag->consume( sub( @item ) { $self->_insert( @item ) } );

        $self->{ merged }   += $left;
    }

    $self->{ size }     += $left;
    $batch->{ left }     = 0;

    $left
}

########################################################################
# utility
########################################################################

# the queue is empty: both cursors are as they were when it was new.

sub _reset( $self )
{
    $self->{ last }     = $self->{ anchor };
    $self->{ latest }   = $before_all;

    $self
}

# put a message in its place. one that starts no earlier than the last
# is pushed on the end. any other is found by walking from the anchor to
# the last message that does not start after it, which leaves a cursor
# on the node it goes after.

sub _insert( $self, $start, @msg )
{
    if( $start >= $self->{ latest } )
    {
        my $last    = $self->{ last };

        $last->next->push( $start, @msg );

        $self->{ last }     = $last->next;
        $self->{ latest }   = $start;

        return $self
    }

    my $pred    = $self->{ anchor }->next( 0 );
    my $walked  = 0;

    for(;;)
    {
        my( $next ) = $pred->next_data;

        defined $next
        && $next <= $start
        or last;

        $pred->advance;
        ++$walked;
    }

    $self->{ walked }   += $walked;

    # the start is below the last one's, so something follows $pred and
    # this does not touch the sentinel.

    $pred->append( $start, @msg );

    $self
}

########################################################################
# introspection
########################################################################

# arrayref of [ $start, @msg ], earliest first.

sub contents( $self )
{
    my @item
    = ( ( scalar $self->{ list }->extract ) // [] )->@*;

    # the anchor is not a message.

    shift @item;

    \@item
}

# the start time of the first message, or undef.

sub next_start( $self )
{
    ( $self->{ anchor }->next_data )[ 0 ]
}

sub size( $self )
{
    $self->{ size }
}

sub window( $self )
{
    $self->{ window }
}

sub walked( $self )
{
    $self->{ walked }
}

sub merged( $self )
{
    $self->{ merged }
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Timer - a queue of messages that dispatches those whose start time has passed, held in a linked list

=head1 SYNOPSIS

    use LinkedList::Single::Example::Timer;

    my $queue   = LinkedList::Single::Example::Timer->new( window => 60 );

    $queue->enqueue( $start, 'send', $mail );

    my $batch   = $queue->take;            # everything due now, or undef

    # nothing is held while the batch is worked on

    my $sent    = $queue->process( $batch, sub( $start, @job ) { ... } );

    $queue->requeue( $batch );             # what the window cut off

=head1 DESCRIPTION

A queue of messages, each with the time it may start, kept in start
order. C<enqueue( $start, @msg )> adds one. A dispatcher works in rounds:
C<take( $now )> cuts every message whose start has passed off the front
of the queue as one I<batch>; C<process( $batch, $handler, $deadline )>
hands the batch's messages to the handler in order until the clock
reaches the deadline (by default C<window> seconds, 60, from the call) or
the batch is used up; and C<requeue( $batch )> puts what is left back in
front of the queue, ahead of anything queued meanwhile. Nothing is
dropped. The queue is not held while the batch is worked on. C<size>,
C<left>, C<next_start>, C<contents> (earliest first), C<walked> and
C<merged> look at it without changing it. The clock is passed to C<new>,
so the tests and the demonstration never sleep.

The queue is a L<LinkedList::Single> behind a permanent anchor node, with
a cursor kept on the last message. A message that starts no earlier than
the last one is pushed on the end without a search; any other is placed
by walking from the front. The batch is a Fragment of the list, so taking
it and putting its unused part back are relinks, not copies. If a message
whose start has already passed arrived while the batch was out, the batch
is put back one message at a time, each in its place, and counted in
C<merged>.

L<LinkedList::Single::Example::Timer::Array> has the same interface over
a perl array, written as well as it can be: a binary search for the cut
and for out-of-order messages, C<splice> to take and C<unshift> to put
back. It is the test oracle: the tests drive both with the same random
schedule and compare everything they report.

=head2 How it is benchmarked

F<benchmarks/70-Timer/compare> measures the memory of 200,000 queued
messages and of a queue drained to 10 after a burst; enqueue in start
order (1,000 to 200,000 messages) and out of order (500 to 8,000); the
dispatch cycle (C<take>, C<requeue>) for 10 to 10,000 due messages in
front of 10,000 and 200,000 others; C<requeue> of the unused part of a
batch; and statements and branches in each implementation's code.
F<benchmarks/70-Timer/latency> times every call on its own, in a fresh
process three times per case, on the thread's CPU-time clock, and reports
the median, the 99th and 99.9th percentiles and the slowest call.

=head2 Why it matters

A dispatcher that works within a window has to put back what it did not
reach, and the hope was that a list makes putting it back "nearly zero"
time and the slowest call lower than an array's. Neither holds today.
Putting the part back does not depend on the length of the queue, but it
does grow with the size of the part, because the module walks the
Fragment to find its tail; the array's C<unshift> is cheaper still. The
array is faster at every operation measured, its slowest calls are lower
in steady state, and its one spike (a reallocation as it grows) stays
under a millisecond up to two million messages. A change to the module that makes the
re-attach constant was prototyped and measured, and is only a proposal
(a known-tail argument to C<append_to> and a C<detach_through>); this example runs on the module as it is. The list's own
advantages are that the batch is one object owned by the dispatcher and
that its memory follows what is queued. The measurements, the background
and the references are in L<LinkedList::Single::Example::Timer::POD>.

This is an example, not a scheduler for production use: it has no
persistence, no retry limit and no thread safety.

=head1 SEE ALSO

L<LinkedList::Single::Example::Timer::POD>,
L<LinkedList::Single::Example::Timer::Array>, L<LinkedList::Single>
