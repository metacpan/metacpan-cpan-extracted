#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = {
	"type" => "object",
	"properties" => {
		"some_value_any_of" => {
			"anyOf" => [
				{ "type" => "string", "maxLength" => 5 },
				{ "type" => "number", "minimum" => 0 }
			]
		}
	}
};

my $json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

cmp_deeply(
	$json,
	{ some_value_any_of => re( '^(.{1,5}|\d+(\.\d+)?)$' ) },
	'anyOf'
);

_validate_json_against_schema( $json,$schema );

# https://spacetelescope.github.io/understanding-json-schema/reference/combining.html
$schema = {
    "definitions" => {
        "address" => {
            "type"       => "object",
            "properties" => {
                "street_address" => { "type" => "string" },
                "city"           => { "type" => "string" },
                "state"          => { "type" => "string" }
            },
            "required" => [ "street_address", "city", "state" ]
        }
    },

    "allOf" => [
        { '$ref'       => "#/definitions/address" },
        { "properties" => { "type" => { "enum" => [ "residential", "business" ] } } }
    ]
};

$json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

cmp_deeply(
	$json,
	{
		street_address => ignore(),
		city           => ignore(),
		state          => ignore(),
		type           => re( '^(residential|business)$' ),
	},
	'allOf',
);

_validate_json_against_schema( $json,$schema );

# we don't round trip oneOf and not because of current limitations
# in the implementation (see CAVEATS section of perldoc and comments
# in the code referencing these)
$schema = {
	"oneOf" => [
		{ "type" => "number", "multipleOf" => 5 },
		{ "type" => "number", "multipleOf" => 3 }
	]
};

$json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

is( $json,5,'oneOf' );

# this is equivalent to the above
$schema = {
	"type"  => "number",
	"oneOf" => [
		{ "multipleOf" => 5 },
		{ "multipleOf" => 3 }
	]
};

$json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

is( $json,5,'oneOf' );

$schema = {
	"type" => "integer",
	"not"  => { "type" => "integer" },
};

$json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

unlike( $json,qr/^\d+$/,'not (type)' );

done_testing();

sub _validate_json_against_schema {
	my ( $json,$schema ) = @_;

	my $validator = JSON::Validator->new;

	$validator->schema( $schema );
	my @errors = $validator->validate( $json );

	ok( ! @errors,'round trip' );
}

# vim:noet:sw=4:ts=4
