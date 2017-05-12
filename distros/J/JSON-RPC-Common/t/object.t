#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use JSON::RPC::Common::Procedure::Call;

{
	package Foo;
	use Moose;

	sub hello {
		my ( $self, %args ) = @_;
		return "hello " . $args{greet};
	}
}

{
	my $call = JSON::RPC::Common::Procedure::Call->new(
		method => "hello",
		params  => { greet => "world" },
	);

	isa_ok( $call, "JSON::RPC::Common::Procedure::Call" );

	can_ok( $call, "call" );

	my $res = $call->call( Foo->new );

	isa_ok( $res, "JSON::RPC::Common::Procedure::Return" );

	ok( $res->has_result, "has result" );
	is( $res->result, "hello world", "result" );

	ok( !$res->has_error, "no error" );
}

{
	my $call = JSON::RPC::Common::Procedure::Call->new(
		method => "does_not_exist",
		params => { },
	);

	my $res = $call->call( Foo->new );

	isa_ok( $res, "JSON::RPC::Common::Procedure::Return" );

	ok( !$res->has_result, "no result" );
	ok( $res->has_error, "has error" );

	isa_ok( $res->error, "JSON::RPC::Common::Procedure::Return::Error" );

	like( $res->error->message, qr/does_not_exist/, "error talks about non existent method" );
}
