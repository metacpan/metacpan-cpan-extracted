########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Handoff::Marked v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single::Example::Lock;

########################################################################
# the array version that an experienced perl programmer writes when
# cancel has to be fast: the same array of [ $id, @data ], plus a hash
# id => item so that a handle finds its item without a search.
#
# an array cannot remove an item from the middle cheaply, so cancel
# does not: it empties the item in place, leaving a husk [ undef ]
# that stays in the array until a take or a process passes over it.
# the payload is let go at cancel; the husk is not.
#
# so cancel is O(1) here as well, and what the list is left with is
# the cost of the husks: memory kept until they are dequeued, and take
# having to step over them.
########################################################################

sub new( $class, %arg )
{
    my $lock    = $arg{ lock } // LinkedList::Single::Example::Lock->new;

    bless
    {
        lock    => $lock
      , queue   => []
      , item    => {}
      , live    => 0
      , serial  => 0
      , touched => 0
      , purged  => 0
    }
    => $class
}

########################################################################
# public interface: take the lock and do the work.
########################################################################

sub enqueue( $self, @data )
{
    $self->{ lock }->hold( \&_enqueue, $self, @data )
}

# as in LinkedList::Single::Example::Handoff, the old index leaves with the batch and is
# freed once the lock has been released.

sub drain( $self )
{
    my( $batch, $retired )
    = $self->{ lock }->hold( \&_drain, $self )->@*;

    undef $retired;

    $batch
}

sub take( $self, $k )
{
    $self->{ lock }->hold( \&_take, $self, $k )
}

sub cancel( $self, $id )
{
    $self->{ lock }->hold( \&_cancel, $self, $id )
}

sub requeue( $self, $batch )
{
    left( $self, $batch )
    or return 0;

    $self->{ lock }->hold( \&_requeue, $self, $batch )
}

########################################################################
# work on a batch: the lock is not held. a batch from drain still has
# the husks of cancelled items in it, which are skipped.
########################################################################

sub process( $self, $batch, $handler, $limit = undef )
{
    my $done    = 0;

    while
    (
        $batch->@*
        && ( ! defined $limit || $done < $limit )
    )
    {
        my $item    = shift $batch->@*;

        defined $item->[ 0 ]
        or next;

        $handler->( $item->@* );

        ++$done;
    }

    $done
}

sub left( $self, $batch )
{
    scalar grep { defined $_->[ 0 ] } $batch->@*
}

########################################################################
# the work done while the lock is held
########################################################################

sub _enqueue( $self, @data )
{
    my $id      = ++$self->{ serial };
    my $item    = [ $id, @data ];

    push $self->{ queue }->@*, $item;

    $self->{ item }{ $id }  = $item;

    ++$self->{ live };

    $id
}

# swap the arrays and the index. the batch is the old array as it
# stands, husks and all; the old index goes back to be freed outside
# the lock.

sub _drain( $self )
{
    my $batch   = $self->{ queue };
    my $index   = $self->{ item };

    $self->{ purged }   += $self->{ live };

    $self->{ queue }    = [];
    $self->{ item }     = {};
    $self->{ live }     = 0;

    [ $batch, $index ]
}

# step over the front of the queue, husks included, until $k live
# items have been found; splice off what was passed and keep the
# live ones.

sub _take( $self, $k )
{
    my $queue   = $self->{ queue };
    my $end     = 0;
    my $found   = 0;

    while( $end < $queue->@* && $found < $k )
    {
        ++$found
        if defined $queue->[ $end ][ 0 ];

        ++$end;
    }

    $self->{ touched }  += $end;

    my $batch   = [ grep { defined $_->[ 0 ] } splice $queue->@*, 0, $end ];

    delete $self->{ item }->@{ map { $_->[ 0 ] } $batch->@* };

    $self->{ live }     -= $batch->@*;

    $batch
}

sub _cancel( $self, $id )
{
    my $item    = delete $self->{ item }{ $id }
    // return 0;

    # empty the item in place; the array keeps the husk.

    $item->@*   = ( undef );

    --$self->{ live };

    1
}

sub _requeue( $self, $batch )
{
    my @live    = grep { defined $_->[ 0 ] } $batch->@*;

    unshift $self->{ queue }->@*, @live;

    $self->{ item }->@{ map { $_->[ 0 ] } @live }   = @live;

    $self->{ live }     += @live;
    $self->{ touched }  += @live;

    $batch->@*  = ();

    scalar @live
}

########################################################################
# introspection
########################################################################

sub contents( $self )
{
    [ map { [ $_->@* ] } grep { defined $_->[ 0 ] } $self->{ queue }->@* ]
}

sub size( $self )
{
    $self->{ live }
}

sub lock( $self )
{
    $self->{ lock }
}

sub walked( $self )
{
    $self->{ touched }
}

sub purged( $self )
{
    $self->{ purged }
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Handoff::Marked - the work queue in an array with an id index and cancel by marking

=head1 DESCRIPTION

The array version that does not search to cancel. See
L<LinkedList::Single::Example::Handoff::POD>. Same interface as L<LinkedList::Single::Example::Handoff>.
