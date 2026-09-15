use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::HTTP::StreamingClientConnection;
    use parent 'Linux::Event::HTTP::Client::Connection';

    our $DRAINS = 0;

    sub stream_tuning ($class) {
        return high_watermark => 128, low_watermark => 32;
    }

    sub on_drain ($self) {
        ++$DRAINS;
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my %server_body;
my %server_header;

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    on_request => sub ($conn, $req, $res) {
        $server_header{$req->target} = {
            content_length    => $req->header('Content-Length'),
            transfer_encoding => $req->header('Transfer-Encoding'),
        };

        if ($req->target eq '/early') {
            $res->status(413);
            $res->body('rejected');
        }
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $server_body{$req->target} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        return if $req->target eq '/early';
        my $length = length($server_body{$req->target} // '');
        $res->body("received=$length");
    },
);

my $base = 'http://127.0.0.1:' . $server->port;
my $client = Linux::Event::HTTP::Client->new(loop => $loop);
my $blocked_client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connection_class => 'T::HTTP::StreamingClientConnection',
);

my $ok = eval {
    $client->post(
        "$base/scalar-and-stream",
        body => 'abc',
        stream_body => {},
    );
    1;
};
ok(!$ok, 'scalar body and stream_body are mutually exclusive');
like($@, qr/body and stream_body are mutually exclusive/,
    'scalar/stream conflict reports a clear error');

$ok = eval {
    $client->post(
        "$base/bad-stream-callback",
        stream_body => { on_drain => 'not-a-coderef' },
    );
    1;
};
ok(!$ok, 'invalid stream_body callback is rejected before request start');
like($@, qr/request_body\(\): on_drain must be a coderef/,
    'invalid stream_body callback reports producer validation error');

$ok = eval {
    $client->post(
        "$base/http10-unknown",
        version => '1.0',
        stream_body => {},
    );
    1;
};
ok(!$ok, 'HTTP/1.0 unknown-length streaming Request is rejected');
like($@, qr/HTTP\/1\.0 streaming Request requires Content-Length/,
    'HTTP/1.0 streaming failure explains required framing');

my $short = $client->post(
    "$base/short",
    headers => [ [ 'Content-Length', 5 ] ],
    stream_body => {},
);
my $short_body = $short->request_body;
$ok = eval { $short_body->complete('abc'); 1 };
ok(!$ok, 'stream completion rejects fewer bytes than Content-Length');
like($@, qr/does not match Content-Length/,
    'short streaming body reports Content-Length mismatch');
ok(!$short->request->is_complete,
    'failed final write leaves Request message incomplete');
$short->cancel;

my $long = $client->post(
    "$base/long",
    headers => [ [ 'Content-Length', 5 ] ],
    stream_body => {},
);
my $long_body = $long->request_body;
$ok = eval { $long_body->write('abcdef'); 1 };
ok(!$ok, 'stream write rejects bytes beyond Content-Length');
like($@, qr/exceeds Content-Length/,
    'oversized streaming body reports Content-Length overflow');
ok(!$long->request->is_complete,
    'oversized non-final write leaves Request incomplete');
$long->cancel;

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 5,
    on_timer => sub ($timer) {
        die "streaming client Request test timed out\n";
    },
);

my $complete = 0;
my $drain_calls = 0;
my $known_cancel = 0;
my $early_cancel = 0;
my ($known_tx, $chunked_tx, $early_tx, $early_body);

my $done = sub {
    return if ++$complete < 3;
    $guard->cancel;
    $client->close;
    $blocked_client->close;
    $server->close;
    $loop->stop;
};

$known_tx = $blocked_client->post(
    "$base/known",
    headers => [
        [ 'Content-Length', 6 ],
        [ 'X-Pad', 'x' x 256 ],
    ],
    stream_body => {
        on_drain => sub ($body) {
            ++$drain_calls;
            my $accepted = $body->write('abc');
            ok(defined($accepted), 'stream write returns backpressure state');
            $body->complete('def');
        },
        on_cancel => sub ($body) {
            ++$known_cancel;
        },
    },
    buffer_body => 1024,
    on_complete => sub ($tx) {
        is($tx->response->body, 'received=6',
            'known-length streaming Request receives normal response');
        $done->();
    },
    on_error => sub ($tx, $error) {
        die "known-length streaming request failed: $error\n";
    },
);

ok(!$known_tx->request->is_complete,
    'streaming Request starts incomplete');
is($known_tx->request->content_length, 6,
    'known-length streaming Request preserves Content-Length');
is($known_tx->request->header('Transfer-Encoding'), undef,
    'known-length streaming Request does not add chunked framing');
is($known_tx->request_body, $known_tx->request_body,
    'request_body returns a stable producer');

$chunked_tx = $client->post(
    "$base/chunked",
    stream_body => {},
    buffer_body => 1024,
    on_complete => sub ($tx) {
        is($tx->response->body, 'received=11',
            'chunked streaming Request receives normal response');
        $done->();
    },
    on_error => sub ($tx, $error) {
        die "chunked streaming request failed: $error\n";
    },
);

is(lc($chunked_tx->request->header('Transfer-Encoding') // ''), 'chunked',
    'unknown-length HTTP/1.1 streaming Request automatically uses chunked');
is($chunked_tx->request->content_length, undef,
    'automatic chunked streaming Request has no Content-Length');
my $chunked_body = $chunked_tx->request_body;
$chunked_body->write('hello ');
$chunked_body->complete('world');
ok($chunked_tx->request->is_complete,
    'Request becomes complete when streaming producer completes');

$early_tx = $client->post(
    "$base/early",
    stream_body => {
        on_cancel => sub ($body) {
            ++$early_cancel;
        },
    },
    buffer_body => 1024,
    on_complete => sub ($tx) {
        is($tx->response->status, 413,
            'early final Response is delivered to streaming client');
        is($tx->response->body, 'rejected',
            'early Response body is still handled normally');
        ok(!$tx->request->is_complete,
            'early final Response does not falsely complete unfinished Request');
        ok($early_body->is_cancelled,
            'early final Response cancels retained unfinished Request producer');
        $done->();
    },
    on_error => sub ($tx, $error) {
        die "early-response streaming request failed: $error\n";
    },
);
$early_body = $early_tx->request_body;
$early_body->write('partial');

$loop->run;

is($server_body{'/known'}, 'abcdef',
    'server receives exact known-length streamed Request body');
is($server_header{'/known'}{content_length}, 6,
    'server sees known streamed Content-Length');
is($server_header{'/known'}{transfer_encoding}, undef,
    'server does not see Transfer-Encoding on known-length stream');

is($server_body{'/chunked'}, 'hello world',
    'server receives decoded automatic chunked Request body');
is(lc($server_header{'/chunked'}{transfer_encoding} // ''), 'chunked',
    'server sees automatic chunked transfer coding');

ok($drain_calls >= 1,
    'streaming Request producer is resumed through Linux::Event on_drain');
ok($T::HTTP::StreamingClientConnection::DRAINS >= 1,
    'subclass on_drain callback composes with HTTP producer drain bookkeeping');
is($known_cancel, 0,
    'completed known-length producer is not cancelled');
is($early_cancel, 1,
    'early final Response invokes Request producer cancellation exactly once');

done_testing;
