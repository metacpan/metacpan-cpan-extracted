#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

isa_ok(
	$ToJSON->json_schema_to_json(
		schema_str => '{ "type" : "boolean" }',
	),
	'JSON::PP::Boolean',
	'boolean',
);

my $int = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "integer"
	}'
);

ok( $int >= 1 && $int <= 1000,'integer (simple)' );

$int = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "integer",
		"multipleOf": 7
	}'
);

ok( $int == 7,'integer (multipleOf)' );

$int = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "integer",
		"minimum": 25,
		"maximum": 75,
		"exclusiveMinimum": true,
		"exclusiveMaximum": true
	}'
);

ok( $int > 25 && $int < 75,'integer (min/max)' );

# nonsensical range + multipleOf means we can't possibly have
# an integer that fits the requirements
$int = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "integer",
		"minimum": 1,
		"maximum": 4,
		"multipleOf": 4,
		"exclusiveMinimum": true,
		"exclusiveMaximum": true
	}'
);

ok( ! defined( $int ),'integer (min/max + multipleOf nonsensical)' );

my $str = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "string",
		"minLength": 10,
		"maxLength": 40
	}'
);

ok( length( $str ) >= 10 && length( $str ) <= 40,'string (min/max)' );

$str = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "string",
		"pattern": "[A-z]{3}[1-4]{7}hello[1-3]{2}"
	}'
);

like( $str,qr/^[A-z]{3}[1-4]{7}hello[1-3]{2}$/,'string (pattern)' );

$str = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type": "string",
		"enum": [ "foo","bar","baz" ]
	}'
);

like( $str,qr/^(foo|bar|baz)$/,'string (enum)' );

done_testing();

# vim:noet:sw=4:ts=4
