#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# THE TUNNEL ON EVERY BACKEND THIS BOX HAS.
#
# A 101 stream handle turns an HTTP/1.1 connection into a tunnel whose bytes
# belong to the handle both ways. The read half has TWO ways of finishing a
# read - a readiness watcher (kqueue, epoll, poll) hands it to hm_readable, a
# completion (io_uring with completion reads) lands in HM_EV_RECV - and 0.48
# only taught one of them about tunnels. The other fed the bytes to the
# request parser, which kept them as the start of a request that never came.
#
# t/41 could not see it: the default chooser picks kqueue here and epoll
# without liburing, and the completion path only ever ran on the six Linux
# smokers that reported it. So this file runs the same two tunnel cases once
# per backend the box can build a loop on, and on io_uring with completion
# both on and off. A backend that is not available is noted, not skipped
# silently - the count of servers actually driven is the proof of coverage.

my @backends;
push @backends, ['kqueue',   undef] if Hyperman::Event::Kqueue->available;
push @backends, ['epoll',    undef] if Hyperman::Event::Epoll->available;
push @backends, ['poll',     undef] if Hyperman::Event::Poll->available;
if (Hyperman::Event::IOUring->available) {
    push @backends, ['io_uring', 1], ['io_uring', 0];
}
plan skip_all => 'no backend is available here' unless @backends;

my $driven = 0;

for my $case (@backends) {
    my ($backend, $completion) = @$case;
    my $label = $backend
              . (defined $completion ? " completion=$completion" : '');

    my ($port) = free_ports(1);
    ok($port, "$label: a free loopback port") or next;

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        quiet_child();
        # The chooser reads HYPERMAN_BACKEND; run() has no backend key, and
        # completion is a run option so the env override is not relied on.
        $ENV{HYPERMAN_BACKEND} = $backend;
        Hyperman->run(
            app => sub {
                my $env = shift;
                my $p   = $env->{PATH_INFO};
                if ($p eq '/backend') {
                    my $s = Hyperman->stats;
                    return [ 200, [ 'Content-Type' => 'text/plain' ],
                             [ $s->{backend} ] ];
                }
                if ($p eq '/tunnel') {
                    Hyperman::_abi_stream_open($env, 101,
                        [ 'Upgrade' => 'echo', 'Connection' => 'Upgrade' ])
                        or return [ 500, [ 'Content-Type' => 'text/plain' ],
                                    ['no tunnel'] ];
                    Hyperman::_abi_stream_read();
                    Hyperman::_abi_stream_write("hello;");
                    return [ 101, [], [] ];
                }
                if ($p eq '/tunnel-deferred') {
                    return sub {
                        Hyperman::_abi_stream_open($env, 101,
                            [ 'Upgrade' => 'echo', 'Connection' => 'Upgrade' ])
                            or return;
                        Hyperman::_abi_stream_read();
                        Hyperman::_abi_stream_write("deferred;");
                    };
                }
                if ($p eq '/tunnel-rx') {
                    my ($n, $len, $bytes) = Hyperman::_abi_stream_rx();
                    return [ 200, [ 'Content-Type' => 'text/plain' ], [$bytes] ];
                }
                if ($p eq '/tunnel-close') {
                    my $r = Hyperman::_abi_stream_close();
                    return [ 200, [ 'Content-Type' => 'text/plain' ], ["close=$r"] ];
                }
                return [ 404, [ 'Content-Type' => 'text/plain' ], ['?'] ];
            },
            host    => '127.0.0.1',
            port    => $port,
            workers => 1,
            (defined $completion ? (completion => $completion) : ()),
        );
        exit 0;
    }

    my $connect = sub {
        my $s;
        for (1 .. 100) {
            $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1',
                                       PeerPort => $port, Proto => 'tcp');
            last if $s;
            Time::HiRes::sleep(0.05);
        }
        return $s;
    };
    my $body = sub {
        my ($path) = @_;
        my $s = $connect->() or return;
        syswrite $s, "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                   . "Connection: close\r\n\r\n";
        my $resp = '';
        while (1) {
            my $n = sysread $s, my $buf, 65536;
            last if !defined $n || $n == 0;
            $resp .= $buf;
        }
        close $s;
        my (undef, $b) = split /\r\n\r\n/, $resp, 2;
        return defined $b ? $b : '';
    };
    # Read until the pattern matches, or EOF, or the timeout.
    my $read_until = sub {
        my ($s, $re, $timeout) = @_;
        require IO::Select;
        my $sel = IO::Select->new($s);
        my $got = '';
        my $deadline = Time::HiRes::time() + $timeout;
        while (!defined $re || $got !~ $re) {
            my $left = $deadline - Time::HiRes::time();
            last if $left <= 0 || !$sel->can_read($left);
            my $n = sysread($s, my $b, 4096);
            last unless $n;
            $got .= $b;
        }
        return $got;
    };

    # NOT OPTIONAL: a server that quietly fell back to another backend would
    # pass every check below without testing the one this case is for.
    is($body->('/backend'), $backend, "$label: the worker runs on $backend");
    $driven++;

    for my $t (['/tunnel', 'hello;', 'synchronous'],
               ['/tunnel-deferred', 'deferred;', 'deferred']) {
        my ($path, $first, $how) = @$t;
        my $s = $connect->();
        ok($s, "$label: connected for the $how tunnel") or next;
        syswrite $s, "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                   . "Upgrade: echo\r\nConnection: Upgrade\r\n\r\nearly;";
        my $got = $read_until->($s, qr/\Q$first\E/, 5);
        my ($head, $b) = split /\r\n\r\n/, $got, 2;
        like($head || '', qr{^HTTP/1\.1 101 }, "$label: $how: a 101 went out");
        is($b, $first, "$label: $how: the first write followed the headers raw");

        # The bytes that arrive AFTER the upgrade are the ones that took the
        # other path. Converge rather than sleep: a healthy server shows them
        # on the first look, and only a deaf one pays the bound.
        syswrite $s, 'ping-from-client';
        my $rx = '';
        my $deadline = Time::HiRes::time() + 5;
        while (Time::HiRes::time() < $deadline) {
            $rx = $body->('/tunnel-rx');
            last if $rx eq 'early;ping-from-client';
            Time::HiRes::sleep(0.02);
        }
        is($rx, 'early;ping-from-client',
           "$label: $how: bytes sent with the request and afterwards both "
         . "reached the read half, in order");
        is($body->('/tunnel-close'), 'close=0', "$label: $how: stream_close");
        is($read_until->($s, undef, 3), '',
           "$label: $how: closing the handle closed the connection");
        close $s;
    }

    kill 'TERM', $pid;
    server_reap($pid);
}

cmp_ok($driven, '>=', 1, "drove the tunnel through $driven backend configuration(s): "
                       . join(', ', map { $_->[0] . (defined $_->[1] ? "/c$_->[1]" : '') } @backends));

done_testing();
