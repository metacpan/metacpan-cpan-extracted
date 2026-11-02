use v5.36;
use strict;
use warnings;

# Direct entry-point comparison on the same build. The native path runs the
# original epoll driver; the public path adds the deferred-fork scheduling
# boundary. No actual fork is requested by these measurements.
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Linux::Event::Loop;

my $count = $ENV{LOOP_BENCH_CALLS} // 300_000;
my $repeat = $ENV{LOOP_BENCH_REPEATS} // 9;
die "LOOP_BENCH_CALLS must be positive\n" unless $count =~ /\A[1-9][0-9]*\z/;
die "LOOP_BENCH_REPEATS must be positive\n" unless $repeat =~ /\A[1-9][0-9]*\z/;

sub median (@items) {
    @items = sort { $a <=> $b } @items;
    return $items[int(@items / 2)] if @items % 2;
    return ($items[@items / 2 - 1] + $items[@items / 2]) / 2;
}

sub measure ($loop, $method, $calls, $with_timeout) {
    my $start = clock_gettime(CLOCK_MONOTONIC);
    if ($with_timeout) {
        $loop->$method(0) for 1 .. $calls;
    }
    else {
        $loop->$method() for 1 .. $calls;
    }
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $start;
    return $elapsed * 1_000_000_000 / $calls;
}

say "Deferred-fork driver boundary overhead";
say "Perl $] pid $$, calls per sample=$count, repeat=$repeat";
say "Values are median wall-clock nanoseconds per call; lower is better.";
say "No callbacks or deferred forks are scheduled in this benchmark.";
say "";

for my $pair (
    [ 'poll', 'poll', '_poll_native', 0 ],
    [ 'run_once(0)', 'run_once', '_run_once_native', 1 ],
) {
    my ($name, $public, $native, $with_timeout) = @$pair;
    my $loop = Linux::Event::Loop->new;

    # Warm up Perl method lookup and kernel entry points.
    measure($loop, $public, 5_000, $with_timeout);
    measure($loop, $native, 5_000, $with_timeout);

    my (@public_ns, @native_ns);
    for my $i (0 .. $repeat - 1) {
        my @order = $i % 2
            ? ([ 'public', $public ], [ 'native', $native ])
            : ([ 'native', $native ], [ 'public', $public ]);
        for my $entry (@order) {
            my ($kind, $method) = @$entry;
            my $ns = measure($loop, $method, $count, $with_timeout);
            push @{ $kind eq 'public' ? \@public_ns : \@native_ns }, $ns;
        }
    }

    my $native_median = median(@native_ns);
    my $public_median = median(@public_ns);
    my $delta = $public_median - $native_median;
    printf "%-15s native %9.1f ns   public %9.1f ns   difference %+9.1f ns (%+.1f%%)\n",
        $name, $native_median, $public_median, $delta,
        $native_median > 0 ? 100 * $delta / $native_median : 0;
}
