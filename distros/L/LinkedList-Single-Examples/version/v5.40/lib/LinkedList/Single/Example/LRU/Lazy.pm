########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::LRU::Lazy v2.0.0;
use v5.40;

use Carp    qw( croak );

########################################################################
# the array programmer's best version: nothing is ever searched for or
# spliced out.
#
# a hash holds key => [ value, stamp ]. every use pushes [ key, stamp ]
# at the back of a queue with a fresh stamp, and leaves the older queue
# entry for that key behind as a husk: it is stale because the hash now
# has a newer stamp. eviction shifts entries from the front, skipping
# the husks. when the queue holds too many husks it is compacted, which
# is O(n) but happens once per O(limit) operations.
#
# the price: a queue longer than the cache (up to 3x), husks to
# recognise, a stamp in every entry, and a compaction rule to get right.
########################################################################

sub new( $class, %arg )
{
    my $limit   = $arg{ limit }
    // croak 'Botched new: missing limit';

    $limit > 0
    or croak "Botched new: limit '$limit' is not positive";

    bless
    {
        limit       => $limit
      , on_evict    => $arg{ on_evict } // sub {}
      , entry       => {}
      , queue       => []
      , stamp       => 0
    }
    => $class
}

# a queue entry is current if the hash still has its stamp.

sub _current( $self, $queued )
{
    my $entry   = $self->{ entry }{ $queued->[ 0 ] }
    or return 0;

    $entry->[ 1 ] == $queued->[ 1 ]
}

sub _touch( $self, $key )
{
    my $stamp   = ++$self->{ stamp };
    my $queue   = $self->{ queue };

    $self->{ entry }{ $key }[ 1 ]   = $stamp;

    push $queue->@*, [ $key, $stamp ];

    # compaction: once husks outnumber the live entries 2:1.

    if( @$queue > 3 * $self->{ limit } + 16 )
    {
        $queue->@* = grep { $self->_current( $_ ) } $queue->@*;
    }
}

sub get( $self, $key )
{
    my $entry   = $self->{ entry }{ $key }
    or return undef;

    $self->_touch( $key );

    $entry->[ 0 ]
}

sub put( $self, $key, $value )
{
    my $entry   = $self->{ entry }{ $key } //= [];

    $entry->[ 0 ]   = $value;

    $self->_touch( $key );

    while( keys $self->{ entry }->%* > $self->{ limit } )
    {
        my $queued  = shift $self->{ queue }->@*;

        $self->_current( $queued )
        or next;

        my $old = delete $self->{ entry }{ $queued->[ 0 ] };

        $self->{ on_evict }->( $queued->[ 0 ], $old->[ 0 ] );
    }

    $self
}

sub exists( $self, $key )
{
    exists $self->{ entry }{ $key }
}

sub size( $self )
{
    scalar keys $self->{ entry }->%*
}

sub limit( $self )
{
    $self->{ limit }
}

# newest first: the current queue entries, from the back.

sub contents( $self )
{
    [
        map { [ $_->[ 0 ], $self->{ entry }{ $_->[ 0 ] }[ 0 ] ] }
        grep { $self->_current( $_ ) }
        reverse $self->{ queue }->@*
    ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::LRU::Lazy - least-recently-used cache: hash plus stamped queue

=head1 DESCRIPTION

Same interface as L<LinkedList::Single::Example::LRU>. O(1) amortised for every
operation; stale queue entries are skipped on eviction and swept out
when they pile up.
