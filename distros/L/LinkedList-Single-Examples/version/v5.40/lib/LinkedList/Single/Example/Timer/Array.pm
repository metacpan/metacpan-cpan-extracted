########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Timer::Array v2.0.0;
use v5.40;

use Carp    qw( carp );

########################################################################
# the same queue over a perl array of [ $start, @msg ], in start order.
# this is the version a good perl programmer writes, so it uses what
# perl is fast at:
#
#   enqueue   a message that starts no earlier than the last is pushed.
#             any other is placed by a binary search and one splice
#             (a memmove of the elements behind it).
#   take      a binary search finds the cut, then one splice takes the
#             due messages off the front. perl moves the array's start
#             pointer for a splice at the front, so this does not move
#             the messages that stay.
#   requeue   unshift of what is left. perl keeps room before the start
#             of the array, so this copies only the messages put back.
#
# so the work is a binary search where the list walks, and a copy of the
# pointers of what is moved where the list relinks them.
#
# 'walked' counts the elements the module's own code steps over, as the
# list version's does (the binary search is not counted: it is a log).
########################################################################

sub new( $class, %arg )
{
    bless
    {
        clock   => $arg{ clock  } // sub { time }
      , window  => $arg{ window } // 60
      , queue   => []
      , walked  => 0
      , merged  => 0
    }
    => $class
}

########################################################################
# public interface
########################################################################

sub enqueue( $self, $start, @msg )
{
    $self->_insert( $start, @msg );

    $self
}

sub take( $self, $now = $self->{ clock }->() )
{
    my $queue   = $self->{ queue };

    # the count of messages that start at or before $now: the first
    # whose start is above it is where the search ends.

    my( $lo, $hi ) = ( 0, scalar @$queue );

    while( $lo < $hi )
    {
        my $mid = ( $lo + $hi ) >> 1;

        if( $queue->[ $mid ][ 0 ] <= $now )
        {
            $lo = $mid + 1;
        }
        else
        {
            $hi = $mid;
        }
    }

    $lo
    or return undef;

    my @item    = splice @$queue, 0, $lo;

    return
    {
        items   => \@item
      , at      => 0
      , latest  => $item[ -1 ][ 0 ]
      , left    => scalar @item
    };
}

sub process( $self, $batch, $handler, $deadline = undef )
{
    $batch
    or return 0;

    my $clock   = $self->{ clock };

    $deadline //= $clock->() + $self->{ window };

    my $items   = $batch->{ items };
    my $done    = 0;

    while( $batch->{ at } < @$items )
    {
        $clock->() >= $deadline
        and last;

        # an exception stops the batch where it was, as consume does:
        # quietly for die "\n", carped for any other.

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

    $batch->{ left }    -= $done;

    $done
}

sub left( $self, $batch )
{
    $batch
    ? $batch->{ left }
    : 0
}

sub requeue( $self, $batch )
{
    $batch
    or return 0;

    my $left    = $batch->{ left }
    or return 0;

    my $queue   = $self->{ queue };
    my $items   = $batch->{ items };
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

    $batch->{ left }    = 0;

    $left
}

########################################################################
# utility
########################################################################

# put a message after every message that does not start after it.

sub _insert( $self, $start, @msg )
{
    my $queue   = $self->{ queue };

    if( ! @$queue || $start >= $queue->[ -1 ][ 0 ] )
    {
        push @$queue, [ $start, @msg ];

        return $self
    }

    my( $lo, $hi ) = ( 0, scalar @$queue );

    while( $lo < $hi )
    {
        my $mid = ( $lo + $hi ) >> 1;

        if( $queue->[ $mid ][ 0 ] <= $start )
        {
            $lo = $mid + 1;
        }
        else
        {
            $hi = $mid;
        }
    }

    splice @$queue, $lo, 0, [ $start, @msg ];

    $self
}

########################################################################
# introspection
########################################################################

# arrayref of [ $start, @msg ], earliest first: copies, as the list's is.

sub contents( $self )
{
    [ map { [ $_->@* ] } $self->{ queue }->@* ]
}

sub next_start( $self )
{
    $self->{ queue }[ 0 ] && $self->{ queue }[ 0 ][ 0 ]
}

sub size( $self )
{
    scalar $self->{ queue }->@*
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

LinkedList::Single::Example::Timer::Array - the same start-time queue over a perl array

=head1 DESCRIPTION

See L<LinkedList::Single::Example::Timer> and L<LinkedList::Single::Example::Timer::POD>.
