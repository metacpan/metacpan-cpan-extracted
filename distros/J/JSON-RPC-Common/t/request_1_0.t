#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use JSON::RPC::Common::Procedure::Call;

{
	my $req_data = {
		method  => "hello",
		id      => "foo",
		params  => [ 1 .. 3 ],
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_0" );

	is_deeply( $req_obj->deflate, $req_data, "round trip through deflate" );

	is( $req_obj->version, "1.0", "version" );

	ok( $req_obj->has_id, "has_id" );
	is( $req_obj->id, "foo", "id value" );

	ok( !$req_obj->is_notification, "not a notification" );

	ok( !$req_obj->is_service, "not a service req" );

	is_deeply( $req_obj->params, [ 1 .. 3 ], "params" );
	is_deeply( [ $req_obj->params_list ], [ 1 .. 3 ], "params_list" );

	my $res = $req_obj->return_result("moose");

	isa_ok( $res, "JSON::RPC::Common::Procedure::Return" );
	isa_ok( $res, "JSON::RPC::Common::Procedure::Return::Version_1_0" );

	is_deeply( $res->deflate, { result => "moose", error => undef, id => "foo" }, "deflated" );

	my $res_passthrough = JSON::RPC::Common::Procedure::Return->inflate($res->deflate);

	isa_ok( $res_passthrough, "JSON::RPC::Common::Procedure::Return", "reinflate result" );
	ok( !$res_passthrough->has_error, "no error" );
	is( $res->id, "foo", "ID" );
	is( $res->result, "moose", "result" );
}

{
	my $req_data = {
		method  => "hello",
		id      => undef,
		params  => [ 1 .. 3 ],
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_0" );

	is( $req_obj->version, "1.0", "version" );

	ok( $req_obj->has_id, "has_id" );

	ok( $req_obj->is_notification, "not a notification" );
}
