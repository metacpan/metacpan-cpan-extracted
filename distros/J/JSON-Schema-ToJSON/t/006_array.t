#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $json = $ToJSON->json_schema_to_json(
	schema => { type => "array", items => { type => "number" } },
);

ok( ref( $json ) eq 'ARRAY','array (simple)' );
ok( scalar( @{ $json } ) >= 0 && scalar( @{ $json } ) <= 5,' ... length' );

$json = $ToJSON->json_schema_to_json(
	schema => {
		type  => "array",
		items => [
			{ type => "number" },
			{ type => "string" },
			{ type => "string", enum => [ "Street", "Avenue", "Boulevard" ] },
			{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
		]
	},
);

cmp_deeply(
	$json,
	[
		re( '^\d+' ),
		re( '.+' ),
		re( '^(Street|Avenue|Boulevard)$' ),
		re( '^(NW|NE|SW|SE)$' ),
	],
	'array (items)'
);

$json = $ToJSON->json_schema_to_json(
	schema => {
		type => "array",
		minItems => 3,
		maxItems => 7,
		items => {
			type => "integer",
			minimum => 3,
			maximum => 7,
		}
	},
);

ok( scalar( @{ $json } ) >= 3 && scalar( @{ $json } ) <= 7,'array (min/max)' );

$json = $ToJSON->json_schema_to_json(
	schema => {
		type => "array",
		uniqueItems => 1,
		minItems => 4,
		maxItems => 4,
		items => {
			type => "integer",
			minimum => 3,
			maximum => 6,
		}
	},
);

cmp_deeply(
	[ sort( @{ $json } ) ],
	[ 3,4,5,6 ],
	'array (uniqueItems, simple)'
);

$json = $ToJSON->json_schema_to_json(
	schema => {
		type  => "array",
		uniqueItems => 1,
		items => [
			{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
			{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
			{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
			{ type => "string", enum => [ "NW", "NE", "SW", "SE" ] },
		]
	},
);

cmp_deeply(
	[ sort( @{ $json } ) ],
	[ qw/ NE NW SE SW / ],
	'array (uniqueItems, complex)',
);

done_testing();

# vim:noet:sw=4:ts=4
