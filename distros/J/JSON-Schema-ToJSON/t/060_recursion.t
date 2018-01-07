#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Cpanel::JSON::XS;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new(
	max_depth => 1,
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

eval {
	my $json = $ToJSON->json_schema_to_json(
		schema => $schema,
	);
};

like( $@,qr/Seems like you have a circular reference/,'die on recursion' );

done_testing();

# vim:noet:sw=4:ts=4
