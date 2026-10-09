use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_KEEPALIVE);
use EV;
use EV::Memcached;

plan skip_all => 'requires /proc/self/fd' unless -d '/proc/self/fd';
my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
    Proto => 'tcp', Listen => 5) or plan skip_all => "cannot listen: $!";
my $connected;
my $mc = EV::Memcached->new(host => '127.0.0.1', port => $listener->sockport,
    keepalive => 5, on_error => sub { diag "@_"; EV::break },
    on_connect => sub { $connected = 1; EV::break });
my $t = EV::timer 2, 0, sub { EV::break };
EV::run;
ok($connected, 'TCP connection established with keepalive');

opendir my $dir, '/proc/self/fd' or die $!;
my @fds = readdir $dir;
closedir $dir;
my $socket;
for my $fd (@fds) {
    next unless $fd =~ /^\d+$/ && (readlink("/proc/self/fd/$fd") // '') =~ /^socket:/;
    open my $probe, '<&', $fd or next;
    my $option = getsockopt($probe, SOL_SOCKET, SO_KEEPALIVE);
    next unless defined $option && unpack('i', $option);
    $socket = $probe;
    last;
}
ok($socket, 'keepalive enabled on the client socket');
SKIP: {
    skip 'client socket unavailable', 2 unless $socket;
    $mc->keepalive(0);
    is(unpack('i', getsockopt($socket, SOL_SOCKET, SO_KEEPALIVE)), 0,
        'keepalive(0) disables the live socket option');
    $mc->keepalive(10);
    is(unpack('i', getsockopt($socket, SOL_SOCKET, SO_KEEPALIVE)), 1,
        'keepalive can be enabled again');
}
$mc->disconnect;
done_testing;
