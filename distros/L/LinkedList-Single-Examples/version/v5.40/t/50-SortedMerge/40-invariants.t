########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::SortedMerge;

########################################################################
# utility
########################################################################

# the real nodes of a list, in order. tests may look inside; the
# example code does not.

sub chain( $list )
{
    my @node    = ();
    my $node    = $list->node;

    while( $node->@* )
    {
        push @node, $node;

        $node   = $node->[ 0 ];
    }

    @node
}

sub keys_of( $list )
{
    map { $_->[ 1 ] } chain $list
}

sub in_order( @key )
{
    ! grep { $key[ $_ ] > $key[ $_ + 1 ] } 0 .. $#key - 1
}

sub no_shared_nodes( @list )
{
    my %seen    = ();

    ++$seen{ refaddr $_ } for map { chain $_ } @list;

    ! grep { $_ > 1 } values %seen
}

# a list that is left after an operation must still be a proper list:
# something can be added at its end, and it shows up there.

sub extends_ok( $sorter, $list, $label )
{
    my $before  = $list->count;

    $list->push( 999, 'tail' );

    is $list->count, $before + 1, "$label: can be extended";

    cmp_deeply $sorter->contents( $list )->[ -1 ], [ 999, 'tail' ], "$label: new item is last";
}

########################################################################
# tests
########################################################################

srand 20261031;

for my $how ( qw( relink copy ) )
{
    my $sorter  = LinkedList::Single::Example::SortedMerge->new( how => $how );

    for my $sizes ( [ 0, 0 ], [ 0, 5 ], [ 5, 0 ], [ 1, 1 ], [ 7, 3 ], [ 30, 40 ] )
    {
        my( $nx, $ny )  = $sizes->@*;
        my $label       = "$how merge $nx + $ny";

        my $x   = $sorter->build( map { [ $_ * 2,     "x$_" ] } 1 .. $nx );
        my $y   = $sorter->build( map { [ $_ * 2 + 1, "y$_" ] } 1 .. $ny );

        my $out = $sorter->merge( $x, $y );

        is $out->count, $nx + $ny, "$label: item count preserved";

        ok in_order( keys_of $out ), "$label: result in order";

        ok no_shared_nodes( $out, $x, $y ), "$label: no node in two lists";

        ok ! $x && ! $y, "$label: inputs consumed";

        extends_ok $sorter, $out, $label;

        # the emptied inputs are still usable lists.

        extends_ok $sorter, $x, "$label: emptied left";
    }

    # split: the halves share nothing, hold everything, and both extend.

    for my $count ( 2, 3, 8, 9 )
    {
        my $label           = "$how split_half of $count";
        my $list            = $sorter->build( map { [ $_ ] } 1 .. $count );
        my( $left, $right ) = $sorter->split_half( $list );

        is $left->count + $right->count, $count, "$label: no item lost";

        ok no_shared_nodes( $left, $right ), "$label: halves share no node";

        cmp_deeply [ keys_of( $left ), keys_of( $right ) ], [ 1 .. $count ]
        , "$label: halves are the front and the back, in order";

        extends_ok $sorter, $left,  "$label: left";
        extends_ok $sorter, $right, "$label: right";
    }

    # merge_sort: count preserved, ordered, and the result is a proper list.

    for my $count ( 0, 1, 2, 17, 100 )
    {
        my $label   = "$how merge_sort of $count";
        my $sorted  = $sorter->merge_sort( $sorter->build( map { [ int rand 20 ] } 1 .. $count ) );

        is $sorted->count, $count, "$label: item count preserved";

        ok in_order( keys_of $sorted ), "$label: in order";

        extends_ok $sorter, $sorted, $label;
    }

    # split_half refuses a list with nothing to split.

    my $ok
    = eval
    {
        $sorter->split_half( $sorter->build( [ 1 ] ) );

        1
    };

    ok ! $ok, "$how: split_half of a single item croaks";
}

done_testing
__END__
