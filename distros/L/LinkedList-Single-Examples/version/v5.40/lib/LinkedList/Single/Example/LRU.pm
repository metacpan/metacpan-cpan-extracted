########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::LRU v2.0.0;
use v5.40;

use Carp            qw( croak );
use Scalar::Util    qw( refaddr );

use LinkedList::Single qw( v2 );

########################################################################
# the cache is a list that begins with a permanent anchor node:
#
#   anchor -> newest -> ... -> oldest -> sentinel
#
# every entry is a node [ $key, $value ]. the hash finds an entry, the
# list keeps the order, and moving an entry to the front, or dropping
# the oldest one, is a few pointer changes whatever the size.
#
# things kept beside the list, all of them cursors:
#
#   anchor  the first node, never removed. it gives the newest entry a
#           predecessor, which is what the index needs.
#   index   key => cursor on the node *before* that entry. a singly
#           linked list can only unlink a node from its predecessor,
#           so this is what makes a hit O(1).
#   last    cursor on the node before the *oldest* entry. eviction
#           unlinks the oldest entry from it.
#
# the cursors are only ever used to step off of ('next' and 'detach'
# return new objects), never advanced, so one cursor can safely be
# stored in several places.
#
# only operations that leave every other node where it is are used
# next to a stored cursor: 'append' after a non-sentinel, 'detach', and
# the pointer 'append_to'. 'fragment', 'delete', 'insert', 'shift' and
# 'unshift' move the *contents* of a node, which would leave a stored
# cursor looking at some other entry's data.
#
# the price of a singly linked list is the fix-ups: when an entry is
# unlinked, the entry behind it has a new predecessor and its index
# cursor has to follow. a doubly linked list would not need them.
########################################################################

sub new( $class, %arg )
{
    my $limit   = $arg{ limit }
    // croak 'Botched new: missing limit';

    $limit > 0
    or croak "Botched new: limit '$limit' is not positive";

    my $list    = LinkedList::Single->new;

    # an empty list: push fills the sentinel in place.

    $list->push( 'anchor' );

    my $anchor  = $list->cursor;

    bless
    {
        limit       => $limit
      , on_evict    => $arg{ on_evict } // sub {}
      , list        => $list
      , anchor      => $anchor
      , last        => $anchor
      , index       => {}
      , size        => 0
    }
    => $class
}

########################################################################
# utility
########################################################################

# the key of the entry that follows a cursor.

sub _key_after( $cursor )
{
    ( $cursor->next_data )[ 0 ]
}

# the key of the entry a cursor stands on.

sub _key_at( $cursor )
{
    ( $cursor->data )[ 0 ]
}

########################################################################
# move an entry to the front.
#
# A anchor, P the entry's predecessor, M the entry, T the node after M,
# S the node after A (the newest entry before the move).
#
#   before:  A -> S ... P -> M -> T
#   after:   A -> M -> S ... P -> T
########################################################################

sub _promote( $self, $key )
{
    my $anchor  = $self->{ anchor };
    my $index   = $self->{ index };
    my $pred    = $index->{ $key };

    # already the newest: nothing moves.

    refaddr $pred == refaddr $anchor
    and return $self;

    my $newest  = _key_after $anchor;

    # M comes out whole, in a fragment of its own: the nodes on either
    # side are joined by the detach.

    my $entry   = $pred->detach( 1 );

    # T, if there is one, now follows P.

    my $after   = $pred->next;

    $after
    and $index->{ _key_at $after } = $pred;

    # M goes in behind the anchor, S behind M.

    $entry->append_to( $anchor );

    $index->{ $key }        = $anchor;
    $index->{ $newest }     = $anchor->next;

    # 'last' stands on the node before the oldest entry, and that
    # may be a node that just moved:
    #
    #   M was the oldest: P is, and its predecessor is whatever the
    #   index says it is after the moves above.
    #
    #   T is the oldest: M was the node before it, and P is now.

    if( ! $after )
    {
        $self->{ last } = $index->{ _key_at $pred };
    }
    elsif( ! $pred->next( 2 ) )
    {
        $self->{ last } = $pred;
    }

    $self
}

########################################################################
# drop the oldest entry, handing it to the eviction handler.
########################################################################

sub _evict( $self )
{
    my $last    = $self->{ last };
    my $index   = $self->{ index };

    my $entry   = $last->detach( 1 );

    delete $index->{ _key_at $entry };

    --$self->{ size };

    # the entry before the one removed is the oldest now; with nothing
    # left that is the anchor, and 'last' stays where it is.

    $self->{ size }
    and $self->{ last } = $index->{ _key_at $last };

    # consuming releases the node and destroys the payload; the handler
    # sees ( $key, $value ).

    $entry->consume( $self->{ on_evict } );

    $self
}

########################################################################
# public interface
########################################################################

# the value for a key and the entry becomes the newest; undef on a miss.

sub get( $self, $key )
{
    my $pred    = $self->{ index }{ $key }
    or return undef;

    $self->_promote( $key );

    ( $self->{ anchor }->next_data )[ 1 ]
}

# add or replace an entry; it is now the newest. the oldest is evicted
# if the cache is over its limit.

sub put( $self, $key, $value )
{
    my $anchor  = $self->{ anchor };
    my $index   = $self->{ index };

    if( my $pred = $index->{ $key } )
    {
        $self->_promote( $key );

        $anchor->next->set_data( $key, $value );
    }
    else
    {
        my $newest  = $self->{ size } ? _key_after $anchor : undef;
        my $alone   = $self->{ size } == 1;

        # append after a non-sentinel links a new node in; no other
        # node moves.

        $anchor->append( $key, $value );

        $index->{ $key }    = $anchor;

        if( defined $newest )
        {
            $index->{ $newest } = $anchor->next;

            # the lone entry was the oldest: the new one is before it.

            $alone
            and $self->{ last } = $anchor->next;
        }
        else
        {
            $self->{ last } = $anchor;
        }

        ++$self->{ size };

        $self->{ size } > $self->{ limit }
        and $self->_evict;
    }

    $self
}

sub exists( $self, $key )
{
    exists $self->{ index }{ $key }
}

sub size( $self )
{
    $self->{ size }
}

sub limit( $self )
{
    $self->{ limit }
}

# arrayref of [ $key, $value ], newest first.

sub contents( $self )
{
    my $all = $self->{ list }->extract;

    # the anchor is not an entry.

    [ $all->@[ 1 .. $#$all ] ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::LRU - least-recently-used cache with the order kept in a linked list

=head1 SYNOPSIS

    use LinkedList::Single::Example::LRU;

    my $cache
    = LinkedList::Single::Example::LRU->new
    (
        limit       => 1_000
      , on_evict    => sub( $key, $value ) { write_back( $key, $value ) }
    );

    $cache->put( $key => $value );

    my $value = $cache->get( $key );    # undef on a miss

=head1 DESCRIPTION

A cache holds at most C<limit> entries. C<get> returns a value and makes
its entry the newest; C<put> adds or replaces an entry as the newest and,
if the cache is then over its limit, evicts the oldest, passing its key
and value to C<on_evict> if there is one. This is the least-recently-used
(LRU) policy. C<exists>, C<size>, C<limit> and C<contents> (newest first)
look at the cache without changing it.

The order of the entries is kept in a L<LinkedList::Single>. A hash maps
each key to a cursor on the node before its entry, so a hit finds the
entry without searching and moves it to the front with pointer changes,
and the eviction of the oldest is another. The cost of one operation does
not depend on how many entries the cache holds.

Three classes with the same interface keep the same cache in perl arrays
and hashes: L<LinkedList::Single::Example::LRU::Array> (an array of pairs,
searched on every hit), L<LinkedList::Single::Example::LRU::Order> (a hash
and an array of keys) and L<LinkedList::Single::Example::LRU::Lazy> (a hash
and a queue of time-stamped uses, never searched). The first is the test
oracle: the tests drive the list and the arrays with the same random
requests and compare what each returns and what each evicts.

=head2 How it is benchmarked

F<benchmarks/10-LRU/compare> runs a read-through cache (a C<get> that
misses is followed by a C<put>) at limits of 100, 10,000 and 200,000
entries, with three request patterns: C<hot> (90% of requests to a tenth
of the limit's worth of keys), C<uniform> (keys drawn from twice the limit,
about half hit) and C<scan> (keys taken in turn from one more than the
limit). It reports microseconds per operation, the memory of a fresh
process holding 200,000 entries, and statements and branches counted in
each implementation's code.

=head2 Why it matters

A cache is on the hot path of whatever uses it, and the order of its
entries is touched on every hit. How that order is kept decides whether
the cost of a hit stays the same or grows with the size of the cache.
Here the list's cost stays flat, the arrays that search for the key grow
with the cache, and the array version written to avoid the search is
fastest of the four at every size measured. So the list is a fair choice
against an array that searches and not against one that does not. The
measurements, the background and the references are in
L<LinkedList::Single::Example::LRU::POD>.

This is an example, not a cache for production use: it has no expiry, no
thread safety and no hit counters.

=head1 SEE ALSO

L<LinkedList::Single::Example::LRU::POD>, L<LinkedList::Single>
