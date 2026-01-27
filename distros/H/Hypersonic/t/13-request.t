use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic::Request;

# ============================================================
# Test JIT-compiled Request accessors
# ============================================================

# Compile the JIT accessors
my $cache_dir = "_test_jit_cache_$$";
Hypersonic::Request->compile_accessors(cache_dir => $cache_dir);

# Create a mock request object (array-based, matching slot layout)
sub mock_request {
    my %args = @_;

    # Build hashrefs for nested data
    my $params = $args{params} // {};
    my $query = $args{query} // {};
    my $headers = $args{headers} // {};
    my $cookies = $args{cookies} // {};
    my $form = $args{form} // {};
    my $segments = $args{segments} // [];

    # Create array-based request matching JIT slot layout
    my $req = bless [
        $args{method} // 'GET',                    # SLOT_METHOD = 0
        $args{path} // '/',                        # SLOT_PATH = 1
        $args{body} // '',                         # SLOT_BODY = 2
        $params,                                   # SLOT_PARAMS = 3
        $query,                                    # SLOT_QUERY = 4
        $args{query_string} // '',                 # SLOT_QUERY_STRING = 5
        $headers,                                  # SLOT_HEADERS = 6
        $cookies,                                  # SLOT_COOKIES = 7
        $args{json} // undef,                      # SLOT_JSON = 8
        $form,                                     # SLOT_FORM = 9
        $segments,                                 # SLOT_SEGMENTS = 10
        $args{id} // '',                           # SLOT_ID = 11
    ], 'Hypersonic::Request';

    return $req;
}

subtest 'Simple scalar accessors' => sub {
    my $req = mock_request(
        method => 'POST',
        path => '/api/users',
        body => '{"name":"test"}',
        query_string => 'page=1&limit=10',
        id => '123',
    );

    is($req->method, 'POST', 'method() returns POST');
    is($req->path, '/api/users', 'path() returns path');
    is($req->body, '{"name":"test"}', 'body() returns body');
    is($req->query_string, 'page=1&limit=10', 'query_string() returns query string');
    is($req->id, '123', 'id() returns id');
};

subtest 'Hashref accessors' => sub {
    my $req = mock_request(
        params => { user_id => '42', post_id => '99' },
        query => { page => '1', limit => '10' },
        headers => { content_type => 'application/json', authorization => 'Bearer xyz' },
        cookies => { session => 'abc123' },
        form => { username => 'john' },
    );

    # Test hashref returns
    is(ref($req->params), 'HASH', 'params() returns hashref');
    is(ref($req->query), 'HASH', 'query() returns hashref');
    is(ref($req->headers), 'HASH', 'headers() returns hashref');
    is(ref($req->cookies), 'HASH', 'cookies() returns hashref');
};

subtest 'Keyed param accessor' => sub {
    my $req = mock_request(
        params => { user_id => '42', post_id => '99' },
    );

    is($req->param('user_id'), '42', 'param(key) returns value');
    is($req->param('post_id'), '99', 'param(key) returns other value');
    ok(!defined $req->param('nonexistent'), 'param(missing) returns undef');
};

subtest 'Keyed query_param accessor' => sub {
    my $req = mock_request(
        query => { page => '5', sort => 'name' },
    );

    is($req->query_param('page'), '5', 'query_param(key) returns value');
    is($req->query_param('sort'), 'name', 'query_param(key) returns other value');
    ok(!defined $req->query_param('nonexistent'), 'query_param(missing) returns undef');
};

subtest 'Header accessor with normalization' => sub {
    my $req = mock_request(
        headers => {
            content_type => 'application/json',
            authorization => 'Bearer token',
            x_custom_header => 'custom-value',
        },
    );

    # Test various header name formats (should be normalized)
    is($req->header('content_type'), 'application/json', 'header(lowercase) works');
    is($req->header('Content-Type'), 'application/json', 'header(Title-Case) normalizes');
    is($req->header('CONTENT-TYPE'), 'application/json', 'header(UPPERCASE) normalizes');
    is($req->header('authorization'), 'Bearer token', 'header(auth) works');
    ok(!defined $req->header('nonexistent'), 'header(missing) returns undef');
};

subtest 'Cookie accessor' => sub {
    my $req = mock_request(
        cookies => { session => 'xyz789', user => 'alice' },
    );

    is($req->cookie('session'), 'xyz789', 'cookie(key) returns value');
    is($req->cookie('user'), 'alice', 'cookie(key) returns other value');
    ok(!defined $req->cookie('nonexistent'), 'cookie(missing) returns undef');
};

subtest 'is_json and is_form checks' => sub {
    my $json_req = mock_request(
        headers => { content_type => 'application/json' },
    );
    ok($json_req->is_json, 'is_json() true for application/json');
    ok(!$json_req->is_form, 'is_form() false for application/json');

    my $form_req = mock_request(
        headers => { content_type => 'application/x-www-form-urlencoded' },
    );
    ok(!$form_req->is_json, 'is_json() false for form');
    ok($form_req->is_form, 'is_form() true for form content type');

    my $plain_req = mock_request(
        headers => { content_type => 'text/plain' },
    );
    ok(!$plain_req->is_json, 'is_json() false for text/plain');
    ok(!$plain_req->is_form, 'is_form() false for text/plain');
};

subtest 'Response helper methods' => sub {
    my $req = mock_request();

    my $json = $req->json_response({ ok => 1 });
    is($json->{status}, 200, 'json_response default status 200');
    is($json->{headers}{'Content-Type'}, 'application/json', 'json_response Content-Type');
    like($json->{body}, qr/"ok"/, 'json_response encodes data');

    my $text = $req->text_response('hello');
    is($text->{headers}{'Content-Type'}, 'text/plain', 'text_response Content-Type');
    is($text->{body}, 'hello', 'text_response body');

    my $redirect = $req->redirect('/new-path', 301);
    is($redirect->{status}, 301, 'redirect custom status');
    is($redirect->{headers}{'Location'}, '/new-path', 'redirect Location');

    my $err = $req->not_found('User not found');
    is($err->{status}, 404, 'not_found status 404');
    like($err->{body}, qr/User not found/, 'not_found message');
};

subtest 'Direct slot access (maximum speed)' => sub {
    use Hypersonic::Request qw(SLOT_METHOD SLOT_PATH SLOT_PARAMS);

    my $req = mock_request(
        method => 'DELETE',
        path => '/api/item/5',
        params => { id => '5' },
    );

    # Direct array access - bypasses all method overhead
    is($req->[SLOT_METHOD], 'DELETE', 'Direct SLOT_METHOD access');
    is($req->[SLOT_PATH], '/api/item/5', 'Direct SLOT_PATH access');
    is($req->[SLOT_PARAMS]{id}, '5', 'Direct SLOT_PARAMS hash access');
};

# ============================================================
# Form field accessor tests
# ============================================================

subtest 'Form field accessor (form_param equivalent)' => sub {
    my $req = mock_request(
        form => {
            username => 'john',
            email => 'john@example.com',
            password => 'secret123',
        },
    );

    # form() returns the full hashref
    is(ref($req->form), 'HASH', 'form() returns hashref');
    is($req->form->{username}, 'john', 'form() hash access works');

    # Test form field values
    is($req->form->{email}, 'john@example.com', 'form email field');
    is($req->form->{password}, 'secret123', 'form password field');

    # Test missing field
    ok(!exists $req->form->{nonexistent}, 'form missing field not exists');
};

subtest 'Form with special characters' => sub {
    my $req = mock_request(
        form => {
            'field_with_underscore' => 'value1',
            'field-with-dash' => 'value2',
            'email' => 'user+tag@example.com',
            'message' => 'Hello World! Special: <>&"\'',
        },
    );

    is($req->form->{'field_with_underscore'}, 'value1', 'underscore field name');
    is($req->form->{'field-with-dash'}, 'value2', 'dash field name');
    is($req->form->{'email'}, 'user+tag@example.com', 'email with plus sign');
    like($req->form->{'message'}, qr/<>&"'/, 'message with special chars');
};

subtest 'Empty form' => sub {
    my $req = mock_request(form => {});
    is(ref($req->form), 'HASH', 'empty form returns hashref');
    is(scalar keys %{$req->form}, 0, 'empty form has no keys');
};

# ============================================================
# Segments accessor tests
# ============================================================

subtest 'Segments accessor' => sub {
    my $req = mock_request(
        segments => ['api', 'users', '42', 'posts'],
    );

    my $segs = $req->segments;
    is(ref($segs), 'ARRAY', 'segments() returns arrayref');
    is(scalar @$segs, 4, 'segments has 4 elements');
    is($segs->[0], 'api', 'first segment');
    is($segs->[1], 'users', 'second segment');
    is($segs->[2], '42', 'third segment (numeric)');
    is($segs->[3], 'posts', 'fourth segment');
};

subtest 'Empty segments' => sub {
    my $req = mock_request(segments => []);
    is(ref($req->segments), 'ARRAY', 'empty segments returns arrayref');
    is(scalar @{$req->segments}, 0, 'empty segments has 0 elements');
};

subtest 'Root path segments' => sub {
    my $req = mock_request(
        path => '/',
        segments => [],
    );
    is(scalar @{$req->segments}, 0, 'root path has empty segments');
};

# ============================================================
# JSON accessor tests
# ============================================================

subtest 'JSON accessor' => sub {
    my $req = mock_request(
        json => { name => 'test', count => 42, active => \1 },
    );

    my $json = $req->json;
    is(ref($json), 'HASH', 'json() returns hashref');
    is($json->{name}, 'test', 'json name field');
    is($json->{count}, 42, 'json count field');
};

subtest 'JSON with nested structure' => sub {
    my $req = mock_request(
        json => {
            user => {
                name => 'Alice',
                roles => ['admin', 'editor'],
            },
            meta => {
                version => '1.0',
            },
        },
    );

    my $json = $req->json;
    is($json->{user}{name}, 'Alice', 'nested json user.name');
    is(ref($json->{user}{roles}), 'ARRAY', 'nested array');
    is($json->{user}{roles}[0], 'admin', 'nested array element');
};

subtest 'Empty/null JSON' => sub {
    my $req = mock_request(json => undef);
    ok(!defined $req->json, 'undef json returns undef');

    my $req2 = mock_request(json => {});
    is(ref($req2->json), 'HASH', 'empty json returns hashref');
    is(scalar keys %{$req2->json}, 0, 'empty json has no keys');
};

# ============================================================
# Edge cases
# ============================================================

subtest 'Empty request' => sub {
    my $req = mock_request();

    is($req->method, 'GET', 'default method is GET');
    is($req->path, '/', 'default path is /');
    is($req->body, '', 'default body is empty');
    is($req->query_string, '', 'default query_string is empty');
    is($req->id, '', 'default id is empty');
};

subtest 'Request with binary body' => sub {
    my $binary = "binary\x00data\xFF";
    my $req = mock_request(body => $binary);
    is($req->body, $binary, 'binary body preserved');
    is(length($req->body), length($binary), 'binary body length correct');
};

subtest 'Request with UTF-8 data' => sub {
    my $req = mock_request(
        path => '/api/用户',
        body => '{"name":"日本語"}',
        params => { name => 'Ελληνικά' },
    );

    like($req->path, qr/用户/, 'UTF-8 in path');
    like($req->body, qr/日本語/, 'UTF-8 in body');
    is($req->param('name'), 'Ελληνικά', 'UTF-8 in params');
};

subtest 'Header with various content types' => sub {
    # JSON with charset
    my $req1 = mock_request(
        headers => { content_type => 'application/json; charset=utf-8' },
    );
    # Note: is_json checks for 'application/json' substring
    ok($req1->is_json, 'is_json true for application/json; charset=utf-8');

    # JSON with vendor prefix
    my $req2 = mock_request(
        headers => { content_type => 'application/vnd.api+json' },
    );
    # This might not match depending on implementation
    # Just verify the header is accessible
    like($req2->header('content_type'), qr/json/, 'vendor json content type accessible');
};

subtest 'Multiple response helper variations' => sub {
    my $req = mock_request();

    # json_response with custom status
    my $json = $req->json_response({ created => 1 }, 201);
    is($json->{status}, 201, 'json_response custom status');

    # text_response with custom status
    my $text = $req->text_response('Created', 201);
    is($text->{status}, 201, 'text_response custom status');

    # html_response
    my $html = $req->html_response('<h1>Hello</h1>');
    is($html->{headers}{'Content-Type'}, 'text/html', 'html_response Content-Type');
    is($html->{body}, '<h1>Hello</h1>', 'html_response body');

    # error with default status
    my $err = $req->error('Something wrong');
    is($err->{status}, 500, 'error default status 500');

    # bad_request
    my $bad = $req->bad_request('Invalid data');
    is($bad->{status}, 400, 'bad_request status 400');

    # unauthorized
    my $unauth = $req->unauthorized('No token');
    is($unauth->{status}, 401, 'unauthorized status 401');

    # forbidden
    my $forbidden = $req->forbidden('Access denied');
    is($forbidden->{status}, 403, 'forbidden status 403');
};

subtest 'Slot constants exported' => sub {
    use Hypersonic::Request qw(
        SLOT_METHOD SLOT_PATH SLOT_BODY SLOT_PARAMS
        SLOT_QUERY SLOT_QUERY_STRING SLOT_HEADERS
        SLOT_COOKIES SLOT_JSON SLOT_FORM SLOT_SEGMENTS SLOT_ID
    );

    is(SLOT_METHOD, 0, 'SLOT_METHOD is 0');
    is(SLOT_PATH, 1, 'SLOT_PATH is 1');
    is(SLOT_BODY, 2, 'SLOT_BODY is 2');
    is(SLOT_PARAMS, 3, 'SLOT_PARAMS is 3');
    is(SLOT_QUERY, 4, 'SLOT_QUERY is 4');
    is(SLOT_QUERY_STRING, 5, 'SLOT_QUERY_STRING is 5');
    is(SLOT_HEADERS, 6, 'SLOT_HEADERS is 6');
    is(SLOT_COOKIES, 7, 'SLOT_COOKIES is 7');
    is(SLOT_JSON, 8, 'SLOT_JSON is 8');
    is(SLOT_FORM, 9, 'SLOT_FORM is 9');
    is(SLOT_SEGMENTS, 10, 'SLOT_SEGMENTS is 10');
    is(SLOT_ID, 11, 'SLOT_ID is 11');
};

# Cleanup
END {
    system("rm -rf $cache_dir") if $cache_dir;
}

done_testing();
