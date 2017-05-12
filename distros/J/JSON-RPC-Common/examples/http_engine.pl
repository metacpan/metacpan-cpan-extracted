#!/usr/bin/perl

use strict;
use warnings;

use HTTPEx::Declare;

use JSON::RPC::Common::Marshal::HTTP;

interface Standalone => { port => 8000, fork => 1, keepalive => 1 };

my $marshal = JSON::RPC::Common::Marshal::HTTP->new;

run {
	my $c = shift;

	# decode the request into an object
	# this takes the JSON from the body, deserializes, and constructs a call
	eval {
		my $json_rpc_req = $marshal->request_to_call($c->req);

		# fake some sort of return value without actually calling anything
		my $json_rpc_res = $json_rpc_req->return_result({
			time => scalar localtime,
			echo => {
				params => [ $json_rpc_req->params_list ],
				method  => $json_rpc_req->method,
			},
		});

		# to invoke the request as a method of some object:
		# my $json_rpc_res = $json_rpc_req->call( $some_object );

		# and write the result back to the HTTP client

		$marshal->write_result_to_response($json_rpc_res, $c->res);
	};

	if ($@) {
		$c->res->status(500);
		$c->res->body($@);
	}
};

