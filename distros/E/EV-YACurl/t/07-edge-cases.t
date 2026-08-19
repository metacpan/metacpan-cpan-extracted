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

    return (200, [], '')                      if $path eq '/empty';
    return (200, [], $request->{body})        if $path eq '/echo-body';
    return (200, ['Content-Type' => 'application/octet-stream'],
                 join('', map { chr } 0 .. 255))
        if $path eq '/binary';
    return (200, ['X-Multi' => 'value1', 'X-Multi' => 'value2'], 'OK')
        if $path eq '/multi-header';

    if ($path eq '/echo-headers') {
        my $headers = $request->{headers};
        return (200, [], join "\n", map { "$_: $headers->{$_}" } sort keys %$headers);
    }

    if (my ($ms) = $path =~ m{^/delay/(\d+)}) {
        select undef, undef, undef, $ms / 1000;
        return (200, [], "delayed $ms ms");
    }

    return (200, [], 'OK');
});

my $base = $server->base_url;

plan tests => 19;

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/empty",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Empty response: got response");
    is($body // '', '', "Empty response: body is empty");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err);
    my $done = 0;
    my $die_count = 0;

    local $SIG{__WARN__} = sub { };  # Suppress warnings

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/",
        CURLOPT_WRITEFUNCTION => sub {
            $die_count++;
            die "Intentional death in callback" if $die_count == 1;
        },
    });

    EV::run until $done;
    ok($res || $err, "Callback die: request completed");
    ok($die_count >= 1, "Callback die: callback was called");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    my $upload_data = "Hello, this is upload data! " x 100;
    my $offset = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/echo-body",
        CURLOPT_UPLOAD => 1,
        CURLOPT_INFILESIZE => length($upload_data),
        CURLOPT_READFUNCTION => sub {
            my $maxlen = shift;
            my $chunk = substr($upload_data, $offset, $maxlen);
            $offset += length($chunk);
            return $chunk;
        },
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Upload: got response") or diag("Error: $err");
    is($body, $upload_data, "Upload: data echoed correctly");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err);
    my $done = 0;
    my @debug_output;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/",
        CURLOPT_VERBOSE => 1,
        CURLOPT_DEBUGFUNCTION => sub {
            my ($type, $data) = @_;
            push @debug_output, [$type, $data];
        },
        CURLOPT_WRITEFUNCTION => sub { },
    });

    EV::run until $done;
    ok($res, "Debug: got response");
    ok(scalar @debug_output > 0, "Debug: captured " . scalar(@debug_output) . " debug messages");

    my %types = map { $_->[0] => 1 } @debug_output;
    ok(exists $types{CURLINFO_TEXT()}, "Debug: has text output");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/binary",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Binary: got response");
    is(length($body), 256, "Binary: correct length");

    my $expected = join('', map { chr($_) } 0..255);
    is($body, $expected, "Binary: all bytes correct");
}

# A server that never answers must be abandoned on the timeout.
# TestServer forks per connection, so the stuck one costs nothing here.
{
    my $silent = TestServer->new(sub { sleep 30; (200, [], 'too late') });
    my $client = EV::YACurl->new({});
    my ($res, $err);
    my $done = 0;
    my $started = EV::time();

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => $silent->base_url . '/',
        CURLOPT_TIMEOUT_MS => 400,
        CURLOPT_WRITEFUNCTION => sub { },
    });

    EV::run until $done;
    ok(!$res, "Timeout: no response");
    like($err // '', qr/timed?\s*out/i, "Timeout: error message ($err)");
    cmp_ok(EV::time() - $started, '<', 5, 'Timeout: gave up promptly');
}

{
    my $client = EV::YACurl->new({});
    my $completed = 0;
    my @connect_times;

    for (1..3) {
        my $done = 0;
        my $response;

        $client->request(sub {
            ($response, my $err) = @_;
            if ($response) {
                push @connect_times, $response->getinfo(CURLINFO_NUM_CONNECTS);
            }
            $done = 1;
            $completed++;
        }, {
            CURLOPT_URL => "$base/",
            CURLOPT_WRITEFUNCTION => sub { },
        });

        EV::run until $done;
    }

    is($completed, 3, "Keep-alive: all requests completed");
    # On localhost a reconnect is as fast as the first connect, so timing proves
    # nothing here; the count of new connections does.
    is_deeply([@connect_times[1, 2]], [0, 0], "Keep-alive: later requests opened no connection")
        or diag "num_connects: @connect_times";
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err);
    my $done = 0;
    my @headers;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/multi-header",
        CURLOPT_WRITEFUNCTION => sub { },
        CURLOPT_HEADERFUNCTION => sub { push @headers, $_[0] },
    });

    EV::run until $done;
    ok($res, "Headers: got response");
    ok(scalar @headers >= 2, "Headers: captured " . scalar(@headers) . " headers");
}
