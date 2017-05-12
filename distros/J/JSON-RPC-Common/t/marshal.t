#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Test::Exception;

use JSON;

use JSON::RPC::Common::Marshal::Text;

{
	my $m_json = JSON::RPC::Common::Marshal::Text->new;

	isa_ok( $m_json, "JSON::RPC::Common::Marshal::Text" );

	my $call = $m_json->json_to_message(<<JSON);
{	"jsonrpc": "2.0"
,	"method":  "oink"
,	"params":  { "foo": 3 }
,	"id":      "dancing"
}
JSON

	ok( $call, "JSON text parsed into Procedure Call" );
	isa_ok( $call, "JSON::RPC::Common::Procedure::Call" );

	is( $call->version, "2.0", "version" );
	is( $call->id, "dancing", "id" );

	my $res = $call->return_result("bah");

	my $text = $m_json->message_to_json($res);

	is_deeply(
		from_json($text),
		{
			jsonrpc => "2.0",
			id      => "dancing",
			result  => "bah",
		},
		"result encoding",
	);

	ok( $m_json->json_to_call('{"jsonrpc":"2.0","params":{"foo":3},"method":"hello"}'), "notification (2.0)" );

	my $no_ver = $m_json->json_to_call('{"id":"moo","params":[],"method":"hello"}');
	ok( $no_ver, "missing version parsed" );
	is( $no_ver->version, "1.0", "version 1.0" );

	my %required = (
		method => '{"jsonrpc":"2.0","params":{},"id":3}', # missing method
		params => '{"method":"hello","id":3}', # missing params
		id => '{"params":[],"method":"hello"}', # missing id (version 1.0)
	);

	foreach my $req ( keys %required ) {
		throws_ok {
			$m_json->json_to_call($required{$req});
		} qr/\Q$req\E.*required/, "required param $req";
	}

	dies_ok { $m_json->json_to_call("adtjhat3!!!!") } "JSON parse error";
}


