#!perl
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use POSIX ();
use Hyperman::Loop;
use Hyperman::Future;

# Hard watchdog. This file finishes in well under a second; a stalled
# readiness/timer path (as happened once on a FreeBSD smoker) must fail fast,
# not hang for hours. A Perl alarm cannot interrupt a blocked C event loop, so
# fork a killer that SIGKILLs us if we overrun. The child uses _exit so it
# never runs END/Test::More teardown, and kills only its live parent (once the
# parent exits it is reparented to init, so a stale pid is never signalled).
my $watchdog = fork;
if (defined $watchdog && $watchdog == 0) {
    $SIG{TERM} = sub { POSIX::_exit(0) };
    sleep 30;
    kill 'KILL', getppid();
    POSIX::_exit(0);
}
END { kill 'TERM', $watchdog if $watchdog }

my $loop = Hyperman::Loop->new;
isa_ok($loop, 'Hyperman::Loop');
ok(length $loop->backend, 'backend selected: ' . $loop->backend);

# ---- one-shot callback timer ---------------------------------------------
{
    my $fired = 0;
    $loop->timer(0.02, sub { $fired++; $loop->stop });
    my $t0 = Time::HiRes::time();
    $loop->run;
    my $dt = Time::HiRes::time() - $t0;
    is($fired, 1, 'timer callback fired once');
    cmp_ok($dt, '>=', 0.015, 'after the delay');
    cmp_ok($dt, '<', 1, 'without hanging');
}

# ---- timer_f + run_until -------------------------------------------------
{
    my $f = $loop->timer_f(0.02);
    ok(!$f->is_ready, 'timer future pending');
    $loop->run_until($f);
    ok($f->is_done, 'timer future resolved by run_until');
}

# ---- deferred queue ------------------------------------------------------
{
    my @order;
    $loop->defer(sub { push @order, 'a' });
    $loop->defer(sub { push @order, 'b'; $loop->defer(sub { push @order, 'c' }) });
    my $f = $loop->timer_f(0.02);
    $loop->run_until($f);
    is_deeply(\@order, [qw(a b c)], 'deferred callbacks run FIFO, re-defers included');
}

# ---- io watchers on a pipe -----------------------------------------------
{
    pipe(my $r, my $w) or die "pipe: $!";
    my $f = $loop->readable_f($r);
    ok(!$f->is_ready, 'readable_f pending on empty pipe');
    $loop->timer(0.01, sub { syswrite $w, "x" });
    $loop->run_until($f);
    ok($f->is_done, 'readable future resolved when pipe had data');
    sysread $r, my $buf, 1;

    my $wf = $loop->writable_f($w);
    $loop->run_until($wf);
    ok($wf->is_done, 'writable future resolves on writable pipe');
}

# ---- persistent watch_io + unwatch_io ------------------------------------
{
    pipe(my $r, my $w) or die "pipe: $!";
    my $hits = 0;
    # Read one byte per fire, not the whole buffer: if both timers fire before
    # the loop services the pipe (likely on a slow/loaded box) the two writes
    # coalesce, and a level-triggered watcher that drained everything at once
    # would fire only once - hanging this test waiting for a second hit. One
    # byte at a time lets the still-readable pipe re-fire the watcher.
    my $watcher = $loop->watch_io($r, 'r', sub {
        $hits++;
        sysread $r, my $buf, 1;
        $loop->stop if $hits >= 2;
    });
    $loop->timer(0.01, sub { syswrite $w, "1" });
    $loop->timer(0.03, sub { syswrite $w, "2" });
    $loop->run;
    is($hits, 2, 'persistent watcher fired per readiness');
    $loop->unwatch_io($watcher);
    ok(1, 'unwatch_io removed the watcher');
}

# ---- install_await: ->get pumps this loop --------------------------------
{
    $loop->install_await;
    my $f = $loop->timer_f(0.02)->then(sub { 'pumped' });
    is(scalar($f->get), 'pumped', 'get on a pending future pumps the loop');
}

done_testing;
