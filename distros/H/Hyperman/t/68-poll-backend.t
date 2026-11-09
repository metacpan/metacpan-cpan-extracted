#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# The readiness floor, poll(2), serving requests: a response too big for one
# write arms the write watcher, a keep-alive connection changes its interest,
# and the idle sweep runs on its interval timer.

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;
plan skip_all => 'the poll backend is not on Windows' if $^O eq 'MSWin32';

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    $ENV{HYPERMAN_BACKEND} = 'poll';
    Hyperman->run(
        app => sub {
            my $env = shift;
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'x' x (4 * 1024 * 1024) ] ]
                if $env->{PATH_INFO} eq '/big';
            [ 200, [ 'Content-Type' => 'text/plain' ], [ Hyperman->stats->{backend} ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1, idle_timeout => 1,
    );
    exit 0;
}

my $s;
for (1 .. 50) {
    $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}
ok($s, 'the server is up');

sub read_response {
    my ($sock) = @_;
    my $buf = '';
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 10;
    while ($buf !~ /\r\n\r\n/) { my $n = $sock->sysread(my $c, 65536) or last; $buf .= $c }
    my ($len) = $buf =~ /Content-Length: (\d+)/;
    my $body = (split /\r\n\r\n/, $buf, 2)[1] // '';
    while (defined $len && length $body < $len) { my $n = $sock->sysread(my $c, 65536) or last; $body .= $c }
    alarm 0;
    return ($buf, $body);
}

$s->syswrite("GET / HTTP/1.1\r\nHost: a\r\n\r\n");
my ($hdr, $body) = read_response($s);
is($body, 'poll', 'the worker runs on the poll backend');
$s->syswrite("GET /big HTTP/1.1\r\nHost: a\r\n\r\n");
($hdr, $body) = read_response($s);
is(length $body, 4 * 1024 * 1024, 'a four megabyte response arrives whole over the write watcher');
$s->syswrite("GET / HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
($hdr, $body) = read_response($s);
is($body, 'poll', 'and the connection still answers after it');
close $s;

my $idle = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
ok($idle, 'an idle connection');
my $gone = 0;
for (1 .. 60) {
    Time::HiRes::sleep(0.1);
    my $n = $idle->sysread(my $c, 10);
    if (defined $n && $n == 0) { $gone = 1; last }
}
ok($gone, 'the idle sweep on the interval timer closed it');

kill 'TERM', $pid;
is(server_reap($pid) >> 8, 0, 'the server stopped cleanly');
done_testing;
