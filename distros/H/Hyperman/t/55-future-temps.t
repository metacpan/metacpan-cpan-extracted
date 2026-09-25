#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use Hyperman;
use Hyperman::Loop;

# A resolved Future, and every callback attached to it, must be released
# while the loop is still running.
#
# hmf_pump mortalises the (callback, future) pair it drains. Without a temps
# frame of its own it hangs them on whichever frame it was entered from, and
# for a timer that frame is the worker's event loop - which does not return
# while the server is up. Everything ever resolved is then held for the life
# of the process.
#
# The shape that finds it is the one every clock in an application has: a
# timer whose callback schedules the next timer, with nobody keeping a
# reference to any of them.
#
# Measured by a CANARY captured in each callback, and counted DURING the
# run. Both halves matter. After the loop returns the frame has been left
# and the evidence is gone, which is what let this survive - it is invisible
# to any test that looks once the loop is over. And a canary asks the
# question an application actually cares about, which is whether the thing
# the callback closed over is freed, rather than requiring a heap walker.
#
# Found 24 Sep 2026 on peer2peergames, where an arbiter re-arming at 25Hz
# had accumulated 1,157,536 live Futures and 2.3 million CODE in one worker.

our $DESTROYED = 0;
{
    package T55::Canary;
    sub new { return bless {}, shift }
    sub DESTROY { $main::DESTROYED++ }
}

my $TICKS = 2000;
my $PROBE = 500;

my $loop = Hyperman::Loop->new;
# Never fires: run_until wants a Future, and the loop is stopped by hand.
my $never = $loop->timer_f(3600);

my @seen;
my $n = 0;
my $step;
$step = sub {
    $n++;
    push @seen, [ $n, $DESTROYED ] unless $n % $PROBE;
    if ($n >= $TICKS) { $loop->stop; return }
    my $canary = T55::Canary->new;
    $loop->timer_f(0)->on_done(sub {
        my $held = $canary;     # the callback closes over it
        $step->();
    });
};
$step->();
$loop->run_until($never);

is $n, $TICKS, "ran $TICKS timer futures";
cmp_ok scalar @seen, '>=', 2, 'took at least two readings during the run';

# The canaries have to be dying AS THE LOOP RUNS. Leaked, the count stays
# at or near zero however long it runs; released, it tracks the ticks.
my ($first, $last) = ($seen[0], $seen[-1]);
my $ticks_between = $last->[0] - $first->[0];
my $freed_between = $last->[1] - $first->[1];

cmp_ok $freed_between, '>', $ticks_between * 0.9,
    sprintf 'callbacks are released during the run (%d of %d ticks freed between readings)',
            $freed_between, $ticks_between;

diag sprintf 'after %5d ticks: %d callbacks freed', @$_ for @seen;

done_testing;
