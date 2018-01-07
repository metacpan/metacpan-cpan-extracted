#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = {
  '$schema' => "http://json-schema.org/schema#",
  "type" => "object",
  "properties" => {
    "roles" => {
      "type" => "array",
      "minItems" => 1,
      "maxItems" => 4,
      "uniqueItems" => 1,
      "items" => {
        "type" => "string",
        "enum" => [ "admin", "manager", "trainer", "member" ]
      }
    }
  }
};

my $gen    = JSON::Schema::ToJSON->new( max_depth => 10 );
my $json   = $gen->json_schema_to_json( schema    => $schema );

my $validator = JSON::Validator->new;
 
$validator->schema( $schema );
my @errors = $validator->validate( $json );

ok( ! @errors,'round trip' );

done_testing();
