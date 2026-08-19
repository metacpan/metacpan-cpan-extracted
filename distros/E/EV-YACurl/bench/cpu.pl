#!/usr/bin/env perl
# Client-side CPU per request, against a local server, so the number reflects
# the binding rather than the network.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../t/lib";
use Getopt::Long;
use Time::HiRes qw(time);
use TestServer;
use EV;
use EV::YACurl ':constants';

my ($requests, $concurrency, $size) = (30_000, 50, 512);
GetOptions(
    'requests=i'    => \$requests,
    'concurrency=i' => \$concurrency,
    'size=i'        => \$size,
) or die "usage: $0 [--requests N] [--concurrency N] [--size BYTES]\n";

my $server = TestServer->new(sub { (200, [], 'x' x $size) });
my $url = $server->base_url . '/';

{
    my $done = 0;
    EV::YACurl->new({})->request(sub { $done = 1 },
        { CURLOPT_URL => $url, CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $done;
}

my $client = EV::YACurl->new({ CURLMOPT_MAX_TOTAL_CONNECTIONS => $concurrency });
my ($issued, $done) = (0, 0);
my @before = times();
my $started = time();

my $submit;
$submit = sub {
    while ($issued - $done < $concurrency && $issued < $requests) {
        $issued++;
        $client->request(sub { $done++; $submit->() },
            { CURLOPT_URL => $url, CURLOPT_WRITEFUNCTION => sub { } });
    }
};
$submit->();
EV::run until $done >= $requests;

my @after = times();
my $wall = time() - $started;
my $cpu = ($after[0] - $before[0]) + ($after[1] - $before[1]);

printf "requests:     %d (concurrency %d, %d byte bodies)\n", $requests, $concurrency, $size;
printf "wall:         %.3f s (%.0f req/s)\n", $wall, $requests / $wall;
printf "client cpu:   %.3f s (%.1f us/request)\n", $cpu, 1e6 * $cpu / $requests;
