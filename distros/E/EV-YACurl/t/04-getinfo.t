use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;

    return (200, [], 'x' x 1000)                         if $request->{path} eq '/info';
    return (301, ['Location' => '/info'], 'Redirecting') if $request->{path} eq '/redirect-info';
    return (404, [], 'Not found');
});

my $base = $server->base_url;

plan tests => 12;

{
    my $client = EV::YACurl->new({});
    my ($response, $error, $body);
    my $done = 0;

    $client->request(sub {
        ($response, $error) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/info",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;

    ok($response, "Got response");

    is($response->getinfo(CURLINFO_RESPONSE_CODE), 200, "CURLINFO_RESPONSE_CODE");
    is($response->getinfo(CURLINFO_CONTENT_LENGTH_DOWNLOAD_T), 1000, "CURLINFO_CONTENT_LENGTH_DOWNLOAD_T");
    is($response->getinfo(CURLINFO_SIZE_DOWNLOAD_T), 1000, "CURLINFO_SIZE_DOWNLOAD_T");
    like($response->getinfo(CURLINFO_CONTENT_TYPE), qr/text\/plain/, "CURLINFO_CONTENT_TYPE");
    like($response->getinfo(CURLINFO_EFFECTIVE_URL), qr/\/info$/, "CURLINFO_EFFECTIVE_URL");
    ok($response->getinfo(CURLINFO_TOTAL_TIME_T) > 0, "CURLINFO_TOTAL_TIME_T > 0");
    ok($response->getinfo(CURLINFO_NAMELOOKUP_TIME_T) >= 0, "CURLINFO_NAMELOOKUP_TIME_T >= 0");
    ok($response->getinfo(CURLINFO_CONNECT_TIME_T) >= 0, "CURLINFO_CONNECT_TIME_T >= 0");
}

{
    my $client = EV::YACurl->new({});
    my ($response, $error);
    my $done = 0;

    $client->request(sub {
        ($response, $error) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/redirect-info",
        CURLOPT_FOLLOWLOCATION => 1,
        CURLOPT_WRITEFUNCTION => sub { },
    });

    EV::run until $done;

    is($response->getinfo(CURLINFO_RESPONSE_CODE), 200, "Final response 200 after redirect");
    is($response->getinfo(CURLINFO_REDIRECT_COUNT), 1, "CURLINFO_REDIRECT_COUNT is 1");
    like($response->getinfo(CURLINFO_EFFECTIVE_URL), qr/\/info$/, "Effective URL is final destination");
}
