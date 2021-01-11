#!/bin/env perl

use strict;
use warnings;

#use Test::More qw( no_plan );
use Test::More tests => 16;

BEGIN { use_ok('Kafka'); }
BEGIN { use_ok('Kafka::Connection'); }
BEGIN { use_ok('Confluent::SchemaRegistry'); }
BEGIN { use_ok('Kafka::Producer::Avro'); }
BEGIN { use_ok('Kafka::Consumer::Avro'); }
BEGIN { use_ok('Time::HiRes'); }

sub _nvl_str {
	return defined $_[0] ? $_[0] : ''; 
}

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
		skip "Unable to get Kafka metadata at ${kafka_host}:${kafka_port}", 8;
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
        skip(qq/Confluent Schema Registry service is not up or isn't listening on $sr_url/, 7);
	}

	my $class = 'Kafka::Producer::Avro';
	my $cap = new_ok($class => [ 'Connection',$kc , 'SchemaRegistry',$sr ], qq/Valid REST client config/);
	isa_ok($cap, $class);

	my $topic = 'perl-kafka-consumer-avro-test-' . time;
	my $partition = 0;
	my $messages = [];
	my $keys = [];
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

	for (my $i=0; $i<100; $i++) {
		push @$keys, $i;
		push @$messages, {
			f1 => ('x' x ($i+1))
		};
	}

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
		value_schema=>$value_schema, 
		unexpected_param=>$unexpected_param
	);
	isa_ok($res, 'HASH', 'Sent some messages');

	$class = 'Kafka::Consumer::Avro';
	my $cac = new_ok($class => [ 'Connection',$kc , 'SchemaRegistry',$sr ], qq/Valid REST client config/);
	isa_ok($cac, $class);

	my $read_keys = [];
	my $read_messages = [];
	my $offset = 0;
    while (1) {
		my $x = $cac->fetch(
			$topic,
			$partition,
			$offset,
			$Kafka::DEFAULT_MAX_BYTES    # Maximum size of MESSAGE(s) to receive
		);
		last unless scalar(@$x);
		$offset = $x->[$#$x]->next_offset;
		for (my $i=0; $i<=$#$x; $i++) {
			push @$read_keys, $x->[$i]->key;
			push @$read_messages, $x->[$i]->payload;
		}
		last unless $offset;
	}

	is_deeply( $read_keys, $keys, 'Keys comparison' );
	is_deeply( $read_messages, $messages, 'Messages comparison' );

	# Clear Schema Registry subjects used for testing
	$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'key');
	$cap->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'value');

}

$kc->close();

