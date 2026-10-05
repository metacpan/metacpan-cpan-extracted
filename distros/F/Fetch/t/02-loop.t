#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Fetch;

plan tests => 12;

# ---- backend selection ---------------------------------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    ok($loop->backend, 'a readiness backend was selected (' . $loop->backend . ')');
}

# ---- timer resolves a future via run_until -------------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    my $f = Fetch::Future->new;
    my $fired = 0;
    $loop->timer(0.02, sub { $fired++; $f->done('tick') });
    $loop->run_until($f);
    is($fired, 1, 'timer fired exactly once');
    is(scalar($f->get), 'tick', 'run_until pumped until the future resolved');
}

# ---- stop ----------------------------------------------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    my $n = 0;
    $loop->timer(0.01, sub { $n++; $loop->stop });
    $loop->run;
    is($n, 1, 'run returns after stop');
}

# ---- install_await: bare ->get pumps the loop ----------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    $loop->install_await;
    my $f = Fetch::Future->new;
    $loop->timer(0.02, sub { $f->done('awaited') });
    is(scalar($f->get), 'awaited', 'bare get pumps the loop via $AWAIT');
}

# ---- watch_io: fd readiness fires the callback ---------------------------
{
    pipe(my $r, my $w) or die "pipe: $!";
    my $loop = Fetch::Loop::Standalone->new;
    my $got  = Fetch::Future->new;
    $loop->watch_io($r, 'r', sub {
        my $buf; sysread($r, $buf, 16);
        $loop->unwatch_io($r, 'r');
        $got->done($buf);
    });
    syswrite($w, "hello");
    $loop->run_until($got);
    is(scalar($got->get), 'hello', 'watch_io read callback fired with the data');
}

# ---- many timers all resolve --------------------------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    my @f = map { Fetch::Future->new } 1 .. 10;
    $loop->timer(0.001 * $_, do { my $i = $_; sub { $f[$i-1]->done($i) } }) for 1 .. 10;
    my $all = Fetch::Future->needs_all(@f);
    $loop->run_until($all);
    ok($all->is_done, 'ten timers each resolved their future');
    is_deeply([map { scalar $_->get } @f], [1 .. 10], 'all values correct');
}

# ---- a timer never fires before its deadline -----------------------------
# The kernel's timer is not the deadline. NetBSD's kqueue schedules
# EVFILT_TIMER in scheduler ticks and, in a VM, delivered a 300ms timer at
# 246ms; the loop re-arms an early oneshot for the remainder of `due`,
# measured on the same monotonic clock as here. Every backend this build
# has gets the same pin; within a millisecond is the backends' rounding.
{
    my $now = eval {
        my $clk = Time::HiRes::CLOCK_MONOTONIC();
        Time::HiRes::clock_gettime($clk);
        sub { Time::HiRes::clock_gettime($clk) };
    } || \&Time::HiRes::time;
    for my $name (qw(kqueue epoll io_uring poll)) {
      SKIP: {
            my $loop = eval { Fetch::Loop::Standalone->new($name) };
            skip "no $name backend in this build", 1 unless $loop;
            my $f  = Fetch::Future->new;
            my $t0 = $now->();
            $loop->timer(0.05, sub { $f->done($now->() - $t0) });
            $loop->run_until($f);
            cmp_ok(scalar($f->get), '>=', 0.05 - 1e-3,
                   "$name: a 50ms timer did not fire early");
        }
    }
}
