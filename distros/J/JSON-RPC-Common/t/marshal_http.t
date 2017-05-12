#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use Encode;

use Test::More;

BEGIN {
	plan skip_all => "HTTP::Request required for this test"  unless eval { require HTTP::Request };
	plan skip_all => "HTTP::Response required for this test" unless eval { require HTTP::Response };
	plan 'no_plan';
}

use MIME::Base64 qw(encode_base64);

use JSON::RPC::Common::Marshal::HTTP;

{
	my $m_http = JSON::RPC::Common::Marshal::HTTP->new;

	my %reqs = (
		"get with params" => HTTP::Request->new( GET =>  '/rpc?version=1.1&method=foo&id=4&oink=3&oink=2&bar=elk' ),
		"REST style"      => HTTP::Request->new( GET =>  '/rpc/foo?version=1.1&id=4&oink=3&oink=2&bar=elk' ),
		"b64 encoded get" => HTTP::Request->new( GET =>  '/rpc?version=1.1&method=foo&id=4&params=' . encode_base64('{"oink":[3,2],"bar":"elk"}') ),
		"encoded get"     => HTTP::Request->new( GET =>  '/rpc?version=1.1&method=foo&id=4&params={"oink":[3,2],"bar":"elk"}' ),
		"post"            => HTTP::Request->new( POST => '/rpc', undef, q|{"version":"1.1","method":"foo","id":4,"params":{"oink":[3,2],"bar":"elk"}}| ),
	);

	foreach my $req ( keys %reqs ) {
		my $req_obj = $reqs{$req};

		ok( my $call = $m_http->request_to_call($req_obj), "$req into proc call" );;

		isa_ok( $call, "JSON::RPC::Common::Procedure::Call" );

		is( $call->version, "1.1", "version" );
		is( $call->method, "foo", "method" );
		is( $call->id, 4, "id" );
		is_deeply( $call->params, { oink => [ 3, 2 ], bar => "elk" }, "params" );

		foreach my $opts (
			{},
			{ prefer_get => 0 },
			{ prefer_get => 1, encoded => 0, },
			{ prefer_get => 1, encoded => 1, },
		) {
			ok( my $re_req = $m_http->call_to_request($call, %$opts), "call_to_request" );
			isa_ok( $re_req, "HTTP::Request" );

			ok( my $re_call = $m_http->request_to_call( $re_req ), "round tripped call" );

			my $def_1 = $call->deflate;
			my $def_2 = $re_call->deflate;

			if ( $opts->{prefer_get} ) {
				# GET can't guarantee version, we need to scrub that
				foreach my $hash ( $def_1, $def_2 ) {
					foreach my $key (qw(version jsonrpc)) {
						delete $hash->{$key};
					}
				}
			}

			use Data::Dumper;
			is_deeply( $def_1, $def_2, "round trip call is_deeply first one" )
				or diag Dumper($def_1, $def_2, $re_req, $opts);
		}
	}
}

{
	my $m_http = JSON::RPC::Common::Marshal::HTTP->new;


	my %reqs = (
		"explicit path_info & base" => [
			HTTP::Request->new( GET => '/some/app/rpc/elaborate/method?version=1.1&id=4&oink=3&oink=2&bar=elk' ),
			path_info => "/elaborate/method",
			base_path => "/some/app/rpc",
		],
		"just base" => [
			HTTP::Request->new( GET => '/some/app/rpc/elaborate/method?version=1.1&id=4&oink=3&oink=2&bar=elk' ),
			base_path => "/some/app/rpc",
		],
	);

	foreach my $req ( keys %reqs ) {
		my ( $req_obj, %args ) = @{$reqs{$req}};

		ok( my $call = $m_http->request_to_call($req_obj, %args), "$req into proc call" );

		isa_ok( $call, "JSON::RPC::Common::Procedure::Call" );

		is( $call->version, "1.1", "version" );
		is( $call->method, "elaborate/method", "method" );
		is( $call->id, 4, "id" );
		is_deeply( $call->params, { oink => [ 3, 2 ], bar => "elk" }, "params" );

		foreach my $opts (
			{},
			{ prefer_get => 0 },
			{ prefer_get => 1, encoded => 0, rest_style_methods => 1 },
			{ prefer_get => 1, encoded => 0, rest_style_methods => 0, },
			{ prefer_get => 1, encoded => 1, }, # rest style methods don't apply
		) {
			ok( my $re_req = $m_http->call_to_request($call, %args, %$opts), "$req back through call_to_request (" . ( $opts->{prefer_get} ? ( $opts->{encode} ? "en" : "de" ) . "coded get" : "post" ) . ")" );
			isa_ok( $re_req, "HTTP::Request" );

			if ( $opts->{rest_style_methods} ) {
				like( $re_req->uri->path, qr{rpc/elaborate/method$}, "method is in PATH_INFO" );
			} else {
				unlike( $re_req->uri->path, qr{elaborate}, "method is not in path at all" );

				if ( $opts->{prefer_get} ) {
					is( $re_req->uri->query_param("method"), "elaborate/method", "method is a param" );
				}
			}

			like( $re_req->uri, qr{^/some/app/rpc}, "base path" );

			ok( my $re_call = $m_http->request_to_call( $re_req, %args ), "round tripped call" );

			my $def_1 = $call->deflate;
			my $def_2 = $re_call->deflate;

			if ( $opts->{prefer_get} ) {
				# GET can't guarantee version, we need to scrub that
				foreach my $hash ( $def_1, $def_2 ) {
					foreach my $key (qw(version jsonrpc)) {
						delete $hash->{$key};
					}
				}
			}

			use Data::Dumper;
			is_deeply( $def_1, $def_2, "round trip call is_deeply first one" )
				or diag Dumper($def_1, $def_2, $re_req, $opts);
		}
	}
}

{
	my $m_http = JSON::RPC::Common::Marshal::HTTP->new;

	my $http_res = HTTP::Response->new( 200, "YATTA", undef, Encode::encode( utf8 => '{"jsonrpc":"2.0","result":"שלום","id":3}' ) );

	my $res_obj = $m_http->response_to_result($http_res);

	is( $res_obj->version, "2.0", "version 2.0");
	ok( !$res_obj->has_error, "no error" );
	is( $res_obj->result, "שלום", "result" );
	ok( utf8::is_utf8($res_obj->result), "unicode decoded" );
	is( $res_obj->id, 3, "id" );

	isa_ok( my $re_http_res = $m_http->result_to_response($res_obj), "HTTP::Response" );

	ok( !utf8::is_utf8($re_http_res->content), "body is not unicode (encoded)" );

	is( $re_http_res->content_length, length($re_http_res->content), "content length" );

	ok( my $re_res = $m_http->response_to_result($re_http_res), "round trip result" );

	ok( utf8::is_utf8($re_res->result), "unicode decoded" );

	is_deeply(
		$re_res->deflate,
		$res_obj->deflate,
		"round trip result eq deeply",
	);
}

{
	my $m_http = JSON::RPC::Common::Marshal::HTTP->new;

	my $http_res = HTTP::Response->new( 500, "OH NOES", undef, '{"jsonrpc":"2.0","error":{"message":"bork","code":3,"data":"horses"},"id":5}' );

	my $res_obj = $m_http->response_to_result($http_res);

	is( $res_obj->version, "2.0", "version 2.0");
	ok( !$res_obj->has_result, "no result" );
	is( $res_obj->id, 5, "id" );
	ok( $res_obj->has_error, "has error" );
	my $error = $res_obj->error;
	isa_ok( $error, "JSON::RPC::Common::Procedure::Return::Error" );
	isa_ok( $error, "JSON::RPC::Common::Procedure::Return::Version_2_0::Error" );
	is( $error->code, 3, "error code" );
	is( $error->message, "bork", "error message" );
	is_deeply( $error->data, "horses", "error data" );

	isa_ok( my $re_http_res = $m_http->result_to_response($res_obj), "HTTP::Response" );

	ok( my $re_res = $m_http->response_to_result($re_http_res), "round trip result" );

	is_deeply(
		$re_res->deflate,
		$res_obj->deflate,
		"round trip result eq deeply",
	);
}

{
	my $m_http = JSON::RPC::Common::Marshal::HTTP->new;

	my $http_res = HTTP::Response->new( 500, "OH NOES", undef, '{}' );

	my $res_obj = $m_http->response_to_result($http_res);

	ok( !$res_obj->has_result, "no result" );
	ok( !$res_obj->has_id, "no id" );
	ok( $res_obj->has_error, "has error" );
	my $error = $res_obj->error;
	isa_ok( $error, "JSON::RPC::Common::Procedure::Return::Error" );
	is( $error->message, "OH NOES", "error message" );
	is_deeply( $error->data, { response => $http_res }, "error data" );
}

SKIP: {
	plan skip "CGI::Expand is required", 2 unless eval { require CGI::Expand };

	my $m_http = JSON::RPC::Common::Marshal::HTTP->new( expand => 1 );

	my $req = HTTP::Request->new( GET => '/rpc?version=1.1&method=foo&id=4&oink.1=3&oink.0=2&bar.foo=elk' );

	my $call = $m_http->request_to_call( $req );

	isa_ok( $call, "JSON::RPC::Common::Procedure::Call" );

	# note "oink" params are reversed
	is_deeply( $call->params, { oink => [ 2, 3 ], bar => { foo => "elk" } }, "expanded params" );
}
