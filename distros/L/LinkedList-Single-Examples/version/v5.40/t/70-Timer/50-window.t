########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Timer;
use LinkedList::Single::Example::Timer::Array;

########################################################################
# utility
########################################################################

my $now;

sub starts( $queue )
{
    [ map { $_->[ 0 ] } $queue->contents->@* ]
}

########################################################################
# tests
#
# each case is run on the list and on the array, with a clock that the
# handler moves, so the window closes when the case says and nothing
# sleeps.
########################################################################

for my $class ( qw( LinkedList::Single::Example::Timer LinkedList::Single::Example::Timer::Array ) )
{
    my $name    = $class =~ s{ \A LinkedList::Single::Example:: }{}rx;

    $now    = 1_000;

    my $queue
    = $class->new
    (
        clock   => sub { $now }
      , window  => 60
    );

    is $queue->window, 60, "$name: window";

    # nothing queued, nothing due.

    is $queue->take, undef, "$name: take on an empty queue";
    is $queue->process( undef, sub { die 'called' } ), 0, "$name: process of no batch";
    is $queue->requeue( undef ), 0, "$name: requeue of no batch";

    $queue->enqueue( $_, "m$_" ) for 1_100, 1_200;

    is $queue->take, undef, "$name: nothing due yet";
    is $queue->size, 2, "$name: nothing was taken";

    # in start order: no walking at all.

    is $queue->walked, 0, "$name: messages in start order are not searched for";

    # ten due messages; the handler spends 7 seconds on each, so a window
    # of 60 seconds dispatches nine of them.

    $queue = $class->new( clock => sub { $now }, window => 60 );

    $queue->enqueue( 900 + $_, "m$_" ) for 1 .. 10;
    $queue->enqueue( 2_000, 'later' );

    my @sent    = ();
    my $batch   = $queue->take;

    is $queue->left( $batch ), 10, "$name: ten are due";
    is $queue->size, 1, "$name: one is left in the queue";

    my $done
    = $queue->process
    (
        $batch
      , sub( $start, $msg ) { push @sent, $msg; $now += 7 }
    );

    is $done, 9, "$name: nine fit in the window (the tenth would start at 63)";

    cmp_deeply \@sent, [ map { "m$_" } 1 .. 9 ], "$name: dispatched in order";

    is $queue->left( $batch ), 1, "$name: one left in the batch";

    is $queue->requeue( $batch ), 1, "$name: one put back";
    is $queue->merged, 0, "$name: put back in front, without a merge";

    cmp_deeply starts( $queue ), [ 910, 2_000 ], "$name: in front of what was queued";

    is $queue->next_start, 910, "$name: the next to start";

    # the next round picks up where the last stopped.

    @sent   = ();

    $batch  = $queue->take;

    $queue->process( $batch, sub( $start, $msg ) { push @sent, $msg } );

    cmp_deeply \@sent, [ 'm10' ], "$name: the next round starts with the one left over";

    is $queue->requeue( $batch ), 0, "$name: nothing to put back from a used-up batch";

    cmp_deeply starts( $queue ), [ 2_000 ], "$name: the future message is untouched";

    # the whole queue is due and the window cuts it: the queue was
    # empty, so the part put back is all of it, and later messages go
    # after it without a search.

    $queue = $class->new( clock => sub { $now }, window => 5 );

    $queue->enqueue( 100 + $_, "n$_" ) for 1 .. 6;

    $batch  = $queue->take;

    is $queue->size, 0, "$name: the queue was emptied";

    $queue->process( $batch, sub { $now += 3 } );

    is $queue->left( $batch ), 4, "$name: two dispatched in a window of 5";

    $queue->requeue( $batch );

    $queue->enqueue( 5_000, 'tail' );
    $queue->enqueue( 5_001, 'tail2' );

    cmp_deeply starts( $queue ), [ 103 .. 106, 5_000, 5_001 ], "$name: the put-back part is first, new ones follow";
    # a late arrival while the batch is out: a message whose start has
    # passed but is after some in the batch must go between them.

    $queue = $class->new( clock => sub { $now }, window => 100 );

    $queue->enqueue( $_, "p$_" ) for 10, 20, 30, 40;

    $batch  = $queue->take( 40 );

    $queue->enqueue( 25, 'late' );
    $queue->enqueue( 45, 'future' );

    cmp_deeply starts( $queue ), [ 25, 45 ], "$name: late arrivals queue in start order";

    is $queue->process( $batch, sub {}, 0 ), 0, "$name: a window already closed dispatches nothing";

    $queue->requeue( $batch );

    cmp_deeply starts( $queue ), [ 10, 20, 25, 30, 40, 45 ], "$name: the batch is merged around the late arrival";
    is $queue->merged, 4, "$name: four messages put back one at a time";

    # a batch whose latest start equals the head of the queue still goes
    # back in front, without a merge: the order is already right.

    $queue = $class->new( clock => sub { $now } );

    $queue->enqueue( 10, 'x' );
    $queue->enqueue( 20, 'y' );

    $batch  = $queue->take( 10 );

    $queue->enqueue( 10, 'z' );

    $queue->requeue( $batch );

    is $queue->merged, 0, "$name: a tie at the head is put back in front";

    cmp_deeply $queue->contents, [ [ 10, 'x' ], [ 10, 'z' ], [ 20, 'y' ] ]
    , "$name: ... with the older message first";

    # ties: the earlier message goes first.

    $queue = $class->new;

    $queue->enqueue( 5, 'a' );
    $queue->enqueue( 5, 'b' );
    $queue->enqueue( 3, 'c' );
    $queue->enqueue( 5, 'd' );

    cmp_deeply $queue->contents
    , [ [ 3, 'c' ], [ 5, 'a' ], [ 5, 'b' ], [ 5, 'd' ] ]
    , "$name: equal starts keep arrival order";

    # a handler that dies stops the batch where it was.

    $now    = 0;

    $queue  = $class->new( clock => sub { $now } );

    $queue->enqueue( $_, "e$_" ) for 1 .. 4;

    $batch  = $queue->take( 10 );

    my @warn    = ();

    {
        local $SIG{__WARN__}    = sub { push @warn, @_ };

        $queue->process
        (
            $batch
          , sub( $start, $msg ) { $msg eq 'e3' and die "boom\n" }
          , 100
        );
    }

    ok scalar @warn, "$name: the failure was reported";

    is $queue->left( $batch ), 2, "$name: it stopped on the message that failed";

    $queue->requeue( $batch );

    cmp_deeply starts( $queue ), [ 3, 4 ], "$name: the failed message is queued again";
}

done_testing
__END__
