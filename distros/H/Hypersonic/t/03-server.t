use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

# Skip if we can't fork
plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 19876 + ($$ % 1000);  # Use unique port based on PID
my $cache_dir = "_test_cache_$$";  # Capture before fork!

# Fork a server process
my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    # Child - run server
    my $server = Hypersonic->new(cache_dir => $cache_dir);
    $server->get('/test' => sub { 'Hello from Hypersonic!' });
    $server->get('/json' => sub { '{"status":"ok","server":"hypersonic"}' });
    $server->post('/echo' => sub { '{"echo":"received"}' });
    $server->compile();
    $server->run(port => $port, workers => 1);
    exit(0);
}

# Parent - wait for server to start
sleep(2);

# Test helper to make HTTP requests
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

# Test 1: Basic GET request
$resp = http_request('GET', '/test');
ok($resp, 'Got response for GET /test');
like($resp, qr/HTTP\/1\.1 200 OK/, 'GET /test returns 200');
like($resp, qr/Hello from Hypersonic!/, 'GET /test has correct body');

# Test 2: JSON response
$resp = http_request('GET', '/json');
ok($resp, 'Got response for GET /json');
like($resp, qr/Content-Type: application\/json/, 'JSON content type');
like($resp, qr/"status":"ok"/, 'JSON body correct');

# Test 3: POST request
$resp = http_request('POST', '/echo', '{"data":"test"}');
ok($resp, 'Got response for POST /echo');
like($resp, qr/HTTP\/1\.1 200 OK/, 'POST returns 200');
like($resp, qr/"echo":"received"/, 'POST body correct');

# Test 4: 404 for unknown route
$resp = http_request('GET', '/unknown');
ok($resp, 'Got response for unknown route');
like($resp, qr/HTTP\/1\.1 404/, '404 for unknown route');
like($resp, qr/Not Found/, '404 body');

# Test 5: 404 for wrong method
$resp = http_request('DELETE', '/test');
ok($resp, 'Got response for wrong method');
like($resp, qr/HTTP\/1\.1 404/, '404 for wrong method');

# Test 6: Multiple requests (keep-alive simulation)
for my $i (1..5) {
    $resp = http_request('GET', '/test');
    ok($resp, "Request $i successful");
    like($resp, qr/200 OK/, "Request $i returns 200");
}

# Cleanup
kill('TERM', $pid);
waitpid($pid, 0);

# Clean up cache
system("rm -rf $cache_dir");

done_testing();
