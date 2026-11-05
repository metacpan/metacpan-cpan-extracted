########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;

use LinkedList::Single::Example::Handoff;
use LinkedList::Single::Example::Handoff::Array;

########################################################################
# tests
#
# what is done while the lock is held, counted rather than timed (a
# timing test would be flaky): 'walked' is the nodes (list) or elements
# (array) that the implementation steps over one at a time.
#
# the point is which operations depend on the length of the queue.
########################################################################

my $n       = 2_000;
my $k       = 10;

for my $short ( 100, $n )
{
    my $list    = LinkedList::Single::Example::Handoff->new;
    my $swap    = LinkedList::Single::Example::Handoff::Array->new( drain => 'swap' );
    my $copy    = LinkedList::Single::Example::Handoff::Array->new( drain => 'copy' );

    $list->enqueue( $_ ) for 1 .. $short;
    $swap->enqueue( $_ ) for 1 .. $short;
    $copy->enqueue( $_ ) for 1 .. $short;

    is $list->walked, 0, "List ($short items): enqueue walks nothing";

    # cancel an item from near the back.

    my $id      = $short - 2;

    $list->cancel( $id );
    $swap->cancel( $id );

    is $list->walked, 0, "List ($short items): cancel walks nothing";

    is $swap->walked, $id
    , "Array ($short items): cancel looked at the $id items up to and including its own";

    # take a bounded batch: the list walks k (and two more to fix up
    # the handles at the cut); the array copies k.

    $list->take( $k );
    $swap->take( $k );

    is $list->walked, $k + 2, "List ($short items): take of $k walks $k + 2";
    is $swap->walked, $id + $k, "Array ($short items): take of $k touches $k more";

    # drain: the list walks nothing but retires its index; the
    # swap touches nothing and has no index; the copy copies it all.

    my $before  = $list->walked;
    my $left    = $list->size;

    $list->drain;

    is $list->walked, $before, "List ($short items): drain walks nothing";
    is $list->purged, $left, "List ($short items): drain retires an index entry per item (freed after the lock)";

    $copy->drain;

    is $copy->walked, $short, "Array copy ($short items): drain copies every item";

    my $touched = $swap->walked;

    $swap->drain;

    is $swap->walked, $touched, "Array swap ($short items): drain touches nothing";
}

done_testing
__END__
