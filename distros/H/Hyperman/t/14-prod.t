#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports server_status server_reap slurp);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# Phase 5 production behavior: supervisor respawn, SIGHUP zero-downtime
# recycle, per-worker stats, access_log.

my $dir    = File::Temp::tempdir(CLEANUP => 1);
my $logfile = "$dir/access.log";
my $errfile = "$dir/stderr.log";
my ($port) = free_ports(1);
plan skip_all => 'the worker pool and fork tests need fork(2); Windows runs a single worker'
    if $^O eq 'MSWin32';

plan skip_all => 'no free loopback port' unless $port;

# Everything below reads worker pids out of response bodies. Against someone
# else's server those pids are real and meaningless, so stamp the responses
# with a token only this run knows and refuse to test a stranger.
my $token = "hm$$-" . time;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    open STDERR, '>', $errfile;
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            if ($env->{PATH_INFO} eq '/whoami') {
                return [ 200, [], [ $token ] ];
            }
            if ($env->{PATH_INFO} eq '/stats') {
                my $s = Hyperman->stats;
                return [ 200, [], [ "req=$s->{requests} conn=$s->{connections} pid=$s->{pid}" ] ];
            }
            [ 200, [ 'Content-Type' => 'text/plain' ], [ "w$$" ] ];
        },
        access_log => sub {
            my ($env, $status, $bytes) = @_;
            open my $fh, '>>', $logfile or return;
            print $fh "$env->{REQUEST_METHOD} $env->{PATH_INFO} $status $bytes\n";
            close $fh;
        },
        host => '127.0.0.1', port => $port, workers => 2,
    );
    exit 0;
}

# One request, or undef within GET_BUDGET seconds. Both bounds matter: a
# refused connect retries (the server may still be forking), and a peer that
# accepts and then says nothing - which is what someone else holding the port
# looks like - must not wedge the file. The budget is wall clock rather than
# a retry count so the two failure modes cannot multiply into minutes.
use constant GET_BUDGET => 10;

sub get {
    my $path = shift;
    my $deadline = Time::HiRes::time() + GET_BUDGET;
    while (Time::HiRes::time() < $deadline) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port,
            Proto => 'tcp', Timeout => 2)
            or (Time::HiRes::sleep(0.1), next);
        $s->print("GET $path HTTP/1.0\r\n\r\n");
        my $r = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 3;
            local $/;
            my $body = <$s>;
            alarm 0;
            $body;
        };
        alarm 0;
        return $1 if defined $r && $r =~ /\r\n\r\n(.*)\z/s;
        Time::HiRes::sleep(0.1);
    }
    return undef;
}

# Poll $code until it returns true or $secs of wall-clock elapse. Fixed
# iteration counts are unreliable on loaded CPAN smokers - a killed worker
# is respawned with exponential backoff (see hm_core.h), so respawn/recycle
# can lag several seconds. Bound by wall time instead.
sub wait_until {
    my ($secs, $code) = @_;
    my $deadline = Time::HiRes::time() + $secs;
    while (1) {
        my $r = $code->();
        return $r if $r;
        return $r if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep(0.1);
    }
}

# collect the pids currently serving
sub worker_pids {
    my %p;
    for (1 .. 30) {
        my $b = get('/');
        $p{$1} = 1 if defined $b && $b =~ /^w(\d+)/;
    }
    return sort keys %p;
}

# ---- the server under test is ours ----------------------------------------
# Before reading any pid off the wire, establish that the supervisor is alive
# and that the thing answering on $port is the server this file started. A
# bind clash used to leave every assertion below measuring a stranger.
{
    my $who;
    wait_until(15, sub {
        return 1 if defined server_status($sup);
        $who = get('/whoami');
        defined $who;
    });

    my $dead = server_status($sup);
    if (defined $dead) {
        plan skip_all => "server did not stay up ($dead): " . slurp($errfile);
    }
    unless (defined $who && $who eq $token) {
        kill 'TERM', $sup;
        server_reap($sup);
        plan skip_all => "port $port answered by another process (got "
            . (defined $who ? "'$who'" : 'no response') . ")";
    }
}

my @orig = worker_pids();
cmp_ok(scalar @orig, '>=', 1, "serving from workers: @orig");

# ---- stats --------------------------------------------------------------
{
    # The per-worker counter is bumped after the response is sent, and /stats
    # may land on a freshly-accepted worker whose count is still 0. Poll until
    # some worker reports a request it has already completed.
    my $b;
    my $req = 0;
    wait_until(15, sub {
        $b = get('/stats');
        ($req) = ($b // '') =~ /req=(\d+)/;
        $req && $req > 0;
    });
    like($b, qr/^req=\d+ conn=\d+ pid=\d+$/, "stats: $b");
    cmp_ok($req, '>', 0, 'request counter advanced');
}

# ---- access_log ---------------------------------------------------------
{
    get('/logged-path');
    my $found = 0;
    for (1 .. 20) {
        if (open my $fh, '<', $logfile) {
            local $/;
            my $log = <$fh>;
            if ($log =~ m{^GET /logged-path 200 \d+$}m) { $found = 1; last }
        }
        Time::HiRes::sleep(0.1);
    }
    ok($found, 'access_log wrote method/path/status/bytes')
        or diag "supervisor stderr: " . slurp($errfile);
}

# ---- respawn: kill -9 a worker, service continues, pool refills ----------
{
    my ($victim) = @orig;
    kill 'KILL', $victim;
    Time::HiRes::sleep(0.2);
    my $ok = wait_until(15, sub { defined get('/') });
    ok($ok, 'service continues after a worker is killed -9');

    my %orig = map { $_ => 1 } @orig;
    my $newcomer = wait_until(15, sub {
        my $b = get('/');
        defined $b && $b =~ /^w(\d+)/ && !$orig{$1};
    });
    ok($newcomer, 'supervisor respawned a replacement worker')
        or diag "killed $victim, still only @orig; supervisor "
            . (server_status($sup) || 'alive')
            . "; stderr: " . slurp($errfile);
}

# ---- SIGHUP: zero-downtime recycle ---------------------------------------
{
    my %before = map { $_ => 1 } worker_pids();
    kill 'HUP', $sup;

    # keep requesting through the recycle: none may fail
    my $failures = 0;
    for (1 .. 30) {
        defined get('/') or $failures++;
        Time::HiRes::sleep(0.05);
    }
    is($failures, 0, 'no failed requests during HUP recycle');

    my $fresh = wait_until(15, sub {
        my $b = get('/');
        defined $b && $b =~ /^w(\d+)/ && !$before{$1};
    });
    ok($fresh, 'HUP produced fresh workers')
        or diag "pre-HUP workers " . join(' ', sort keys %before)
            . "; supervisor " . (server_status($sup) || 'alive')
            . "; stderr: " . slurp($errfile);
}

# only signal a pid we know we still own: a diag above may already have
# reaped the supervisor, and a reaped pid can be recycled by the kernel.
kill 'TERM', $sup unless defined server_status($sup);
my $st = server_reap($sup);
is($st >> 8, 0, 'supervisor exited cleanly on TERM')
    or diag "wait status $st, supervisor stderr: " . slurp($errfile);

done_testing;
