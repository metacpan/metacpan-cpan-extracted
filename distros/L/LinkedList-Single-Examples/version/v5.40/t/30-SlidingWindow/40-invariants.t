########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::SlidingWindow;

########################################################################
# utility
########################################################################

# the tail cursor must always stand on the sentinel that ends the
# list, otherwise the next record lands in the wrong place.

sub last_node( $list )
{
    my $node    = $list->node;

    $node       = $node->[0] while $node->@*;

    $node
}

sub tail_ok( $window, $label )
{
    my $tail    = $window->{ tail }->node;
    my $last    = last_node $window->{ list };

    is refaddr $tail, refaddr $last, "$label: tail stands on the list's sentinel";
}

########################################################################
# tests
########################################################################

my $window  = LinkedList::Single::Example::SlidingWindow->new( span => 10 );

tail_ok $window, 'New window';

$window->record( $_ ) for 1 .. 10;

tail_ok $window, 'After records';

$window->expire( 15 );

tail_ok $window, 'After partial expire';

cmp_deeply $window->contents, [ map { [ $_ ] } 5 .. 10 ]
, 'Partial expire kept 5 .. 10 (time 5 is not older than the cutoff)';

$window->expire( 100 );

tail_ok $window, 'After expiring everything';

is $window->size, 0, 'Empty';

$window->record( 200 );
$window->record( 201 );

tail_ok $window, 'After recording into an emptied window';

cmp_deeply $window->contents, [ [ 200 ], [ 201 ] ], 'Window refilled';

# repeated cycles: the cursor must not drift.

for my $cycle ( 1 .. 50 )
{
    $window->record( 300 + $cycle );
    $window->expire( 300 + $cycle + ( $cycle % 7 ) );
}

tail_ok $window, 'After 50 record/expire cycles';

# expire on an empty window is harmless.

my $empty   = LinkedList::Single::Example::SlidingWindow->new( span => 1 );

is $empty->expire( 100 ), 0, 'Expire on an empty window drops nothing';

tail_ok $empty, 'Empty window after expire';

done_testing
__END__
