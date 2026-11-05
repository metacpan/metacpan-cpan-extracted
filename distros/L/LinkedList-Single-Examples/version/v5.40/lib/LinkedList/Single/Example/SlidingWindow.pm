########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::SlidingWindow v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single qw( v2 );

########################################################################
# methods
########################################################################

sub new( $class, %arg )
{
    my $span = $arg{ span }
    // croak 'Botched new: missing span';

    my $list    = LinkedList::Single->new;

    my $self
    = bless
    {
        span    => $span
      , list    => $list

        # the tail is a cursor parked on the sentinel at the end of
        # the list, so recording an event never walks the list.

      , tail    => $list->cursor
    }
    => $class;

    $self
}

########################################################################
# add an event at the tail
########################################################################

sub record( $self, $time, @payload )
{
    # push at the sentinel fills it and hangs a new sentinel
    # off the end; advance moves the cursor onto the new one.
    #
    # Note: $list->push would walk the whole list to find the tail
    # on every call, which makes building a long window quadratic.

    $self->{ tail }->push( $time, @payload )->advance;

    $self
}

########################################################################
# discard events older than the span
#
# the expired events are always a prefix of the list. they are
# cut off whole with two fragments rather than shifted one by one,
# and then consumed: each node is released, and each payload
# destroyed, as the fragment advances past it.
########################################################################

sub expire( $self, $now, $handler = sub {} )
{
    my $list    = $self->{ list };
    my $cutoff  = $now - $self->{ span };

    # the usual case in a busy window is that nothing has expired.

    $list
    and ( $list->data )[ 0 ] < $cutoff
    or return 0;

    # take every node: the list is left empty.

    my $dead    = $list->fragment;

    # the first node still inside the window, if there is one.

    my $live    = $dead->first( sub( $time, @ ) { $time >= $cutoff } );

    if( $live )
    {
        # cutting at the boundary leaves $dead ending there and
        # returns the live nodes as a fragment, which goes
        # straight back onto the (empty) list.
        #
        # the sentinel at the end of the chain never moves, so
        # the tail cursor is still parked on it.

        $live->fragment->push_onto( $list );
    }
    else
    {
        # everything expired: the old sentinel went off with $dead
        # so the tail needs a new place to stand.

        $self->{ tail } = $list->cursor;
    }

    my $count   = 0;

    $dead->consume
    (
        sub( @event )
        {
            ++$count;

            $handler->( @event );
        }
    );

    $count
}

########################################################################
# introspection
########################################################################

# arrayref of [ $time, @payload ], oldest first.

sub contents( $self )
{
    ( scalar $self->{ list }->extract ) // []
}

sub size( $self )
{
    $self->{ list }->count
}

1
__END__

=head1 NAME

LinkedList::Single::Example::SlidingWindow - events in a time window held in a linked list

=head1 SYNOPSIS

    use LinkedList::Single::Example::SlidingWindow;

    my $window = LinkedList::Single::Example::SlidingWindow->new( span => 60 );

    $window->record( $now, $request );

    # returns the number of events dropped; the handler sees each
    # one as it goes.

    my $dropped = $window->expire( $now, sub( $time, @payload ) { ... } );

=head1 DESCRIPTION

A window holds the events of the last C<span> time units, oldest first.
C<record> adds an event (a time and any payload) at the end. C<expire>
drops every event older than C<$now - span>, passes each one to the
handler, oldest first, and returns how many went. C<size> and
C<contents> (an arrayref of C<[ $time, @payload ]>, oldest first) look at
the window without changing it. Times must be recorded in order.

The events are kept in a L<LinkedList::Single>. A cursor parked at the end
of the list makes C<record> a constant-time step that never walks the
list. C<expire> cuts the expired events off the front as one Fragment
(a piece of list that nothing else can reach), puts the live events back,
and consumes the Fragment, so each expired node and its payload are freed
as the handler finishes with it.

L<LinkedList::Single::Example::SlidingWindow::Array> keeps the same
window in a perl array with C<splice>, behind the same interface. It is
the test oracle: the tests drive both with the same random events and
compare the contents, the counts and the handler calls after every step.
F<app/30-SlidingWindow/sliding-window> uses the window as a login
throttle.

=head2 How it is benchmarked

F<benchmarks/30-SlidingWindow/compare> records 100,000 events into a
window of 1,000, expiring after every event and after every 100 events,
and reports the best of three runs in seconds. It then records a burst
of 200,000 events, expires all but 10, and reports the bytes each
container still holds, along with statements, branches and index
operations counted in each C<expire>.

=head2 Why it matters

A rate limiter or a login throttle runs on every request, and its window
grows and shrinks with the traffic. Here the array is more than ten
times faster in steady state, and the list gives the memory of a burst
back as it expires (1,056 bytes left against 1,754,784) and destroys each
expired payload at once. So the list is a choice for bursty windows, or
when expired events hold something that must be released promptly, and
not for speed. The measurements, the background and the references are in
L<LinkedList::Single::Example::SlidingWindow::POD>.

This is an example, not a rate limiter for production use: it has no
locking, no persistence and no per-key windows.

=head1 SEE ALSO

L<LinkedList::Single::Example::SlidingWindow::POD>,
L<LinkedList::Single::Example::SlidingWindow::Array>, L<LinkedList::Single>
