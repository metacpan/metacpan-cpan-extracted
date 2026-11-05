########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Latency v2.0.0;
use v5.40;

use Exporter        qw( import );
use Time::HiRes     qw( clock_gettime CLOCK_MONOTONIC CLOCK_THREAD_CPUTIME_ID );

our @EXPORT_OK
= qw
(
    clock_floor
    clock_name
    in_child
    sample
    summary
    row
    tick
);

########################################################################
# why this is not best_of(): an average hides exactly what a latency
# bound is about. every call is timed on its own, and what is reported is
# how the calls are distributed (median, 99th, 99.9th percentile) and the
# one slowest call, with its position in the run so that a spike can be
# traced to what happened there (a reallocation, a split).
#
# the samples go into an array that has been extended to its final size
# before the first call is timed, so that the harness does not grow an
# array in the middle of a measurement and report it as the code's.
# the clock is monotonic.
########################################################################

########################################################################
# the clock. wall time includes every moment the process is not running:
# the scheduler takes the cpu from it, and the longest call in any run is
# then a measure of the machine and not of the code (the empty loop
# below shows it: its slowest call is hundreds of microseconds). the
# default is the time this thread is actually running, which still counts
# a page fault, a reallocation or a memmove, and leaves out being
# descheduled. LATENCY_CLOCK=wall selects wall time.
########################################################################

my $wall    = ( $ENV{ LATENCY_CLOCK } // '' ) eq 'wall';

my $clock   = $wall ? CLOCK_MONOTONIC : CLOCK_THREAD_CPUTIME_ID;

sub tick()
{
    clock_gettime( $clock )
}

sub clock_name()
{
    $wall ? 'wall clock' : 'thread cpu time'
}

# time $count calls of $code->( $i ) one by one. returns the list of
# seconds taken.

sub sample( $count, $code )
{
    my @took;

    $#took  = $count - 1;

    for my $i ( 0 .. $count - 1 )
    {
        my $t0  = tick();

        $code->( $i );

        $took[ $i ] = tick() - $t0;
    }

    \@took
}

# what the timing itself costs: the same loop around an empty call.
# the median of this is the smallest number any report can show.

sub clock_floor( $count = 200_000 )
{
    my $took    = sample( $count, sub {} );

    summary( $took )
}

# percentiles, the slowest call and where it was, in microseconds.

sub summary( $took )
{
    my @order   = sort { $a <=> $b } @$took;
    my $count   = @order;

    my $at
    = sub( $fraction )
    {
        $order[ int( $fraction * ( $count - 1 ) ) ]
    };

    # the position of the slowest call.

    my $slow    = 0;

    $took->[ $_ ] > $took->[ $slow ]
    and $slow = $_
    for 0 .. $#$took;

    my $total   = 0;

    $total  += $_ for @order;

    return
    {
        count   => $count
      , mean    => 1e6 * $total / $count
      , p50     => 1e6 * $at->( 0.50  )
      , p99     => 1e6 * $at->( 0.99  )
      , p999    => 1e6 * $at->( 0.999 )
      , max     => 1e6 * $order[ -1 ]
      , at      => $slow
    }
}

# $code run in a child process, which returns what it prints on one
# line: the numbers come back as a list. perl does not give freed heap
# back, so a run that follows another in the same process starts from
# the other's high-water mark; each case gets a process of its own.

sub in_child( $code )
{
    pipe my $r, my $w
    or die "Botched pipe: $!\n";

    my $pid = fork // die "Botched fork: $!\n";

    if( ! $pid )
    {
        close $r;

        say $w join ' ' => $code->();

        close $w;

        exit 0;
    }

    close $w;

    my $line    = <$r>;

    close $r;
    waitpid $pid, 0;

    defined $line
    or die "Botched child: no result\n";

    chomp $line;

    split ' ', $line
}

# one table row: the name and the five numbers of a summary.

sub row( $name, $s )
{
    sprintf '%-18s %9.2f %9.2f %9.2f %9.2f %11.1f %9d'
    =>  $name
      , $s->@{ qw( mean p50 p99 p999 max at ) }
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Latency - per-call timing for the examples: percentiles, the worst call, and where it was

=head1 SYNOPSIS

    use LinkedList::Single::Example::Latency qw( sample summary clock_floor in_child );

    my $took    = sample( 100_000, sub( $i ) { $queue->enqueue( $i, 'job' ) } );
    my $s       = summary( $took );        # mean p50 p99 p999 max (us), at

=head1 DESCRIPTION

The examples' C<best_of> reports the best of a few runs, which is the
right number for an average and the wrong one for a bound. These
helpers time each call, and report the spread.
