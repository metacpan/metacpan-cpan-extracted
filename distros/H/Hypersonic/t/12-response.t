use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;
use Hypersonic::Response 'res';

# Skip if we can't fork
plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

# ============================================================
# Unit tests for Hypersonic::Response (no server needed)
# ============================================================

subtest 'Response basic methods' => sub {
    my $res = Hypersonic::Response->new();
    is($res->[Hypersonic::Response::SLOT_STATUS], 200, 'Default status is 200');

    $res->status(201);
    is($res->[Hypersonic::Response::SLOT_STATUS], 201, 'status() sets status');

    $res->header('X-Custom', 'test-value');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Custom'}, 'test-value', 'header() sets header');

    $res->body('Hello World');
    is($res->[Hypersonic::Response::SLOT_BODY], 'Hello World', 'body() sets body');
};

subtest 'Response content helpers' => sub {
    my $res = Hypersonic::Response->new();

    $res->text('plain text');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'text/plain', 'text() sets Content-Type');
    is($res->[Hypersonic::Response::SLOT_BODY], 'plain text', 'text() sets body');

    $res = Hypersonic::Response->new();
    $res->html('<h1>Hello</h1>');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'text/html', 'html() sets Content-Type');
    is($res->[Hypersonic::Response::SLOT_BODY], '<h1>Hello</h1>', 'html() sets body');

    $res = Hypersonic::Response->new();
    $res->json({ key => 'value' });
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'application/json', 'json() sets Content-Type');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/"key"/, 'json() encodes data');
};

subtest 'Response redirect' => sub {
    my $res = Hypersonic::Response->new();
    $res->redirect('/new-location');
    is($res->[Hypersonic::Response::SLOT_STATUS], 302, 'redirect() sets 302 by default');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Location'}, '/new-location', 'redirect() sets Location');

    $res = Hypersonic::Response->new();
    $res->redirect('/permanent', 301);
    is($res->[Hypersonic::Response::SLOT_STATUS], 301, 'redirect() accepts custom status');
};

subtest 'Response cookies' => sub {
    my $res = Hypersonic::Response->new();

    $res->cookie('session', 'abc123');
    is(scalar @{$res->[Hypersonic::Response::SLOT_COOKIES]}, 1, 'cookie() adds to cookies array');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/session=abc123/, 'cookie has name=value');

    $res->cookie('user', 'john', httponly => 1, secure => 1, samesite => 'Strict');
    is(scalar @{$res->[Hypersonic::Response::SLOT_COOKIES]}, 2, 'Multiple cookies');
    like($res->[Hypersonic::Response::SLOT_COOKIES][1], qr/HttpOnly/, 'cookie has HttpOnly');
    like($res->[Hypersonic::Response::SLOT_COOKIES][1], qr/Secure/, 'cookie has Secure');
    like($res->[Hypersonic::Response::SLOT_COOKIES][1], qr/SameSite=Strict/, 'cookie has SameSite');

    my $final = $res->finalize;
    is(ref($final->{headers}{'Set-Cookie'}), 'ARRAY', 'finalize() returns cookies as array');
    is(scalar @{$final->{headers}{'Set-Cookie'}}, 2, 'finalize() has all cookies');
};

subtest 'Response error helpers' => sub {
    my $res = Hypersonic::Response->new();
    $res->bad_request('Invalid input');
    is($res->[Hypersonic::Response::SLOT_STATUS], 400, 'bad_request() sets 400');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/Invalid input/, 'bad_request() includes message');

    $res = Hypersonic::Response->new();
    $res->not_found();
    is($res->[Hypersonic::Response::SLOT_STATUS], 404, 'not_found() sets 404');

    $res = Hypersonic::Response->new();
    $res->unauthorized();
    is($res->[Hypersonic::Response::SLOT_STATUS], 401, 'unauthorized() sets 401');

    $res = Hypersonic::Response->new();
    $res->forbidden();
    is($res->[Hypersonic::Response::SLOT_STATUS], 403, 'forbidden() sets 403');

    $res = Hypersonic::Response->new();
    $res->server_error();
    is($res->[Hypersonic::Response::SLOT_STATUS], 500, 'server_error() sets 500');
};

subtest 'res() shortcut' => sub {
    my $r = res();
    isa_ok($r, 'Hypersonic::Response', 'res() returns Response object');
    is($r->[Hypersonic::Response::SLOT_STATUS], 200, 'res() default status');
    
    $r = res->status(404)->json({ error => 'not found' });
    is($r->[Hypersonic::Response::SLOT_STATUS], 404, 'res() chaining works');
};

subtest 'Response additional methods' => sub {
    # content_type
    my $res = Hypersonic::Response->new();
    $res->content_type('image/png');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'image/png', 'content_type() works');
    
    # cache
    $res = Hypersonic::Response->new();
    $res->cache('public, max-age=3600');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Cache-Control'}, 'public, max-age=3600', 'cache() works');
    
    # no_cache
    $res = Hypersonic::Response->new();
    $res->no_cache;
    like($res->[Hypersonic::Response::SLOT_HEADERS]{'Cache-Control'}, qr/no-store/, 'no_cache() sets Cache-Control');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Pragma'}, 'no-cache', 'no_cache() sets Pragma');
    
    # etag
    $res = Hypersonic::Response->new();
    $res->etag('abc123');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'ETag'}, '"abc123"', 'etag() wraps in quotes');
    
    # attachment
    $res = Hypersonic::Response->new();
    $res->attachment('report.pdf');
    like($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Disposition'}, qr/attachment/, 'attachment() sets header');
    like($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Disposition'}, qr/report\.pdf/, 'attachment() includes filename');
    
    # created
    $res = Hypersonic::Response->new();
    $res->created('/items/123');
    is($res->[Hypersonic::Response::SLOT_STATUS], 201, 'created() sets 201');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Location'}, '/items/123', 'created() sets Location');
    
    # no_content
    $res = Hypersonic::Response->new();
    $res->no_content;
    is($res->[Hypersonic::Response::SLOT_STATUS], 204, 'no_content() sets 204');
    is($res->[Hypersonic::Response::SLOT_BODY], '', 'no_content() clears body');
    
    # conflict
    $res = Hypersonic::Response->new();
    $res->conflict('Already exists');
    is($res->[Hypersonic::Response::SLOT_STATUS], 409, 'conflict() sets 409');
    
    # unprocessable
    $res = Hypersonic::Response->new();
    $res->unprocessable('Validation failed');
    is($res->[Hypersonic::Response::SLOT_STATUS], 422, 'unprocessable() sets 422');
    
    # too_many_requests
    $res = Hypersonic::Response->new();
    $res->too_many_requests(60);
    is($res->[Hypersonic::Response::SLOT_STATUS], 429, 'too_many_requests() sets 429');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Retry-After'}, 60, 'too_many_requests() sets Retry-After');
    
    # unavailable
    $res = Hypersonic::Response->new();
    $res->unavailable(300);
    is($res->[Hypersonic::Response::SLOT_STATUS], 503, 'unavailable() sets 503');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Retry-After'}, 300, 'unavailable() sets Retry-After');
    
    # clear_cookie
    $res = Hypersonic::Response->new();
    $res->clear_cookie('session');
    is(scalar @{$res->[Hypersonic::Response::SLOT_COOKIES]}, 1, 'clear_cookie() adds cookie');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Max-Age=0/, 'clear_cookie() sets Max-Age=0');
    
    # xml
    $res = Hypersonic::Response->new();
    $res->xml('<root/>');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'application/xml', 'xml() sets Content-Type');
    
    # last_modified
    $res = Hypersonic::Response->new();
    $res->last_modified(0);  # Unix epoch
    like($res->[Hypersonic::Response::SLOT_HEADERS]{'Last-Modified'}, qr/GMT/, 'last_modified() sets GMT date');
};

subtest 'Response finalize' => sub {
    my $res = Hypersonic::Response->new()
        ->status(201)
        ->header('X-Custom', 'value')
        ->json({ success => 1 });

    my $final = $res->finalize;
    is(ref($final), 'HASH', 'finalize() returns hashref');
    is($final->{status}, 201, 'finalize() includes status');
    is($final->{headers}{'Content-Type'}, 'application/json', 'finalize() includes Content-Type');
    is($final->{headers}{'X-Custom'}, 'value', 'finalize() includes custom header');
    ok(defined $final->{body}, 'finalize() includes body');
};

subtest 'Response chaining' => sub {
    my $res = Hypersonic::Response->new()
        ->status(200)
        ->header('X-One', '1')
        ->header('X-Two', '2')
        ->json({ count => 2 })
        ->cookie('visited', '1');

    is($res->[Hypersonic::Response::SLOT_STATUS], 200, 'Chained status');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-One'}, '1', 'Chained header 1');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Two'}, '2', 'Chained header 2');
    is(scalar @{$res->[Hypersonic::Response::SLOT_COOKIES]}, 1, 'Chained cookie');
};

# ============================================================
# to_http() tests - Direct HTTP response generation
# ============================================================

subtest 'to_http() basic response' => sub {
    my $res = Hypersonic::Response->new()
        ->status(200)
        ->text('Hello World');

    my $http = $res->to_http();
    ok(defined $http, 'to_http() returns value');
    like($http, qr/^HTTP\/1\.1 200 OK\r\n/, 'to_http() has status line');
    like($http, qr/Content-Type: text\/plain\r\n/, 'to_http() has Content-Type header');
    like($http, qr/Content-Length: 11\r\n/, 'to_http() has correct Content-Length');
    like($http, qr/\r\n\r\nHello World$/, 'to_http() has body after blank line');
};

subtest 'to_http() with multiple headers' => sub {
    my $res = Hypersonic::Response->new()
        ->status(201)
        ->header('X-Request-Id', 'abc123')
        ->header('X-Custom', 'value')
        ->json({ created => 1 });

    my $http = $res->to_http();
    like($http, qr/^HTTP\/1\.1 201 Created\r\n/, 'to_http() 201 status');
    like($http, qr/X-Request-Id: abc123\r\n/, 'to_http() includes custom header 1');
    like($http, qr/X-Custom: value\r\n/, 'to_http() includes custom header 2');
    like($http, qr/Content-Type: application\/json\r\n/, 'to_http() includes JSON content type');
    like($http, qr/"created":1/, 'to_http() includes JSON body');
};

subtest 'to_http() with cookies' => sub {
    my $res = Hypersonic::Response->new()
        ->json({ ok => 1 })
        ->cookie('session', 'token123', httponly => 1, secure => 1)
        ->cookie('user', 'alice');

    my $http = $res->to_http();
    like($http, qr/Set-Cookie: session=token123/, 'to_http() includes first cookie');
    like($http, qr/HttpOnly/, 'to_http() includes HttpOnly flag');
    like($http, qr/Secure/, 'to_http() includes Secure flag');
    like($http, qr/Set-Cookie: user=alice/, 'to_http() includes second cookie');
};

subtest 'to_http() status codes' => sub {
    # Test various status codes
    my @status_tests = (
        [200, 'OK'],
        [201, 'Created'],
        [204, 'No Content'],
        [301, 'Moved Permanently'],
        [302, 'Found'],
        [304, 'Not Modified'],
        [400, 'Bad Request'],
        [401, 'Unauthorized'],
        [403, 'Forbidden'],
        [404, 'Not Found'],
        [409, 'Conflict'],
        [422, 'Unprocessable Entity'],
        [429, 'Too Many Requests'],
        [500, 'Internal Server Error'],
        [502, 'Bad Gateway'],
        [503, 'Service Unavailable'],
    );

    for my $test (@status_tests) {
        my ($code, $text) = @$test;
        my $res = Hypersonic::Response->new()->status($code)->body('test');
        my $http = $res->to_http();
        like($http, qr/^HTTP\/1\.1 $code $text\r\n/, "to_http() status $code $text");
    }
};

subtest 'to_http() redirect' => sub {
    my $res = Hypersonic::Response->new()
        ->redirect('/new-location', 301);

    my $http = $res->to_http();
    like($http, qr/^HTTP\/1\.1 301 Moved Permanently\r\n/, 'to_http() redirect status');
    like($http, qr/Location: \/new-location\r\n/, 'to_http() redirect Location header');
};

subtest 'to_http() empty body' => sub {
    my $res = Hypersonic::Response->new()
        ->status(204)
        ->body('');

    my $http = $res->to_http();
    like($http, qr/^HTTP\/1\.1 204 No Content\r\n/, 'to_http() 204 status');
    like($http, qr/Content-Length: 0\r\n/, 'to_http() zero content length');
    like($http, qr/\r\n\r\n$/, 'to_http() ends with blank line (no body)');
};

subtest 'to_http() binary-safe body' => sub {
    my $binary = "Hello\x00World\xFF";
    my $res = Hypersonic::Response->new()
        ->content_type('application/octet-stream')
        ->body($binary);

    my $http = $res->to_http();
    like($http, qr/Content-Length: 12\r\n/, 'to_http() correct length for binary');
    # Check body ends with our binary data
    ok(substr($http, -12) eq $binary, 'to_http() preserves binary body');
};

# ============================================================
# headers() multi-set tests
# ============================================================

subtest 'headers() sets multiple at once' => sub {
    my $res = Hypersonic::Response->new();
    $res->headers(
        'X-One' => 'value1',
        'X-Two' => 'value2',
        'X-Three' => 'value3',
    );

    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-One'}, 'value1', 'headers() sets first');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Two'}, 'value2', 'headers() sets second');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Three'}, 'value3', 'headers() sets third');

    # Test chaining
    my $r2 = $res->headers('X-Four' => '4');
    is($r2, $res, 'headers() returns $self for chaining');
};

# ============================================================
# Cookie attribute coverage
# ============================================================

subtest 'cookie() all attributes' => sub {
    my $res = Hypersonic::Response->new();

    # Test path
    $res->cookie('c1', 'v1', path => '/api');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Path=\/api/, 'cookie path attribute');

    # Test domain
    $res = Hypersonic::Response->new();
    $res->cookie('c2', 'v2', domain => '.example.com');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Domain=\.example\.com/, 'cookie domain attribute');

    # Test max_age
    $res = Hypersonic::Response->new();
    $res->cookie('c3', 'v3', max_age => 3600);
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Max-Age=3600/, 'cookie max_age attribute');

    # Test expires
    $res = Hypersonic::Response->new();
    $res->cookie('c4', 'v4', expires => 'Thu, 01 Jan 2030 00:00:00 GMT');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Expires=Thu, 01 Jan 2030/, 'cookie expires attribute');

    # Test SameSite variations
    $res = Hypersonic::Response->new();
    $res->cookie('c5', 'v5', samesite => 'Lax');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/SameSite=Lax/, 'cookie SameSite=Lax');

    $res = Hypersonic::Response->new();
    $res->cookie('c6', 'v6', samesite => 'None', secure => 1);
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/SameSite=None/, 'cookie SameSite=None');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/Secure/, 'cookie Secure with SameSite=None');

    # Test all attributes combined
    $res = Hypersonic::Response->new();
    $res->cookie('session', 'token',
        path => '/',
        domain => '.example.com',
        max_age => 86400,
        httponly => 1,
        secure => 1,
        samesite => 'Strict',
    );
    my $cookie = $res->[Hypersonic::Response::SLOT_COOKIES][0];
    like($cookie, qr/session=token/, 'combined cookie name=value');
    like($cookie, qr/Path=\//, 'combined cookie path');
    like($cookie, qr/Domain=\.example\.com/, 'combined cookie domain');
    like($cookie, qr/Max-Age=86400/, 'combined cookie max_age');
    like($cookie, qr/HttpOnly/, 'combined cookie httponly');
    like($cookie, qr/Secure/, 'combined cookie secure');
    like($cookie, qr/SameSite=Strict/, 'combined cookie samesite');
};

# ============================================================
# Error response JSON format
# ============================================================

subtest 'error helpers return JSON' => sub {
    my $res = Hypersonic::Response->new();
    $res->bad_request('Bad input');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'application/json', 'bad_request() sets JSON type');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{"error":"Bad input"\}$/, 'bad_request() JSON format');

    $res = Hypersonic::Response->new();
    $res->unauthorized('No token');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{"error":"No token"\}$/, 'unauthorized() JSON format');

    $res = Hypersonic::Response->new();
    $res->forbidden('Denied');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{"error":"Denied"\}$/, 'forbidden() JSON format');

    $res = Hypersonic::Response->new();
    $res->not_found('Missing');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{"error":"Missing"\}$/, 'not_found() JSON format');

    $res = Hypersonic::Response->new();
    $res->server_error('Oops');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{"error":"Oops"\}$/, 'server_error() JSON format');
};

subtest 'error helpers escape quotes' => sub {
    my $res = Hypersonic::Response->new();
    $res->bad_request('Invalid "value" provided');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/\\"value\\"/, 'error message escapes quotes');
};

# ============================================================
# Constructor options
# ============================================================

subtest 'new() with options' => sub {
    my $res = Hypersonic::Response->new(
        status  => 404,
        headers => { 'X-Custom' => 'preset' },
        body    => 'preset body',
    );

    is($res->[Hypersonic::Response::SLOT_STATUS], 404, 'new() accepts status option');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Custom'}, 'preset', 'new() accepts headers option');
    is($res->[Hypersonic::Response::SLOT_BODY], 'preset body', 'new() accepts body option');
};

# ============================================================
# TO_JSON for JSON::XS compatibility
# ============================================================

subtest 'TO_JSON auto-finalize' => sub {
    my $res = Hypersonic::Response->new()
        ->status(200)
        ->json({ data => 'value' });

    my $final = $res->TO_JSON;
    is(ref($final), 'HASH', 'TO_JSON returns hashref');
    is($final->{status}, 200, 'TO_JSON includes status');
    ok(exists $final->{headers}, 'TO_JSON includes headers');
    ok(exists $final->{body}, 'TO_JSON includes body');
};

# ============================================================
# Slot constant exports
# ============================================================

subtest 'slot constants exported' => sub {
    # Test that slot constants are usable
    is(Hypersonic::Response::SLOT_STATUS, 0, 'SLOT_STATUS is 0');
    is(Hypersonic::Response::SLOT_HEADERS, 1, 'SLOT_HEADERS is 1');
    is(Hypersonic::Response::SLOT_BODY, 2, 'SLOT_BODY is 2');
    is(Hypersonic::Response::SLOT_COOKIES, 3, 'SLOT_COOKIES is 3');
    is(Hypersonic::Response::SLOT_COUNT, 4, 'SLOT_COUNT is 4');
};

# ============================================================
# Edge cases and additional coverage
# ============================================================

subtest 'Response with very long body' => sub {
    my $long_body = 'x' x 100_000;
    my $res = Hypersonic::Response->new()
        ->text($long_body);

    my $http = $res->to_http();
    like($http, qr/Content-Length: 100000\r\n/, 'Large body Content-Length correct');
    ok(length($http) > 100_000, 'to_http() includes full large body');
};

subtest 'Response with unicode body' => sub {
    my $unicode = "Hello \x{4E16}\x{754C}";  # Hello 世界
    my $res = Hypersonic::Response->new()
        ->text($unicode);

    my $http = $res->to_http();
    ok(defined $http, 'to_http() handles unicode');
    like($http, qr/Content-Length: \d+\r\n/, 'Has Content-Length');
};

subtest 'Response unknown status code' => sub {
    # Test a non-standard status code
    my $res = Hypersonic::Response->new()
        ->status(418)  # I'm a teapot
        ->text("I'm a teapot");

    my $http = $res->to_http();
    like($http, qr/^HTTP\/1\.1 418 /, 'Unknown status code included');
};

subtest 'Response header case preservation' => sub {
    my $res = Hypersonic::Response->new()
        ->header('X-Custom-Header', 'value1')
        ->header('x-another-header', 'value2');

    is($res->[Hypersonic::Response::SLOT_HEADERS]{'X-Custom-Header'}, 'value1', 'Original case preserved');
    is($res->[Hypersonic::Response::SLOT_HEADERS]{'x-another-header'}, 'value2', 'Lowercase preserved');
};

subtest 'Response body overwrite' => sub {
    my $res = Hypersonic::Response->new()
        ->text('first body')
        ->json({ replaced => 1 });

    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'application/json', 'Content-Type updated');
    like($res->[Hypersonic::Response::SLOT_BODY], qr/replaced/, 'Body replaced');
};

subtest 'Response multiple cookies same name' => sub {
    my $res = Hypersonic::Response->new()
        ->cookie('session', 'first')
        ->cookie('session', 'second');

    is(scalar @{$res->[Hypersonic::Response::SLOT_COOKIES]}, 2, 'Both cookies added');
    like($res->[Hypersonic::Response::SLOT_COOKIES][0], qr/session=first/, 'First cookie preserved');
    like($res->[Hypersonic::Response::SLOT_COOKIES][1], qr/session=second/, 'Second cookie added');
};

subtest 'Response empty JSON object' => sub {
    my $res = Hypersonic::Response->new()->json({});
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\{\}$/, 'Empty JSON object');
};

subtest 'Response JSON array' => sub {
    my $res = Hypersonic::Response->new()->json([1, 2, 3]);
    like($res->[Hypersonic::Response::SLOT_BODY], qr/^\[1,2,3\]$/, 'JSON array encoded');
};

subtest 'Response status without body' => sub {
    my $res = Hypersonic::Response->new()->status(304);
    my $final = $res->finalize;
    is($final->{status}, 304, 'Status-only response has status');
    ok(!$final->{body} || $final->{body} eq '', 'No body for 304');
};

subtest 'Response special characters in header value' => sub {
    my $res = Hypersonic::Response->new()
        ->header('X-Message', 'Hello, World! (special: "chars")');

    my $http = $res->to_http();
    like($http, qr/X-Message: Hello, World! \(special: "chars"\)/, 'Special chars in header');
};

subtest 'Response Content-Type charset' => sub {
    my $res = Hypersonic::Response->new()
        ->content_type('text/html; charset=utf-8')
        ->body('<html></html>');

    is($res->[Hypersonic::Response::SLOT_HEADERS]{'Content-Type'}, 'text/html; charset=utf-8', 'Content-Type with charset');
};

subtest 'Response null byte in body' => sub {
    my $body_with_null = "before\x00after";
    my $res = Hypersonic::Response->new()
        ->content_type('application/octet-stream')
        ->body($body_with_null);

    my $http = $res->to_http();
    like($http, qr/Content-Length: 12\r\n/, 'Null byte counted in length');
    ok(index($http, $body_with_null) > 0, 'Null byte preserved in body');
};

subtest 'clear_cookie with path and domain' => sub {
    my $res = Hypersonic::Response->new()
        ->clear_cookie('session', path => '/app', domain => '.example.com');

    my $cookie = $res->[Hypersonic::Response::SLOT_COOKIES][0];
    like($cookie, qr/Max-Age=0/, 'clear_cookie sets Max-Age=0');
    like($cookie, qr/Path=\/app/, 'clear_cookie includes path');
    like($cookie, qr/Domain=\.example\.com/, 'clear_cookie includes domain');
};

subtest 'finalize multiple times' => sub {
    my $res = Hypersonic::Response->new()
        ->status(200)
        ->json({ ok => 1 });

    my $final1 = $res->finalize;
    my $final2 = $res->finalize;

    is_deeply($final1, $final2, 'finalize() is idempotent');
};

subtest 'to_http multiple times' => sub {
    my $res = Hypersonic::Response->new()
        ->text('test');

    my $http1 = $res->to_http();
    my $http2 = $res->to_http();

    is($http1, $http2, 'to_http() is idempotent');
};

# ============================================================
# Integration tests with actual server
# ============================================================

my $port = 22000 + ($$ % 1000);
my $cache_dir = "_test_cache_resp_$$";  # Capture before fork!

my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    # Child - run server
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Test JSON response
    $server->get('/api/json' => sub {
        my ($req) = @_;
        return Hypersonic::Response->new()
            ->json({ message => 'hello' })
            ->finalize;
    }, { dynamic => 1 });

    # Test custom status
    $server->post('/api/create' => sub {
        my ($req) = @_;
        return Hypersonic::Response->new()
            ->status(201)
            ->header('Location', '/api/items/123')
            ->json({ id => 123 })
            ->finalize;
    }, { dynamic => 1 });

    # Test redirect
    $server->get('/old-path' => sub {
        return Hypersonic::Response->new()
            ->redirect('/new-path', 301)
            ->finalize;
    }, { dynamic => 1 });

    # Test cookies
    $server->get('/set-cookie' => sub {
        return Hypersonic::Response->new()
            ->json({ ok => 1 })
            ->cookie('session', 'xyz789', httponly => 1)
            ->cookie('user', 'alice')
            ->finalize;
    }, { dynamic => 1 });

    # Test error response
    $server->get('/error' => sub {
        return Hypersonic::Response->new()
            ->not_found('Resource not found')
            ->finalize;
    }, { dynamic => 1 });

    # Test HTML response
    $server->get('/page' => sub {
        return Hypersonic::Response->new()
            ->html('<html><body><h1>Hello</h1></body></html>')
            ->finalize;
    }, { dynamic => 1 });

    # Test res() shortcut in server context
    $server->get('/api/res-shortcut' => sub {
        return res()
            ->status(200)
            ->header('X-Via', 'res-shortcut')
            ->json({ via => 'res' })
            ->finalize;
    }, { dynamic => 1 });

    # Test complex chained response
    $server->post('/api/complex' => sub {
        my ($req) = @_;
        return res()
            ->status(201)
            ->header('X-Request-Id', 'req-123')
            ->header('X-Processing-Time', '5ms')
            ->json({ id => 999, created => 1 })
            ->cookie('last_created', '999')
            ->finalize;
    }, { dynamic => 1 });

    # Test text response
    $server->get('/api/text' => sub {
        return res()->text('Plain text response')->finalize;
    }, { dynamic => 1 });

    # Test xml response
    $server->get('/api/xml' => sub {
        return res()->xml('<root><item>test</item></root>')->finalize;
    }, { dynamic => 1 });

    $server->compile();
    $server->run(port => $port);
    exit(0);
}

# Parent - run tests
sleep(1);

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

subtest 'Server: JSON response' => sub {
    my $resp = make_request('GET', '/api/json');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: application\/json/, 'Content-Type JSON');
    like($resp, qr/"message":"hello"/, 'JSON body');
};

subtest 'Server: Custom status and Location header' => sub {
    my $resp = make_request('POST', '/api/create');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 201/, 'Status 201 Created');
    like($resp, qr/Location: \/api\/items\/123/, 'Location header');
    like($resp, qr/"id":123/, 'JSON body');
};

subtest 'Server: Redirect' => sub {
    my $resp = make_request('GET', '/old-path');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 301/, 'Status 301');
    like($resp, qr/Location: \/new-path/, 'Location header for redirect');
};

subtest 'Server: Set-Cookie headers' => sub {
    my $resp = make_request('GET', '/set-cookie');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Set-Cookie: session=xyz789/, 'First cookie');
    like($resp, qr/HttpOnly/, 'HttpOnly flag');
    like($resp, qr/Set-Cookie: user=alice/, 'Second cookie');
};

subtest 'Server: Error response' => sub {
    my $resp = make_request('GET', '/error');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 404/, 'Status 404');
    like($resp, qr/Resource not found/, 'Error message in body');
};

subtest 'Server: HTML response' => sub {
    my $resp = make_request('GET', '/page');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: text\/html/, 'Content-Type HTML');
    like($resp, qr/<h1>Hello<\/h1>/, 'HTML body');
};

# ============================================================
# Additional server integration tests
# ============================================================

subtest 'Server: res() shortcut' => sub {
    my $resp = make_request('GET', '/api/res-shortcut');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'res() shortcut Status 200');
    like($resp, qr/X-Via: res-shortcut/, 'res() shortcut custom header');
    like($resp, qr/Content-Type: application\/json/, 'res() shortcut Content-Type');
    like($resp, qr/"via":"res"/, 'res() shortcut JSON body');
};

subtest 'Server: Complex chained response' => sub {
    my $resp = make_request('POST', '/api/complex');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 201/, 'Complex Status 201');
    like($resp, qr/X-Request-Id: req-123/, 'Complex header 1');
    like($resp, qr/X-Processing-Time: 5ms/, 'Complex header 2');
    like($resp, qr/Content-Type: application\/json/, 'Complex Content-Type');
    like($resp, qr/Set-Cookie: last_created=999/, 'Complex cookie');
    like($resp, qr/"id":999/, 'Complex JSON body');
};

subtest 'Server: text() response' => sub {
    my $resp = make_request('GET', '/api/text');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'text() Status 200');
    like($resp, qr/Content-Type: text\/plain/, 'text() Content-Type');
    like($resp, qr/Plain text response/, 'text() body');
};

subtest 'Server: xml() response' => sub {
    my $resp = make_request('GET', '/api/xml');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'xml() Status 200');
    like($resp, qr/Content-Type: application\/xml/, 'xml() Content-Type');
    like($resp, qr/<root><item>test<\/item><\/root>/, 'xml() body');
};

# Cleanup
END {
    if ($pid) {
        kill(9, $pid);
        waitpid($pid, 0);
        system("rm -rf $cache_dir");
    }
}

done_testing();
