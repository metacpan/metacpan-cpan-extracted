########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single qw( v2 );

use LinkedList::Single::Example::Probe;
use LinkedList::Single::Example::SortedMerge;

########################################################################
# utility
########################################################################

# build the late objects that make the class let go of the last
# argument it was given (the stale whence slot).

sub flush()
{
    my $list    = LinkedList::Single->new;

    $list->cursor;

    LinkedList::Single::Fragment->new;

    return
}

# every probe destroyed exactly once: the counts, not just the ids.

sub destroyed_once( @id )
{
    my %seen    = %LinkedList::Single::Example::Probe::gone;

    # eq_deeply is a plain boolean; cmp_deeply would run a test of its own.

    eq_deeply [ sort { $a <=> $b } keys %seen ], [ sort { $a <=> $b } @id ]
    or return 0;

    ! grep { $_ != 1 } values %seen
}

########################################################################
# tests
#
# merging moves or copies the items of a list, never the payloads: a
# probe in an item must be alive while the result holds it, and be
# destroyed once, and only once, when the result is let go.
########################################################################

for my $how ( qw( relink copy ) )
{
    my $sorter  = LinkedList::Single::Example::SortedMerge->new( how => $how );

    # merge: two lists of probes with interleaved keys.

    LinkedList::Single::Example::Probe->reset;

    my $x   = $sorter->build( map { [ 2 * $_,     LinkedList::Single::Example::Probe->new( 100 + $_ ) ] } 1 .. 10 );
    my $y   = $sorter->build( map { [ 2 * $_ + 1, LinkedList::Single::Example::Probe->new( 200 + $_ ) ] } 1 .. 10 );

    my $merged  = $sorter->merge( $x, $y );

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], "$how: merge destroyed nothing";

    ok ! $x && ! $y, "$how: both inputs consumed";

    is $merged->count, 20, "$how: result holds all twenty items";

    cmp_deeply [ map { $_->[ 0 ] } $sorter->contents( $merged )->@* ], [ 2 .. 21 ]
    , "$how: result is in key order";

    undef $merged;

    flush;

    ok destroyed_once( 101 .. 110, 201 .. 210 )
    , "$how: letting the result go destroyed each payload exactly once";

    # merge_sort: probes in reverse order.

    LinkedList::Single::Example::Probe->reset;

    my $list    = $sorter->build( map { [ 50 - $_, LinkedList::Single::Example::Probe->new( $_ ) ] } 1 .. 40 );

    my $sorted  = $sorter->merge_sort( $list );

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], "$how: merge_sort destroyed nothing";

    cmp_deeply [ map { $_->[ 1 ]->id } $sorter->contents( $sorted )->@* ], [ reverse 1 .. 40 ]
    , "$how: probes came out in key order, each once";

    undef $sorted;
    undef $list;

    flush;

    ok destroyed_once( 1 .. 40 )
    , "$how: letting the sorted list go destroyed each payload exactly once";
}

# the sort through an array makes the same promise.

{
    my $sorter  = LinkedList::Single::Example::SortedMerge->new;

    LinkedList::Single::Example::Probe->reset;

    my $list    = $sorter->build( map { [ 50 - $_, LinkedList::Single::Example::Probe->new( $_ ) ] } 1 .. 40 );
    my $sorted  = $sorter->sort_via_array( $list );

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'sort_via_array destroyed nothing';

    ok ! $list, 'sort_via_array consumed its argument';

    cmp_deeply [ map { $_->[ 1 ]->id } $sorter->contents( $sorted )->@* ], [ reverse 1 .. 40 ]
    , 'sort_via_array: probes came out in key order, each once';

    undef $sorted;

    flush;

    ok destroyed_once( 1 .. 40 )
    , 'sort_via_array: letting the sorted list go destroyed each payload exactly once';
}

done_testing
__END__
