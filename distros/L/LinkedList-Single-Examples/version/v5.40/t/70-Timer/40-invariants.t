########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Scalar::Util    qw( refaddr );

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::Timer;

########################################################################
# utility
########################################################################

# what must be true of the queue after every operation. returns a list
# of the things that are not.
#
#   * the anchor is the first node of the list and holds -inf
#   * the starts are in order (not decreasing) through the whole list
#   * the size is the number of messages
#   * 'last' stands on the last node of the list, and 'latest' is its
#     start (or -inf, with 'last' on the anchor, when it is empty)
#
# read through cursors; nothing is unwrapped.

sub problems( $queue )
{
    my @problem = ();
    my $anchor  = $queue->{ anchor };
    my $curs    = $queue->{ list }->cursor;

    refaddr $curs->node == refaddr $anchor->node
    or push @problem, 'the list does not begin at the anchor';

    my @start   = ();
    my $end     = $curs->node;

    while( $curs )
    {
        push @start, ( $curs->data )[ 0 ];

        $end    = $curs->node;

        $curs->advance;
    }

    shift( @start ) == -9**9**9
    or push @problem, 'the anchor does not hold -inf';

    for my $i ( 1 .. $#start )
    {
        $start[ $i - 1 ] <= $start[ $i ]
        or push @problem, "the starts decrease at message $i";
    }

    @start == $queue->size
    or push @problem, 'size ' . $queue->size . ' but ' . @start . ' messages';

    refaddr $queue->{ last }->node == refaddr $end
    or push @problem, "'last' is not the last node";

    my $latest  = @start ? $start[ -1 ] : -9**9**9;

    $queue->{ latest } == $latest
    or push @problem, "'latest' is $queue->{ latest }, not $latest";

    @problem
}

########################################################################
# tests
########################################################################

srand 20261031;

my $now     = 500;

my $queue   = LinkedList::Single::Example::Timer->new( clock => sub { $now }, window => 10 );
my $batch;

is_deeply [ problems( $queue ) ], [], 'A new queue is sound';

my $bad = 0;

for my $step ( 1 .. 1_500 )
{
    my $op  = int rand 10;

    if( $op < 5 )
    {
        $queue->enqueue( $now - 30 + int rand 100, "m$step" );
    }
    elsif( $op < 7 && ! $batch )
    {
        $batch  = $queue->take( $now + int rand 30 );
    }
    elsif( $op < 9 )
    {
        $batch
        and $queue->process( $batch, sub { $now += 2 }, $now + 1 + int rand 8 );
    }
    else
    {
        $batch
        and $queue->requeue( $batch );

        $batch  = undef;
    }

    my @problem = problems( $queue );

    @problem
    or next;

    fail "step $step: " . join '; ' => @problem;
    $bad++;
    last;
}

$bad
or pass 'Sound after every one of 1500 operations';

# the case the random schedule seldom reaches: the whole queue is taken,
# the window cuts it, and the unused part is the only thing queued. 'last'
# has to be on the end of it, or every later append would search for the
# end of the list.

{
    my $q   = LinkedList::Single::Example::Timer->new( clock => sub { 0 }, window => 5 );

    $q->enqueue( $_, "w$_" ) for 1 .. 6;

    my $b   = $q->take( 100 );

    is_deeply [ problems( $q ) ], [], 'Sound with the whole queue taken';

    $q->process( $b, sub { }, -1 );
    $q->requeue( $b );

    is_deeply [ problems( $q ) ], [], 'Sound after the whole queue is put back';

    $q->enqueue( 50, 'after' );

    is_deeply [ problems( $q ) ], [], 'Sound after an append behind the put-back part';
    is $q->walked, 6, 'Six nodes walked for the cut and none for the append';
}

# nothing was lost between the queue and the batch that was left out.

$batch
and $queue->requeue( $batch );

is_deeply [ problems( $queue ) ], [], 'Sound at the end';

done_testing
__END__
