#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use JSON::RPC::Common::Procedure::Call;

{
	my $req_data = {
		version => "1.1",
		method  => "hello",
		id      => "foo",
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_1" );

	is_deeply( $req_obj->deflate, $req_data, "round trip through deflate" );

	is( $req_obj->version, "1.1", "version" );

	ok( $req_obj->has_id, "has_id" );
	is( $req_obj->id, "foo", "id value" );

	ok( !$req_obj->is_notification, "not a notification" );

	ok( !$req_obj->is_service, "not a service req" );

	my $res = $req_obj->return_result("moose");

	isa_ok( $res, "JSON::RPC::Common::Procedure::Return" );
	isa_ok( $res, "JSON::RPC::Common::Procedure::Return::Version_1_1" );

	is_deeply( $res->deflate, { version => "1.1", result => "moose", id => "foo" }, "deflated" );
}

{
	my $req_data = {
		version => "1.1",
		method  => "hello",
		id      => undef,
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_1" );

	is( $req_obj->version, "1.1", "version" );

	ok( $req_obj->has_id, "has_id" );

	ok( !$req_obj->is_notification, "not a notification" );
}

{
	my $req_data = {
		version => "1.1",
		method  => "hello",
		params  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_1" );

	is( $req_obj->version, "1.1", "version" );

	ok( !$req_obj->has_id, "not has_id" );

	ok( !$req_obj->is_notification, "no id is still not a notification" );
}

{
	my $req_data = {
		version => "1.1",
		method  => "hello",
		kwparams  => { foo => "bar" },
	};

	my $req_obj = JSON::RPC::Common::Procedure::Call->inflate($req_data);

	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call" );
	isa_ok( $req_obj, "JSON::RPC::Common::Procedure::Call::Version_1_1" );

	is_deeply( $req_obj->deflate, $req_data, "round trip through deflate" );

	is( $req_obj->version, "1.1", "version" );

	ok( $req_obj->alt_spec, "alt 1.1 detected" );
}
