#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();

# The v3 abuse controls: the shared arena's denylist enforced at accept. The
# arena logic itself (deny add/check/remove + fixed-window ratelimit_hit,
# shared across a fork) is driven through the ABI table by _abi_selftest and
# checked in t/22-abi.t; here we prove the accept-path drop end to end - a
# denylisted peer is closed before it can get a response, and a peer that is
# NOT on the list is served exactly as before.

my @ports = free_ports(2);
plan skip_all => "no free loopback ports" unless @ports == 2;
my ($deny_port, $ok_port) = @ports;

my $app = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'ok' ] ] };

# A server that denylists the loopback address every test connection uses, and
# one that denylists an unrelated TEST-NET address so the same client sails
# through - proving the denylist blocks the named IP and nothing else.
sub spawn {
    my ($port, @deny) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        open STDERR, '>', '/dev/null';
        require Hyperman;
        Hyperman->run(app => $app, host => '127.0.0.1', port => $port,
                      workers => 1, deny => [ @deny ]);
        exit 0;
    }
    return $pid;
}

sub connect_srv {
    my ($port) = @_;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return undef;
}

# GET one request; returns the HTTP status, or undef if the connection yielded
# no response (dropped).
sub get_status {
    my ($s) = @_;
    $s->print("GET / HTTP/1.1\r\nHost: t\r\n\r\n");
    my $buf = '';
    while ($s->sysread(my $chunk, 4096)) {
        $buf .= $chunk;
        last if $buf =~ /\r\n\r\n/;
    }
    my ($status) = $buf =~ m{^HTTP/1\.\d (\d+)};
    return $status;
}

my $deny_pid = spawn($deny_port, '127.0.0.1');
my $ok_pid   = spawn($ok_port,   '198.51.100.7');   # TEST-NET-2, never us

# ---- the control: a non-denylisted client is served normally ----------------
{
    my $s = connect_srv($ok_port);
    ok($s, 'server up (denylist does not block an unrelated IP)');
    SKIP: {
        skip 'no connection', 1 unless $s;
        is(get_status($s), 200, 'a peer not on the denylist gets its 200');
        close $s;
    }
}

# ---- the block: a denylisted client is dropped at accept --------------------
{
    # The TCP handshake still completes (the kernel accepts the SYN), so
    # connect() succeeds; the server then closes the fd before serving, so the
    # first read is EOF and there is no HTTP status.
    my $s = connect_srv($deny_port);
    ok($s, 'a denylisted peer still completes the TCP connect');
    SKIP: {
        skip 'no connection', 1 unless $s;
        is(get_status($s), undef,
           'but is dropped before any response - denylist enforced at accept');
        close $s;
    }
}

for my $pid ($deny_pid, $ok_pid) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
