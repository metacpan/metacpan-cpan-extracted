#!/bin/env perl

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

use Kafka::Connection;

use Confluent::SchemaRegistry;

use Test::More qw( no_plan );
#use Test::More tests => 32;

BEGIN { use_ok('Kafka::Producer::Avro', qq/Using/); }

sub _nvl_str {
	return defined $_[0] ? $_[0] : ''; 
}

my $class = 'Kafka::Producer::Avro';

my $kc = new_ok('Kafka::Connection' => [ 'host','localhost' ]);
isa_ok($kc, 'Kafka::Connection');
my $sr = new_ok('Confluent::SchemaRegistry' => []);
isa_ok($sr, 'Confluent::SchemaRegistry');

my $cap = new_ok($class => [ 'Connection',$kc , 'SchemaRegistry',$sr ], qq/Valid REST client config/);
isa_ok($cap, $class);

my $topic = 'test-elasticsearch-sink';
my $partition = 0;
my $messages = [ 
	{ 'f1' => 'foo ' . localtime }, 
	{ 'f1' => 'bar ' . localtime } 
];
my $keys = [
	1,
	2
];
my $compression_codec = undef;
my $key_schema = <<KEY_SCHEMA;
{
	"type": "long",
	"name": "_id"
}
KEY_SCHEMA
my $value_schema = <<VALUE_SCHEMA;
{
	"type": "record",
	"name": "myrecord",
	"fields": [
		{
			"name": "f1",
			"type": "string"
		}
	]
}
VALUE_SCHEMA
my $value_schema_not_compliant = <<VALUE_SCHEMA;
{
	"type": "string",
	"name": "myrecord"
}
VALUE_SCHEMA
my $value_schema_bad = <<VALUE_SCHEMA;
{
	"typ": "string",
	"name": "myrecord"
}
VALUE_SCHEMA
my $unexpected_param = 0;
my $res;

# Clear Schema Registry subjects used for testing
$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'key');
$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'value');

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	value_schema=>$value_schema_bad
);
ok(!defined $res, 'No schema in registry and bad schema supplied: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	value_schema=>$value_schema, 
	unexpected_param=>$unexpected_param
);
isa_ok($res, 'HASH', 'Message(s) sent with new value schema: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema
);
isa_ok($res, 'HASH', 'Message(s) sent by retreiving schema from registry: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	value_schema=>$value_schema_not_compliant
);
ok(!defined $res, 'Incompatible schema: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	value_schema=>$value_schema_bad
);
ok(!defined $res, 'Invalid schema: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic.'BAD', 
	partition=>$partition, 
	messages=>$messages, 
	keys=>$keys, 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	#value_schema=>$value_schema_bad
);
ok(!defined $res, 'No schema in registry: ' . _nvl_str($cap->_get_error()));

$res = $cap->send(
	topic=>$topic, 
	partition=>$partition, 
	messages=>$messages->[0], 
	keys=>$keys->[0], 
	compressione_codec=>$compression_codec, 
	key_schema=>$key_schema, 
	value_schema=>$value_schema
);
isa_ok($res, 'HASH', 'Single message sent');


$kc->close();
