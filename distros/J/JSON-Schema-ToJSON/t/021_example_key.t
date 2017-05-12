#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Cpanel::JSON::XS;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new(
	example_key => 'x-example'
);

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $json = $ToJSON->json_schema_to_json(
	schema_str => '{
		"type" : "object",
		"properties" : {
			"id" : {
				"type" : "string",
				"description" : "ID of the payment.",
				"x-example" : "123ABC"
			}
		}
	}',
);

is( $json->{id},'123ABC','example key used' );

done_testing();

# vim:noet:sw=4:ts=4
