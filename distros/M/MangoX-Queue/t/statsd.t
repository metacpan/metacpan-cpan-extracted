#!/usr/bin/env perl

use strict;
use warnings;

use Mango;
use MangoX::Queue;

use Test::More;

SKIP: {
	eval { require Net::Statsd };
	
	skip "Net::Statsd not installed", 1 if $@;

	my $mango = Mango->new('mongodb://localhost:27017');
	my $collection = $mango->db('test')->collection('mangox_queue_test');
	eval { $collection->drop };
	$collection->create;

	my $queue = MangoX::Queue->new(collection => $collection);

	plugin $queue 'MangoX::Queue::Plugin::Statsd';

	ok(exists $queue->plugins->{'MangoX::Queue::Plugin::Statsd'}, 'Plugin loaded ok');
};

done_testing;