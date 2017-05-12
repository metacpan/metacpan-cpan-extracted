#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $json = $ToJSON->json_schema_to_json(
	schema => {
		"type" => "object",
		"required" => [ "id","name","address" ],
		"properties" => {
			"id" => {
				"type" => "integer",
			},
			"name" => {
				"type" => "string",
			},
			"address" => {
				"type" => "array",
				items => [
					{ type => "string" },
					{ type => "string", enum => [ "Street", "Avenue", "Boulevard" ] },
					{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
				],
			}
		},
	},
);

cmp_deeply(
	$json,
	{
		'id'      => re( '^\d+$' ),
		'name'    => re( '.+' ),
		'address' => [
			re( '.+' ),
			re( '^(Street|Avenue|Boulevard)$' ),
			re( '^(NW|NE|SW|SE)$' ),
		],
	},
	'object'
);

done_testing();

# vim:noet:sw=4:ts=4
