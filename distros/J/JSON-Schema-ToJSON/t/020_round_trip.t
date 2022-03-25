#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Test::Most;

plan skip_all => '$ref resolution currently broken';

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = {
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

	"type" => "object",

	"properties" => {
		"billing_address"  => { '$ref' => "#/definitions/address" },
	}
};

my $json = $ToJSON->json_schema_to_json(
    schema => $schema,
);

my $validator = JSON::Validator->new;
 
$validator->schema( $schema );
my @errors = $validator->validate( $json );

ok( ! @errors,'round trip' );

done_testing();

# vim:noet:sw=4:ts=4
