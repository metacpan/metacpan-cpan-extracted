# A worker must not retain dispatched jobs for the life of EV::run.
# io_cb is a raw libev callback with no per-callback Perl scope, so a
# mortal jobref would never be FREETMPS'd: pre-fix the worker pinned
# every job's RV+HV+workload until EV::run returned (i.e. never, for
# a worker daemon). Drain N large-payload jobs in ONE EV::run and
# assert RSS growth is a small fraction of payload x jobs.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use POSIX qw(sysconf _SC_PAGESIZE);
use EV;
use EV::Gearman;

plan skip_all => 'Linux /proc/self/statm required'
    unless $^O eq 'linux' && -r '/proc/self/statm';

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)"
    unless $probe;
close $probe;

my $page_kb = sysconf(_SC_PAGESIZE) / 1024;
sub rss_kb {
    open my $fh, '<', '/proc/self/statm' or die "statm: $!";
    my $line = <$fh>;
    close $fh;
    return (split ' ', $line)[1] * $page_kb;
}

my $N       = 200;
my $pay_kb  = 256;                       # payload per job, in KiB
my $payload = 'x' x ($pay_kb * 1024);

my $wkr = EV::Gearman->new(host => $host, port => $port);
my ($rss_a, $rss_b);
my $done = 0;
$wkr->register_function('noleak_'.$$ => sub {
    $done++;
    $rss_a = rss_kb() if $done == 10;    # let startup churn settle
    if ($done == $N) {
        $rss_b = rss_kb();
        EV::break;
    }
    return 'ok';
});
$wkr->work;

my $cli = EV::Gearman->new(host => $host, port => $port);
$cli->submit_job_bg('noleak_'.$$, $payload) for 1 .. $N;

my $guard = EV::timer 60, 0, sub { fail 'timeout draining jobs'; EV::break };
EV::run;

is $done, $N, "all $N jobs processed in one EV::run";

SKIP: {
    # The RSS-delta heuristic is meaningless under an instrumented
    # allocator: ASan redzones and quarantine (freed blocks are held,
    # not returned — and CI runs detect_leaks=0) inflate RSS far past
    # the real retained set, by an environment-dependent amount that
    # sits right around this budget. Real leaks under the sanitizer
    # build are caught by ASan itself and by xt/91_asan.t; the heuristic
    # is validated on the normal-build CI jobs.
    skip 'RSS-delta leak heuristic invalid under a sanitizer build', 1
        if $ENV{ASAN_OPTIONS} || $ENV{UBSAN_OPTIONS}
        || ($ENV{LD_PRELOAD} && $ENV{LD_PRELOAD} =~ /asan/i);

    my $delta  = $rss_b - $rss_a;
    my $budget = 0.25 * $N * $pay_kb;        # payload x jobs = 51200 KiB
    diag sprintf 'RSS delta job10->job%d: %.0f KiB (budget %.0f KiB)',
        $N, $delta, $budget;
    cmp_ok $delta, '<', $budget,
        'worker retains only a small fraction of payload x jobs';
}

done_testing;
