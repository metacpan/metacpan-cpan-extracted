use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);


use Hypersonic;

# Skip if we can't fork
plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 19900 + ($$ % 1000);
my $cache_dir = "_test_cache_dyn_$$";  # Capture before fork!

# spawn_server captures the child's STDERR/STDOUT so we can diag the
# actual error when the server fails to bind on platforms like OpenBSD.
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Static route - runs once at compile time
    $server->get('/static' => sub { '{"type":"static"}' });

    # Dynamic route with path parameter - uses JIT accessor
    $server->get('/users/:id' => sub {
        my ($req) = @_;
        my $id = $req->id // 'unknown';
        return qq({"user_id":"$id"});
    });

    # Dynamic route with explicit option - uses JIT accessor
    $server->post('/echo' => sub {
        my ($req) = @_;
        my $body = $req->body // '';
        return qq({"echoed":"$body"});
    }, { dynamic => 1 });

    # Dynamic route that accesses method - uses JIT accessors
    $server->get('/info' => sub {
        my ($req) = @_;
        my $method = $req->method // 'unknown';
        my $path = $req->path // 'unknown';
        return qq({"method":"$method","path":"$path"});
    }, { dynamic => 1 });

    $server->compile();
    $server->run(port => $port, workers => 1);
});

wait_for_port($port, { pid => $pid, log => $log, tries => 50 })
    or do {
        kill 'TERM', $pid;
        BAIL_OUT("server child failed to bind port $port (see diag above)");
    };

# Test helper
sub http_request {
    my ($method, $path, $body) = @_;
    $body //= '';

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    );

    return undef unless $sock;

    my $content_length = length($body);
    my $request = "$method $path HTTP/1.1\r\n"
                . "Host: localhost:$port\r\n"
                . "Content-Length: $content_length\r\n"
                . "Connection: close\r\n"
                . "\r\n"
                . $body;

    print $sock $request;

    my $response = '';
    while (my $line = <$sock>) {
        $response .= $line;
    }
    close($sock);

    return $response;
}

# Run tests
my $resp;

# Test 1: Static route still works
$resp = http_request('GET', '/static');
ok($resp, 'Static route: got response');
like($resp, qr/HTTP\/1\.1 200 OK/, 'Static route: returns 200');
like($resp, qr/"type":"static"/, 'Static route: correct body');

# Test 2: Dynamic route with path parameter
$resp = http_request('GET', '/users/123');
ok($resp, 'Dynamic route /users/123: got response');
like($resp, qr/HTTP\/1\.1 200 OK/, 'Dynamic route: returns 200');
like($resp, qr/"user_id":"123"/, 'Dynamic route: extracted id parameter');

# Test 3: Different path parameter
$resp = http_request('GET', '/users/456');
ok($resp, 'Dynamic route /users/456: got response');
like($resp, qr/"user_id":"456"/, 'Dynamic route: different id extracted');

# Test 4: POST with body (dynamic)
$resp = http_request('POST', '/echo', 'hello world');
ok($resp, 'POST /echo: got response');
like($resp, qr/HTTP\/1\.1 200 OK/, 'POST /echo: returns 200');
like($resp, qr/"echoed":"hello world"/, 'POST /echo: body echoed');

# Test 5: Dynamic route accessing request info
$resp = http_request('GET', '/info');
ok($resp, 'GET /info: got response');
like($resp, qr/"method":"GET"/, 'Dynamic route: has method');
like($resp, qr/"path":"\/info"/, 'Dynamic route: has path');

# Test 6: 404 for unknown route
$resp = http_request('GET', '/unknown');
ok($resp, 'Unknown route: got response');
like($resp, qr/HTTP\/1\.1 404/, 'Unknown route: returns 404');

# Cleanup
kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
