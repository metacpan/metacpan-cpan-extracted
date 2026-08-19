#!/usr/bin/env perl
# Multiplex several transfers over one HTTP/2 connection. The client opts in
# with CURLMOPT_PIPELINING, and each request adds CURLOPT_PIPEWAIT so curl
# waits for the shared connection instead of opening another one.
use strict;
use warnings;
use EV;
use EV::YACurl ':constants';

my @urls = @ARGV ? @ARGV : map { "https://www.perl.org$_" } qw(
    / /get.html /docs/ /books/ /about.html
);

# CURL_HTTP_VERSION_3 only exists from libcurl 7.66 on.
my %version = (
    CURL_HTTP_VERSION_1_0, '1.0',
    CURL_HTTP_VERSION_1_1, '1.1',
    CURL_HTTP_VERSION_2_0, '2',
);
$version{ EV::YACurl::CURL_HTTP_VERSION_3() } = '3'
    if defined &EV::YACurl::CURL_HTTP_VERSION_3;

for my $multiplex (1, 0) {
    my $client = EV::YACurl->new({
        CURLMOPT_PIPELINING => $multiplex ? CURLPIPE_MULTIPLEX : CURLPIPE_NOTHING,
    });

    my ($left, $connections, $started) = (scalar @urls, 0, EV::time);
    my @failed;

    for my $url (@urls) {
        my $bytes = 0;

        $client->request(sub {
            my ($response, $error) = @_;
            $left--;

            if ($error) {
                push @failed, "$url: $error";
            } else {
                my $opened = $response->getinfo(CURLINFO_NUM_CONNECTS);
                $connections += $opened;
                printf "  %-40s HTTP/%s, %d bytes, %d new connection(s)\n", $url,
                    $version{ $response->getinfo(CURLINFO_HTTP_VERSION) } // '?',
                    $bytes, $opened;
            }

            EV::break unless $left;
        }, {
            CURLOPT_URL => $url,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_2TLS,
            CURLOPT_PIPEWAIT => $multiplex,
            CURLOPT_WRITEFUNCTION => sub { $bytes += length $_[0] },
        });
    }

    printf "%s:\n", $multiplex ? 'multiplexed' : 'one connection per transfer';
    EV::run;
    printf "  %d transfer(s) over %d connection(s) in %.2fs\n\n",
        scalar @urls, $connections, EV::time - $started;

    warn "$_\n" for @failed;
}
