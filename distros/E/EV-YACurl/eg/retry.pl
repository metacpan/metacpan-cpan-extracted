#!/usr/bin/env perl
# Retry a failing request with exponential backoff, driven by an EV timer so
# the loop keeps running meanwhile. The local server at the bottom fails the
# first two attempts, asking for a delay on the second.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';
use IO::Socket::INET;
use POSIX ();

my $attempts = 5;
my $backoff  = 0.1;

my ($server, $base) = start_server();

my $client = EV::YACurl->new({});
my ($attempt, $timer, $done, $failed) = (0);

my $try;
$try = sub {
    $attempt++;
    my ($body, $retry_after) = ('');

    $client->request(sub {
        my ($response, $error) = @_;
        my $status = $error ? 0 : $response->getinfo(CURLINFO_RESPONSE_CODE);
        my $problem = $error || ($status >= 500 ? "status $status" : undef);

        unless ($problem) {
            printf "attempt %d: %d, %d bytes\n", $attempt, $status, length $body;
            $done = 1;
            return;
        }

        if ($attempt >= $attempts) {
            ($done, $failed) = (1, "gave up after $attempt attempts: $problem");
            return;
        }

        my $delay = defined $retry_after ? $retry_after : $backoff * 2 ** ($attempt - 1);
        printf "attempt %d: %s, retrying in %.2fs%s\n", $attempt, $problem, $delay,
            defined $retry_after ? ' (server asked)' : '';

        # The watcher must outlive this callback or dropping it cancels the retry.
        $timer = EV::timer($delay, 0, $try);
    }, {
        CURLOPT_URL => "$base/flaky",
        CURLOPT_HEADERFUNCTION => sub {
            $retry_after = $1 if $_[0] =~ /^retry-after:\s*(\d+)/i;
        },
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });
};

$try->();
EV::run until $done;

kill 'TERM', $server;
waitpid $server, 0;
die "$base/flaky: $failed\n" if $failed;

sub start_server {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 8, ReuseAddr => 1)
        or die "listen failed: $!\n";
    my $url = 'http://127.0.0.1:' . $listener->sockport;

    defined(my $pid = fork) or die "fork failed: $!\n";
    return ($pid, $url) if $pid;

    $SIG{PIPE} = 'IGNORE';
    my $seen = 0;

    while (my $conn = $listener->accept) {
        my ($buffer, $chunk) = ('');
        $buffer .= $chunk while index($buffer, "\r\n\r\n") < 0 && sysread $conn, $chunk, 65536;

        $seen++;
        my ($status, $headers, $body) = $seen > 2
            ? (200, [], "the service is back\n")
            : (503, $seen == 2 ? ['Retry-After: 1'] : [], "try again later\n");

        print { $conn } "HTTP/1.1 $status Status\r\n", map("$_\r\n", @$headers),
            "Content-Type: text/plain\r\n",
            "Content-Length: ", length $body, "\r\nConnection: close\r\n\r\n", $body;
        close $conn;
    }

    POSIX::_exit(0);
}
