########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Ordered v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single qw( v2 );

########################################################################
# an ordered map from numeric keys to values: a linked list of entries
# in key order, divided into buckets by permanent marker nodes, with a
# small array that indexes the markers.
#
#   index[0]    index[1]               index[2]
#      |           |                      |
#   marker -> e -> e -> marker -> e -> e -> e -> marker -> e -> sentinel
#
# the nodes are [ $next, $key, $value ] for an entry and [ $next, 'bucket' ]
# for a marker. each index element is
#
#   low     the smallest key the bucket may hold. every key in the bucket
#           is >= low and < the next bucket's low. the first bucket has
#           no low: it takes every key below the second's.
#   mark    a cursor on the bucket's marker node.
#   count   how many entries the bucket holds.
#
# a lookup is two levels: a binary search of the index finds the bucket,
# then a walk from the marker finds the entry. the walk is bounded by
# the bucket size (at most 2 * bucket entries), not by the size of the
# map.
#
# why markers: a singly linked list can remove or insert only from the
# predecessor, and in the LRU cache (example 01) the index had to hold a
# cursor on the node before every entry, and repair it whenever a
# neighbour went. here the index points only at markers, and a marker is
# never moved or removed while its bucket has entries, so nothing in the
# index ever needs repair except the counts. the walk from the marker
# supplies the predecessor for each insert and delete.
#
# an entry is added after its predecessor with 'append' (a pointer
# change, nothing else moves) and removed with 'drop'. a bucket that
# reaches twice its size is split in two by inserting a new marker; an
# empty bucket's marker is dropped. the index is an array, but it holds
# one element per bucket, so splicing it costs 1/bucket of the work an
# array of all the entries would.
#
# in-order traversal is a walk of the list. no recursion, no stack, no
# rebalancing.
########################################################################

sub new( $class, %arg )
{
    # the default is the fastest found for lists of up to 100,000 entries
    # (see the POD); LLS_BUCKET_SIZE overrides it.

    my $bucket
    = $arg{ bucket }
    // $ENV{ LLS_BUCKET_SIZE }
    // 3
    ;

    $bucket > 0
    or croak "Botched new: bucket '$bucket' is not positive";

    my $list    = LinkedList::Single->new;

    # an empty list: push fills the sentinel in place.

    $list->push( 'bucket' );

    bless
    {
        bucket  => $bucket
      , list    => $list
      , index   =>
        [
            {
                low     => undef
              , mark    => $list->cursor
              , count   => 0
            }
        ]
      , size    => 0
    }
    => $class
}

########################################################################
# utility
########################################################################

# the position in the index of the bucket that holds, or would hold, a
# key: the last one whose low is not above it.

sub _locate( $self, $key )
{
    my $index   = $self->{ index };
    my( $lo, $hi ) = ( 0, $#$index );

    while( $lo < $hi )
    {
        my $mid = ( $lo + $hi + 1 ) >> 1;

        if( $index->[ $mid ]{ low } <= $key )
        {
            $lo = $mid;
        }
        else
        {
            $hi = $mid - 1;
        }
    }

    $lo
}

# a cursor on the node before the first entry of bucket $at whose key is
# not below $key (the marker if there is none before it), and whether
# that entry's key is $key.
#
# a new cursor is made for the walk: the marker's own is never moved.

sub _before( $self, $at, $key )
{
    my $entry   = $self->{ index }[ $at ];
    my $curs    = $entry->{ mark }->next( 0 );

    for( 1 .. $entry->{ count } )
    {
        my( $found ) = $curs->next_data;

        $found >= $key
        and return( $curs, $found == $key );

        $curs->advance;
    }

    ( $curs, 0 )
}

# a bucket has outgrown its size: the second half becomes a bucket of its
# own, behind a new marker.

sub _split( $self, $at )
{
    my $entry   = $self->{ index }[ $at ];
    my $keep    = $self->{ bucket };

    # the last entry that stays.

    my $last    = $entry->{ mark }->next( $keep );

    $last->append( 'bucket' );

    my $mark    = $last->next;

    splice $self->{ index }->@*, $at + 1, 0
    ,   {
            low     => ( $mark->next_data )[ 0 ]
          , mark    => $mark
          , count   => $entry->{ count } - $keep
        };

    $entry->{ count }   = $keep;

    $self
}

# drop the marker of bucket $at, which has no entries left. the node
# before a marker is the last node of the bucket before it.

sub _remove_bucket( $self, $at )
{
    my $index   = $self->{ index };
    my $before  = $index->[ $at - 1 ];

    $before->{ mark }->next( $before->{ count } )->drop;

    splice $index->@*, $at, 1;

    $self
}

########################################################################
# public interface
########################################################################

# add an entry, or replace the value of an existing one.

sub put( $self, $key, $value )
{
    my $at              = $self->_locate( $key );
    my( $curs, $found ) = $self->_before( $at, $key );

    if( $found )
    {
        $curs->next->set_data( $key, $value );
    }
    else
    {
        $curs->append( $key, $value );

        ++$self->{ size };

        my $entry   = $self->{ index }[ $at ];

        ++$entry->{ count } > 2 * $self->{ bucket }
        and $self->_split( $at );
    }

    $self
}

# the value for a key, or undef.

sub get( $self, $key )
{
    my $at              = $self->_locate( $key );
    my( $curs, $found ) = $self->_before( $at, $key );

    $found
    ? ( $curs->next_data )[ 1 ]
    : undef
}

# remove an entry; returns its value, or undef if there was none.

sub delete( $self, $key )
{
    my $at              = $self->_locate( $key );
    my( $curs, $found ) = $self->_before( $at, $key );

    $found
    or return undef;

    my( undef, $value ) = $curs->drop;

    --$self->{ size };

    my $entry   = $self->{ index }[ $at ];

    --$entry->{ count }
    or $at
    and $self->_remove_bucket( $at );

    $value
}

# the entries with lo <= key <= hi, in order, as [ key, value ] pairs.

sub range( $self, $lo, $hi )
{
    my $at      = $self->_locate( $lo );
    my $curs    = $self->{ index }[ $at ]{ mark }->next( 0 );
    my @found   = ();

    while( $curs->advance )
    {
        my @data    = $curs->data;

        # a marker holds one datum, an entry two.

        @data > 1
        or next;

        $data[ 0 ] > $hi
        and last;

        $data[ 0 ] >= $lo
        and push @found, \@data;
    }

    \@found
}

# remove and return the entries with lo <= key <= hi.
#
# buckets that lie wholly inside the range, markers and all, come out as
# one detached piece, without a look at the keys in them. the buckets at
# the two ends are cut entry by entry.

sub cut( $self, $lo, $hi )
{
    my $index   = $self->{ index };
    my @found   = ();
    my $at      = $self->_locate( $lo );

    while( $at <= $#$index )
    {
        my $entry   = $index->[ $at ];

        # nothing at or after a bucket whose low is above the range
        # is in it.

        defined $entry->{ low }
        and $entry->{ low } > $hi
        and last;

        if( $self->_inside( $at, $lo, $hi ) )
        {
            # take this bucket and every whole bucket after it.

            my $stop    = $at;

            ++$stop while $self->_inside( $stop + 1, $lo, $hi );

            push @found, $self->_detach( $at, $stop )->@*;
        }
        else
        {
            push @found, $self->_cut_bucket( $at, $lo, $hi )->@*;

            # an emptied bucket was removed, and the next one is here.

            $at <= $#$index
            and $index->[ $at ] == $entry
            and ++$at;
        }
    }

    \@found
}

# is every key that bucket $at can hold within the range? the keys are
# all below the next bucket's low, so the last bucket never is.

sub _inside( $self, $at, $lo, $hi )
{
    my $index   = $self->{ index };

    $at > 0
    and $at < $#$index
    and $index->[ $at ]{ low } >= $lo
    and $index->[ $at + 1 ]{ low } <= $hi
}

# detach buckets $first .. $last whole, and return their entries.

sub _detach( $self, $first, $last )
{
    my $index   = $self->{ index };
    my $before  = $index->[ $first - 1 ];
    my $nodes   = 0;

    $nodes  += 1 + $index->[ $_ ]{ count } for $first .. $last;

    my $piece   = $before->{ mark }->next( $before->{ count } )->detach( $nodes );

    my @entry
    = grep { @$_ > 1 }
      $piece->extract->@*;

    $self->{ size } -= @entry;

    splice $index->@*, $first, $last - $first + 1;

    \@entry
}

# cut the entries in range out of bucket $at, one by one.

sub _cut_bucket( $self, $at, $lo, $hi )
{
    my $entry   = $self->{ index }[ $at ];
    my $curs    = $entry->{ mark }->next( 0 );
    my @found   = ();

    for( 1 .. $entry->{ count } )
    {
        my( $key ) = $curs->next_data;

        if( $key < $lo )
        {
            $curs->advance;
        }
        elsif( $key <= $hi )
        {
            push @found, [ $curs->drop ];
        }
        else
        {
            last;
        }
    }

    $entry->{ count }   -= @found;
    $self->{ size }     -= @found;

    $entry->{ count }
    or $at
    and $self->_remove_bucket( $at );

    \@found
}

sub size( $self )
{
    $self->{ size }
}

sub buckets( $self )
{
    scalar $self->{ index }->@*
}

# arrayref of [ key, value ] in key order.

sub contents( $self )
{
    [ grep { @$_ > 1 } $self->{ list }->extract->@* ]
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Ordered - an ordered map in a linked list with a small index of markers

=head1 SYNOPSIS

    use LinkedList::Single::Example::Ordered;

    # bucket defaults to $ENV{ LLS_BUCKET_SIZE }, else 3.

    my $map = LinkedList::Single::Example::Ordered->new( bucket => 8 );

    $map->put( 42 => 'answer' );

    my $value   = $map->get( 42 );          # undef if absent
    my $pairs   = $map->range( 10, 50 );    # [ [ key, value ], ... ]
    my $gone    = $map->cut( 10, 50 );      # the same, removed
    my $old     = $map->delete( 7 );        # the value removed, or undef

=head1 DESCRIPTION

An ordered map with numeric keys: C<put> adds or replaces, C<get> and
C<delete> return the value or C<undef>, C<range( $lo, $hi )> returns the
entries with C<lo E<lt>= key E<lt>= hi> in key order as C<[ $key, $value ]>
pairs and C<cut> removes them as well. C<contents> (all entries in
order), C<size> and C<buckets> look at the map without changing it.

The entries are kept in one L<LinkedList::Single> in key order. Marker
nodes divide the list into buckets of at most twice the bucket
size, and a small array holds each bucket's lowest key, a cursor on its
marker and its count. A binary search of that array finds the bucket and
a short walk from the marker finds the entry; an insert or delete is
then a change of links. Because the index points only at markers, which
do not move while their bucket has entries, it never needs repair when
entries come and go. Buckets that lie wholly inside a C<cut> come out of
the list in one piece.

Three classes with the same interface keep the same map in perl arrays
and hashes: L<LinkedList::Single::Example::Ordered::Sorted> (one sorted
array, the test oracle), L<LinkedList::Single::Example::Ordered::Buckets>
(an array of small sorted arrays, the same two-level design without the
list) and L<LinkedList::Single::Example::Ordered::Hash> (a hash, sorted
on demand). The tests drive all four with the same random operations and
compare every result.

=head2 How it is benchmarked

F<benchmarks/60-Ordered/compare> builds maps of 1,000 to 200,000 entries
and reports microseconds per build insert, get, churn operation (half
put, half delete), range of about 50 entries, cut of a tenth of the map
and full traversal; a sweep of bucket sizes; the memory of a fresh
process holding about 190,000 entries; and statements and branches
counted in each implementation. F<benchmarks/60-Ordered/latency> times
every call separately, at 100,000 and 400,000 entries, and reports the
median, the 99.9th percentile and the slowest call.

=head2 Why it matters

Keeping a map in order costs either a search that cannot halve (a list)
or a move of everything after the change (an array). The two-level
design bounds both, and the list's cost hardly grows with the size of
the map. Measured on one machine, though, the array of buckets, the
same design written with arrays, is faster at every size up to 800,000
entries, its slowest call is no worse, and its code is shorter; the list
passes only the plain sorted array, between 200,000 and 400,000 entries.
The hash is fastest for single keys and has the one slowest call that
grows with the size, its rehash. The measurements and the reasons are
in L<LinkedList::Single::Example::Ordered::POD>.

=head1 SEE ALSO

L<LinkedList::Single::Example::Ordered::POD>, L<LinkedList::Single>
