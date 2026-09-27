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
plan skip_all => 'openssl command is required for high-level HTTP/2 Client test'
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
    h2_connections => {},
    h2_requests    => [],
    post_body      => '',
    first_body     => '',
    second_body    => '',
    fallback_body  => '',
    errors         => [],
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
        $state->{h2_connections}{refaddr($conn)} = 1;
        push @{$state->{h2_requests}}, {
            target    => $req->target,
            version   => $req->version,
            authority => $req->authority,
            host      => $req->header('Host'),
            alpn      => $conn->selected_alpn,
        };

        if ($req->target eq '/two') {
            $res->header('x-protocol', 'h2');
            $res->body("second\n");
        }
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{post_body} .= $bytes if $req->target eq '/one';
    },
    on_request_end => sub ($conn, $req, $res) {
        if ($req->target eq '/one') {
            $res->header('x-protocol', 'h2');
            $res->body('post:' . $state->{post_body});
        }
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "h2 server: $error";
        $loop->stop;
    },
);

my $fallback_server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    tls  => {
        cert_file => $cert,
        key_file  => $key,
        alpn      => [ 'http/1.1' ],
    },
    on_request => sub ($conn, $req, $res) {
        $state->{fallback_alpn} = $conn->selected_alpn;
        $state->{fallback_version} = $req->version;
        $state->{fallback_host} = $req->header('Host');
        $res->header('x-protocol', 'http/1.1');
        $res->body("fallback\n");
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "fallback server: $error";
        $loop->stop;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "high-level HTTP/2 Client test timed out\n";
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

ok($client->http2, 'high-level Client reports HTTP/2 enabled');

my $first_url = 'https://localhost:' . $h2_server->port . '/one';
my $first = $client->post(
    $first_url,
    body => 'abc',
    on_response => sub ($tx, $res) {
        $state->{first_status} = $res->status;
        $state->{first_protocol} = $res->header('x-protocol');
    },
    on_body => sub ($tx, $res, $bytes) {
        $state->{first_body} .= $bytes;
    },
    on_complete => sub ($tx) {
        $state->{first_complete} = $tx->is_complete ? 1 : 0;
        $state->{first_final_request_id} = refaddr($tx->request);
        $state->{first_final_version} = $tx->request->version;
        $state->{first_final_authority} = $tx->request->authority;
        $state->{first_final_host} = $tx->request->header('Host');

        my $second_url = 'https://localhost:' . $h2_server->port . '/two';
        my $second = $client->get(
            $second_url,
            headers => [ [ Host => 'virtual.test' ] ],
            on_response => sub ($second_tx, $res) {
                $state->{second_status} = $res->status;
                $state->{second_protocol} = $res->header('x-protocol');
            },
            on_body => sub ($second_tx, $res, $bytes) {
                $state->{second_body} .= $bytes;
            },
            on_complete => sub ($second_tx) {
                $state->{second_complete} =
                    $second_tx->is_complete ? 1 : 0;
                $state->{second_final_version} =
                    $second_tx->request->version;
                $state->{second_final_authority} =
                    $second_tx->request->authority;
                $state->{second_final_host} =
                    $second_tx->request->header('Host');

                my $fallback_url =
                    'https://localhost:' . $fallback_server->port . '/fallback';
                my $fallback = $client->get(
                    $fallback_url,
                    on_response => sub ($fallback_tx, $fallback_res) {
                        $state->{fallback_status} = $fallback_res->status;
                        $state->{fallback_protocol} =
                            $fallback_res->header('x-protocol');
                    },
                    on_body => sub ($fallback_tx, $fallback_res, $bytes) {
                        $state->{fallback_body} .= $bytes;
                    },
                    on_complete => sub ($fallback_tx) {
                        $state->{fallback_complete} =
                            $fallback_tx->is_complete ? 1 : 0;
                        $state->{fallback_client_version} =
                            $fallback_tx->request->version;
                        $state->{fallback_client_host} =
                            $fallback_tx->request->header('Host');

                        $guard->cancel;
                        $client->close;
                        $h2_server->close;
                        $fallback_server->close;
                        $loop->stop;
                    },
                    on_error => sub ($fallback_tx, $error) {
                        push @{$state->{errors}},
                            "fallback client: $error";
                        $loop->stop;
                    },
                );
                $state->{fallback_immediate_version} =
                    $fallback->request->version;
            },
            on_error => sub ($second_tx, $error) {
                push @{$state->{errors}}, "second client: $error";
                $loop->stop;
            },
        );
        $state->{second_immediate_version} = $second->request->version;
        $state->{second_immediate_authority} =
            $second->request->authority;
        $state->{second_immediate_host} = $second->request->header('Host');
    },
    on_error => sub ($tx, $error) {
        push @{$state->{errors}}, "first client: $error";
        $loop->stop;
    },
);

my $first_request = $first->request;
my $first_request_id = refaddr($first_request);

is($first_request->version, '1.1',
    'operation exposes provisional HTTP/1-compatible Request before ALPN');
is($first_request->header('Host'), 'localhost:' . $h2_server->port,
    'provisional Request exposes synthesized Host immediately');

$loop->run;

is_deeply($state->{errors}, [], 'high-level Client selector reports no errors');

ok($state->{first_complete}, 'first H2 operation completes');
is($state->{first_status}, 200, 'first H2 operation receives status 200');
is($state->{first_protocol}, 'h2',
    'first response came through HTTP/2');
is($state->{first_body}, 'post:abc',
    'scalar POST body crosses high-level HTTP/2 Client');
is($state->{first_final_request_id}, $first_request_id,
    'ALPN selection preserves Request object identity');
is($state->{first_final_version}, '2',
    'same Request records HTTP/2 after protocol selection');
is($state->{first_final_authority}, 'localhost:' . $h2_server->port,
    'same Request records H2 authority');
ok(!defined($state->{first_final_host}),
    'Client-synthesized Host is not exposed as an H2 normal field');

ok($state->{second_complete}, 'second H2 operation completes');
is($state->{second_immediate_version}, '2',
    'reused selected H2 connection commits the next Request immediately as H2');
is($state->{second_immediate_authority}, 'virtual.test',
    'reused H2 connection maps caller Host semantics to authority immediately');
ok(!defined($state->{second_immediate_host}),
    'reused H2 Request does not retain Host as a normal field');
is($state->{second_status}, 200, 'second H2 operation receives status 200');
is($state->{second_protocol}, 'h2',
    'second response also uses HTTP/2');
is($state->{second_body}, "second\n", 'second H2 response body is delivered');
is($state->{second_final_version}, '2',
    'second Request records selected H2 version');
is($state->{second_final_authority}, 'virtual.test',
    'caller Host semantics map to H2 authority');
ok(!defined($state->{second_final_host}),
    'caller Host field is consumed into H2 authority');

is(scalar(keys %{$state->{h2_connections}}), 1,
    'sequential high-level H2 requests reuse one TLS connection');
is(scalar(@{$state->{h2_requests}}), 2,
    'H2 Server receives both high-level Client requests');
is_deeply(
    [ map { $_->{version} } @{$state->{h2_requests}} ],
    [ '2', '2' ],
    'Server sees HTTP/2 Request version for both exchanges',
);
is($state->{h2_requests}[0]{authority},
    'localhost:' . $h2_server->port,
    'first H2 request uses URL-derived authority');
is($state->{h2_requests}[1]{authority}, 'virtual.test',
    'second H2 request uses caller Host as authority');
ok(!defined($state->{h2_requests}[0]{host})
    && !defined($state->{h2_requests}[1]{host}),
    'H2 Server normal header list contains no synthesized Host');
is($state->{h2_requests}[0]{alpn}, 'h2',
    'H2 Server callback sees negotiated h2');

ok($state->{fallback_complete}, 'HTTP/1.1 fallback operation completes');
is($state->{fallback_immediate_version}, '1.1',
    'fallback operation Request is immediately HTTP/1.1-compatible');
is($state->{fallback_status}, 200,
    'fallback operation receives status 200');
is($state->{fallback_protocol}, 'http/1.1',
    'fallback response uses HTTP/1.1');
is($state->{fallback_body}, "fallback\n",
    'fallback response body is delivered');
is($state->{fallback_alpn}, 'http/1.1',
    'server that offers only HTTP/1.1 selects HTTP/1.1');
is($state->{fallback_version}, '1.1',
    'fallback Server receives HTTP/1.1 Request');
is($state->{fallback_client_version}, '1.1',
    'fallback Client Request remains HTTP/1.1');
is($state->{fallback_client_host},
    'localhost:' . $fallback_server->port,
    'fallback Client Request retains Host');
is($state->{fallback_host},
    'localhost:' . $fallback_server->port,
    'fallback Server receives Host normally');

done_testing;
