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
use LinkedList::Single::Example::Handoff;

########################################################################
# tests
#
# payloads are destroyed when the queue lets go of them, no earlier and
# no later: at cancel, as a batch is processed, and not at all when
# items are only moved (take, requeue).
########################################################################

LinkedList::Single::Example::Probe->reset;

my $queue   = LinkedList::Single::Example::Handoff->new;

$queue->enqueue( LinkedList::Single::Example::Probe->new( $_ ) ) for 1 .. 10;

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [], 'Nothing destroyed yet';

# cancel destroys the item's payload at once.

ok $queue->cancel( 4 ), 'Cancelled item 4';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 4 ], 'Cancel destroyed payload 4 immediately';

ok ! $queue->cancel( 4 ), 'Cancelling it again finds nothing';

# taking moves nodes into a batch: nothing is destroyed.

my $batch   = $queue->take( 3 );

is $queue->left( $batch ), 3, 'Took three items (1, 2, 3; 4 is gone)';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 4 ], 'Take destroyed nothing';

# processing two of them lets those two go as the batch advances.

my @seen    = ();

my $done
= $queue->process
(
    $batch
  , sub( $id, $probe ) { push @seen, $probe->id }
  , 2
);

is $done, 2, 'Processed two items';

cmp_deeply \@seen, [ 1, 2 ], 'Handler saw 1 then 2';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 2, 4 ]
, 'Processed payloads destroyed as the batch advanced; item 3 still held';

is $queue->left( $batch ), 1, 'One item left in the batch';

# putting the rest back destroys nothing and the item is queued again.

is $queue->requeue( $batch ), 1, 'Requeued the one left over';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 2, 4 ], 'Requeue destroyed nothing';

cmp_deeply [ map { $_->[ 0 ] } $queue->contents->@* ], [ 3, 5 .. 10 ]
, 'Item 3 is back at the front, ahead of 5 .. 10';

ok $queue->cancel( 3 ), 'A requeued item can be cancelled';

# the requeue relinked the batch onto the queue (append_to moves no
# contents and holds no node afterwards), so cancelling the item
# destroys it at once. before append_to relinked, the node was the
# 'whence' of the last Fragment built and lived until the next one (the stale whence slot).

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 2, 3, 4 ]
, 'Payload 3 destroyed by that cancel';

# a batch that is never finished still lets go of its items when it is.

my $all     = $queue->drain;

is $queue->size, 0, 'Drained the rest';

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1, 2, 3, 4 ], 'Drain destroyed nothing';

$queue->process( $all, sub( @ ) { } );

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 10 ], 'Processing the rest destroyed the rest';

# the queue still works after being drained.

$queue->enqueue( LinkedList::Single::Example::Probe->new( 99 ) );
$queue->enqueue( LinkedList::Single::Example::Probe->new( 98 ) );

is $queue->size, 2, 'Queued again after the drain';

undef $queue;

# Stale whence: the module's ADJUST block keeps its last 'whence' argument alive
# until the next object of the same class is built, so the final list is
# not always released the moment the last reference goes. When that is
# fixed this test starts passing (and prove reports it as unexpectedly
# succeeded).

TODO:
{
    local $TODO = 'stale whence: ADJUST holds the last whence until the next object';

    cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 10, 98, 99 ]
    , 'Dropping the queue destroys what was left at once';
}

# building any later object lets go of it: one per class.

{
    my $flush   = LinkedList::Single->new;

    $flush->cursor;

    LinkedList::Single::Fragment->new;
}

cmp_deeply [ LinkedList::Single::Example::Probe->destroyed ], [ 1 .. 10, 98, 99 ]
, 'Dropping the queue destroys what was left (once later objects are built)';

done_testing
__END__
