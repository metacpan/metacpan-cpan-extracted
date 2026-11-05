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
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261031;

my $steps   = 2_500;

########################################################################
# tests
#
# one random schedule of enqueue (in order, out of order, and with ties)
# / take / process (with a window that closes part way) / requeue, with
# late arrivals while a batch is out, driven through the list queue and
# the array queue. the array queue is the oracle: what each says, what
# is dispatched, and the whole contents must agree after every step.
#
# the clock is a variable. the handler moves it, so the window closes
# after a chosen number of messages and nothing sleeps.
########################################################################

my $now     = 1_000;

my $clock   = sub { $now };

my @impl
= map
  {
      {
          name      => $_->[ 0 ]
        , queue     => $_->[ 1 ]->new( clock => $clock, window => 10 )
        , batch     => undef
        , sent      => []
      }
  }
  [ list  => 'LinkedList::Single::Example::Timer'        ]
, [ array => 'LinkedList::Single::Example::Timer::Array' ]
;

my( $list, $array ) = @impl;

my %seen    = ();
my $serial  = 0;
my $bad     = 0;

# the messages are [ $start, 'm<serial>' ]; the serial makes ties
# visible, since the order of equal starts must agree too.

STEP:
for my $step ( 1 .. $steps )
{
    my $op  = int rand 100;

    my $what;

    if( $op < 40 )
    {
        # enqueue: half in order (a start at or after the latest queued),
        # the rest anywhere from long past to well ahead, and often a tie.

        my $start
        = ( rand() < 0.5 )
        ? $now + int rand 200
        : $now - 50 + int rand 300
        ;

        my $msg = 'm' . ++$serial;

        $_->{ queue }->enqueue( $start, $msg ) for @impl;

        $what   = "enqueue $start $msg";
        $seen{ enqueue }++;
    }
    elsif( $op < 55 )
    {
        # take, only when no batch is out (one dispatcher).

        $list->{ batch }
        and next STEP;

        my $at  = $now + int rand 40;

        $now   += int rand 5;

        for my $i ( @impl )
        {
            $i->{ batch }   = $i->{ queue }->take( $at );
        }

        $what   = "take $at";
        $seen{ take }++;

        is defined $list->{ batch }, defined $array->{ batch }, "$step $what: same answer"
        or $bad++;

        $list->{ batch }
        and is $list->{ queue }->left( $list->{ batch } )
        ,      $array->{ queue }->left( $array->{ batch } )
        ,      "$step $what: same count"
        and $seen{ taken }++;
    }
    elsif( $op < 80 )
    {
        # process, with a window of 1-4 messages: the handler advances
        # the clock by 3, and the window is 10.

        $list->{ batch }
        or next STEP;

        my $start   = $now;
        my @done    = ();

        for my $i ( @impl )
        {
            $now    = $start;
            $i->{ sent }    = [];

            my $sent    = $i->{ sent };

            $i->{ done }
            = $i->{ queue }->process
            (
                $i->{ batch }
              , sub( @msg ) { push @$sent, [ @msg ]; $now += 3 }
              , $start + 10
            );
        }

        $what   = "process";
        $seen{ process }++;

        is $list->{ done }, $array->{ done }, "$step $what: same count dispatched"
        or $bad++;

        cmp_deeply $list->{ sent }, $array->{ sent }, "$step $what: same messages"
        or $bad++;

        $list->{ done} < $list->{ queue }->left( $list->{ batch } ) + $list->{ done }
        and $seen{ cut_short }++;
    }
    elsif( $op < 95 )
    {
        $list->{ batch }
        or next STEP;

        my @back    = map { $_->{ queue }->requeue( $_->{ batch } ) } @impl;

        $_->{ batch }   = undef for @impl;

        $what   = "requeue";
        $seen{ requeue }++;

        is $back[ 0 ], $back[ 1 ], "$step $what: same count put back"
        or $bad++;

        $list->{ queue }->merged
        and $seen{ merged }++;
    }
    else
    {
        # time passes.

        $now   += int rand 30;

        $what   = 'tick';
    }

    cmp_deeply $list->{ queue }->contents, $array->{ queue }->contents, "$step $what: same queue"
    or $bad++;

    is $list->{ queue }->size, $array->{ queue }->size, "$step $what: same size"
    or $bad++;

    $bad
    and last STEP;
}

# the stream has to have exercised the interesting parts: a batch cut
# short by its window, put back in front, and put back by merging.

ok $seen{ enqueue }, 'Enqueued';
ok $seen{ take },    'Took batches';
ok $seen{ process }, 'Processed batches';
ok $seen{ cut_short }, 'Some batches were cut short by the window';
ok $seen{ requeue }, 'Requeued batches';
ok $list->{ queue }->merged, 'Late arrivals forced merges';

is $list->{ queue }->merged, $array->{ queue }->merged, 'Both merged the same number of messages';

ok $list->{ queue }->walked > 0, 'The list walked for out-of-order messages';

done_testing
__END__
