use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $state = {
    request => {},
    bodies  => {},
};

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    on_request => sub ($conn, $req, $res) {
        $state->{request}{$req->target} = {
            connection => refaddr($conn),
            method     => $req->method,
            host       => $req->header('Host'),
            custom     => $req->header('X-Custom'),
        };
        return if $req->target eq '/post';
        $res->header('X-Target', $req->target);
        $res->body($req->method . ' ' . $req->target . "\n");
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{bodies}{$req->target} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        if ($req->target eq '/post') {
            $res->header('X-Target', $req->target);
            $res->body("POST /post\n");
        }
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
);

is($client->loop, $loop, 'Client retains its Loop');
is($client->connection_class, 'Linux::Event::HTTP::Client::Connection',
    'Client uses the normal Connection class by default');
ok(!$client->is_closed, 'new Client is open');

my $ok = eval { $client->get('/relative'); 1 };
ok(!$ok, 'relative URL is rejected');
like($@, qr/scheme must be http or https/, 'relative URL failure is clear');

$ok = eval { $client->get('ftp://example.test/file'); 1 };
ok(!$ok, 'unsupported URL scheme is rejected');
like($@, qr/scheme must be http or https/, 'unsupported scheme failure is clear');

$ok = eval { $client->get('http://user\@example.test/'); 1 };
ok(!$ok, 'URL userinfo is rejected rather than becoming hidden auth policy');
like($@, qr/userinfo is not supported/, 'userinfo rejection is clear');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "high-level Client integration test timed out\n";
    },
);

my $base = 'http://127.0.0.1:' . $server->port;
my $completed = 0;
my @body;
my @response_status;
my @tx;

my $finish_one = sub ($transaction) {
    push @response_status, $transaction->response->status;
    if (++$completed == 2) {
        my $third = $client->delete(
            "$base/after?x=1#fragment",
            on_body => sub ($tx, $res, $bytes) {
                $body[2] .= $bytes;
            },
            on_complete => sub ($tx) {
                push @tx, $tx;
                push @response_status, $tx->response->status;
                $guard->cancel;
                $client->close;
                $server->close;
                $loop->stop;
            },
            on_error => sub ($tx, $error) {
                die "third Client request failed: $error\n";
            },
        );
        is($third->request->target, '/after?x=1',
            'URL fragment is excluded from the HTTP request-target');
        is(
            $third->request->header('Host'),
            '127.0.0.1:' . $server->port,
            'non-default port is included in synthesized Host',
        );
    }
};

my $first = $client->get(
    "$base/one?x=1#ignored",
    headers => [ [ 'X-Custom', 'first' ] ],
    on_response => sub ($tx, $res) {
        is($res->header('X-Target'), '/one?x=1',
            'GET response corresponds to parsed URL target');
    },
    on_body => sub ($tx, $res, $bytes) {
        $body[0] .= $bytes;
    },
    on_complete => sub ($tx) {
        push @tx, $tx;
        $finish_one->($tx);
    },
    on_error => sub ($tx, $error) {
        die "first Client request failed: $error\n";
    },
);

my $second = $client->post(
    "$base/post",
    headers => [
        [ 'Host', 'virtual.example.test' ],
        [ 'Content-Type', 'text/plain' ],
        [ 'X-Custom', 'second' ],
    ],
    body => 'abc',
    on_body => sub ($tx, $res, $bytes) {
        $body[1] .= $bytes;
    },
    on_complete => sub ($tx) {
        push @tx, $tx;
        $finish_one->($tx);
    },
    on_error => sub ($tx, $error) {
        die "second Client request failed: $error\n";
    },
);

is($first->request->method, 'GET', 'get() constructs canonical GET Request');
is($first->request->target, '/one?x=1',
    'Client turns URL path/query into Request target');
is($first->request->header('Host'), '127.0.0.1:' . $server->port,
    'Client synthesizes Host from destination URL');
is($first->request->header('X-Custom'), 'first',
    'Client preserves caller headers');

is($second->request->method, 'POST', 'post() constructs canonical POST Request');
is($second->request->body, 'abc', 'post() retains scalar Request body');
is($second->request->content_length, 3,
    'low-level execution adds Content-Length to Client scalar body');
is($second->request->header('Host'), 'virtual.example.test',
    'explicit caller Host is preserved');

$loop->run;

is_deeply(
    \@response_status,
    [ 200, 200, 200 ],
    'all high-level Client Transactions complete successfully',
);
is($body[0], "GET /one?x=1\n", 'GET body delivered incrementally');
is($body[1], "POST /post\n", 'POST response body delivered incrementally');
is($body[2], "DELETE /after?x=1\n", 'DELETE convenience method works');
is($state->{bodies}{'/post'}, 'abc', 'server receives Client POST body');

is($state->{request}{'/one?x=1'}{host}, '127.0.0.1:' . $server->port,
    'server receives synthesized Host');
is($state->{request}{'/post'}{host}, 'virtual.example.test',
    'server receives explicit Host override');
is($state->{request}{'/one?x=1'}{custom}, 'first',
    'server receives first custom header');
is($state->{request}{'/post'}{custom}, 'second',
    'server receives second custom header');

my %first_two_connections = map {
    $state->{request}{$_}{connection} => 1
} ('/one?x=1', '/post');
is(scalar(keys %first_two_connections), 2,
    'concurrent same-origin requests use separate HTTP/1 connections rather than pipelining');

my $after_connection = $state->{request}{'/after?x=1'}{connection};
ok($first_two_connections{$after_connection},
    'later request reuses one idle same-origin connection');

for my $transaction (@tx) {
    ok($transaction->is_complete,
        'Client returns successfully completed Transaction objects');
}

ok($client->is_closed, 'Client close marks Client closed');
$ok = eval { $client->get("$base/late"); 1 };
ok(!$ok, 'closed Client rejects new requests');
like($@, qr/Client is closed/, 'closed Client rejection is clear');

done_testing;
