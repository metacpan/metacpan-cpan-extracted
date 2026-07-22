#!/usr/bin/env perl
# Assert the 0.09 reconnect semantics end-to-end through an RST-capable TCP
# proxy: an abrupt mid-stream drop (which completes the pending RECV batch as
# success=1 with a NULL message — the form every real disconnect takes) must
# arm the backoff and reconnect silently, keepalive ticks and watch events
# must resume once the proxy accepts again, and cancel() during the backoff
# window must reap the handle so no callbacks ever fire afterwards (0.09).
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use IO::Select;
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }

use EV;
use EV::Etcd;

my $ETCD = '127.0.0.1:2379';

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => [$ETCD], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => "etcd not available on $ETCD" unless $available;

# --- RST-capable TCP proxy (forked before any gRPC state exists) ---
my $listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0,
    Listen => 5, ReuseAddr => 1,
) or plan skip_all => "cannot create proxy listener: $!";
my $proxy_port = $listener->sockport;

my $proxy_pid = fork;
plan skip_all => "fork failed: $!" unless defined $proxy_pid;
if (!$proxy_pid) {
    run_proxy($listener);            # never returns
    POSIX::_exit(0);
}
close $listener;

my $PROXY = "127.0.0.1:$proxy_port";
note("proxy $PROXY -> $ETCD (pid $proxy_pid)");

my $direct  = EV::Etcd->new(endpoints => [$ETCD]);
my $proxied = EV::Etcd->new(endpoints => [$PROXY], max_retries => 5);

my $prefix = "/xt-rb-$$";

# --- Phase 1: streams up through the proxy ---
my ($lease_id, $ka1, $watch1);
my ($ticks, $ka_errs, $events, $watch_errs, $watch_created) = (0) x 5;
my (@ka_errmsgs, @watch_errmsgs);

$proxied->lease_grant(6, sub {
    my ($resp, $err) = @_;
    BAIL_OUT("lease_grant via proxy failed: $err->{message}") if $err;
    $lease_id = $resp->{id};
    $ka1 = $proxied->lease_keepalive($lease_id, sub {
        my ($r, $e) = @_;
        if ($e) { $ka_errs++; push @ka_errmsgs, $e->{message}; return }
        $ticks++;
    });
    $watch1 = $proxied->watch("$prefix/key", sub {
        my ($r, $e) = @_;
        if ($e) { $watch_errs++; push @watch_errmsgs, $e->{message}; return }
        $watch_created = 1 if $r->{created};
        $events++ if $r->{events} && @{$r->{events}};
    });
});

wait_for(sub { $watch_created && $ticks >= 1 }, 5);
ok($watch_created && $ticks >= 1, 'watch created and keepalive ticking through proxy')
    or BAIL_OUT('streams never came up through the proxy');

# --- RST all proxied connections; detect which dispatch path fires ---
my ($ticks0, $events0) = ($ticks, $events);
kill 'USR1', $proxy_pid;
wait_for(sub { 0 }, 0.35);    # give the failure event time to surface

my $mode = ($ka_errs || $watch_errs) ? 'terminal' : 'backoff';
note("abrupt RST surfaced as: $mode"
    . ($mode eq 'terminal'
        ? " (watch: @watch_errmsgs; keepalive: @ka_errmsgs)" : ''));

if ($mode eq 'backoff') {
    # Reconnect engaged silently — assert it completes end-to-end.
    wait_for(sub { $ticks > $ticks0 }, 8);
    cmp_ok($ticks, '>', $ticks0, 'keepalive ticks resumed after reconnect');

    $direct->put("$prefix/key", 'post-rst', sub { });
    wait_for(sub { $events > $events0 }, 5);
    cmp_ok($events, '>', $events0, 'watch event delivered after reconnect');

    is($ka_errs + $watch_errs, 0, 'no error callbacks during silent reconnect');

    # Retire phase-1 handles on the normal cancel path.
    my $done = 0;
    $watch1->cancel(sub { $done++ });
    $ka1->cancel(sub { $done++ });
    wait_for(sub { $done == 2 }, 3);

    # --- Phase 2: cancel DURING backoff (the 0.09 reap branch) ---
    my ($created2, $ticks2, $errs2) = (0, 0, 0);
    my $ka2 = $proxied->lease_keepalive($lease_id, sub {
        my ($r, $e) = @_;
        if ($e) { $errs2++; return }
        $ticks2++;
    });
    my $watch2 = $proxied->watch("$prefix/key2", sub {
        my ($r, $e) = @_;
        if ($e) { $errs2++; return }
        $created2 = 1 if $r->{created};
    });
    wait_for(sub { $created2 && $ticks2 >= 1 }, 8);
    ok($created2 && $ticks2 >= 1, 'phase-2 streams up through proxy')
        or BAIL_OUT('phase-2 streams never came up');

    kill 'USR1', $proxy_pid;
    wait_for(sub { 0 }, 0.25);    # inside the 0.5s first-attempt backoff

    is($errs2, 0, 'no error callbacks yet: streams are in backoff, timers armed');

    my $cancelled = 0;
    $watch2->cancel(sub { $cancelled++ });
    $ka2->cancel(sub { $cancelled++ });
    is($cancelled, 2, 'both cancels succeeded synchronously mid-backoff');

    # Reaped structs must never fire again (callback SVs were released).
    my ($t2_snap, $e2_snap) = ($ticks2, $errs2);
    wait_for(sub { 0 }, 1.5);
    is($errs2, $e2_snap,  'no error callbacks after mid-backoff cancel');
    is($ticks2, $t2_snap, 'no keepalive ticks after mid-backoff cancel');

    # --- Phase 3: retry exhaustion — server stays down past every backoff ---
    # max_retries=2 gives attempts at ~0.5s and ~1.5s; the terminal error must
    # come after the full budget (not after the first failed attempt), exactly
    # once per stream, with a retryable UNAVAILABLE status.
    my $client3 = EV::Etcd->new(endpoints => [$PROXY], max_retries => 2);
    my ($lease3, $created3, $ticks3) = (undef, 0, 0);
    my (@werr3, @kerr3);
    $direct->lease_grant(30, sub {
        my ($resp, $err) = @_;
        BAIL_OUT("phase-3 lease_grant failed: $err->{message}") if $err;
        $lease3 = $resp->{id};
        EV::break;
    });
    my $tg3 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    my $ka3 = $client3->lease_keepalive($lease3, sub {
        my ($r, $e) = @_;
        if ($e) { push @kerr3, [EV::time, $e]; return }
        $ticks3++;
    });
    my $watch3 = $client3->watch("$prefix/key3", sub {
        my ($r, $e) = @_;
        if ($e) { push @werr3, [EV::time, $e]; return }
        $created3 = 1 if $r->{created};
    });
    wait_for(sub { $created3 && $ticks3 >= 1 }, 8);
    ok($created3 && $ticks3 >= 1, 'phase-3 streams up through proxy')
        or BAIL_OUT('phase-3 streams never came up');

    my $t_down = EV::time;
    kill 'TERM', $proxy_pid;    # proxy gone entirely: FIN now, refused later
    waitpid $proxy_pid, 0;
    $proxy_pid = 0;

    wait_for(sub { @werr3 && @kerr3 }, 10);
    is(scalar @werr3, 1, 'exactly one terminal watch error after exhaustion');
    is(scalar @kerr3, 1, 'exactly one terminal keepalive error after exhaustion');
    if (@werr3 && @kerr3) {
        my $w_delay = $werr3[0][0] - $t_down;
        my $k_delay = $kerr3[0][0] - $t_down;
        cmp_ok($w_delay, '>=', 1.2,
            sprintf 'watch error came after the full retry budget (%.2fs)', $w_delay);
        cmp_ok($k_delay, '>=', 1.2,
            sprintf 'keepalive error came after the full retry budget (%.2fs)', $k_delay);
        is($werr3[0][1]{status}, 'UNAVAILABLE', 'watch exhaustion status is UNAVAILABLE');
        ok($werr3[0][1]{retryable}, 'watch exhaustion error is marked retryable');
        is($kerr3[0][1]{status}, 'UNAVAILABLE', 'keepalive exhaustion status is UNAVAILABLE');
    }

    # No stragglers, and dead handles cancel cleanly.
    my ($w3_snap, $k3_snap) = (scalar @werr3, scalar @kerr3);
    wait_for(sub { 0 }, 1.5);
    is(@werr3 + @kerr3, $w3_snap + $k3_snap, 'no further callbacks after exhaustion');
    my $cancelled3 = 0;
    $watch3->cancel(sub { $cancelled3++ });
    $ka3->cancel(sub { $cancelled3++ });
    is($cancelled3, 2, 'cancel after exhaustion succeeds synchronously');
    $direct->lease_revoke($lease3, sub { });
}
else {
    # Since 0.09 a stream ending without a message must arm the backoff and
    # reconnect silently; an immediate error callback is a regression to the
    # pre-0.09 terminal-error behavior.
    fail('abrupt connection drop arms the reconnect backoff path');
    diag("watch errors: @watch_errmsgs");
    diag("keepalive errors: @ka_errmsgs");
}

# --- Cleanup ---
$direct->lease_revoke($lease_id, sub { EV::break }) if $lease_id;
my $tc = EV::timer(3, 0, sub { EV::break });
EV::run;
$direct->delete("$prefix/", { prefix => 1 }, sub { EV::break });
my $td = EV::timer(3, 0, sub { EV::break });
EV::run;

if ($proxy_pid) {
    kill 'TERM', $proxy_pid;
    waitpid $proxy_pid, 0;
}

done_testing();

# Pump the EV loop until $cond returns true or $seconds elapse.
sub wait_for {
    my ($cond, $seconds) = @_;
    my $poll  = EV::timer(0.05, 0.05, sub { EV::break if $cond->() });
    my $guard = EV::timer($seconds, 0, sub { EV::break });
    EV::run;
}

sub run_proxy {
    my ($lst) = @_;
    my $rst_all = 0;
    local $SIG{USR1} = sub { $rst_all = 1 };
    local $SIG{TERM} = sub { POSIX::_exit(0) };

    my $sel  = IO::Select->new($lst);
    my %peer;    # fh -> paired fh

    while (1) {
        my @ready = $sel->can_read(0.1);
        if ($rst_all) {
            $rst_all = 0;
            for my $sock ($sel->handles) {
                next if $sock == $lst;
                # SO_LINGER {on, 0s}: close() sends RST instead of FIN
                setsockopt($sock, SOL_SOCKET, SO_LINGER, pack('ll', 1, 0));
                $sel->remove($sock);
                close $sock;
            }
            %peer = ();
        }
        for my $fh (@ready) {
            if ($fh == $lst) {
                my $client = $lst->accept or next;
                my $backend = IO::Socket::INET->new(
                    PeerAddr => '127.0.0.1', PeerPort => 2379, Proto => 'tcp',
                );
                if (!$backend) { close $client; next }
                $peer{$client}  = $backend;
                $peer{$backend} = $client;
                $sel->add($client, $backend);
                next;
            }
            my $n = sysread($fh, my $buf, 65536);
            if (!$n) {    # EOF or error: mirror the close
                my $other = $peer{$fh};
                $sel->remove($fh);
                close $fh;
                if ($other) {
                    $sel->remove($other);
                    close $other;
                    delete $peer{$other};
                }
                delete $peer{$fh};
                next;
            }
            my $off = 0;
            while ($off < $n) {
                my $w = syswrite($peer{$fh}, $buf, $n - $off, $off);
                last unless defined $w;
                $off += $w;
            }
        }
    }
}
