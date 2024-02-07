#!/bin/env perl

use strict;
use warnings;

#use Test::More qw( no_plan );
use Test::More tests => 23;

BEGIN { use_ok('Kafka'); }
BEGIN { use_ok('Kafka::Connection'); }
BEGIN { use_ok('Confluent::SchemaRegistry'); }
BEGIN { use_ok('Kafka::Producer::Avro'); }
BEGIN { use_ok('Time::HiRes'); }

sub _nvl_str {
	return defined $_[0] ? $_[0] : ''; 
}

my $class = 'Kafka::Producer::Avro';

my $kafka_host = $ENV{KAFKA_HOST} || 'localhost';
my $kafka_port = $ENV{KAFKA_PORT} || '9092';
my $kc = new_ok('Kafka::Connection' => [ 'host',$kafka_host, 'port',$kafka_port, 'timeout',600 ]); # set long timeout to handle very slow connections!
isa_ok($kc, 'Kafka::Connection');

SKIP: {
	my $kafka_connection_metadata;
	eval { $kafka_connection_metadata = $kc->get_metadata(); };
	if ($@) {
		diag(   "\n",
				"\n",
				('*' x 80), "\n",
				"WARNING! Apache Kafka service is not up or isn't listening on ${kafka_host}:${kafka_port}.", "\n",
				"Please, try setting KAFKA_HOST and KAFKA_PORT environment variables to specify Kafka's host and port.", "\n",
				('*' x 80) . "\n",
				"\n");
		skip "Unable to get Kafka metadata at ${kafka_host}:${kafka_port}", 17;
	}
	isa_ok($kafka_connection_metadata, 'HASH');

	my $sr_url = $ENV{CONFLUENT_SCHEMA_REGISTY_URL} || 'http://localhost:8081';
	my $sr = Confluent::SchemaRegistry->new('host' => $sr_url);
	unless (ref($sr) eq 'Confluent::SchemaRegistry') {
		diag(   "\n",
				"\n",
				('*' x 80), "\n",
				"WARNING! Confluent Schema Registry service is not up or isn't listening on $sr_url.", "\n",
				"Please, try setting CONFLUENT_SCHEMA_REGISTY_URL environment variable to specify it's URL.", "\n",
				('*' x 80) . "\n",
				"\n");
        skip(qq/Confluent Schema Registry service is not up or isn't listening on $sr_url/, 16);
	}

	my $cap = new_ok($class => [ 'Connection',$kc , 'SchemaRegistry',$sr ], qq/Valid REST client config/);
	isa_ok($cap, $class);

	my $topic = 'perl-kafka-producer-avro-test-' . time;
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
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema, 
		value_schema=>$value_schema_bad
	);
	ok(!defined $res, 'No schema in registry and bad schema supplied: ' . _nvl_str($cap->_get_error()));

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages, 
		keys=>$keys, 
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
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
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema
	);
	isa_ok($res, 'HASH', 'Message(s) sent by retreiving schema from registry: ' . _nvl_str($cap->_get_error()));

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages, 
		keys=>$keys, 
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema, 
		value_schema=>$value_schema_not_compliant
	);
	ok(!defined $res, 'Incompatible schema: ' . _nvl_str($cap->_get_error()));

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages, 
		keys=>$keys, 
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema, 
		value_schema=>$value_schema_bad
	);
	ok(!defined $res, 'Invalid schema: ' . _nvl_str($cap->_get_error()));

	$res = $cap->send(
		topic=>$topic.'BAD', 
		partition=>$partition, 
		messages=>$messages, 
		keys=>$keys, 
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema, 
		#value_schema=>$value_schema_bad
	);
	ok(!defined $res, 'No schema in registry: ' . _nvl_str($cap->_get_error()));

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages->[0], 
		keys=>$keys->[0], 
		compression_codec=>$compression_codec,
		timestamps=>int( Time::HiRes::time * 1000 ), 
		key_schema=>$key_schema, 
		value_schema=>$value_schema
	);
	isa_ok($res, 'HASH', 'Single message sent');

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages->[0], 
		keys=>$keys->[0], 
		compression_codec=>$compression_codec,
		key_schema=>$key_schema, 
		value_schema=>$value_schema
	);
	isa_ok($res, 'HASH', 'Single message sent w/o timestamp');

	$res = $cap->send(
		topic=>$topic, 
		partition=>$partition, 
		messages=>$messages, 
		keys=>$keys, 
		compression_codec=>$compression_codec,
		timestamps=> [ map { int( Time::HiRes::time * 1000 ) } @$messages ], 
		key_schema=>$key_schema
	);
	isa_ok($res, 'HASH', 'Message(s) sent by suggesting multiple timestamps');

	$res = $cap->send(
		$topic, 
		$partition, 
		$messages->[0], 
		$keys->[0], 
		$compression_codec, 
		int( Time::HiRes::time * 1000 ),
		$key_schema, 
		$value_schema
	);
	isa_ok($res, 'HASH', 'Single message sent with positional params call');

	$res = $cap->send(
		$topic, 
		$partition, 
		$messages, 
		$keys, 
		$compression_codec, 
		int( Time::HiRes::time * 1000 ),
		$key_schema, 
		$value_schema
	);
	isa_ok($res, 'HASH', 'Multiple messages sent with positional params call');

	$res = $cap->send(
		$topic, 
		$partition, 
		$messages
	);
	isa_ok($res, 'HASH', 'Multiple messages sent with minimal positional params call');

	$res = $cap->send(
		$topic, 
		$partition, 
		{ f1 => ('0' x ($Kafka::DEFAULT_MAX_BYTES - 1024)) }
	);
	isa_ok($res, 'HASH', 'Big message');

	# Clear Schema Registry subjects used for testing
	$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'key');
	$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'value');

}

$kc->close();
