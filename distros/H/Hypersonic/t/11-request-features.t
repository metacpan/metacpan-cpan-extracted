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

my $port = 21000 + ($$%1000);
my $cache_dir = "_test_cache_req_$$";  # Capture before fork!

# Fork a server process to test request features
my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    # Child - run server
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Test named params via $req->param() - JIT accessor
    $server->get('/users/:user_id/posts/:post_id' => sub {
        my ($req) = @_;
        my $user = $req->param('user_id') // 'none';
        my $post = $req->param('post_id') // 'none';
        return qq({"user_id":"$user","post_id":"$post"});
    });

    # Test query string via $req->query_param() - JIT accessor
    $server->get('/search' => sub {
        my ($req) = @_;
        my $q = $req->query_param('q') // '';
        my $page = $req->query_param('page') // '1';
        return qq({"query":"$q","page":"$page"});
    }, { dynamic => 1, parse_query => 1 });

    # Test headers via $req->header() - JIT accessor
    $server->get('/headers' => sub {
        my ($req) = @_;
        my $ua = $req->header('user-agent') // '';
        my $custom = $req->header('x-custom-header') // '';
        return qq({"user_agent":"$ua","custom":"$custom"});
    }, { dynamic => 1, parse_headers => 1 });

    # Test cookies via $req->cookie() - JIT accessor
    $server->get('/cookies' => sub {
        my ($req) = @_;
        my $session = $req->cookie('session') // '';
        my $user = $req->cookie('user') // '';
        return qq({"session":"$session","user":"$user"});
    }, { dynamic => 1, parse_headers => 1, parse_cookies => 1 });

    # Test combined: params + query + headers
    $server->get('/api/:version/items' => sub {
        my ($req) = @_;
        my $ver = $req->param('version') // '';
        my $limit = $req->query_param('limit') // '10';
        my $auth = $req->header('authorization') // '';
        return qq({"version":"$ver","limit":"$limit","auth":"$auth"});
    }, { parse_query => 1, parse_headers => 1 });

    # Test JSON body parsing
    $server->post('/json' => sub {
        my ($req) = @_;
        my $json = $req->json;
        if ($json && ref($json) eq 'HASH') {
            my $name = $json->{name} // '';
            my $value = $json->{value} // '';
            return qq({"received_name":"$name","received_value":"$value"});
        }
        return '{"error":"no json"}';
    }, { dynamic => 1, parse_headers => 1, parse_json => 1 });

    # Test form data parsing
    $server->post('/form' => sub {
        my ($req) = @_;
        my $form = $req->form;
        my $username = $form->{username} // '';
        my $password = $form->{password} // '';
        return qq({"username":"$username","password":"$password"});
    }, { dynamic => 1, parse_headers => 1, parse_form => 1 });

    # Test query string edge cases
    $server->get('/query-edge' => sub {
        my ($req) = @_;
        my $empty = $req->query_param('empty') // 'NOT_SET';
        my $special = $req->query_param('special') // '';
        my $unicode = $req->query_param('unicode') // '';
        my $plus = $req->query_param('plus') // '';
        return qq({"empty":"$empty","special":"$special","unicode":"$unicode","plus":"$plus"});
    }, { dynamic => 1, parse_query => 1 });

    # Test raw query string access
    $server->get('/raw-query' => sub {
        my ($req) = @_;
        my $qs = $req->query_string // '';
        return qq({"query_string":"$qs"});
    }, { dynamic => 1, parse_query => 1 });

    # Test form edge cases
    $server->post('/form-edge' => sub {
        my ($req) = @_;
        my $form = $req->form;
        my $empty = exists $form->{empty} ? ($form->{empty} // 'NULL') : 'NOT_SET';
        my $plus = $form->{plus} // '';
        my $amp = $form->{amp} // '';
        return qq({"empty":"$empty","plus":"$plus","amp":"$amp"});
    }, { dynamic => 1, parse_headers => 1, parse_form => 1 });

    $server->compile();
    $server->run(port => $port);
    exit(0);
}

# Parent - run tests
sleep(1);  # Wait for server to start

sub make_request {
    my ($method, $path, $headers, $body) = @_;
    $headers //= [];
    $body //= '';
    
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 2,
    );
    return undef unless $sock;
    
    my $content_length = length($body);
    my $header_str = join("\r\n", @$headers);
    $header_str = "\r\n$header_str" if $header_str;
    
    my $req = "$method $path HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\nContent-Length: $content_length$header_str\r\n\r\n$body";
    print $sock $req;
    
    local $/;
    my $response = <$sock>;
    close($sock);
    return $response;
}

# Test 1: Named path params
{
    my $resp = make_request('GET', '/users/42/posts/123');
    ok($resp, 'Named params: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Named params: returns 200');
    like($resp, qr/"user_id":"42"/, 'Named params: user_id extracted');
    like($resp, qr/"post_id":"123"/, 'Named params: post_id extracted');
}

# Test 2: Query string parsing
{
    my $resp = make_request('GET', '/search?q=hello%20world&page=5');
    ok($resp, 'Query string: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Query string: returns 200');
    like($resp, qr/"query":"hello world"/, 'Query string: q decoded');
    like($resp, qr/"page":"5"/, 'Query string: page extracted');
}

# Test 3: Query string with no params
{
    my $resp = make_request('GET', '/search');
    ok($resp, 'No query: got response');
    like($resp, qr/"query":""/, 'No query: empty q');
    like($resp, qr/"page":"1"/, 'No query: default page');
}

# Test 4: Header access
{
    my $resp = make_request('GET', '/headers', [
        'User-Agent: TestBot/1.0',
        'X-Custom-Header: custom-value',
    ]);
    ok($resp, 'Headers: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Headers: returns 200');
    like($resp, qr/"user_agent":"TestBot\/1\.0"/, 'Headers: User-Agent extracted');
    like($resp, qr/"custom":"custom-value"/, 'Headers: X-Custom-Header extracted');
}

# Test 5: Cookie parsing
{
    my $resp = make_request('GET', '/cookies', [
        'Cookie: session=abc123; user=john',
    ]);
    ok($resp, 'Cookies: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Cookies: returns 200');
    like($resp, qr/"session":"abc123"/, 'Cookies: session extracted');
    like($resp, qr/"user":"john"/, 'Cookies: user extracted');
}

# Test 6: Combined params + query + headers
{
    my $resp = make_request('GET', '/api/v2/items?limit=25', [
        'Authorization: Bearer token123',
    ]);
    ok($resp, 'Combined: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Combined: returns 200');
    like($resp, qr/"version":"v2"/, 'Combined: path param extracted');
    like($resp, qr/"limit":"25"/, 'Combined: query param extracted');
    like($resp, qr/"auth":"Bearer token123"/, 'Combined: header extracted');
}

# Test 7: JSON body parsing
{
    my $json_body = '{"name":"test","value":42}';
    my $resp = make_request('POST', '/json', [
        'Content-Type: application/json',
    ], $json_body);
    ok($resp, 'JSON: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'JSON: returns 200');
    like($resp, qr/"received_name":"test"/, 'JSON: name extracted');
    like($resp, qr/"received_value":"42"/, 'JSON: value extracted');
}

# Test 8: Form data parsing
{
    my $form_body = 'username=john&password=secret123';
    my $resp = make_request('POST', '/form', [
        'Content-Type: application/x-www-form-urlencoded',
    ], $form_body);
    ok($resp, 'Form: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Form: returns 200');
    like($resp, qr/"username":"john"/, 'Form: username extracted');
    like($resp, qr/"password":"secret123"/, 'Form: password extracted');
}

# Test 9: Form data with URL encoding
{
    my $form_body = 'username=hello%20world&password=test';
    my $resp = make_request('POST', '/form', [
        'Content-Type: application/x-www-form-urlencoded',
    ], $form_body);
    ok($resp, 'Form encoded: got response');
    like($resp, qr/"username":"hello world"/, 'Form encoded: space decoded');
}

# Test 10: Query string with empty value
{
    my $resp = make_request('GET', '/query-edge?empty=&other=value');
    ok($resp, 'Query empty value: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Query empty value: returns 200');
    like($resp, qr/"empty":""/, 'Query empty value: empty string captured');
}

# Test 11: Query string with special characters (URL encoded)
{
    my $resp = make_request('GET', '/query-edge?special=%26%3D%3F&other=x');
    ok($resp, 'Query special chars: got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Query special chars: returns 200');
    like($resp, qr/"special":"&=\?"/, 'Query special chars: decoded correctly');
}

# Test 12: Query string with plus sign as space
{
    my $resp = make_request('GET', '/query-edge?plus=hello+world');
    ok($resp, 'Query plus sign: got response');
    like($resp, qr/"plus":"hello world"/, 'Query plus sign: converted to space');
}

# Test 13: Query string with only key (no equals)
{
    my $resp = make_request('GET', '/query-edge?empty');
    ok($resp, 'Query key only: got response');
    # Key without = should be treated as key with empty value or not exist
    # depending on implementation
}

# Test 14: Raw query string access
{
    my $resp = make_request('GET', '/raw-query?foo=bar&baz=qux');
    ok($resp, 'Raw query: got response');
    like($resp, qr/"query_string":"foo=bar&baz=qux"/, 'Raw query: full string accessible');
}

# Test 15: Form with empty value
{
    my $form_body = 'empty=&other=value';
    my $resp = make_request('POST', '/form-edge', [
        'Content-Type: application/x-www-form-urlencoded',
    ], $form_body);
    ok($resp, 'Form empty value: got response');
    like($resp, qr/"empty":""/, 'Form empty value: empty string captured');
}

# Test 16: Form with plus sign encoding
{
    my $form_body = 'plus=hello+there&other=x';
    my $resp = make_request('POST', '/form-edge', [
        'Content-Type: application/x-www-form-urlencoded',
    ], $form_body);
    ok($resp, 'Form plus sign: got response');
    like($resp, qr/"plus":"hello there"/, 'Form plus sign: converted to space');
}

# Test 17: Form with %26 (encoded ampersand)
{
    my $form_body = 'amp=one%26two&other=x';
    my $resp = make_request('POST', '/form-edge', [
        'Content-Type: application/x-www-form-urlencoded',
    ], $form_body);
    ok($resp, 'Form encoded amp: got response');
    like($resp, qr/"amp":"one&two"/, 'Form encoded amp: decoded correctly');
}

# Cleanup
END {
    if ($pid) {
        kill(9, $pid);
        waitpid($pid, 0);
        system("rm -rf $cache_dir");
    }
}

done_testing();
