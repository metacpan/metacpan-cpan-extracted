#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $json = $ToJSON->json_schema_to_json(
	schema => {
		"type" => "array",
		"items" => { '$ref' => "#/definitions/positiveInteger" },
		"definitions" => {
			"positiveInteger" => {
				"type" => "integer",
				"minimum" => 1,
			}
		}
	}
);

ok( ref( $json ) eq 'ARRAY','ref type of JSON' );
like( $json->[0],qr/^\d+$/,'contains integers' );

eval {
   	$ToJSON->json_schema_to_json(
		schema => {
			"type" => "array",
			"items" => { '$ref' => "#/definitions/doesNotExist" },
			"definitions" => {
				"positiveInteger" => {
					"type" => "integer",
					"minimum" => 1,
				}
			}
		}
	);
};

like(
	$@,
	qr!Could not find.*?#/definitions/doesNotExist!,
	'die on bad $ref',
);

done_testing();

# vim:noet:sw=4:ts=4
