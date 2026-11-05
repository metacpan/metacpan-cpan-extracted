########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Handoff;

########################################################################
# utility
########################################################################

# the real nodes of a chain, in order. the sentinel is not included.

sub chain( $node )
{
    my @node    = ();

    while( $node->@* )
    {
        push @node, $node;

        $node   = $node->[ 0 ];
    }

    @node
}

# what must be true of the queue after every operation. returns a list
# of the things that are not.
#
#   * the handle of every queued item, and only those, is in the index
#   * the cursor behind each handle stands on the node *before* the item
#   * 'last' stands on the final node, and the sentinel follows it
#   * the anchor is still the first node
#   * the size is what a walk counts

sub problems( $queue )
{
    my @node    = chain $queue->{ list }->node;
    my @bad     = ();

    my $anchor  = shift @node;

    refaddr $queue->{ anchor }->node == refaddr $anchor
    or push @bad, 'anchor cursor is not on the first node';

    my @id      = map { $_->[ 1 ] } @node;

    # eq_deeply is a plain boolean: cmp_deeply would run (and count) a
    # test of its own on every call.

    eq_deeply [ sort { $a <=> $b } keys $queue->{ pred }->%* ], [ sort { $a <=> $b } @id ]
    or push @bad, 'index holds other handles than the queued items';

    $queue->size == @id
    or push @bad, 'size is ' . $queue->size . ' but ' . @id . ' are queued';

    # each item's predecessor: node i-1 in the chain, with the anchor
    # standing in before the first.

    my @before  = ( $anchor, @node );

    for my $at ( 0 .. $#node )
    {
        my $pred    = $queue->{ pred }{ $id[ $at ] }
        or next;

        refaddr $pred->node == refaddr $before[ $at ]
        or push @bad, "handle $id[ $at ] does not stand on the node before its item";
    }

    my $final   = $before[ -1 ];

    refaddr $queue->{ last }->node == refaddr $final
    or push @bad, "'last' is not on the final node";

    $queue->{ last }->next
    and push @bad, "the node after 'last' is not the sentinel";

    @bad
}

sub invariants_ok( $queue, $label )
{
    my @bad = problems $queue;

    ok ! @bad, $label
    or diag join "\n", map { "  $_" } @bad;
}

# refaddrs of the nodes of a batch (a Fragment).

sub batch_nodes( $batch )
{
    $batch
    or return ();

    map { refaddr $_ } chain $batch->node
}

########################################################################
# tests
########################################################################

my $queue   = LinkedList::Single::Example::Handoff->new;

invariants_ok $queue, 'New queue';

$queue->enqueue( "job$_" ) for 1 .. 10;

invariants_ok $queue, 'After ten enqueues';

# cancel: front, middle, last, then something not there.

$queue->cancel( 1 );

invariants_ok $queue, 'After cancelling the first item';

$queue->cancel( 5 );

invariants_ok $queue, 'After cancelling a middle item';

$queue->cancel( 10 );

invariants_ok $queue, 'After cancelling the last item';

ok ! $queue->cancel( 10 ), 'Cancelling it twice finds nothing';

invariants_ok $queue, 'After a cancel that found nothing';

# the queue must go on accepting items after the last was cancelled.

$queue->enqueue( 'after-last' );

invariants_ok $queue, 'After enqueue behind a cancelled last item';

# take: fewer than the queue, then the batch shares nothing with it.

my $batch   = $queue->take( 3 );

invariants_ok $queue, 'After take of three';

{
    my %queued  = map { refaddr $_ => 1 } chain $queue->{ list }->node;

    ok ! grep( { $queued{ $_ } } batch_nodes $batch ), 'Batch shares no node with the queue';
}

# not-quite-all and exactly-all and more-than-all.

my $rest    = $queue->size;

my $big     = $queue->take( $rest - 1 );

invariants_ok $queue, 'After take of all but one';

is $queue->size, 1, 'One item left';

my $one     = $queue->take( 1 );

invariants_ok $queue, 'After take of exactly everything';

is $queue->size, 0, 'Queue empty';

$queue->enqueue( 'again' );

invariants_ok $queue, 'After enqueue into a queue that was taken empty';

my $over    = $queue->take( 50 );

invariants_ok $queue, 'After take of more than the queue held';

is $queue->left( $over ), 1, 'Got only what was there';

# requeue onto an empty queue, a short one, and a long one.

$queue->requeue( $over );

invariants_ok $queue, 'After requeue onto an empty queue';

ok ! $over, 'A requeued batch is spent (false)';

$queue->enqueue( "n$_" ) for 1 .. 3;

$queue->requeue( $batch );

invariants_ok $queue, 'After requeue in front of a short queue';

$queue->enqueue( "m$_" ) for 1 .. 20;

$queue->requeue( $big );

invariants_ok $queue, 'After requeue in front of a longer queue';

# a partly processed batch.

my $part    = $queue->take( 6 );

$queue->process( $part, sub( @ ) { }, 2 );

$queue->requeue( $part );

invariants_ok $queue, 'After take, partial process, requeue';

# drain, then reuse.

my $all     = $queue->drain;

invariants_ok $queue, 'After drain';

is $queue->size, 0, 'Drained queue empty';

$queue->enqueue( "z$_" ) for 1 .. 4;

invariants_ok $queue, 'After enqueue into a drained queue';

# a long random run, checking every step.

srand 20261030;

my $run     = LinkedList::Single::Example::Handoff->new;
my $out     = undef;
my $bad     = 0;

for my $i ( 1 .. 1_500 )
{
    my $roll    = rand;

    if( $roll < 0.45 )
    {
        $run->enqueue( $i );
    }
    elsif( $roll < 0.55 && ! $out )
    {
        $out    = $run->take( 1 + int rand 6 );
    }
    elsif( $roll < 0.58 && ! $out )
    {
        $out    = $run->drain;
    }
    elsif( $roll < 0.70 && $out )
    {
        $run->process( $out, sub( @ ) { }, int rand 4 );
    }
    elsif( $roll < 0.80 && $out )
    {
        $run->requeue( $out );

        $out    = undef;
    }
    else
    {
        $run->cancel( 1 + int rand $i );
    }

    problems $run
    and ++$bad
    and diag "Step $i: " . join '; ', problems $run
    and last;
}

is $bad, 0, 'Invariants held after every step of a random run';

done_testing
__END__
