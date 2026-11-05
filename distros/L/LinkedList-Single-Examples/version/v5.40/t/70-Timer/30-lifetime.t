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
use LinkedList::Single::Example::Timer;

########################################################################
# utility
########################################################################

# the ids of this test's probes that have been destroyed.

sub mine { LinkedList::Single::Example::Probe->destroyed }

# the module keeps the last argument given to an object of a class alive
# until the next object of that class is built (the stale whence slot). building one of each
# lets go of the stale ones.

sub flush
{
    my $list    = LinkedList::Single->new;

    $list->cursor;

    LinkedList::Single::Fragment->new;

    return
}

########################################################################
# tests
#
# a message that is dispatched is released as the batch moves past it:
# the queue keeps nothing of it. one the window cut off is kept, and
# put back, and released when it is dispatched in turn.
########################################################################

my $now     = 100;

LinkedList::Single::Example::Probe->reset;

my $queue
= LinkedList::Single::Example::Timer->new
(
    clock   => sub { $now }
  , window  => 10
);

$queue->enqueue( $_, LinkedList::Single::Example::Probe->new( $_ ) ) for 1 .. 6;

cmp_deeply [ mine() ], [], 'Six queued, nothing destroyed';

my $batch   = $queue->take( 4 );

is $queue->left( $batch ), 4, 'Four are due';

cmp_deeply [ mine() ], [], 'Taking a batch destroys nothing';

# dispatch two of them: the clock passes the deadline in the handler.

my $sent    = 0;

my $done
= $queue->process
(
    $batch
  , sub( $start, $probe ) { ++$sent; $now += 6 }
  , 110
);

is $done, 2, 'The window closed after two';

flush();

cmp_deeply [ mine() ], [ 1, 2 ], 'The two dispatched are released';

is $queue->left( $batch ), 2, 'Two are left in the batch';

# put back what is left: nothing is lost, nothing destroyed.

is $queue->requeue( $batch ), 2, 'Two put back';

flush();

cmp_deeply [ mine() ], [ 1, 2 ], 'Requeueing destroys nothing';

cmp_deeply [ map { $_->[ 0 ] } $queue->contents->@* ], [ 3 .. 6 ], 'Four queued in order';

# and they go when they are dispatched.

$now        = 200;

$batch      = $queue->take( 100 );

$queue->process( $batch, sub {} , 1_000 );

flush();

cmp_deeply [ mine() ], [ 1 .. 6 ], 'All six released once dispatched';

is $queue->size, 0, 'The queue is empty';

# the rest go with the queue. (stale whence: the last Fragment is not released at
# once.)

LinkedList::Single::Example::Probe->reset;

{
    my $q   = LinkedList::Single::Example::Timer->new( clock => sub { 0 } );

    $q->enqueue( $_, LinkedList::Single::Example::Probe->new( $_ ) ) for 11 .. 15;
}

flush();

cmp_deeply [ mine() ], [ 11 .. 15 ], 'Dropping the queue releases what it held';

done_testing
__END__
