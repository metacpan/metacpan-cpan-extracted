use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::HTTP;

subtest 'status code constants' => sub {
	is(Continue,           100, 'Continue is 100');
	is(OK,                 200, 'OK is 200');
	is(Created,            201, 'Created is 201');
	is(NoContent,          204, 'NoContent is 204');
	is(MovedPermanently,   301, 'MovedPermanently is 301');
	is(Found,              302, 'Found is 302');
	is(NotModified,        304, 'NotModified is 304');
	is(BadRequest,         400, 'BadRequest is 400');
	is(Unauthorized,       401, 'Unauthorized is 401');
	is(Forbidden,          403, 'Forbidden is 403');
	is(NotFound,           404, 'NotFound is 404');
	is(Conflict,           409, 'Conflict is 409');
	is(UnprocessableEntity, 422, 'UnprocessableEntity is 422');
	is(TooManyRequests,    429, 'TooManyRequests is 429');
	is(InternalServerError, 500, 'InternalServerError is 500');
	is(BadGateway,         502, 'BadGateway is 502');
	is(ServiceUnavailable, 503, 'ServiceUnavailable is 503');
	is(GatewayTimeout,     504, 'GatewayTimeout is 504');
};

subtest 'status code meta' => sub {
	my $meta = StatusCode();
	ok($meta->valid(200), '200 is valid');
	ok($meta->valid(404), '404 is valid');
	ok(!$meta->valid(999), '999 is not valid');
	is($meta->name(200), 'OK', 'name of 200 is OK');
	is($meta->name(404), 'NotFound', 'name of 404 is NotFound');
	is($meta->value('OK'), 200, 'value of OK is 200');
};

subtest 'method constants' => sub {
	is(GET,     'get',     'GET is "get"');
	is(POST,    'post',    'POST is "post"');
	is(PUT,     'put',     'PUT is "put"');
	is(PATCH,   'patch',   'PATCH is "patch"');
	is(DELETE,  'delete',  'DELETE is "delete"');
	is(HEAD,    'head',    'HEAD is "head"');
	is(OPTIONS, 'options', 'OPTIONS is "options"');
};

subtest 'method meta' => sub {
	my $meta = Method();
	is($meta->count, 8, '8 methods');
	ok($meta->valid('get'), 'get is valid');
	ok($meta->valid('post'), 'post is valid');
};

subtest 'helper functions' => sub {
	ok(is_info(100),          '100 is info');
	ok(!is_info(200),         '200 is not info');
	ok(is_success(200),       '200 is success');
	ok(is_success(204),       '204 is success');
	ok(!is_success(301),      '301 is not success');
	ok(is_redirect(301),      '301 is redirect');
	ok(is_redirect(308),      '308 is redirect');
	ok(is_client_error(400),  '400 is client error');
	ok(is_client_error(404),  '404 is client error');
	ok(!is_client_error(500), '500 is not client error');
	ok(is_server_error(500),  '500 is server error');
	ok(is_server_error(503),  '503 is server error');
};

done_testing();
