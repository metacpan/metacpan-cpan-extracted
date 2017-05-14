use strict;
use warnings;

use Test::Deep;
use Test::More tests => 7;
use HTTP::Request;
use HTTP::Response;
use HTTP::Lint qw/http_lint/;

sub transaction
{
	my $request = HTTP::Request->parse ($_[0]);
	return $request if $request->method eq 'CONNECT';
	my $response = HTTP::Response->parse ($_[1]);
	$response->request ($request);
	return $response;
}

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
DELETE /trololo\r
Accept: */*\r
\r
REQ
HTTP/1.0 405 Y U NO METHOD\r
\r
RES
	bless ['405 without allowed methods specified',
                   [10, 4, 6]], 'HTTP::Lint::Error'
], 'Bad 405');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
GET /trololo HTTP/1.1\r
Host: Wololo\r
\r
Yololo
REQ
HTTP/1.1 503 Service unavailable\r
Location: http://konsky.kokot/\r
\r
Trololo
RES
	bless (['HTTP/1.1 non-close response without given size',
		[19, 6, 2]], 'HTTP::Lint::Error'),
	bless (['Missing media type',
		[7, 2, 1]], 'HTTP::Lint::Warning'),
	bless (['Retry-After header missing for a 503 response',
		[10, 5, 4]], 'HTTP::Lint::Warning'),
	bless (['GET request with non-empty body',
		[]], 'HTTP::Lint::Error'),
	bless (['Missing Accept header',
		[14, 1]], 'HTTP::Lint::Warning')
], 'Random violations');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
HEAD /wololo HTTP/1.1\r
Accept: text/pain\r
\r
REQ
HTTP/1.1 201 Created\r
Retry-After: 1\r
Content-Type: text/plain\r
Content-Length: 8
\r
Trololo
RES
	bless (['Location missing for a 201 response',
		[10, 2, 2]], 'HTTP::Lint::Error'),
	bless (['Missing Date header',
		[14, 18]], 'HTTP::Lint::Warning'),
	bless (['Action with side effects conducted for a HEAD request',
		[13, 9]], 'HTTP::Lint::Warning'),
	bless (['HEAD response with non-empty body',
		[4, 3]], 'HTTP::Lint::Error'),
	bless (['HTTP/1.1 request without Host header',
		[9]], 'HTTP::Lint::Error')
], 'More random violations');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
POST /trololo HTTP/1.0\r
Host: Wololo\r
Accept: text/plain\r
\r
REQ
HTTP/1.1 204 Wololo\r
\r
RES
	bless (['Missing Date header',
		[14, 18]], 'HTTP::Lint::Warning'),
	bless (['HTTP/1.1 response for a HTTP/1.0 request',
		[3, 1]], 'HTTP::Lint::Warning')
], 'Bad HTTP/1.1');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
POST /trololo HTTP/1.1\r
Host: Wololo\r
Accept: text/plain\r
\r
REQ
HTTP/1.1 200 You need to login\r
Content-Type: text/plain\r
\r
Meow
RES
	bless (['HTTP/1.1 non-close response without given size',
		[19, 6, 2]], 'HTTP::Lint::Error'),
	bless (['Missing Date header',
		[14, 18]], 'HTTP::Lint::Warning')
], 'Bad keepalive');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
POST /trololo\r
Host: Wololo\r
Accept: text/plain\r
\r
REQ
401 You need to login\r
Content-Type: text/plain\r
\r
See, I replied without an authenticate header
RES
	bless (['WWW-Authenticate header missing for a 401 response',
		[14, 47]], 'HTTP::Lint::Error')
], 'Bad 401');

cmp_deeply ([http_lint (transaction (<<REQ, <<RES))], [
DELETE /trololo\r
Accept: */*\r
\r
REQ
HTTP/1.0 405 Y U NO METHOD\r
\r
RES
	bless (['405 without allowed methods specified',
		[10, 4, 6]], 'HTTP::Lint::Error')
], 'Bad 405');
