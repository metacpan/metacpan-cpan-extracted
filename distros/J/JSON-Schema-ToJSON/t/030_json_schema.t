#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Cpanel::JSON::XS;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

# this is a JSON Schema that uses at least one of every possible
# property for each type where that is valid, see the following:
# http://json-schema.org/latest/json-schema-validation.html
my $schema = decode_json( do { local $/ = undef; <DATA> } );

my $json   = $ToJSON->json_schema_to_json(
	schema => $schema,
);

cmp_deeply(
	$json,
	superhashof({
		"a_simple_integer"        => re( '^\d+$' ),
		"a_multiple_of_3"         => 3,
		"a_maximum_of_2"          => re( '^[12]$' ),
		"a_minimum_of_700"        => re( '^\d+$' ),
		"an_exclusive_max"        => 1,
		"an_exclusive_min"        => 2,
		"an_exclusive_max_min"    => 2,
		"a_simple_string"         => re( '^.+$' ),
		"a_regex_string"          => re( '^A{1,20}$' ),
		"a_min_length_string"     => re( '^.{50,}$' ),
		"a_max_length_string"     => re( '^.{1,5}$' ),
		"a_min_max_length_string" => re( '^.{12,15}$' ),
		"an_object"               => superhashof({
			address => ignore(),
		}),
		"an_object_max_properties"=> subhashof({
			id    => ignore(),
			name  => ignore(),
			place => ignore(),
		}),
	}),
	'all possible validation keywords covered'
);

ok( $json->{a_maximum_of_2} <= 2,'maximum' );
ok( $json->{a_minimum_of_700} >= 700,'minimum' );

cmp_deeply( $json->{an_array},subbagof( 1 .. 5 ),'an_array' );
cmp_deeply( $json->{an_array_min_items},subbagof( 1 .. 6 ),'an_array' );
cmp_deeply( $json->{an_array_max_items},subbagof( 1 .. 10 ),'an_array' );
cmp_deeply( $json->{an_array_min_max_items},subbagof( 1 .. 10 ),'an_array' );

ok(
	! defined $json->{"a_multiple_type"}
		|| $json->{"a_multiple_type"} =~ /^.+$/,
	"a_multiple_type"
);

my $validator = JSON::Validator->new;
 
$validator->schema( $schema );
my @errors = $validator->validate( $json );

ok( ! @errors,'round trip' );

diag @errors if @errors;

done_testing();

# vim:noet:sw=4:ts=4

__DATA__
{
	"type" : "object",
	"properties" : {
		"a_simple_integer" : {
			"type" : "integer"
		},
		"a_multiple_of_3" : {
			"type" : "integer",
			"multipleOf" : 3
		},
		"a_maximum_of_2" : {
			"type" : "integer",
			"maximum" : 2
		},
		"a_minimum_of_700" : {
			"type" : "integer",
			"minimum" : 700
		},
		"an_exclusive_max" : {
			"type" : "integer",
			"minimum" : 1,
			"maximum" : 2,
			"exclusiveMaximum" : true
		},
		"an_exclusive_min" : {
			"type" : "integer",
			"minimum" : 1,
			"maximum" : 2,
			"exclusiveMinimum" : true
		},
		"an_exclusive_max_min" : {
			"type" : "integer",
			"minimum" : 1,
			"maximum" : 3,
			"exclusiveMinimum" : true,
			"exclusiveMaximum" : true
		},
		"a_simple_string" : {
			"type" : "string"
		},
		"a_max_length_string" : {
			"type" : "string",
			"maxLength" : 5
		},
		"a_min_length_string" : {
			"type" : "string",
			"minLength" : 50
		},
		"a_min_max_length_string" : {
			"type" : "string",
			"minLength" : 12,
			"maxLength" : 15
		},
		"a_regex_string" : {
			"type" : "string",
			"pattern" : "A{1,20}"
		},
		"an_array" : {
			"type" : "array"
		},
		"an_array_min_items" : {
			"type" : "array",
			"minItems" : 5
		},
		"an_array_max_items" : {
			"type" : "array",
			"maxItems" : 10
		},
		"an_array_min_max_items" : {
			"type" : "array",
			"minItems" : 8,
			"maxItems" : 10
		},
		"an_object" : {
			"type" : "object",
			"minProperties" : 2,
			"maxProperties" : 2,
			"required" : [ "address" ],
			"properties" : {
				"id" : {
					"type" : "integer"
				},
				"name" : {
					"type" : "string"
				},
				"address" : {
					"type" : "array",
					"items" : [
						{
							"type" : "string"
						},
						{
							"type" : "string",
							"enum" : [ "Street", "Avenue", "Boulevard" ]
						},
						{
							"type" : "string",
							"enum" : [ "NW", "NE", "SW", "SE" ]
						}
					]
				}
			}
		},
		"an_object_max_properties" : {
			"type" : "object",
			"maxProperties" : 1,
			"properties" : {
				"id" : {
					"type" : "integer"
				},
				"name" : {
					"type" : "string"
				},
				"place" : {
					"type" : "string"
				}
			}
		},
		"a_multiple_type" : {
			"type" : [ "string","number","null" ]
		}
	}
}
