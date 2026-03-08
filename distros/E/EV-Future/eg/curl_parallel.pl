use strict;
use warnings;
use EV;
use EV::Future;
use AnyEvent::YACurl ':constants';
use feature 'say';

# Fetch multiple URLs in parallel with concurrency limit
my $client = AnyEvent::YACurl->new({});

my @urls = (
    'https://httpbin.org/get?n=1',
    'https://httpbin.org/get?n=2',
    'https://httpbin.org/get?n=3',
    'https://httpbin.org/get?n=4',
    'https://httpbin.org/get?n=5',
    'https://httpbin.org/get?n=6',
);

say "Fetching " . scalar(@urls) . " URLs (max 2 concurrent)...";

parallel_limit([
    map {
        my $url = $_;
        sub {
            my $done = shift;
            my $body = '';
            $client->request(sub {
                my ($resp, $err) = @_;
                if ($err) {
                    say "  FAIL $url: $err";
                } else {
                    my $code = $resp->getinfo(CURLINFO_RESPONSE_CODE);
                    say "  $code $url (" . length($body) . " bytes)";
                }
                $done->();
            }, {
                CURLOPT_URL => $url,
                CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
            });
        }
    } @urls
], 2, sub {
    say "All requests finished.";
    EV::break;
});

EV::run;
