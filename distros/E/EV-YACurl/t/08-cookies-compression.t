use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempfile);
use IO::Compress::Gzip qw(gzip);
use IO::Compress::Deflate qw(deflate);
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

sub compressed {
    my ($encoding, $data) = @_;
    my $out;

    $encoding eq 'gzip' ? gzip(\$data, \$out) : deflate(\$data, \$out)
        or die "$encoding failed";

    return (200, ['Content-Encoding' => $encoding], $out);
}

my $server = TestServer->new(sub {
    my ($request) = @_;
    my $path = $request->{path};

    return (200, ['Set-Cookie' => 'session=abc123; Path=/',
                  'Set-Cookie' => 'user=testuser; Path=/'], 'Cookies set')
        if $path eq '/set-cookie';
    return (200, ['Set-Cookie' => 'temp=value; Path=/; Max-Age=3600'], 'Temp cookie set')
        if $path eq '/set-expire-cookie';
    return (200, [], 'Cookie: ' . ($request->{headers}{cookie} // 'none'))
        if $path eq '/check-cookie';

    return compressed(gzip => 'Hello, this is gzip compressed data! ' x 50)
        if $path eq '/gzip';
    return compressed(deflate => 'Hello, this is deflate compressed data! ' x 50)
        if $path eq '/deflate';
    return (200, [], 'Accept-Encoding: ' . ($request->{headers}{'accept-encoding'} // 'none'))
        if $path eq '/echo-encoding';

    if ($path eq '/auto-compress') {
        my $accept = $request->{headers}{'accept-encoding'} // '';
        my $data = 'This content may be compressed based on Accept-Encoding! ' x 50;

        return compressed(gzip    => $data) if $accept =~ /gzip/;
        return compressed(deflate => $data) if $accept =~ /deflate/;
        return (200, [], $data);
    }

    return (200, [], 'OK');
});

my $base = $server->base_url;

plan tests => 15;

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/set-cookie",
        CURLOPT_COOKIEFILE => "",  # Enable cookie engine with in-memory storage
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Cookie set: got response") or diag("Error: $err");
    like($body // '', qr/Cookies set/, "Cookie set: correct response");
}

{
    my $client = EV::YACurl->new({});

    my (undef, $cookie_file) = tempfile(UNLINK => 1);

    my $done = 0;
    $client->request(sub { $done = 1 }, {
        CURLOPT_URL => "$base/set-cookie",
        CURLOPT_COOKIEJAR => $cookie_file,
        CURLOPT_COOKIEFILE => $cookie_file,
        CURLOPT_WRITEFUNCTION => sub { },
    });
    EV::run until $done;

    my ($res, $err, $body);
    $done = 0;
    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/check-cookie",
        CURLOPT_COOKIEJAR => $cookie_file,
        CURLOPT_COOKIEFILE => $cookie_file,
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });
    EV::run until $done;

    ok($res, "Cookie check: got response") or diag("Error: $err");
    like($body // '', qr/session=abc123/, "Cookie check: session cookie sent back");
}

{
    my (undef, $cookie_file) = tempfile(UNLINK => 1);

    {
        my $client = EV::YACurl->new({});
        my $done = 0;
        $client->request(sub { $done = 1 }, {
            CURLOPT_URL => "$base/set-cookie",
            CURLOPT_COOKIEJAR => $cookie_file,
            CURLOPT_WRITEFUNCTION => sub { },
        });
        EV::run until $done;
    }

    {
        my $client = EV::YACurl->new({});
        my ($res, $err, $body);
        my $done = 0;
        $client->request(sub {
            ($res, $err) = @_;
            $done = 1;
        }, {
            CURLOPT_URL => "$base/check-cookie",
            CURLOPT_COOKIEFILE => $cookie_file,
            CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        });
        EV::run until $done;

        like($body // '', qr/session=abc123/, "Cookie persistence: cookies loaded from file");
    }
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/gzip",
        CURLOPT_ACCEPT_ENCODING => "gzip",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Gzip: got response") or diag("Error: $err");
    like($body // '', qr/Hello, this is gzip compressed data!/, "Gzip: data decompressed");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/deflate",
        CURLOPT_ACCEPT_ENCODING => "deflate",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Deflate: got response") or diag("Error: $err");
    like($body // '', qr/Hello, this is deflate compressed data!/, "Deflate: data decompressed");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/echo-encoding",
        CURLOPT_ACCEPT_ENCODING => "gzip, deflate",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Accept-Encoding: got response");
    like($body // '', qr/gzip.*deflate|deflate.*gzip/i, "Accept-Encoding: header sent");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/echo-encoding",
        CURLOPT_ACCEPT_ENCODING => "",  # All supported
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "All encodings: got response");
    like($body // '', qr/Accept-Encoding:.*\S/, "All encodings: header sent with supported types");
}

{
    my $client = EV::YACurl->new({});
    my ($res, $err, $body);
    my $done = 0;

    $client->request(sub {
        ($res, $err) = @_;
        $done = 1;
    }, {
        CURLOPT_URL => "$base/auto-compress",
        CURLOPT_ACCEPT_ENCODING => "",  # Accept any
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
    });

    EV::run until $done;
    ok($res, "Auto-compress: got response") or diag("Error: $err");
    like($body // '', qr/This content may be compressed/, "Auto-compress: transparent decompression");
}
