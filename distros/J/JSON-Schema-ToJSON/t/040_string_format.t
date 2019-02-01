#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use Test::Most;

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = {
	"type" => "object",
	"properties" => {
		(
			map {
				( "a_$_" => {
					"type"   => "string",
					"format" => $_,
				} )
			} qw/ date-time email hostname ipv4 ipv6 uri uriref /
		),
	},
};

my $json = $ToJSON->json_schema_to_json(
	schema => $schema,
);

cmp_deeply(
	$json,
	{
		'a_date-time' => re( '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$' ),
		'a_email' => re( '^[A-Za-z]+@gmail.com$' ),
		'a_hostname' => re( 'www.[A-Za-z]+.com' ),
		'a_ipv4' => re( '^\d+\.\d+\.\d+\.\d+$' ),
		'a_ipv6' => '2001:0db8:0000:0000:0000:0000:1428:57ab',
		'a_uri' => re( '^https://www.[A-z]+.com$' ),
		'a_uriref' => re( '^https://www.[A-z]+.com$' ),
	},
	'object'
);

done_testing();

# vim:noet:sw=4:ts=4
