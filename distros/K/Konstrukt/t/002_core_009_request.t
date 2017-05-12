# check core module: request

use strict;
use warnings;

use Test::More tests => 9;

#=== Dependencies
#none

#Request
use Konstrukt::Request;

my $r = Konstrukt::Request->new(
	uri     => '/foo',
	method  => 'GET',
	headers => {
		Accept => 'text/html'
	}
);

#header
is($r->header('Accept'), "text/html", "header: get");
is($r->header('accept'), "text/html", "header: get");
is($r->header('aCCept', "text/plain"), "text/plain", "header: set");
$r->header('content_type', "text/html");
is($r->header('Content-Type'), "text/html", "header: set");

#headers
is_deeply($r->headers, { Accept => "text/plain", "Content-Type" => "text/html" }, "headers");

#method
is($r->method(), "GET", "method: get");
is($r->method("POST"), "POST", "method: set");

#uri
is($r->uri(), "/foo", "uri: get");
is($r->uri("/bar"), "/bar", "uri: set");
