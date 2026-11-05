########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::SortedMerge v2.0.0;
use v5.40;

use Carp    qw( croak );

use LinkedList::Single qw( v2 );

########################################################################
# an item is [ $key, @payload ]: one node of the list. the comparator
# sees the keys only, and returns <0, 0, >0 like <=>; the default is
# numeric. a merge is stable: when the keys are equal the item from the
# left list goes first.
#
# two ways to merge are provided, chosen by new( how => ... ):
#
#   relink  move the nodes of the inputs onto the output through
#           Fragments. nothing is built; each input is emptied as
#           its nodes leave it.
#   copy    push each item's data onto a new list through a tail
#           cursor, then empty the inputs.
#
# neither can do what a pointer-based merge inside the module could
# (see benchmarks/50-SortedMerge/raw-nodes): LinkedList::Single has no operation that
# moves a node by pointer, and its Fragments move a node's *contents*
# into a new array. what each costs is in LinkedList::Single::Example::SortedMerge::POD.
########################################################################

sub new( $class, %arg )
{
    my $cmp = $arg{ cmp } // sub( $x, $y ) { $x <=> $y };
    my $how = $arg{ how } // 'relink';

    # with no comparator given, sort_via_array can use perl's own
    # numeric comparison instead of calling $cmp for every pair.

    my $default = ! defined $arg{ cmp };

    $how =~ m{ \A (?: relink | copy ) \z }x
    or croak "Botched new: how must be 'relink' or 'copy', not '$how'";

    bless
    {
        cmp     => $cmp
      , how     => $how
      , default => $default
    }
    => $class
}

########################################################################
# merge two sorted lists into a new one. both inputs are consumed
# (they test false afterwards).
########################################################################

sub merge( $self, $x, $y )
{
    $self->{ how } eq 'relink'
    ? _merge_relink( $self->{ cmp }, $x, $y )
    : _merge_copy(   $self->{ cmp }, $x, $y )
}

########################################################################
# relink: take the front node of whichever list goes next.
#
# the output is built at a cursor parked on its sentinel, so adding to
# it never walks it (push_onto walks to the sentinel of whatever it is
# given; for a cursor already standing on one that is no walk at all).
# when one input runs out the other is moved whole, in one cut.
########################################################################

sub _merge_relink( $cmp, $x, $y )
{
    my $out     = LinkedList::Single->new;
    my $tail    = $out->cursor;

    while( $x && $y )
    {
        my $from
        = $cmp->( ( $x->data )[ 0 ], ( $y->data )[ 0 ] ) <= 0
        ? $x
        : $y
        ;

        _move_front( $from, $tail );
    }

    for my $rest ( $x, $y )
    {
        $rest
        and $rest->fragment->push_onto( $tail );
    }

    $out
}

# one node from the front of $src onto the sentinel $tail stands on.
#
#   $rest  everything after the first node (cut O(1): the cursor
#          is on the first node, the cut is at the next)
#   $one   the first node alone, which empties $src
#
# then the rest goes back into the empty $src, and the node is added
# to the output, where its own sentinel becomes the new end.

sub _move_front( $src, $tail )
{
    my $rest    = $src->cursor->next->fragment;
    my $one     = $src->fragment;

    $rest
    and $rest->push_onto( $src );

    $one->push_onto( $tail );

    $tail->advance;

    return
}

########################################################################
# copy: read both inputs with cursors, push onto a new list.
########################################################################

sub _merge_copy( $cmp, $x, $y )
{
    my $out     = LinkedList::Single->new;
    my $tail    = $out->cursor;
    my $xc      = $x->cursor;
    my $yc      = $y->cursor;

    while( $xc && $yc )
    {
        my $from
        = $cmp->( ( $xc->data )[ 0 ], ( $yc->data )[ 0 ] ) <= 0
        ? $xc
        : $yc
        ;

        $tail->push( $from->data )->advance;

        $from->advance;
    }

    for my $rest ( $xc, $yc )
    {
        while( $rest )
        {
            $tail->push( $rest->data )->advance;

            $rest->advance;
        }
    }

    # the inputs were consumed: empty them, as relink does.

    $x->fragment;
    $y->fragment;

    $out
}

########################################################################
# split a list in two. the first $n nodes stay in the list given, the
# rest go to a new list. $n must be less than the length of the list.
#
# the cut is one cursor walk of $n nodes and one O(1) fragment.
########################################################################

sub _split( $list, $n )
{
    my $right   = LinkedList::Single->new;

    $list->cursor->next( $n )->fragment->push_onto( $right );

    ( $list, $right )
}

# into two halves; the left gets the extra node when the length is odd.

sub split_half( $self, $list )
{
    my $count   = $list->count;

    $count > 1
    or croak "Botched split_half: a list of $count nodes has no halves";

    _split( $list, int( ( $count + 1 ) / 2 ) )
}

########################################################################
# merge sort: split, sort each half, merge. the recursion is log2(n)
# deep; the length is passed down so no list is counted twice.
#
# the argument is consumed: use the list returned.
########################################################################

sub merge_sort( $self, $list )
{
    _sort( $self, $list, $list->count )
}

sub _sort( $self, $list, $count )
{
    $count > 1
    or return $list;

    my $half            = int( ( $count + 1 ) / 2 );
    my( $left, $right ) = _split( $list, $half );

    $self->merge
    (
        _sort( $self, $left,  $half           )
      , _sort( $self, $right, $count - $half  )
    )
}

########################################################################
# sort through an array: take the items out, let perl's own sort order
# them, and build a new list. nothing here is clever, and it is the
# practical competitor to a merge sort on the list: perl's sort is C,
# and each item crosses the list boundary only twice.
#
# the order of equal keys is perl's: its sort has been a stable merge
# sort since 5.8, though the documentation stops short of promising it,
# and the tests check it. the argument is consumed, like merge_sort's.
########################################################################

sub sort_via_array( $self, $list )
{
    my $cmp     = $self->{ cmp };
    my $item    = ( scalar $list->extract ) // [];
    my $out     = LinkedList::Single->new;
    my $tail    = $out->cursor;

    my @sorted
    = $self->{ default }
    ? sort { $a->[ 0 ] <=> $b->[ 0 ] } $item->@*
    : sort { $cmp->( $a->[ 0 ], $b->[ 0 ] ) } $item->@*
    ;

    $tail->push( $_->@* )->advance
    for @sorted;

    $list->fragment;

    $out
}

########################################################################
# test support: items in and out.
########################################################################

# a list of the items, in order.

sub build( $self, @item )
{
    my $list    = LinkedList::Single->new;
    my $tail    = $list->cursor;

    $tail->push( $_->@* )->advance
    for @item;

    $list
}

# arrayref of the items in a list: [ $key, @payload ], in order.

sub contents( $self, $list )
{
    ( scalar $list->extract ) // []
}

1
__END__

=head1 NAME

LinkedList::Single::Example::SortedMerge - merge and merge sort on LinkedList::Single lists

=head1 SYNOPSIS

    use LinkedList::Single::Example::SortedMerge;

    my $sorter
    = LinkedList::Single::Example::SortedMerge->new
    (
        how     => 'copy'                       # or 'relink', the default
      , cmp     => sub( $x, $y ) { $x <=> $y }  # on keys; this is the default
    );

    my $log     = $sorter->build( [ 3, 'web', 'login' ], [ 8, 'web', 'view' ] );

    my $both    = $sorter->merge( $log, $other );       # both consumed

    my $sorted  = $sorter->merge_sort( $unsorted );     # use this, not $unsorted
    my $also    = $sorter->sort_via_array( $more );     # extract, sort, rebuild

    my( $left, $right ) = $sorter->split_half( $list );

=head1 DESCRIPTION

An item is a node C<[ $key, @payload ]> of a L<LinkedList::Single> list.
C<merge> combines two lists that are each sorted by key into one sorted
list; C<merge_sort> sorts a list by splitting it in half, sorting each
half and merging them. Both are stable (on equal keys the item from the
left goes first) and both consume their arguments, which test false
afterwards. C<sort_via_array> takes the items out, sorts them with perl's
C<sort> and builds a new list. C<build> and C<contents> put items in and
take them out.

There are two merges, chosen by C<how>. C<copy> reads both inputs with
cursors and pushes each item onto a new list. C<relink> moves the front
node of an input onto the output through Fragments; it reads like a relink
but, because a Fragment moves a node's contents into a new array, builds
an array per node moved, and it is the slower of the two.

L<LinkedList::Single::Example::SortedMerge::Array> has the same interface
over perl arrays and is the test oracle with perl's C<sort>: the tests
merge and sort the same random items through all of them and compare.

=head2 How it is benchmarked

F<benchmarks/50-SortedMerge/compare> sorts 1,000, 10,000 and 100,000
random numbers with both list merge sorts, the array merge sort,
C<sort_via_array>, perl's C<sort> and the module's own C<< $list->sort >>;
times the growth of the module's sort from 500 to 8,000 items; merges two
sorted lists of n/2; and reports the memory of a merged result and
statements and branches in each merge. F<benchmarks/50-SortedMerge/raw-nodes>
looks inside the list's nodes, which no other example does, to measure a
pointer merge sort: the ceiling that only code inside the module can
reach.

=head2 Why it matters

Merging is the step under a merge sort, and under combining ordered logs
or files. On a linked list the textbook merge relinks nodes and copies
nothing. Through this module's public operations it does not: at every
size measured the array merge and perl's C<sort> are faster, and the
list merge sorts are 13 to 50 times slower than the array one. The example did
find that the module's own C<sort> was quadratic, and the pointer merge
sort that replaced it now beats the array merge sort written in perl. The
measurements and references are in
L<LinkedList::Single::Example::SortedMerge::POD>.

=head1 SEE ALSO

L<LinkedList::Single::Example::SortedMerge::POD>,
L<LinkedList::Single::Example::SortedMerge::Array>, L<LinkedList::Single>
