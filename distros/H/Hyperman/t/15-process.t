#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# Process model (plan/06-process-model.md): max_requests_per_worker recycle,
# USR1 stats dump, bounded graceful shutdown with a hung async request,
# extended stats counters.

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $err  = "$dir/stderr.log";
my $port = 21000 + ($$ % 1000);

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    open STDERR, '>', $err;
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
        local $/;
        my $r = <$s>;
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

done_testing;
