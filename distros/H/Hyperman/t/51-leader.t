#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# THE LEADER. Hyperman->leader is the lease on the server's arena: exactly one
# worker holds it at a time, and when that worker is killed another takes it
# over within the ttl. Two workers, each asked to acquire on every request;
# the answers are collected from outside and never assume which worker won.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'Shared::Arena is not available to this Hyperman'
    if $ENV{HYPERMAN_NO_SA_ABI} || !eval { require Shared::Arena; 1 };

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

is(Hyperman->leader('t51'), undef, 'no arena, no leader, undef');

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    my $lease;
    Hyperman->run(
        app => sub {
            $lease //= Hyperman->leader('t51', ttl => 2);
            my $held = $lease->acquire ? 1 : 0;
            my $out  = "pid=$$ held=$held fence=" . ($held ? $lease->fence : 0);
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

# Open several connections together so both workers answer, then read them.
sub round {
    my @socks = grep { defined }
        map { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                    Proto => 'tcp', Timeout => 2) } 1 .. 6;
    syswrite $_, "GET / HTTP/1.0\r\nHost: x\r\n\r\n" for @socks;
    my %by_pid;
    for my $s (@socks) {
        local $/;
        my $res = <$s>;
        close $s;
        next unless defined $res && $res =~ /pid=(\d+) held=(\d) fence=(\d+)/;
        $by_pid{$1} = { held => $2, fence => $3 };
    }
    return %by_pid;
}

http_get();   # the pool is up
my %r = round();
my @holders = grep { $r{$_}{held} } keys %r;
cmp_ok(scalar(keys %r), '>=', 1, 'at least one worker answered');
is(scalar @holders, 1, 'exactly one worker holds the lease');
my ($leader) = @holders;
my $fence = $r{$leader}{fence};
cmp_ok($fence, '>', 0, "and it has a fencing token ($fence)");

# Renewed on every request by the holder, nobody else gets it meanwhile.
%r = round();
is_deeply([ grep { $r{$_}{held} } keys %r ], [ grep { $_ == $leader } keys %r ],
          'the same worker still holds it, whoever else answered') if exists $r{$leader};

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
cmp_ok($took, '<', 4, sprintf('within the ttl and a respawn (%.1fs)', $took));
cmp_ok($newfence, '>', $fence, 'with a fencing token that supersedes the old one')
    if defined $newfence;

kill 'TERM', $pid;
server_reap($pid);
done_testing;
