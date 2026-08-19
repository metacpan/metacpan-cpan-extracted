use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;
    my $path = $request->{path};

    return (200, [], 'GET OK')                            if $path eq '/get';
    return (200, [], "POST:$request->{body}")             if $path eq '/post';
    return (200, [], 'Header:' . ($request->{headers}{'x-custom-header'} // 'none'))
        if $path eq '/headers';
    return (302, ['Location' => '/get'], 'Redirecting')   if $path eq '/redirect';
    return (302, ['Location' => '/redirect-loop'], 'Loop') if $path eq '/redirect-loop';
    return (200, [], 'x' x 100_000)                       if $path eq '/large';
    return (200, [], $request->{method})                  if $path eq '/echo-method';

    if ($path eq '/slow') {
        sleep 2;
        return (200, [], 'Slow OK');
    }

    return (404, [], 'Not Found');
});

my $base = $server->base_url;

sub request {
    my ($opts, $timeout) = @_;
    $timeout //= 5;
    my $client = EV::YACurl->new({});
    my ($response, $error, $body);
    my $done = 0;

    $opts->{CURLOPT_WRITEFUNCTION} //= sub { $body .= $_[0] };
    $opts->{CURLOPT_TIMEOUT} //= $timeout;

    $client->request(sub {
        ($response, $error) = @_;
        $done = 1;
    }, $opts);

    EV::run until $done;
    return ($response, $error, $body);
}

plan tests => 17;

{
    my ($res, $err, $body) = request({ CURLOPT_URL => "$base/get" });
    ok($res, "GET: got response") or diag("Error: $err");
    is($body, "GET OK", "GET: correct body");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/post",
        CURLOPT_POSTFIELDS => "hello=world",
    });
    ok($res, "POST: got response") or diag("Error: $err");
    is($body, "POST:hello=world", "POST: body echoed");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/headers",
        CURLOPT_HTTPHEADER => ["X-Custom-Header: test-value-123"],
    });
    ok($res, "Headers: got response") or diag("Error: $err");
    is($body, "Header:test-value-123", "Headers: custom header received");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/redirect",
        CURLOPT_FOLLOWLOCATION => 1,
    });
    ok($res, "Redirect: got response") or diag("Error: $err");
    is($body, "GET OK", "Redirect: followed to /get");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/redirect",
        CURLOPT_FOLLOWLOCATION => 0,
    });
    ok($res, "No-follow: got response") or diag("Error: $err");
    is($res->getinfo(CURLINFO_RESPONSE_CODE), 302, "No-follow: got 302");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/redirect-loop",
        CURLOPT_FOLLOWLOCATION => 1,
        CURLOPT_MAXREDIRS => 3,
    });
    ok(!$res || $err, "Redirect loop: got error");
    like($err // '', qr/redirect|maximum/i, "Redirect loop: error mentions redirects");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/slow",
        CURLOPT_TIMEOUT => 1,
    });
    ok(!$res, "Timeout: no response");
    like($err // '', qr/timeout|timed out|operation/i, "Timeout: error mentions timeout");
}

{
    my ($res, $err, $body) = request({ CURLOPT_URL => "$base/large" });
    ok($res, "Large: got response") or diag("Error: $err");
    is(length($body // ''), 100_000, "Large: correct size");
}

{
    my ($res, $err, $body) = request({
        CURLOPT_URL => "$base/echo-method",
        CURLOPT_CUSTOMREQUEST => "DELETE",
    });
    is($body, "DELETE", "Custom method: DELETE");
}
