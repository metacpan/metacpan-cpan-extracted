use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $openssl = -x '/usr/bin/openssl' ? '/usr/bin/openssl' : undef;
if (!defined $openssl) {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'openssl');
        if (-x $candidate) {
            $openssl = $candidate;
            last;
        }
    }
}
plan skip_all => 'openssl command is required for HTTP/2 streaming upload test'
    if !defined $openssl;

my $temp = tempdir(CLEANUP => 1);
my $cert = File::Spec->catfile($temp, 'server-cert.pem');
my $key = File::Spec->catfile($temp, 'server-key.pem');

my $generated;
{
    local $ENV{OPENSSL_CONF};
    delete $ENV{OPENSSL_CONF};
    $generated = system(
        $openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', $key,
        '-out', $cert,
        '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost',
        '-days', '1',
    );
}
plan skip_all => 'openssl could not generate temporary TLS certificate'
    if $generated != 0 || !-s $cert || !-s $key;

my $loop = Linux::Event::Loop->new;
my $state = {
    h2_body        => '',
    h1_body        => '',
    h2_response    => '',
    h1_response    => '',
    errors         => [],
    h2_drain_hits  => 0,
    h2_cancel_hits => 0,
};

my $h2_server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '127.0.0.1',
    port  => 0,
    http2 => 1,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_request => sub ($conn, $req, $res) {
        $state->{h2_request_version} = $req->version;
        $state->{h2_request_authority} = $req->authority;
        $state->{h2_request_host} = $req->header('Host');
        $state->{h2_content_length} = $req->header('Content-Length');
        $state->{h2_transfer_encoding} =
            $req->header('Transfer-Encoding');
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{h2_body} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        $res->body('h2:' . length($state->{h2_body}));
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "h2 server: $error";
        $loop->stop;
    },
);

my $h1_server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    tls  => {
        cert_file => $cert,
        key_file  => $key,
        alpn      => [ 'http/1.1' ],
    },
    on_request => sub ($conn, $req, $res) {
        $state->{h1_request_version} = $req->version;
        $state->{h1_host} = $req->header('Host');
        $state->{h1_transfer_encoding} =
            $req->header('Transfer-Encoding');
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{h1_body} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        $res->body('h1:' . $state->{h1_body});
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "h1 server: $error";
        $loop->stop;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "high-level HTTP/2 streaming upload test timed out\n";
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    http2 => 1,
    tls   => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout  => 1,
    },
);

my $h2_url = 'https://localhost:' . $h2_server->port . '/upload';
my $h2_operation;
$h2_operation = $client->post(
    $h2_url,
    headers => [ [ 'Content-Length', 100_004 ] ],
    stream_body => {
        on_drain => sub ($body) {
            ++$state->{h2_drain_hits};
            $body->complete('tail');
        },
        on_cancel => sub ($body) {
            ++$state->{h2_cancel_hits};
        },
    },
    on_body => sub ($tx, $res, $bytes) {
        $state->{h2_response} .= $bytes;
    },
    on_complete => sub ($tx) {
        $state->{h2_complete} = $tx->is_complete ? 1 : 0;
        $state->{h2_final_version} = $tx->request->version;
        $state->{h2_final_authority} = $tx->request->authority;
        $state->{h2_final_host} = $tx->request->header('Host');

        my $h1_url = 'https://localhost:' . $h1_server->port . '/fallback';
        my $h1_operation = $client->post(
            $h1_url,
            stream_body => {},
            on_body => sub ($fallback_tx, $res, $bytes) {
                $state->{h1_response} .= $bytes;
            },
            on_complete => sub ($fallback_tx) {
                $state->{h1_complete} =
                    $fallback_tx->is_complete ? 1 : 0;
                $state->{h1_final_version} =
                    $fallback_tx->request->version;
                $state->{h1_final_host} =
                    $fallback_tx->request->header('Host');

                $guard->cancel;
                $client->close;
                $h2_server->close;
                $h1_server->close;
                $loop->stop;
            },
            on_error => sub ($fallback_tx, $error) {
                push @{$state->{errors}}, "h1 client: $error";
                $loop->stop;
            },
        );

        $state->{h1_immediate_version} =
            $h1_operation->request->version;
        my $h1_body = $h1_operation->request_body;
        $h1_body->write('hello ');
        $h1_body->complete('world');
    },
    on_error => sub ($tx, $error) {
        push @{$state->{errors}}, "h2 client: $error";
        $loop->stop;
    },
);

my $h2_request_id = refaddr($h2_operation->request);
my $h2_body = $h2_operation->request_body;

is($h2_operation->request->version, '1.1',
    'streaming operation exposes provisional HTTP/1 Request before ALPN');
is($h2_operation->request->content_length, 100_004,
    'streaming operation exposes Content-Length immediately');

my $accepted = $h2_body->write('x' x 100_000);
ok(!$accepted,
    'large pre-ALPN streaming write applies selector backpressure');
ok(!$h2_body->is_complete,
    'pre-ALPN producer remains open after non-final write');

$loop->run;

is_deeply($state->{errors}, [],
    'streaming selector reports no client or server errors');

ok($state->{h2_complete}, 'H2 streaming upload operation completes');
is($state->{h2_request_version}, '2',
    'H2 server receives streaming Request as HTTP/2');
is($state->{h2_final_version}, '2',
    'same Client Request records HTTP/2 after ALPN');
is(refaddr($h2_operation->request), $h2_request_id,
    'streaming ALPN selection preserves Request object identity');
is($state->{h2_request_authority},
    'localhost:' . $h2_server->port,
    'H2 streaming Request receives URL-derived authority');
is($state->{h2_final_authority},
    'localhost:' . $h2_server->port,
    'Client Request retains selected H2 authority');
ok(!defined($state->{h2_request_host})
    && !defined($state->{h2_final_host}),
    'H2 streaming Request does not expose synthesized Host field');
is($state->{h2_content_length}, '100004',
    'H2 server receives streaming Content-Length unchanged');
ok(!defined($state->{h2_transfer_encoding}),
    'H2 streaming Request does not synthesize Transfer-Encoding');
is(length($state->{h2_body}), 100_004,
    'H2 server receives all pre- and post-selection body bytes');
is(substr($state->{h2_body}, 0, 8), 'xxxxxxxx',
    'H2 streaming body begins with pre-selection bytes');
is(substr($state->{h2_body}, -4), 'tail',
    'H2 streaming body completes from on_drain after selection');
cmp_ok($state->{h2_drain_hits}, '>=', 1,
    'pre-selection backpressure resumes through the same Body::Stream');
is($state->{h2_cancel_hits}, 0,
    'completed H2 producer is not cancelled');
is($state->{h2_response}, 'h2:100004',
    'H2 streaming upload receives normal response');

ok($state->{h1_complete}, 'HTTP/1.1 fallback streaming upload completes');
is($state->{h1_immediate_version}, '1.1',
    'fallback streaming Request remains provisional HTTP/1.1');
is($state->{h1_request_version}, '1.1',
    'fallback server receives HTTP/1.1 Request');
is($state->{h1_final_version}, '1.1',
    'fallback Client Request remains HTTP/1.1');
is(lc($state->{h1_transfer_encoding} // ''), 'chunked',
    'unknown-length fallback upload gains HTTP/1.1 chunked framing');
is($state->{h1_body}, 'hello world',
    'pre-ALPN fallback body bytes are transferred through HTTP/1 framing');
is($state->{h1_response}, 'h1:hello world',
    'fallback streaming upload receives normal response');
is($state->{h1_host}, 'localhost:' . $h1_server->port,
    'fallback server receives ordinary Host field');
is($state->{h1_final_host}, 'localhost:' . $h1_server->port,
    'fallback Client Request retains Host field');

{
    my $short = Linux::Event::HTTP::Client->new(
        loop  => Linux::Event::Loop->new,
        http2 => 1,
        tls   => { verify => 0 },
    );
    my $operation = $short->post(
        'https://127.0.0.1:9/short',
        headers => [ [ 'Content-Length', 5 ] ],
        stream_body => {},
    );
    my $producer = $operation->request_body;
    my $ok = eval { $producer->complete('abc'); 1 };
    ok(!$ok,
        'pre-ALPN streaming completion enforces Content-Length immediately');
    like($@, qr/does not match Content-Length/,
        'pre-ALPN Content-Length failure is clear');
    $operation->cancel;
    $short->close;
}

done_testing;
