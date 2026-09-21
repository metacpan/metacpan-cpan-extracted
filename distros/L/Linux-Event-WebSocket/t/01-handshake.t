use v5.36;
use strict;
use warnings;

use Test::More;
use MIME::Base64 qw(decode_base64);

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::WebSocket::_Handshake;

my $RFC_KEY = 'dGhlIHNhbXBsZSBub25jZQ==';
my $RFC_ACCEPT = 's3pPLMBiTxaQ9kYGzzhZRbK+xOo=';

sub dies_like ($code, $pattern, $name) {
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, $name);
    like($error, $pattern, "$name reports expected error");
}

my $request = Linux::Event::HTTP::Request->new(
    method  => 'GET',
    target  => '/chat',
    version => '1.1',
    headers => [
        [ Host                     => 'server.example.com' ],
        [ Upgrade                  => 'WebSocket' ],
        [ Connection               => 'keep-alive, Upgrade' ],
        [ 'Sec-WebSocket-Key'      => $RFC_KEY ],
        [ 'Sec-WebSocket-Version'  => '13' ],
        [ 'Sec-WebSocket-Protocol' => 'chat, superchat' ],
    ],
);

my $server_handshake = Linux::Event::WebSocket::_Handshake->server_from_request(
    $request,
    subprotocols => [qw(superchat chat)],
);
my $response = Linux::Event::HTTP::Response->new(status => 200);
Linux::Event::WebSocket::_Handshake->apply_server_response(
    $server_handshake,
    $response,
);

is($response->status, 101, 'server accepts a valid WebSocket request');
is($response->reason, 'Switching Protocols', 'server sets the response reason');
is($response->header('Upgrade'), 'websocket', 'server sets Upgrade');
is($response->header('Connection'), 'Upgrade', 'server sets Connection');
is($response->header('Sec-WebSocket-Accept'), $RFC_ACCEPT,
    'server calculates the RFC accept value');
is($response->header('Sec-WebSocket-Protocol'), 'chat',
    'server selects the first supported client preference');
is(Linux::Event::WebSocket::_Handshake->subprotocol($server_handshake), 'chat',
    'server handshake retains selected subprotocol');

my ($client_handshake, $client_request) =
    Linux::Event::WebSocket::_Handshake->client_request(
        'ws://example.com/chat?room=1',
        key          => $RFC_KEY,
        host_header  => 'example.com',
        origin       => 'https://example.net',
        subprotocols => [qw(chat superchat)],
        headers      => [ [ Authorization => 'Bearer token' ] ],
    );

is($client_request->method, 'GET', 'client uses GET');
is($client_request->target, '/chat?room=1', 'client keeps path and query');
is($client_request->version, '1.1', 'client uses HTTP/1.1');
is($client_request->header('Host'), 'example.com', 'client sets Host');
is($client_request->header('Upgrade'), 'websocket', 'client sets Upgrade');
is($client_request->header('Connection'), 'Upgrade', 'client sets Connection');
is($client_request->header('Sec-WebSocket-Key'), $RFC_KEY,
    'client uses the supplied deterministic key');
is($client_request->header('Sec-WebSocket-Version'), '13',
    'client requests RFC 6455 version 13');
is($client_request->header('Sec-WebSocket-Protocol'), 'chat, superchat',
    'client sends ordered subprotocols');
is($client_request->header('Origin'), 'https://example.net',
    'client sends Origin when configured');
is($client_request->header('Authorization'), 'Bearer token',
    'client preserves additional headers');

my (undef, $random_request) =
    Linux::Event::WebSocket::_Handshake->client_request(
        'ws://example.com/',
        host_header => 'example.com',
    );
my $random_key = $random_request->header('Sec-WebSocket-Key');
like($random_key, qr/\A[A-Za-z0-9+\/] {22} ==\z/x,
    'client generates a base64 nonce');
is(length(decode_base64($random_key)), 16,
    'client nonce decodes to sixteen bytes');

my $client_response = Linux::Event::HTTP::Response->new(
    status => 101,
    reason => 'Switching Protocols',
    headers => [
        [ Upgrade                  => 'websocket' ],
        [ Connection               => 'Upgrade' ],
        [ 'Sec-WebSocket-Accept'   => $RFC_ACCEPT ],
        [ 'Sec-WebSocket-Protocol' => 'chat' ],
    ],
);

Linux::Event::WebSocket::_Handshake->validate_client_response(
    $client_handshake,
    $client_response,
);
is(Linux::Event::WebSocket::_Handshake->subprotocol($client_handshake), 'chat',
    'client retains the selected subprotocol');

for my $case (
    [ method => 'POST', qr/method.*GET/i ],
    [ version => '1.0', qr/HTTP.*1\.1/i ],
) {
    my ($field, $value, $pattern) = @$case;
    my %copy = (
        method  => 'GET',
        target  => '/chat',
        version => '1.1',
        headers => [
            [ Upgrade                 => 'websocket' ],
            [ Connection              => 'Upgrade' ],
            [ 'Sec-WebSocket-Key'     => $RFC_KEY ],
            [ 'Sec-WebSocket-Version' => '13' ],
        ],
    );
    $copy{$field} = $value;
    my $bad = Linux::Event::HTTP::Request->new(%copy);
    dies_like(
        sub { Linux::Event::WebSocket::_Handshake->server_from_request($bad) },
        $pattern,
        "server rejects invalid $field",
    );
}

my $bad_accept = Linux::Event::HTTP::Response->new(
    status => 101,
    headers => [
        [ Upgrade                => 'websocket' ],
        [ Connection             => 'Upgrade' ],
        [ 'Sec-WebSocket-Accept' => 'wrong' ],
    ],
);
dies_like(
    sub {
        Linux::Event::WebSocket::_Handshake->validate_client_response(
            $client_handshake,
            $bad_accept,
        );
    },
    qr/Sec-WebSocket-Accept/,
    'client rejects an incorrect accept value',
);

done_testing;
