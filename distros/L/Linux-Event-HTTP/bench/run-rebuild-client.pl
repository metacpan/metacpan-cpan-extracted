#!/usr/bin/env perl
use v5.36;
use Getopt::Long qw(GetOptions);
use IO::Socket::INET;
use IO::Handle;
use POSIX qw(_exit);
use Time::HiRes qw(time clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use JSON::PP;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Client;

my ($legacy, $native, $requests, $warmup, $repeats, $json) = (0, 1, 5000, 500, 3);
GetOptions('legacy!' => \$legacy, 'native-input!' => \$native,
    'requests=i' => \$requests, 'warmup=i' => \$warmup,
    'repeats=i' => \$repeats, 'json=s' => \$json) or die 'bad options';
die 'invalid workload' unless $requests > 0 && $warmup >= 0 && $repeats > 0;
$SIG{PIPE} = 'IGNORE';
my @rows;
for my $repeat (1 .. $repeats) {
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 8, ReuseAddr => 1) or die $!;
    my $port = $listener->sockport;
    my $pid = fork;
    die $! unless defined $pid;
    if (!$pid) {
        alarm 30;
        my $peer = $listener->accept or die $!;
        close $listener;
        my $buffer = '';
        my $response = "HTTP/1.1 200 OK\r\nContent-Length: 32\r\n\r\n" . ('x' x 32);
        for (1 .. $requests + $warmup) {
            while (index($buffer, "\r\n\r\n") < 0) {
                my $n = sysread($peer, my $chunk, 65536);
                die 'client EOF' unless $n;
                $buffer .= $chunk;
            }
            substr($buffer, 0, index($buffer, "\r\n\r\n") + 4, '');
            my $offset = 0;
            while ($offset < length $response) {
                my $n = syswrite($peer, $response, length($response) - $offset, $offset);
                die $! unless $n;
                $offset += $n;
            }
        }
        close $peer;
        _exit(0);
    }
    close $listener;
    my $loop = Linux::Event::Loop->new;
    my $client = Linux::Event::HTTP::Client->new(loop => $loop,
        ($legacy ? () : (native_input => $native, max_connections_per_origin => 1)));
    my ($seen, $wall_start, $cpu_start, $wall, $cpu) = (0);
    my $issue;
    my $complete = sub {
        ++$seen;
        if ($seen == $warmup) {
            $wall_start = time;
            $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
        }
        if ($seen == $requests + $warmup) {
            $wall = time - $wall_start;
            $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;
            $loop->stop;
        } else {
            $loop->defer($issue);
        }
    };
    $issue = sub {
        $client->get("http://127.0.0.1:$port/",
            ($legacy ? (buffer_body => 1_048_576, on_complete => $complete)
                     : (on_finish => $complete)),
            on_error => sub ($object, $error) { die "$error\n" },
        );
    };
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 25,
        on_timer => sub { die "client benchmark timed out\n" });
    $wall_start = time;
    $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    $issue->();
    $loop->run;
    $guard->cancel;
    $legacy ? $client->close : $client->shutdown;
    undef $issue;
    waitpid($pid, 0);
    die 'responder failed' if $?;
    my $row = { repeat => $repeat, requests_per_second => $requests / $wall,
        client_cpu_us_per_request => $cpu * 1_000_000 / $requests };
    push @rows, $row;
    printf "repeat=%d %.1f req/s client_cpu=%.3f us/req\n",
        $repeat, $row->{requests_per_second}, $row->{client_cpu_us_per_request};
}
if ($json) {
    open my $fh, '>', $json or die "$json: $!";
    print {$fh} JSON::PP->new->canonical->pretty->encode({
        legacy => $legacy, native_input => $native, requests => $requests,
        warmup => $warmup, repeats => $repeats, connections => 1, records => \@rows });
    close $fh or die $!;
}
