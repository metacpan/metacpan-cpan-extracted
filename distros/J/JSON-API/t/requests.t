use strict;
use Test::Fake::HTTPD;
use Test::More;
use JSON::API;

sub call_api
{
	my ($api, $METHOD, $path, $data, $expected, $expected_code, $message) = @_;
	if ($METHOD eq "GET") {
		my $scalar = $api->get($path, $data);
		is_deeply($scalar, $expected, "Scalar context for $message") or diag explain $scalar;
		my ($code, $response) = $api->get($path, $data);
		is($code, $expected_code, "List context HTTP Code for $message should return $expected_code");
		is_deeply($response, $expected, "List context Content for $message");
	} elsif ($METHOD eq "PUT") {
		my $scalar = $api->put($path, $data);
		is_deeply($scalar, $expected, "Scalar context for $message");
		my ($code, $response) = $api->put($path, $data);
		is($code, $expected_code, "List context HTTP Code for $message should return $expected_code");
		is_deeply($response, $expected, "List context response for $message");
	} elsif ($METHOD eq "POST") {
		my $scalar = $api->post($path, $data);
		is_deeply($scalar, $expected, "Scalar context for $message");
		my ($code, $response) = $api->post($path, $data);
		is($code, $expected_code, "List context HTTP Code for $message should return $expected_code");
		is_deeply($response, $expected, "List context response for $message");
	} elsif ($METHOD eq "DELETE") {
		my $scalar = $api->del($path);
		is_deeply($scalar, $expected, "Scalar context for $message");
		my ($code, $response) = $api->del($path);
		is($code, $expected_code, "List context HTTP Code: $message should return $expected_code");
		is_deeply($response, $expected, "List context response for $message");
	} else {
		fail("Invalid METHOD provided. Must be one of GET PUT POST DELETE");
	}
}

my $httpd = run_http_server {
	my $request = shift;

	my $uri = $request->uri;
	my $path = $uri->as_string;

	return do {
		if ($path eq '/get_valid_json') { # {{{
			[
				200,
				['Content-Type' => 'application/json'],
				[ '{"name":"foo","value":"bar"}'],
			]
		} # }}}
		elsif ($path eq '/get_valid_json?name=foo&value=abc%21%40%23%24%25%5E%26%3D%3F%2F') { # {{{
			[
				200,
				['Content-Type' => 'application/json'],
				[ '{"success":"query params passed + encoded"}' ],
			]
		} # }}}
		elsif ($path eq '/get_invalid_json') { # {{{
			[
				200,
				['Content-Type' => 'application/json'],
				[ 'asdf' ],
			]
		} # }}}
		elsif ($path =~ m/^\/(put|post)_(in)?valid_json$/) { # {{{
			[
				200,
				[ 'Content-Type' => 'application/json' ],
				[ '{"code":"success"}' ]
			]
		} # }}}
		elsif ($path eq "/del_valid_json") { # {{{
			[
				200,
				[ 'Content-Type' => 'application/json' ],
				[ '' ]
			]
		} # }}}
		elsif ($path eq '/auth-test') { # {{{
			if (!$request->header('Authorization')) {
				[
					401,
					[
						'Content-Type' => 'application/json',
						'WWW-Authenticate' => 'Basic realm="Test"',
					],
					[ '{"error":"authentication required"}' ],
				]
			}
			elsif ($request->header('Authorization') eq 'Basic dGVzdHVzZXI6dGVzdHBhc3M=') {
				[
					200,
					[ 'Content-Type' => 'application/json' ],
					[ '{"code":"authentication successful"}' ],
				],
			} else {
				[
					403,
					[ 'Content-Type' => 'application/json' ],
					[ '{"error":"authentication failed"}' ],
				],
			}
		} #}}}
		else { # 404 catchall # {{{
			[
				404,
				[ 'Content-Type' => 'application/json' ],
				[ '{"error":"My Custom Page Not Found Message"}' ]
			]
		} # }}}
	};
};

my $api = JSON::API->new($httpd->endpoint, debug => 0);

isa_ok($api, 'JSON::API', "JSON::API obj creation succssful");

call_api($api, "GET", '/get_valid_json', undef,
	{name => 'foo', value => 'bar'}, 200,
	"get('/get_valid_json') returns hashref decoded from json");

call_api($api, "GET", '/get_valid_json', { name => 'foo', value => 'abc!@#$%^&=?/' },
	{success => "query params passed + encoded"}, 200,
	"get('/get_valid_json') with query params object passes + encodes params");

call_api($api, "POST", '/get_invalid_json', undef,
	{}, 200,
	"post('/get_invalid_json') returns {}");

call_api($api, "PUT",'/put_valid_json', {name => 'foo', value => 'bar'},
	{ code => 'success' }, 200,
	"put('/put_valid_json') returns with decoded content");

call_api($api, "POST",  '/post_valid_json', {name => 'foo', value => 'bar'},
	{ code => 'success' }, 200,
	"post('/post_valid_json') returns with decoded content");

call_api($api, "DELETE", '/del_valid_json', undef,
	{}, 200,
	"del('/del_valid_json') returns without content");

call_api($api, "PUT", '/put_invalid_json', '',
	{}, 500,
	'/put_invalid_json bails before request');

call_api($api, "GET", '/get_404', undef,
	{ error => 'My Custom Page Not Found Message'}, 404,
	'get(/get_404) returns page not found');

is_deeply($api->errstr, '{"error":"My Custom Page Not Found Message"}', "get('/get_404') returned an errrstr");

call_api($api, "GET", '/auth-test', undef,
	{ error => 'authentication required'}, 401,
	'get(/auth-test) with no creds should get auth required failure');

$api = JSON::API->new($httpd->endpoint, debug => 0,
	user => 'testuser', pass => 'testbadpass', realm => 'Test');

call_api($api, "GET", '/auth-test', undef,
	{ error => 'authentication failed'}, 403,
	'get(/auth-test) with bad creds should get authentication failed error');

$api = JSON::API->new($httpd->endpoint, debug => 0,
	user => 'testuser', pass => 'testpass', realm => 'Test');

call_api($api, "GET", '/auth-test', undef,
	{ code => 'authentication successful'}, 200,
	'get(/auth-test) with good creds should succeed');

done_testing;
