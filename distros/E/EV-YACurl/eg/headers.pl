#!/usr/bin/env perl
# Send request headers, collect response headers, and read the transfer's
# metadata back out of the response object.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my $url = shift || 'https://www.perl.org/';

my $client = EV::YACurl->new({});
my (@headers, $done, $failed);

$client->request(sub {
    my ($response, $error) = @_;
    $done = 1;
    return $failed = $error if $error;

    print "request took ", $response->getinfo(CURLINFO_TOTAL_TIME_T) / 1_000_000, "s\n";
    print "  connect  ", $response->getinfo(CURLINFO_CONNECT_TIME_T) / 1_000_000, "s\n";
    print "  redirects ", $response->getinfo(CURLINFO_REDIRECT_COUNT), "\n";
    print "  final url ", $response->getinfo(CURLINFO_EFFECTIVE_URL), "\n\n";

    print "response headers:\n";
    print "  $_" for grep { /^\S+:/ } @headers;
}, {
    CURLOPT_URL => $url,
    CURLOPT_FOLLOWLOCATION => 1,
    CURLOPT_HTTPHEADER => [
        'X-Example: forty-two',
        'Accept: text/html',
    ],
    CURLOPT_HEADERFUNCTION => sub { push @headers, $_[0] },
    CURLOPT_WRITEFUNCTION => sub { },
});

EV::run until $done;
die "$url: $failed\n" if $failed;
