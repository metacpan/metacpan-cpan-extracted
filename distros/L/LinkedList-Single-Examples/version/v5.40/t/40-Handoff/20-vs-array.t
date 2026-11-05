########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Handoff;
use LinkedList::Single::Example::Handoff::Array;
use LinkedList::Single::Example::Handoff::Marked;

########################################################################
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261030;

my $steps   = 3_000;

########################################################################
# tests
#
# drive the list queue and the three array queues with the same
# random schedule of enqueue / take / drain / process / requeue /
# cancel. the array queue is the oracle: every result, every item
# processed, and the whole contents of the queue must agree after every
# step.
########################################################################

# one implementation under test: a name, its queue, and (once taken)
# the batch it is holding.

sub impl( $name, $queue )
{
    return
    {
        name    => $name
      , queue   => $queue
    };
}

my @impl
= (
    impl( 'list',       LinkedList::Single::Example::Handoff->new )
  , impl( 'array-swap', LinkedList::Single::Example::Handoff::Array->new( drain => 'swap' ) )
  , impl( 'array-copy', LinkedList::Single::Example::Handoff::Array->new( drain => 'copy' ) )
  , impl( 'array-mark', LinkedList::Single::Example::Handoff::Marked->new )
);

# $each->( sub( $queue, $state ) {...} ) runs the same step on each
# implementation and returns what each of them said.

my $each
= sub( $code )
{
    [ map { $code->( $_->{ queue }, $_ ) } @impl ]
};

my %count
= map { $_ => 0 } qw( enqueue take drain process requeue cancel cancelled );

my $bad     = 0;

# the queue's items as one string.

my $flat
= sub( $queue )
{
    join '|', map { join ',', map { $_ // '' } $_->@* } $queue->contents->@*
};

for my $i ( 1 .. $steps )
{
    my $roll    = rand;
    my $result  = undef;

    if( $roll < 0.42 )
    {
        ++$count{ enqueue };

        $result
        = $each->
        (
            sub( $q, $s )
            {
                $q->enqueue( "job$i", $i )
            }
        );
    }
    elsif( $roll < 0.55 && ! $impl[ 0 ]{ batch } )
    {
        ++$count{ take };

        my $k   = 1 + int rand 8;

        $result
        = $each->
        (
            sub( $q, $s )
            {
                $s->{ batch }   = $q->take( $k );

                $q->left( $s->{ batch } )
            }
        );
    }
    elsif( $roll < 0.60 && ! $impl[ 0 ]{ batch } )
    {
        ++$count{ drain };

        $result
        = $each->
        (
            sub( $q, $s )
            {
                $s->{ batch }   = $q->drain;

                $q->left( $s->{ batch } )
            }
        );
    }
    elsif( $roll < 0.75 && $impl[ 0 ]{ batch } )
    {
        ++$count{ process };

        my $limit   = int rand 5;

        $result
        = $each->
        (
            sub( $q, $s )
            {
                my @seen    = ();

                my $done
                = $q->process
                (
                    $s->{ batch }
                  , sub( $id, @ ) { push @seen, $id }
                  , $limit
                );

                [ $done, \@seen, $q->left( $s->{ batch } ) ]
            }
        );
    }
    elsif( $roll < 0.85 && $impl[ 0 ]{ batch } )
    {
        ++$count{ requeue };

        $result
        = $each->
        (
            sub( $q, $s )
            {
                my $back    = $q->requeue( $s->{ batch } );

                delete $s->{ batch };

                $back
            }
        );
    }
    else
    {
        # ids from the whole range ever issued: queued, taken,
        # already cancelled, and not yet issued.

        ++$count{ cancel };

        my $id  = 1 + int rand( $count{ enqueue } + 3 );

        $result
        = $each->
        (
            sub( $q, $s )
            {
                $q->cancel( $id )
            }
        );

        $count{ cancelled } += $result->[ 0 ];
    }

    # all four implementations must have said the same thing.

    for my $n ( 1 .. $#impl )
    {
        eq_deeply $result->[ $n ], $result->[ 0 ]
        and next;

        ++$bad;

        cmp_deeply $result->[ $n ], $result->[ 0 ]
        , "Step $i: $impl[ $n ]{ name } result matches";
    }

    # and hold the same queue. comparing a flattened string is
    # cheap enough to do after every step; the deep comparison is
    # only for reporting what differed.

    for my $n ( 1 .. $#impl )
    {
        my $want    = $flat->( $impl[ 0 ]{ queue } );
        my $have    = $flat->( $impl[ $n ]{ queue } );

        $want eq $have
        and $impl[ $n ]{ queue }->size == $impl[ 0 ]{ queue }->size
        and next;

        ++$bad;

        cmp_deeply $impl[ $n ]{ queue }->contents, $impl[ 0 ]{ queue }->contents
        , "Step $i: $impl[ $n ]{ name } contents match";
    }

    $bad
    and last;
}

is $bad, 0, 'No mismatches against the array queues';

ok $count{ $_ } > 20, "The schedule exercised $_ ($count{ $_ } times)"
for qw( enqueue take drain process requeue cancel cancelled );

done_testing
__END__
