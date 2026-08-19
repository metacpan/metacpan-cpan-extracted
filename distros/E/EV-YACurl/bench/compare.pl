#!/usr/bin/env perl
# Needs Feersum, Test::TCP and AnyEvent::YACurl, none of which this
# distribution depends on; it is a benchmark, not part of the test suite.
use strict;
use warnings;
use Time::HiRes qw(time);
use Getopt::Long;
use Test::TCP;

my $requests = 2000;
my $concurrency = 100;
my $workers = 4;

GetOptions(
    'n=i' => \$requests,
    'c=i' => \$concurrency,
    'w=i' => \$workers,
) or die "Usage: $0 [-n requests] [-c concurrency] [-w workers]\n";

# Start multiple Feersum server instances (fast XS/libev server)
my @servers;
my @urls;
for my $i (1..$workers) {
    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            require Feersum;
            require EV;
            require IO::Socket::INET;
            my $app = sub {
                return [200, ['Content-Type' => 'text/plain', 'Content-Length' => 12], ['Hello World!']];
            };
            my $s = Feersum->new;
            $s->use_socket(IO::Socket::INET->new(
                LocalAddr => '127.0.0.1',
                LocalPort => $port,
                Listen => 1024,
                ReuseAddr => 1,
            ));
            $s->psgi_request_handler($app);
            EV::run();
        },
    );
    push @servers, $server;
    push @urls, "http://127.0.0.1:" . $server->port . "/";
}

print "=" x 60, "\n";
print "EV::YACurl vs AnyEvent::YACurl Benchmark\n";
print "=" x 60, "\n";
print "Requests:    $requests\n";
print "Concurrency: $concurrency\n";
print "Servers:     $workers x Feersum (round-robin)\n";
print "=" x 60, "\n\n";

sleep 1;

# Benchmark EV::YACurl
{
    require EV;
    require EV::YACurl;
    EV::YACurl->import(':constants');

    my $client = EV::YACurl->new({});
    my $completed = 0;
    my $success = 0;
    my $in_flight = 0;
    my $url_idx = 0;

    my $start = time();

    my $launch; $launch = sub {
        while ($in_flight < $concurrency && $completed + $in_flight < $requests) {
            $in_flight++;
            my $url = $urls[$url_idx++ % @urls];
            $client->request(sub {
                my ($res, $err) = @_;
                $in_flight--;
                $completed++;
                $success++ if $res;
                $launch->() if $completed + $in_flight < $requests;
            }, {
                CURLOPT_URL() => $url,
                CURLOPT_WRITEFUNCTION() => sub { },
            });
        }
    };
    $launch->();

    EV::run() until $completed >= $requests;

    my $elapsed = time() - $start;
    my $rps = $requests / $elapsed;

    printf "EV::YACurl\n";
    printf "  Time:         %.3f sec\n", $elapsed;
    printf "  Requests/sec: %.2f\n", $rps;
    printf "  Success:      %d/%d\n\n", $success, $requests;
}

# Benchmark AnyEvent::YACurl
{
    require AnyEvent;
    require AnyEvent::YACurl;
    AnyEvent::YACurl->import(':constants');

    my $client = AnyEvent::YACurl->new({});
    my $completed = 0;
    my $success = 0;
    my $in_flight = 0;
    my $url_idx = 0;
    my $cv = AnyEvent->condvar;

    my $start = time();

    my $launch; $launch = sub {
        while ($in_flight < $concurrency && $completed + $in_flight < $requests) {
            $in_flight++;
            my $url = $urls[$url_idx++ % @urls];
            $client->request(sub {
                my ($res, $err) = @_;
                $in_flight--;
                $completed++;
                $success++ if $res;
                if ($completed >= $requests) {
                    $cv->send;
                } else {
                    $launch->() if $completed + $in_flight < $requests;
                }
            }, {
                CURLOPT_URL() => $url,
                CURLOPT_WRITEFUNCTION() => sub { },
            });
        }
    };
    $launch->();

    $cv->recv;

    my $elapsed = time() - $start;
    my $rps = $requests / $elapsed;

    printf "AnyEvent::YACurl\n";
    printf "  Time:         %.3f sec\n", $elapsed;
    printf "  Requests/sec: %.2f\n", $rps;
    printf "  Success:      %d/%d\n\n", $success, $requests;
}

print "=" x 60, "\n";
