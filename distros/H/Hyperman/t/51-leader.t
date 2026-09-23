#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_guard server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# THE LEADER. Hyperman->leader is the lease on the server's arena: exactly one
# worker holds it at a time, and when that worker is killed another takes it
# over within the ttl. Two workers, each asked to acquire on every request.
#
# WHICH worker answers a request is the kernel's business, not the lease's.
# Both workers wait on one inherited listening socket, so a round of six
# connections can be accepted entirely by the worker that does NOT hold the
# lease; every reply then says held=0, truthfully, while the lease is held all
# along. So each reply also carries the lease's own answer to "who holds it" -
# holder and non-holder alike agree on that - and nothing here assumes the
# holder is one of the processes that replied.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'Shared::Arena is not available to this Hyperman'
    if $ENV{HYPERMAN_NO_SA_ABI} || !eval { require Shared::Arena; 1 };

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

is(Hyperman->leader('t51'), undef, 'no arena, no leader, undef');

# Registered with HMTest before anything can die: an assertion failing on the
# way to `kill TERM` below would otherwise leave the whole pool running.
my $pid = server_guard(fork // die "fork: $!");
if (!$pid) {
    quiet_child();
    my $lease;
    Hyperman->run(
        app => sub {
            $lease //= Hyperman->leader('t51', ttl => 2);
            my $held = $lease->acquire ? 1 : 0;
            my $out  = "pid=$$ held=$held fence=" . ($held ? $lease->fence : 0)
                     . ' holder=' . $lease->holder;
            [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => length $out ], [$out] ];
        },
        host => '127.0.0.1', port => $port, workers => 2,
    );
    exit 0;
}

sub http_get {
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                      Proto => 'tcp', Timeout => 2);
        if (!$s) { Time::HiRes::sleep(0.05); next }
        syswrite $s, "GET / HTTP/1.0\r\nHost: x\r\n\r\n";
        local $/;
        my $res = <$s>;
        close $s;
        return $1 if defined $res && $res =~ /\r\n\r\n(.*)\z/s && length $1;
        Time::HiRes::sleep(0.05);
    }
    return '';
}

# Open several connections together so both workers get a chance to answer,
# then read them.
#
# Every round is TIMED, because the lease lapses after two seconds: inside a
# round that took longer than that, a second worker taking the lease over is
# the lease working, not failing, and two replies saying held=1 mean nothing.
# A loaded smoker produces such rounds. They are counted and noted; only a
# round that finished well inside the ttl is asserted on.
my $ROUND_MAX   = 1;      # seconds
my $round_took  = 0;
my $rounds_slow = 0;
my $two_at_once = 0;
sub round {
    my $t0 = Time::HiRes::time();
    my @socks = grep { defined }
        map { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                    Proto => 'tcp', Timeout => 2) } 1 .. 6;
    syswrite $_, "GET / HTTP/1.0\r\nHost: x\r\n\r\n" for @socks;
    my %by_pid;
    for my $s (@socks) {
        local $/;
        my $res = <$s>;
        close $s;
        next unless defined $res
            && $res =~ /pid=(\d+) held=(\d) fence=(\d+) holder=(\d+)/;
        $by_pid{$1} = { held => $2, fence => $3, holder => $4 };
    }
    $round_took = Time::HiRes::time() - $t0;
    if ($round_took >= $ROUND_MAX) { $rounds_slow++ }
    elsif (1 < grep { $by_pid{$_}{held} } keys %by_pid) { $two_at_once++ }
    return %by_pid;
}

http_get();   # the pool is up
my ($fast, %r) = (0);
for (1 .. 20) {
    %r = round();
    if ($round_took < $ROUND_MAX) { $fast = 1; last }
}
cmp_ok(scalar(keys %r), '>=', 1, 'at least one worker answered');

SKIP: {
    skip 'no round finished inside the lease ttl on this box', 2 unless $fast;
    my %named = map { $r{$_}{holder} => 1 } keys %r;
    is(scalar(keys %named), 1, 'every worker names the same holder')
        or diag(explain \%r);
    my ($named) = keys %named;
    cmp_ok($named || 0, '>', 0, "and it is a real pid ($named)");
}

# The holder's own voice, for the fencing token: keep asking until the process
# holding the lease is one of the ones answering. It cannot take long - a
# holder that stops getting requests stops renewing, and the lease lapses to
# whoever is serving within the ttl.
my ($leader, $fence);
for (1 .. 40) {
    my @h = grep { $r{$_}{held} } keys %r;
    if (@h) { ($leader) = @h; $fence = $r{$leader}{fence}; last }
    Time::HiRes::sleep(0.1);
    %r = round();
}
ok($leader, 'the worker holding the lease says so when it answers');

if ($leader) {
    cmp_ok($fence, '>', 0, "and it has a fencing token ($fence)");

    # Renewed on every request by the holder, and nobody else takes it
    # meanwhile: a round the holder answered in is a round it renewed in, so
    # every reply in that round must still name it.
    %r = round();
    if (exists $r{$leader} && $round_took < $ROUND_MAX) {
        my %still = map { $r{$_}{holder} => 1 } keys %r;
        is_deeply([ keys %still ], [ $leader ],
                  'the same worker still holds it, whoever else answered');
    }

    # Kill the leader: within the ttl a survivor takes over, with a NEW token.
    kill 'KILL', $leader;
    my ($successor, $newfence);
    my $t0 = Time::HiRes::time();
    for (1 .. 80) {
        %r = round();
        my @h = grep { $r{$_}{held} && $_ != $leader } keys %r;
        if (@h == 1) { ($successor) = @h; $newfence = $r{$successor}{fence}; last }
        Time::HiRes::sleep(0.1);
    }
    my $took = Time::HiRes::time() - $t0;
    ok($successor, 'a survivor took the lease over after the leader was killed');
    # The ttl is two seconds and a respawn is quick; the bound is loose because
    # the number being asserted is a stranger's machine under load, and the
    # measurement is in the message either way.
    cmp_ok($took, '<', 8, sprintf('within the ttl and a respawn (%.1fs)', $took));
    cmp_ok($newfence, '>', $fence, 'with a fencing token that supersedes the old one')
        if defined $newfence;
}

is($two_at_once, 0, 'no round ever found two workers holding the lease');
diag("$rounds_slow round(s) took longer than the ${ROUND_MAX}s ceiling and were "
     . 'not asserted on') if $rounds_slow;

kill 'TERM', $pid;
server_reap($pid);
done_testing;
