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

my $port = 22000 + ($$%1000);
my $cache_dir = "_test_cache_mw_$$";  # Capture before fork!

# Fork a server process to test middleware
my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    # Child - run server
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Global before middleware - adds request ID
    $server->before(sub {
        my ($req) = @_;
        # Set a custom attribute on the request (using the hash underlying the blessed array)
        # For now, just return undef to continue
        return undef;  # Continue to next middleware/handler
    });

    # Global after middleware - could modify response
    $server->after(sub {
        my ($req) = @_;
        # After middleware can return a new response to replace the handler's response
        return undef;  # Use handler's response
    });

    # Test route 1: Basic route with global middleware
    $server->get('/hello' => sub {
        my ($req) = @_;
        return '{"message":"hello"}';
    });

    # Test route 2: Short-circuit before middleware
    $server->get('/auth-required' => sub {
        my ($req) = @_;
        return '{"status":"authorized"}';
    }, {
        dynamic => 1,
        parse_headers => 1,
        before => [
            sub {
                my ($req) = @_;
                my $auth = $req->header('authorization') // '';
                if ($auth ne 'Bearer secret') {
                    return [401, {}, '{"error":"unauthorized"}'];
                }
                return undef;  # Continue
            }
        ]
    });

    # Test route 3: Multiple before middleware
    $server->get('/multi-before' => sub {
        my ($req) = @_;
        return '{"step":"handler"}';
    }, {
        dynamic => 1,
        before => [
            sub { return undef; },  # Pass through
            sub { return undef; },  # Pass through
        ]
    });

    # Test route 4: After middleware modifies response
    $server->get('/with-after' => sub {
        my ($req) = @_;
        return '{"original":"response"}';
    }, {
        dynamic => 1,
        after => [
            sub {
                my ($req) = @_;
                return '{"modified":"by-after"}';
            }
        ]
    });

    # Test route 5: Combined before + after
    $server->get('/combined' => sub {
        my ($req) = @_;
        return '{"handler":"executed"}';
    }, {
        dynamic => 1,
        before => [
            sub { return undef; }  # Pass through
        ],
        after => [
            sub { return undef; }  # Use handler response
        ]
    });

    $server->compile();
    $server->run(port => $port);
    exit(0);
}

# Parent - run tests
sleep(1);  # Wait for server to start

sub make_request {
    my ($method, $path, $headers) = @_;
    $headers //= [];
    
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 2,
    );
    return undef unless $sock;
    
    my $header_str = join("\r\n", @$headers);
    $header_str = "\r\n$header_str" if $header_str;
    
    my $req = "$method $path HTTP/1.1\r\nHost: localhost\r\nConnection: close$header_str\r\n\r\n";
    print $sock $req;
    
    local $/;
    my $response = <$sock>;
    close($sock);
    return $response;
}

# Test 1: Basic route with global middleware
{
    my $resp = make_request('GET', '/hello');
    ok($resp, 'Global middleware: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Global middleware: returns 200');
    like($resp, qr/"message":"hello"/, 'Global middleware: handler executed');
}

# Test 2: Auth middleware - unauthorized
{
    my $resp = make_request('GET', '/auth-required');
    ok($resp, 'Auth (no header): got response');
    like($resp, qr/HTTP\/1\.1 401/, 'Auth (no header): returns 401');
    like($resp, qr/"error":"unauthorized"/, 'Auth (no header): short-circuited');
}

# Test 3: Auth middleware - authorized
{
    my $resp = make_request('GET', '/auth-required', ['Authorization: Bearer secret']);
    ok($resp, 'Auth (with header): got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Auth (with header): returns 200');
    like($resp, qr/"status":"authorized"/, 'Auth (with header): handler executed');
}

# Test 4: Multiple before middleware pass through
{
    my $resp = make_request('GET', '/multi-before');
    ok($resp, 'Multi-before: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Multi-before: returns 200');
    like($resp, qr/"step":"handler"/, 'Multi-before: handler executed');
}

# Test 5: After middleware modifies response
{
    my $resp = make_request('GET', '/with-after');
    ok($resp, 'After middleware: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'After middleware: returns 200');
    like($resp, qr/"modified":"by-after"/, 'After middleware: response modified');
}

# Test 6: Combined before + after
{
    my $resp = make_request('GET', '/combined');
    ok($resp, 'Combined: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Combined: returns 200');
    like($resp, qr/"handler":"executed"/, 'Combined: handler executed');
}

# Cleanup
END {
    if ($pid) {
        kill(9, $pid);
        waitpid($pid, 0);
    }
    # Clean up cache directory
    if (-d $cache_dir) {
        system("rm", "-rf", $cache_dir);
    }
}

done_testing();
