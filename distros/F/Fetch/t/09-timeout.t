#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Time::HiRes ();
use Test::More;
use File::Spec ();
use Fetch;

# Per-request deadline: a request to a server that accepts but never replies
# fails with a timeout after roughly the requested interval, while a request
# that completes well inside its timeout succeeds (and cancels its timer
# cleanly, leaving nothing to fire later).

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run:
    # a leaked server child hangs the whole suite after this test is done.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    my @hold;                       # keep slow sockets open, unanswered
    while (my $c = $srv->accept) {
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        if ($p =~ m{^/fast}) {
            while (my $h = <$c>) { last if $h eq "\r\n" }
            my $b = "quick";
            print $c "HTTP/1.1 200 OK\r\nContent-Length: " . length($b)
                   . "\r\nConnection: close\r\n\r\n$b";
            close $c;
        } else {
            push @hold, $c;         # never answer
        }
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

plan tests => 7;

# Deadlines are timed on a monotonic clock, as the library times them.
# Time::HiRes::time() is the wall clock, which a smoker's host can step
# (an NTP correction, a VM resuming): an interval measured across a step
# comes back short, or negative, with nothing wrong at the timer.
my $now = eval {
    my $clk = Time::HiRes::CLOCK_MONOTONIC();
    Time::HiRes::clock_gettime($clk);
    sub { Time::HiRes::clock_gettime($clk) };
} || \&Time::HiRes::time;

my $ua = Fetch->new;

# ---- a stalled request fails with a timeout ------------------------------
{
    my $t0 = $now->();
    my $f  = $ua->get("$base/slow", timeout => 0.3);
    eval { $f->get };
    my $elapsed = $now->() - $t0;

    ok($f->is_failed, 'stalled request fails');
    like($f->failure, qr/timed out/, 'failure says it timed out');
    cmp_ok($elapsed, '>=', 0.25, 'waited about the timeout, not forever');
}

# ---- a prompt request beats a generous timeout (timer cancels cleanly) ----
# Also the calibration for the block below: whatever a round trip costs on
# this box, the deadlines there are multiples of it.
my $rtt;
{
    my $t0  = $now->();
    my $res = $ua->get("$base/fast", timeout => 30)->get;
    $rtt = $now->() - $t0;
    is($res->content, 'quick', 'fast request succeeds with a timeout set');
}

# ---- a cancelled deadline must stay cancelled ----------------------------
# The fast request's timer is cancelled when its response lands. A backend
# that forgets to tell the kernel (io_uring before 0.19, kqueue reported on
# FreeBSD 9.2) left the timeout in flight with the freed watcher naming it:
# when it came due during the next wait it was either dereferenced as a live
# timer - a crash - or, once the allocator handed that block to the next
# request, charged to that request instead, which then failed on a deadline
# that was never its own. So: cancel a short deadline, then wait on a longer
# one and check nothing fires early.
#
# Both deadlines scale off the measured round trip, because the short one is
# an upper bound on a request completing and a slow or emulated smoker will
# break any fixed value; only the ratio between them matters to the bug.
{
    my $short = $rtt * 20;  $short = 0.5 if $short < 0.5;
    my $long  = $short * 3;

    my $res = $short > 2 ? undef
            : eval { $ua->get("$base/fast", timeout => $short)->get };
  SKIP: {
        skip "round trip of ${rtt}s is too slow to time a cancelled deadline", 3
            unless $res;
        is($res->content, 'quick', "fast request cancels its ${short}s deadline");

        my $t0 = $now->();
        my $f  = $ua->get("$base/slow2", timeout => $long);
        eval { $f->get };
        my $elapsed = $now->() - $t0;
        ok($f->is_failed, 'the following stalled request still fails');
      SKIP: {
            # Only reachable on the wall-clock fallback; time cannot run
            # backwards on the monotonic one, and a stepped clock measures
            # the host, not the deadline.
            skip "the clock stepped back ${elapsed}s mid-request", 1
                if $elapsed < 0;
            cmp_ok($elapsed, '>=', $short * 1.5,
                   'on its own deadline, not the cancelled one')
                or diag "failed after ${elapsed}s of a ${long}s deadline: "
                      . (defined $f->failure ? $f->failure : 'no failure');
        }
    }
}

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
