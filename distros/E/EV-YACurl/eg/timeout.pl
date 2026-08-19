#!/usr/bin/env perl
# Two ways to stop work that takes too long: a per-request deadline enforced by
# libcurl (CURLOPT_TIMEOUT_MS), and cancelling a transfer that is already in
# flight by returning undef from its read callback when an EV timer says so.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';
use IO::Socket::INET;
use POSIX ();

my ($server, $base) = start_server();

my $client = EV::YACurl->new({});
my $payload = 'x' x (4 * 1024 * 1024);
my ($sent, $cancel, $timer, $done) = (0, 0);

my $started = EV::time;
$client->request(sub {
    my ($response, $error) = @_;

    printf "deadline:  %.2fs elapsed, %s\n", EV::time - $started,
        $error || 'finished, status ' . $response->getinfo(CURLINFO_RESPONSE_CODE);

    $started = EV::time;
    $timer = EV::timer(0.5, 0, sub { $cancel = 1 });

    $client->request(sub {
        my ($response, $error) = @_;
        $done = 1;

        printf "cancelled: %.2fs elapsed, %s, %d of %d bytes sent\n", EV::time - $started,
            $error || 'finished, status ' . $response->getinfo(CURLINFO_RESPONSE_CODE),
            $sent, $sent + length $payload;
    }, {
        CURLOPT_URL => "$base/sink",
        CURLOPT_UPLOAD => 1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_INFILESIZE_LARGE => length $payload,
        CURLOPT_READFUNCTION => sub {
            return undef if $cancel;
            my $chunk = substr $payload, 0, $_[0], '';
            $sent += length $chunk;
            return $chunk;
        },
        CURLOPT_WRITEFUNCTION => sub { },
    });
}, {
    CURLOPT_URL => "$base/slow",
    CURLOPT_CONNECTTIMEOUT_MS => 1_000,
    CURLOPT_TIMEOUT_MS => 300,
    CURLOPT_WRITEFUNCTION => sub { },
});

EV::run until $done;

kill 'TERM', -$server;
waitpid $server, 0;

sub start_server {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 8, ReuseAddr => 1)
        or die "listen failed: $!\n";
    my $url = 'http://127.0.0.1:' . $listener->sockport;

    defined(my $pid = fork) or die "fork failed: $!\n";
    return ($pid, $url) if $pid;

    setpgrp 0, 0;                 # so one kill reaches the per-connection children
    $SIG{PIPE} = 'IGNORE';
    $SIG{CHLD} = 'IGNORE';

    while (my $conn = $listener->accept) {
        if (fork) {
            close $conn;
            next;
        }

        my ($buffer, $chunk) = ('');
        $buffer .= $chunk while index($buffer, "\r\n\r\n") < 0 && sysread $conn, $chunk, 65536;
        my ($head, $body) = (split(/\r\n\r\n/, $buffer, 2), '', '');
        my ($length) = $head =~ /^content-length:\s*(\d+)/im;

        # Without this reply curl sits on a large body for a second before sending it.
        print { $conn } "HTTP/1.1 100 Continue\r\n\r\n"
            if $head =~ /^expect:\s*100-continue/im;

        if ($head =~ m{\A\S+ /slow}) {
            select undef, undef, undef, 2;
        } else {
            while (length($body) < ($length || 0)) {
                sysread $conn, $chunk, 65536 or last;
                $body .= $chunk;
                select undef, undef, undef, 0.05;
            }
        }

        print { $conn } "HTTP/1.1 200 OK\r\nContent-Length: 3\r\nConnection: close\r\n\r\nok\n";
        close $conn;
        POSIX::_exit(0);
    }

    POSIX::_exit(0);
}
