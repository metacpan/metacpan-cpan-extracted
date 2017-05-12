#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use JSON::RPC::Common::Procedure::Call;

{
	my $req_data = {
		jsonrpc => "2.0",
		method  => "hello",
		id      => "foo",
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	is_deeply( $req_obj->deflate, $req_data, "round trip through deflate" );

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_2_0" );

	is( $req_obj->version, "2.0", "version" );

	ok( $req_obj->has_id, "has_id" );
	is( $req_obj->id, "foo", "id value" );

	ok( !$req_obj->is_notification, "not a notification" );

	ok( !$req_obj->is_service, "not a service req" );

	is_deeply( $req_obj->params, { foo => "bar" }, "params" );

	is_deeply( [ $req_obj->params_list ], [ qw(foo bar) ], "params_list" );

	my $res_hash = $req_obj->return_result({ foo => "bar" });

	isa_ok( $res_hash, "JSON::RPC::Common::Procedure::Return" );
	isa_ok( $res_hash, "JSON::RPC::Common::Procedure::Return::Version_2_0" );

	is_deeply( $res_hash->deflate, { result => { foo => "bar" }, id => "foo", jsonrpc => "2.0" }, "hash result" );

	is_deeply( $req_obj->return_result( 1 .. 3 )->deflate, { result => [ 1 .. 3 ], id => "foo", jsonrpc => "2.0" }, "list result" );
}

{
	my $req_data = {
		jsonrpc => "2.0",
		method  => "hello",
		id      => undef,
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_2_0" );

	is( $req_obj->version, "2.0", "version" );

	ok( $req_obj->has_id, "has_id" );

	ok( !$req_obj->is_notification, "not a notification" );
}

{
	my $req_data = {
		jsonrpc => "2.0",
		method  => "hello",
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_2_0" );

	is( $req_obj->version, "2.0", "version" );

	ok( !$req_obj->has_id, "not has_id" );

	ok( $req_obj->is_notification, "no id means notification" );
}

{
	my $req_data = {
		jsonrpc => "2.0",
		method  => "hello",
		id      => "foo",
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Message->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_2_0" );
}
{
	my $req_data = {
		jsonrpc => "2.0",
		id      => "foo",
		result  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Message->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Return" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Return::Version_2_0" );
}
