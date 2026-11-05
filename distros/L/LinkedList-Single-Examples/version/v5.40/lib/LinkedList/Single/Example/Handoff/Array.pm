########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Handoff::Array v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single::Example::Lock;

########################################################################
# the queue is an array of [ $id, @data ]. a handle is the id; an
# array has no way to go from an id to a position except by looking,
# so cancel searches.
#
# drain has two forms, chosen by new( drain => ... ):
#
#   swap    ( $batch, $queue ) = ( $queue, [] )
#           O(1) under the lock, and as cheap as the list's. this is
#           what anyone who knows perl would write.
#   copy    copy the items out and clear the queue: O(n) under the
#           lock. what a careless version does, and the version that
#           many languages without reference swaps are stuck with.
#
# 'touched' counts the elements this module's code examines or copies
# one by one. what splice, unshift and the swap do inside perl is not
# counted: a memmove of the queue is cheap per element, but it is not
# free, and the timings are where that shows.
########################################################################

sub new( $class, %arg )
{
    my $how     = $arg{ drain } // 'swap';
    my $lock    = $arg{ lock  } // LinkedList::Single::Example::Lock->new;

    $how =~ m{ \A (?: swap | copy ) \z }x
    or croak "Botched new: drain must be 'swap' or 'copy', not '$how'";

    bless
    {
        lock    => $lock
      , queue   => []
      , drain   => $how
      , serial  => 0
      , touched => 0
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

sub drain( $self )
{
    $self->{ lock }->hold( \&_drain, $self )
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
    $batch->@*
    or return 0;

    $self->{ lock }->hold( \&_requeue, $self, $batch )
}

########################################################################
# work on a batch: the lock is not held.
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

        $handler->( $item->@* );

        ++$done;
    }

    $done
}

sub left( $self, $batch )
{
    scalar $batch->@*
}

########################################################################
# the work done while the lock is held
########################################################################

sub _enqueue( $self, @data )
{
    my $id  = ++$self->{ serial };

    push $self->{ queue }->@*, [ $id, @data ];

    $id
}

sub _drain( $self )
{
    my $queue   = $self->{ queue };

    if( $self->{ drain } eq 'swap' )
    {
        $self->{ queue }    = [];

        return $queue;
    }

    # copy: every element is handled, and the emptied array keeps
    # the capacity it grew to.

    my $batch   = [ $queue->@* ];

    $self->{ touched }  += $queue->@*;

    $queue->@*  = ();

    $batch
}

sub _take( $self, $k )
{
    my $queue   = $self->{ queue };
    my $batch   = [ splice $queue->@*, 0, $k ];

    $self->{ touched }  += $batch->@*;

    $batch
}

sub _cancel( $self, $id )
{
    my $queue   = $self->{ queue };
    my $at      = 0;

    ++$at
    while $at < $queue->@*
    && $queue->[ $at ][ 0 ] != $id;

    $self->{ touched }  += $at + 1;

    $at < $queue->@*
    or return 0;

    splice $queue->@*, $at, 1;

    1
}

sub _requeue( $self, $batch )
{
    my $count   = $batch->@*;

    unshift $self->{ queue }->@*, $batch->@*;

    $self->{ touched }  += $count;

    $batch->@*  = ();

    $count
}

########################################################################
# introspection
########################################################################

sub contents( $self )
{
    [ map { [ $_->@* ] } $self->{ queue }->@* ]
}

sub size( $self )
{
    scalar $self->{ queue }->@*
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
    0
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Handoff::Array - the same work queue held in a perl array

=head1 DESCRIPTION

The array twin of L<LinkedList::Single::Example::Handoff>, with the same interface, used as
the reference for the tests and the comparison in the benchmarks. Build
it with C<< drain => 'copy' >> to see the cost of the hand-off that does
not use the reference swap.
