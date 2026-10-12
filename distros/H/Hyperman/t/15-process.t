#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use POSIX ();

# Process model: max_requests_per_worker recycle,
# USR1 stats dump, bounded graceful shutdown with a hung async request,
# extended stats counters.

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $err  = "$dir/stderr.log";
my ($port) = free_ports(1);
plan skip_all => 'the worker pool and fork tests need fork(2); Windows runs a single worker'
    if $^O eq 'MSWin32';

plan skip_all => "no free loopback port" unless $port;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    quiet_child(stderr => $err);
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            if ($env->{PATH_INFO} eq '/stats') {
                my $s = Hyperman->stats;
                my $keys = join ',', sort grep { defined $s->{$_} } keys %$s;
                return [ 200, [], [ $keys ] ];
            }
            if ($env->{PATH_INFO} eq '/hang') {   # a Future that never resolves
                return Hyperman::Future->new;
            }
            [ 200, [], [ "w$$" ] ];
        },
        host => '127.0.0.1', port => $port, workers => 2,
        max_requests_per_worker => 10,
        shutdown_grace          => 1,
    );
    exit 0;
}

sub get {
    my $path = shift;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        $s->print("GET $path HTTP/1.0\r\n\r\n");
        # bounded read: a peer that accepts and then says nothing must not
        # wedge the test file for the harness's whole timeout.
        my $r = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
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

# ---- stats has the doc-06 counters ---------------------------------------
{
    my $keys = get('/stats');
    like($keys, qr/accepts/,   'stats: accepts');
    like($keys, qr/bytes_out/, 'stats: bytes_out');
    like($keys, qr/requests/,  'stats: requests');
}

# ---- max_requests_per_worker: pool recycles, service uninterrupted -------
{
    my %pids;
    my $failures = 0;
    for (1 .. 80) {
        my $b = get('/');
        if (defined $b && $b =~ /^w(\d+)/) { $pids{$1} = 1 }
        else { $failures++ }
    }
    is($failures, 0, 'no failed requests across worker recycles');
    cmp_ok(scalar keys %pids, '>', 2,
        'workers recycled after max_requests (' . (keys %pids) . ' pids seen)');

    # The supervisor never serves. $$ is a plain SV that perl only refreshes
    # inside pp_fork, so a worker forked from C reported the supervisor's pid
    # until hm_spawn started setting it - which made every worker look like
    # the same process to the application (and to the assertion above).
    ok(!$pids{$sup}, "workers report their own pid, not the supervisor's ($sup)");
}

# ---- USR1: workers dump stats to stderr ----------------------------------
{
    kill 'USR1', $sup;
    my $found = 0;
    for (1 .. 30) {
        if (open my $fh, '<', $err) {
            local $/;
            my $log = <$fh>;
            if ($log =~ /Hyperman worker \d+: requests=\d+ accepts=\d+/) {
                $found = 1;
                last;
            }
        }
        Time::HiRes::sleep(0.1);
    }
    ok($found, 'USR1 produced a per-worker stats dump');
}

# ---- an alarm the caller had pending is honoured, not cancelled ----------
# The supervisor's own clock is SIGALRM - the scoreboard tick - so taking that
# signal over silently cancelled any alarm() the caller had set before run().
# A watchdog is exactly what that alarm is for, and an unkilled supervisor
# keeps a whole pool (and the descriptors it inherited) alive for ever. So a
# pending deadline is carried: the pool goes down and SIGALRM then does what it
# would have done. A pool of its own, on its own port, to be killed by it.
{
    my ($p2) = free_ports(1);
    my $kid  = $p2 ? fork : undef;
    die "fork: $!" if $p2 && !defined $kid;
    if ($p2 && !$kid) {
        quiet_child(alarm => 2);
        require Hyperman;
        Hyperman->run(app => sub { [ 200, [], ['x'] ] },
                      host => '127.0.0.1', port => $p2, workers => 2);
        exit 0;
    }
  SKIP: {
        skip 'no free loopback port for the alarm pool', 3 unless $p2;
        my ($reaped, $st) = (0, 0);
        for (1 .. 150) {                       # the tick is three seconds
            if (waitpid($kid, POSIX::WNOHANG()) == $kid) { $reaped = 1; $st = $?; last }
            Time::HiRes::sleep(0.1);
        }
        ok($reaped, 'a supervisor whose caller set alarm() dies of it');
        is($st & 127, POSIX::SIGALRM(), 'killed by SIGALRM, as the caller asked')
            if $reaped;
        # ... and it took the workers with it: one still holding the listening
        # socket would go on answering.
        my $refused = 0;
        for (1 .. 50) {
            my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1',
                                          PeerPort => $p2, Proto => 'tcp');
            if (!$s) { $refused = 1; last }
            close $s;
            Time::HiRes::sleep(0.1);
        }
        ok($refused, 'and no worker was left holding the port');
        kill 'KILL', $kid unless $reaped;
    }
}

# ---- bounded shutdown: hung awaiting request cannot stall TERM -----------
{
    my $h = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
    $h->print("GET /hang HTTP/1.1\r\nHost: t\r\n\r\n");
    Time::HiRes::sleep(0.3);      # let it park on the never-ready Future

    my $t0 = Time::HiRes::time();
    kill 'TERM', $sup;
    waitpid $sup, 0;
    my $dt = Time::HiRes::time() - $t0;
    cmp_ok($dt, '<', 5,
        sprintf('supervisor exited in %.1fs despite a hung request (grace=1s)', $dt));
}

# ---- pid_file and umask ---------------------------------------------------
{
    my ($p3) = free_ports(1);
    my $pidfile = "$dir/server.pid";
    my $kid = fork;
    die "fork: $!" unless defined $kid;
    if ($kid == 0) {
        quiet_child(stderr => $err);
        require Hyperman;
        Hyperman->run(
            app => sub {
                my $env = shift;
                if ($env->{PATH_INFO} eq '/mk') {
                    open my $fh, '>', "$dir/made" or return [ 500, [], [ "$!" ] ];
                    close $fh;
                    return [ 200, [], [ sprintf '%04o', (stat "$dir/made")[2] & 07777 ] ];
                }
                [ 200, [], [ 'ok' ] ];
            },
            host => '127.0.0.1', port => $p3, workers => 2,
            pid_file => $pidfile, umask => 0077,
        );
        exit 0;
    }
    my $got;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $p3, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        $s->print("GET /mk HTTP/1.0\r\n\r\n");
        local $/; my $r = <$s>; $got = $1 if defined $r && $r =~ /\r\n\r\n(.*)\z/s;
        last;
    }
    is($got, '0600', 'umask 0077 applied: a file the worker made is 0600');
    ok(-e $pidfile, 'pid_file exists while the server runs');
    open my $pf, '<', $pidfile; my $content = <$pf> // ''; close $pf;
    chomp $content;
    is($content, $kid, 'pid_file holds the supervisor pid');
    kill 'TERM', $kid;
    waitpid $kid, 0;
    ok(!-e $pidfile, 'pid_file removed at exit');
}

# ---- an unknown user is refused before anything is bound ----------------
{
    my ($p4) = free_ports(1);
    my $kid = fork;
    die "fork: $!" unless defined $kid;
    if ($kid == 0) {
        open STDERR, '>', "$dir/user.err";
        open STDOUT, '>', '/dev/null';
        require Hyperman;
        eval { Hyperman->run(app => sub { [200, [], ['x']] }, host => '127.0.0.1',
                             port => $p4, workers => 1, user => 'no-such-user-hm-xyz') };
        print STDERR "CROAK: $@" if $@;
        exit 3;
    }
    waitpid $kid, 0;
    is($? >> 8, 3, 'run() croaked on an unknown user');
    open my $fh, '<', "$dir/user.err"; local $/; my $e = <$fh> // '';
    like($e, qr/user 'no-such-user-hm-xyz': no such user/, '...naming it');
    my $probe = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $p4,
                                      Proto => 'tcp', Listen => 1, ReuseAddr => 1);
    ok($probe, '...and the port was never bound');
    close $probe if $probe;
}

# ---- the real drop, only as root ---------------------------------------
SKIP: {
    skip 'the setuid case runs only as root', 2 unless $< == 0;
    my ($p5) = free_ports(1);
    my $nobody = getpwnam('nobody');
    skip 'no "nobody" user on this box', 2 unless defined $nobody;
    my $kid = fork;
    die "fork: $!" unless defined $kid;
    if ($kid == 0) {
        quiet_child(stderr => $err);
        require Hyperman;
        Hyperman->run(app => sub { [200, [], ["uid=$< euid=$>"]] }, host => '127.0.0.1',
                      port => $p5, workers => 2, user => 'nobody');
        exit 0;
    }
    my $got;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $p5, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        $s->print("GET / HTTP/1.0\r\n\r\n");
        local $/; my $r = <$s>; $got = $1 if defined $r && $r =~ /\r\n\r\n(.*)\z/s;
        last;
    }
    is($got, "uid=$nobody euid=$nobody", 'the worker runs as nobody');
    my $sup_uid = (stat "/proc/$kid")[4];
    SKIP: {
        skip 'no /proc', 1 unless defined $sup_uid;
        is($sup_uid, $nobody, 'the supervisor runs as nobody too');
    }
    kill 'TERM', $kid;
    waitpid $kid, 0;
}

done_testing;
