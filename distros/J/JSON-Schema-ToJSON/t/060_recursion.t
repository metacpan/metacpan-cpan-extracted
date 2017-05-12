#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Cpanel::JSON::XS;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new(
	max_depth => 10,
);

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = {
	"type" => "array",
	"items" => {
		'$ref' => "#/definitions/Property"
	},
	"description" => "List of Property objects",
	"type" => "array",
	"definitions" => {
		"Property" => {
			"type" => "object",
			"properties" => {
				"neighbour" => {
					"type" => "array",
					"items" => {
						'$ref' => "#/definitions/Property"
					},
				},
			},
		},
	},
};

$SIG{ALRM} = sub { die 'Recursion!' };
alarm 5;

my $json = $ToJSON->json_schema_to_json(
	schema => $schema,
);

alarm 0;

pass( 'did not deeply recurse' );

my $validator = JSON::Validator->new;
 
$validator->schema( $schema );
my @errors = $validator->validate( $json );

ok( ! @errors,'round trip' );

done_testing();

# vim:noet:sw=4:ts=4
