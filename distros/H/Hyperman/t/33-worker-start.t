#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# hm_abi v4: on_worker_start. A callback registered before run() fires once in
# every worker, after the fork, with that worker's own loop, before the loop
# starts turning.
#
# The registration is a C entry, so a Perl test cannot call it directly: it
# goes through _abi_worker_hook_install, which registers a C callback THROUGH
# the table. What the callback increments is a plain static, inherited as 0
# across the fork, so each worker counts its own - and the application reports
# that count back over HTTP, which is the only way to see inside a worker.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

# ---- before run(), nothing has fired ----------------------------------------
{
    my ($n, $loop_ok) = Hyperman::_abi_worker_hook_state();
    is($n, 0, 'the hook has not fired in the supervisor');
    is(Hyperman::_abi_worker_hook_install(), 1,
        'a C consumer registers on_worker_start through the table');
}

my $pid = fork // die "fork: $!";
if (!$pid) {
    # Both handles, not just STDERR: the child inherits the TAP pipe on
    # STDOUT, and a server writing into it makes the harness see a corrupt
    # stream and the smoker report a SIGKILL after every test has passed.
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my ($n, $loop_ok) = Hyperman::_abi_worker_hook_state();
            return [ 200, [ 'Content-Type' => 'text/plain' ],
                     ["fired=$n loop=$loop_ok pid=$$"] ];
        },
        host => '127.0.0.1', port => $port, workers => 2,
    );
    exit 0;
}

sub http_get {
    my ($path) = @_;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                      Proto => 'tcp', Timeout => 2);
        if (!$s) { Time::HiRes::sleep(0.05); next }
        syswrite $s, "GET $path HTTP/1.0\r\nHost: x\r\n\r\n";
        local $/;
        my $body = <$s>;
        close $s;
        return $body if defined $body && length $body;
        Time::HiRes::sleep(0.05);
    }
    return '';
}

# ---- inside a worker --------------------------------------------------------
my %pids;
my $checked = 0;
for (1 .. 12) {
    my $res = http_get('/');
    last unless $res =~ /fired=(\d+) loop=(\d+) pid=(\d+)/;
    my ($fired, $loop_ok, $wpid) = ($1, $2, $3);

    is($fired, 1, "worker $wpid fired on_worker_start exactly once")
        unless $pids{$wpid}++;
    is($loop_ok, 1, "worker $wpid was handed a real loop")
        unless $checked++;
}

ok(scalar(keys %pids) >= 1, 'at least one worker answered');
isnt((keys %pids)[0], $$, 'the worker is not the process that registered');

kill 'TERM', $pid;
waitpid $pid, 0;

# ---- the supervisor's own count is still zero -------------------------------
{
    my ($n) = Hyperman::_abi_worker_hook_state();
    is($n, 0, 'the supervisor never fired it: this is a WORKER hook');
}

done_testing();
