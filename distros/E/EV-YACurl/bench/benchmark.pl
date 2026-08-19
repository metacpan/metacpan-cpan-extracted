#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../t/lib";
use Time::HiRes qw(time);
use Getopt::Long;
use TestServer;
use EV::YACurl ':constants';

my $url = '';
my $requests = 1000;
my $concurrency = 50;
my $local = 1;

GetOptions(
    'url=s' => \$url,
    'n=i' => \$requests,
    'c=i' => \$concurrency,
    'local!' => \$local,
) or die "Usage: $0 [-n requests] [-c concurrency] [-url URL] [--no-local]\n";

my $server;
if ($local && !$url) {
    $server = TestServer->new(sub { (200, [], 'x' x 256) });
    $url = $server->base_url . '/';
}

$url ||= 'https://httpbin.org/get';

print "EV::YACurl Benchmark\n";
print "=" x 50, "\n";
print "URL:         $url\n";
print "Requests:    $requests\n";
print "Concurrency: $concurrency\n";
print "=" x 50, "\n\n";

my $client = EV::YACurl->new({
    CURLMOPT_MAX_TOTAL_CONNECTIONS => $concurrency,
    CURLMOPT_PIPELINING => CURLPIPE_MULTIPLEX,
});

my $completed = 0;
my $success = 0;
my $failed = 0;
my $bytes = 0;
my $in_flight = 0;

my $start_time = time();

sub launch_request {
    return if $completed + $in_flight >= $requests;
    $in_flight++;

    $client->request(sub {
        my ($response, $error) = @_;
        $in_flight--;
        $completed++;

        if ($response && $response->getinfo(CURLINFO_RESPONSE_CODE) == 200) {
            $success++;
            $bytes += $response->getinfo(CURLINFO_SIZE_DOWNLOAD_T) // 0;
        } else {
            $failed++;
            warn "Request failed: $error\n" if $error && $failed <= 3;
        }

        # Progress
        if ($completed % 10 == 0 || $completed == $requests) {
            printf "\rProgress: %d/%d (%.1f%%)", $completed, $requests, 100 * $completed / $requests;
        }

        # Launch more
        launch_request() while $in_flight < $concurrency && $completed + $in_flight < $requests;
    }, {
        CURLOPT_URL => $url,
        CURLOPT_WRITEFUNCTION => sub { },
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 30,
    });
}

# Initial batch
launch_request() for 1..$concurrency;

# Run event loop
EV::run until $completed >= $requests;

my $elapsed = time() - $start_time;
print "\n\n";
print "Results\n";
print "-" x 50, "\n";
printf "Total time:      %.3f seconds\n", $elapsed;
printf "Requests/sec:    %.2f\n", $requests / $elapsed;
printf "Successful:      %d (%.1f%%)\n", $success, 100 * $success / $requests;
printf "Failed:          %d\n", $failed;
printf "Total bytes:     %d\n", $bytes;
printf "Avg bytes/req:   %.0f\n", $success ? $bytes / $success : 0;
printf "Throughput:      %.2f KB/s\n", $bytes / 1024 / $elapsed;
