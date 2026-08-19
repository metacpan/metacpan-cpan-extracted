#!/usr/bin/env perl
# The smallest useful request: fetch one URL and report on it.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $url = shift || 'https://www.perl.org/';

my $client = EV::YACurl->new({});
my $body = '';
my $done = 0;

$client->request(sub {
    my ($response, $error) = @_;

    if ($error) {
        warn "$url: $error\n";
    } else {
        printf "%s\n  status    %d\n  type      %s\n  bytes     %d\n  total     %.3fs\n",
            $response->getinfo(CURLINFO_EFFECTIVE_URL),
            $response->getinfo(CURLINFO_RESPONSE_CODE),
            $response->getinfo(CURLINFO_CONTENT_TYPE) // 'unknown',
            length $body,
            $response->getinfo(CURLINFO_TOTAL_TIME_T) / 1_000_000;
    }

    $done = 1;
}, {
    CURLOPT_URL => $url,
    CURLOPT_FOLLOWLOCATION => 1,
    CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
});

EV::run until $done;
