#!/usr/bin/env perl
# Fetch many URLs at once through a single client, with a cap on how many are
# in flight. One client means one connection pool, so hosts that appear more
# than once get keep-alive and HTTP/2 multiplexing for free.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $limit = 4;
my @urls = @ARGV ? @ARGV : map { "https://www.perl.org$_" } qw(
    / /get.html /docs/ /books/ /about.html /learn.html
);

my $client = EV::YACurl->new({ CURLMOPT_MAX_TOTAL_CONNECTIONS => $limit });

my @queue = @urls;
my $running = 0;
my $done = 0;

my $pump;
$pump = sub {
    while ($running < $limit && @queue) {
        my $url = shift @queue;
        my $bytes = 0;
        $running++;

        $client->request(sub {
            my ($response, $error) = @_;
            $running--;
            $done++;

            printf "%-45s %s\n", $url,
                $error ? "failed: $error"
                       : sprintf('%d, %d bytes, %d new connection(s)',
                                 $response->getinfo(CURLINFO_RESPONSE_CODE),
                                 $bytes,
                                 $response->getinfo(CURLINFO_NUM_CONNECTS));

            $pump->();
        }, {
            CURLOPT_URL => $url,
            CURLOPT_FOLLOWLOCATION => 1,
            CURLOPT_WRITEFUNCTION => sub { $bytes += length $_[0] },
        });
    }
};

$pump->();
EV::run until $done == @urls;
