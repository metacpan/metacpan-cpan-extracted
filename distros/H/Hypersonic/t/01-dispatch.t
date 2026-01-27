use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

# Test route registration and dispatch
my $server = Hypersonic->new(cache_dir => '_test_cache');

# Register some routes
$server->get('/api/hello' => sub { '{"message":"Hello"}' });
$server->get('/health'    => sub { 'OK' });
$server->post('/api/data' => sub { '{"status":"received"}' });
$server->get('/api/users' => sub { '[{"id":1},{"id":2}]' });
$server->put('/api/update' => sub { '{"updated":true}' });
$server->del('/api/delete' => sub { '{"deleted":true}' });

# Compile routes
$server->compile();
ok($server->{compiled}, 'Server compiled');

# Test dispatch with mock requests
# Request format: [method, path, body, keep_alive, fd]
# Note: dispatch now returns FULL HTTP response (headers + body)

my $tests = [
    {
        name     => 'GET /api/hello returns JSON',
        request  => ['GET', '/api/hello', '', 1, 0],
        contains => '{"message":"Hello"}',
        header   => 'application/json',
    },
    {
        name     => 'GET /health returns plain text',
        request  => ['GET', '/health', '', 1, 0],
        contains => 'OK',
        header   => 'text/plain',
    },
    {
        name     => 'POST /api/data',
        request  => ['POST', '/api/data', '{}', 1, 0],
        contains => '{"status":"received"}',
        header   => 'application/json',
    },
    {
        name     => 'GET /api/users returns array',
        request  => ['GET', '/api/users', '', 1, 0],
        contains => '[{"id":1},{"id":2}]',
        header   => 'application/json',
    },
    {
        name     => 'PUT /api/update',
        request  => ['PUT', '/api/update', '{}', 1, 0],
        contains => '{"updated":true}',
    },
    {
        name     => 'DELETE /api/delete',
        request  => ['DELETE', '/api/delete', '', 1, 0],
        contains => '{"deleted":true}',
    },
    {
        name     => '404 for unknown route',
        request  => ['GET', '/nonexistent', '', 1, 0],
        is_404   => 1,
    },
    {
        name     => '404 for wrong method',
        request  => ['POST', '/health', '', 1, 0],
        is_404   => 1,
    },
];

for my $test (@$tests) {
    my $response = $server->dispatch($test->{request});

    if ($test->{is_404}) {
        ok(!defined $response || $response =~ /404/, $test->{name});
    } else {
        ok(defined $response, "$test->{name} - got response");
        like($response, qr/HTTP\/1\.1 200 OK/, "$test->{name} - HTTP 200");
        like($response, qr/\Q$test->{contains}\E/, "$test->{name} - body matches");

        if ($test->{header}) {
            like($response, qr/Content-Type: \Q$test->{header}\E/, "$test->{name} - content type");
        }
    }
}

# Test HTTP response structure
my $resp = $server->dispatch(['GET', '/api/hello', '', 1, 0]);
like($resp, qr/^HTTP\/1\.1 200 OK\r\n/, 'Response starts with HTTP status');
like($resp, qr/Content-Length: \d+\r\n/, 'Has Content-Length header');
like($resp, qr/Connection: keep-alive\r\n/, 'Has Connection header');
like($resp, qr/\r\n\r\n/, 'Has header/body separator');

# Cleanup
system("rm -rf _test_cache");

done_testing();
